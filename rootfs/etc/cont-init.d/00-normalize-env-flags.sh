#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

source /etc/simplelogin-aio/env-helpers.sh

normalize_simplelogin_blank_sensitive_env_vars
normalize_simplelogin_compat_env_vars
normalize_simplelogin_presence_env_vars
