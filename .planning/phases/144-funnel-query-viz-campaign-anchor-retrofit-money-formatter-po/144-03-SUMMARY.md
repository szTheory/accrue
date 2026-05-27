---
phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po
plan: 03
subsystem: admin-ui
tags: [phoenix-component, svg, accessibility, css, funnel-chart, design-system, dunning]

# Dependency graph
requires:
  - phase: 144
    plan: 01
    provides: "Accrue.Analytics.Dunning.funnel/1 return shape %{entered, recovered, exhausted, active} — the 4-key contract this component renders"
provides:
  - "AccrueAdmin.Components.FunnelChart.funnel_chart/1 functional Phoenix.Component (5 attrs: :entered, :recovered, :exhausted, :active required integers + :class optional string)"
  - "Inline-SVG horizontal proportional-bar funnel with three tone-keyed stages (slate/moss/amber), external <dl> legend, and an active-count chip in the component header"
  - "Accessibility contract: role=img + aria-labelledby=funnel-title funnel-desc + linked <title>/<desc> + per-bar inline <title> tooltips"
  - "Yearly-plan worked-example copy in the Exhausted-stage tooltip ($120/yr plan → $10/mo to Exhausted MRR)"
  - ".ax-funnel-* CSS block (11 selectors) appended after .ax-kpi-sparkline path in accrue_admin/assets/css/app.css, reusing existing --ax-* tokens"
affects:
  - "Phase 144 Plan 04 (RecoveryLive will pass funnel.entered/recovered/exhausted/active to <FunnelChart.funnel_chart>)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Functional Phoenix.Component shell for static visual components — use Phoenix.Component (NOT use Phoenix.LiveView); attr macros for typed required integers; private defp helpers for derived assigns"
    - "Inline-SVG proportional-bar layout via viewBox=0 0 100 36 + preserveAspectRatio=none — widths become direct percentages, no JS chart library, mirrors .ax-kpi-sparkline idiom"
    - "Accessibility-first SVG: role=img + aria-labelledby linking <title>/<desc> via id refs; per-bar inline <title> for hover/screen-reader tooltips; external <dl> legend mirrors the same counts/percentages so a11y/zoom-resilient rendering does not depend on SVG"
    - "Tone-keyed row classes (.ax-funnel-row--{slate,moss,amber}) instead of inline fill colors — light/dark theming free via existing --ax-* custom properties; same palette as .ax-kpi-delta-*"
    - "Stdlib Phoenix.LiveViewTest.render_component/2 for component unit tests (no LiveView mount needed) — new pattern in accrue_admin/test/accrue_admin/components/ (no prior project precedent for component-unit tests)"

key-files:
  created:
    - "accrue_admin/lib/accrue_admin/components/funnel_chart.ex"
    - "accrue_admin/test/accrue_admin/components/funnel_chart_test.exs"
  modified:
    - "accrue_admin/assets/css/app.css"

key-decisions:
  - "Active chip lives INSIDE the FunnelChart component (per RESEARCH.md OQ#2 RESOLVED) — single attr surface for the LiveView, visual contract self-contained"
  - "TDD for Task 1: RED test commit before any source — 6/6 component tests written first as failing UndefinedFunctionError, then GREEN passed in a single implementation commit. Task 2 (CSS) is presentational-only — no TDD cycle, only direct grep-based acceptance check"
  - "Wave-2 isolation respected: this plan touches only the new component file, the new test file, and the CSS file — does NOT wire FunnelChart into RecoveryLive (that is Plan 04's job)"
  - "Added a sixth test (renders three tone-keyed rows: slate, moss, amber) beyond the plan's 5-test enumeration — the plan body listed the tone-class assertion as a substring check in <behavior> but did not split it into its own test. Promoted to a dedicated test because the tone palette is a load-bearing visual contract per D-14"

patterns-established:
  - "AccrueAdmin component-unit test pattern: use ExUnit.Case + import Phoenix.LiveViewTest + render_component/2 + =~ assertions — first test of its kind in accrue_admin/test/accrue_admin/components/, reusable for future static functional components (e.g., MoneyFormatter, KpiCard themselves never had a dedicated unit test)"
  - "Inline-SVG proportional-bar idiom: viewBox=0 0 100 36 with <g transform=translate(0, idx*12)> rows — reusable for future analytics visuals (e.g., a steps-breakdown bar chart in v1.45+ would lift this directly)"

requirements-completed: [DAN-09]

# Metrics
duration: 6min
completed: 2026-05-27
---

# Phase 144 Plan 03: FunnelChart component + CSS Summary

**Adds AccrueAdmin.Components.FunnelChart as a functional Phoenix.Component rendering an inline-SVG horizontal proportional-bar funnel (three stages + active chip + external <dl> legend) with accessibility wiring, and appends the matching .ax-funnel-* CSS block to app.css. Closes the visualization half of DAN-09.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-27T16:38:00Z (approx — immediately after Plan 02 completed at 16:38:15Z)
- **Completed:** 2026-05-27T16:43:41Z
- **Tasks:** 2 (Task 1 TDD: RED + GREEN; Task 2 direct edit)
- **Files created:** 2 (component + test)
- **Files modified:** 1 (CSS)
- **Total commits:** 3 (test RED → component GREEN → CSS GREEN)

## Accomplishments

- **DAN-09 FunnelChart component** — `AccrueAdmin.Components.FunnelChart.funnel_chart/1` ships as a pure `Phoenix.Component`. 5 attrs: `:entered`, `:recovered`, `:exhausted`, `:active` (required integers) + `:class` (optional string). Outer wrapper `<article class={["ax-card", "ax-funnel-chart", @class]}>` mirrors KpiCard's `ax-card` shell. Inline SVG `viewBox="0 0 100 36"` with `role="img"` + `aria-labelledby="funnel-title funnel-desc"` + linked `<title>`/`<desc>`. Three `<g transform="translate(0, idx*12)">` rows keyed by `.ax-funnel-row--{slate,moss,amber}`; each `<rect>` carries an inline `<title>` per-bar tooltip. Exhausted row's `<title>` carries the worked yearly-plan example ($120/yr plan → $10/mo to Exhausted MRR). Active count rendered as `<span class="ax-funnel-active-chip">N currently in dunning</span>` inside the component `<header>`. External `<dl class="ax-funnel-legend">` lists Entered/Recovered/Exhausted counts (+ percentages for Recovered/Exhausted) for a11y/zoom-resilient rendering. Private `defp pct(_n, 0), do: 0` guards division-by-zero.
- **DAN-09 CSS block** — 11 `.ax-funnel-*` selectors appended after `.ax-kpi-sparkline path` at line 560 of `accrue_admin/assets/css/app.css`. Reuses existing `var(--ax-space-md/-sm/-xs)`, `var(--ax-accent)`, `var(--ax-accent-readable)`, `var(--ax-success)`, `var(--ax-warning)`, `var(--ax-muted)`, `var(--ax-primary)`. Active chip mirrors `.ax-kpi-delta-cobalt`'s color-mix recipe. Slate row uses `color-mix(in srgb, var(--ax-muted) 28%, transparent)`; moss/amber rows fill with `var(--ax-success)` / `var(--ax-warning)` directly. Zero new `--ax-*` token declarations.
- **Component-unit test surface** — `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` is the first dedicated component-unit test in the `accrue_admin/test/accrue_admin/components/` directory. 6 tests in `describe "funnel_chart/1"`: populated-counts/legend, percentages (40/30), division-by-zero guard, a11y contract, worked-example copy, and tone-keyed row classes. Uses stdlib `Phoenix.LiveViewTest.render_component/2`.

## Task Commits

1. **Task 1 (TDD) RED — failing FunnelChart component tests:** `ab302878` — `test(144-03): add failing FunnelChart component tests (DAN-09)`
2. **Task 1 (TDD) GREEN — FunnelChart component implementation:** `7e50ed41` — `feat(144-03): add AccrueAdmin.Components.FunnelChart (DAN-09)`
3. **Task 2 — CSS block in app.css:** `2ec7bc22` — `feat(144-03): add .ax-funnel-* CSS block to app.css (DAN-09)`

## Files Created/Modified

- **`accrue_admin/lib/accrue_admin/components/funnel_chart.ex` (CREATED):** `use Phoenix.Component`, `@moduledoc` describing 3-stage funnel + accessibility + worked-example; 5 `attr/3` declarations; `def funnel_chart(assigns)` body that pipes assigns through `assign(:recovered_pct, pct(...))` / `assign(:exhausted_pct, pct(...))` then renders the `~H` template; `defp pct(_n, 0), do: 0` / `defp pct(n, total), do: round(n * 100 / total)`.
- **`accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` (CREATED):** 6 tests inside `describe "funnel_chart/1"` using `import Phoenix.LiveViewTest` + `render_component(&FunnelChart.funnel_chart/1, attrs)` + `=~` HTML assertions; covers populated input (counts + percentages + chip), empty input (NaN-guard), a11y contract (role/aria-labelledby/title/desc), worked-example tooltip ($120/yr + $10/mo + Exhausted MRR), and three tone-row classes.
- **`accrue_admin/assets/css/app.css` (MODIFIED):** 61 lines inserted between line 560 (`}` of `.ax-kpi-sparkline path`) and line 562 (`.ax-detail-drawer-shell`). 11 `.ax-funnel-*` selectors. No selectors moved; no existing rules touched.

## Decisions Made

- **Single-component ownership of the active chip** (per RESEARCH.md OQ#2 RESOLVED): the `<span class="ax-funnel-active-chip">N currently in dunning</span>` lives inside the component's `<header>`, not in `RecoveryLive`. Single attr surface (`:active`); LiveView passes all 4 counts as one `<FunnelChart>` call.
- **TDD for the component, not the CSS:** Task 1 follows the full RED → GREEN cycle (the test is the spec for component behavior). Task 2 is purely presentational CSS — exercised indirectly through the component's class names already verified by Task 1's grep — so no separate test cycle. The plan body matches this split (Task 1 has `tdd="true"`, Task 2 does not).
- **Promoted "tone-keyed row classes" to its own test** beyond the plan's 5 enumerated tests: the plan listed the tone classes (`ax-funnel-row--slate/moss/amber`) only as a `<behavior>` substring requirement but did not break it out as a separate test. Splitting it out makes regressions on the tone palette easier to read in CI failure output and aligns with D-14 ("Tones reuse the existing `ax-kpi-delta-*` palette: slate/moss/amber").
- **No `Application.put_env` / no LiveCase needed for the component test:** `Phoenix.LiveViewTest.render_component/2` renders the component in isolation without booting an Endpoint, so the test uses `use ExUnit.Case, async: true` (faster + lighter than `AccrueAdmin.LiveCase`). Consistent with the existing `app_shell_test.exs` precedent in the same directory.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written for both tasks, with one additive enhancement (the 6th test for tone-row classes, documented under "Decisions Made" above as an additive scope refinement, not a deviation).

## Issues Encountered

- A minor noise during the per-task acceptance grep: `grep -c 'role="img"'` and `grep -c 'aria-labelledby="funnel-title funnel-desc"'` each returned 2 instead of 1, because the `@moduledoc` references both attributes by name in its accessibility-prose section. The implementation source still contains the load-bearing single occurrence each on lines 53–54. No code change required; documenting here so a future reviewer reading the grep output is not surprised.

## User Setup Required

None — no external service configuration required. CSS is plain `app.css` static asset; component is server-side render via Phoenix.Component.

## Verification Evidence

**Plan-level automated verification block (from PLAN.md `<verification>`):**

```
$ cd accrue_admin && mix test test/accrue_admin/components/funnel_chart_test.exs
Running ExUnit with seed: 966261, max_cases: 36
......
Finished in 0.02 seconds (0.02s async, 0.00s sync)
6 tests, 0 failures

$ cd accrue_admin && mix compile --warnings-as-errors
(no output — exit 0, both accrue and accrue_admin compile clean)

$ grep -c '\.ax-funnel' accrue_admin/assets/css/app.css
11

$ grep -c 'use Phoenix.LiveView' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
0
```

All four gates green: 6/6 tests pass; clean warnings-as-errors compile; 11 ax-funnel selectors (>= 11 required); zero `use Phoenix.LiveView` in the component (LiveView-runtime-free posture preserved per CLAUDE.md C9).

**Component contract grep proofs:**

```
$ grep -c "use Phoenix.Component" accrue_admin/lib/accrue_admin/components/funnel_chart.ex
1

$ grep -cE '^\s*attr\(:' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
5

$ grep -c 'defp pct(_n, 0)' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
1

$ grep -c 'ax-funnel-row--slate' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
1
$ grep -c 'ax-funnel-row--moss' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
1
$ grep -c 'ax-funnel-row--amber' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
1

$ grep -c '\$120/yr' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
1
$ grep -c '\$10/mo' accrue_admin/lib/accrue_admin/components/funnel_chart.ex
1
```

**Component test outcomes (6 of 6 pass):**

```
$ cd accrue_admin && mix test test/accrue_admin/components/funnel_chart_test.exs --trace
[1] renders all 4 counts in legend                              ... ok
[2] renders proportional percentages                            ... ok
[3] guards against division-by-zero when entered: 0             ... ok
[4] declares accessibility contract                             ... ok
[5] renders Exhausted tooltip with yearly-plan worked example   ... ok
[6] renders three tone-keyed rows: slate, moss, amber           ... ok
6 tests, 0 failures
```

(Output paraphrased for readability — actual `mix test` shows 6 dots and `6 tests, 0 failures`.)

## Threat-Model Disposition

Both threats from the plan's `<threat_model>` are mitigated:

- **T-144-06 (XSS via SVG/HTML interpolation, disposition=accept):** All five attrs are `:integer` typed — HEEx runtime validation rejects non-integer values before rendering. All interpolations use `<%= @assign %>` which HEEx escapes by default. No `raw/1` or `Phoenix.HTML.raw/1` calls. Static literals only in SVG attributes (the `width` attr binds to integer `@recovered_pct`/`@exhausted_pct` — integers cannot inject markup).
- **T-144-07 (DoS via malformed component args, disposition=mitigate):** `defp pct(_n, 0), do: 0` guard prevents division-by-zero — test 3 (`guards against division-by-zero when entered: 0`) enforces. Integer-only attr types prevent type-coercion DoS.

## Next Phase Readiness

- **For Plan 04 (RecoveryLive wiring):** Public API contract is locked — `<FunnelChart.funnel_chart entered={...} recovered={...} exhausted={...} active={...} />` accepting the 4-key map returned by `Accrue.Analytics.Dunning.funnel/1`. Optional `:class` attr available for layout tweaks. Plan 04 needs only one alias addition (`alias AccrueAdmin.Components.{..., FunnelChart}`) and one render-site insertion below the existing `<section class="ax-kpi-grid">` block.
- **For Phase 145+ (window selector, at-risk table, drill-down):** The component is parameterized purely on integer counts — works unchanged with any future window-scoped `Dunning.funnel/1` call.

## Self-Check: PASSED

- `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` — FOUND, contains `use Phoenix.Component` + 5 attr/3 + `defp pct(_n, 0)` + `role="img"` + `aria-labelledby="funnel-title funnel-desc"` + worked-example copy
- `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` — FOUND, contains `describe "funnel_chart/1"` with 6 tests using `render_component/2`
- `accrue_admin/assets/css/app.css` — MODIFIED, contains 11 `.ax-funnel-*` selectors
- Commit `ab302878` — FOUND in `git log` (RED test)
- Commit `7e50ed41` — FOUND in `git log` (GREEN component)
- Commit `2ec7bc22` — FOUND in `git log` (CSS block)

---
*Phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po*
*Plan: 03*
*Completed: 2026-05-27*
