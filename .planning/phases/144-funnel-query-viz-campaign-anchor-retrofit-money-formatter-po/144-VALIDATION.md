---
phase: 144
slug: funnel-query-viz-campaign-anchor-retrofit-money-formatter-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
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

> Filled by the planner after PLAN.md files are generated. Each row maps a task to its automated verification command. Wave 0 rows are infrastructure stubs only.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | DAN-08 | — | N/A | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs:safe_cast` | ✅ | ⬜ pending |
| 144-02-01 | 02 | 1 | DAN-02 | — | campaign_anchor present on dunning.exhausted | unit | `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs` | ✅ | ⬜ pending |
| 144-02-02 | 02 | 1 | DAN-02 | — | campaign_anchor present on dunning.recovered | unit | `cd accrue && mix test test/accrue/webhook/dunning_campaign_keying_test.exs` | ✅ | ⬜ pending |
| 144-03-01 | 03 | 2 | DAN-01 | — | funnel/1 returns DISTINCT-tuple stage counts | unit | `cd accrue && mix test test/accrue/analytics/dunning_test.exs:funnel` | ✅ | ⬜ pending |
| 144-03-02 | 03 | 2 | DAN-01 | — | property: recovered+exhausted+active ≤ entered | property | `cd accrue && mix test test/accrue/analytics/dunning_test.exs:funnel_property` | ✅ | ⬜ pending |
| 144-04-01 | 04 | 3 | DAN-09 | — | FunnelChart renders proportional bars + legend | unit | `cd accrue_admin && mix test test/accrue_admin/components/funnel_chart_test.exs` | ✅ | ⬜ pending |
| 144-05-01 | 05 | 3 | DAN-13 | — | RecoveryLive renders ¥ for JPY | live | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs:jpy` | ✅ | ⬜ pending |
| 144-05-02 | 05 | 3 | DAN-09, DAN-13 | — | Funnel rendered below KPI grid; "Exhausted MRR" label | live | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs:funnel_and_copy` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: Final Task IDs, plan numbers, and wave assignments are authoritative in the corresponding `*-PLAN.md` frontmatter. The planner fills the canonical map; this is the validation contract scaffold.*

---

## Wave 0 Requirements

> Wave 0 verifies test infrastructure exists before Wave 1 begins. For Phase 144, no new framework install is needed — ExUnit + `stream_data` are already in `mix.exs`. Existing test files cover all target surfaces; no new conftest-equivalent needed.

- [x] `accrue/test/accrue/analytics/dunning_test.exs` — existing; funnel + safe-cast tests append here
- [x] `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` — existing; campaign_anchor assertion extends `:308-311`
- [x] `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` — existing; campaign_anchor assertion on recovered edge
- [x] `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — existing; JPY regression + funnel render tests append here
- [ ] `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` — NEW file (Wave 0 creates the stub before Wave 3 FunnelChart implementation lands)
- [x] `stream_data ~> 1.3` — already in `accrue/mix.exs` per project STACK
- [x] No new mix deps required

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual confirmation of funnel proportional bars rendering correctly in browser (Chrome + Firefox, light + dark theme) | DAN-09 | LiveView render tests assert HTML structure but not visual proportions or theme-token resolution | Boot `cd accrue_admin && mix phx.server`; visit `/billing/analytics/recovery` with seeded events; verify bars are visibly proportional and tones (`slate/moss/amber`) render in both themes |
| Tooltip copy on Exhausted stage reads as worked yearly-plan example | DAN-09 success criterion #5 | Tooltip copy is content review; render tests can assert presence but copy quality is editorial | Hover over Exhausted bar/legend row; confirm the copy explains yearly-plan annualization in plain English |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (only `funnel_chart_test.exs` stub needed)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
