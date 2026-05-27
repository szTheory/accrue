---
phase: 146
plan: "03"
subsystem: admin-ui/analytics
tags: [dunning, at-risk-table, phoenix-component, liveview, tdd]
dependency_graph:
  requires: ["146-01", "146-02"]
  provides: [AtRiskTable, at_risk_table/1, at-risk-assign-in-RecoveryLive]
  affects:
    - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
tech_stack:
  added: []
  patterns:
    - Phoenix.Component stateless function component with :list attr
    - format_eta/1 + format_failure/1 private helpers outside ~H template
    - TDD RED/GREEN cycle for LiveView integration tests
    - Static file-read assertion for cross-package boundary enforcement
key_files:
  created:
    - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
decisions:
  - "AtRiskTable uses <section> root (not <article>) per UI-SPEC layout contract — matches analytics-table semantic vs chart-article distinction"
  - "format_failure/1 extracts stripe_event_id from raw pf.data map per D-06 honest-default; nil -> \"—\" for pre-v1.44 rows"
  - "base_path attr uses @admin_mount_path (not @current_path) in RecoveryLive so drill-down href root follows mount path, not current analytics path"
metrics:
  duration: "3m"
  completed: "2026-05-27"
  tasks: 2
  files: 4
---

# Phase 146 Plan 03: AtRiskTable Component + RecoveryLive Wiring Summary

**One-liner:** `AccrueAdmin.Components.AtRiskTable` renders at-risk subscriptions below the recovery funnel; `RecoveryLive.handle_params/3` calls `Dunning.at_risk_subscriptions/1` and assigns `@at_risk`; 3 new DAN-11 tests pass including a static cross-package boundary assertion.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | AtRiskTable component + CSS classes | e199cd4a | at_risk_table.ex, app.css |
| 2 (RED) | Failing at-risk table tests (DAN-11 RED gate) | bea0419b | recovery_live_test.exs |
| 2 (GREEN) | Wire RecoveryLive to render AtRiskTable | f097ab62 | recovery_live.ex |

## What Was Built

### Task 1: AccrueAdmin.Components.AtRiskTable

New `accrue_admin/lib/accrue_admin/components/at_risk_table.ex`:

- `use Phoenix.Component` (stateless function component — NOT LiveComponent)
- `attr(:rows, :list, required: true)` — list of maps from `Dunning.at_risk_subscriptions/1`
- `attr(:base_path, :string, default: "/billing")` — mount-path prefix for drill-down hrefs
- `attr(:class, :string, default: nil)`
- Root: `<section class={["ax-card", "ax-at-risk-table", @class]}>` per UI-SPEC (section not article)
- Header: `<header class="ax-at-risk-header">` with count subtext: `{length(@rows)} active dunning campaigns in this window`
- `<table :if={not Enum.empty?(@rows)} class="ax-at-risk-grid">` with columns: Customer, Days in Campaign, Current Step, Next-Step ETA, Last Failure Reason (`scope="col"` on all `<th>`)
- `<tbody>` iterates `row <- @rows` rendering all 5 columns
- Customer cell: `<a href="{base_path}/analytics/recovery/subscriptions/{subscription_id}" class="ax-link">` — stub for Phase 147 route
- `<div :if={Enum.empty?(@rows)} class="ax-empty-state" data-role="empty-state">` with "No active dunning campaigns" heading + positive-framing body copy
- `defp format_eta(nil)` → `"—"`; `defp format_eta(%DateTime{})` → `Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")`
- `defp format_failure(nil)` → `"—"`; `defp format_failure(data)` when `is_map(data)` → `Map.get(data, "stripe_event_id", "—") || "—"`

Appended to `accrue_admin/assets/css/app.css`:
- `.ax-at-risk-table { overflow-x: auto; }` — horizontal scroll on narrow viewports
- `.ax-at-risk-header { display: flex; align-items: baseline; justify-content: space-between; ... }`
- `.ax-at-risk-grid { width: 100%; border-collapse: collapse; }` + cell padding + `thead` strong border + last-child no-border + hover background via `color-mix`

### Task 2: RecoveryLive wiring + DAN-11 test suite

Modified `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`:

- `AtRiskTable` added to Components alias: `alias AccrueAdmin.Components.{AppShell, AtRiskTable, Breadcrumbs, FunnelChart, KpiCard, WindowSelector}`
- `handle_params/3`: `at_risk = Dunning.at_risk_subscriptions(since: since, until: until)` added after `funnel` call
- `|> assign(:at_risk, at_risk)` added to socket assign chain
- `render/1`: `<AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />` inserted between FunnelChart and `</section>`
- No `import Ecto.Query`, `Accrue.Repo`, or `Accrue.Billing.Subscription` — D-14 maintained

Extended `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` with new `describe "at-risk table (DAN-11)"` block:

| Test | Assertion | Result |
|------|-----------|--------|
| renders At-Risk Subscriptions section | `html =~ "At-Risk Subscriptions"` + empty state or count copy | PASS |
| window change via render_patch | `render_patch` to `?window=7d` doesn't crash; still renders section | PASS |
| cross-package boundary static assertion | `refute source =~ "import Ecto.Query"` + Repo + Subscription | PASS |

## Verification

Final run: `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0`

**Result: 12 tests, 0 failures**

Core cross-package regression: `cd accrue && mix test test/accrue/analytics/at_risk_subscriptions_test.exs test/accrue/analytics/dunning_test.exs test/accrue/billing/query_test.exs test/accrue/webhook/dunning_campaign_start_test.exs --seed 0`

**Result: 32 tests, 0 failures**

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

One intentional stub documented:

- **Customer drill-down href** (`accrue_admin/lib/accrue_admin/components/at_risk_table.ex`, `<a href={@base_path <> "/analytics/recovery/subscriptions/" <> row.subscription_id}>`): resolves to 404 until Phase 147 ships the per-subscription route. Accepted per T-146-07: operator-only UI, non-sensitive UUID reference, Phase 147 closes the route. The href is not a broken `#` — it's a forward-reference stub.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.

- T-146-06 mitigated: HEEx `{}` interpolation auto-escapes all values; no `raw/1` or `{:safe, ...}` used
- T-146-07 accepted: drill-down href uses `subscription_id` UUID, operator-only, 404 until Phase 147
- T-146-08 mitigated: D-14 enforced; static test assertion `refute source =~ "import Ecto.Query"` catches violations

## TDD Gate Compliance

Task 2 followed strict RED/GREEN cycle:

- RED: `test(146-03)` commit bea0419b — 2 tests failed (component not wired), 1 test passed (static assertion)
- GREEN: `feat(146-03)` commit f097ab62 — all 12 tests pass

RED gate confirmed: tests 1 and 2 failed before implementation because `@at_risk` assign didn't exist.

## Self-Check: PASSED

- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` — created, exists ✓
- `accrue_admin/assets/css/app.css` — modified, `.ax-at-risk-table` and `.ax-at-risk-grid` present ✓
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — modified, `AtRiskTable` alias + `at_risk_subscriptions` call + `assign(:at_risk, at_risk)` + render ✓
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — modified, 3 new DAN-11 tests ✓
- Commit e199cd4a exists ✓
- Commit bea0419b exists ✓
- Commit f097ab62 exists ✓
- `mix test recovery_live_test.exs --seed 0`: 12 tests, 0 failures ✓
- `mix test` core at_risk + dunning + query + campaign_start: 32 tests, 0 failures ✓
