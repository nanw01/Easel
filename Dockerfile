FROM node:24-bookworm-slim AS frontend
WORKDIR /build
COPY web/frontend/package*.json ./
RUN npm ci
COPY web/frontend/ ./
RUN npm run build

FROM python:3.11-slim-bookworm
ARG OPENCLAW_VERSION=2026.9.7
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 PATH=/app/.venv/bin:$PATH \
    PLAYWRIGHT_BROWSERS_PATH=/opt/playwright EASEL_ROOT=/app EASEL_PORT=7860 \
    EASEL_GATEWAY_PORT=37289 EASEL_OPENCLAW_WORKSPACE=/home/easel/.openclaw-easel/workspace
COPY --from=frontend /usr/local/bin/node /usr/local/bin/node
COPY --from=frontend /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && apt-get update && apt-get install -y --no-install-recommends git curl ffmpeg tini fonts-noto-cjk ca-certificates build-essential \
 && npm install -g openclaw@${OPENCLAW_VERSION} \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
# Keep media dependency builds cached when application/frontend files change.
COPY pyproject.toml ./
COPY easel/ ./easel/
RUN python -m venv /app/.venv \
 && pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision \
 && CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 pip install -e . \
 && python -m playwright install --with-deps chromium \
 && useradd --create-home --uid 1000 easel \
 && chown -R easel:easel /app /opt/playwright \
 && rm -rf /root/.cache /root/.cargo /root/.rustup /tmp/pip-* /var/lib/apt/lists/*
COPY --chown=1000:1000 . .
COPY --chown=1000:1000 --from=frontend /build/dist /app/web/frontend/dist
RUN cp -a profiles/_template /opt/easel-profile-template \
 && mkdir -p /app/outputs /app/assets /app/profiles \
 && chown easel:easel /app/outputs /app/assets /app/profiles
USER easel
EXPOSE 7860
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 CMD python docker/healthcheck.py
ENTRYPOINT ["/usr/bin/tini", "--", "bash", "/app/docker/entrypoint.sh"]
