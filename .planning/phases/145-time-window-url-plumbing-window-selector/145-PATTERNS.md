# Phase 145: Time-window URL plumbing + window selector - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 4 (1 new, 3 modified)
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/lib/accrue_admin/components/window_selector.ex` | component | request-response | `accrue_admin/lib/accrue_admin/components/tabs.ex` | exact (same Phoenix.Component structure; swap `<a href>` for `<.link patch>`, `tab:id` match for window string match) |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | LiveView | request-response | `accrue_admin/lib/accrue_admin/live/customers_live.ex` | role-match (existing `handle_params` that stores raw params; Phase 145 upgrades to data-loading `handle_params`) |
| `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` | exact (same `render_component/2` + `assert html =~` pattern) |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | test | request-response | self (extend existing file) | exact (same `AccrueAdmin.LiveCase` + `live/2` pattern) |

---

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/components/window_selector.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/components/tabs.ex`

**Module structure / imports** (tabs.ex lines 1-10):
```elixir
defmodule AccrueAdmin.Components.Tabs do
  @moduledoc """
  Link-based tab navigation for admin detail and list subviews.
  """

  use Phoenix.Component

  attr(:tabs, :list, required: true)
  attr(:active, :string, required: true)
```

**Core render pattern** (tabs.ex lines 11-27):
```elixir
def tabs(assigns) do
  ~H"""
  <nav class="ax-tabs" aria-label="Page sections">
    <a
      :for={tab <- @tabs}
      href={tab[:href]}
      class={["ax-tab", active_tab?(tab, @active) && "ax-tab-active"]}
      aria-current={if(active_tab?(tab, @active), do: "page", else: nil)}
    >
      <span><%= tab[:label] %></span>
      <span :if={tab[:count]} class="ax-tab-count"><%= tab[:count] %></span>
    </a>
  </nav>
  """
end

defp active_tab?(tab, active), do: to_string(tab[:id]) == to_string(active)
```

**Adaptation for WindowSelector** — copy the above shell verbatim, then make these targeted changes:
- Replace `defmodule AccrueAdmin.Components.Tabs` with `defmodule AccrueAdmin.Components.WindowSelector`
- Replace `attr(:tabs, :list, ...)` + `attr(:active, :string, ...)` with `attr :current_window, :string, required: true` + `attr :base_path, :string, required: true`
- Replace `<a href={tab[:href]}>` with `<.link patch={@base_path <> "?window=" <> value}>`
- Replace active guard `active_tab?(tab, @active)` with inline `@current_window == value`
- Replace the `:for` list with a module-level `@windows [{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]`
- Remove the `active_tab?/2` private function (comparison is trivially inlined)
- Change `aria-label="Page sections"` to `aria-label="Time window (UTC)"`

**CSS classes to reuse** (from `accrue_admin/assets/css/app.css` lines 1117-1151 per RESEARCH.md):
- Outer nav: `ax-tabs`
- Each button: `ax-tab`
- Active button: `ax-tab-active` (additional class in the list, same as Tabs)

**Complete new file pattern** (derived from tabs.ex + CONTEXT.md D-04/D-05/D-07):
```elixir
defmodule AccrueAdmin.Components.WindowSelector do
  @moduledoc "Three-preset time window selector for analytics pages."

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

---

### `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (LiveView, request-response)

**Analog for handle_params shell:** `accrue_admin/lib/accrue_admin/live/customers_live.ex`

**Existing handle_params (to upgrade from)** (customers_live.ex lines 43-45):
```elixir
@impl true
def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end
```

**Existing mount pattern (to keep for assign_shell shape)** (customers_live.ex lines 16-39):
```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  {:ok,
   socket
   |> assign_shell(admin)
   |> assign(:params, %{})
   |> ...}
end
```

**Current RecoveryLive mount (source of truth for what to strip)** (recovery_live.ex lines 10-31):
```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  stats = Dunning.recovered_vs_lost_mrr()     # <-- REMOVE
  funnel = Dunning.funnel()                    # <-- REMOVE

  currency = Accrue.Config.get!(:default_currency)           # <-- REMOVE
  locale = Accrue.Config.default_locale()                    # <-- REMOVE
  recovered_str = Accrue.Invoices.Render.format_money(...)   # <-- REMOVE
  exhausted_str = Accrue.Invoices.Render.format_money(...)   # <-- REMOVE

  {:ok,
   socket
   |> assign_shell(admin)
   |> assign(:stats, stats)           # <-- REMOVE
   |> assign(:funnel, funnel)         # <-- REMOVE
   |> assign(:recovered_str, ...)     # <-- REMOVE
   |> assign(:exhausted_str, ...)}    # <-- REMOVE
end
```

**After refactor, mount becomes** (CONTEXT.md D-01):
```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  {:ok, assign_shell(socket, admin)}
end
```

**New handle_params to add** (CONTEXT.md D-03; DateTime.add convention from dunning_step.ex:265):
```elixir
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
```

**Private helpers to add** (CONTEXT.md D-03; `N * 86_400, :second` convention matches existing codebase usage):
```elixir
defp parse_window(w) when w in ["7d", "30d", "90d"], do: w
defp parse_window(_), do: "30d"

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

**Dunning API contract (no changes needed)** (dunning.ex lines 42-58, 117, 145-159):
```elixir
@spec recovered_vs_lost_mrr(keyword()) :: %{recovered_cents: non_neg_integer(), lost_cents: non_neg_integer()}
def recovered_vs_lost_mrr(opts \\ []) when is_list(opts) do
  ...
  |> apply_window(opts)   # opts[:since] and opts[:until] already wired
end

@spec funnel(keyword()) :: %{entered: ..., recovered: ..., exhausted: ..., active: ...}
def funnel(opts \\ []) when is_list(opts) do

defp apply_window(query, opts) do
  query
  |> maybe_since(opts[:since])   # %DateTime{} or nil
  |> maybe_until(opts[:until])   # %DateTime{} or nil
end
```

**Template insertion point for WindowSelector** (recovery_live.ex lines 45-49):
```heex
<header class="ax-page-header">
  <Breadcrumbs.breadcrumbs items={[%{label: "Analytics"}, %{label: "Recovery"}]} />
  <p class="ax-eyebrow">Recovery Dashboard</p>
  <h2 class="ax-display">Revenue Recovery</h2>
  <!-- INSERT WindowSelector here, after h2, before closing </header> -->
  <WindowSelector.window_selector
    current_window={@window}
    base_path={@current_path}
  />
</header>
```

**Alias block update** (recovery_live.ex line 8 — add WindowSelector):
```elixir
alias AccrueAdmin.Components.{AppShell, Breadcrumbs, FunnelChart, KpiCard, WindowSelector}
```

---

### `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` (test, request-response)

**Analog:** `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` itself (this is an extension) + `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` for the `render_component` pattern.

**Module header pattern** (navigation_components_test.exs lines 1-10):
```elixir
defmodule AccrueAdmin.NavigationComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.{Breadcrumbs, Button, FlashGroup, StatusBadge}
  alias AccrueAdmin.Components.{DropdownMenu, Input, Select, Tabs}
```

Add `WindowSelector` to the alias on the second line.

**render_component pattern for a component with string attrs** (funnel_chart_test.exs lines 10-13):
```elixir
html =
  render_component(&FunnelChart.funnel_chart/1,
    entered: 10,
    recovered: 4,
    ...
  )
```

**Tabs describe block as structural template** (navigation_components_test.exs lines 165-181):
```elixir
describe "Tabs" do
  test "renders link tabs with active detail-page state" do
    html =
      render_component(&Tabs.tabs/1, %{
        active: "events",
        tabs: [
          %{id: "overview", label: "Overview", href: "/billing/customers/cus_123"},
          %{id: "events", label: "Events", href: "/billing/customers/cus_123/events", count: 12}
        ]
      })

    assert html =~ "Overview"
    assert html =~ ~s(aria-current="page")
    assert html =~ "ax-tab-active"
    assert html =~ ">12<"
  end
end
```

**New describe block to add** (copy Tabs pattern, adapt for WindowSelector):
```elixir
describe "WindowSelector" do
  test "renders 3 preset buttons with correct labels" do
    html =
      render_component(&WindowSelector.window_selector/1, %{
        current_window: "30d",
        base_path: "/billing/analytics/recovery"
      })

    assert html =~ "7 days UTC"
    assert html =~ "30 days UTC"
    assert html =~ "90 days UTC"
  end

  test "marks active window with aria-current and ax-tab-active" do
    html =
      render_component(&WindowSelector.window_selector/1, %{
        current_window: "30d",
        base_path: "/billing/analytics/recovery"
      })

    assert html =~ ~s(aria-current="page")
    assert html =~ "ax-tab-active"
    # inactive buttons do not carry aria-current
    assert html =~ ~s(aria-current="page")
  end

  test "constructs correct patch hrefs from base_path" do
    html =
      render_component(&WindowSelector.window_selector/1, %{
        current_window: "7d",
        base_path: "/billing/analytics/recovery"
      })

    assert html =~ ~s(?window=7d)
    assert html =~ ~s(?window=30d)
    assert html =~ ~s(?window=90d)
  end
end
```

---

### `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` (test, request-response)

**Analog:** self (extend existing file)

**Test module header / setup** (recovery_live_test.exs lines 1-53):
```elixir
defmodule AccrueAdmin.Live.Analytics.RecoveryLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events

  # inline AuthAdapter defined here (lines 6-24)

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    Events.record(%{type: "dunning.recovered", ...})
    Events.record(%{type: "dunning.exhausted", ...})
    :ok
  end
```

**Existing live/2 connection pattern** (recovery_live_test.exs lines 55-58):
```elixir
test "renders recovery dashboard with MRR totals", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")
  assert html =~ "Revenue Recovery"
```

**JPY env-override teardown pattern** (recovery_live_test.exs lines 130-144):
```elixir
prior_currency = Application.get_env(:accrue, :default_currency)
Application.put_env(:accrue, :default_currency, :jpy)
on_exit(fn ->
  if is_nil(prior_currency) do
    Application.delete_env(:accrue, :default_currency)
  else
    Application.put_env(:accrue, :default_currency, prior_currency)
  end
end)
```

**New tests to add** (adapt from live/2 connection pattern + RESEARCH.md test examples):
```elixir
describe "window parameter (DAN-10)" do
  test "no ?window= param defaults to 30d window selector active", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")
    # 30d button is active; 7d and 90d are not
    assert html =~ "30 days UTC"
    assert html =~ ~s(aria-current="page")
  end

  test "?window=7d renders 7d button as active", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=7d")
    assert html =~ "7 days UTC"
    assert html =~ ~s(aria-current="page")
  end

  test "?window=90d renders 90d button as active", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=90d")
    assert html =~ "90 days UTC"
    assert html =~ ~s(aria-current="page")
  end

  test "invalid ?window= falls back to 30d default", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=bad")
    assert html =~ "30 days UTC"
  end

  test "window change via render_patch reloads data", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/analytics/recovery")
    html = render_patch(view, "/billing/analytics/recovery?window=7d")
    assert html =~ "7 days UTC"
    assert html =~ ~s(aria-current="page")
  end
end
```

---

## Shared Patterns

### Phoenix.Component authoring
**Source:** `accrue_admin/lib/accrue_admin/components/tabs.ex` (entire file, 28 lines)
**Apply to:** `window_selector.ex`
```elixir
use Phoenix.Component

attr(:name, :type, required: true)

def function_name(assigns) do
  ~H"""
  ...
  """
end
```
- `use Phoenix.Component` (not `use Phoenix.LiveComponent`) — stateless function component
- `attr/3` macros declare the public API; planner generates ExDoc from them automatically
- Single public function named identically to the module's concept (tabs → `tabs/1`, window_selector → `window_selector/1`)

### aria-current active state pattern
**Source:** `accrue_admin/lib/accrue_admin/components/tabs.ex` lines 18-20
**Apply to:** `window_selector.ex`
```elixir
aria-current={if(active_tab?(tab, @active), do: "page", else: nil)}
```
The `nil` value omits the attribute entirely from the rendered HTML — correct accessibility behavior. Use `"page"` (not `"true"`) per ARIA spec for current page/view within a nav.

### ax-tab CSS class pattern
**Source:** `accrue_admin/lib/accrue_admin/components/tabs.ex` line 17
**Apply to:** `window_selector.ex`
```elixir
class={["ax-tab", active_tab?(tab, @active) && "ax-tab-active"]}
```
Phoenix.Component list-class syntax: base class + conditional extra class. `false` entries are dropped; `nil` entries are dropped. `&&` returns `false` (dropped) or the string (added).

### mount → pure shell setup
**Source:** `accrue_admin/lib/accrue_admin/live/customers_live.ex` lines 16-19 (pattern); `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` line 82 (`assign_shell/2` location)
**Apply to:** `recovery_live.ex` refactored `mount/3`
```elixir
@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  {:ok, assign_shell(socket, admin)}
end
```
No DB calls, no analytics calls, no business logic — only session reads and shell assigns.

### handle_params return tuple
**Source:** `accrue_admin/lib/accrue_admin/live/customers_live.ex` line 44
**Apply to:** `recovery_live.ex` new `handle_params/3`
```elixir
{:noreply, assign(socket, ...)}
# or with pipe:
{:noreply, socket |> assign(...) |> assign(...)}
```
`handle_params` returns `{:noreply, socket}` (not `{:ok, socket}` like `mount`).

### Application env override + on_exit teardown
**Source:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` lines 27-30
**Apply to:** Any new test in `recovery_live_test.exs` that needs env isolation
```elixir
prior = Application.get_env(:accrue, :auth_adapter)
Application.put_env(:accrue, :auth_adapter, AuthAdapter)
on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)
```

### render_component for component tests
**Source:** `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs` lines 10-13; `navigation_components_test.exs` lines 14-17
**Apply to:** new WindowSelector describe block in `navigation_components_test.exs`
```elixir
html =
  render_component(&ModuleName.function_name/1, %{
    attr_one: value,
    attr_two: value
  })
assert html =~ "expected text"
```
No LiveCase, no DB, no endpoint required for stateless `Phoenix.Component` tests.

---

## No Analog Found

None. All 4 files have strong analogs in the codebase.

---

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/components/`, `accrue_admin/lib/accrue_admin/live/`, `accrue_admin/test/accrue_admin/components/`, `accrue_admin/test/accrue_admin/live/`, `accrue/lib/accrue/analytics/`
**Files scanned:** 7 source files read directly + 2 grep scans
**Pattern extraction date:** 2026-05-27
