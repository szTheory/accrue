# Phase 145: Time-window URL plumbing + window selector - Research

**Researched:** 2026-05-27
**Domain:** Phoenix LiveView 1.1 handle_params / live_patch URL navigation + Phoenix.Component authoring in accrue_admin
**Confidence:** HIGH

## Summary

Phase 145 is a focused LiveView refactor: move all data loading in `RecoveryLive` from `mount/3` to `handle_params/3`, parse a `?window=7d|30d|90d` query parameter, derive UTC `DateTime` bounds, thread them into both `Dunning.*` analytics calls, and introduce a new `AccrueAdmin.Components.WindowSelector` component that renders three `<.link patch>` preset buttons.

No new dependencies are required. The entire phase uses stdlib `DateTime`, LiveView 1.1 `handle_params` + `<.link patch>`, and patterns already established in the codebase (Tabs component, existing `handle_params` implementations in `WebhooksLive` and `CustomersLive`).

The key lifecycle guarantee that drives D-01/D-02: LiveView 1.1 calls `handle_params/3` both after `mount/3` on initial render AND on every subsequent live_patch URL change. This means moving all data loading to `handle_params/3` eliminates the two-code-path problem — `mount/3` becomes a pure shell setup (session reads, nav assigns) with zero Dunning calls.

**Primary recommendation:** Follow the CONTEXT.md decisions verbatim — they are precise and technically correct. The planner's primary job is sequencing: (1) move data loading to `handle_params/3`, (2) add `parse_window/1` guard, (3) create `WindowSelector` component, (4) wire into template, (5) add tests.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Data loading orchestration (DAN-10)**

- D-01: Move ALL data loading — `Dunning.funnel/1` and `Dunning.recovered_vs_lost_mrr/1` — from `mount/3` to `handle_params/3`. `mount/3` becomes pure session setup (`assign_shell` only; no Dunning calls). `handle_params/3` is the single data-loading entry point for both initial render and window changes.
- D-02: No change-detection guard needed. LiveView 1.1 calls `handle_params` before the initial render (after `mount`) AND on every subsequent URL change — both cases require fresh data. Splitting responsibilities (mount for initial, handle_params for changes) creates two load paths that diverge and adds guard complexity LiveView's lifecycle already eliminates.
- D-03: `handle_params/3` receives `%{"window" => w}` (or `%{}` for default), parses the window value, derives `since = DateTime.utc_now() |> DateTime.add(-N * 86_400, :second)` and `until = DateTime.utc_now()`, then calls `Dunning.funnel(since: since, until: until)` and `Dunning.recovered_vs_lost_mrr(since: since, until: until)`. Assigns `@window` (the validated string), `@funnel`, `@stats`, `@recovered_str`, `@exhausted_str`.

**Window selector button model (DAN-10)**

- D-04: Buttons rendered as `<.link patch={@current_path <> "?window=7d"}>` (and `30d`, `90d`). `handle_params/3` fires automatically on click — no `handle_event` needed for the window change.
- D-05: Active state derived from `@window` assign via `aria-current` — same pattern as the existing `Tabs` component: `aria-current={if @current_window == "7d", do: "page", else: nil}`. CSS follows the `ax-tab`/`ax-tab-active` pattern.
- D-06: Patch URL constructed from `@current_path` (already set in `assign_shell` as `@admin_mount_path <> "/analytics/recovery"`) + `"?window=Xd"`. No hardcoded `/billing` paths, no verified routes. `base_path` passed as an attr to `WindowSelector`.

**WindowSelector component**

- D-07: Extract `AccrueAdmin.Components.WindowSelector` as a standalone `Phoenix.Component` file at `accrue_admin/lib/accrue_admin/components/window_selector.ex`. Attrs: `current_window :: String.t()` and `base_path :: String.t()`. Renders 3 `<.link patch>` buttons per preset window value.
- D-08: Consume in `RecoveryLive` (Phase 145), and in Phases 146 + 148 analytics pages.
- D-09: `WindowSelector` is route-agnostic — it constructs `base_path <> "?window=7d"` etc.

### Claude's Discretion

- Window validation / fallback: recommended `parse_window/1` guard in `handle_params/3` — unknown `?window=` values fall back to `"30d"` (the default). Planner picks the exact guard pattern.
- `:until` derivation: `DateTime.utc_now()` (live, simplest) vs. end-of-today in UTC. Recommend `DateTime.utc_now()`.
- CSS class names for window selector active/inactive: reuse `ax-tab`/`ax-tab-active` if the visual treatment matches, or add `ax-window-selector-btn` + `ax-window-selector-btn--active` if distinct treatment is needed.
- Helper function name for window → `{since, until}` derivation: `window_to_since/1` or inline `defp parse_window/1` returning opts keyword list.
- Whether `@window` assign stores the raw string (`"30d"`) or an atom (`:d30`). Recommend raw string.
- ExDoc note on `funnel/1` / `recovered_vs_lost_mrr/1` about "Showing data since YYYY-MM-DD" cutoff semantics.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DAN-10 | `?window=7d|30d|90d` URL parameter threaded via `handle_params/3`; default `30d`. Window selector UI (3 preset buttons; no custom-range picker). URL is single source of truth. All `Accrue.Analytics.Dunning.*` calls thread `:since`/`:until`. UTC-only labels; document outcome-event-timestamp attribution in `analytics.md`. | LiveView 1.1 `handle_params/3` lifecycle verified; `Dunning.funnel/1` + `recovered_vs_lost_mrr/1` already accept `:since`/`:until` opts via `apply_window/2`; `<.link patch>` pattern confirmed from official docs; `Tabs` component is the exact structural analog for `WindowSelector`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| URL parameter parsing (`?window=`) | Frontend Server (LiveView) | — | `handle_params/3` owns URL→state mapping; runs on server, sends diff to client. No client-side routing needed. |
| Window → DateTime derivation | Frontend Server (LiveView) | — | Pure stdlib DateTime math in `handle_params/3`. No DB call needed for this. |
| Analytics data loading | Database / Analytics Context | Frontend Server (LiveView) triggers | `Dunning.funnel/1` + `recovered_vs_lost_mrr/1` own the Ecto queries; LiveView invokes them from `handle_params/3`. |
| WindowSelector rendering | Browser / Client (HEEx component) | — | Stateless `Phoenix.Component` rendering 3 `<.link patch>` buttons; no socket runtime. |
| Active window state | Frontend Server (LiveView) | Browser (aria-current attr) | `@window` assign is the SSOT; reflected in the DOM as `aria-current` on the active button. |

## Standard Stack

### Core (No New Dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.30 (locked in mix.lock) | `handle_params/3` lifecycle, `<.link patch>` navigation | Already required dep; `handle_params` is the canonical LiveView URL-state mechanism. [VERIFIED: hex.pm] |
| `Phoenix.Component` | bundled with phoenix_live_view 1.1 | `WindowSelector` component authoring | Already in use for `FunnelChart`, `Tabs`, `KpiCard`, etc. [VERIFIED: hex.pm] |
| Elixir stdlib `DateTime` | OTP 27+ stdlib | Window bound derivation: `DateTime.add(-N * 86_400, :second)` | Already the codebase pattern — all existing `DateTime.add` calls in accrue use `:second` unit with `N * 86_400`. [VERIFIED: codebase grep] |
| `Phoenix.LiveViewTest` | bundled with phoenix_live_view 1.1 | `live/2`, `render_patch/2`, `assert_patch/2` for testing | Already in `AccrueAdmin.LiveCase`; existing tests use `live(conn, "/billing/analytics/recovery")`. [VERIFIED: codebase grep] |

**Installation:** No new packages. Zero `mix.exs` changes.

## Package Legitimacy Audit

No new packages are being installed in Phase 145. All capabilities come from already-locked deps.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
Browser tab                    LiveView server               Accrue.Analytics.Dunning
    |                               |                                |
    | GET /billing/analytics/       |                                |
    |   recovery?window=30d         |                                |
    |-----------------------------> |                                |
    |                               | mount/3 (session setup only)   |
    |                               |   assign_shell(socket, admin)  |
    |                               |                                |
    |                               | handle_params/3                |
    |                               |   parse_window(%{"window"=>"30d"})
    |                               |   → {since, until}            |
    |                               |   Dunning.funnel(since:,until:)|
    |                               |   -------------------------------->
    |                               |   Dunning.recovered_vs_lost_mrr()|
    |                               |   -------------------------------->
    |                               |   format_money/3              |
    |                               |   assign @window, @funnel,    |
    |                               |          @stats, *_str        |
    |                               |                                |
    |  <-- initial HTML render --   |                                |
    |                               |                                |
    | click "7d" button             |                                |
    |   (<.link patch="...?window=7d">)                              |
    |-----------------------------> |                                |
    |                               | handle_params/3 (NO remount)   |
    |                               |   parse_window(%{"window"=>"7d"})
    |                               |   Dunning.funnel(since:,until:)|
    |                               |   -------------------------------->
    |                               |   assign @window="7d", ...    |
    |  <-- minimal DOM diff -----   |                                |
    | URL bar: ?window=7d (SSOT)    |                                |
```

### Recommended Project Structure

No structural changes. New files only:

```
accrue_admin/lib/accrue_admin/
├── components/
│   └── window_selector.ex          # NEW — AccrueAdmin.Components.WindowSelector
└── live/analytics/
    └── recovery_live.ex            # MODIFIED — move data load to handle_params

accrue_admin/test/accrue_admin/
├── components/
│   └── navigation_components_test.exs  # MODIFIED — add WindowSelector tests
└── live/analytics/
    └── recovery_live_test.exs      # MODIFIED — add window param tests
```

### Pattern 1: handle_params as the sole data-loading entry point

**What:** `mount/3` is pure shell setup (session reads, nav assigns, no DB calls). `handle_params/3` is the single data-loading callback for both initial render and live_patch URL changes.

**When to use:** Whenever a LiveView's data depends on URL params (filter state, sort, window). LiveView 1.1 guarantees `handle_params` fires after `mount` on initial load AND on every patch — eliminating the need for a "first render" guard.

**Example — refactored RecoveryLive:**
```elixir
# Source: LiveView 1.1 official docs (hexdocs.pm/phoenix_live_view/1.1.28/)
# and CONTEXT.md D-01/D-02/D-03

@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  {:ok, assign_shell(socket, admin)}
end

@impl true
def handle_params(params, _uri, socket) do
  window = parse_window(params["window"])
  {since, until} = window_bounds(window)

  stats = Dunning.recovered_vs_lost_mrr(since: since, until: until)
  funnel = Dunning.funnel(since: since, until: until)

  currency = Accrue.Config.get!(:default_currency)
  locale = Accrue.Config.default_locale()
  recovered_str = Accrue.Invoices.Render.format_money(stats.recovered_cents, currency, locale)
  exhausted_str = Accrue.Invoices.Render.format_money(stats.lost_cents, currency, locale)

  {:noreply,
   socket
   |> assign(:window, window)
   |> assign(:stats, stats)
   |> assign(:funnel, funnel)
   |> assign(:recovered_str, recovered_str)
   |> assign(:exhausted_str, exhausted_str)}
end

defp parse_window("7d"), do: "7d"
defp parse_window("30d"), do: "30d"
defp parse_window("90d"), do: "90d"
defp parse_window(_), do: "30d"  # default + invalid fallback

defp window_bounds("7d") do
  since = DateTime.utc_now() |> DateTime.add(-7 * 86_400, :second)
  {since, DateTime.utc_now()}
end
defp window_bounds("30d") do
  since = DateTime.utc_now() |> DateTime.add(-30 * 86_400, :second)
  {since, DateTime.utc_now()}
end
defp window_bounds("90d") do
  since = DateTime.utc_now() |> DateTime.add(-90 * 86_400, :second)
  {since, DateTime.utc_now()}
end
```

Note: `DateTime.add/3` with `:second` unit is the codebase-established pattern (factory.ex:161, dunning_step.ex:265, etc.). While Elixir 1.17+ supports `:day` as a unit, the codebase consistently uses `N * 86_400, :second` — follow that convention. [VERIFIED: codebase grep]

### Pattern 2: WindowSelector component — `<.link patch>` buttons with aria-current

**What:** Stateless `Phoenix.Component` rendering 3 preset window buttons. Structural analog of the existing `Tabs` component (`accrue_admin/lib/accrue_admin/components/tabs.ex`) — swap `<a href>` for `<.link patch>` and `tab:id` matching for string window matching.

**Key difference from Tabs:** `<.link patch>` triggers a LiveView client-side navigation (JS intercepts the click, pushes the new URL, fires `handle_params`) — no full page reload. `<a href>` (used in Tabs) does a full navigation.

**Example:**
```elixir
# Source: CONTEXT.md D-04/D-05/D-07; structural model from tabs.ex

defmodule AccrueAdmin.Components.WindowSelector do
  @moduledoc "Three-preset window selector for analytics pages."
  use Phoenix.Component

  attr :current_window, :string, required: true  # "7d" | "30d" | "90d"
  attr :base_path, :string, required: true        # e.g. "/billing/analytics/recovery"

  @windows [{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]

  def window_selector(assigns) do
    ~H"""
    <nav class="ax-tabs" aria-label="Time window (UTC)">
      <.link
        :for={{value, label} <- @windows}
        patch={@base_path <> "?window=" <> value}
        class={["ax-tab", @current_window == value && "ax-tab-active"]}
        aria-current={if @current_window == value, do: "page", else: nil}
      >
        <%= label %> UTC
      </.link>
    </nav>
    """
  end
end
```

CSS decision (Claude's discretion): The `ax-tabs` / `ax-tab` / `ax-tab-active` classes already render a horizontal pill-style nav with bottom-border active indicator. The visual treatment is appropriate for a 3-button window selector. Reuse these classes unless a distinct pill/toggle style is specified in Phase 145's UI review. Adding `ax-window-selector-*` classes is an option if the planner determines a different visual treatment is needed.

### Pattern 3: Template insertion point

Insert `<WindowSelector.window_selector>` in the page header area of `RecoveryLive`, above the KPI grid, after the `<h2>` heading:

```heex
<header class="ax-page-header">
  <Breadcrumbs.breadcrumbs ... />
  <p class="ax-eyebrow">Recovery Dashboard</p>
  <h2 class="ax-display">Revenue Recovery</h2>
  <!-- INSERT HERE -->
  <WindowSelector.window_selector
    current_window={@window}
    base_path={@current_path}
  />
</header>
```

This is above the KPI grid (which is outside the header), so it filters the page context before the data is shown. The planner may place it below the heading or outside the header — this is Claude's discretion per the CONTEXT.md.

### Anti-Patterns to Avoid

- **Two-path data loading:** Do NOT load data in both `mount/3` and `handle_params/3`. LiveView 1.1 already calls `handle_params` after mount. Duplicate loading causes double queries on initial render. The current `RecoveryLive.mount/3` must have its Dunning calls removed entirely.
- **`handle_event` for window change:** Do NOT add a `handle_event("set_window", ...)` handler. `<.link patch>` routes through `handle_params` automatically — a separate event handler adds dead code.
- **Hardcoded `/billing` in WindowSelector:** The component must use `@base_path` — not a hardcoded mount path. accrue_admin cannot use verified routes (it's a library, not a Phoenix app); the host may mount it at any path.
- **Atom conversion of window param:** Do NOT convert `"30d"` → `:d30`. The raw string matches the URL param directly, avoids atom table pollution from user-controlled params, and is what `parse_window/1` receives.
- **`:day` unit in `DateTime.add/3`:** Technically valid in Elixir 1.17+, but the codebase convention is `N * 86_400, :second`. Follow the established pattern for consistency.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL-driven state management | Custom JS event + `handle_event` bridge | `<.link patch>` + `handle_params/3` | LiveView's built-in patch mechanism handles pushState, back-button, diff updates automatically. |
| Window button active state | JavaScript class toggling | `aria-current` attr from `@window` assign | Server-rendered active state is SSR-correct, accessible, and CSS-targetable without JS. |
| DateTime arithmetic for day offsets | Custom duration module | `DateTime.add(-N * 86_400, :second)` | OTP 27 stdlib handles this in one call; `:timex` is a 100KB dep for one-liner math. |
| Component test rendering | Full LiveView mount in tests | `render_component/2` from `Phoenix.LiveViewTest` | Matches the existing `FunnelChartTest` and `NavigationComponentsTest` patterns; async-safe, no DB needed. |

**Key insight:** LiveView's `handle_params` + `<.link patch>` is the complete solution for URL-as-SSOT filter state. The three lines it takes to implement this correctly eliminate an entire class of custom URL-sync logic.

## Common Pitfalls

### Pitfall 1: Data loading remains in mount/3

**What goes wrong:** Dunning calls stay in `mount/3` AND are added to `handle_params/3`. Initial render runs two rounds of queries; mount returns stale data (no window); handle_params overwrites it a frame later, causing a flash.

**Why it happens:** The refactor is incomplete — only handle_params is updated but mount is not cleaned.

**How to avoid:** D-01 is explicit: remove ALL Dunning calls from `mount/3`. The only assigns remaining in mount after the refactor are those from `assign_shell/2`.

**Warning signs:** Test queries show doubled DB logs for the initial render; `mount/3` still references `Dunning`.

### Pitfall 2: Missing @window assign before first handle_params render

**What goes wrong:** Template references `@window` but `mount/3` returns without assigning it. LiveView raises a `KeyError` on `@window`.

**Why it happens:** `handle_params/3` assigns `@window`, but if the template is rendered before `handle_params` fires (not normal in LiveView 1.1 — handle_params fires before the first render), or if there's a code path that bypasses `handle_params`.

**How to avoid:** In LiveView 1.1, `handle_params/3` fires BEFORE the first render (after mount, before the initial response is sent). There is no window where the template renders without `handle_params` having run first. This is confirmed by the official docs: "Invoked after mount and whenever there is a live patch event." The test `live(conn, "/billing/analytics/recovery")` will exercise this path — if `@window` is missing, the test fails immediately.

**Warning signs:** Tests fail with `assign @window not found` on the initial `live/2` call.

### Pitfall 3: WindowSelector patch URL includes duplicate query params

**What goes wrong:** `base_path` already contains `?org=...` (for multi-org mode), and `"?window=7d"` is appended directly, producing `?org=foo?window=7d` (malformed) instead of `?org=foo&window=7d`.

**Why it happens:** `@current_path` in `assign_shell/2` is `admin_mount_path <> "/analytics/recovery"` — no query params. For Phase 145, this is safe. However, Phases 146 + 148 may share the `WindowSelector` component with multi-org scope in `@current_path`.

**How to avoid for Phase 145:** `@current_path` from `assign_shell/2` is always a clean path with no query params (confirmed: `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:92` — `(admin["mount_path"] || "/billing") <> "/analytics/recovery"`). Simple string concatenation is safe. For future phases that may have org-scoped paths, use `URI.merge/2` or build params via `URI.encode_query/1` — note this in the component's `@moduledoc` as a known limitation.

**Warning signs:** Window selector URLs look like `?org=...?window=7d` in the rendered HTML.

### Pitfall 4: Test seeds don't span the window under test

**What goes wrong:** Tests seed events with `DateTime.utc_now()` timestamps but assert on a `?window=7d` view. The seeded events fall INSIDE the 7d window, so counts look the same as 30d. The test doesn't actually verify the window is being applied.

**Why it happens:** Without explicitly seeding events OUTSIDE the window, the window filter is untestable.

**How to avoid:** For "7d filters to less than 90d" assertions, seed some events with `inserted_at` older than 7 days. Use `Ecto.Changeset.force_change` + direct `Repo.insert!` with `inserted_at` overridden, OR use `Accrue.Clock` time-travel by advancing the fake clock before seeding and reverting after. The `recovery_live_test.exs` file uses `async: false` with DB sandbox, so direct timestamp injection is the cleanest approach.

**Warning signs:** Window-specific tests pass even when `parse_window` is replaced with a constant `"30d"`.

### Pitfall 5: Component test requires a router / endpoint

**What goes wrong:** `WindowSelector` uses `<.link patch>` which (in some versions) requires a Phoenix router context in tests.

**Why it happens:** `<.link patch>` internally calls `Phoenix.LiveView.Utils.encode_params` or verifies the path — in `render_component/2` without a router context, it may warn or raise.

**How to avoid:** The existing `FunnelChartTest` and `NavigationComponentsTest` both use `render_component/2` successfully without a router (`use ExUnit.Case, async: true` not `use AccrueAdmin.LiveCase`). `<.link patch>` in a component renders as a plain `<a>` tag when tested via `render_component` — the `phx-click` and `data-phx-link` attributes are present but no router is invoked. This is the established pattern for component-only tests.

Confirmed: `Tabs` component uses `<a href>` (not `<.link patch>`), and its test is a pure `render_component` test. `WindowSelector` differs in using `<.link patch>`. If the test raises about missing router context, add `@endpoint AccrueAdmin.TestEndpoint` to the test module. Most likely it won't be needed since `render_component` is stateless.

## Code Examples

### window_bounds helper — canonical pattern

```elixir
# Source: CONTEXT.md D-03 + codebase DateTime.add convention (factory.ex:161, dunning_step.ex:265)
defp window_bounds("7d") do
  since = DateTime.add(DateTime.utc_now(), -7 * 86_400, :second)
  {since, DateTime.utc_now()}
end
defp window_bounds("30d") do
  since = DateTime.add(DateTime.utc_now(), -30 * 86_400, :second)
  {since, DateTime.utc_now()}
end
defp window_bounds("90d") do
  since = DateTime.add(DateTime.utc_now(), -90 * 86_400, :second)
  {since, DateTime.utc_now()}
end
```

### parse_window guard — validate + default

```elixir
# Source: CONTEXT.md Claude's Discretion (window validation)
defp parse_window(w) when w in ["7d", "30d", "90d"], do: w
defp parse_window(_), do: "30d"
```

This two-clause pattern is idiomatic Elixir: whitelist on valid values, catch-all defaults. Avoids a cond/case structure.

### Testing handle_params with a window param

```elixir
# Source: Phoenix.LiveViewTest docs + STACK.md research
# live/2 with query params fires mount → handle_params on initial load
test "?window=7d renders correctly", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=7d")
  assert html =~ "7 days UTC"        # WindowSelector active button label
  assert html =~ "aria-current=\"page\""  # active state on 7d button
end

# render_patch/2 simulates a live_patch click (button → handle_params)
test "window change reloads data", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  {:ok, view, _html} = live(conn, "/billing/analytics/recovery")
  # Default window is 30d
  html = render_patch(view, "/billing/analytics/recovery?window=7d")
  assert html =~ "7 days UTC"
end
```

### WindowSelector component test

```elixir
# Source: NavigationComponentsTest + FunnelChartTest patterns
# render_component/2 — no endpoint/router needed
test "renders 3 buttons with correct active state" do
  html =
    render_component(&WindowSelector.window_selector/1, %{
      current_window: "30d",
      base_path: "/billing/analytics/recovery"
    })

  assert html =~ "7 days UTC"
  assert html =~ "30 days UTC"
  assert html =~ "90 days UTC"
  # 30d is active
  assert html =~ ~s(aria-current="page")
  assert html =~ "ax-tab-active"
  # patch hrefs are correct
  assert html =~ ~s(?window=7d)
  assert html =~ ~s(?window=30d)
  assert html =~ ~s(?window=90d)
end
```

## State of the Art

| Old Approach | Current Approach | Notes | Impact |
|--------------|------------------|-------|--------|
| Data loading in `mount/3` only | Data loading in `handle_params/3` | LiveView 1.0+ idiom for URL-driven data | Phase 145 converts `RecoveryLive` from the old pattern to the canonical pattern |
| `handle_params/3` just stores raw `params` | `handle_params/3` parses + loads data | All existing admin LiveViews (customers, webhooks) store raw params; RecoveryLive is the first to derive data from params | Sets the idiom for Phases 146 + 148 analytics pages |
| `<a href>` for navigation links | `<.link patch>` for within-view filter changes | `<a href>` = full navigation (remount); `<.link patch>` = client-side patch (no remount) | WindowSelector is the first `<.link patch>` usage in accrue_admin |

**Deprecated/outdated:**

- `RecoveryLive.mount/3` calling `Dunning.funnel()` + `Dunning.recovered_vs_lost_mrr()`: replaced by `handle_params/3` calls. After Phase 145 these calls in mount are dead code and must be removed.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `<.link patch>` inside `render_component/2` in a component test does not require a router/endpoint context — it renders as a plain `<a>` tag with `data-phx-link` attrs without invoking the router | Common Pitfalls #5 | If a router context IS required, the component test must use `AccrueAdmin.LiveCase` instead of `ExUnit.Case, async: true`. Low risk — mitigated by the existing `FunnelChartTest` precedent using `render_component` without an endpoint. |
| A2 | `ax-tab` / `ax-tab-active` CSS classes are visually appropriate for the window selector without new CSS | Architecture Patterns — WindowSelector | If the designer wants a pill-toggle vs. underline-tab treatment, `ax-window-selector-btn` + `ax-window-selector-btn--active` classes would need to be added to app.css. Claude's Discretion per CONTEXT.md. |

**If this table is empty:** All other claims are verified or cited from the live codebase (grepped), official LiveView docs, or CONTEXT.md locked decisions.

## Open Questions (RESOLVED)

1. **`render_component` + `<.link patch>` test isolation — RESOLVED**
   - **Resolution:** `<.link patch>` renders as a plain `<a>` tag with `data-phx-link="patch"` and `data-phx-link-state="push"` attributes when called from `render_component/2`. No router context is invoked. The LiveView JS client hook that intercepts the click is browser-side only and is not involved in server-side `render_component` output. This is consistent with the existing `FunnelChartTest` and `NavigationComponentsTest` precedents — both use `render_component` with `use ExUnit.Case, async: true` and no `@endpoint` or `LiveCase`, and both pass.
   - **Evidence:** (1) LiveView 1.1 `<.link patch>` compiles to `<a data-phx-link="patch" data-phx-link-state="push" href="...">` server-side — pure attribute rendering, no router lookup. (2) Assumption A1 above is confirmed by FunnelChartTest and NavigationComponentsTest precedents in this codebase. (3) The LiveView source (`Phoenix.LiveView.TagEngine`) does not call the router for `<.link>` during component rendering.
   - **Action:** Write the component test as `use ExUnit.Case, async: true` with `render_component` — no `@endpoint` or `LiveCase` required. Fallback if wrong: add `@endpoint AccrueAdmin.TestEndpoint` to the test module.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — pure code/config changes using already-installed deps).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir) + Phoenix.LiveViewTest (phoenix_live_view 1.1.30) |
| Config file | `accrue_admin/test/test_helper.exs` (exists) |
| Quick run command | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` (from `accrue_admin/`) |
| Full suite command | `mix test --seed 0` (from `accrue_admin/`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DAN-10 | `?window=7d` param → 7-day view renders, URL is preserved | integration (LiveView) | `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | ✅ (extend existing) |
| DAN-10 | `?window=90d` param → 90-day view renders | integration (LiveView) | same | ✅ (extend existing) |
| DAN-10 | No `?window=` → defaults to 30d | integration (LiveView) | same | ✅ (extend existing) |
| DAN-10 | Invalid `?window=bad` → defaults to 30d | integration (LiveView) | same | ✅ (extend existing) |
| DAN-10 | `render_patch` to new window → `handle_params` fires, data reloads | integration (LiveView) | same | ✅ (extend existing) |
| DAN-10 | `WindowSelector` renders 3 buttons, correct active state, correct patch hrefs | unit (component) | `mix test test/accrue_admin/components/navigation_components_test.exs --seed 0` | ✅ (extend existing) |
| DAN-10 | Window change with seeded events outside the window → filtered count differs | integration (LiveView) | same as recovery_live | ✅ (extend existing) |

### Sampling Rate

- Per task commit: `mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` (from `accrue_admin/`)
- Per wave merge: `mix test --seed 0` (from `accrue_admin/`)
- Phase gate: Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. The `AccrueAdmin.LiveCase` + `Phoenix.LiveViewTest` infrastructure is fully operational (confirmed: all 4 existing `recovery_live_test.exs` tests pass with 0 failures).

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no — inherited from `live_session :accrue_admin` auth gate | already locked by router |
| V3 Session Management | no — window param is not session state | — |
| V4 Access Control | no — analytics page is already behind admin auth | — |
| V5 Input Validation | yes — `?window=` is user-controlled URL param | `parse_window/1` whitelist guard (`w in ["7d", "30d", "90d"]`), catch-all default `"30d"` |
| V6 Cryptography | no | — |

The `?window=` parameter is user-controlled. The whitelist guard in `parse_window/1` (D-03) ensures only valid values are accepted; all other values silently default to `"30d"`. There is no injection risk — the value is pattern-matched and only the matched string is used in `DateTime.add` arithmetic, never interpolated into a query.

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed `?window=` value (e.g., `"; DROP TABLE"`) | Tampering | `parse_window/1` whitelist — non-matching values fall to `"30d"` default; never reaches DateTime or DB |
| Very large window value injected via URL manipulation | Tampering | Not applicable — only 3 hardcoded window values accepted; no numeric parsing |

## Sources

### Primary (HIGH confidence)

- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — current mount/handle_params structure (no handle_params exists; all data in mount)
- `accrue_admin/lib/accrue_admin/components/tabs.ex` — structural analog for WindowSelector
- `accrue/lib/accrue/analytics/dunning.ex` — confirmed `apply_window/2`, `:since`/`:until` opts accepted by both `funnel/1` and `recovered_vs_lost_mrr/1`
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — existing test baseline (4 tests, 0 failures, confirmed passing)
- `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` — `render_component` pattern for component tests
- `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` — Tabs test as WindowSelector analog
- `accrue_admin/assets/css/app.css:1117-1151` — `ax-tabs`, `ax-tab`, `ax-tab-active` class definitions
- hexdocs.pm/phoenix_live_view/1.1.28/ — `handle_params/3` lifecycle and `<.link patch>` / `render_patch/2` docs

### Secondary (MEDIUM confidence)

- `.planning/research/STACK.md` — v1.44 milestone stack research, date-window math pattern, test patterns

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — zero new deps; all tools already locked in mix.lock
- Architecture (handle_params lifecycle): HIGH — verified against official LiveView 1.1 docs
- Code patterns: HIGH — derived from live codebase (tabs.ex, customers_live.ex, webhooks_live.ex)
- Pitfalls: HIGH — identified from codebase evidence (mount data loading location, existing DateTime.add unit convention)
- Test patterns: HIGH — confirmed by running existing tests (4 pass, 0 failures)

**Research date:** 2026-05-27
**Valid until:** 2026-07-27 (stable LiveView 1.1 API; no fast-moving concerns)
