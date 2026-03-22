#!/command/with-contenv bash
# ==============================================================================
# 01-validate-env.sh
# Purpose: Validates all required environment variables for SimpleLogin-AIO.
# Fails fast and prevents the container from starting if critical configs are missing.
# ==============================================================================

# ANSI Color Codes for readability
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting SimpleLogin-AIO environment validation...${NC}"

ERROR_COUNT=0

# Check URL
if [ -z "$URL" ]; then
    echo -e "${RED}[ERROR] URL is not set.${NC} This is the public-facing URL of your SimpleLogin instance (e.g., https://app.yourdomain.com). Please set the 'App URL' variable."
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Check EMAIL_DOMAIN
if [ -z "$EMAIL_DOMAIN" ]; then
    echo -e "${RED}[ERROR] EMAIL_DOMAIN is not set.${NC} This is the primary domain used to create aliases (e.g., yourdomain.com). Please set the 'Email Domain' variable."
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Check SUPPORT_EMAIL
if [ -z "$SUPPORT_EMAIL" ]; then
    echo -e "${RED}[ERROR] SUPPORT_EMAIL is not set.${NC} This is the address from which transactional system emails are sent. Please set the 'Support Email' variable."
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Check FLASK_SECRET
if [ -z "$FLASK_SECRET" ]; then
    echo -e "${RED}[ERROR] FLASK_SECRET is not set.${NC} This is the cryptographic secret used by Flask to sign session cookies. Please set the 'Flask Secret' variable to a random string."
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Check DB_URI
if [ -z "$DB_URI" ]; then
    echo -e "${RED}[ERROR] DB_URI is not set.${NC} This is the connection string for the PostgreSQL database. Please set the 'Database URI' variable."
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Check POSTFIX_SERVER
if [ -z "$POSTFIX_SERVER" ]; then
    echo -e "${RED}[ERROR] POSTFIX_SERVER is not set.${NC} This is the hostname or IP of the MTA (Postfix) server. Please set the 'Postfix Server' variable."
    ERROR_COUNT=$((ERROR_COUNT+1))
fi

# Halt if there are errors
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${RED}Validation failed with $ERROR_COUNT error(s). Container startup halted.${NC}"
    exit 1
fi

# Check important optional variables and print warnings
if [ -z "$ADMIN_EMAIL" ] && [ -z "$SL_ADMIN_EMAIL" ]; then
    echo -e "${YELLOW}[WARNING] ADMIN_EMAIL is not set.${NC} You will not receive general system statistics and alerts."
fi

if [ -z "$DISABLE_REGISTRATION" ]; then
    echo -e "${YELLOW}[WARNING] DISABLE_REGISTRATION is not set.${NC} Your instance currently allows open registration. It is highly recommended to set this to 1 after creating your admin account to prevent abuse."
fi

# Print confirmed values for non-sensitive vars
echo "========================================"
echo "Confirmed Environment Configuration:"
echo "URL:              $URL"
echo "EMAIL_DOMAIN:     $EMAIL_DOMAIN"
echo "SUPPORT_EMAIL:    $SUPPORT_EMAIL"
echo "POSTFIX_SERVER:   $POSTFIX_SERVER"
echo "========================================"
echo -e "${GREEN}Environment validation passed successfully.${NC}"
