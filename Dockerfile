# syntax=docker/dockerfile:1@sha256:2780b5c3bab67f1f76c781860de469442999ed1a0d7992a5efdf2cffc0e3d769

ARG UPSTREAM_VERSION=v4.80.1
ARG UPSTREAM_IMAGE_DIGEST=sha256:e79744cfeb653ae3d2d8450f8421063f44b36690932ebfcb295d616bd6975d6d
FROM simplelogin/app-ci:${UPSTREAM_VERSION}@${UPSTREAM_IMAGE_DIGEST}

ARG S6_OVERLAY_VERSION=3.2.0.0
ARG S6_OVERLAY_NOARCH_SHA256=4b0c0907e6762814c31850e0e6c6762c385571d4656eb8725852b0b1586713b6
ARG S6_OVERLAY_X86_64_SHA256=ad982a801bd72757c7b1b53539a146cf715e640b4d8f0a6a671a3d1b560fe1e2
ARG TARGETARCH

LABEL org.opencontainers.image.source="https://github.com/JSONbored/simplelogin-aio" \
      org.opencontainers.image.title="simplelogin-aio" \
      org.opencontainers.image.description="SimpleLogin packaged as a single-container Unraid AIO image"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/code/.venv/bin:${PATH}"

RUN apt-get update && apt-get -y dist-upgrade && apt-get install -y --no-install-recommends \
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
    echo "${S6_OVERLAY_NOARCH_SHA256}  /tmp/s6-overlay-noarch.tar.xz" | sha256sum -c - && \
    case "${TARGETARCH}" in \
      amd64) s6_arch="x86_64"; s6_sha="${S6_OVERLAY_X86_64_SHA256}" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}. simplelogin-aio currently supports linux/amd64 only." >&2; exit 1 ;; \
    esac && \
    curl -L -o /tmp/s6-overlay-arch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${s6_arch}.tar.xz" && \
    echo "${s6_sha}  /tmp/s6-overlay-arch.tar.xz" | sha256sum -c - && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    useradd --system --create-home --home-dir /home/simplelogin --shell /usr/sbin/nologin simplelogin && \
    mkdir -p /appdata/postgres /appdata/redis /appdata/dkim /appdata/sl/upload /pgp /custom-assets /run/postgresql && \
    chown -R postgres:postgres /appdata/postgres /run/postgresql && \
    chown -R redis:redis /appdata/redis && \
    chown -R simplelogin:simplelogin /appdata/sl /pgp /custom-assets && \
    rm -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem && \
    rm -rf /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

RUN find /etc/cont-init.d -type f -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "run" -exec chmod +x {} \;

EXPOSE 7777 25
VOLUME ["/appdata", "/pgp"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS http://127.0.0.1:7777/health >/dev/null || exit 1

ENTRYPOINT ["/init"]
