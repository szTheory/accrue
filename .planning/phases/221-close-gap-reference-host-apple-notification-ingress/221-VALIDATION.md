---
phase: 221
slug: close-gap-reference-host-apple-notification-ingress
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-05
---

# Phase 221 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir/Mix host project) |
| **Config file** | `examples/accrue_host/config/test.exs` |
| **Quick run command** | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs --warnings-as-errors` |
| **Full suite command** | `cd examples/accrue_host && mix verify` |
| **Estimated runtime** | ~120 seconds |

## Sampling Rate

- **After every task commit:** Run the focused Apple ingress test and formatter.
- **After every plan wave:** Run `cd examples/accrue_host && mix verify`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 120 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 221-02-T1 | 221-02 | 2 | D-01/D-02/D-03/D-04/D-05/D-06/D-09/D-11 | T-221-01..06 | Exact bytes pass through the dedicated host route, verifier, durable intake, and wakeup | router + PostgreSQL integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 221-03-T1/T2 | 221-03 | 3 | D-03/D-08/D-09/D-10/D-11 | T-221-05 | Malformed, oversized, rate-limited, duplicate, and concurrent ingress remains bounded and privacy-safe | router + rate-policy integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs test/accrue_host/apple_rate_policy_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 221-04-T1/T2 | 221-04 | 4 | D-03/D-04/D-05/D-07/D-11 | T-221-06 | Durable wakeups use the additive queue, sweeper, and shared production admission configuration | recovery-wiring integration | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/recovery_wiring_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 221-05-T1/T2, 221-06-T1/T2 | 221-05/06 | 5-6 | D-01..D-13 | T-221-07..09 | Documentation, catalog admission, trusted edge, and bounded verifier remain contract-checked | integration + static contract | `cd examples/accrue_host && mix verify` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` — router-level coverage for all D-11 cases.
- [x] Register the focused test in `scripts/ci/accrue_host_verify_test_bounded.sh` so `mix verify` is literal and bounded.
- [x] Add a test-safe host Apple configuration/fake-verifier helper that uses opaque synthetic JSON only.
- [x] Add static config wiring coverage (or equivalent integration assertions) for the Apple Oban queue/Cron resources.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App Store Connect test notification | D-12 | Requires deployed Apple credential/endpoint; advisory only | Run the documented deployment check and record only safe correlation/status information. |

## Validation Sign-Off

- [x] All implementation tasks have automated verification or a completed Wave 0 dependency.
- [x] Sampling continuity: no 3 consecutive implementation tasks lack automated verification.
- [x] Wave 0 covers all previously missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 120 seconds for the focused suite.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** validated from the completed Phase 221 evidence on 2026-08-05.

## Validation Audit 2026-08-05

| Metric | Count |
|--------|------:|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

The previous draft was not reconciled after execution. The completed Phase 221 summaries and verification report establish coverage for every implementation requirement. The live App Store Connect delivery remains a deliberately advisory external smoke test, not a missing automated coverage item.
