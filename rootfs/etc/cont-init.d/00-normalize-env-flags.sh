#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

# trunk-ignore(shellcheck/SC1091)
source /etc/simplelogin-aio/env-helpers.sh

echo "Validating raw SimpleLogin container environment before normalization..."

if ! python3 /etc/simplelogin-aio/validate-config.py --validate-current-env; then
	echo "Fatal raw-env validation failure. Stopping container before normalization or long-running services start." >&2
	kill -TERM 1
	sleep 5
	exit 1
fi

normalize_simplelogin_blank_sensitive_env_vars
normalize_simplelogin_compat_env_vars
normalize_simplelogin_presence_env_vars
