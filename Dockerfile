# syntax=docker/dockerfile:1@sha256:4a43a54dd1fedceb30ba47e76cfcf2b47304f4161c0caeac2db1c61804ea3c91

ARG UPSTREAM_VERSION=v4.80.1
FROM simplelogin/app-ci:${UPSTREAM_VERSION}

ARG S6_OVERLAY_VERSION=3.2.0.0
ARG TARGETARCH

LABEL org.opencontainers.image.source="https://github.com/JSONbored/simplelogin-aio" \
      org.opencontainers.image.title="simplelogin-aio" \
      org.opencontainers.image.description="SimpleLogin packaged as a single-container Unraid AIO image"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/code/.venv/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    xz-utils \
    sudo \
    ca-certificates \
    netcat-openbsd \
    postgresql \
    postgresql-contrib \
    redis-server \
    postfix \
    postfix-pgsql && \
    curl -L -o /tmp/s6-overlay-noarch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
    case "${TARGETARCH}" in \
      amd64) s6_arch="x86_64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}. simplelogin-aio currently supports linux/amd64 only." >&2; exit 1 ;; \
    esac && \
    curl -L -o /tmp/s6-overlay-arch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${s6_arch}.tar.xz" && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    useradd --system --create-home --home-dir /home/simplelogin --shell /usr/sbin/nologin simplelogin && \
    mkdir -p /appdata/postgres /appdata/redis /appdata/dkim /appdata/sl/upload /pgp /run/postgresql && \
    chown -R postgres:postgres /appdata/postgres /run/postgresql && \
    chown -R redis:redis /appdata/redis && \
    chown -R simplelogin:simplelogin /appdata/sl /pgp && \
    rm -rf /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

RUN find /etc/cont-init.d -type f -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "run" -exec chmod +x {} \;

EXPOSE 7777 25
VOLUME ["/appdata", "/pgp"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS http://127.0.0.1:7777/health >/dev/null || exit 1

ENTRYPOINT ["/init"]
