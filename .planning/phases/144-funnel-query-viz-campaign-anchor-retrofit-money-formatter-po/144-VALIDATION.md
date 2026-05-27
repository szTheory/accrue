---
phase: 144
slug: funnel-query-viz-campaign-anchor-retrofit-money-formatter-polish
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 144 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) — both `accrue/` and `accrue_admin/` mix apps |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test --stale` (core) / `cd accrue_admin && mix test --stale` (admin) |
| **Full suite command** | `cd accrue && mix test && cd ../accrue_admin && mix test` |
| **Estimated runtime** | ~30–60 seconds full suite (per-package quick: ~3–10 s) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale` in the affected package.
- **After every plan wave:** Run full suite for the affected package (both packages if cross-cutting).
- **Before `/gsd:verify-work`:** Full suite green across `accrue/` and `accrue_admin/`; `mix format --check-formatted` clean; `mix credo --strict` clean.
- **Max feedback latency:** 60 s (per package) for stale runs.

---

## Per-Task Verification Map

> Canonical task IDs sourced from each `144-0{1..4}-PLAN.md` frontmatter (`phase`+`plan`) and task ordering. Each row maps a task to its automated verification command.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | DAN-08 | T-144-01 | safe-cast wraps `(?->>'mrr_value_cents')::integer`; malformed-row regression contributes 0 | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ | ⬜ pending |
| 144-01-02 | 01 | 1 | DAN-01 | T-144-02 | funnel/1 returns DISTINCT-`(subject_id, campaign_anchor)`-tuple stage counts via single Repo.one query | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs` | ✅ | ⬜ pending |
| 144-01-03 | 01 | 1 | DAN-01, DAN-08 | T-144-02 | property invariant `recovered + exhausted + active ≤ entered` holds across StreamData generations | property | `cd accrue && mix test test/property/dunning_funnel_property_test.exs` | ❌ Wave 0 creates stub (file new in Task 3) | ⬜ pending |
| 144-02-01 | 02 | 1 | DAN-02 | — | `dunning.exhausted` event payload carries `campaign_anchor` (ISO-8601 binary OR nil) at emission boundary | unit | `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs` | ✅ | ⬜ pending |
| 144-02-02 | 02 | 1 | DAN-02 | — | `dunning.recovered` event payload carries `campaign_anchor` (ISO-8601 binary, captured BEFORE anchor clear) at emission boundary | unit | `cd accrue && mix test test/accrue/webhook/dunning_campaign_keying_test.exs` | ✅ | ⬜ pending |
| 144-03-01 | 03 | 2 | DAN-09 | — | `AccrueAdmin.Components.FunnelChart` Phoenix.Component renders 3 proportional `<rect>` bars + active chip + `<dl>` legend; zero-divide safe at entered=0 | unit (render_component) | `cd accrue_admin && mix test test/accrue_admin/components/funnel_chart_test.exs` | ❌ Wave 0 creates stub (file new in Task 1) | ⬜ pending |
| 144-03-02 | 03 | 2 | DAN-09 | — | `.ax-funnel-chart`, `.ax-funnel-row`, `.ax-funnel-row--{slate,moss,amber}`, `.ax-funnel-bar`, `.ax-funnel-legend` present in app.css | unit (CSS presence via component render) | `cd accrue_admin && mix test test/accrue_admin/components/funnel_chart_test.exs` | ✅ (test file from 144-03-01) | ⬜ pending |
| 144-04-01 | 04 | 3 | DAN-09, DAN-13 | T-144-02 | RecoveryLive.mount/3 calls `Dunning.funnel/1`, renders `<FunnelChart.funnel_chart>` below `.ax-kpi-grid`, swaps `format_minor/1` for `Render.format_money/3`, renames "Lost MRR" → "Exhausted MRR" | integration (LiveView) | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ✅ | ⬜ pending |
| 144-04-02 | 04 | 3 | DAN-09, DAN-13 | — | JPY regression: `Application.put_env(:accrue, :default_currency, :jpy)` + seeded mrr_value_cents/currency renders `¥` (not `$`); funnel HTML present; "Exhausted MRR" label asserted | integration (LiveView) | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs follow the canonical `{phase}-{plan}-{seq}` convention; verify against `144-0{1..4}-PLAN.md` `<task>` order before execution. The only NEW test files created during execution are `accrue/test/property/dunning_funnel_property_test.exs` (Plan 01 Task 3) and `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` (Plan 03 Task 1) — both stubs are created in-line by the task that implements the behavior, so no separate Wave 0 scaffolding is required.*

---

## Wave 0 Requirements

> Wave 0 verifies test infrastructure exists before Wave 1 begins. For Phase 144, no separate scaffolding wave is needed — ExUnit + `stream_data` are already in `mix.exs`, and the two new test files are authored in-line by the task that implements the behavior under test.

- [x] `accrue/test/accrue/analytics/dunning_test.exs` — existing; funnel + safe-cast tests appended by Tasks 144-01-01 and 144-01-02
- [x] `accrue/test/property/dunning_funnel_property_test.exs` — NEW file created by Task 144-01-03 (file authoring + assertion live in the same task; no separate scaffold needed)
- [x] `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` — existing; `campaign_anchor` assertion extends `:308-311` (Task 144-02-01)
- [x] `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` — existing; `campaign_anchor` assertion on recovered edge (Task 144-02-02)
- [x] `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` — NEW file created by Task 144-03-01 (component + tests authored in the same task; no separate scaffold needed)
- [x] `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — existing; JPY regression + funnel render + "Exhausted MRR" copy tests appended by Task 144-04-02
- [x] `stream_data ~> 1.3` — already in `accrue/mix.exs` per project STACK
- [x] No new mix deps required

`wave_0_complete: true` — the two new test files are created in-line by their owning tasks. No standalone Wave 0 stub commit is required because the test-and-implementation pairings are co-located by design.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual confirmation of funnel proportional bars rendering correctly in browser (Chrome + Firefox, light + dark theme) | DAN-09 | LiveView render tests assert HTML structure but not visual proportions or theme-token resolution | Boot `cd accrue_admin && mix phx.server`; visit `/billing/analytics/recovery` with seeded events; verify bars are visibly proportional and tones (`slate/moss/amber`) render in both themes |
| Tooltip copy on Exhausted stage reads as worked yearly-plan example | DAN-09 success criterion #5 | Tooltip copy is content review; render tests can assert presence but copy quality is editorial | Hover over Exhausted bar/legend row; confirm the copy explains yearly-plan annualization in plain English |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (both new files authored in-line by owning task)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
