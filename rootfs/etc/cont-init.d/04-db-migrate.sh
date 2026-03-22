#!/command/with-contenv bash
# ==============================================================================
# 04-db-migrate.sh
# Purpose: Ensures the database is reachable before attempting to run migrations.
# Runs `flask db upgrade` idempotently on every start.
# Detects first run, executes `init_app.py`, and creates a marker file.
# ==============================================================================

# ANSI Color Codes
CYAN='\033[1;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /code || exit 1

# Extract DB credentials robustly using a quick python script since the container has psycopg2
echo -e "${CYAN}Testing database connection...${NC}"

cat << 'EOF' > /tmp/db_test.py
import os
import sys
from sqlalchemy import create_engine

db_uri = os.environ.get("DB_URI")
if not db_uri:
    sys.exit(1)

try:
    engine = create_engine(db_uri)
    conn = engine.connect()
    conn.close()
    sys.exit(0)
except Exception as e:
    sys.exit(1)
EOF

MAX_RETRIES=30
RETRY_COUNT=0
DB_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo -n "Attempt $RETRY_COUNT of $MAX_RETRIES: "
    
    if python3 /tmp/db_test.py; then
        echo -e "${GREEN}Database connection established!${NC}"
        DB_READY=true
        break
    else
        echo -e "${YELLOW}Waiting for database to accept connections...${NC}"
        sleep 3
    fi
done

if [ "$DB_READY" = false ]; then
    echo -e "${RED}[ERROR] Database is unreachable after $MAX_RETRIES attempts.${NC}"
    echo -e "Please check your DB_URI setting and ensure your PostgreSQL container is running."
    exit 1
fi

# Run Migrations
echo -e "${CYAN}Running database migrations...${NC}"
if ! flask db upgrade; then
    echo -e "${RED}[ERROR] Database migration failed.${NC}"
    exit 1
fi
echo -e "${GREEN}Database migrations complete.${NC}"

# Check for Initialization Marker
MARKER_FILE="/sl/.initialized"

if [ -f "$MARKER_FILE" ]; then
    echo -e "${GREEN}First-run initialization marker found. Skipping init_app.py.${NC}"
else
    echo -e "${CYAN}First-run detected. Executing initial database seeding...${NC}"
    if ! python3 init_app.py; then
         echo -e "${RED}[ERROR] Failed to run init_app.py.${NC}"
         exit 1
    fi
    
    # Create marker file
    mkdir -p "$(dirname "$MARKER_FILE")"
    touch "$MARKER_FILE"
    
    echo -e "================================================================================"
    echo -e "${GREEN}First-run setup successfully completed!${NC}"
    echo -e "================================================================================"
    echo -e "Next Steps:"
    echo -e "1. Visit your App URL ($URL)"
    echo -e "2. Register your administrator account."
    echo -e "3. Once registered, edit this container and set ${YELLOW}DISABLE_REGISTRATION=1${NC}"
    echo -e "4. Restart the container to lock down your instance from public signups."
    echo -e "================================================================================"
fi
