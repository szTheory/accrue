---
phase: 110
slug: lifecycle-semantics-self-serve-clarity
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 110 — Validation Strategy

> Per-phase validation contract for lifecycle semantics truth, touched LiveView copy, and drift-proof coverage. Source-of-truth detail lives in `110-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit across `accrue`, `accrue_admin`, `accrue_portal`, and `examples/accrue_host` |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `accrue_portal/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/billing/subscription_predicates_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing_portal_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/billing/subscription_predicates_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing_portal_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs && cd ../accrue_portal && mix deps.get && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs && cd ../examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` |
| **Estimated runtime** | ~3-5 minutes with portal deps restore |
| **Environment note** | The current local `accrue_portal` test lane may fail until `mix deps.get` restores the missing `rendro` dependency. |

---

## Sampling Rate

- **After every task commit:** run the smallest command that covers the touched behavior.
- **After every plan wave:** run the phase-local core + admin quick lane; include the portal lane once deps are restored.
- **Before `$gsd-verify-work`:** run the full suite command.
- **Max feedback latency:** keep targeted feedback under ~180 seconds once deps are present.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 110-01-01 | 01 | 1 | LIF-01 | T-110-01/T-110-02 | canonical lifecycle guide exists, names the action/state glossary, and uses provider labels without implying parity | static | `test -f accrue/guides/lifecycle_semantics.md && rg -n "cancel_at_period_end|resume/2|pause/2|unpause/2|active|canceling|paused|past_due|ended|native|host-owned|unsupported|testing/local-only" accrue/guides/lifecycle_semantics.md` | ✅ | ⬜ pending |
| 110-01-02 | 01 | 1 | LIF-01 | T-110-01/T-110-02 | adjacent docs link back to the lifecycle SSOT and stop teaching immediate-cancel-first self-serve behavior | static | `rg -n "lifecycle_semantics|at_period_end|cancel renewal|end at period end|convergence|local projection" accrue/guides/braintree-local-portal.md accrue/guides/portal_configuration_checklist.md accrue/guides/webhooks.md accrue/guides/webhook_gotchas.md && ! rg -n "Offer immediate cancellations using Accrue's cancel functions|Braintree supports immediate cancellation" accrue/guides/braintree-local-portal.md` | ✅ | ⬜ pending |
| 110-02-01 | 02 | 2 | LIF-02 | T-110-03/T-110-04 | portal list/detail surfaces render lifecycle-safe labels and explicit access-timing wording instead of raw status-only meaning | static/integration | `rg -n "cancel renewal|end at period end|access ends|canceling|paused|past due|ended" accrue_portal/lib/accrue_portal/copy.ex accrue_portal/lib/accrue_portal/live/subscription_live.ex accrue_portal/lib/accrue_portal/live/subscriptions_live.ex && ! rg -n "<span>\\{@subscription.status\\}</span>|Status\\}: \\{subscription.status\\}" accrue_portal/lib/accrue_portal/live/subscription_live.ex accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` | ✅ | ⬜ pending |
| 110-02-02 | 02 | 2 | LIF-02 | T-110-03/T-110-04 | admin and example-host wording distinguish exceptional immediate cancel from default scheduled-end semantics and stay provider-honest | static/integration | `rg -n "Cancel now|Cancel at period end|cancel renewal|access ends|Braintree|pause|resume|ended|canceling|past due" accrue_admin/lib/accrue_admin/copy/subscription.ex accrue_admin/lib/accrue_admin/live/subscription_live.ex examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | ✅ | ⬜ pending |
| 110-03-01 | 03 | 3 | LIF-01/LIF-02 | T-110-05 | docs and example-host tests pin the lifecycle SSOT, adjacent linkbacks, and least-surprise cancellation posture | unit/integration | `cd accrue && mix test test/accrue/billing_portal_test.exs && cd ../examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` | ✅ | ⬜ pending |
| 110-03-02 | 03 | 3 | LIF-02 | T-110-05/T-110-06 | portal and admin tests prove lifecycle-safe labels, timing, and provider-aware wording; portal lane restores deps first if needed | integration | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs && cd ../accrue_portal && mix deps.get && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/subscription_cancel_test.exs`, `subscription_predicates_test.exs`, and `subscription_actions_test.exs` already exist for the core lifecycle semantics lane.
- [x] `accrue/test/accrue/billing_portal_test.exs` already exists and can absorb the lifecycle-guide assertion extension.
- [x] `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` and `subscriptions_live_test.exs` already exist for the customer lifecycle wording lane.
- [x] `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` and `subscriptions_live_test.exs` already exist for the operator lifecycle wording lane.
- [x] `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` already exists for the example-host wording proof lane.
- [x] `accrue/guides/braintree-local-portal.md`, `portal_configuration_checklist.md`, `webhooks.md`, and `webhook_gotchas.md` all exist and are eligible for SSOT linkback assertions.
- [x] Portal dependency restoration path is known: `cd accrue_portal && mix deps.get`.

---

## Manual-Only Verifications

All planned Phase 110 behaviors are doc-assertable, grep-verifiable, or covered by targeted ExUnit/LiveView tests. No manual-only gate is required for planning.

---

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers every referenced proof lane
- [x] No watch-mode flags
- [x] Feedback latency < 300 seconds for the full focused lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
