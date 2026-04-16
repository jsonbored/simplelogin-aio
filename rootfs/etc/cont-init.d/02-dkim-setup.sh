#!/command/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# 02-dkim-setup.sh
# Purpose: Auto-generates DKIM (DomainKeys Identified Mail) keys if they do not exist.
# Sets correct permissions, extracts the public key payload, and formats the DNS
# TXT record to easily copy-paste into Cloudflare or Route53.
# ==============================================================================

# ANSI Color Codes for readability
CYAN='\033[1;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DKIM_DIR="/appdata/dkim"
PRIVATE_KEY="$DKIM_DIR/dkim.key"
PUBLIC_KEY="$DKIM_DIR/dkim.pub.key"
DNS_RECORD_FILE="$DKIM_DIR/dkim-dns-record.txt"

echo -e "${CYAN}Checking DKIM keys...${NC}"

# Ensure directory exists
mkdir -p "$DKIM_DIR"

if [ -f "$PRIVATE_KEY" ]; then
    echo -e "${GREEN}DKIM keys found at $PRIVATE_KEY. Skipping generation.${NC}"
else
    echo -e "${YELLOW}No DKIM keys found. Generating new 2048-bit RSA key pair...${NC}"
    
    # Generate private key
    if ! openssl genrsa -out "$PRIVATE_KEY" 2048 2>/dev/null; then
        echo -e "${RED}[ERROR] Failed to generate DKIM private key!${NC}"
        exit 1
    fi
    
    # Set strict permissions
    chmod 600 "$PRIVATE_KEY"
    
    # Extract public key
    if ! openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY" 2>/dev/null; then
        echo -e "${RED}[ERROR] Failed to extract DKIM public key!${NC}"
        exit 1
    fi
    
    # Strip headers, footers, and newlines from public key to construct the DNS record value
    RAW_PUBKEY=$(grep -v '^-' "$PUBLIC_KEY" | tr -d '\n')
    DKIM_DNS_VALUE="v=DKIM1; k=rsa; p=$RAW_PUBKEY"
    DKIM_DNS_NAME="dkim._domainkey.$EMAIL_DOMAIN"
    
    # Save to file
    echo "Host/Name: $DKIM_DNS_NAME" > "$DNS_RECORD_FILE"
    echo "Value:     $DKIM_DNS_VALUE" >> "$DNS_RECORD_FILE"
    
    echo -e "${GREEN}DKIM key generation successful!${NC}"
    echo -e "================================================================================"
    echo -e "IMPORTANT! You must add the following TXT record to your DNS provider:"
    echo -e "================================================================================"
    echo -e "${CYAN}Type:  TXT${NC}"
    echo -e "${CYAN}Name:  $DKIM_DNS_NAME${NC}"
    echo -e "${CYAN}Value: $DKIM_DNS_VALUE${NC}"
    echo -e "================================================================================"
    echo -e "A copy of this record has been saved to $DNS_RECORD_FILE"
fi

# Create symlinks at root for easy reference in write-env.sh and backward compatibility
echo -e "${CYAN}Symlinking DKIM keys to root...${NC}"
ln -sf "$PRIVATE_KEY" "/dkim.key"
ln -sf "$PUBLIC_KEY" "/dkim.pub.key"

# Ensure symlinks succeeded
if [ ! -L "/dkim.key" ]; then
    echo -e "${RED}[ERROR] Failed to symlink DKIM private key!${NC}"
    exit 1
fi

echo -e "${GREEN}DKIM setup complete.${NC}"
