---
phase: 117-contract-promotion-preview-truth
verified: 2026-05-07T19:35:00Z
status: passed
score: 2/2 requirements verified
overrides_applied: 0
re_verification:
  previous_status: missing
  previous_score: 0/2
  gaps_closed:
    - Promoted `swap_plan/3` and `preview_upcoming_invoice/2` into the explicit public contract
    - Added swap/preview drift gates across docs, host mirrors, admin copy, and CI verifiers
  gaps_remaining: []
  regressions: []
human_verification: []
---

# Phase 117: Contract Promotion + Preview Truth Verification Report

**Phase Goal:** Promote the active subscription-change bundle into one explicit support contract centered on `swap_plan/3` and preview-before-commit truth.
**Verified:** 2026-05-07T19:35:00Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `swap_plan/3` and `preview_upcoming_invoice/2` are now the explicit official active-subscription-change facade, and the codebase carries provider-honest swap/preview labels. | ✓ VERIFIED | `accrue/lib/accrue/billing.ex` documents both APIs as the official contract, `accrue/lib/accrue/processor/capabilities.ex` exposes dedicated swap/preview labels plus provider-specific wording, and `accrue/test/accrue/processor/capabilities_test.exs` proves the labels. |
| 2 | The canonical docs spine, thin mirrors, admin copy, and shift-left verifier bundle all repeat the same bounded Braintree story: preview is canonical where supported and unsupported on Braintree. | ✓ VERIFIED | `.planning/processor-support-matrix.md`, `accrue/guides/lifecycle_semantics.md`, `accrue/README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`, `accrue_admin/lib/accrue_admin/copy/subscription.ex`, and the `scripts/ci/verify_*` bundle all carry the same wording and passed validation. |

**Score:** 2/2 truths verified

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused billing and docs suite | `cd accrue && mix test test/accrue/billing/swap_plan_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs test/accrue/processor/capabilities_test.exs test/accrue/docs/processor_support_matrix_test.exs test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` | 20 tests, 0 failures | ✓ PASS |
| Admin contradiction guard | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs --warnings-as-errors` | 7 tests, 0 failures | ✓ PASS |
| Support-contract drift gates | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` | All four scripts exit 0 | ✓ PASS |

### Requirements Coverage

Coverage was cross-referenced against `.planning/REQUIREMENTS.md`.

| Requirement | Description | Status | Evidence |
| --- | --- | --- | --- |
| SCM-01 | Promote the subscription-change bundle into an explicit first-party contract in code and docs. | ✓ SATISFIED | Public billing docs, capability labels, support matrix rows, lifecycle semantics, and package mirrors now name `swap_plan/3` and `preview_upcoming_invoice/2` explicitly. |
| SCM-02 | Keep preview-before-commit guidance provider-honest without implying unsupported Braintree parity. | ✓ SATISFIED | Braintree is documented and tested as bounded swap support plus explicit no-preview support across lifecycle docs, host docs, admin copy, and CI verifier needles. |

No orphaned Phase 117 requirement IDs remain.
