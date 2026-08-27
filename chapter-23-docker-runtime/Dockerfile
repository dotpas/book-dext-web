# Dockerfile de Produção Ultraleve para Dext Framework no Linux64
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    libsqlite3-0 \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r dextgroup && useradd -r -g dextgroup dextuser

WORKDIR /app

COPY ./Chapter23_DockerRuntimeApp /app/Chapter23_DockerRuntimeApp

RUN chmod +x /app/Chapter23_DockerRuntimeApp && chown -R dextuser:dextgroup /app

USER dextuser

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8080/healthz/live || exit 1

ENTRYPOINT ["/app/Chapter23_DockerRuntimeApp"]
