---
phase: 156
slug: entitlements-gating-adopter-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 156 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) |
| **Config file** | `examples/accrue_host/test/test_helper.exs`; `accrue/test/test_helper.exs` if a supplemental core guard test is added |
| **Quick run command** | `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` |
| **Estimated runtime** | ~30-120 seconds, depending on dependency freshness |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs`
- **After every plan wave:** Run `cd examples/accrue_host && mix test`
- **Before `$gsd-verify-work`:** `cd examples/accrue_host && mix verify.full` must be green
- **Max feedback latency:** 120 seconds for focused host test feedback

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 156-01-01 | 01 | 1 | PRF-01 | T-156-01 / T-156-02 | `%Ecto.Association.NotLoaded{}` is denied safely without raise or grant | integration | `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs` | ✅ | pending |
| 156-01-02 | 01 | 1 | PRF-01 | T-156-03 | Router documents auth/scope before entitlement guard and deny target outside gated session | static review | `rg -n "Ordering contract|Accrue.Live.Entitlements|NotLoaded|unloaded" examples/accrue_host/lib/accrue_host_web/router.ex accrue/guides/entitlements.md` | ✅ | pending |
| 156-01-03 | 01 | 1 | PRF-01 | T-156-01 / T-156-02 / T-156-03 | Existing positive and negative entitlement guard paths remain green | integration | `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs` | ✅ | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated or static verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify or static-documentation verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-31
