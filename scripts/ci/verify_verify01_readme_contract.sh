#!/usr/bin/env bash
# Shift-left gate: README VERIFY-01 prose must stay aligned with CI + seed contract.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readme="${repo_root}/examples/accrue_host/README.md"

if [[ ! -f "${readme}" ]]; then
  echo "verify_verify01_readme_contract: missing ${readme}" >&2
  exit 1
fi

require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${readme}"; then
    echo "verify_verify01_readme_contract: README missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}

require_substring "VERIFY-01" "VERIFY-01 heading marker"
require_substring "accrue_host_seed_e2e.exs" "E2E seed script path"
require_substring "npx playwright test" "Playwright command"
require_substring "cd examples/accrue_host" "examples/accrue_host cwd instruction"
require_substring "host-integration" "GitHub Actions job name for PR CI"
require_substring "mix verify.full" "canonical verify.full gate"
require_substring ".github/workflows/ci.yml" "CI workflow pointer"
require_substring "docs/adoption-proof-matrix.md" "adoption proof matrix doc link"
require_substring "e2e/verify01-admin-a11y.spec.js" "mounted admin axe gate spec path"

# Negative: VERIFY-01 section must not advise storing sk_live without explicit negation.
if awk '
  /^## VERIFY-01/ { in_block = 1; next }
  in_block && /^## / { exit 0 }
  in_block && /sk_live/ {
    line = $0
    if (line !~ /[Dd]o not|[Dd]on'\''t|[Nn]ever|[Aa]void/) {
      print FILENAME ":" FNR ": VERIFY-01 section mentions sk_live without do not / never / avoid: " line
      exit 1
    }
  }
' "${readme}"; then
  :
else
  exit 1
fi

echo "verify_verify01_readme_contract: OK"
