#!/usr/bin/env bash
#
# accrue_host_uat.sh
#
# Automates the Phase 10 host-app dogfood checks:
#   1. Clean documented setup path stays executable.
#   2. User billing, webhook ingest, and admin replay smoke tests pass.
#   3. Phoenix can boot from the example app without hidden local state.
#
# Usage:
#   bash scripts/ci/accrue_host_uat.sh
#
# Environment:
#   PGHOST / PGUSER / PGPASSWORD  Postgres connection used by the host app
#   ACCRUE_HOST_PORT              Port for the bounded dev boot smoke (default: 4100)
#   ACCRUE_HOST_SKIP_DEV_BOOT     Set to 1 to skip the bounded phx.server smoke
#   ACCRUE_HOST_SKIP_BROWSER      Set to 1 to skip the headless browser smoke

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"
port="${ACCRUE_HOST_PORT:-4100}"
browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"

echo "=== Accrue host UAT — repo root: $repo_root ==="

if command -v pg_isready >/dev/null 2>&1; then
  echo "--- checking Postgres availability ---"
  pg_isready -h "${PGHOST:-localhost}" -U "${PGUSER:-postgres}"
fi

cd "$host_dir"

echo ""
echo "--- documented setup: deps + installer idempotence ---"
mix deps.get
mix accrue.install --yes \
  --billable AccrueHost.Accounts.User \
  --billing-context AccrueHost.Billing \
  --admin-mount /billing \
  --webhook-path /webhooks/stripe

if [ "${ACCRUE_HOST_ALLOW_GENERATED_DRIFT:-}" != "1" ]; then
  if ! git -C "$repo_root" diff --quiet -- \
    examples/accrue_host \
    ':!examples/accrue_host/README.md'; then
    echo "Generated host-app drift detected after rerunning mix accrue.install."
    echo "Review and commit intentional generated changes, then rerun this script."
    git -C "$repo_root" diff --stat -- \
      examples/accrue_host \
      ':!examples/accrue_host/README.md'
    exit 1
  fi
fi

echo ""
echo "--- compile gate ---"
mix compile --warnings-as-errors

echo ""
echo "--- browser asset build ---"
mix assets.build

echo ""
echo "--- host UAT test suite ---"
MIX_ENV=test mix ecto.drop --quiet || true
MIX_ENV=test mix ecto.create --quiet
MIX_ENV=test mix ecto.migrate --quiet
MIX_ENV=test mix test --warnings-as-errors \
  test/install_boundary_test.exs \
  test/accrue_host/billing_facade_test.exs \
  test/accrue_host_web/subscription_flow_test.exs \
  test/accrue_host_web/webhook_ingest_test.exs \
  test/accrue_host_web/admin_mount_test.exs \
  test/accrue_host_web/admin_webhook_replay_test.exs

echo ""
echo "--- full host regression suite ---"
MIX_ENV=test mix test --warnings-as-errors

if [ "${ACCRUE_HOST_SKIP_DEV_BOOT:-}" = "1" ]; then
  echo ""
  echo "--- dev boot smoke skipped (ACCRUE_HOST_SKIP_DEV_BOOT=1) ---"
else
  echo ""
  echo "--- bounded dev boot smoke ---"
  MIX_ENV=dev mix ecto.create --quiet
  MIX_ENV=dev mix ecto.migrate --quiet

  log_file="$(mktemp)"
  cleanup() {
    if [ -n "${server_pid:-}" ] && kill -0 "$server_pid" >/dev/null 2>&1; then
      kill "$server_pid" >/dev/null 2>&1 || true
      wait "$server_pid" >/dev/null 2>&1 || true
    fi
    rm -f "$log_file"
  }
  trap cleanup EXIT

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
      break
    fi

    sleep 1
  done

  if ! curl --fail --silent --show-error "http://127.0.0.1:${port}/" >/dev/null; then
    echo "Phoenix server did not become ready"
    cat "$log_file"
    exit 1
  fi

  if grep -Ei "(could not|failed|exception|pending migration|missing|undefined)" "$log_file" >/dev/null; then
    echo "Phoenix boot log contains failure-like output"
    cat "$log_file"
    exit 1
  fi

  cleanup
  trap - EXIT
fi

if [ "${ACCRUE_HOST_SKIP_BROWSER:-}" = "1" ]; then
  echo ""
  echo "--- browser smoke skipped (ACCRUE_HOST_SKIP_BROWSER=1) ---"
else
  if ! NODE_PATH="$repo_root/accrue_admin/node_modules" node -e "require('@playwright/test')" >/dev/null 2>&1; then
    echo "Playwright is not installed. Run: cd accrue_admin && npm ci && npx playwright install chromium"
    exit 1
  fi

  echo ""
  echo "--- headless browser billing/admin smoke ---"
  fixture_file="$(mktemp)"
  browser_log_file="$(mktemp)"

  cleanup_browser() {
    if [ -n "${browser_server_pid:-}" ] && kill -0 "$browser_server_pid" >/dev/null 2>&1; then
      kill "$browser_server_pid" >/dev/null 2>&1 || true
      wait "$browser_server_pid" >/dev/null 2>&1 || true
    fi
    rm -f "$fixture_file" "$browser_log_file"
  }
  trap cleanup_browser EXIT

  MIX_ENV=test mix ecto.drop --quiet || true
  MIX_ENV=test mix ecto.create --quiet
  MIX_ENV=test mix ecto.migrate --quiet
  ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run "$repo_root/scripts/ci/accrue_host_seed_e2e.exs"

  PORT="$browser_port" PHX_SERVER=true MIX_ENV=test mix phx.server >"$browser_log_file" 2>&1 &
  browser_server_pid=$!

  for _ in $(seq 1 30); do
    if ! kill -0 "$browser_server_pid" >/dev/null 2>&1; then
      echo "Phoenix browser-smoke server exited early"
      cat "$browser_log_file"
      exit 1
    fi

    if curl --fail --silent --show-error "http://127.0.0.1:${browser_port}/" >/dev/null; then
      break
    fi

    sleep 1
  done

  ACCRUE_HOST_BASE_URL="http://127.0.0.1:${browser_port}" \
    ACCRUE_HOST_E2E_FIXTURE="$fixture_file" \
    NODE_PATH="$repo_root/accrue_admin/node_modules" \
    node "$repo_root/scripts/ci/accrue_host_browser_smoke.cjs" || {
      echo "Phoenix browser-smoke server log:"
      cat "$browser_log_file"
      exit 1
    }
fi

echo ""
echo "=== Accrue host UAT complete ==="
