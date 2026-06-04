---
phase: 175
slug: b-persona-driven-ia-spine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 175 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Populated by the planner from RESEARCH.md `## Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (e2e/axe) |
| **Config file** | `accrue_admin/test/test_helper.exs`; `accrue_admin/e2e/` (Playwright) |
| **Quick run command** | `cd accrue_admin && mix test` |
| **Full suite command** | `cd accrue_admin && mix test && npm run e2e:visuals:png-only` |
| **Estimated runtime** | ~30–60 seconds (ExUnit); e2e longer |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue_admin && mix test test/<touched>_test.exs`
- **After every plan wave:** Run `cd accrue_admin && mix test`
- **Before `/gsd:verify-work`:** Full suite green; `mix accrue_admin.assets.build` succeeds and `priv/static` committed
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

> Planner fills exact task IDs. The IA-spine validation surface (what MUST be tested):

| Area | Requirement | Test Type | What it proves | Automated Command |
|------|-------------|-----------|----------------|-------------------|
| `/charges`→`/payments` (and `/charges/:id`→`/payments/:id`) redirect | IA-07 | controller/integration | old bookmarks resolve 200 at new path; no dead link | `mix test test/.../redirect_test.exs` |
| Work-queue defaults (invoices open+uncollectible, subs past_due+canceling, payments failed, customers all) | IA-03 | LiveView test | bare list nav shows persona queue; `?view=all` sentinel shows all; no push_patch loop | `mix test test/.../*_live_test.exs` |
| Nav attention badges (Developer=dead-letter, Recovery=at-risk) | IA-02 | unit + LiveView | `AttentionCounts.compute/1` returns correct counts; badge renders only when >0; auto-expand when >0 | `mix test test/.../attention_counts_test.exs` |
| Bidirectional Related card on all 8 detail screens | IA-04 | LiveView test | each detail renders a Related card; no dead ends | `mix test test/.../*_live_test.exs` |
| Webhook→Event→entity thread (+ `/events/:id`) | IA-04 | LiveView test | webhook detail links to derived event(s); event detail links to affected entity | `mix test test/.../event_live_test.exs` |
| Customer-360 primary tabs + "More ▾" | IA-05 | LiveView test | primary tabs visible; More toggle reveals recessed tabs | `mix test test/.../customer_live_test.exs` |
| Compliance "By actor" lens on `/events` | IA-06 | LiveView test | actor-filter preset filters event list | `mix test test/.../events_live_test.exs` |
| Visible labeled search + verb launchers on Home | IA-01 | LiveView test | search field visible (not hotkey-only); launchers use exact verb strings | `mix test test/.../dashboard_live_test.exs` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Verify `AccrueAdmin.Queries.Invoices.list/1` (and subs/charges) support multi-value status filtering — if not, a query-module extension task precedes work-queue defaults (RESEARCH open question A1).
- [ ] Audit current Related-card coverage on the 6 unread detail screens (subscription, invoice, charge, coupon, promotion_code, connect_account) before threading work.

*Existing ExUnit + Playwright infrastructure otherwise covers all phase requirements — no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sidebar collapse localStorage persistence across reloads | IA-02 | client-side JS hook; e2e-only | Toggle a specialist zone, reload, confirm state persists (Playwright or manual) |
| Visual hierarchy of primary vs recessed zones reads correctly | IA-02 | subjective visual | Screenshot review (deferred to Phase F sweep) |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (multi-status query support, related-card audit)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
