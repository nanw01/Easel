"""Run on nanlab once before deploying compose.coolify.yaml; never prints credentials."""
import os
import secrets
import subprocess
from pathlib import Path

root = Path('/home/nan/apps/easel/docker/data')
root.mkdir(parents=True, exist_ok=True)
root.chmod(0o700)
credentials = root / 'domain-login.txt'
config = root / 'Caddyfile'
if credentials.exists() or config.exists():
    raise SystemExit('Existing domain files retained; rotate explicitly if needed.')
password = secrets.token_urlsafe(24)
result = subprocess.run(
    ['docker', 'run', '--rm', '-i', 'caddy:2-alpine', 'caddy', 'hash-password'],
    input=password + '\n', text=True, capture_output=True, check=True)
hashed = next((line.strip() for line in result.stdout.splitlines() if line.strip().startswith('$2')), '')
if not hashed:
    raise SystemExit('Password hashing failed; no configuration written.')
os.umask(0o077)
credentials.write_text('URL: https://easel.nanlab.xyz\nUsername: nan\nPassword: ' + password + '\n')
config.write_text('''{
    admin off
    auto_https off
}
:8080 {
    basic_auth {
        nan ''' + hashed + '''
    }
    reverse_proxy easel:7860 {
        header_up -Authorization
        flush_interval -1
    }
}
:8081 {
    respond /healthz "ok" 200
}
''')
print('Domain authentication configured; credentials stored locally with mode 0600.')
