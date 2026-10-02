#!/usr/bin/env bash
set -euo pipefail
cd /app
mkdir -p outputs assets profiles /home/easel/.openclaw-easel
# Copy the reusable template only when the mounted profile directory is empty.
if [ ! -d profiles/_template ]; then cp -a /opt/easel-profile-template profiles/_template; fi
mkdir -p /home/easel/config
touch /home/easel/config/easel.env
chmod 600 /home/easel/config/easel.env
ln -sfn /home/easel/config/easel.env /app/.env
python docker/init_config.py
bash openclaw/sync.sh > /tmp/easel-sync.log
export OPENCLAW_RAW_STREAM=1 OPENCLAW_RAW_STREAM_PATH=/tmp/easel-raw-stream.jsonl
export EASEL_ASKUSER_CARDS=1
openclaw --profile easel gateway run --allow-unconfigured --bind loopback &
gateway_pid=$!
cleanup() { kill "${web_pid:-}" "$gateway_pid" 2>/dev/null || true; wait || true; }
trap cleanup EXIT
trap 'exit 0' TERM INT
for attempt in $(seq 1 90); do
    kill -0 "$gateway_pid" || exit 1
    if curl -fsS "http://127.0.0.1:${EASEL_GATEWAY_PORT}/healthz" >/dev/null; then break; fi
    sleep 1
done
curl -fsS "http://127.0.0.1:${EASEL_GATEWAY_PORT}/healthz" >/dev/null
python web/app.py &
web_pid=$!
wait -n "$gateway_pid" "$web_pid"
exit 1
