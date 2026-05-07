---
phase: 113
slug: cancellation-semantics-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 113 — Validation Strategy

> Per-phase validation contract for closing cancellation semantics drift across runtime labels, provider-honest docs, touched UI wording, and proof lanes without widening Accrue’s public cancellation API.

---

## Coverage Audit

| Source | Item | Covered By |
|--------|------|------------|
| GOAL | Normalize shipped cancellation semantics and capability labels so immediate vs scheduled-end behavior is explicit and truthful | Plans `113-01`, `113-02`, `113-03` |
| REQ | `PROC-22` supported generic cancellation path without staged-label drift or ambiguous semantics | Plans `113-01`, `113-02`, `113-03` |
| REQ | `PROC-23` runtime capability truth aligned to actual behavior with clear unsupported branches | Plans `113-01`, `113-02`, `113-03` |
| RESEARCH | immediate cancel first-party across Fake/Stripe/Braintree; scheduled-end unsupported on Braintree | Plans `113-01`, `113-02`, `113-03` |
| RESEARCH | doc/UI contradiction on Braintree immediate cancel must be corrected explicitly | Plan `113-02`, Plan `113-03` |
| RESEARCH | drift gates should pin support-matrix and guide wording | Plan `113-03` |
| CONTEXT | D-06..D-16 explicit facade semantics and capability-truth co-update discipline | Plan `113-01`, Plan `113-02` |
| CONTEXT | D-17..D-20 typed unsupported errors with one concrete next-step hint | Plan `113-01`, Plan `113-03` |
| CONTEXT | D-21..D-24 touched UX should gate or branch by provider truth instead of implying parity | Plan `113-02`, Plan `113-03` |

No deferred ideas are planned. Public API alias churn and library-owned Braintree scheduled-end orchestration remain out of scope.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus existing bash drift gates |
| **Config file** | `accrue/test/*`, `accrue_admin/test/*`, `accrue_portal/test/*`, `examples/accrue_host/test/*`, `scripts/ci/verify_processor_support_matrix.sh` |
| **Quick run command** | `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_cancel_test.exs test/accrue/processor/braintree_test.exs test/accrue/billing_portal_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_cancel_test.exs test/accrue/processor/braintree_test.exs test/accrue/billing_portal_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs && cd ../accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs && cd ../examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs && cd ../.. && bash scripts/ci/verify_processor_support_matrix.sh` |
| **Estimated runtime** | 3-6 minutes |

---

## Sampling Rate

- **After every task commit:** run that task’s focused `mix test`, `rg`, or bash verification command.
- **After Plan 01:** run the Plan 01 verification bundle before touching docs or UI.
- **After Plan 02:** run the doc/admin/host targeted tests.
- **After Plan 03:** run the full suite command and the support-matrix gate.
- **Max feedback latency:** under 6 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 113-01-01 | 01 | 1 | PROC-22, PROC-23 | T-113-01 | runtime labels and support-matrix rows promote immediate cancellation to first-party while preserving explicit split truth for scheduled-end cancellation | unit+static | `cd accrue && mix test test/accrue/processor/capabilities_test.exs && rg -n "subscription.cancel|subscription.cancel_immediately|subscription.cancel_at_period_end" lib/accrue/processor/capabilities.ex ../.planning/processor-support-matrix.md` | ✅ | ⬜ pending |
| 113-01-02 | 01 | 1 | PROC-22, PROC-23 | T-113-02 | unsupported Braintree scheduled-end and reversal branches carry typed semantics plus one concrete next-step hint, while immediate cancel remains supported | integration | `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/processor/braintree_test.exs && rg -n "host-owned|create a new subscription|cancel now|cancel at period end" lib/accrue/billing/subscription_actions.ex lib/accrue/processor/braintree.ex` | ✅ | ⬜ pending |
| 113-02-01 | 02 | 2 | PROC-22, PROC-23 | T-113-03 | lifecycle docs and Braintree guide explicitly mark Braintree immediate cancel as supported and scheduled-end policy as host-owned or unsupported | static | `rg -n "Accrue.Billing.cancel/2|cancel renewal|cancel_at_period_end|host-owned|Braintree|immediate" accrue/guides/braintree-local-portal.md accrue/guides/lifecycle_semantics.md accrue/guides/portal_configuration_checklist.md` | ✅ | ⬜ pending |
| 113-02-02 | 02 | 2 | PROC-22, PROC-23 | T-113-04 | admin/reference copy distinguishes immediate cancel from end-of-period guidance and corrects the current Braintree immediate-cancel contradiction | static | `rg -n "Cancel now|Cancel at period end|host-owned|supported|Braintree|pause|resume" accrue_admin/lib/accrue_admin/copy/subscription.ex accrue_admin/lib/accrue_admin/live/subscription_live.ex examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | ✅ | ⬜ pending |
| 113-03-01 | 03 | 3 | PROC-22, PROC-23 | T-113-05 | support-matrix verifier and guide assertions fail if immediate-cancel rows slide back to staged or if Braintree guide wording regresses | unit+script | `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/billing_portal_test.exs` | ✅ | ⬜ pending |
| 113-03-02 | 03 | 3 | PROC-22, PROC-23 | T-113-06 | admin, portal, and example-host tests pin renewal-stop vs hard-stop wording and the supported-immediate / unsupported-scheduled Braintree split | integration | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs && cd ../accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs && cd ../examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/lib/accrue/processor/capabilities.ex`, `accrue/lib/accrue/billing/subscription_actions.ex`, and `accrue/lib/accrue/processor/braintree.ex` all exist.
- [x] `.planning/processor-support-matrix.md`, `accrue/guides/lifecycle_semantics.md`, `accrue/guides/braintree-local-portal.md`, and `accrue/guides/portal_configuration_checklist.md` all exist.
- [x] `accrue/test/accrue/processor/capabilities_test.exs`, `accrue/test/accrue/billing/subscription_cancel_test.exs`, `accrue/test/accrue/processor/braintree_test.exs`, and `accrue/test/accrue/billing_portal_test.exs` all exist.
- [x] `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`, `accrue_portal/test/accrue_portal/live/subscription_live_test.exs`, `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs`, and `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` all exist.
- [x] `scripts/ci/verify_processor_support_matrix.sh` exists.

---

## Manual-Only Verifications

All planned phase behaviors have automated verification. No manual-only gate is required for planning.

---

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers every referenced proof lane
- [x] No watch-mode flags
- [x] Feedback latency < 360 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
