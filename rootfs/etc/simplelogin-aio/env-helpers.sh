#!/usr/bin/env bash
# shellcheck shell=bash

is_truthy_env_value() {
    local value="${1:-}"
    case "${value,,}" in
        1|true|yes|on|enabled) return 0 ;;
        *) return 1 ;;
    esac
}

normalize_presence_env_var() {
    local name="$1"
    local current="${!name:-}"

    if is_truthy_env_value "$current"; then
        export "$name=1"
    else
        unset "$name"
    fi
}

normalize_simplelogin_presence_env_vars() {
    local var_name
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
        normalize_presence_env_var "$var_name"
    done
}

escape_configparser_value() {
    local value="${1:-}"
    printf '%s' "${value//%/%%}"
}
