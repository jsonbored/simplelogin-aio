#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${1:-simplelogin-aio:test}"
CONTAINER_NAME="simplelogin-aio-smoke"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-57777}"
HOST_SMTP_PORT="${HOST_SMTP_PORT:-52525}"
READY_TIMEOUT_SECONDS="${READY_TIMEOUT_SECONDS:-420}"
KEEP_SMOKE_ARTIFACTS="${KEEP_SMOKE_ARTIFACTS:-0}"

TMP_APPDATA="$(mktemp -d /tmp/simplelogin-aio-appdata.XXXXXX)"
TMP_PGP="$(mktemp -d /tmp/simplelogin-aio-pgp.XXXXXX)"
cleanup_needed=1

cleanup() {
  local exit_code=$?
  if [[ "$cleanup_needed" -eq 1 ]]; then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    rm -rf "$TMP_APPDATA" "$TMP_PGP"
  elif [[ "$exit_code" -ne 0 ]]; then
    echo "Smoke test failed; preserving artifacts for debugging."
    echo "SMOKE_CONTAINER_NAME=$CONTAINER_NAME"
    echo "SMOKE_APPDATA_DIR=$TMP_APPDATA"
    echo "SMOKE_PGP_DIR=$TMP_PGP"
  fi
  exit "$exit_code"
}
trap cleanup EXIT

start_container() {
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
    -e DISABLE_REGISTRATION="1" \
    -e NOT_SEND_EMAIL="true" \
    -e POSTMASTER="postmaster@example.com" \
    -v "${TMP_APPDATA}:/appdata" \
    -v "${TMP_PGP}:/pgp" \
    "$IMAGE_TAG" >/dev/null
}

wait_for_http() {
  local deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
  while (( SECONDS < deadline )); do
    if curl -fsS "http://127.0.0.1:${HOST_HTTP_PORT}/health" >/dev/null; then
      return 0
    fi
    docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"
    sleep 2
  done
  echo "SimpleLogin web service did not become healthy in time."
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
  echo "SimpleLogin SMTP service did not become ready in time."
  docker logs "$CONTAINER_NAME" || true
  return 1
}

verify_persistence() {
  docker exec "$CONTAINER_NAME" test -f /appdata/postgres/PG_VERSION
  docker exec "$CONTAINER_NAME" test -f /appdata/sl/.initialized
}

start_container
wait_for_http
wait_for_smtp
verify_persistence

docker restart "$CONTAINER_NAME" >/dev/null
wait_for_http
wait_for_smtp
verify_persistence

if [[ "$KEEP_SMOKE_ARTIFACTS" -eq 1 ]]; then
  cleanup_needed=0
fi
