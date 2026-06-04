---
phase: 176
slug: c-systematic-per-screen-rubric-uplift
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 176 — Validation Strategy

> Per-phase validation contract for the systematic per-screen rubric uplift. Populated from RESEARCH.md `## Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (spot e2e/axe) |
| **Config file** | `accrue_admin/test/test_helper.exs`; `accrue_admin/e2e/` |
| **Quick run command** | `cd accrue_admin && mix test test/<touched>_test.exs --seed 0` |
| **Full suite command** | `cd accrue_admin && mix test --seed 0` |
| **Estimated runtime** | ~30–60s (ExUnit) |

---

## Sampling Rate

- **After every task commit:** focused `mix test` for the touched screen + `mix accrue_admin.assets.build` if CSS changed
- **After every wave:** full suite `cd accrue_admin && mix test --seed 0` (must stay 227+ green)
- **Before sign-off:** full suite green; assets built, no `priv/static` drift; SCORECARD before/after deltas recorded
- **Max feedback latency:** ~60s

---

## Per-Task Verification Map

> The rubric-uplift validation surface (planner fills exact task IDs):

| Area | Requirement | Test Type | What it proves | Automated Command |
|------|-------------|-----------|----------------|-------------------|
| Data-table card-collapse breakpoint (--ax-bp-lg→--ax-bp-md, app.css:1361) | SCR-02 | CSS/structural | tables collapse to cards below 768px (not 1024); no horizontal scroll @360px | `mix accrue_admin.assets.build` + structural LiveView/Playwright assertion |
| Per-screen 10-dim ≥2 (light+dark, desktop+mobile) | SCR-01, SCR-02 | code-audit SCORECARD + LiveView | every screen scores ≥2; documented before/after | SCORECARD.md + `mix test test/.../<screen>_live_test.exs` |
| Under-iterated tail lifted (payments, coupons, promo-codes, connect, events, webhooks, invoice, EventLive) | SCR-03 | LiveView + SCORECARD | each tail screen renders proper Detail components / field lists / states; before<2 → after≥2 | per-screen `mix test --seed 0 -x` |
| Reading-measure on dense prose | SCR-04 | source assertion | `.ax-measure` wraps prose regions (not tables/KPIs) | `grep "ax-measure" <screen>.ex` + render test |
| Token-compliance (dim ①) | SCR-01 | grep guard | no NEW literal hex/px in render path (branding-config hex excluded) | token-bypass grep guard |
| Mobile structural (no horizontal scroll, card layout active) | SCR-02 | structural/Playwright spot | usable @360px | `npm run e2e:visuals:png-only` spot (full sweep Phase 179) |
| Regression | all | full suite | 227+ tests stay green | `cd accrue_admin && mix test --seed 0` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **Baseline SCORECARD sweep** — score every admin screen × 10 dimensions (incl. Analytics/Recovery + CampaignLive per RESEARCH open question 2) at code level → `176-SCORECARD.md` with before scores. This is the worst-first input.
- [ ] Read `detail.ex` slot API before the first Wave 2 detail-screen task (RESEARCH open question 1 / A1-A2).
- [ ] Decide horizontal-overflow defense at 768px: add `overflow-x: auto` to `.ax-data-table-shell` or verify no overflow first (RESEARCH open question 3).

*Existing ExUnit + Playwright infrastructure otherwise covers the phase — no framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual ≥2 across {light,dark}×{desktop,mobile} per screen | SCR-01, SCR-02 | photographic proof | Deferred to Phase 179 screenshot QA sweep; this phase scores at code level |
| Brand-feel / hierarchy reads correctly | dim ②/⑧ | subjective | Phase 179 screenshot review |

*All structural/source behaviors have automated verification; visual confirmation is Phase 179's job.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 SCORECARD baseline captured before uplift tasks
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
