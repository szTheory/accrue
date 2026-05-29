# Phase 145: Time-window URL plumbing + window selector - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Thread a `?window=7d|30d|90d` URL parameter through `RecoveryLive` so all `Accrue.Analytics.Dunning.*` analytics calls respect the selected time window via `:since`/`:until` opts. A new `AccrueAdmin.Components.WindowSelector` component renders 3 preset buttons that keep the URL as the single source of truth. Default window: `30d`. No custom range picker. UTC-only labels.

**Scope anchor — what ships:**
- `RecoveryLive` updated: `mount/3` becomes pure session setup; all data loading moves to `handle_params/3`.
- `handle_params/3` parses `?window=` (valid: `"7d"`, `"30d"`, `"90d"`; default `"30d"`), derives `DateTime` `:since`/`:until`, calls `Dunning.funnel/1` + `Dunning.recovered_vs_lost_mrr/1` with window opts, assigns results.
- `AccrueAdmin.Components.WindowSelector` — new `Phoenix.Component` with `current_window` + `base_path` attrs, rendering 3 `<.link patch>` buttons with `aria-current` active state.
- Tests: `?window=` param variations, default fallback, data reload on window change.

**Out of scope (handled in later v1.44 phases):**
- At-risk subscriptions query + table (DAN-03/04/11) → Phase 146.
- Per-subscription drill-down (DAN-05/12) → Phase 147.
- Cross-currency widening, recovery-rate API, public docs (DAN-06/07/14/15/16) → Phase 148.

</domain>

<decisions>
## Implementation Decisions

### Data loading orchestration (DAN-10)

- **D-01:** Move ALL data loading — `Dunning.funnel/1` and `Dunning.recovered_vs_lost_mrr/1` — from `mount/3` to `handle_params/3`. `mount/3` becomes pure session setup (`assign_shell` only; no Dunning calls). `handle_params/3` is the single data-loading entry point for both initial render and window changes.
- **D-02:** No change-detection guard needed. LiveView 1.1 calls `handle_params` before the initial render (after `mount`) AND on every subsequent URL change — both cases require fresh data. Splitting responsibilities (mount for initial, handle_params for changes) creates two load paths that diverge and adds guard complexity LiveView's lifecycle already eliminates.
- **D-03:** `handle_params/3` receives `%{"window" => w}` (or `%{}` for default), parses the window value, derives `since = DateTime.utc_now() |> DateTime.add(-N * 86_400, :second)` and `until = DateTime.utc_now()`, then calls `Dunning.funnel(since: since, until: until)` and `Dunning.recovered_vs_lost_mrr(since: since, until: until)`. Assigns `@window` (the validated string), `@funnel`, `@stats`, `@recovered_str`, `@exhausted_str`.

### Window selector button model (DAN-10)

- **D-04:** Buttons rendered as `<.link patch={@current_path <> "?window=7d"}>` (and `30d`, `90d`). `handle_params/3` fires automatically on click — no `handle_event` needed for the window change. This is the first `live_patch`-style URL navigation in `accrue_admin`; it sets the idiom for future analytics pages.
- **D-05:** Active state derived from `@window` assign via `aria-current` — same pattern as the existing `Tabs` component: `aria-current={if @current_window == "7d", do: "page", else: nil}`. CSS follows the `ax-tab`/`ax-tab-active` pattern (reuse or add `ax-window-selector-*` classes as needed).
- **D-06:** Patch URL constructed from `@current_path` (already set in `assign_shell` as `@admin_mount_path <> "/analytics/recovery"`) + `"?window=Xd"`. No hardcoded `/billing` paths, no verified routes (`accrue_admin` cannot access the host app's router). `base_path` passed as an attr to `WindowSelector`.

### WindowSelector component

- **D-07:** Extract `AccrueAdmin.Components.WindowSelector` as a standalone `Phoenix.Component` file at `accrue_admin/lib/accrue_admin/components/window_selector.ex`. Attrs: `current_window :: String.t()` (e.g., `"7d"`, `"30d"`, `"90d"`) and `base_path :: String.t()`. Renders 3 `<.link patch>` buttons per preset window value.
- **D-08:** Consume in `RecoveryLive` (Phase 145), and in Phases 146 + 148 analytics pages. Keeping the window preset logic in one component prevents copy-paste drift across 3 analytics pages within the same milestone.
- **D-09:** `WindowSelector` is route-agnostic — it constructs `base_path <> "?window=7d"` etc. Future analytics routes pass their own `@current_path` as `base_path`.

### Claude's Discretion

- Window validation / fallback: recommended `parse_window/1` guard in `handle_params/3` — unknown `?window=` values fall back to `"30d"` (the default). Planner picks the exact guard pattern.
- `:until` derivation: `DateTime.utc_now()` (live, simplest) vs. end-of-today in UTC. Recommend `DateTime.utc_now()` — keeps the window "rolling" and is simpler.
- CSS class names for window selector active/inactive: reuse `ax-tab`/`ax-tab-active` if the visual treatment matches, or add `ax-window-selector-btn` + `ax-window-selector-btn--active` if distinct treatment is needed. Planner picks based on visual context.
- Helper function name for window → `{since, until}` derivation: `window_to_since/1` or inline `defp parse_window/1` returning opts keyword list. Either is fine.
- Whether `@window` assign stores the raw string (`"30d"`) or an atom (`:d30`). Recommend raw string — matches URL param directly, no conversion needed.
- ExDoc note on `funnel/1` / `recovered_vs_lost_mrr/1` about "Showing data since YYYY-MM-DD" cutoff semantics — the `@doc` annotation noting legacy-event behavior. Phase 148 adds the UI badge; Phase 145 may add the `@doc` comment note at planner's discretion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope + requirements
- `.planning/REQUIREMENTS.md` §"Admin UI Recovery Dashboard (DAN)" DAN-10 — full time-window URL plumbing spec (URL param format, handle_params requirement, default, button count, UTC labels, no custom range)
- `.planning/ROADMAP.md` §"Phase 145" — goal + success criteria

### Phase 144 foundation (DO NOT regress)
- `.planning/phases/144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po/144-CONTEXT.md` — all Phase 144 decisions, especially D-01 (funnel query), D-17/D-18 (FunnelChart component + insertion point), D-19/D-20 (currency strategy on KPI cards). Must not regress any Phase 144 deliverables.

### Live code touchpoints
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — the LiveView to update; currently loads data in `mount/3` (to be moved to `handle_params/3`); `@current_path` and `@admin_mount_path` set in `assign_shell/2`; `FunnelChart` already slotted below `ax-kpi-grid`
- `accrue_admin/lib/accrue_admin/components/tabs.ex` — closest analog for `WindowSelector`; shows the `<a href>` + `aria-current` active state pattern (adapt for `<.link patch>`)
- `accrue/lib/accrue/analytics/dunning.ex` — `funnel/1` and `recovered_vs_lost_mrr/1` already accept `[since: dt, until: dt]` opts via `apply_window/2`; no API changes needed in Phase 145
- `accrue_admin/lib/accrue_admin/router.ex` `:75-76` — `live("/recovery", RecoveryLive, :index)` inside `live_session :accrue_admin`; no route changes needed for Phase 145

### Tests
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — add: `?window=7d` renders correctly, `?window=90d` renders correctly, no `?window=` param defaults to `30d`, window change (simulated `handle_params` call) re-fetches data

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AccrueAdmin.Components.Tabs` (`accrue_admin/lib/accrue_admin/components/tabs.ex`) — direct structural analog for `WindowSelector`: `<a href>` loop + `aria-current` from assign comparison. Adapt `<a href>` to `<.link patch>` for client-side URL updates.
- `Accrue.Analytics.Dunning.funnel/1` + `recovered_vs_lost_mrr/1` — already accept `[since: dt, until: dt]` keyword opts via `apply_window/2`; Phase 145 just passes the opts, no API changes.
- `@current_path` assign in `assign_shell/2` — already holds `@admin_mount_path <> "/analytics/recovery"`; use as `base_path` for `WindowSelector`.
- `ax-tabs`, `ax-tab`, `ax-tab-active` CSS classes in `accrue_admin/assets/css/app.css` — reuse for window selector button styling if visual treatment aligns.

### Established Patterns
- `assign_shell/2` in `RecoveryLive` — all shell/nav assigns live here; add `@window` assign here after it's parsed in `handle_params`.
- `Application.put_env(:accrue, :default_currency, :jpy)` + `on_exit` cleanup — existing test pattern for env overrides in `recovery_live_test.exs`; same pattern applies for any window-specific test setup.
- `handle_params/3` exists in multiple LiveViews (`customers_live.ex`, `webhooks_live.ex`, etc.) — but all currently just assign raw `params`. Phase 145 introduces the first data-loading `handle_params`.

### Integration Points
- `RecoveryLive.mount/3` → remove `Dunning.*` calls, keep only `assign_shell(socket, admin)` + `:ok` return
- `RecoveryLive.handle_params/3` → new callback; parse `?window=`, derive `since`/`until`, call both Dunning functions, assign `@window`, `@funnel`, `@stats`, `@recovered_str`, `@exhausted_str`
- `RecoveryLive` template → add `<WindowSelector.window_selector current_window={@window} base_path={@current_path} />` in the page header area (above or below the KPI grid — planner picks)
- `accrue_admin/lib/accrue_admin/components/window_selector.ex` → new file; import in `RecoveryLive` alias block

</code_context>

<specifics>
## Specific Ideas

- Window param values are strings: `"7d"`, `"30d"`, `"90d"` — matching the URL param directly with no atom conversion.
- `<.link patch>` is idiomatic LiveView 1.1 for filter controls. This is the first use in `accrue_admin` and sets the pattern for Phases 146 + 148.
- The `WindowSelector` component is route-agnostic: it accepts `base_path` and constructs `base_path <> "?window=7d"` etc. Any analytics page passes its own `@current_path`.
- UTC-only labels per DAN-10: no timezone conversion anywhere in the UI; if a label shows a date it shows UTC.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 145-time-window-url-plumbing-window-selector*
*Context gathered: 2026-05-27*
