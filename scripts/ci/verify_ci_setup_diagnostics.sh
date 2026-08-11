#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
diagnostic="$root_dir/scripts/ci/ci_setup_diagnostic.sh"

fail() {
  echo "verify_ci_setup_diagnostics: $*" >&2
  exit 1
}

[ -x "$diagnostic" ] || fail "missing executable setup diagnostic registry"

assert_node_contract() {
  local output
  output="$("$diagnostic" describe node_missing_or_version)" || fail "node setup code must resolve"

  printf '%s\n' "$output" | grep -Fx 'code=node_missing_or_version' >/dev/null ||
    fail "missing stable Node code"
  printf '%s\n' "$output" | grep -Fx 'owner=host' >/dev/null ||
    fail "Node preflight must be host-owned"
  printf '%s\n' "$output" | grep -Fx 'next_command=Install Node 22 with your version manager, then run mix verify.full.' >/dev/null ||
    fail "Node preflight must provide the fixed repair command"
  printf '%s\n' "$output" | grep -Fx 'evidence_location=local host preflight stderr' >/dev/null ||
    fail "Node preflight must provide its evidence location"
}

assert_node_contract
echo "verify_ci_setup_diagnostics: ok"
