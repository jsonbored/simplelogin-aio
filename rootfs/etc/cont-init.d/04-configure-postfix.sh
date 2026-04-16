#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

echo "Configuring Postfix MTA routing..."

DB_URI_VALUE="${DB_URI:-$(cat /var/run/s6/container_environment/DB_URI 2>/dev/null || true)}"

if [ -f /appdata/postgres/.sl_internal_pass ]; then
    PG_PASS=$(cat /appdata/postgres/.sl_internal_pass)
    PG_USER="simplelogin"
    PG_HOST="127.0.0.1"
    PG_DB="simplelogin"
elif [ -n "$DB_URI_VALUE" ]; then
    PG_USER=$(echo "$DB_URI_VALUE" | sed -E 's|.*://([^:/]+).*|\1|')
    PG_PASS=$(echo "$DB_URI_VALUE" | sed -E 's|.*://[^:]+:([^@]+)@.*|\1|')
    PG_HOST=$(echo "$DB_URI_VALUE" | sed -E 's|.*@([^:/]+).*|\1|')
    PG_DB=$(echo "$DB_URI_VALUE" | sed -E 's|.*/([^/?]+).*|\1|')
else
    echo "Unable to determine PostgreSQL settings for Postfix."
    exit 1
fi

cat >/etc/postfix/pgsql-relay-domains.cf <<EOF
user = $PG_USER
password = $PG_PASS
hosts = $PG_HOST
dbname = $PG_DB
query = SELECT domain FROM custom_domain WHERE domain = '%s' AND verified = true
    UNION SELECT '%s' WHERE '%s' = '${EMAIL_DOMAIN}' LIMIT 1;
EOF

cat >/etc/postfix/pgsql-transport-maps.cf <<EOF
user = $PG_USER
password = $PG_PASS
hosts = $PG_HOST
dbname = $PG_DB
query = SELECT 'smtp:127.0.0.1:20381' FROM custom_domain WHERE domain = '%s' AND verified = true
    UNION SELECT 'smtp:127.0.0.1:20381' WHERE '%s' = '${EMAIL_DOMAIN}' LIMIT 1;
EOF

chmod 640 /etc/postfix/pgsql-*.cf
chown postfix:postfix /etc/postfix/pgsql-*.cf

if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ] || [ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]; then
    mkdir -p /etc/ssl/private /etc/ssl/certs
    openssl req -x509 -nodes -days 3650 -subj "/CN=mail.${EMAIL_DOMAIN}" \
        -newkey rsa:2048 \
        -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
        -out /etc/ssl/certs/ssl-cert-snakeoil.pem >/dev/null 2>&1
fi

postconf -e "compatibility_level = 2"
postconf -e "myhostname = mail.${EMAIL_DOMAIN}"
postconf -e "mydomain = ${EMAIL_DOMAIN}"
postconf -e "myorigin = ${EMAIL_DOMAIN}"
postconf -e "mydestination ="
postconf -e "inet_interfaces = all"
postconf -e "alias_maps = hash:/etc/aliases"
postconf -e "relay_domains = pgsql:/etc/postfix/pgsql-relay-domains.cf"
postconf -e "transport_maps = pgsql:/etc/postfix/pgsql-transport-maps.cf"
postconf -e "mynetworks = 127.0.0.0/8 [::1]/128"
postconf -e "smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem"
postconf -e "smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key"
postconf -e "smtp_tls_security_level = may"
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtpd_delay_reject = yes"
postconf -e "smtpd_helo_required = yes"
postconf -e "smtpd_helo_restrictions = permit_mynetworks,reject_non_fqdn_helo_hostname,reject_invalid_helo_hostname,permit"
postconf -e "smtpd_sender_restrictions = permit_mynetworks,reject_non_fqdn_sender,reject_unknown_sender_domain,permit"
postconf -e "smtpd_recipient_restrictions = reject_unauth_pipelining,reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_mynetworks,reject_unauth_destination,permit"

echo "Applying SMTP relay configuration..."
: > /etc/postfix/sasl_passwd

case "${RELAY_MODE:-direct}" in
    direct)
        postconf -X "relayhost"
        ;;
    brevo)
        postconf -e "relayhost = [smtp-relay.brevo.com]:587"
        echo "[smtp-relay.brevo.com]:587 ${BREVO_USERNAME}:${BREVO_PASSWORD}" > /etc/postfix/sasl_passwd
        ;;
    protonmail)
        postconf -e "relayhost = [smtp.protonmail.ch]:587"
        echo "[smtp.protonmail.ch]:587 ${SUPPORT_EMAIL}:${PROTONMAIL_TOKEN}" > /etc/postfix/sasl_passwd
        ;;
    gmail)
        postconf -e "relayhost = [smtp.gmail.com]:587"
        echo "[smtp.gmail.com]:587 ${GMAIL_USERNAME}:${GMAIL_APP_PASSWORD}" > /etc/postfix/sasl_passwd
        ;;
    mailgun)
        postconf -e "relayhost = [smtp.mailgun.org]:587"
        echo "[smtp.mailgun.org]:587 ${MAILGUN_USERNAME}:${MAILGUN_PASSWORD}" > /etc/postfix/sasl_passwd
        ;;
    custom)
        postconf -e "relayhost = ${CUSTOM_RELAYHOST}"
        echo "${CUSTOM_RELAYHOST} ${CUSTOM_USERNAME}:${CUSTOM_PASSWORD}" > /etc/postfix/sasl_passwd
        ;;
esac

if [ "${RELAY_MODE:-direct}" != "direct" ]; then
    postconf -e "smtp_sasl_auth_enable = yes"
    postconf -e "smtp_sasl_security_options = noanonymous"
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_tls_security_level = encrypt"
    postmap /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
fi

newaliases >/dev/null 2>&1 || true
echo "Postfix configuration complete."
