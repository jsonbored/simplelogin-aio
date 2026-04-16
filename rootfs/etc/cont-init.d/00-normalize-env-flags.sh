#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

ENV_DIR="/var/run/s6/container_environment"
source /etc/simplelogin-aio/env-helpers.sh

normalize_presence_var() {
    local name="$1"
    local current="${!name:-}"

    if is_truthy_env_value "$current"; then
        printf '1\n' > "${ENV_DIR}/${name}"
    else
        rm -f "${ENV_DIR}/${name}"
    fi
}

for var_name in \
    ALIAS_AUTOMATIC_DISABLE \
    APPLE_WEBHOOK_SECRET_CHECK_ENABLED \
    COLOR_LOG \
    CONNECT_WITH_PROTON \
    DISABLE_ALIAS_SUFFIX \
    DISABLE_ONBOARDING \
    DISABLE_RATE_LIMIT \
    DISABLE_REGISTRATION \
    DMARC_CHECK_ENABLED \
    DROP_PGP_KEY_ATTACHMENTS_ON_REPLY \
    ENABLE_ALL_REVERSE_ALIAS_REPLACEMENT \
    ENABLE_SPAM_ASSASSIN \
    ENFORCE_SPF \
    EVENT_WEBHOOK_DISABLE \
    EVENT_WEBHOOK_SKIP_VERIFY_SSL \
    LOAD_PGP_EMAIL_HANDLER \
    LOCAL_FILE_UPLOAD \
    NOT_SEND_EMAIL \
    POSTFIX_SUBMISSION_TLS \
    PROTON_PREVENT_CHANGE_LINKED_ACCOUNT \
    PROTON_VALIDATE_CERTS \
    RSPAMD_SIGN_DKIM \
    STORE_TRANSACTIONAL_EMAILS \
    USE_RUST_PGP \
    ZENDESK_ENABLED
do
    normalize_presence_var "$var_name"
done
