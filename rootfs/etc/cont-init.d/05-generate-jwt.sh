#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail
# trunk-ignore(shellcheck/SC1091)
source /etc/simplelogin-aio/env-helpers.sh

CYAN='\033[1;36m'
GREEN='\033[0;32m'
NC='\033[0m'

JWT_DIR="/appdata/sl"
PRIVATE_KEY_FILE="${JWT_DIR}/jwtRS256.key"
PUBLIC_KEY_FILE="${JWT_DIR}/jwtRS256.key.pub"

if [[ ${ENABLE_OIDC_SERVER:-0} == "1" ]]; then
	echo -e "${CYAN}OIDC Server enabled. Checking for JWT Keys...${NC}"

	mkdir -p "${JWT_DIR}"
	chmod 700 "${JWT_DIR}"
	chown simplelogin:simplelogin "${JWT_DIR}"

	if [[ ! -f ${PRIVATE_KEY_FILE} ]]; then
		echo "Generating secure RS256 JWT Keypair for OpenID Connect..."
		openssl genrsa -out "${PRIVATE_KEY_FILE}" 2048 >/dev/null 2>&1
		openssl rsa -in "${PRIVATE_KEY_FILE}" -pubout -out "${PUBLIC_KEY_FILE}" >/dev/null 2>&1
		chmod 600 "${PRIVATE_KEY_FILE}"
		chmod 644 "${PUBLIC_KEY_FILE}"
		chown simplelogin:simplelogin "${PRIVATE_KEY_FILE}" "${PUBLIC_KEY_FILE}"
		echo -e "${GREEN}JWT keys generated successfully.${NC}"
	else
		echo "Existing JWT keys found. Skipping generation."
	fi

	sync_env_value "OPENID_PRIVATE_KEY_PATH" "${PRIVATE_KEY_FILE}"
	sync_env_value "OPENID_PUBLIC_KEY_PATH" "${PUBLIC_KEY_FILE}"
fi
