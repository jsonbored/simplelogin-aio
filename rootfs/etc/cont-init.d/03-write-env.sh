#!/command/with-contenv bash
# ==============================================================================
# 03-write-env.sh
# Purpose: Translates Unraid XML environment variables into the specific format
# that SimpleLogin expects in its /code/.env file. This isolates host configuration
# from application expectations and ensures every variable is mapped.
# Regenerates on every container start.
# ==============================================================================

# ANSI Color Codes
CYAN='\033[1;36m'
GREEN='\033[0;32m'
NC='\033[0m'

ENV_FILE="/code/.env"

echo -e "${CYAN}Generating SimpleLogin .env configuration...${NC}"

# Clear existing file
> "$ENV_FILE"

# ------------------------------------------------------------------------------
# CORE & REQUIRED VARIABLES
# ------------------------------------------------------------------------------
echo "URL=${URL}" >> "$ENV_FILE"
echo "EMAIL_DOMAIN=${EMAIL_DOMAIN}" >> "$ENV_FILE"
echo "SUPPORT_EMAIL=${SUPPORT_EMAIL}" >> "$ENV_FILE"
echo "FLASK_SECRET=${FLASK_SECRET}" >> "$ENV_FILE"
echo "DB_URI=${DB_URI}" >> "$ENV_FILE"
echo "REDIS_URL=${REDIS_URL}" >> "$ENV_FILE"
echo "POSTFIX_SERVER=127.0.0.1" >> "$ENV_FILE"

# ------------------------------------------------------------------------------
# DEFAULTS & HARDCODED PATHS
# ------------------------------------------------------------------------------
echo "POSTFIX_PORT=${POSTFIX_PORT:-25}" >> "$ENV_FILE"
echo "DKIM_PRIVATE_KEY_PATH=/dkim.key" >> "$ENV_FILE"
echo "DKIM_PUBLIC_KEY_PATH=/dkim.pub.key" >> "$ENV_FILE"
echo "GNUPGHOME=${GNUPGHOME:-/sl/pgp}" >> "$ENV_FILE"

# Self-hosting optimized defaults
echo "LOCAL_FILE_UPLOAD=${LOCAL_FILE_UPLOAD:-true}" >> "$ENV_FILE"
echo "DISABLE_ALIAS_SUFFIX=${DISABLE_ALIAS_SUFFIX:-1}" >> "$ENV_FILE"
echo "DISABLE_REGISTRATION=${DISABLE_REGISTRATION:-0}" >> "$ENV_FILE"
echo "DISABLE_ONBOARDING=${DISABLE_ONBOARDING:-true}" >> "$ENV_FILE"
echo "MAX_NB_EMAIL_FREE_PLAN=${MAX_NB_EMAIL_FREE_PLAN:-10}" >> "$ENV_FILE"
echo "ENFORCE_SPF=${ENFORCE_SPF:-true}" >> "$ENV_FILE"

# Support both SL_NAMESERVERS and NAMESERVERS syntax
if [ -n "$SL_NAMESERVERS" ]; then
    echo "NAMESERVERS=${SL_NAMESERVERS}" >> "$ENV_FILE"
elif [ -n "$NAMESERVERS" ]; then
    echo "NAMESERVERS=${NAMESERVERS}" >> "$ENV_FILE"
else
    echo "NAMESERVERS=1.1.1.1,1.0.0.1" >> "$ENV_FILE"
fi

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES (Appended only if set)
# ------------------------------------------------------------------------------

# General Settings
[ -n "$WORDS_FILE_PATH" ] && echo "WORDS_FILE_PATH=${WORDS_FILE_PATH}" >> "$ENV_FILE"
[ -n "$TEMP_DIR" ] && echo "TEMP_DIR=${TEMP_DIR}" >> "$ENV_FILE"
[ -n "$COLOR_LOG" ] && echo "COLOR_LOG=${COLOR_LOG}" >> "$ENV_FILE"
[ -n "$NOT_SEND_EMAIL" ] && echo "NOT_SEND_EMAIL=${NOT_SEND_EMAIL}" >> "$ENV_FILE"
[ -n "$LANDING_PAGE_URL" ] && echo "LANDING_PAGE_URL=${LANDING_PAGE_URL}" >> "$ENV_FILE"
[ -n "$STATUS_PAGE_URL" ] && echo "STATUS_PAGE_URL=${STATUS_PAGE_URL}" >> "$ENV_FILE"
[ -n "$PARTNER_API_TOKEN_SECRET" ] && echo "PARTNER_API_TOKEN_SECRET=${PARTNER_API_TOKEN_SECRET}" >> "$ENV_FILE"
[ -n "$ALLOWED_REDIRECT_DOMAINS" ] && echo "ALLOWED_REDIRECT_DOMAINS=${ALLOWED_REDIRECT_DOMAINS}" >> "$ENV_FILE"

# Email Routing & Domains
[ -n "$OTHER_ALIAS_DOMAINS" ] && echo "OTHER_ALIAS_DOMAINS=${OTHER_ALIAS_DOMAINS}" >> "$ENV_FILE"
[ -n "$ALIAS_DOMAINS" ] && echo "ALIAS_DOMAINS=${ALIAS_DOMAINS}" >> "$ENV_FILE"
[ -n "$PREMIUM_ALIAS_DOMAINS" ] && echo "PREMIUM_ALIAS_DOMAINS=${PREMIUM_ALIAS_DOMAINS}" >> "$ENV_FILE"
[ -n "$FIRST_ALIAS_DOMAIN" ] && echo "FIRST_ALIAS_DOMAIN=${FIRST_ALIAS_DOMAIN}" >> "$ENV_FILE"
[ -n "$SUPPORT_NAME" ] && echo "SUPPORT_NAME=${SUPPORT_NAME}" >> "$ENV_FILE"
[ -n "$ADMIN_EMAIL" ] && echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >> "$ENV_FILE"
[ -n "$EMAIL_SERVERS_WITH_PRIORITY" ] && echo "EMAIL_SERVERS_WITH_PRIORITY=${EMAIL_SERVERS_WITH_PRIORITY}" >> "$ENV_FILE"
[ -n "$POSTMASTER" ] && echo "POSTMASTER=${POSTMASTER}" >> "$ENV_FILE"

# Security & Limits
[ -n "$PGP_SENDER_PRIVATE_KEY_PATH" ] && echo "PGP_SENDER_PRIVATE_KEY_PATH=${PGP_SENDER_PRIVATE_KEY_PATH}" >> "$ENV_FILE"
[ -n "$OPENID_PRIVATE_KEY_PATH" ] && echo "OPENID_PRIVATE_KEY_PATH=${OPENID_PRIVATE_KEY_PATH}" >> "$ENV_FILE"
[ -n "$OPENID_PUBLIC_KEY_PATH" ] && echo "OPENID_PUBLIC_KEY_PATH=${OPENID_PUBLIC_KEY_PATH}" >> "$ENV_FILE"
[ -n "$ALIAS_LIMIT" ] && echo "ALIAS_LIMIT=${ALIAS_LIMIT}" >> "$ENV_FILE"
[ -n "$ALIAS_AUTOMATIC_DISABLE" ] && echo "ALIAS_AUTOMATIC_DISABLE=${ALIAS_AUTOMATIC_DISABLE}" >> "$ENV_FILE"

# Bounce Processing (VERP)
[ -n "$BOUNCE_PREFIX" ] && echo "BOUNCE_PREFIX=${BOUNCE_PREFIX}" >> "$ENV_FILE"
[ -n "$BOUNCE_SUFFIX" ] && echo "BOUNCE_SUFFIX=${BOUNCE_SUFFIX}" >> "$ENV_FILE"
[ -n "$BOUNCE_PREFIX_FOR_REPLY_PHASE" ] && echo "BOUNCE_PREFIX_FOR_REPLY_PHASE=${BOUNCE_PREFIX_FOR_REPLY_PHASE}" >> "$ENV_FILE"

# OAuth & Logins
[ -n "$GITHUB_CLIENT_ID" ] && echo "GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}" >> "$ENV_FILE"
[ -n "$GITHUB_CLIENT_SECRET" ] && echo "GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}" >> "$ENV_FILE"
[ -n "$GOOGLE_CLIENT_ID" ] && echo "GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}" >> "$ENV_FILE"
[ -n "$GOOGLE_CLIENT_SECRET" ] && echo "GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}" >> "$ENV_FILE"
[ -n "$FACEBOOK_CLIENT_ID" ] && echo "FACEBOOK_CLIENT_ID=${FACEBOOK_CLIENT_ID}" >> "$ENV_FILE"
[ -n "$FACEBOOK_CLIENT_SECRET" ] && echo "FACEBOOK_CLIENT_SECRET=${FACEBOOK_CLIENT_SECRET}" >> "$ENV_FILE"
[ -n "$PROTON_CLIENT_ID" ] && echo "PROTON_CLIENT_ID=${PROTON_CLIENT_ID}" >> "$ENV_FILE"
[ -n "$PROTON_CLIENT_SECRET" ] && echo "PROTON_CLIENT_SECRET=${PROTON_CLIENT_SECRET}" >> "$ENV_FILE"
[ -n "$PROTON_BASE_URL" ] && echo "PROTON_BASE_URL=${PROTON_BASE_URL}" >> "$ENV_FILE"
[ -n "$PROTON_VALIDATE_CERTS" ] && echo "PROTON_VALIDATE_CERTS=${PROTON_VALIDATE_CERTS}" >> "$ENV_FILE"
[ -n "$CONNECT_WITH_PROTON" ] && echo "CONNECT_WITH_PROTON=${CONNECT_WITH_PROTON}" >> "$ENV_FILE"
[ -n "$CONNECT_WITH_PROTON_COOKIE_NAME" ] && echo "CONNECT_WITH_PROTON_COOKIE_NAME=${CONNECT_WITH_PROTON_COOKIE_NAME}" >> "$ENV_FILE"

# Generic OIDC
[ -n "$CONNECT_WITH_OIDC_ICON" ] && echo "CONNECT_WITH_OIDC_ICON=${CONNECT_WITH_OIDC_ICON}" >> "$ENV_FILE"
[ -n "$OIDC_WELL_KNOWN_URL" ] && echo "OIDC_WELL_KNOWN_URL=${OIDC_WELL_KNOWN_URL}" >> "$ENV_FILE"
[ -n "$OIDC_SCOPES" ] && echo "OIDC_SCOPES=${OIDC_SCOPES}" >> "$ENV_FILE"
[ -n "$OIDC_NAME_FIELD" ] && echo "OIDC_NAME_FIELD=${OIDC_NAME_FIELD}" >> "$ENV_FILE"
[ -n "$OIDC_CLIENT_ID" ] && echo "OIDC_CLIENT_ID=${OIDC_CLIENT_ID}" >> "$ENV_FILE"
[ -n "$OIDC_CLIENT_SECRET" ] && echo "OIDC_CLIENT_SECRET=${OIDC_CLIENT_SECRET}" >> "$ENV_FILE"
[ -n "$APPLE_API_SECRET" ] && echo "APPLE_API_SECRET=${APPLE_API_SECRET}" >> "$ENV_FILE"
[ -n "$MACAPP_APPLE_API_SECRET" ] && echo "MACAPP_APPLE_API_SECRET=${MACAPP_APPLE_API_SECRET}" >> "$ENV_FILE"

# Spam Scanning
[ -n "$ENABLE_SPAM_ASSASSIN" ] && echo "ENABLE_SPAM_ASSASSIN=${ENABLE_SPAM_ASSASSIN}" >> "$ENV_FILE"
[ -n "$SPAMASSASSIN_HOST" ] && echo "SPAMASSASSIN_HOST=${SPAMASSASSIN_HOST}" >> "$ENV_FILE"

# Analytics & Integrations
[ -n "$HCAPTCHA_SECRET" ] && echo "HCAPTCHA_SECRET=${HCAPTCHA_SECRET}" >> "$ENV_FILE"
[ -n "$HCAPTCHA_SITEKEY" ] && echo "HCAPTCHA_SITEKEY=${HCAPTCHA_SITEKEY}" >> "$ENV_FILE"
[ -n "$PLAUSIBLE_HOST" ] && echo "PLAUSIBLE_HOST=${PLAUSIBLE_HOST}" >> "$ENV_FILE"
[ -n "$PLAUSIBLE_DOMAIN" ] && echo "PLAUSIBLE_DOMAIN=${PLAUSIBLE_DOMAIN}" >> "$ENV_FILE"
[ -n "$SENTRY_DSN" ] && echo "SENTRY_DSN=${SENTRY_DSN}" >> "$ENV_FILE"
[ -n "$SENTRY_FRONT_END_DSN" ] && echo "SENTRY_FRONT_END_DSN=${SENTRY_FRONT_END_DSN}" >> "$ENV_FILE"
[ -n "$FLASK_PROFILER_PATH" ] && echo "FLASK_PROFILER_PATH=${FLASK_PROFILER_PATH}" >> "$ENV_FILE"
[ -n "$FLASK_PROFILER_PASSWORD" ] && echo "FLASK_PROFILER_PASSWORD=${FLASK_PROFILER_PASSWORD}" >> "$ENV_FILE"
[ -n "$HIBP_SCAN_INTERVAL_DAYS" ] && echo "HIBP_SCAN_INTERVAL_DAYS=${HIBP_SCAN_INTERVAL_DAYS}" >> "$ENV_FILE"
[ -n "$HIBP_API_KEYS" ] && echo "HIBP_API_KEYS=${HIBP_API_KEYS}" >> "$ENV_FILE"

# AWS Storage (If LOCAL_FILE_UPLOAD is overridden)
[ -n "$BUCKET" ] && echo "BUCKET=${BUCKET}" >> "$ENV_FILE"
[ -n "$AWS_ACCESS_KEY_ID" ] && echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> "$ENV_FILE"
[ -n "$AWS_SECRET_ACCESS_KEY" ] && echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> "$ENV_FILE"
[ -n "$AWS_REGION" ] && echo "AWS_REGION=${AWS_REGION}" >> "$ENV_FILE"

# Paddle Billing (SaaS only)
[ -n "$PADDLE_VENDOR_ID" ] && echo "PADDLE_VENDOR_ID=${PADDLE_VENDOR_ID}" >> "$ENV_FILE"
[ -n "$PADDLE_MONTHLY_PRODUCT_ID" ] && echo "PADDLE_MONTHLY_PRODUCT_ID=${PADDLE_MONTHLY_PRODUCT_ID}" >> "$ENV_FILE"
[ -n "$PADDLE_YEARLY_PRODUCT_ID" ] && echo "PADDLE_YEARLY_PRODUCT_ID=${PADDLE_YEARLY_PRODUCT_ID}" >> "$ENV_FILE"
[ -n "$PADDLE_PUBLIC_KEY_PATH" ] && echo "PADDLE_PUBLIC_KEY_PATH=${PADDLE_PUBLIC_KEY_PATH}" >> "$ENV_FILE"
[ -n "$PADDLE_AUTH_CODE" ] && echo "PADDLE_AUTH_CODE=${PADDLE_AUTH_CODE}" >> "$ENV_FILE"

# Coinbase Billing (SaaS only)
[ -n "$COINBASE_WEBHOOK_SECRET" ] && echo "COINBASE_WEBHOOK_SECRET=${COINBASE_WEBHOOK_SECRET}" >> "$ENV_FILE"
[ -n "$COINBASE_CHECKOUT_ID" ] && echo "COINBASE_CHECKOUT_ID=${COINBASE_CHECKOUT_ID}" >> "$ENV_FILE"
[ -n "$COINBASE_API_KEY" ] && echo "COINBASE_API_KEY=${COINBASE_API_KEY}" >> "$ENV_FILE"
[ -n "$COINBASE_YEARLY_PRICE" ] && echo "COINBASE_YEARLY_PRICE=${COINBASE_YEARLY_PRICE}" >> "$ENV_FILE"

# Secure permissions on .env
chmod 600 "$ENV_FILE"

echo -e "${GREEN}Successfully generated ${ENV_FILE}${NC}"
