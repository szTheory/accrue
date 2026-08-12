#!/usr/bin/env bash
#
# accrue_host_uat.sh
#
# Delegates the repo-root host verification entrypoint to the package-local
# `mix verify.full` contract in `examples/accrue_host`.
#
# Usage:
#   bash scripts/ci/accrue_host_uat.sh
#
# Environment:
#   PGHOST / PGPORT / PGUSER / PGPASSWORD / PGDATABASE
#                                  Postgres connection used by the host app
#   ACCRUE_HOST_PORT              Port for the bounded dev boot smoke (default: 4100)
#   ACCRUE_HOST_SKIP_DEV_BOOT     Set to 1 to skip the bounded phx.server smoke
#   ACCRUE_HOST_SKIP_BROWSER      Set to 1 to skip the headless browser smoke

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"
port="${ACCRUE_HOST_PORT:-4100}"
browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"

echo "=== Accrue host UAT — repo root: $repo_root ==="
echo "[host-integration] entry=accrue_host_uat delegating_to=mix_verify.full" >&2

if command -v pg_isready >/dev/null 2>&1; then
  echo "--- checking Postgres availability ---"
  pg_isready \
    -h "${PGHOST:-localhost}" \
    -p "${PGPORT:-5432}" \
    -U "${PGUSER:-postgres}" \
    ${PGDATABASE:+-d "$PGDATABASE"}
fi

export ACCRUE_HOST_PORT="$port"
export ACCRUE_HOST_BROWSER_PORT="$browser_port"
export ACCRUE_HOST_SKIP_DEV_BOOT="${ACCRUE_HOST_SKIP_DEV_BOOT:-}"
export ACCRUE_HOST_SKIP_BROWSER="${ACCRUE_HOST_SKIP_BROWSER:-}"
export ACCRUE_HOST_ALLOW_GENERATED_DRIFT="${ACCRUE_HOST_ALLOW_GENERATED_DRIFT:-}"
export ACCRUE_HOST_BROWSER_LOG="${ACCRUE_HOST_BROWSER_LOG:-}"
export ACCRUE_CI_SETUP_FACTS="${ACCRUE_CI_SETUP_FACTS:-}"

setup_fact_count() {
  local facts="${ACCRUE_CI_SETUP_FACTS:-}"
  if [ -z "$facts" ] || [ ! -f "$facts" ]; then
    printf '0\n'
    return
  fi

  grep -cE '^\{"schema_version":"1","code":"[A-Za-z0-9._:-]{1,80}",' "$facts" || true
}

echo ""
echo "--- delegating to host-local mix verify.full ---"
cd "$host_dir"
setup_fact_count_before="$(setup_fact_count)"
set +e
mix verify.full
delegated_status=$?
set -e

if [ "$delegated_status" -ne 0 ]; then
  setup_fact_count_after="$(setup_fact_count)"
  if [ "$setup_fact_count_after" -le "$setup_fact_count_before" ]; then
    "$repo_root/scripts/ci/ci_setup_diagnostic.sh" emit host_gate_failure --result failure --duration-ms 0 --node-identity wrapper --playwright-identity delegated --lockfile-identity package-lock --browser-class host-gate --cache-state inherited >/dev/null 2>&1 || true
    "$repo_root/scripts/ci/ci_setup_diagnostic.sh" render host_gate_failure
  fi
  echo "FAILED_GATE=host-integration" >&2
  exit "$delegated_status"
fi

echo ""
echo "=== Accrue host UAT complete ==="
