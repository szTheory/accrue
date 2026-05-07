---
phase: 117
slug: contract-promotion-preview-truth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 117 — Validation Strategy

> Per-phase validation contract for active subscription-change contract promotion and drift closure. Source-of-truth detail lives in `117-RESEARCH.md` section `Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus bash docs verifiers and focused `rg` contract checks |
| **Config file** | `accrue/test/*`, `accrue_admin/test/*`, `scripts/ci/verify_processor_support_matrix.sh`, `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/swap_plan_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs test/accrue/processor/capabilities_test.exs test/accrue/docs/processor_support_matrix_test.exs --warnings-as-errors` |
| **Full suite command** | `cd accrue && mix test test/accrue/billing/swap_plan_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs test/accrue/processor/capabilities_test.exs test/accrue/docs/processor_support_matrix_test.exs test/accrue/docs/package_docs_verifier_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs --warnings-as-errors && cd .. && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Estimated runtime** | 3-6 minutes |

---

## Sampling Rate

- **After every task commit:** run that task's local `rg` or focused `mix test` command.
- **After every plan wave:** run the quick run command plus the support-contract verifier bundle if docs or mirrors changed in that wave.
- **Before `$gsd-verify-work`:** run the full suite command.
- **Max feedback latency:** under 6 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 117-01-01 | 01 | 1 | SCM-01 | T-117-01 | explicit support labels and capability rows name `swap_plan/3` and bounded Braintree support without overstating parity | unit + static | `cd accrue && mix test test/accrue/billing/swap_plan_test.exs test/accrue/processor/capabilities_test.exs --warnings-as-errors && rg -n "swap_plan|preview_upcoming_invoice|bounded first-party|testing/local-only|unsupported" .planning/processor-support-matrix.md accrue/lib/accrue/processor/capabilities.ex` | ✅ | ✅ green |
| 117-01-02 | 01 | 1 | SCM-02 | T-117-02 | preview is canonical where supported and explicitly unsupported on Braintree, with no pseudo-preview wording | unit | `cd accrue && mix test test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 117-02-01 | 02 | 2 | SCM-01/SCM-02 | T-117-03 | lifecycle SSOT and support matrix align on one provider-honest active-subscription-change contract | integration + static | `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 117-02-02 | 02 | 2 | SCM-01/SCM-02 | T-117-03 | package and host mirrors stay thin, link back to canonical docs, and avoid stale Stripe-only or fake-parity wording | static | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ✅ green |
| 117-03-01 | 03 | 3 | SCM-02 | T-117-04 | admin subscription wording and gating reflect preview-first only where supported and avoid fake Braintree preview affordances | integration | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 117-03-02 | 03 | 3 | SCM-01/SCM-02 | T-117-05 | verifier scripts and contributor-map guidance pin the promoted swap/preview contract across canonical docs and thin mirrors | integration + static | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && rg -n "swap_plan/3|preview_upcoming_invoice/2|support-contract bundle|same-PR" scripts/ci/README.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/swap_plan_test.exs`, `accrue/test/accrue/billing/upcoming_invoice_test.exs`, `accrue/test/accrue/billing/proration_roundtrip_test.exs`, `accrue/test/accrue/processor/capabilities_test.exs`, and `accrue/test/accrue/docs/processor_support_matrix_test.exs` all exist.
- [x] `accrue/test/accrue/docs/package_docs_verifier_test.exs` and the support-contract bash verifiers all exist.
- [x] `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` exists for provider-honest admin regression coverage.
- [x] `accrue/test/live_stripe/proration_fidelity_live_test.exs` exists as an advisory fidelity lane outside the merge-blocking default suite.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live Stripe numerical preview-vs-commit fidelity remains consistent with the documented "closest fidelity path" wording | SCM-02 | Requires live Stripe credentials and real provider interaction, so it is advisory rather than merge-blocking | Run `cd accrue && STRIPE_TEST_SECRET_KEY=... ACCRUE_LIVE_BASIC_PRICE=... ACCRUE_LIVE_PRO_PRICE=... mix test test/live_stripe/proration_fidelity_live_test.exs --only live_stripe --warnings-as-errors` after the contract bundle lands, then confirm docs still describe this lane as advisory fidelity proof rather than default CI proof. |

---

## Validation Sign-Off

- [x] All tasks have automated verification or an explicit advisory lane
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers every referenced proof lane
- [x] No watch-mode flags
- [x] Feedback latency < 360 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed
