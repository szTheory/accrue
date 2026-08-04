#!/usr/bin/env bash
# Shift-left gate: ORG-09 literals in adoption-proof-matrix.md must stay aligned with docs + CI.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
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
require_substring "scripts/ci/README.md" "support-contract bundle readme pointer"
require_substring 'exact bundle membership lives in `scripts/ci/README.md` and `.github/workflows/ci.yml`' "pointer-based bundle wording"
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
require_substring "Fake remains the merge-blocking SSOT" "Fake-backed merge-blocking SSOT"
require_substring "advisory" "advisory proof lane"
require_substring "Braintree" "Braintree provider mention"
require_substring "gateway subscription core" "gateway subscription core slice"
require_substring "Stripe returns upstream hosted checkout and billing-portal URLs" "provider-honest Stripe hosted wording"
require_substring "Braintree returns mounted local checkout and portal URLs" "provider-honest Braintree mounted wording"
require_substring "swap_plan/3" "swap-plan API in matrix"
require_substring "preview_upcoming_invoice/2" "preview API in matrix"
require_substring "canonical path where supported" "preview-before-commit wording"
require_substring "unsupported on Braintree" "braintree preview boundary wording"
require_substring "update_customer/2" "bounded customer-update wording"
require_substring "cancel/2" "shared immediate cancellation wording"
require_substring "cancel_at_period_end/2" "scheduled-end split wording"
require_substring "dunning_wiring_test.exs" "dunning wiring host smoke test path in matrix"
require_substring "accrue_dunning" "accrue_dunning queue token in matrix"
require_substring "Oban.Plugins.Cron" "Oban.Plugins.Cron crontab token in matrix"
require_substring "dunning_full_journey_test.exs" "dunning full journey test path in matrix"
require_substring "Entitlement gating" "Entitlement gating row"
require_substring "Accrue.Live.Entitlements" "Accrue.Live.Entitlements API reference"
require_substring "dunning_banner_live_test.exs" "BAN-04 in-app dunning banner live test path in matrix"
require_substring "AccrueAdmin.Components.DunningBanner" "BAN-04 dunning banner component reference in matrix"

if grep -Eq 'Stripe-only|remain Stripe-only' "${matrix}"; then
  echo "verify_adoption_proof_matrix: matrix still contains stale Stripe-only wording" >&2
  exit 1
fi

if grep -Fq 'job `docs-contracts-shift-left` runs `verify_package_docs.sh`' "${matrix}"; then
  echo "verify_adoption_proof_matrix: matrix drifted back to the stale inline docs-contracts-shift-left inventory wording" >&2
  exit 1
fi

if grep -Eq 'preview parity|pseudo-preview' "${matrix}"; then
  echo "verify_adoption_proof_matrix: stale preview-parity wording still present" >&2
  exit 1
fi

# v1.59 uses this hand-authored path to explain how adopters move from the
# reference host to the generated exact-fact matrix. The fixture/matrix itself
# remains owned by verify_reference_scenario_contract.sh.
require_substring "## v1.59 first-adopter path" "v1.59 path heading"
require_substring "mix accrue.entitlements.reference_scenarios --check" "v1.59 deterministic command"
require_substring "capability-limits-matrix.md" "generated v1.59 matrix link"
require_substring "operator-runbooks.md#v159-multi-rail-and-offline-runbooks" "v1.59 runbook link"
require_substring "Apple-to-web and Stripe-to-iOS" "cross-rail convergence boundary"
require_substring "feasibility_blocked" "blocked runtime-capability boundary"

if grep -Eq 'Crosswake runtime (is )?(supported|feasible)' "${matrix}"; then
  echo "verify_adoption_proof_matrix: examples/accrue_host/docs/adoption-proof-matrix.md has runtime-capability inflation" >&2
  exit 1
fi

echo "verify_adoption_proof_matrix: OK"
echo "verify_adoption_proof_matrix: v1.59 OK"
