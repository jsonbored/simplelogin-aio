FROM simplelogin/app-ci
RUN apt-get update && apt-get install -y --no-install-recommends xz-utils curl && rm -rf /var/lib/apt/lists/* && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz
ENTRYPOINT ["/init"]
