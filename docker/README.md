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

## Git-based Coolify installation on nanlab

Use https://github.com/nanw01/Easel, branch `container-nanlab`, Docker Compose build
pack, base `/`, Compose location `/compose.coolify.yaml`. This builds Easel from
Git instead of importing an existing unmanaged container. Media dependencies are
cached separately from UI/application files; temporary Rust toolchains are removed
from the final image.

Under Advanced, set Compose deployment to **Raw (deploy file as-is)**. Coolify
4.3.23's managed parser rewrites named volume references, including external ones.
Raw mode preserves the exact external volume names and the explicit Traefik route
in this file, while Coolify still builds from Git and manages the application.

Before the first deployment, run `python3 docker/init_domain.py` on nanlab. This
creates a protected Caddy configuration and a random login in `docker/data/`.
Never commit these generated files. The four existing volumes are declared external
by their exact Docker names, so the prior configuration and content remain available.
Stop the unmanaged Easel container before starting the Coolify application; both
must never use the same OpenClaw state concurrently.

Only the `gateway` service receives public traffic, on internal port 8080.
With the current nanlab Cloudflare Tunnel (HTTPS at the edge, HTTP to Traefik),
the Compose labels route `easel.nanlab.xyz` over HTTP internally; browse
`https://easel.nanlab.xyz`. Raw mode uses these repository labels for routing.
The Easel service itself has no public router.
Caddy requires authentication for every application/API request and removes the
login header before proxying. Its private 8081 health endpoint serves only `ok`.
The server-side login file is `docker/data/domain-login.txt` (0600).

Coolify is the owner of the Git-based deployment after migration. Do not run the
original Compose `up` while the Coolify application is active. A rollback stops
Coolify first, then starts the original Compose file with the preserved volumes.
