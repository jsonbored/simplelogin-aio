#!/command/with-contenv bash
# shellcheck shell=bash
source /etc/simplelogin-aio/env-helpers.sh

PGP_DIR="/pgp"
PRIVATE_KEY_FILE="${PGP_DIR}/server_private_key.asc"
PUBLIC_KEY_FILE="${PGP_DIR}/server_public_key.asc"

if [ "${AUTO_GENERATE_PGP}" = "1" ]; then
    echo "PGP Auto-Generation requested..."
    
    mkdir -p "$PGP_DIR"
    chmod 700 "$PGP_DIR"

    if [ ! -f "$PRIVATE_KEY_FILE" ]; then
        echo "No existing PGP Server Key found. Generating a secure 4096-bit RSA keypair..."
        
        KEY_EMAIL="${POSTMASTER:-postmaster@$EMAIL_DOMAIN}"
        KEY_NAME="${SUPPORT_NAME:-SimpleLogin Postmaster}"

        cat > /tmp/gpg_batch << EOL
%echo Generating SimpleLogin Server Key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${KEY_NAME}
Name-Email: ${KEY_EMAIL}
Expire-Date: 0
%no-protection
%commit
%echo done
EOL

        TEMP_GPG_HOME=$(mktemp -d)
        gpg --batch --homedir "$TEMP_GPG_HOME" --gen-key /tmp/gpg_batch >/dev/null 2>&1
        
        gpg --homedir "$TEMP_GPG_HOME" --armor --export-secret-keys "$KEY_EMAIL" > "$PRIVATE_KEY_FILE"
        gpg --homedir "$TEMP_GPG_HOME" --armor --export "$KEY_EMAIL" > "$PUBLIC_KEY_FILE"
        
        rm -rf "$TEMP_GPG_HOME" /tmp/gpg_batch

        echo "======================================================================"
        echo " SUCCESS: Server PGP Key Generated! "
        echo "======================================================================"
        echo " IMPORT THIS PUBLIC KEY INTO YOUR MAIL CLIENT (Proton/Apple/Thunderbird)"
        cat "$PUBLIC_KEY_FILE"
        echo "======================================================================"
    else
        echo "Existing PGP Server Key found at ${PRIVATE_KEY_FILE}. Skipping generation."
    fi

    sync_env_value "PGP_SENDER_PRIVATE_KEY_PATH" "$PRIVATE_KEY_FILE"
else
    echo "PGP Auto-Generation disabled. Skipping server key creation."
fi
