#!/command/with-contenv bash
# ==============================================================================
# 04-configure-postfix.sh
# Purpose: Dynamically configures Postfix main.cf and pgsql maps based on the
# SimpleLogin domains and SMTP Relay Modes chosen by the user in Unraid.
# ==============================================================================

echo "Configuring Postfix MTA routing..."

# Ensure we have our internal DB credentials
if [ -f /appdata/postgres/.sl_internal_pass ]; then
    PG_PASS=$(cat /appdata/postgres/.sl_internal_pass)
    PG_USER="simplelogin"
    PG_HOST="127.0.0.1"
    PG_DB="simplelogin"
elif [ -n "$DB_URI" ]; then
    # Parse external DB_URI (postgresql://user:pass@host:port/db)
    # Basic extraction for mapped use (fallback)
    PG_USER=$(echo "$DB_URI" | sed -n 's/.*:\/\/\([^:]*\).*/\1/p')
    PG_PASS=$(echo "$DB_URI" | sed -n 's/.*:\/\/[^:]*:\([^@]*\).*/\1/p')
    PG_HOST=$(echo "$DB_URI" | sed -n 's/.*@\([^:]*\).*/\1/p')
    PG_DB=$(echo "$DB_URI" | sed -n 's/.*\/\([^?]*\).*/\1/p')
fi

# Write pgsql mapping files so Postfix can query aliases instantly
cat << EOM > /etc/postfix/pgsql-virtual-mailbox-domains.cf
user = $PG_USER
password = $PG_PASS
hosts = $PG_HOST
dbname = $PG_DB
query = SELECT 1 FROM custom_domain WHERE domain = '%s' AND verified = true UNION SELECT 1 FROM alias WHERE domain = '%s' LIMIT 1;
EOM

cat << EOM > /etc/postfix/pgsql-virtual-mailbox-maps.cf
user = $PG_USER
password = $PG_PASS
hosts = $PG_HOST
dbname = $PG_DB
query = SELECT 1 FROM alias WHERE email = '%s' LIMIT 1;
EOM

cat << EOM > /etc/postfix/pgsql-virtual-alias-maps.cf
user = $PG_USER
password = $PG_PASS
hosts = $PG_HOST
dbname = $PG_DB
query = SELECT target_address FROM alias_route WHERE alias_id = (SELECT id FROM alias WHERE email = '%s') AND target_status = 'verified';
EOM

chmod 640 /etc/postfix/pgsql-*.cf
chown postfix:postfix /etc/postfix/pgsql-*.cf

# Configure main.cf
postconf -e "myhostname = mail.${EMAIL_DOMAIN}"
postconf -e "mydestination = localhost"
postconf -e "virtual_transport = lmtp:127.0.0.1:20381"
postconf -e "virtual_mailbox_domains = pgsql:/etc/postfix/pgsql-virtual-mailbox-domains.cf"
postconf -e "virtual_mailbox_maps = pgsql:/etc/postfix/pgsql-virtual-mailbox-maps.cf"
postconf -e "virtual_alias_maps = pgsql:/etc/postfix/pgsql-virtual-alias-maps.cf"

# ------------------------------------------------------------------------------
# RELAY MODE CONFIGURATION (Bypassing ISP Port 25 Blocks)
# ------------------------------------------------------------------------------
echo "Applying SMTP Relay configurations..."

# Clear existing sasl_passwd to prevent stale data
> /etc/postfix/sasl_passwd

case "$RELAY_MODE" in
    "direct")
        echo "Using DIRECT delivery (Assuming outbound port 25 is open)."
        postconf -X "relayhost"
        ;;
    "brevo")
        echo "Using BREVO relay..."
        postconf -e "relayhost = [smtp-relay.brevo.com]:587"
        echo "[smtp-relay.brevo.com]:587 $BREVO_USERNAME:$BREVO_PASSWORD" > /etc/postfix/sasl_passwd
        ;;
    "protonmail")
        echo "Using PROTONMAIL relay..."
        postconf -e "relayhost = [127.0.0.1]:1025" # Assuming user runs Proton bridge
        echo "[127.0.0.1]:1025 $SUPPORT_EMAIL:$PROTONMAIL_TOKEN" > /etc/postfix/sasl_passwd
        ;;
    "gmail")
        echo "Using GMAIL relay..."
        postconf -e "relayhost = [smtp.gmail.com]:587"
        echo "[smtp.gmail.com]:587 $GMAIL_USERNAME:$GMAIL_APP_PASSWORD" > /etc/postfix/sasl_passwd
        ;;
    "mailgun")
        echo "Using MAILGUN relay..."
        postconf -e "relayhost = [smtp.mailgun.org]:587"
        echo "[smtp.mailgun.org]:587 $MAILGUN_USERNAME:$MAILGUN_PASSWORD" > /etc/postfix/sasl_passwd
        ;;
    "custom")
        echo "Using CUSTOM relay..."
        postconf -e "relayhost = $CUSTOM_RELAYHOST"
        echo "$CUSTOM_RELAYHOST $CUSTOM_USERNAME:$CUSTOM_PASSWORD" > /etc/postfix/sasl_passwd
        ;;
esac

if [ "$RELAY_MODE" != "direct" ]; then
    postconf -e "smtp_sasl_auth_enable = yes"
    postconf -e "smtp_sasl_security_options = noanonymous"
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_tls_security_level = encrypt"
    postmap /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
fi

echo "Postfix configuration complete."
