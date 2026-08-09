#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
canonical_input="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"

fail() {
  echo "verify_ci_baseline_contract: $*" >&2
  exit 1
}

input="$canonical_input"
if [ "${1:-}" = "--input" ]; then
  [ "$#" -eq 2 ] || fail "--input requires a path"
  input="$2"
elif [ "$#" -ne 0 ]; then
  fail "usage: $0 [--input PATH]"
fi

[ -f "$input" ] || fail "missing baseline input: ${input#$root_dir/}"
[ -x "$root_dir/scripts/ci/capture_ci_baseline.sh" ] ||
  fail "missing executable collector: scripts/ci/capture_ci_baseline.sh"

echo "verify_ci_baseline_contract: preliminary contract passed"
