"""Fixed, project-scoped release. Credentials never enter arguments or logs."""
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.parse import unquote, urlsplit

PROJECT = 'izusbttdgtwbnuyzjrpw'
ROOT = Path(__file__).resolve().parents[1]


class ReleaseError(Exception):
    """Only fixed, non-secret diagnostics may use this exception."""


def connection(raw):
    uri = urlsplit(raw)
    host = uri.hostname or ''
    if uri.scheme not in ('postgres', 'postgresql'):
        raise ReleaseError('URL_SCHEME: expected a PostgreSQL URI, without quotes or code fences.')
    if not host.endswith('.pooler.supabase.com'):
        raise ReleaseError('URL_HOST: select Session pooler, not Direct connection.')
    if uri.port != 5432:
        raise ReleaseError('URL_PORT: select Session pooler on port 5432.')
    if unquote(uri.username or '') != 'postgres.' + PROJECT:
        raise ReleaseError('URL_PROJECT: expected the Session pooler user of Grupli.')
    if uri.path != '/postgres' or not uri.password or uri.fragment:
        raise ReleaseError('URL_FORMAT: check database name and percent-encode password symbols.')
    if '[YOUR-PASSWORD]' in raw:
        raise ReleaseError('URL_PASSWORD_PLACEHOLDER: replace the password placeholder.')
    return {'PGHOST': host, 'PGPORT': '5432', 'PGDATABASE': 'postgres',
            'PGUSER': unquote(uri.username), 'PGPASSWORD': unquote(uri.password),
            'PGSSLMODE': 'verify-full', 'PGCONNECT_TIMEOUT': '15'}


CHECK = """
do $$ begin
 if to_regprocedure('public.grupli_save_expense(uuid,uuid,text,numeric,uuid,jsonb,text)') is null
 then raise exception 'Finance prerequisite missing'; end if;
end $$;
"""
VERIFY = """
do $$ begin
 if to_regprocedure('public.grupli_transfer_group(uuid,uuid)') is null
 or not exists(select 1 from pg_trigger where tgrelid='public.groups'::regclass
 and tgname='guard_group_owner' and not tgisinternal and tgenabled='O')
 then raise exception 'Ownership verification failed'; end if;
 if has_function_privilege('anon','public.grupli_transfer_group(uuid,uuid)','execute')
 or not has_function_privilege('authenticated','public.grupli_transfer_group(uuid,uuid)','execute')
 then raise exception 'RPC permission verification failed'; end if;
end $$;
"""


def main():
    mode = sys.argv[1] if len(sys.argv) == 2 else ''
    if mode not in ('check', 'apply'):
        raise ValueError('Expected check or apply.')
    raw = os.environ.pop('GRUPLI_DATABASE_URL', '')
    cert = os.environ.pop('GRUPLI_DATABASE_CA_CERT', '')
    if not raw:
        raise ReleaseError('MISSING_URL: add repository secret GRUPLI_DATABASE_URL.')
    if not cert:
        raise ReleaseError('MISSING_CA: add repository secret GRUPLI_DATABASE_CA_CERT.')
    settings = connection(raw.strip())
    if '-----BEGIN CERTIFICATE-----' not in cert or 'PRIVATE KEY' in cert:
        raise ReleaseError('CA_FORMAT: paste the complete PEM public certificate text, not a file path.')
    print('PASS: both secrets present; Session pooler project, port and certificate header checked.', flush=True)
    sql = "begin; set local statement_timeout='30s'; set local lock_timeout='10s';\n"
    sql += "select pg_advisory_xact_lock(719204510);\n" + CHECK
    if mode == 'apply':
        patch = (ROOT / 'supabase/patches/20261013_group_ownership.sql').read_text().strip()
        if not patch.startswith('begin;') or not patch.endswith('commit;'):
            raise ValueError('Unexpected patch transaction boundaries.')
        sql += patch[len('begin;'):-len('commit;')] + '\n' + VERIFY
    sql += 'commit;'
    with tempfile.TemporaryDirectory() as directory:
        ca = Path(directory) / 'ca.pem'
        ca.write_text(cert)
        ca.chmod(0o600)
        env = {key: value for key, value in os.environ.items() if not key.startswith('PG')}
        env.update(settings, PGSSLROOTCERT=str(ca))
        result = subprocess.run(['psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1'],
                                input=sql, text=True, capture_output=True, env=env, timeout=120)
    if result.returncode:
        # Do not echo libpq errors, which can contain hosts, users or secret fragments.
        error = result.stderr.lower()
        reason = 'DATABASE: connection or SQL operation failed; no success confirmed.'
        for needle, message in [
            ('password authentication failed', 'DB_PASSWORD: PostgreSQL rejected the database password.'),
            ('tenant or user not found', 'DB_TENANT: Session pooler host and user do not identify the project.'),
            ('certificate verify failed', 'DB_CERTIFICATE: certificate verification failed; use the project CA certificate.'),
            ('root certificate file', 'DB_CA_FILE: CA certificate could not be read or parsed.'),
            ('could not translate host name', 'DB_DNS: Session pooler host could not be resolved.'),
            ('timeout expired', 'DB_TIMEOUT: server did not respond within the connection timeout.'),
            ('finance prerequisite missing', 'DB_PREREQUISITE: finance update is absent from this database.'),
            ('permission denied', 'DB_PERMISSION: database role lacks required permissions.'),
        ]:
            if needle in error:
                reason = message
                break
        raise ReleaseError(reason)
    print('PASS: verified TLS connection and finance prerequisite.' if mode == 'check'
          else 'PASS: ownership patch committed; trigger and RPC permissions verified.')


if __name__ == '__main__':
    try:
        main()
    except ReleaseError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except (ValueError, RuntimeError, subprocess.TimeoutExpired):
        print('Release stopped. Check the two Actions secrets, Session pooler on port 5432, CA certificate and project access. No success confirmed.', file=sys.stderr)
        sys.exit(1)
