#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$repo_root/examples/accrue_host"

export ACCRUE_HOST_HEX_RELEASE=1

echo "Phase 12 plan 08 activates Hex smoke"
exit 0

# mix deps.get
# mix accrue.install
# mix compile --warnings-as-errors
# MIX_ENV=test mix ecto.create
# MIX_ENV=test mix ecto.migrate
# MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs
