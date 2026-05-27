---
phase: 145-time-window-url-plumbing-window-selector
plan: "01"
subsystem: ui
tags: [phoenix, live_view, phoenix_component, analytics, dunning, window_selector]

# Dependency graph
requires:
  - phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po
    provides: "RecoveryLive with FunnelChart + Dunning.funnel/1 + Dunning.recovered_vs_lost_mrr/1 accepting since:/until: opts"
provides:
  - "AccrueAdmin.Components.WindowSelector — stateless Phoenix.Component rendering 3 .link patch preset buttons"
  - "RecoveryLive handle_params/3 as sole data-loading entry point with parse_window/1 + window_bounds/1"
  - "?window=7d|30d|90d URL parameter plumbing through RecoveryLive"
  - "8 new tests: 3 WindowSelector unit + 5 DAN-10 integration"
affects:
  - "Phase 146 (at-risk table) — use WindowSelector with same pattern"
  - "Phase 148 (cross-currency) — may need handle_params reuse"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "First live_patch-style URL filter in accrue_admin — sets idiom for Phases 146 + 148"
    - "mount/3 as pure shell (assign_shell only), handle_params/3 as sole data-loading entry point"
    - "parse_window/1 two-clause whitelist guard for URL parameter validation"
    - "window_bounds/1 using DateTime.add with N * 86_400 :second convention"
    - "WindowSelector route-agnostic via base_path attr — no hardcoded /billing paths"

key-files:
  created:
    - accrue_admin/lib/accrue_admin/components/window_selector.ex
  modified:
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - accrue_admin/test/accrue_admin/components/navigation_components_test.exs
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs

key-decisions:
  - "parse_window/1 whitelist guard (w in [\"7d\", \"30d\", \"90d\"]) + catch-all returning \"30d\"; matched string only used for DateTime arithmetic — never interpolated into SQL, ETS, or atoms (T-145-01 mitigated)"
  - "window_bounds/1 uses DateTime.add(DateTime.utc_now(), -N * 86_400, :second) — rolling window not end-of-day, matching codebase convention from factory.ex"
  - "@windows module attribute assigned to assigns via assign(assigns, :windows, @windows) before ~H sigil — Phoenix Component assigns are the source of truth inside HEEx"
  - "WindowSelector uses assign(assigns, :windows, @windows) pattern to surface module attribute into template without compiler warning"
  - "Floki not available in test env — single aria-current count assertion uses String.split counting (1 == html |> String.split(...) |> length() |> Kernel.-(1))"

patterns-established:
  - "live_patch filter idiom: stateless Phoenix.Component + base_path attr + .link patch — no handle_event needed"
  - "handle_params as sole data-loading entry point (replaces split mount/handle_params approach)"

requirements-completed: [DAN-10]

# Metrics
duration: 3min
completed: 2026-05-27
---

# Phase 145 Plan 01: Time-window URL plumbing + WindowSelector Summary

**DAN-10 closed: ?window=7d|30d|90d URL param threads through RecoveryLive via handle_params; AccrueAdmin.Components.WindowSelector renders 3 live_patch preset buttons with aria-current active state, setting the filter idiom for Phases 146 + 148.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-27T20:56:16Z
- **Completed:** 2026-05-27T20:59:52Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Created `AccrueAdmin.Components.WindowSelector` — stateless Phoenix.Component with `current_window` + `base_path` attrs, rendering `ax-tabs` nav with 3 `.link patch` buttons (7 days UTC / 30 days UTC / 90 days UTC)
- Refactored `RecoveryLive.mount/3` to pure shell (`assign_shell` only); all data loading moved to new `handle_params/3` with `parse_window/1` whitelist guard and `window_bounds/1` DateTime arithmetic
- Added `<WindowSelector.window_selector>` to RecoveryLive template after `<h2>` heading — positions filter above data it controls
- 8 new tests: 3 WindowSelector unit tests (labels, active state, patch hrefs) + 5 DAN-10 integration tests (?window=7d, ?window=90d, no param → 30d, bad param → 30d, render_patch fires handle_params)

## Task Commits

1. **Task 1: Create AccrueAdmin.Components.WindowSelector** - `a4e0e47e` (feat)
2. **Task 2: Refactor RecoveryLive — data loading to handle_params** - `f8c1ecea` (feat)
3. **Task 3: WindowSelector unit tests + DAN-10 integration tests** - `07e72af8` (test)

## Files Created/Modified
- `accrue_admin/lib/accrue_admin/components/window_selector.ex` — New Phoenix.Component: `@windows [{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]`; attrs `current_window` + `base_path`; `ax-tabs` nav with 3 `.link patch` buttons; `aria-current="page"` + `ax-tab-active` on active button
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — mount/3 stripped to assign_shell only; handle_params/3 added with parse_window + window_bounds + Dunning calls with since:/until: opts; WindowSelector inserted after `<h2 class="ax-display">Revenue Recovery</h2>`; WindowSelector alias added
- `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` — 3 new tests in `describe "WindowSelector"` block; WindowSelector alias added; 11 total component tests
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — 5 new tests in `describe "window parameter (DAN-10)"` block; inherits file-level setup (no nested setup); 9 total live tests

## Decisions Made

- **parse_window/1 exact clauses:**
  ```elixir
  defp parse_window(w) when w in ["7d", "30d", "90d"], do: w
  defp parse_window(_), do: "30d"
  ```
- **window_bounds/1 exact DateTime.add calls:**
  ```elixir
  defp window_bounds("7d"), do: {DateTime.add(DateTime.utc_now(), -7 * 86_400, :second), DateTime.utc_now()}
  defp window_bounds("30d"), do: {DateTime.add(DateTime.utc_now(), -30 * 86_400, :second), DateTime.utc_now()}
  defp window_bounds("90d"), do: {DateTime.add(DateTime.utc_now(), -90 * 86_400, :second), DateTime.utc_now()}
  ```
- **WindowSelector @windows:** `[{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]` — module attribute surfaced via `assign(assigns, :windows, @windows)` before `~H` to avoid compiler warning
- **Template insertion:** After `<h2 class="ax-display">Revenue Recovery</h2>`, before `</header>` — filter above data per "filter then data" reading order

## Deviations from Plan

**1. [Rule 1 - Bug] @windows module attribute required assign bridge in component**
- **Found during:** Task 1 (WindowSelector creation)
- **Issue:** Inside `~H` sigil, `@windows` resolves as `assigns.windows` (LiveView assign), not the module attribute. Compile warning: "module attribute @windows was set but never used."
- **Fix:** Added `assigns = assign(assigns, :windows, @windows)` before the `~H` block to surface the module attribute into the assigns map. The plan's `@windows` module attribute is preserved as specified.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/window_selector.ex`
- **Verification:** `mix compile` exits 0 with no warnings
- **Committed in:** `a4e0e47e` (Task 1 commit)

**2. [Rule 1 - Bug] Floki not available — used String.split count pattern for Test 2**
- **Found during:** Task 3 (navigation_components_test.exs)
- **Issue:** Plan suggested `Floki.find(Floki.parse_document!(html), ...)` for counting aria-current occurrences; Floki is not a dependency in accrue_admin test env.
- **Fix:** Plan pre-documented the fallback: `assert 1 == html |> String.split(~s(aria-current="page")) |> length() |> Kernel.-(1)`. Used the fallback as specified.
- **Files modified:** `accrue_admin/test/accrue_admin/components/navigation_components_test.exs`
- **Verification:** Test passes with 0 failures
- **Committed in:** `07e72af8` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — known pitfalls pre-documented in plan)
**Impact on plan:** No scope creep. Both fixes required for correctness. All plan acceptance criteria met.

## Issues Encountered

- 3 pre-existing test failures in full suite (EmailPreviewLiveTest x2, ConnectAccountLiveTest x1) — confirmed pre-existing by running `git stash` then `mix test --seed 0` (same 3 failures). Not caused by Phase 145 changes. Documented in deferred-items scope.

## Known Stubs

None — all data paths are wired. `@window` assign is set by `handle_params/3` before render; `WindowSelector` receives live `@window` and `@current_path` from socket assigns.

## Threat Flags

None — all threat surface covered by plan's threat model (T-145-01 `parse_window/1` whitelist mitigated, T-145-02 `base_path` from server-side session accepted).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 146 (at-risk subscriptions): WindowSelector component ready to reuse; same live_patch idiom applies. Pass `@current_path` as `base_path` from each analytics LiveView.
- Phase 148: handle_params pattern established; cross-currency widening can extend assigns set in handle_params

## Self-Check

- [x] `accrue_admin/lib/accrue_admin/components/window_selector.ex` — FOUND
- [x] `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — contains `def handle_params`, `parse_window`, `window_bounds`, `WindowSelector.window_selector`
- [x] Commits `a4e0e47e`, `f8c1ecea`, `07e72af8` — verified in git log

## Self-Check: PASSED

---
*Phase: 145-time-window-url-plumbing-window-selector*
*Completed: 2026-05-27*
