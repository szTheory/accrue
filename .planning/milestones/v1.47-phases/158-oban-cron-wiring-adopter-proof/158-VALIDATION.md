---
phase: 158
slug: oban-cron-wiring-adopter-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 158 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `examples/accrue_host/mix.exs` |
| **Quick run command** | `cd examples/accrue_host && mix test test/accrue_host/recovery_wiring_test.exs --seed 0` |
| **Full suite command** | `cd examples/accrue_host && mix test test/accrue_host/recovery_wiring_test.exs --seed 0` |
| **Estimated runtime** | ~20 seconds |

## Sampling Rate

- **After every task commit:** Run `cd examples/accrue_host && mix test test/accrue_host/recovery_wiring_test.exs --seed 0`
- **After every plan wave:** Run `cd examples/accrue_host && mix test test/accrue_host/recovery_wiring_test.exs --seed 0`
- **Before `$gsd-verify-work`:** Focused recovery wiring test must be green and source assertions must pass.
- **Max feedback latency:** 30 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 158-01-01 | 01 | 1 | PRF-03 | T-158-01 | N/A | ExUnit + source assertion | `cd examples/accrue_host && mix test test/accrue_host/recovery_wiring_test.exs --seed 0` | yes | pending |
| 158-01-02 | 01 | 1 | PRF-03 | T-158-02 | N/A | Source assertion | `rg "existing_cron_jobs\\(\\).*\\+\\+" examples/accrue_host/config/config.exs` | yes | pending |
| 158-01-03 | 01 | 1 | PRF-03 | T-158-03 | N/A | Source assertion | `rg "append|replacing|config/config.exs|DunningSweeper|accrue_dunning" examples/accrue_host/docs/adoption-proof-matrix.md` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have automated verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
