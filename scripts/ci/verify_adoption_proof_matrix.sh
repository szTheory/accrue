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

require_substring "## Layering note (local proof vs merge-blocking CI)" "Layer B/C layering heading"
require_substring "**Layer B (local Fake-backed proof):**" "Layer B label"
require_substring "**Layer C (merge-blocking \`docs-contracts-shift-left\` + \`host-integration\`):**" "Layer C label"
require_substring "verify_package_docs.sh" "verify_package_docs script name in matrix Layer C"
require_substring "verify_v1_17_friction_research_contract.sh" "v1.17 planning SSOT script name in matrix"
require_substring "verify_verify01_readme_contract.sh" "VERIFY-01 shift-left script name in matrix"
require_substring "verify_core_admin_invoice_verify_ids.sh" "Layer C verify_core_admin_invoice_verify_ids script name in matrix"
require_substring "accrue_host_hex_smoke.sh" "Hex smoke script name in matrix layering note"
require_substring "## Organization billing proof (ORG-09)" "ORG-09 section heading"
require_substring "### Primary archetype (merge-blocking)" "primary archetype heading"
require_substring "### Recipe lanes (advisory by default)" "recipe lanes heading"
require_substring "scripts/ci/verify_adoption_proof_matrix.sh" "script path literal"
require_substring "phx.gen.auth" "phx.gen.auth mention"
require_substring "use Accrue.Billable" "Accrue.Billable hook"
require_substring "non-Sigra" "non-Sigra framing"
require_substring "ORG-05" "ORG-05 taxonomy token in matrix"
require_substring "ORG-06" "ORG-06 taxonomy token in matrix"
require_substring "ORG-07" "ORG-07 row"
require_substring "ORG-08" "ORG-08 row"
require_substring "Accrue.Billing.create_checkout_session/2" "checkout facade API in matrix"
require_substring "[:accrue, :billing, :checkout_session, :create]" "checkout billing span tuple in matrix"
require_substring "checkout_session_facade_test.exs" "checkout facade ExUnit path in matrix"
require_substring "Accrue.Billing.create_billing_portal_session/2" "billing portal facade API in matrix"
require_substring "[:accrue, :billing, :billing_portal, :create]" "billing portal billing span tuple in matrix"
require_substring "billing_portal_session_facade_test.exs" "billing portal facade ExUnit path in matrix"
require_substring 'linked `1.0.0` pair' "linked 1.0.0 pair proof needle"

echo "verify_adoption_proof_matrix: OK"
