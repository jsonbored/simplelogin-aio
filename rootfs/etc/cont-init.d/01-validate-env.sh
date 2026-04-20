#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

source /etc/simplelogin-aio/env-helpers.sh
normalize_simplelogin_blank_sensitive_env_vars
normalize_simplelogin_compat_env_vars
normalize_simplelogin_presence_env_vars

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting SimpleLogin-AIO environment validation...${NC}"

ERROR_COUNT=0

for required_var in URL EMAIL_DOMAIN SUPPORT_EMAIL FLASK_SECRET; do
    if [ -z "${!required_var:-}" ]; then
        echo -e "${RED}[ERROR] ${required_var} is not set.${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

RELAY_MODE_VALUE="${RELAY_MODE:-direct}"
case "$RELAY_MODE_VALUE" in
    direct)
        ;;
    brevo)
        [ -n "${BREVO_USERNAME:-}" ] || { echo -e "${RED}[ERROR] BREVO_USERNAME is required when RELAY_MODE=brevo.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        [ -n "${BREVO_PASSWORD:-}" ] || { echo -e "${RED}[ERROR] BREVO_PASSWORD is required when RELAY_MODE=brevo.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        ;;
    protonmail)
        [ -n "${PROTONMAIL_TOKEN:-}" ] || { echo -e "${RED}[ERROR] PROTONMAIL_TOKEN is required when RELAY_MODE=protonmail.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        ;;
    gmail)
        [ -n "${GMAIL_USERNAME:-}" ] || { echo -e "${RED}[ERROR] GMAIL_USERNAME is required when RELAY_MODE=gmail.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        [ -n "${GMAIL_APP_PASSWORD:-}" ] || { echo -e "${RED}[ERROR] GMAIL_APP_PASSWORD is required when RELAY_MODE=gmail.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        ;;
    mailgun)
        [ -n "${MAILGUN_USERNAME:-}" ] || { echo -e "${RED}[ERROR] MAILGUN_USERNAME is required when RELAY_MODE=mailgun.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        [ -n "${MAILGUN_PASSWORD:-}" ] || { echo -e "${RED}[ERROR] MAILGUN_PASSWORD is required when RELAY_MODE=mailgun.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        ;;
    custom)
        [ -n "${CUSTOM_RELAYHOST:-}" ] || { echo -e "${RED}[ERROR] CUSTOM_RELAYHOST is required when RELAY_MODE=custom.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        [ -n "${CUSTOM_USERNAME:-}" ] || { echo -e "${RED}[ERROR] CUSTOM_USERNAME is required when RELAY_MODE=custom.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        [ -n "${CUSTOM_PASSWORD:-}" ] || { echo -e "${RED}[ERROR] CUSTOM_PASSWORD is required when RELAY_MODE=custom.${NC}"; ERROR_COUNT=$((ERROR_COUNT + 1)); }
        ;;
    *)
        echo -e "${RED}[ERROR] RELAY_MODE=${RELAY_MODE_VALUE} is not supported.${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        ;;
esac

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${RED}Validation failed with $ERROR_COUNT error(s). Container startup halted.${NC}"
    exit 1
fi

if [ -z "${ADMIN_EMAIL:-}" ] && [ -z "${SL_ADMIN_EMAIL:-}" ]; then
    echo -e "${YELLOW}[WARNING] ADMIN_EMAIL is not set.${NC} You will not receive general system statistics and alerts."
fi

if [ -z "${DISABLE_REGISTRATION:-}" ]; then
    echo -e "${YELLOW}[WARNING] DISABLE_REGISTRATION is not set.${NC} Your instance currently allows open registration."
fi

echo "========================================"
echo "Confirmed Environment Configuration:"
echo "URL:              $URL"
echo "EMAIL_DOMAIN:     $EMAIL_DOMAIN"
echo "SUPPORT_EMAIL:    $SUPPORT_EMAIL"
echo "RELAY_MODE:       $RELAY_MODE_VALUE"
echo "========================================"
echo -e "${GREEN}Environment validation passed successfully.${NC}"
