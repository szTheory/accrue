---
phase: 145
slug: time-window-url-plumbing-window-selector
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 145 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled with Elixir) + Phoenix.LiveViewTest (phoenix_live_view 1.1.30) |
| **Config file** | `accrue_admin/test/test_helper.exs` (exists) |
| **Quick run command** | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` (from `accrue_admin/`) |
| **Full suite command** | `mix test --seed 0` (from `accrue_admin/`) |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0`
- **After every plan wave:** Run `mix test --seed 0` (from `accrue_admin/`)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 145-01-01 | 01 | 1 | DAN-10 | — | `parse_window/1` whitelist returns `"30d"` for invalid input | unit | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | ✅ (extend existing) | ⬜ pending |
| 145-01-02 | 01 | 1 | DAN-10 | T-145-01 | `?window=7d` param → 7-day view renders, URL preserved | integration (LiveView) | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | ✅ (extend existing) | ⬜ pending |
| 145-01-03 | 01 | 1 | DAN-10 | — | No `?window=` → defaults to 30d | integration (LiveView) | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | ✅ (extend existing) | ⬜ pending |
| 145-01-04 | 01 | 1 | DAN-10 | T-145-01 | Invalid `?window=bad` → defaults to 30d | integration (LiveView) | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | ✅ (extend existing) | ⬜ pending |
| 145-01-05 | 01 | 1 | DAN-10 | — | `render_patch` to new window → `handle_params` fires, data reloads | integration (LiveView) | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | ✅ (extend existing) | ⬜ pending |
| 145-01-06 | 01 | 1 | DAN-10 | — | `WindowSelector` renders 3 buttons, correct active state, correct patch hrefs | unit (component) | `mix test test/accrue_admin/components/navigation_components_test.exs --seed 0` | ✅ (extend existing) | ⬜ pending |
| 145-01-07 | 01 | 1 | DAN-10 | — | Window change with seeded events outside the window → filtered count differs | integration (LiveView) | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | ✅ (extend existing) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — existing test infrastructure covers all phase requirements. The `AccrueAdmin.LiveCase` + `Phoenix.LiveViewTest` infrastructure is fully operational (confirmed: all 4 existing `recovery_live_test.exs` tests pass with 0 failures).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser back-button restores prior window after `<.link patch>` click | DAN-10 | Browser history interaction cannot be driven by `LiveViewTest` | 1. Load `/billing/analytics/recovery`. 2. Click "7d" preset — URL updates to `?window=7d`. 3. Click browser back — URL returns to prior state and correct view renders. |
| UTC label visible on window selector | DAN-10 | Visual rendering check | Load page; confirm "UTC" appears in or beside the window selector component. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
