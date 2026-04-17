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

echo ""
echo "--- delegating to host-local mix verify.full ---"
cd "$host_dir"
mix verify.full

echo ""
echo "=== Accrue host UAT complete ==="
