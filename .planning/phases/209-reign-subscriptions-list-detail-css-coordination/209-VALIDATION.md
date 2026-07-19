---
phase: 209
slug: reign-subscriptions-list-detail-css-coordination
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-19
---

# Phase 209 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (unit)** | ExUnit via `mix test` (`AccrueAdmin.LiveCase` = Phoenix.LiveViewTest + Floki) |
| **Framework (visual)** | Playwright `@playwright/test ^1.57.0` (`accrue_admin/playwright.config.js`) |
| **Config file** | `accrue_admin/mix.exs` / `test/test_helper.exs`; `accrue_admin/playwright.config.js` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test` |
| **Visual (scoped)** | `cd accrue_admin && RATCHET_SURFACES=subscriptions,subscription-detail npx playwright test e2e/admin-visuals.spec.js` |
| **Estimated runtime** | ~1s (scoped unit) / visual per harness |

---

## Sampling Rate

- **After every task commit:** Run scoped `mix test test/accrue_admin/live/subscriptions_live_test.exs`
- **After every plan wave:** Run `cd accrue_admin && mix test`
- **Before `/gsd-verify-work`:** Full unit suite green + scoped Playwright PNG parity captured
- **Max feedback latency:** ~5 seconds (unit)

---

## Per-Task Verification Map

*(Populated by gsd-planner — each task's `<automated>`/`<verify>` maps here.)*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | — | — | REIGN-01 / REIGN-02 / COMP-01 | — | N/A (read/navigate surface) | unit + visual | `mix test .../subscriptions_live_test.exs` | ✅ (exists) | ⬜ pending |

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements — `subscriptions_live_test.exs` exists (12/12 green pre-reign) and the Playwright `admin-visuals` harness is wired. No new framework install needed. Retired-class/copy assertions are *migrated* in-phase, not stubbed in Wave 0.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Detail page (`subscription_live.ex`) visually unbroken after list reign | REIGN-02 / D-04 | Shared `.ax-inline-worklist*` / `.ax-audit-summary-row` CSS; parity is a human PNG read | Capture before/after via `RATCHET_SURFACES=subscriptions,subscription-detail npx playwright test e2e/admin-visuals.spec.js`; confirm subscription-detail PNG identical |
| Density-no-regression on Subscriptions list | REIGN-01 (UI-SPEC pt 6) | Row height / rows-per-viewport / header-band height is a visual judgment vs pre-reign baseline | Compare pre-reign vs post-reign Subscriptions PNG; density held at-or-tighter |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infra suffices)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
