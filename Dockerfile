FROM simplelogin/app-ci

# Install s6-overlay, Postgres, Redis, Postfix, OpenDKIM
RUN apt-get update && apt-get install -y --no-install-recommends \
    xz-utils curl sudo \
    postgresql postgresql-contrib redis-server \
    postfix postfix-pgsql opendkim opendkim-tools && \
    rm -rf /var/lib/apt/lists/* && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz

# Ensure base directories exist
RUN mkdir -p /appdata/postgres /appdata/redis /appdata/dkim /appdata/sl /run/postgresql && \
    chown -R postgres:postgres /run/postgresql

COPY rootfs/ /

ENTRYPOINT ["/init"]
