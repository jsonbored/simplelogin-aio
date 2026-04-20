#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${1:-simplelogin-aio:test}"
BASE_HTTP_PORT="${BASE_HTTP_PORT:-57800}"
BASE_SMTP_PORT="${BASE_SMTP_PORT:-52800}"
READY_TIMEOUT_SECONDS="${READY_TIMEOUT_SECONDS:-420}"

NETWORK_NAME="simplelogin-aio-runtime-matrix"
POSTGRES_NAME="simplelogin-aio-ext-postgres"
REDIS_NAME="simplelogin-aio-ext-redis"
CASE_INDEX=0
CONTAINER_NAME=""
TMP_APPDATA=""
TMP_PGP=""

cleanup_external_services() {
  docker rm -f "$POSTGRES_NAME" "$REDIS_NAME" >/dev/null 2>&1 || true
  docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
}

cleanup_case() {
  if [ -n "$CONTAINER_NAME" ]; then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_APPDATA" "$TMP_PGP"
  CONTAINER_NAME=""
  TMP_APPDATA=""
  TMP_PGP=""
}

cleanup_all() {
  cleanup_case
  cleanup_external_services
}

trap cleanup_all EXIT

wait_for_http() {
  local deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
  while (( SECONDS < deadline )); do
    if curl -fsS "http://127.0.0.1:${HOST_HTTP_PORT}/health" >/dev/null; then
      return 0
    fi
    docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"
    sleep 2
  done
  echo "Case '$CASE_NAME' did not become HTTP healthy in time." >&2
  docker logs "$CONTAINER_NAME" || true
  return 1
}

wait_for_smtp() {
  local deadline=$((SECONDS + 120))
  while (( SECONDS < deadline )); do
    if nc -z 127.0.0.1 "$HOST_SMTP_PORT" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "Case '$CASE_NAME' did not expose SMTP in time." >&2
  docker logs "$CONTAINER_NAME" || true
  return 1
}

start_case() {
  CASE_NAME="$1"
  shift

  CASE_INDEX=$((CASE_INDEX + 1))
  HOST_HTTP_PORT=$((BASE_HTTP_PORT + CASE_INDEX))
  HOST_SMTP_PORT=$((BASE_SMTP_PORT + CASE_INDEX))
  CONTAINER_NAME="simplelogin-aio-matrix-${CASE_INDEX}"
  TMP_APPDATA="$(mktemp -d "/tmp/${CONTAINER_NAME}-appdata.XXXXXX")"
  TMP_PGP="$(mktemp -d "/tmp/${CONTAINER_NAME}-pgp.XXXXXX")"

  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker run -d \
    --platform linux/amd64 \
    --name "$CONTAINER_NAME" \
    -p "${HOST_HTTP_PORT}:7777" \
    -p "${HOST_SMTP_PORT}:25" \
    -e URL="http://127.0.0.1:${HOST_HTTP_PORT}" \
    -e EMAIL_DOMAIN="example.com" \
    -e SUPPORT_EMAIL="support@example.com" \
    -e FLASK_SECRET="0123456789abcdef0123456789abcdef" \
    -e RELAY_MODE="direct" \
    -e NOT_SEND_EMAIL="true" \
    -e POSTMASTER="postmaster@example.com" \
    -v "${TMP_APPDATA}:/appdata" \
    -v "${TMP_PGP}:/pgp" \
    "$@" \
    "$IMAGE_TAG" >/dev/null
}

run_case() {
  local case_name="$1"
  local verify_cmd="$2"
  shift 2

  echo "==> ${case_name}"
  start_case "$case_name" "$@"
  wait_for_http
  wait_for_smtp
  if [ -n "$verify_cmd" ]; then
    docker exec "$CONTAINER_NAME" sh -lc "$verify_cmd"
  fi
  cleanup_case
}

start_external_services() {
  cleanup_external_services
  docker network create "$NETWORK_NAME" >/dev/null

  docker run -d \
    --platform linux/amd64 \
    --name "$POSTGRES_NAME" \
    --network "$NETWORK_NAME" \
    -e POSTGRES_DB="simplelogin" \
    -e POSTGRES_USER="simplelogin" \
    -e POSTGRES_PASSWORD="simpleloginpass" \
    postgres:14 >/dev/null

  docker run -d \
    --platform linux/amd64 \
    --name "$REDIS_NAME" \
    --network "$NETWORK_NAME" \
    redis:6 >/dev/null

  local deadline=$((SECONDS + 120))
  while (( SECONDS < deadline )); do
    if docker exec "$POSTGRES_NAME" pg_isready -U simplelogin -d simplelogin >/dev/null 2>&1 \
      && docker exec "$REDIS_NAME" redis-cli ping >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "External PostgreSQL/Redis test services did not become ready in time." >&2
  docker logs "$POSTGRES_NAME" || true
  docker logs "$REDIS_NAME" || true
  return 1
}

run_external_services_case() {
  echo "==> external-db-redis"
  start_external_services
  CASE_INDEX=$((CASE_INDEX + 1))
  HOST_HTTP_PORT=$((BASE_HTTP_PORT + CASE_INDEX))
  HOST_SMTP_PORT=$((BASE_SMTP_PORT + CASE_INDEX))
  CONTAINER_NAME="simplelogin-aio-matrix-${CASE_INDEX}"
  TMP_APPDATA="$(mktemp -d "/tmp/${CONTAINER_NAME}-appdata.XXXXXX")"
  TMP_PGP="$(mktemp -d "/tmp/${CONTAINER_NAME}-pgp.XXXXXX")"

  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker run -d \
    --platform linux/amd64 \
    --name "$CONTAINER_NAME" \
    --network "$NETWORK_NAME" \
    -p "${HOST_HTTP_PORT}:7777" \
    -p "${HOST_SMTP_PORT}:25" \
    -e URL="http://127.0.0.1:${HOST_HTTP_PORT}" \
    -e EMAIL_DOMAIN="example.com" \
    -e SUPPORT_EMAIL="support@example.com" \
    -e FLASK_SECRET="0123456789abcdef0123456789abcdef" \
    -e RELAY_MODE="direct" \
    -e NOT_SEND_EMAIL="true" \
    -e POSTMASTER="postmaster@example.com" \
    -e DB_URI="postgresql://simplelogin:simpleloginpass@${POSTGRES_NAME}:5432/simplelogin" \
    -e REDIS_URL="redis://${REDIS_NAME}:6379/0" \
    -v "${TMP_APPDATA}:/appdata" \
    -v "${TMP_PGP}:/pgp" \
    "$IMAGE_TAG" >/dev/null

  wait_for_http
  wait_for_smtp
  docker exec "$CONTAINER_NAME" sh -lc "! ps -eo args | grep -E '(^| )/usr/lib/postgresql/.*/bin/postgres -D /appdata/postgres' >/dev/null"
  docker exec "$CONTAINER_NAME" sh -lc "! pgrep -x redis-server >/dev/null"
  cleanup_case
  cleanup_external_services
}

./scripts/smoke-test.sh "$IMAGE_TAG"

run_case "legacy-admin-fido-default" "" \
  -e ADMIN_FIDO_REQUIRED="|none|any|hardware"

run_case "admin-fido-any" "" \
  -e ADMIN_FIDO_REQUIRED="any"

run_case "admin-fido-hardware" "" \
  -e ADMIN_FIDO_REQUIRED="hardware"

run_case "oidc-keygen" "test -f /appdata/sl/jwtRS256.key && test -f /appdata/sl/jwtRS256.key.pub" \
  -e ENABLE_OIDC_SERVER="1"

run_case "pgp-keygen" "test -f /pgp/server_private_key.asc && test -f /pgp/server_public_key.asc" \
  -e AUTO_GENERATE_PGP="1"

run_case "relay-brevo" "grep -F '[smtp-relay.brevo.com]:587' /etc/postfix/sasl_passwd" \
  -e RELAY_MODE="brevo" \
  -e BREVO_USERNAME="brevo-user" \
  -e BREVO_PASSWORD="brevo-pass"

run_case "relay-protonmail" "grep -F '[smtp.protonmail.ch]:587' /etc/postfix/sasl_passwd" \
  -e RELAY_MODE="protonmail" \
  -e PROTONMAIL_TOKEN="proton-token"

run_case "relay-gmail" "grep -F '[smtp.gmail.com]:587' /etc/postfix/sasl_passwd" \
  -e RELAY_MODE="gmail" \
  -e GMAIL_USERNAME="user@gmail.com" \
  -e GMAIL_APP_PASSWORD="abcdefghijklmnop"

run_case "relay-mailgun" "grep -F '[smtp.mailgun.org]:587' /etc/postfix/sasl_passwd" \
  -e RELAY_MODE="mailgun" \
  -e MAILGUN_USERNAME="postmaster@example.com" \
  -e MAILGUN_PASSWORD="mailgun-pass"

run_case "relay-custom" "grep -F '[smtp.example.net]:587' /etc/postfix/sasl_passwd" \
  -e RELAY_MODE="custom" \
  -e CUSTOM_RELAYHOST="[smtp.example.net]:587" \
  -e CUSTOM_USERNAME="smtp-user" \
  -e CUSTOM_PASSWORD="smtp-pass"

run_external_services_case
