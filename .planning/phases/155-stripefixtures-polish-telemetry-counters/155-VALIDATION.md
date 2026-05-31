---
phase: 155
slug: stripefixtures-polish-telemetry-counters
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 155 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/telemetry/metrics_test.exs` |
| **Full suite command** | `cd accrue && mix test.all` |
| **Estimated runtime** | ~60 seconds for focused tests; full suite runtime depends on environment |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/telemetry/metrics_test.exs`
- **After every plan wave:** Run `cd accrue && mix test.all`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds for focused feedback
- **Latency exception:** The phase uses existing ExUnit integration-style files that boot the project test environment; splitting below the focused file commands would reduce behavior coverage more than it improves signal. The 60-second target is accepted for Phase 155 because every task still has an automated focused command and no three-task sampling gap exists.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 155-01-01 | 01 | 1 | POL-03 | T-155-01 | `StripeFixtures` remains clearly test-only and not a public Hex/runtime API | source/docs | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | yes | pending |
| 155-01-02 | 01 | 1 | POL-03 | T-155-02 | `omit_livemode: true` removes only the `"livemode"` key and wins over `livemode:` | unit/integration | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | yes | pending |
| 155-01-03 | 01 | 1 | POL-04 | T-155-03 | Default metrics expose malformed/orphan webhook counters without high-cardinality tags | unit | `cd accrue && mix test test/accrue/telemetry/metrics_test.exs` | yes | pending |
| 155-01-04 | 01 | 1 | POL-03, POL-04 | T-155-01 / T-155-02 / T-155-03 | Focused phase behavior remains green before full-suite verification | regression | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/telemetry/metrics_test.exs` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target documented
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
