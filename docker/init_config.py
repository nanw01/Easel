"""Initialize an isolated runtime once; retain user model configuration on restarts."""
import json
import os
from pathlib import Path

path = Path.home() / '.openclaw-easel/openclaw.json'
if not path.exists():
    config = {
        'gateway': {'mode': 'local', 'bind': 'loopback',
                    'port': int(os.environ.get('EASEL_GATEWAY_PORT', '37289')),
                    'auth': {'mode': 'none'},
                    'http': {'endpoints': {'chatCompletions': {'enabled': True}}}},
        'agents': {'defaults': {'workspace': os.environ['EASEL_OPENCLAW_WORKSPACE']}},
    }
    path.write_text(json.dumps(config, indent=2))
    path.chmod(0o600)
