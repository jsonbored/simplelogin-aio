#!/command/with-contenv bash

echo "Checking internal database requirements..."

mkdir -p /appdata/postgres /appdata/redis /appdata/dkim /appdata/sl
chown -R redis:redis /appdata/redis
chown -R postgres:postgres /appdata/postgres

# Auto-provision Postgres if DB_URI is empty
if [ -z "$DB_URI" ]; then
    echo "No external DB_URI provided. Bootstrapping internal PostgreSQL..."
    
    # Initialize DB if empty
    if [ ! -f "/appdata/postgres/PG_VERSION" ]; then
        echo "Initializing bare Postgres cluster..."
        # Get postgres version directory (e.g. /usr/lib/postgresql/14/bin/initdb)
        PG_BIN_DIR=$(ls -d /usr/lib/postgresql/*/bin | head -n 1)
        su - postgres -c "$PG_BIN_DIR/initdb -D /appdata/postgres"
        
        # We need a random password for the simplelogin user to secure it internally
        INTERNAL_PG_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        echo "$INTERNAL_PG_PASS" > /appdata/postgres/.sl_internal_pass
        chown postgres:postgres /appdata/postgres/.sl_internal_pass
        
        # Start PG temporarily to create user/db
        su - postgres -c "$PG_BIN_DIR/pg_ctl -D /appdata/postgres start"
        sleep 3
        su - postgres -c "psql -c \"CREATE USER simplelogin WITH PASSWORD '$INTERNAL_PG_PASS';\""
        su - postgres -c "psql -c \"CREATE DATABASE simplelogin OWNER simplelogin;\""
        su - postgres -c "$PG_BIN_DIR/pg_ctl -D /appdata/postgres stop"
    fi
    
    # Export the DB_URI for the python app to use downstream
    INTERNAL_PG_PASS=$(cat /appdata/postgres/.sl_internal_pass)
    # Write to s6-env so other scripts see it
    echo "postgresql://simplelogin:$INTERNAL_PG_PASS@127.0.0.1:5432/simplelogin" > /var/run/s6/container_environment/DB_URI
fi

if [ -z "$REDIS_URL" ]; then
    echo "redis://127.0.0.1:6379/0" > /var/run/s6/container_environment/REDIS_URL
fi

