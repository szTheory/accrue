---
phase: 44
slug: meter-failures-idempotency-reconciler-webhook
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (v1.10 metering failure paths).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+ / OTP 27+) |
| **Config file** | `accrue/test/test_helper.exs` + `Accrue.BillingCase` |
| **Quick run command** | `cd accrue && mix test path/to/specific_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/billing/ test/accrue/jobs/meter_events_reconciler_test.exs test/accrue/webhook/handlers/billing_meter_error_report_test.exs` |
| **Estimated runtime** | ~60–120 seconds (scoped) |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the files touched by that task.
- **After every plan wave:** Run the full suite command above.
- **Before `/gsd-verify-work`:** `cd accrue && mix test` (package default) must be green.
- **Max feedback latency:** 180 seconds for scoped runs.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 1 | MTR-04 | T-44-01 | No PII in telemetry metadata beyond ids | unit | `cd accrue && mix test test/accrue/billing/meter_event_actions_test.exs` | ✅ | ⬜ pending |
| 44-01-02 | 01 | 1 | MTR-04 | T-44-01 | Same | unit | same | ✅ | ⬜ pending |
| 44-02-01 | 02 | 2 | MTR-05 | T-44-02 | Fake error maps only | unit | `cd accrue && mix test test/accrue/jobs/meter_events_reconciler_test.exs` | ✅ | ⬜ pending |
| 44-03-01 | 03 | 2 | MTR-06 | T-44-03 | Webhook payloads synthetic | unit | `cd accrue && mix test test/accrue/webhook/handlers/billing_meter_error_report_test.exs` | ✅ | ⬜ pending |
| 44-03-02 | 03 | 2 | MTR-06 | T-44-03 | Same + DispatchWorker | unit | `cd accrue && mix test test/accrue/webhook/dispatch_worker_test.exs` (create if plan adds file) | ⚠️ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements — **no** new Wave 0 install; reuse `Accrue.BillingCase`, `Fake`, `Accrue.Test.meter_events_for/1`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| *None planned* | — | All behaviors have automated ExUnit coverage per CONTEXT D-08/D-09/D-11 | — |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency &lt; 180s for scoped runs
- [ ] `nyquist_compliant: true` set in frontmatter after phase execution

**Approval:** pending
