---
phase: 48
slug: admin-metering-billing-signals
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (**ADM-01**).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix `LiveViewTest`) |
| **Config file** | `accrue_admin/config/config.exs` + `test/test_helper.exs` (existing) |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test` |
| **Estimated runtime** | ~30–120 seconds (environment-dependent) |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs`
- **After every plan wave:** Run `cd accrue_admin && mix test`
- **Before `/gsd-verify-work`:** Full `accrue_admin` test suite green
- **Max feedback latency:** 120 seconds (CI parity)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | ADM-01 | T-48-01 / — | No PII in new copy; aggregate is count-only | LiveView | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` | ✅ | ⬜ pending |
| 48-01-02 | 01 | 1 | ADM-01 | — | N/A (HEEx wiring) | LiveView | same as above | ✅ | ⬜ pending |
| 48-01-03 | 01 | 1 | ADM-01 | — | N/A | unit / LiveView | same or dedicated Copy test path | ✅ | ⬜ pending |
| 48-01-04 | 01 | 1 | ADM-01 | — | N/A (CSS only) | visual / manual | `mix test` + optional screenshot | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — `AccrueAdmin.LiveCase`, `TestRepo`, `Factory`, dashboard LiveView tests already in tree.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Laptop viewport “first KPI without scroll” | ADM-01 / UI-SPEC | Viewport-dependent | Open `/billing` at 1280×800; confirm new card is first in KPI grid without scrolling the main KPI section. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: dashboard test file covers consecutive UI tasks
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution green run
