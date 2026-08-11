#!/usr/bin/env bash
#
# Headless browser + Playwright gate for examples/accrue_host (`mix verify.full`).
#
set -euo pipefail

echo "[host-integration] phase=browser_playwright" >&2

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"
diagnostic="$repo_root/scripts/ci/ci_setup_diagnostic.sh"
setup_started_ms=$(( $(date +%s) * 1000 ))

setup_failure() {
  local code="$1"
  local exit_status="${2:-1}"
  local now_ms duration_ms
  now_ms=$(( $(date +%s) * 1000 ))
  duration_ms=$(( now_ms - setup_started_ms ))
  "$diagnostic" emit "$code" --result failure --duration-ms "$duration_ms" --node-identity node-preflight --playwright-identity unknown --lockfile-identity package-lock --browser-class unknown --cache-state unknown >/dev/null 2>&1 || true
  "$diagnostic" render "$code"
  exit "$exit_status"
}

run_classified() {
  local code="$1"
  shift
  local command_status

  set +e
  "$@"
  command_status=$?
  set -e
  if [ "$command_status" -ne 0 ]; then
    setup_failure "$code" "$command_status"
  fi
}

if ! command -v node >/dev/null 2>&1; then
  setup_failure node_missing_or_version
fi

node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
if [ "$node_major" != "22" ]; then
  setup_failure node_missing_or_version
fi

cd "$host_dir"

if [ "${ACCRUE_HOST_SKIP_BROWSER:-}" = "1" ]; then
  echo "--- browser smoke skipped (ACCRUE_HOST_SKIP_BROWSER=1) ---"
  exit 0
fi

# Deterministic test seam: production callers never set this. It only selects a
# fixed registry code and cannot carry runtime detail into the diagnostic.
if [ -n "${ACCRUE_HOST_SETUP_DIAGNOSTIC_FIXTURE:-}" ]; then
  setup_failure "$ACCRUE_HOST_SETUP_DIAGNOSTIC_FIXTURE"
fi

browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"
fixture_file="$(mktemp)"
browser_log_file="${ACCRUE_HOST_BROWSER_LOG:-$(mktemp)}"
browser_failed=0

describe_port_owner() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null || true
}

ensure_port_available() {
  local port="$1"

  if describe_port_owner "$port" | grep -q .; then
    setup_failure port_or_server_readiness
  fi
}

stop_process_tree() {
  local pid="$1"

  pkill -TERM -P "$pid" >/dev/null 2>&1 || true
  kill "$pid" >/dev/null 2>&1 || true
  wait "$pid" >/dev/null 2>&1 || true
}

cleanup() {
  if [ -n "${browser_server_pid:-}" ] && kill -0 "$browser_server_pid" >/dev/null 2>&1; then
    stop_process_tree "$browser_server_pid"
  fi

  rm -f "$fixture_file"

  if [ -z "${ACCRUE_HOST_BROWSER_LOG:-}" ] && [ "$browser_failed" != "1" ]; then
    rm -f "$browser_log_file"
  fi
}

trap cleanup EXIT
trap 'browser_failed=1; exit 130' INT TERM

ensure_port_available "$browser_port"

MIX_ENV=test mix ecto.drop --quiet || true
run_classified fixture_or_database env MIX_ENV=test mix ecto.create --quiet
run_classified fixture_or_database env MIX_ENV=test mix ecto.migrate --quiet
run_classified fixture_or_database env ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run "$repo_root/scripts/ci/accrue_host_seed_e2e.exs"

run_classified fixture_or_database bash "$repo_root/scripts/ci/verify_e2e_fixture_jq.sh" "$fixture_file"

# `accrue_admin` is a path dep of the host, but CI only runs `mix deps.get` from the host app.
# Building assets requires a standalone Mix project cwd with its own `deps/` tree.
(
  cd "$repo_root/accrue_admin"
  run_classified fixture_or_database mix deps.get --quiet
  run_classified fixture_or_database mix accrue_admin.assets.build
  run_classified fixture_or_database mkdir -p "$repo_root/examples/accrue_host/e2e/generated"
  run_classified fixture_or_database mix accrue_admin.export_copy_strings --out "$repo_root/examples/accrue_host/e2e/generated/copy_strings.json"
)
run_classified fixture_or_database env MIX_ENV=test mix deps.compile accrue_admin --force

run_classified npm_lock_or_registry npm ci
run_classified playwright_binary_or_revision npm run e2e:install

PORT="$browser_port" PHX_SERVER=true MIX_ENV=test mix phx.server >"$browser_log_file" 2>&1 &
browser_server_pid=$!

for _ in $(seq 1 30); do
  if ! kill -0 "$browser_server_pid" >/dev/null 2>&1; then
    browser_failed=1
    setup_failure port_or_server_readiness
  fi

  if curl --fail --silent --show-error "http://127.0.0.1:${browser_port}/" >/dev/null; then
    set +e
    # Playwright global-setup also runs `mix run .../accrue_host_seed_e2e.exs` by default.
    # While `mix phx.server` is already bound to the same DB, that concurrent re-seed can race
    # auth inserts (e.g. users_tokens unique on context+token). CI seeds once above; skip the
    # redundant global-setup seed when the fixture path is already populated.
    # Full Playwright suite (blocking PR gate via host-integration). Includes
    # mounted-admin axe checks: e2e/verify01-admin-a11y.spec.js (light + dark).
    ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED=1 \
      ACCRUE_HOST_REUSE_SERVER=1 ACCRUE_HOST_BROWSER_PORT="$browser_port" ACCRUE_HOST_E2E_FIXTURE="$fixture_file" npm run e2e
    e2e_status=$?
    set -e

    if [ "$e2e_status" -ne 0 ]; then
      browser_failed=1
      setup_failure browser_launch "$e2e_status"
    fi

    exit "$e2e_status"
  fi

  sleep 1
done

browser_failed=1
setup_failure port_or_server_readiness
