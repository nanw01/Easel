import os
import urllib.request
for port, path in ((os.environ.get('EASEL_PORT', '7860'), '/'),
                   (os.environ.get('EASEL_GATEWAY_PORT', '37289'), '/healthz')):
    with urllib.request.urlopen(f'http://127.0.0.1:{port}{path}', timeout=3) as response:
        if response.status != 200:
            raise SystemExit(1)
