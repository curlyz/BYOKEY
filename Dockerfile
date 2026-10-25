# Dokploy build for BYOKEY (fork branch: dokploy).
# Upstream has no Dockerfile; this mirrors README "from source":
# Rust 1.91+ (edition 2024), protoc for ConnectRPC codegen, cc for bundled SQLite.
# syntax=docker/dockerfile:1
FROM rust:1-slim AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
      protobuf-compiler pkg-config libssl-dev ca-certificates \
      build-essential \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo build --release -p byokey \
    && cp target/release/byokey /byokey

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -m -u 10001 byokey
WORKDIR /app
COPY --from=builder /byokey /app/byokey
RUN mkdir -p /data && chown byokey /data
USER byokey
VOLUME /data
EXPOSE 8018
ENTRYPOINT ["/app/byokey"]
CMD ["serve", "--host", "0.0.0.0", "--port", "8018", \
     "--config", "/data/settings.json", "--db", "/data/tokens.db", \
     "--log-file", "/data/server.log"]
