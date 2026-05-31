---
phase: 157
slug: metered-usage-adopter-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 157 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveViewTest |
| **Config file** | `examples/accrue_host/config/test.exs` |
| **Quick run command** | `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs --seed 0` |
| **Full suite command** | `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs --seed 0` |
| **Estimated runtime** | ~20 seconds |

## Sampling Rate

- **After every task commit:** Run `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs --seed 0`
- **After every plan wave:** Run `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs --seed 0`
- **Before `$gsd-verify-work`:** Focused host LiveView proof must be green
- **Max feedback latency:** 60 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 157-01-01 | 01 | 1 | PRF-02 | T-157-01 | Existing host billing facade authorization remains in the LiveView usage path | integration | `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs --seed 0` | ✅ | ⬜ pending |
| 157-01-02 | 01 | 1 | PRF-02 | T-157-02 | Inline comment prevents adopter misuse of subscription quantity semantics for metered events | source | `rg "value:.*quantity|quantity:.*value" examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | ✅ | ⬜ pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
