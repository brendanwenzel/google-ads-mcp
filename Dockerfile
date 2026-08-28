FROM ghcr.io/astral-sh/uv@sha256:95f2aa1fe59274951cfe9b0cbc7972e879ff1004bc8945d130a32eb0dbd85945 AS uv
FROM python:3.11-slim@sha256:1042b61448fef4ba92d16a8c7eb4996d027568ce64792a7877fd88511e0af7c6

COPY --from=uv /uv /uvx /bin/

RUN groupadd --system --gid 10001 google-ads-mcp \
    && useradd --system --uid 10001 --gid 10001 --home-dir /nonexistent \
      --shell /usr/sbin/nologin google-ads-mcp

WORKDIR /app
ENV PATH="/app/.venv/bin:${PATH}" \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

COPY --chown=10001:10001 pyproject.toml uv.lock README.md ./
RUN uv sync --frozen --no-dev --no-install-project

COPY --chown=10001:10001 ads_mcp ./ads_mcp
RUN uv sync --frozen --no-dev
RUN uv pip install --python /app/.venv/bin/python --no-deps .

USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD ["python", "-c", "import socket; s=socket.create_connection(('127.0.0.1',8080),3); s.close()"]
CMD ["google-ads-mcp"]
