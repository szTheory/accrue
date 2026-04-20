#!/usr/bin/env bash
#
# Headless browser + Playwright gate for examples/accrue_host (`mix verify.full`).
#
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"
cd "$host_dir"

if [ "${ACCRUE_HOST_SKIP_BROWSER:-}" = "1" ]; then
  echo "--- browser smoke skipped (ACCRUE_HOST_SKIP_BROWSER=1) ---"
  exit 0
fi

browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"
fixture_file="$(mktemp)"
browser_log_file="${ACCRUE_HOST_BROWSER_LOG:-$(mktemp)}"
browser_failed=0

cleanup() {
  if [ -n "${browser_server_pid:-}" ] && kill -0 "$browser_server_pid" >/dev/null 2>&1; then
    kill "$browser_server_pid" >/dev/null 2>&1 || true
    wait "$browser_server_pid" >/dev/null 2>&1 || true
  fi

  rm -f "$fixture_file"

  if [ -z "${ACCRUE_HOST_BROWSER_LOG:-}" ] && [ "$browser_failed" != "1" ]; then
    rm -f "$browser_log_file"
  fi
}

trap cleanup EXIT

MIX_ENV=test mix ecto.drop --quiet || true
MIX_ENV=test mix ecto.create --quiet
MIX_ENV=test mix ecto.migrate --quiet
ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run "$repo_root/scripts/ci/accrue_host_seed_e2e.exs"

bash "$repo_root/scripts/ci/verify_e2e_fixture_jq.sh" "$fixture_file"

# `accrue_admin` is a path dep of the host, but CI only runs `mix deps.get` from the host app.
# Building assets requires a standalone Mix project cwd with its own `deps/` tree.
(
  cd "$repo_root/accrue_admin"
  mix deps.get --quiet
  mix accrue_admin.assets.build
)
MIX_ENV=test mix deps.compile accrue_admin --force

npm ci
npm run e2e:install

PORT="$browser_port" PHX_SERVER=true MIX_ENV=test mix phx.server >"$browser_log_file" 2>&1 &
browser_server_pid=$!

for _ in $(seq 1 30); do
  if ! kill -0 "$browser_server_pid" >/dev/null 2>&1; then
    echo "Phoenix browser-smoke server exited early"
    browser_failed=1
    echo "Phoenix browser-smoke server log: $browser_log_file"
    cat "$browser_log_file"
    exit 1
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
      echo "Phoenix browser-smoke server log: $browser_log_file"
      cat "$browser_log_file"
    fi

    exit "$e2e_status"
  fi

  sleep 1
done

echo "Phoenix browser-smoke server did not become ready"
browser_failed=1
echo "Phoenix browser-smoke server log: $browser_log_file"
cat "$browser_log_file"
exit 1
