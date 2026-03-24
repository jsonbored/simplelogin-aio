#!/command/with-contenv bash
# ==============================================================================
# 05-generate-jwt.sh
# Purpose: Auto-generates OpenID Connect RS256 JWT keys if the user enables
# SimpleLogin as an Identity Provider (SSO).
# ==============================================================================

CYAN='\033[1;36m'
GREEN='\033[0;32m'
NC='\033[0m'

JWT_DIR="/appdata/sl"
PRIVATE_KEY_FILE="${JWT_DIR}/jwtRS256.key"
PUBLIC_KEY_FILE="${JWT_DIR}/jwtRS256.key.pub"

if [ "${ENABLE_OIDC_SERVER}" = "1" ]; then
    echo -e "${CYAN}OIDC Server enabled. Checking for JWT Keys...${NC}"
    
    mkdir -p "$JWT_DIR"
    chmod 700 "$JWT_DIR"

    if [ ! -f "$PRIVATE_KEY_FILE" ]; then
        echo "Generating secure RS256 JWT Keypair for OpenID Connect..."
        # Generate private key
        openssl genrsa -out "$PRIVATE_KEY_FILE" 2048 >/dev/null 2>&1
        # Extract public key
        openssl rsa -in "$PRIVATE_KEY_FILE" -pubout -out "$PUBLIC_KEY_FILE" >/dev/null 2>&1
        chmod 600 "$PRIVATE_KEY_FILE"
        echo -e "${GREEN}JWT keys generated successfully.${NC}"
    else
        echo "Existing JWT keys found. Skipping generation."
    fi

    # Export environmental variable so 03-write-env.sh picks it up
    echo "$PRIVATE_KEY_FILE" > /var/run/s6/container_environment/OPENID_PRIVATE_KEY_PATH
    echo "$PUBLIC_KEY_FILE" > /var/run/s6/container_environment/OPENID_PUBLIC_KEY_PATH
fi
