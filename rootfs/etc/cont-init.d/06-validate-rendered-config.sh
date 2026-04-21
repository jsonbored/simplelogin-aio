#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

# trunk-ignore(shellcheck/SC1091)
source /etc/simplelogin-aio/env-helpers.sh

echo "Validating rendered SimpleLogin configuration before starting services..."

if ! python3 /etc/simplelogin-aio/validate-config.py \
	--env-file /code/.env \
	--import-upstream-config; then
	echo "Fatal rendered-config validation failure. Stopping container before long-running services start." >&2
	kill -TERM 1
	sleep 5
	exit 1
fi
