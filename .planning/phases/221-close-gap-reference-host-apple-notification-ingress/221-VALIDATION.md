---
phase: 221
slug: close-gap-reference-host-apple-notification-ingress
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 221-01-01 | TBD | 1 | D-01/D-02 | T-221-01 | Dedicated route preserves exact raw bytes and enforces 256 KiB boundary | router integration | focused Apple ingress test | ❌ W0 | ⬜ pending |
| 221-01-02 | TBD | 1 | D-03/D-09 | T-221-02 | Acknowledge only durable intake/quarantine; preserve response classes | router + persistence | focused Apple ingress test | ❌ W0 | ⬜ pending |
| 221-01-03 | TBD | 1 | D-04–D-08 | T-221-03 | Runtime trust, reconciliation, and bounded backpressure remain host-owned | config + integration | focused Apple ingress/config test | ❌ W0 | ⬜ pending |
| 221-02-01 | TBD | 2 | D-10/D-13 | T-221-04 | Docs expose no raw provider evidence and give literal verification | static docs contract | `mix verify` and documentation gate | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` — router-level coverage for all D-11 cases.
- [ ] Register the focused test in `scripts/ci/accrue_host_verify_test_bounded.sh` so `mix verify` is literal and bounded.
- [ ] Add a test-safe host Apple configuration/fake-verifier helper that uses opaque synthetic JSON only.
- [ ] Add static config wiring coverage (or equivalent integration assertions) for the Apple Oban queue/Cron resources.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App Store Connect test notification | D-12 | Requires deployed Apple credential/endpoint; advisory only | Run the documented deployment check and record only safe correlation/status information. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 120 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
