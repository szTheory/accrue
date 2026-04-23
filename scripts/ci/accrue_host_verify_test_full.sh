#!/usr/bin/env bash
#
# Full host test suite used by `mix verify.full` (post-assets regression gate).
#
set -euo pipefail

echo "[host-integration] phase=full_mix_tests" >&2

host_dir="$(cd "$(dirname "$0")/../../examples/accrue_host" && pwd)"
cd "$host_dir"

MIX_ENV=test mix test --warnings-as-errors
