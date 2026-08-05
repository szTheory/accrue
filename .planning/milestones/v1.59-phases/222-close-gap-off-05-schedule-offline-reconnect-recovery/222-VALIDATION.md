---
phase: 222
slug: close-gap-off-05-schedule-offline-reconnect-recovery
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 222-01-01 | 01 | 1 | OFF-05 | T-222-01 | A real one-time challenge and P-256 device signature admit the durable attempt before interruption; the worker receives no fabricated authentication input. | PoP + Ecto integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 222-01-02 | 01 | 1 | OFF-05 | T-222-02 | Cron preserves existing schedules; a durable stranded reconnect is swept and terminalizes exactly once through the persisted worker job. | configuration + Oban/Ecto integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 222-01-03 | 01 | 1 | OFF-05 | T-222-03 | Instrumented `due_sources/3` and `refresh/4` calls prove a controlled provider status flows from host configuration through refresh without any client-proof input. | behavior-contract integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 222-01-04 | 01 | 1 | OFF-05 | T-222-04 | Signing/source adapters remain nested test modules and every mutated application key is restored by the non-async fixture. | isolation integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ | ✅ green |

## Wave 0 Requirements

- [x] Extended `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` with test-only offline reconnect key-provider/instrumented due-source coordinator fixtures, exact callback-input assertions, and safe application-environment restoration.
- [x] Extended the same test with static Cron assertions and durable stranded-attempt recovery proof.

## Manual-Only Verifications

All phase behaviors have automated verification. Production `:offline_reconnect` adapter configuration is deliberately outside this narrow scheduling closure and must not be represented as enabled by the test fixtures.

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing recovery-proof references.
- [x] No watch-mode flags.
- [x] Focused feedback latency is under 60 seconds.
- [x] `nyquist_compliant: true` set after execution evidence.

**Approval:** validated — all Phase 222 behaviors have focused host integration coverage, reference-host release-contract coverage, and a core reconnect regression companion.

## Validation Audit 2026-08-05

| Metric | Count |
|--------|------:|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Evidence re-run during this audit:

- Focused host recovery wiring and formatting: 7 tests, 0 failures.
- Reference-host `mix verify`: 64 tests, 0 failures.
- Core offline reconnect lifecycle: 19 tests, 0 failures.

The production `:offline_reconnect` adapter remains an explicit host-owned configuration boundary; it is not a missing validation case for this scheduling closure.
