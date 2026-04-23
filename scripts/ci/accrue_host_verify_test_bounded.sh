#!/usr/bin/env bash
#
# Bounded host test slice used by `mix verify` in examples/accrue_host.
# Must be run with cwd = examples/accrue_host (the mix project root).
#
set -euo pipefail

echo "[host-integration] phase=bounded_mix_tests" >&2

host_dir="$(cd "$(dirname "$0")/../../examples/accrue_host" && pwd)"
cd "$host_dir"

test_files=(
  test/install_boundary_test.exs
  test/accrue_host/billing_facade_test.exs
  test/accrue_host_web/subscription_flow_test.exs
  test/accrue_host_web/webhook_ingest_test.exs
  test/accrue_host_web/trust_smoke_test.exs
  test/accrue_host_web/admin_webhook_replay_test.exs
  test/accrue_host_web/admin_mount_test.exs
  test/accrue_host_web/org_billing_access_test.exs
  test/accrue_host_web/org_billing_live_test.exs
)

MIX_ENV=test mix ecto.drop --quiet || true
MIX_ENV=test mix ecto.create --quiet
MIX_ENV=test mix ecto.migrate --quiet
MIX_ENV=test mix test --warnings-as-errors "${test_files[@]}"
