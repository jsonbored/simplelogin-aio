# syntax=docker/dockerfile:1@sha256:2780b5c3bab67f1f76c781860de469442999ed1a0d7992a5efdf2cffc0e3d769
# checkov:skip=CKV_DOCKER_3: s6-overlay requires root init for bundled services before daemons drop privileges
ARG UPSTREAM_VERSION=v4.81.2
ARG UPSTREAM_IMAGE_DIGEST=sha256:d307d0224e16f036deecc273e28dd82f60ab58fdabc3190a7a31c035c5833a68
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
ENV PYTHONWARNINGS="ignore::SyntaxWarning"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# trunk-ignore(hadolint/DL3008)
RUN find /etc/apt -type f \( -name '*.list' -o -name '*.sources' \) -exec sed -i 's|http://|https://|g' {} + && \
    printf 'Acquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' > /etc/apt/apt.conf.d/80-retries && \
    apt-get update && apt-get -y dist-upgrade && apt-get install -y --no-install-recommends \
    curl \
    xz-utils \
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
    python3 -c "from pathlib import Path; env_py = Path('/code/migrations/env.py'); old = \"config.set_main_option('sqlalchemy.url', DB_URI)\\n\"; new = \"config.set_main_option('sqlalchemy.url', DB_URI.replace('%', '%%'))\\n\"; contents = env_py.read_text(); old in contents or (_ for _ in ()).throw(SystemExit('Unable to patch /code/migrations/env.py for escaped DB_URI handling')); env_py.write_text(contents.replace(old, new, 1))" && \
    python3 -c "from pathlib import Path; config_py = Path('/code/app/config.py'); old = \"ADMIN_FIDO_REQUIRED = os.environ.get(\\\"ADMIN_FIDO_REQUIRED\\\", \\\"none\\\")\\nif ADMIN_FIDO_REQUIRED not in (\\\"none\\\", \\\"any\\\", \\\"hardware\\\"):\\n    raise ValueError(\\\"ADMIN_FIDO_REQUIRED is not a valid value\\\")\\n\"; new = \"ADMIN_FIDO_REQUIRED = (os.environ.get(\\\"ADMIN_FIDO_REQUIRED\\\") or \\\"none\\\").strip()\\nif \\\"|\\\" in ADMIN_FIDO_REQUIRED:\\n    ADMIN_FIDO_REQUIRED = next((option for option in ADMIN_FIDO_REQUIRED.split(\\\"|\\\") if option in (\\\"none\\\", \\\"any\\\", \\\"hardware\\\")), \\\"none\\\")\\nif ADMIN_FIDO_REQUIRED not in (\\\"none\\\", \\\"any\\\", \\\"hardware\\\"):\\n    raise ValueError(\\\"ADMIN_FIDO_REQUIRED is not a valid value\\\")\\n\"; contents = config_py.read_text(); old in contents or (_ for _ in ()).throw(SystemExit('Unable to patch /code/app/config.py for ADMIN_FIDO_REQUIRED compatibility')); config_py.write_text(contents.replace(old, new, 1))" && \
    python3 -c "import logging; logging.getLogger().setLevel(logging.ERROR); import flanker.addresslib._parser.parser" && \
    useradd --system --create-home --home-dir /home/simplelogin --shell /usr/sbin/nologin simplelogin && \
    chmod 711 /root && \
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

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=300000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -fsS http://127.0.0.1:7777/health >/dev/null || exit 1

ENTRYPOINT ["/init"]
