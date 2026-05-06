---
phase: 103
slug: metering-engine
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-02
---

# Phase 103 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto sandbox and Oban manual testing |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/jobs/metered_renewal_reconciler_test.exs test/accrue/telemetry/metered_billing_ops_test.exs --warnings-as-errors && test -f accrue/guides/braintree-metered-billing.md && test -f .planning/phases/103-metering-engine/103-VALIDATION.md` |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-local verify command for the touched task.
- **After every plan wave:** Run that plan's full `<verification>` command.
- **Before `$gsd-verify-work`:** Full `cd accrue && mix test --warnings-as-errors` must be green.
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 103-01-01 | 01 | 1 | BT-06, BT-07 | T-103-01..03 | Meter definitions and immutable renewal windows open only from webhook-proven cycle advancement and remain replay-safe. | unit/integration | `cd accrue && mix test test/accrue/billing/meter_definitions_test.exs test/accrue/webhook/braintree_metered_renewal_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 103-02-01 | 02 | 2 | BT-06 | T-103-04..06 | Worker-owned aggregation authors one local invoice decomposition per closed renewal window and preserves explicit event-resolution outcomes. | unit/integration/Oban | `cd accrue && mix test test/accrue/billing/metered_renewal_invoice_test.exs test/accrue/billing/meter_event_resolution_test.exs test/accrue/jobs/process_metered_renewal_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 103-03-01 | 03 | 3 | BT-07 | T-103-07..09 | Renewal settlement uses one replay-safe Braintree sale per renewal window with typed recovery states. | unit/integration/Oban | `cd accrue && mix test test/accrue/billing/metered_charge_attempts_test.exs test/accrue/jobs/process_metered_renewal_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 103-04-01 | 04 | 4 | BT-06, BT-07 | T-103-10..12 | Stale-window recovery, durable ops telemetry, and docs stay honest about the Braintree local-metering contract. | integration/docs | `cd accrue && mix test test/accrue/jobs/metered_renewal_reconciler_test.exs test/accrue/telemetry/metered_billing_ops_test.exs --warnings-as-errors && test -f accrue/guides/braintree-metered-billing.md && test -f .planning/phases/103-metering-engine/103-VALIDATION.md && rg -n "local aggregation|renewal window|Transaction\\.sale|awaiting-payment-method|failed-exhausted" accrue/guides/braintree-metered-billing.md accrue/guides/operator-runbooks.md && rg -n "metered_|accrue\\.ops\\.|wave_0_complete: true|nyquist_compliant: true" accrue/guides/telemetry.md .planning/phases/103-metering-engine/103-VALIDATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/meter_definitions_test.exs` — meter-definition binding and host-light ingress contract
- [x] `accrue/test/accrue/webhook/braintree_metered_renewal_test.exs` — webhook-primary immutable renewal-window opening
- [x] `accrue/test/accrue/billing/metered_renewal_invoice_test.exs` — renewal-window aggregation and invoice decomposition
- [x] `accrue/test/accrue/billing/meter_event_resolution_test.exs` — explicit matched/unmatched/unusable billing outcomes
- [x] `accrue/test/accrue/jobs/process_metered_renewal_test.exs` — worker-owned aggregation and replay-safe settlement flow
- [x] `accrue/test/accrue/billing/metered_charge_attempts_test.exs` — durable settlement-state machine
- [x] `accrue/test/accrue/jobs/metered_renewal_reconciler_test.exs` — narrow stale-window repair backstop
- [x] `accrue/test/accrue/telemetry/metered_billing_ops_test.exs` — low-noise metered-billing ops tuples and metrics
- [x] Docs verification lane — guide existence plus `rg` assertions for Braintree-local metering, recovery states, and telemetry catalog strings

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | All planned phase behaviors should be automatable in ExUnit and docs checks. | N/A |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all planned proof lanes
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verification contract finalized for Plans 01-04
