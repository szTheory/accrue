---
phase: 222
slug: close-gap-off-05-schedule-offline-reconnect-recovery
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-05
---

# Phase 222 — Validation Strategy

> Per-phase validation contract for reference-host offline reconnect recovery scheduling.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Oban manual test mode |
| **Config file** | `examples/accrue_host/config/test.exs` |
| **Quick run command** | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` |
| **Full suite command** | `cd examples/accrue_host && mix verify` |
| **Estimated runtime** | ~60 seconds focused; full suite varies |

## Sampling Rate

- **After every task commit:** Run the focused recovery-wiring command.
- **After every plan wave:** Run `cd examples/accrue_host && mix verify`.
- **Before `$gsd-verify-work`:** Run the focused core companion: `cd accrue && mix test test/accrue/entitlements/offline_reconnect_test.exs`.
- **Max feedback latency:** 60 seconds for the focused test.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 222-01-01 | 01 | 1 | OFF-05 | T-222-01 | Cron triggers the existing reconnect sweeper without replacing other schedules or queues. | configuration integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 222-01-02 | 01 | 1 | OFF-05 | T-222-02 | A durable stranded reconnect is swept, executes once under configured test-only providers, and reaches signed issuance. | Ecto + Oban integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |

## Wave 0 Requirements

- [ ] Extend `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` with test-only offline reconnect key-provider/source-coordinator fixtures and safe application-environment restoration.
- [ ] Extend the same test with static Cron assertions and durable stranded-attempt recovery proof.

## Manual-Only Verifications

All phase behaviors have automated verification. Production `:offline_reconnect` adapter configuration is deliberately outside this narrow scheduling closure and must not be represented as enabled by the test fixtures.

## Validation Sign-Off

- [ ] All tasks have automated verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing recovery-proof references.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency is under 60 seconds.
- [ ] `nyquist_compliant: true` set after execution evidence.

**Approval:** pending
