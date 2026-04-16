# Phase 7: Admin UI (accrue_admin) - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 18
**Analogs found:** 12 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/router.ex` | route | request-response | No in-repo analog | none |
| `accrue_admin/lib/accrue_admin/assets.ex` | controller | file-I/O | No in-repo analog | none |
| `accrue_admin/lib/accrue_admin/layouts.ex` | component | request-response | `accrue/lib/accrue/invoices/layouts.ex` | adjacent |
| `accrue_admin/lib/accrue_admin/auth_hook.ex` | hook | request-response | `accrue/lib/accrue/auth.ex` | adjacent |
| `accrue_admin/lib/accrue_admin/csp_plug.ex` | middleware | request-response | `accrue/lib/accrue/plug/put_operation_id.ex` | role-match |
| `accrue_admin/lib/accrue_admin/brand_plug.ex` | middleware | request-response | `accrue/lib/accrue/config.ex` | adjacent |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | component | CRUD | `accrue/lib/accrue/invoices/components.ex` | adjacent |
| `accrue_admin/lib/accrue_admin/components/*.ex` | component | request-response | `accrue/lib/accrue/invoices/components.ex` | adjacent |
| `accrue_admin/lib/accrue_admin/live/*_live.ex` | component | CRUD | No in-repo analog | none |
| `accrue_admin/lib/accrue_admin/live/*_live.html.heex` | component | request-response | No in-repo analog | none |
| `accrue_admin/lib/accrue_admin/queries/*.ex` | service | CRUD | `accrue/lib/accrue/billing/query.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/webhooks.ex` | service | CRUD | `accrue/lib/accrue/webhooks/dlq.ex` | role-match |
| `accrue_admin/lib/accrue_admin/queries/events.ex` | service | CRUD | `accrue/lib/accrue/events.ex` | role-match |
| `accrue_admin/lib/accrue_admin/dev/*.ex` | component | event-driven | `accrue/lib/accrue/emails/html_bridge.ex` | adjacent |
| `accrue_admin/test/support/*_case.ex` | test | request-response | `accrue/test/support/repo_case.ex` and `accrue/test/support/billing_case.ex` | exact |
| `accrue_admin/test/**/*_test.exs` | test | CRUD | `accrue/test/accrue/invoices/components_test.exs` and `accrue/test/accrue/billing/query_test.exs` | exact |

## Pattern Assignments

### Monorepo naming/layout/module organization

**Analog:** `accrue/lib/accrue/billing.ex` and `accrue_admin/lib/accrue_admin.ex`

**Namespace anchor pattern** ([accrue_admin/lib/accrue_admin.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin.ex:1)):
```elixir
defmodule AccrueAdmin do
  @moduledoc """
  AccrueAdmin — Phoenix LiveView admin UI for Accrue billing.
  ...
  """
end
```

**Facade + submodule split** ([accrue/lib/accrue/billing.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:1)):
```elixir
defmodule Accrue.Billing do
  alias Accrue.Billing.{
    ChargeActions,
    CouponActions,
    InvoiceActions,
    MeterEventActions,
    PaymentMethodActions,
    RefundActions,
    SubscriptionActions,
    SubscriptionItems,
    SubscriptionScheduleActions
  }

  defdelegate finalize_invoice(invoice, opts \\ []), to: InvoiceActions
  defdelegate charge(customer, amount_or_opts, opts \\ []), to: ChargeActions
end
```

**Apply to Phase 7**
- Keep `accrue_admin/lib/accrue_admin.ex` as the namespace anchor only.
- Put concrete responsibilities in leaf modules under `AccrueAdmin.Router`, `AccrueAdmin.Layouts`, `AccrueAdmin.Components.*`, `AccrueAdmin.Queries.*`, `AccrueAdmin.Live.*`, `AccrueAdmin.Dev.*`.
- Keep query logic out of LiveViews. Phase 7 context already locks that shape; it matches the existing `Billing` facade plus per-surface modules.

### Config and behaviour boundaries

**Analog:** `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/repo.ex`, `accrue/lib/accrue/auth.ex`

**Runtime config boundary** ([accrue/lib/accrue/config.ex](/Users/jon/projects/accrue/accrue/lib/accrue/config.ex:313)):
```elixir
@moduledoc """
Runtime configuration schema for Accrue, backed by `NimbleOptions`.
...
Adapter atoms ... are stable per-deploy and fine at compile time ...
Secrets ... and host-owned fields ... MUST be read at runtime.
"""
```

**`get!/1` guard pattern** ([accrue/lib/accrue/config.ex](/Users/jon/projects/accrue/accrue/lib/accrue/config.ex:345)):
```elixir
def get!(key) when is_atom(key) do
  unless Keyword.has_key?(@schema, key) do
    raise Accrue.ConfigError, key: key, message: "unknown accrue config key: #{inspect(key)}"
  end

  case Application.get_env(:accrue, key, :__accrue_unset__) do
    :__accrue_unset__ -> default_for(key)
    value -> value
  end
end
```

**Behaviour facade boundary** ([accrue/lib/accrue/auth.ex](/Users/jon/projects/accrue/accrue/lib/accrue/auth.ex:37)):
```elixir
@callback current_user(conn()) :: user() | nil
@callback require_admin_plug() :: (conn(), keyword() -> conn())
@callback user_schema() :: module() | nil
@callback log_audit(user(), map()) :: :ok
@callback actor_id(user()) :: String.t() | nil
```

**Runtime module resolution** ([accrue/lib/accrue/repo.ex](/Users/jon/projects/accrue/accrue/lib/accrue/repo.ex:157)):
```elixir
def repo do
  case Application.get_env(:accrue, :repo) do
    nil ->
      raise Accrue.ConfigError, key: :repo, message: "config :accrue, :repo, MyApp.Repo is required ..."

    mod when is_atom(mod) ->
      mod
  end
end
```

**Apply to Phase 7**
- `accrue_admin` should read host-owned auth and branding via `Accrue.Auth` and `Accrue.Config`, not define duplicate config authority.
- New `AccrueAdmin.*` modules should resolve runtime collaborators with `Application.get_env/3` or existing `Accrue.*` facades, not compile-time aliases.
- If the router macro needs option validation, follow `NimbleOptions` schema style from `Accrue.Config`.

### Ecto query/helper organization

**Analog:** `accrue/lib/accrue/billing/query.ex`, `accrue/lib/accrue/billing/invoice_projection.ex`, `accrue/lib/accrue/connect.ex`

**Composable query module** ([accrue/lib/accrue/billing/query.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/query.ex:1)):
```elixir
defmodule Accrue.Billing.Query do
  import Ecto.Query
  alias Accrue.Billing.Subscription

  def active(query \\ Subscription) do
    from s in query, where: s.status in [:active, :trialing]
  end
end
```

**Projection/decomposition helper** ([accrue/lib/accrue/billing/invoice_projection.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice_projection.ex:25)):
```elixir
@spec decompose(map()) :: {:ok, decomposed()}
def decompose(stripe_inv) when is_map(stripe_inv) do
  ...
  {:ok, %{invoice_attrs: invoice_attrs, item_attrs: item_attrs}}
end
```

**Local query kept near domain facade** ([accrue/lib/accrue/connect.ex](/Users/jon/projects/accrue/accrue/lib/accrue/connect.ex:31)):
```elixir
import Ecto.Query, only: [from: 2]
...
def list_accounts(opts \\ []) when is_list(opts) do
```

**Apply to Phase 7**
- Create one `AccrueAdmin.Queries.<Resource>` module per admin resource.
- Keep each query module pure and Ecto-focused: filters, joins, cursor clauses, preload policy, result shaping.
- If row shaping gets non-trivial, split a sibling helper like `AccrueAdmin.Queries.InvoiceRows` instead of bloating the LiveView.
- Match the current repo style: query helpers return `Ecto.Query.t()` or plain maps, while LiveViews call `Accrue.Repo.all/one/aggregate`.

### HEEx/component patterns

**Analog:** `accrue/lib/accrue/invoices/components.ex`, `accrue/lib/accrue/invoices/layouts.ex`, `accrue/lib/accrue/emails/html_bridge.ex`

**Function-component module shape** ([accrue/lib/accrue/invoices/components.ex](/Users/jon/projects/accrue/accrue/lib/accrue/invoices/components.ex:32)):
```elixir
use Phoenix.Component

attr(:context, :map, required: true)

def invoice_header(assigns) do
  ~H"""
  <table ...>
    ...
  </table>
  """
end
```

**Shared layout wrapper** ([accrue/lib/accrue/invoices/layouts.ex](/Users/jon/projects/accrue/accrue/lib/accrue/invoices/layouts.ex:20)):
```elixir
use Phoenix.Component
import Accrue.Invoices.Components

attr(:context, :map, required: true)

def print_shell(assigns) do
  ~H"""
  <!DOCTYPE html>
  <html>
    ...
  </html>
  """
end
```

**Render-outside-LiveView seam** ([accrue/lib/accrue/emails/html_bridge.ex](/Users/jon/projects/accrue/accrue/lib/accrue/emails/html_bridge.ex:31)):
```elixir
@spec render((map() -> Phoenix.LiveView.Rendered.t()), map()) :: String.t()
def render(component, assigns) when is_function(component, 1) and is_map(assigns) do
  component
  |> apply([assigns])
  |> Phoenix.HTML.Safe.to_iodata()
  |> IO.iodata_to_binary()
end
```

**Apply to Phase 7**
- Default to pure function components in `accrue_admin/lib/accrue_admin/components/`.
- Use `attr` declarations and narrow assigns contracts.
- Promote to `Phoenix.LiveComponent` only where state is real: `DataTable`, step-up modal, detail drawer.
- Keep root layout and major shells in `AccrueAdmin.Layouts`; keep reusable atoms in `AccrueAdmin.Components.*`.

### Telemetry, event, and audit integration

**Analog:** `accrue/lib/accrue/telemetry.ex`, `accrue/lib/accrue/telemetry/ops.ex`, `accrue/lib/accrue/events.ex`, `accrue/lib/accrue/integrations/sigra.ex`

**Span wrapper pattern** ([accrue/lib/accrue/telemetry.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry.ex:55)):
```elixir
def span(event, metadata \\ %{}, fun)
    when is_list(event) and is_map(metadata) and is_function(fun, 0) do
  base_metadata = maybe_put_actor(metadata)

  :telemetry.span(event, base_metadata, fn ->
    result = fun.()
    {result, base_metadata}
  end)
end
```

**Ops event helper** ([accrue/lib/accrue/telemetry/ops.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/ops.ex:46)):
```elixir
def emit(suffix, measurements, metadata \\ %{})
...
event = [:accrue, :ops] ++ suffix
:telemetry.execute(event, measurements, merged_metadata)
```

**Audit/event write seam** ([accrue/lib/accrue/events.ex](/Users/jon/projects/accrue/accrue/lib/accrue/events.ex:92)):
```elixir
@spec record_multi(Ecto.Multi.t(), atom(), attrs()) :: Ecto.Multi.t()
def record_multi(multi, name, attrs) when is_atom(name) and is_map(attrs) do
  normalized = normalize(attrs)
  changeset = Event.changeset(normalized)

  Ecto.Multi.insert(multi, name, changeset, insert_opts(normalized))
end
```

**Sigra audit delegation** ([accrue/lib/accrue/integrations/sigra.ex](/Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex:54)):
```elixir
@impl Accrue.Auth
def current_user(conn), do: Sigra.Auth.current_user(conn)

@impl Accrue.Auth
def log_audit(user, event), do: Sigra.Audit.log(user, event)
```

**Apply to Phase 7**
- Wrap admin page loads and destructive actions in `Accrue.Telemetry.span/3`.
- Use `Accrue.Telemetry.Ops.emit/3` only for high-signal admin events like replay bulk actions or auth denial, not every page render.
- Record admin mutations into `accrue_events` via `Accrue.Events.record/1` or `record_multi/3`; do not invent a parallel audit table.
- Thread actor info through `Accrue.Auth.current_user/1`, `Accrue.Auth.actor_id/1`, and `Accrue.Auth.log_audit/2`.

### Test layout and assertion style

**Analog:** `accrue/test/support/repo_case.ex`, `accrue/test/support/billing_case.ex`, `accrue/test/accrue/invoices/components_test.exs`, `accrue/test/accrue/billing/query_test.exs`, `accrue/test/accrue/telemetry_test.exs`, `accrue/lib/accrue/test/mailer_assertions.ex`

**CaseTemplate setup** ([accrue/test/support/repo_case.ex](/Users/jon/projects/accrue/accrue/test/support/repo_case.ex:16)):
```elixir
use ExUnit.CaseTemplate

using do
  quote do
    alias Accrue.TestRepo
    import Ecto
    import Ecto.Changeset
    import Ecto.Query
  end
end
```

**Heavier integration case** ([accrue/test/support/billing_case.ex](/Users/jon/projects/accrue/accrue/test/support/billing_case.ex:47)):
```elixir
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  :ok = Accrue.Processor.Fake.reset()
  :ok = Accrue.Actor.put_operation_id("test-" <> Ecto.UUID.generate())
  :ok
end
```

**Component assertion style** ([accrue/test/accrue/invoices/components_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/invoices/components_test.exs:67)):
```elixir
describe "invoice_header/1" do
  test "renders business_name + invoice number" do
    ctx = build_context()
    out = HtmlBridge.render(&Components.invoice_header/1, %{context: ctx})

    assert out =~ "TestCo"
    assert out =~ "INV-0001"
  end
end
```

**Query test style** ([accrue/test/accrue/billing/query_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/query_test.exs:58)):
```elixir
test "active/1 returns trialing + active rows" do
  statuses = Query.active() |> Repo.all() |> Enum.map(& &1.status)
  assert :trialing in statuses
  refute :past_due in statuses
end
```

**Telemetry capture style** ([accrue/test/accrue/telemetry_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/telemetry_test.exs:12)):
```elixir
:telemetry.attach_many(
  handler_id,
  events,
  fn event, measurements, metadata, _ ->
    send(parent, {:telemetry, event, measurements, metadata})
  end,
  nil
)
```

**Mailbox assertion helper style** ([accrue/lib/accrue/test/mailer_assertions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/test/mailer_assertions.ex:37)):
```elixir
defmacro assert_email_sent(type, opts \\ [], timeout \\ 100) do
  quote do
    receive do
      {:accrue_email_delivered, ^expected_type, assigns} -> ...
    after
      t -> ExUnit.Assertions.flunk(...)
    end
  end
end
```

**Apply to Phase 7**
- Add `accrue_admin/test/support/live_case.ex` and `repo_case.ex` as `ExUnit.CaseTemplate` modules rather than ad-hoc setup duplication.
- Use `describe` blocks, direct `assert`/`refute`, and mailbox assertions for telemetry or JS hook side effects.
- For function components, prefer `render_component/2` or the existing binary-render pattern rather than brittle HTML snapshots.
- For query modules, seed rows explicitly and assert inclusion/exclusion semantics, not raw SQL strings.

## Shared Patterns

### Runtime boundary pattern
**Sources:** [accrue/lib/accrue/config.ex](/Users/jon/projects/accrue/accrue/lib/accrue/config.ex:321), [accrue/lib/accrue/repo.ex](/Users/jon/projects/accrue/accrue/lib/accrue/repo.ex:3)

Apply to all `AccrueAdmin.*` modules that depend on host state.
```elixir
# Runtime resolution, not compile-time aliasing.
Application.get_env(:accrue, :repo)
Application.get_env(:accrue, :auth_adapter, Accrue.Auth.Default)
```

### Behaviour seam pattern
**Sources:** [accrue/lib/accrue/auth.ex](/Users/jon/projects/accrue/accrue/lib/accrue/auth.ex:37), [accrue/lib/accrue/integrations/sigra.ex](/Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex:31)

Apply to auth hook, step-up auth, and audit wiring.
```elixir
@behaviour Accrue.Auth
def current_user(conn), do: Sigra.Auth.current_user(conn)
def log_audit(user, event), do: Sigra.Audit.log(user, event)
```

### Query-module ownership pattern
**Sources:** [accrue/lib/accrue/billing/query.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/query.ex:21), [accrue/lib/accrue/billing/invoice_projection.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice_projection.ex:25)

Apply to every admin list/detail page.
```elixir
import Ecto.Query

def active(query \\ Subscription) do
  from s in query, where: s.status in [:active, :trialing]
end
```

### Telemetry/audit pattern
**Sources:** [accrue/lib/accrue/telemetry.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry.ex:23), [accrue/lib/accrue/events.ex](/Users/jon/projects/accrue/accrue/lib/accrue/events.ex:17)

Apply to admin actions and long-running data loads.
```elixir
Accrue.Telemetry.span([:accrue, :admin, :resource, :action], %{resource_id: id}, fn ->
  ...
end)

Accrue.Events.record(%{
  type: "admin.refund.created",
  subject_type: "Refund",
  subject_id: refund.id
})
```

### Component-module pattern
**Sources:** [accrue/lib/accrue/invoices/components.ex](/Users/jon/projects/accrue/accrue/lib/accrue/invoices/components.ex:32), [accrue/lib/accrue/invoices/layouts.ex](/Users/jon/projects/accrue/accrue/lib/accrue/invoices/layouts.ex:20)

Apply to `AccrueAdmin.Layouts` and `AccrueAdmin.Components.*`.
```elixir
use Phoenix.Component

attr(:context, :map, required: true)

def component(assigns) do
  ~H"""..."""
end
```

## Existing LiveView / HEEx Coverage

### What exists
- HEEx function-component patterns exist in `accrue`, not `accrue_admin`.
- The only current real Phoenix UI-style modules are [accrue/lib/accrue/invoices/components.ex](/Users/jon/projects/accrue/accrue/lib/accrue/invoices/components.ex:1) and [accrue/lib/accrue/invoices/layouts.ex](/Users/jon/projects/accrue/accrue/lib/accrue/invoices/layouts.ex:1).
- Rendering components outside a mounted LiveView already exists via [accrue/lib/accrue/emails/html_bridge.ex](/Users/jon/projects/accrue/accrue/lib/accrue/emails/html_bridge.ex:1).

### What does not exist
- No `use Phoenix.LiveView` modules exist in the repo today.
- No `handle_params/3`, streams, `on_mount`, `live_session`, or `Phoenix.LiveViewTest` patterns exist in-repo yet.
- No existing `accrue_admin` components beyond the namespace anchor exist.

### Planner implication
- Treat LiveView page modules, router macro wiring, and assets controller work as greenfield within this repo.
- Copy HEEx/component discipline from `accrue/lib/accrue/invoices/*`.
- Do not claim false precedent for router/assets macro code; Phase 7 context already points to `Phoenix.LiveDashboard` as the external reference for that portion.

## Recommended file/module conventions for plan ownership

- Reserve `accrue_admin/lib/accrue_admin/router.ex`, `assets.ex`, `layouts.ex`, `auth_hook.ex`, `csp_plug.ex`, and `brand_plug.ex` for foundation plans only. They are high-collision files.
- Put each reusable visual primitive in its own module under `accrue_admin/lib/accrue_admin/components/`: `data_table.ex`, `detail_drawer.ex`, `status_badge.ex`, `kpi_card.ex`, `timeline.ex`, `json_viewer.ex`, `step_up_auth_modal.ex`.
- Put each resource query surface in its own file under `accrue_admin/lib/accrue_admin/queries/`: `customers.ex`, `subscriptions.ex`, `invoices.ex`, `charges.ex`, `events.ex`, `webhooks.ex`, `connect_accounts.ex`, `coupons.ex`, `promotion_codes.ex`.
- Standardize the namespace on `AccrueAdmin.Queries.*`; do not mix `query/` and `queries/` trees in Phase 7 plans or implementation.
- Put each page in its own LiveView module under `accrue_admin/lib/accrue_admin/live/`, with page templates either colocated `.html.heex` or inline `~H` depending on team preference. Keep page modules thin and delegate query work.
- Keep dev-only surfaces under `accrue_admin/lib/accrue_admin/dev/` and `accrue_admin/test/accrue_admin/dev/` so compile gating and test selection stay isolated.
- Mirror test namespaces to runtime namespaces exactly. Existing `accrue` tests already follow this pattern consistently.

## No Analog Found

| File/Area | Role | Data Flow | Reason |
|---|---|---|---|
| `accrue_admin/lib/accrue_admin/router.ex` | route | request-response | No existing router macro, `live_session`, or `on_mount` code in this repo |
| `accrue_admin/lib/accrue_admin/assets.ex` | controller | file-I/O | No existing compile-time asset controller or MD5-suffixed asset route in this repo |
| `accrue_admin/lib/accrue_admin/live/*` | component | CRUD | No existing LiveView modules, streams, or `handle_params` patterns in this repo |
| `accrue_admin/test/**/*_live_test.exs` | test | request-response | No current `Phoenix.LiveViewTest` usage in this repo |

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/test`, `accrue_admin/lib`, `accrue_admin/test`
**Files scanned:** 130+
**Pattern extraction date:** 2026-04-15
