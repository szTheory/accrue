---
phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po
verified: 2026-05-27T13:15:00Z
status: passed
score: 14/14 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: null
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 144: Funnel Query + Viz + Campaign-Anchor Retrofit + Money Formatter Verification Report

**Phase Goal:** Operators see a credible 3-stage dunning funnel (Entered → Recovered → Exhausted) rendered as inline-SVG below the existing KPI cards on `/billing/analytics/recovery`, with no double-counting under cycled-dunning subscriptions, no dashboard crash from a single malformed JSONB row, and money labels that render correctly for any currency (JPY, EUR, GBP, USD).

**Verified:** 2026-05-27T13:15:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (mapped to ROADMAP Success Criteria)

| #   | Truth                                                                                                                                         | Status     | Evidence                                                                                                                                                                                                                                                                            |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SC1 | Operator visits `/billing/analytics/recovery` and sees 3-stage funnel below KPI cards with stage labels + counts + percentages                | VERIFIED   | `recovery_live.ex:71-76` renders `<FunnelChart.funnel_chart>` element immediately after the `<section class="ax-kpi-grid">` close (line 69). `funnel_chart.ex:44-101` renders the three `<g class="ax-funnel-row--{slate,moss,amber}">` rows with `<rect>` bars + external `<dl>` legend (one row per stage, with `({pct}%)` annotation for Recovered/Exhausted). |
| SC2 | Cycled-dunning subscription appears as `entered: 3, recovered: 1, exhausted: 1, active: 1` — DISTINCT tuples; `recovered + exhausted + active ≤ entered` property holds | VERIFIED   | `dunning.ex:117-143` groups by `[e.subject_id, fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", e.data)]` with outer mutually-exclusive `count()` filters. Unit test "cycled dunning" in `dunning_test.exs` asserts the exact `entered:3, recovered:1, exhausted:1, active:1` shape. Property test in `dunning_funnel_property_test.exs:42` asserts the invariant across 100 StreamData runs. |
| SC3 | Inserting a single `dunning.recovered` with `"mrr_value_cents": "5000"` (string) does NOT crash the dashboard — contributes 0 and the page renders | VERIFIED   | `dunning.ex:51-55` wraps the cast in `CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END`. Regression test "does not crash when a malformed string-typed mrr_value_cents row is present (DAN-08)" asserts `%{recovered_cents: 1000, lost_cents: 0}` from a mix of string+integer rows. |
| SC4 | Both KPI cards plus the new funnel render currency-correct labels (JPY shows ¥, USD shows $, EUR shows €) — no more USD-only `:erlang.float_to_binary` rendering | VERIFIED   | `recovery_live.ex:19-22` reads `currency = Accrue.Config.get!(:default_currency)` + `locale = Accrue.Config.default_locale()` and calls `Accrue.Invoices.Render.format_money/3` for both KPI values. `grep -c ':erlang.float_to_binary' recovery_live.ex` → 0 (helper deleted). JPY regression test in `recovery_live_test.exs:153` asserts `refute "$50.00"` and `assert "¥" or "￥" or "JPY"`. |
| SC5 | Funnel renames the previously-shipped "Lost MRR" copy to "Exhausted MRR" with a tooltip defining the term and a worked example for yearly-plan customers | VERIFIED   | `recovery_live.ex:62` renders `label="Exhausted MRR"`. `recovery_live.ex:64` carries delta string with `"a $120/yr plan contributes $10/mo to Exhausted MRR"`. `funnel_chart.ex:75-77` renders the Exhausted-bar `<title>` tooltip with the same worked example. `grep -c "Lost MRR" recovery_live.ex` → 0. Tests assert both `html =~ "Exhausted MRR"` AND `refute html =~ "Lost MRR"`. |

**Score:** 5/5 ROADMAP Success Criteria verified

### Plan-level Truths (from each PLAN's must_haves frontmatter)

| #    | Plan | Truth                                                                                                                                                  | Status     | Evidence                                                                                                                                                                                                  |
| ---- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P01-T1 | 01 | `Dunning.funnel/1` returns `%{entered, recovered, exhausted, active}` over a window                                                                    | VERIFIED   | `dunning.ex:111-143`; `@spec` declared on lines 111-116; unit + property tests green                                                                                                                       |
| P01-T2 | 01 | Cycled subject (3 anchors, same subject_id, 1 recovered + 1 exhausted + 1 active) reports entered=3, recovered=1, exhausted=1, active=1               | VERIFIED   | Unit test in `dunning_test.exs` (describe "funnel/1") asserts this; SQL log shows the DISTINCT-tuple GROUP BY                                                                                              |
| P01-T3 | 01 | String-typed `"mrr_value_cents": "5000"` does NOT crash `recovered_vs_lost_mrr/1`; malformed row contributes 0                                          | VERIFIED   | `dunning.ex:51-55` safe-cast; regression test runs to completion green                                                                                                                                    |
| P01-T4 | 01 | Property test `recovered + exhausted + active <= entered` holds                                                                                        | VERIFIED   | `dunning_funnel_property_test.exs:42` (1 property, 100 default StreamData runs); test passes                                                                                                              |
| P01-T5 | 01 | Funnel runs as a SINGLE Ecto query (one `Repo.one` call wrapping a `subquery/1`; no `Task.async` per stage)                                            | VERIFIED   | SQL log in 144-01-SUMMARY shows `SELECT count(*), count(*) FILTER ... FROM (SELECT bool_or ... GROUP BY ...) AS s0` — single round trip. `grep -c "Task.async" dunning.ex` → 0. |
| P02-T1 | 02 | `dunning.exhausted` event payload carries `data.campaign_anchor` as ISO-8601 string when anchor active, OR `nil` for Stripe-native non-Accrue path     | VERIFIED   | `default_handler.ex:794-798` defensive `case` produces `iso_anchor` (binary-or-nil); `default_handler.ex:828` appends `campaign_anchor: iso_anchor` to the data map; both branches covered by tests        |
| P02-T2 | 02 | `dunning.recovered` event payload carries `data.campaign_anchor` as ISO-8601 string of cleared anchor; Ecto.Multi atomicity preserved                  | VERIFIED   | `default_handler.ex:915` appends `campaign_anchor: iso_anchor` (line 884 binding); `Events.record_multi` still in the same `multi` with `:clear_anchor` (line 889-892)                                     |
| P02-T3 | 02 | Exhausted-edge defensive `case` handles nil anchor without raising (no nil.year KeyError)                                                              | VERIFIED   | `default_handler.ex:794-798` uses `case row.dunning_campaign_started_at do %DateTime{} = dt -> ... ; _ -> nil end`; nil-anchor test exists in `dunning_exhaustion_test.exs` (passes)                       |
| P03-T1 | 03 | `FunnelChart.funnel_chart/1` is a functional `Phoenix.Component` (NOT `Phoenix.LiveView`) — no socket runtime                                          | VERIFIED   | `funnel_chart.ex:30` `use Phoenix.Component`; `grep -c "use Phoenix.LiveView" funnel_chart.ex` → 0                                                                                                          |
| P03-T2 | 03 | Rendering with entered=10/rec=4/exh=3/act=3 produces 3 `<rect>` bars + external `<dl>` legend with all four counts                                     | VERIFIED   | `funnel_chart.ex:64,69,74` (three `<rect>` elements), `funnel_chart.ex:82-99` (legend); component test "renders all 4 counts in legend" passes                                                              |
| P03-T3 | 03 | When entered=0, component renders without dividing by zero                                                                                             | VERIFIED   | `funnel_chart.ex:104` `defp pct(_n, 0), do: 0`; component test "guards against division-by-zero when entered: 0" passes                                                                                   |
| P03-T4 | 03 | Component renders "Recovered MRR" tooltip with yearly-plan worked-example copy on Exhausted stage                                                       | VERIFIED   | `funnel_chart.ex:76` Exhausted `<title>` carries `"A $120/yr plan that exhausts dunning contributes $10/mo to Exhausted MRR"`; test "renders Exhausted tooltip with yearly-plan worked example" passes      |
| P04-T1 | 04 | Operator visiting `/billing/analytics/recovery` sees FunnelChart rendered below `ax-kpi-grid` section                                                  | VERIFIED   | `recovery_live.ex:51-69` (`<section class="ax-kpi-grid">`), `recovery_live.ex:71-76` (`<FunnelChart.funnel_chart>` immediately after)                                                                       |
| P04-T2 | 04 | `RecoveryLive.format_minor/1` deleted; uses `Accrue.Config.get!(:default_currency)` (NOT `Application.compile_env`); calls `Render.format_money/3`     | VERIFIED   | `grep -c "format_minor" recovery_live.ex` → 0; `grep -c "Application.compile_env" recovery_live.ex` → 0; `grep -c "Accrue.Invoices.Render.format_money" recovery_live.ex` → 2                              |

**Score:** 14/14 plan-level must-have truths verified

### Required Artifacts (Three-Level Verification)

| Artifact                                                                                          | Expected                                                              | Status       | Details                                                                                                                                                  |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `accrue/lib/accrue/analytics/dunning.ex`                                                          | `funnel/1` + safe-cast wrap on `recovered_vs_lost_mrr/1`                | ✓ VERIFIED   | Exists, substantive (160 lines), wired — used by `recovery_live.ex:12-13`, tested by 8 unit tests + 1 property test                                       |
| `accrue/test/accrue/analytics/dunning_test.exs`                                                   | `describe "funnel/1"` + DAN-08 safe-cast regression                     | ✓ VERIFIED   | Both describe blocks present; all tests pass                                                                                                              |
| `accrue/test/property/dunning_funnel_property_test.exs`                                           | Property test for DISTINCT-tuple invariant                              | ✓ VERIFIED   | File exists, contains `property "recovered + exhausted + active <= entered..."`, runs 100 StreamData iterations, passes                                  |
| `accrue/lib/accrue/webhook/default_handler.ex`                                                    | `campaign_anchor: iso_anchor` at lines ~828 (exhausted) + ~915 (recovered) | ✓ VERIFIED   | Both sites carry `campaign_anchor:`; `grep -c "campaign_anchor:" default_handler.ex` → 2. Exhausted-edge defensive case at 794-798; recovered-edge reuses `iso_anchor` from line 884 |
| `accrue/test/accrue/webhook/dunning_exhaustion_test.exs`                                          | Emission-boundary tests: anchor-present + nil-anchor branches            | ✓ VERIFIED   | Tests assert `is_binary(ledger.data["campaign_anchor"])` + `DateTime.from_iso8601` round-trip + nil branch; 11 tests pass                                  |
| `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs`                                     | Recovered-edge emission boundary + Multi atomicity                       | ✓ VERIFIED   | Extends existing DUN-08 observability block; tests pass; Multi atomicity test post-clear: `is_nil(Repo.reload!(sub).dunning_campaign_started_at)`           |
| `accrue_admin/lib/accrue_admin/components/funnel_chart.ex`                                        | FunnelChart functional component                                        | ✓ VERIFIED   | Exists (106 lines); `use Phoenix.Component`; 5 attr declarations; a11y contract (role=img + aria-labelledby + linked title/desc); worked-example copy; tone-keyed rows |
| `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs`                                 | 6 tests via `Phoenix.LiveViewTest.render_component/2`                    | ✓ VERIFIED   | All 6 tests pass: counts/legend, percentages, zero-divide guard, a11y contract, worked-example, tone-keyed rows                                            |
| `accrue_admin/assets/css/app.css`                                                                 | `.ax-funnel-*` block (11 selectors)                                     | ✓ VERIFIED   | `grep -c '.ax-funnel' app.css` → 11; appended after `.ax-kpi-sparkline path` at line 560; reuses existing `--ax-*` tokens                                  |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`                                   | Funnel + MoneyFormatter swap + label rename + FunnelChart slot          | ✓ VERIFIED   | All five edits present (alias, mount/3 wiring, FunnelChart slot, KpiCard rename, format_minor deletion); 99 lines; clean compile                          |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`                            | JPY regression + funnel-render + Exhausted-MRR copy tests               | ✓ VERIFIED   | All 4 tests pass: rename update + funnel render + JPY regression + worked-example copy                                                                    |

### Key Link Verification

| From                                              | To                                              | Via                                                          | Status   | Details                                                                                                                |
| ------------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------ | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| `dunning.ex` `funnel/1`                           | `accrue_events` table                           | `from(e in Event, ...)` Ecto JSONB query                     | WIRED    | `dunning.ex:119-129` query references `Event` schema; ledger reads via JSONB fragments                                  |
| `dunning.ex` `recovered_vs_lost_mrr/1`            | PostgreSQL safe-cast                            | `fragment/1` with `CASE WHEN jsonb_typeof`                    | WIRED    | `dunning.ex:51-55` fragment matches pattern verbatim                                                                    |
| `default_handler.ex` `maybe_emit_dunning_exhaustion/3` | `Events.record/1` data jsonb payload          | `campaign_anchor: iso_anchor` map key                        | WIRED    | `default_handler.ex:828` `campaign_anchor: iso_anchor` inside Events.record data map; defensive case at 794-798        |
| `default_handler.ex` `maybe_finalize_dunning_campaign/3` | `Events.record_multi/3` inside Ecto.Multi  | `iso_anchor` already in scope at line 884; one-line append    | WIRED    | `default_handler.ex:915` `campaign_anchor: iso_anchor` in record_multi data map; Multi atomicity preserved (clear_anchor + record_multi in same Multi) |
| `recovery_live.ex` `mount/3`                      | `Accrue.Analytics.Dunning.funnel/1`              | `Dunning.funnel()` call                                       | WIRED    | `recovery_live.ex:13` `funnel = Dunning.funnel()`; assigned to socket at line 28                                       |
| `recovery_live.ex` `render/1`                     | `AccrueAdmin.Components.FunnelChart`            | `<FunnelChart.funnel_chart entered={@funnel.entered} ... />` | WIRED    | `recovery_live.ex:71-76` element present with all 4 attrs sourced from `@funnel`                                       |
| `recovery_live.ex` `mount/3`                      | `Accrue.Invoices.Render.format_money/3`         | `Accrue.Config.get!(:default_currency)` + `default_locale()` | WIRED    | `recovery_live.ex:19-22` reads runtime config + calls format_money twice (recovered_str, exhausted_str)                |
| `funnel_chart.ex`                                 | `accrue_admin/assets/css/app.css`               | `.ax-funnel-*` class names referenced in component            | WIRED    | Component references `ax-funnel-chart`, `ax-funnel-row--{slate,moss,amber}`, `ax-funnel-bar`, `ax-funnel-legend`, `ax-funnel-active-chip`, `ax-funnel-header`, `ax-funnel-svg` — all 11 classes present in app.css |

All 8 key links WIRED.

### Data-Flow Trace (Level 4)

| Artifact                                | Data Variable                                          | Source                                                                                       | Produces Real Data | Status     |
| --------------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------------------------------------- | ------------------ | ---------- |
| `recovery_live.ex` `:funnel` assign     | `@funnel.entered/recovered/exhausted/active`            | `Dunning.funnel()` → `Repo.one(query)` over `accrue_events` ledger                          | Yes — DB query     | ✓ FLOWING  |
| `recovery_live.ex` `:recovered_str`     | KPI card `value` attr                                  | `Render.format_money(stats.recovered_cents, currency, locale)` where stats comes from DB    | Yes — DB+CLDR      | ✓ FLOWING  |
| `recovery_live.ex` `:exhausted_str`     | KPI card `value` attr                                  | `Render.format_money(stats.lost_cents, currency, locale)`                                    | Yes — DB+CLDR      | ✓ FLOWING  |
| `funnel_chart.ex` `@entered/etc`        | SVG `<rect width>` + legend `<dd>` text                | Props passed from `recovery_live.ex` (which sources from `Dunning.funnel()`)                | Yes — props flow   | ✓ FLOWING  |

All artifacts that render dynamic data have real DB-sourced data flowing through them.

### Behavioral Spot-Checks

| Behavior                                                                         | Command                                                                                                       | Result                                  | Status   |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | --------------------------------------- | -------- |
| `Dunning.funnel/1` returns 4-key map; safe-cast handles malformed JSONB           | `cd accrue && mix test test/accrue/analytics/dunning_test.exs test/property/dunning_funnel_property_test.exs` | `1 property, 8 tests, 0 failures`       | ✓ PASS   |
| Webhook exhausted/recovered emit campaign_anchor                                  | `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs test/accrue/webhook/dunning_campaign_keying_test.exs` | `21 tests, 0 failures`                  | ✓ PASS   |
| FunnelChart component + RecoveryLive LiveView green                              | `cd accrue_admin && mix test test/accrue_admin/components/funnel_chart_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs` | `10 tests, 0 failures`                  | ✓ PASS   |
| `:erlang.float_to_binary` deleted from recovery_live.ex                          | `grep -c ':erlang.float_to_binary' recovery_live.ex`                                                          | `0`                                     | ✓ PASS   |
| `Application.compile_env` absent from recovery_live.ex (Pitfall #4)              | `grep -c 'Application.compile_env' recovery_live.ex`                                                          | `0`                                     | ✓ PASS   |
| `Lost MRR` rename complete                                                       | `grep -c 'Lost MRR' recovery_live.ex`                                                                          | `0`                                     | ✓ PASS   |
| `use Phoenix.LiveView` absent from FunnelChart (LiveView-runtime-free)           | `grep -c 'use Phoenix.LiveView' funnel_chart.ex`                                                              | `0`                                     | ✓ PASS   |
| `campaign_anchor:` appears twice in default_handler.ex (exhausted + recovered)   | `grep -c 'campaign_anchor:' default_handler.ex`                                                               | `2`                                     | ✓ PASS   |
| `.ax-funnel` CSS block has 11 selectors                                          | `grep -c '\.ax-funnel' accrue_admin/assets/css/app.css`                                                       | `11`                                    | ✓ PASS   |

All 9 behavioral spot-checks PASS.

### Probe Execution

No project-convention probes (`scripts/*/tests/probe-*.sh`) are present in this repo, and no PLAN/SUMMARY declares probe paths. Skipped (no applicable probes).

### Requirements Coverage

| Requirement | Source Plan | Description                                                                          | Status      | Evidence                                                                                                                                            |
| ----------- | ---------- | ------------------------------------------------------------------------------------ | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| DAN-01      | 144-01     | Funnel public API — `funnel/1` returns `%{entered, recovered, exhausted, active}`     | ✓ SATISFIED | `dunning.ex:111-143` implementation; 5 unit tests in `describe "funnel/1"` + 1 property test; @spec declared                                         |
| DAN-02      | 144-02     | Campaign-anchor snapshot retrofit on `dunning.recovered` + `dunning.exhausted`        | ✓ SATISFIED | `default_handler.ex:794-798,828` (exhausted defensive case) + `default_handler.ex:884,915` (recovered iso_anchor reuse); emission-boundary tests pass |
| DAN-08      | 144-01     | JSONB cast safety — `CASE WHEN jsonb_typeof` wrap                                     | ✓ SATISFIED | `dunning.ex:51-55` safe-cast fragment; regression test asserts malformed row contributes 0 cents                                                     |
| DAN-09      | 144-03+04  | Funnel visualization on `/billing/analytics/recovery`                                 | ✓ SATISFIED | `funnel_chart.ex` component (106 lines); `.ax-funnel-*` CSS block (11 selectors); `recovery_live.ex:71-76` wires component below KPI grid           |
| DAN-13      | 144-04     | MoneyFormatter polish — fix USD-only `:erlang.float_to_binary` bug                    | ✓ SATISFIED | `recovery_live.ex:21-22` uses `Render.format_money/3` driven by `Config.get!(:default_currency)` + `default_locale()`; JPY regression test passes    |

REQUIREMENTS.md (lines 13-84) confirms all 5 requirements are marked `[x]` complete.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |

No anti-patterns found in modified files. Specifically:
- No `TBD`/`FIXME`/`XXX` debt markers in any modified file
- No `:erlang.float_to_binary`, `Application.compile_env`, or `Lost MRR` in `recovery_live.ex`
- No `Task.async` in `dunning.ex`
- No `use Phoenix.LiveView` in `funnel_chart.ex` (LiveView-runtime-free posture preserved)
- No empty/stub implementations
- No hardcoded empty data flowing to render
- No props with hardcoded empty values

### Forward-Fix Notes (Code Reviewer CR-01)

The code reviewer flagged CR-01 (multi-currency aggregation bug in `recovered_vs_lost_mrr/1` — sums across currencies without filtering). Per orchestrator guidance, this is a forward-fix debt item, not a Phase 144 failure:

- **Scope of CR-01:** Data-layer multi-currency aggregation (totals correctly partition multi-currency tenants)
- **Scope of Phase 144 DAN-13:** Display-time CLDR formatting (labels render correctly for the configured tenant currency)
- **Where it is addressed:** Phase 148 DAN-07 "Cross-currency aggregation widening" — explicitly bundles the BREAKING return-shape widening from `%{recovered_cents, lost_cents}` to per-currency lists; this is a SEMVER LOCK-IN item that must ship before the v1.4.0 Hex publish.
- **Today:** Single-currency-per-tenant adopters see correct rendering (the vast majority). Mixed-currency adopters see an aggregate cents total displayed in the tenant's default currency — observable in production but not failing any current test fixture or Phase 144 success criterion.

The code reviewer also identified WR-01..WR-06 warnings + IN-01..IN-04 info items. None of these block Phase 144's stated success criteria; they are quality-improvement debt for future polish phases.

### Gaps Summary

No gaps. All 5 ROADMAP Success Criteria met, all 14 plan-level must-haves verified, all 11 required artifacts pass three-level checks, all 8 key links WIRED, all 4 data flows confirmed real, all 9 behavioral spot-checks PASS, all 5 requirement IDs SATISFIED.

The "Lost MRR" → "Exhausted MRR" rename is enforced by both an `assert` and a `refute` in `recovery_live_test.exs`. The cycled-dunning invariant has both a unit test (asserting the exact `entered:3, recovered:1, exhausted:1, active:1` shape) and a property test (100 StreamData iterations). The JPY regression is exercised through a true LiveView mount that flips `Application.put_env(:accrue, :default_currency, :jpy)` and verifies `¥`/`￥`/`JPY` appears while `"$50.00"`/`"$20.00"` does not. The dashboard-DoS safety is tested end-to-end: a `dunning.recovered` row with `"mrr_value_cents": "5000"` (string) is inserted alongside an integer-typed row, and the aggregation returns `%{recovered_cents: 1000, lost_cents: 0}` without raising.

Pre-existing test failures noted by the orchestrator (`Accrue.Docs.ReleaseNotesContractTest` drift + 3 `email_preview_live_test`/`connect_account_live_test` form-selector collisions from Phase 134) are out of scope for Phase 144 and documented in `deferred-items.md`.

---

_Verified: 2026-05-27T13:15:00Z_
_Verifier: Claude (gsd-verifier)_
