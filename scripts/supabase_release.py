"""Fixed, project-scoped release. Credentials never enter arguments or logs."""
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.parse import unquote, urlsplit

PROJECT = 'izusbttdgtwbnuyzjrpw'
ROOT = Path(__file__).resolve().parents[1]


def connection(raw):
    uri = urlsplit(raw)
    host = uri.hostname or ''
    if (uri.scheme not in ('postgres', 'postgresql')
            or not host.endswith('.pooler.supabase.com')
            or uri.port != 5432 or unquote(uri.username or '') != 'postgres.' + PROJECT
            or uri.path != '/postgres' or not uri.password or uri.fragment):
        raise ValueError('Use the Session pooler connection for Grupli on port 5432.')
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
    if not raw or not cert:
        raise ValueError('Add GRUPLI_DATABASE_URL and GRUPLI_DATABASE_CA_CERT to GitHub Actions secrets.')
    settings = connection(raw)
    if '-----BEGIN CERTIFICATE-----' not in cert or 'PRIVATE KEY' in cert:
        raise ValueError('Expected the public Supabase CA certificate in PEM format.')
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
        raise RuntimeError('Database operation failed. No success confirmed. Check connection, certificate, network restrictions and finance prerequisite.')
    print('PASS: verified TLS connection and finance prerequisite.' if mode == 'check'
          else 'PASS: ownership patch committed; trigger and RPC permissions verified.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, subprocess.TimeoutExpired):
        print('Release stopped. Check the two Actions secrets, Session pooler on port 5432, CA certificate and project access. No success confirmed.', file=sys.stderr)
        sys.exit(1)
