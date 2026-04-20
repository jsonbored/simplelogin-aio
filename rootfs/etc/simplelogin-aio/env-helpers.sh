#!/usr/bin/env bash
# shellcheck shell=bash

SIMPLELOGIN_ENV_DIR="${SIMPLELOGIN_ENV_DIR:-/var/run/s6/container_environment}"

sync_env_value() {
	local name="$1"
	local value="$2"

	export "${name}=${value}"
	if [[ -d ${SIMPLELOGIN_ENV_DIR} ]]; then
		printf '%s' "${value}" >"${SIMPLELOGIN_ENV_DIR}/${name}"
	fi
}

remove_env_value() {
	local name="$1"

	unset "${name}"
	if [[ -d ${SIMPLELOGIN_ENV_DIR} ]]; then
		rm -f "${SIMPLELOGIN_ENV_DIR}/${name}"
	fi
}

is_truthy_env_value() {
	local value="${1-}"
	case "${value,,}" in
	1 | true | yes | on | enabled) return 0 ;;
	*) return 1 ;;
	esac
}

normalize_presence_env_var() {
	local name="$1"
	local current="${!name-}"

	if is_truthy_env_value "${current}"; then
		sync_env_value "${name}" "1"
	else
		remove_env_value "${name}"
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
		ZENDESK_ENABLED; do
		normalize_presence_env_var "${var_name}"
	done
}

normalize_blank_env_var() {
	local name="$1"

	if [[ ${!name+x} == x ]] && [[ -z ${!name} ]]; then
		remove_env_value "${name}"
	fi
}

normalize_simplelogin_blank_sensitive_env_vars() {
	local var_name
	for var_name in \
		ADMIN_FIDO_REQUIRED \
		ADMIN_GRACE_PERIOD \
		ALIAS_DOMAINS \
		ALIAS_RAND_SUFFIX_LENGTH \
		ALLOWED_REDIRECT_DOMAINS \
		ALIAS_TRASH_DAYS \
		AUDIT_LOG_MAX_DAYS \
		EMAIL_SERVERS_WITH_PRIORITY \
		HIBP_API_KEYS \
		HIBP_API_RPM \
		HIBP_SCAN_INTERVAL_DAYS \
		MAX_API_KEYS \
		MAX_BOUNCES_1D \
		MAX_BOUNCES_1W \
		MAX_EMAIL_FORWARD_RECIPIENTS \
		MAX_NB_EMAIL_OLD_FREE_PLAN \
		MIN_RSPAMD_SCORE_FOR_FAILED_DMARC \
		OTHER_ALIAS_DOMAINS \
		PADDLE_MONTHLY_PRODUCT_IDS \
		PADDLE_YEARLY_PRODUCT_IDS \
		POSTFIX_CONNECT_TIMEOUT \
		POSTFIX_PORT \
		POSTFIX_TIMEOUT \
		PREMIUM_ALIAS_DOMAINS \
		SENTRY_TRACE_RATE \
		SMTP_SIZE_LIMIT; do
		normalize_blank_env_var "${var_name}"
	done
}

normalize_simplelogin_compat_env_vars() {
	case "${ADMIN_FIDO_REQUIRED-}" in
	"" | "none")
		remove_env_value "ADMIN_FIDO_REQUIRED"
		;;
	\|none\|any\|hardware | none\|any\|hardware)
		sync_env_value "ADMIN_FIDO_REQUIRED" "none"
		;;
	*)
		:
		;;
	esac
}

run_with_simplelogin_sanitized_env() {
	case "${ADMIN_FIDO_REQUIRED-}" in
	"" | "none" | \|none\|any\|hardware | none\|any\|hardware)
		ADMIN_FIDO_REQUIRED=none "$@"
		;;
	*)
		"$@"
		;;
	esac
}

exec_with_simplelogin_sanitized_env() {
	case "${ADMIN_FIDO_REQUIRED-}" in
	"" | "none" | \|none\|any\|hardware | none\|any\|hardware)
		exec env ADMIN_FIDO_REQUIRED=none "$@"
		;;
	*)
		exec "$@"
		;;
	esac
}

run_as_simplelogin_with_sanitized_env() {
	case "${ADMIN_FIDO_REQUIRED-}" in
	"" | "none" | \|none\|any\|hardware | none\|any\|hardware)
		env ADMIN_FIDO_REQUIRED=none s6-setuidgid simplelogin "$@"
		;;
	*)
		s6-setuidgid simplelogin "$@"
		;;
	esac
}

exec_as_simplelogin_with_sanitized_env() {
	case "${ADMIN_FIDO_REQUIRED-}" in
	"" | "none" | \|none\|any\|hardware | none\|any\|hardware)
		exec env ADMIN_FIDO_REQUIRED=none s6-setuidgid simplelogin "$@"
		;;
	*)
		exec s6-setuidgid simplelogin "$@"
		;;
	esac
}

escape_configparser_value() {
	local value="${1-}"
	printf '%s' "${value//%/%%}"
}

uri_host_is_loopback() {
	local uri="$1"

	URI_TO_PARSE="${uri}" python3 <<'PY'
import ipaddress
import os
from urllib.parse import urlparse

uri = os.environ["URI_TO_PARSE"]
hostname = urlparse(uri).hostname

if not hostname:
    raise SystemExit(1)

if hostname.lower() == "localhost":
    raise SystemExit(0)

try:
    if ipaddress.ip_address(hostname).is_loopback:
        raise SystemExit(0)
except (ValueError, TypeError):
    pass

raise SystemExit(1)
PY
}
