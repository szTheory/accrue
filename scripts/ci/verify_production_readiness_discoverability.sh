#!/usr/bin/env bash
# Merge-blocking gate: production-readiness.md discoverability + stable §1–§10 spine.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
root_readme="${repo_root}/README.md"
package_readme="${repo_root}/accrue/README.md"
guide="${repo_root}/accrue/guides/production-readiness.md"

stderr_prefix="verify_production_readiness_discoverability"

fail() {
  echo "${stderr_prefix}: $*" >&2
  exit 1
}

[[ -f "${root_readme}" ]] || fail "missing ${root_readme}"
[[ -f "${package_readme}" ]] || fail "missing ${package_readme}"
[[ -f "${guide}" ]] || fail "missing ${guide}"

grep -Fq "accrue/guides/production-readiness.md" "${root_readme}" \
  || fail "root README must link accrue/guides/production-readiness.md"

grep -Fq "guides/production-readiness.md" "${package_readme}" \
  || fail "accrue/README.md must link guides/production-readiness.md"

for n in 1 2 3 4 5 6 7 8 9 10; do
  grep -Fq "### ${n}." "${guide}" \
    || fail "production-readiness.md missing stable heading ### ${n}."
done

grep -Fq "## Before you treat billing" "${guide}" \
  || fail "production-readiness.md missing intro section heading"

echo "${stderr_prefix}: OK"
