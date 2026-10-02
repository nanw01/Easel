# Easel container / nanlab

This image builds the React interface, installs the Python media tools, CPU-only PyTorch,
Chromium, FFmpeg and OpenClaw 2026.9.7. Runs as uid 1000. Tini and the entrypoint supervise
both processes: an unexpected exit of either process restarts the whole container.

## Run

```sh
docker compose build
docker compose up -d
ssh -N -L 7860:127.0.0.1:7860 nanlab
```

Open http://localhost:7860. Configure the model inside the private Web interface.
No host OpenClaw configuration, Docker socket or server credentials are mounted.
Gateway stays on container loopback. The host Web port is loopback-only.

## Persistence / backup

Four named volumes retain user home (gateway, login profiles and config/easel.env),
outputs, assets and personas. /app/.env points to the persistent configuration file;
Web writes resolve the symlink before atomic replacement. Do not use compose down -v.
Back up all four volumes while the Easel container is stopped for a consistent restore.
The reusable persona template is restored only if missing.

## Coolify

Use Docker Compose or Dockerfile build from this repository. Preserve the four mounts.
Use container port 7860 and this image's health check. No domain or public port is needed
for the private installation. If configuring a domain later, require an authentication
proxy and explicitly set EASEL_EXTRA_HOSTS and EASEL_EXTRA_ORIGINS for that domain.
The application's Host/Origin guard is not user authentication.

The image does not bundle API credits or configure a default paid model. Video/model
end-to-end acceptance requires credentials supplied by the user.
