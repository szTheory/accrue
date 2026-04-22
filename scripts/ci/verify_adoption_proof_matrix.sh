#!/usr/bin/env bash
# Shift-left gate: ORG-09 literals in adoption-proof-matrix.md must stay aligned with docs + CI.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
matrix="${repo_root}/examples/accrue_host/docs/adoption-proof-matrix.md"

if [[ ! -f "${matrix}" ]]; then
  echo "verify_adoption_proof_matrix: missing ${matrix}" >&2
  exit 1
fi

require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${matrix}"; then
    echo "verify_adoption_proof_matrix: matrix missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}

require_substring "## Organization billing proof (ORG-09)" "ORG-09 section heading"
require_substring "### Primary archetype (merge-blocking)" "primary archetype heading"
require_substring "### Recipe lanes (advisory by default)" "recipe lanes heading"
require_substring "scripts/ci/verify_adoption_proof_matrix.sh" "script path literal"
require_substring "phx.gen.auth" "phx.gen.auth mention"
require_substring "use Accrue.Billable" "Accrue.Billable hook"
require_substring "non-Sigra" "non-Sigra framing"
require_substring "ORG-07" "ORG-07 row"
require_substring "ORG-08" "ORG-08 row"

echo "verify_adoption_proof_matrix: OK"
