FROM simplelogin/app-ci:latest

# Install s6-overlay
ARG S6_OVERLAY_VERSION=3.1.6.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz

# Create required directories
RUN mkdir -p /sl/pgp /sl/upload /dkim

COPY rootfs /
RUN chmod +x /etc/cont-init.d/*.sh /etc/services.d/*/run

VOLUME ["/sl", "/dkim"]
EXPOSE 7777 20381

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:7777/alive || exit 1

ENTRYPOINT ["/init"]