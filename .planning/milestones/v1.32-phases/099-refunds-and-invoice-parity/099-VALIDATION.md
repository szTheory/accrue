---
phase: 99
slug: refunds-and-invoice-parity
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
---

# Phase 99 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto sandbox and Oban manual testing |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/refund_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/billing/refund_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors`
- **After every plan wave:** Run `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 99-01-01 | 01 | 1 | PROC-18 | T-99-01 | Canonical refund facade rejects unsupported or invalid refund inputs and preserves auditable refund issuance flow. | unit/integration | `cd accrue && mix test test/accrue/billing/refund_braintree_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 99-02-01 | 02 | 1 | PROC-19 | T-99-02 | Refund convergence uses verified provider truth plus stale-event/deferral protection instead of optimistic local overwrite. | integration | `cd accrue && mix test test/accrue/webhook/braintree_refund_convergence_test.exs test/accrue/billing/invoice_projection_braintree_refund_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 99-03-01 | 03 | 2 | PROC-18, PROC-19 | T-99-03 | Charge-detail refund UX remains auth-gated, copy-honest, and thin over `Accrue.Billing`. | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/refund_braintree_test.exs` — canonical `refund/2` behavior, partial/full refund semantics, and compatibility wrapper coverage
- [x] `accrue/test/accrue/webhook/braintree_refund_convergence_test.exs` — applicable webhook normalization plus fetch/reconcile fallback coverage
- [x] `accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs` — invoice sale-truth preservation plus derived refund rollups
- [x] Extend `accrue_admin/test/accrue_admin/live/charge_live_test.exs` — Braintree eligibility copy, unsupported-void guidance, and derived refund summary assertions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | All planned phase behaviors should be automatable in ExUnit / LiveView tests. | N/A |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
