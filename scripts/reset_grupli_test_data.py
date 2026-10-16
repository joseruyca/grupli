"""Execute only the authorized, fingerprint-guarded test-account reset."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from supabase_release import connection

try:
    settings = connection(os.environ.pop('GRUPLI_DATABASE_URL', '').strip())
    cert = os.environ.pop('GRUPLI_DATABASE_CA_CERT', '')
    if '-----BEGIN CERTIFICATE-----' not in cert or 'PRIVATE KEY' in cert:
        raise ValueError('Certificate missing')
    with tempfile.TemporaryDirectory() as folder:
        ca = Path(folder) / 'ca.pem'
        ca.write_text(cert)
        ca.chmod(0o600)
        env = {key: value for key, value in os.environ.items() if not key.startswith('PG')}
        env.update(settings, PGSSLROOTCERT=str(ca))
        result = subprocess.run(['psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1'],
            input=Path(__file__).with_suffix('.sql').read_text(), text=True,
            capture_output=True, env=env, timeout=120)
    if result.returncode:
        print('RESET STOPPED: connection, changed account set or SQL check failed. No success confirmed.', file=sys.stderr)
        sys.exit(1)
    print('PASS: authorized test accounts and group data cleared. Storage files retained for API cleanup.')
except Exception:
    print('RESET STOPPED: configuration or execution failed. No credentials printed.', file=sys.stderr)
    sys.exit(1)
