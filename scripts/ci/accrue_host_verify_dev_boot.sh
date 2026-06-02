#!/usr/bin/env bash
#
# Bounded dev Phoenix boot smoke for examples/accrue_host (`mix verify.full`).
#
set -euo pipefail

echo "[host-integration] phase=dev_boot_smoke" >&2

host_dir="$(cd "$(dirname "$0")/../../examples/accrue_host" && pwd)"
cd "$host_dir"

if [ "${ACCRUE_HOST_SKIP_DEV_BOOT:-}" = "1" ]; then
  echo "--- dev boot smoke skipped (ACCRUE_HOST_SKIP_DEV_BOOT=1) ---"
  exit 0
fi

port="${ACCRUE_HOST_PORT:-4100}"
log_file="$(mktemp)"

describe_port_owner() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null || true
}

ensure_port_available() {
  local port="$1"

  if describe_port_owner "$port" | grep -q .; then
    echo "Port ${port} is already in use; set ACCRUE_HOST_PORT to another port or stop the listener." >&2
    describe_port_owner "$port" >&2
    exit 1
  fi
}

stop_process_tree() {
  local pid="$1"

  pkill -TERM -P "$pid" >/dev/null 2>&1 || true
  kill "$pid" >/dev/null 2>&1 || true
  wait "$pid" >/dev/null 2>&1 || true
}

cleanup() {
  if [ -n "${server_pid:-}" ] && kill -0 "$server_pid" >/dev/null 2>&1; then
    stop_process_tree "$server_pid"
  fi

  rm -f "$log_file"
}

trap cleanup EXIT
trap 'exit 130' INT TERM

ensure_port_available "$port"

MIX_ENV=dev mix ecto.create --quiet
MIX_ENV=dev mix ecto.migrate --quiet

PORT="$port" MIX_ENV=dev mix phx.server >"$log_file" 2>&1 &
server_pid=$!

for _ in $(seq 1 30); do
  if ! kill -0 "$server_pid" >/dev/null 2>&1; then
    echo "Phoenix server exited early"
    cat "$log_file"
    exit 1
  fi

  if curl --fail --silent --show-error "http://127.0.0.1:${port}/" >/dev/null; then
    echo "Phoenix boot smoke passed on http://127.0.0.1:${port}/"
    exit 0
  fi

  sleep 1
done

echo "Phoenix server did not become ready"
cat "$log_file"
exit 1
