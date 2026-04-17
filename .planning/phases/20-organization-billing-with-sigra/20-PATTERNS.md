# Phase 20: Organization Billing With Sigra - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 29
**Analogs found:** 29 / 29

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/lib/accrue_host/accounts/organization.ex` | model | CRUD | `examples/accrue_host/lib/accrue_host/accounts/user.ex` | exact |
| `examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex` | model | CRUD | `examples/accrue_host/lib/accrue_host/accounts/user_token.ex` | partial |
| `examples/accrue_host/lib/accrue_host/accounts.ex` | service | CRUD | `examples/accrue_host/lib/accrue_host/accounts.ex` | exact |
| `examples/accrue_host/lib/accrue_host/accounts/scope.ex` | model | request-response | `examples/accrue_host/lib/accrue_host/accounts/scope.ex` | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | service | request-response | `examples/accrue_host/lib/accrue_host/billing.ex` | exact |
| `examples/accrue_host/lib/accrue_host_web/user_auth.ex` | middleware | request-response | `examples/accrue_host/lib/accrue_host_web/user_auth.ex` | exact |
| `examples/accrue_host/lib/accrue_host_web/router.ex` | route | request-response | `examples/accrue_host/lib/accrue_host_web/router.ex` | exact |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | component | request-response | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | exact |
| `examples/accrue_host/test/support/fixtures/accounts_fixtures.ex` | test | CRUD | `examples/accrue_host/test/support/fixtures/accounts_fixtures.ex` | exact |
| `examples/accrue_host/test/accrue_host/billing_facade_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host/billing_facade_test.exs` | exact |
| `examples/accrue_host/test/accrue_host_web/org_billing_live_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` | role-match |
| `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` | role-match |
| `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` | exact |
| `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` | test | event-driven | `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` | exact |
| `examples/accrue_host/priv/repo/migrations/<ts>_create_organizations.exs` | migration | CRUD | `examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs` | role-match |
| `examples/accrue_host/priv/repo/migrations/<ts>_create_organization_memberships.exs` | migration | CRUD | `examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs` | role-match |
| `accrue/test/accrue/billable_test.exs` | test | CRUD | `accrue/test/accrue/billable_test.exs` | exact |
| `accrue_admin/lib/accrue_admin/auth_hook.ex` | middleware | request-response | `accrue_admin/lib/accrue_admin/auth_hook.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/customers.ex` | service | CRUD | `accrue_admin/lib/accrue_admin/queries/customers.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | service | CRUD | `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/invoices.ex` | service | CRUD | `accrue_admin/lib/accrue_admin/queries/invoices.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/webhooks.ex` | service | event-driven | `accrue_admin/lib/accrue_admin/queries/webhooks.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/customer_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | partial |
| `accrue_admin/test/accrue_admin/live/customer_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/customer_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` | exact |

## Pattern Assignments

### Host billable organization models

#### `examples/accrue_host/lib/accrue_host/accounts/organization.ex` (model, CRUD)

**Primary analog:** `examples/accrue_host/lib/accrue_host/accounts/user.ex`

Use the host schema shape from [`examples/accrue_host/lib/accrue_host/accounts/user.ex:1`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/user.ex#L1), but keep it slimmer and pin the billable type the same way `User` does:

```elixir
defmodule AccrueHost.Accounts.User do
  use Ecto.Schema
  use Accrue.Billable, billable_type: "User"
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :billing_admin, :boolean, default: false
```

The org schema should also copy the macro contract from [`accrue/lib/accrue/billable.ex:61`](/Users/jon/projects/accrue/accrue/lib/accrue/billable.ex#L61):

```elixir
quote do
  @__accrue_billable_type__ unquote(billable_type)
  @before_compile Accrue.Billable

  @doc false
  def __accrue__(:billable_type), do: @__accrue_billable_type__
end
```

For ORG-01 round-trip expectations, copy the assertions from [`accrue/test/accrue/billable_test.exs:67`](/Users/jon/projects/accrue/accrue/test/accrue/billable_test.exs#L67):

```elixir
assert {:ok, %Customer{} = customer} = Billing.create_customer(user)
assert customer.owner_type == "TestUser"
assert customer.owner_id == to_string(user.id)
assert customer.processor == "fake"
```

#### `examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex` (model, CRUD)

**Primary analog:** `examples/accrue_host/lib/accrue_host/accounts/user_token.ex`

There is no existing membership schema, so copy the Ecto schema / binary-id / `belongs_to` style from [`examples/accrue_host/lib/accrue_host/accounts/user_token.ex:15`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/user_token.ex#L15):

```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
schema "users_tokens" do
  field :token, :binary
  field :context, :string
  field :sent_to, :string
  field :authenticated_at, :utc_datetime
  belongs_to :user, AccrueHost.Accounts.User
```

For changeset conventions, reuse the cast/validate pattern from [`examples/accrue_host/lib/accrue_host/accounts/user.ex:30`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/user.ex#L30) and keep role/admin flags explicit booleans or enums rather than inferred from params.

#### `examples/accrue_host/lib/accrue_host/accounts.ex` (service, CRUD)

**Primary analog:** `examples/accrue_host/lib/accrue_host/accounts.ex`

Keep org and membership lookup helpers in the same context module and follow the same thin Repo-boundary style as [`examples/accrue_host/lib/accrue_host/accounts.ex:25`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts.ex#L25) and [`examples/accrue_host/lib/accrue_host/accounts.ex:77`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts.ex#L77):

```elixir
def get_user_by_email(email) when is_binary(email) do
  Repo.get_by(User, email: email)
end

def register_user(attrs) do
  %User{}
  |> User.email_changeset(attrs)
  |> Repo.insert()
end
```

For membership-sensitive writes, mirror the transactional pattern from [`examples/accrue_host/lib/accrue_host/accounts.ex:122`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts.ex#L122) when multiple rows must stay in sync.

### Host scope, auth, and route threading

#### `examples/accrue_host/lib/accrue_host/accounts/scope.ex` (model, request-response)

**Primary analog:** `examples/accrue_host/lib/accrue_host/accounts/scope.ex`

Extend the current scope struct instead of inventing a second scope carrier. The file is intentionally simple today at [`examples/accrue_host/lib/accrue_host/accounts/scope.ex:19`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex#L19):

```elixir
alias AccrueHost.Accounts.User

defstruct user: nil

def for_user(%User{} = user) do
  %__MODULE__{user: user}
end
```

Phase 20 should add `organization`, `organization_membership`, and org-admin predicates here, then keep every host/admin entry point reading from `current_scope`.

#### `examples/accrue_host/lib/accrue_host_web/user_auth.ex` (middleware, request-response)

**Primary analog:** `examples/accrue_host/lib/accrue_host_web/user_auth.ex`

Keep scope hydration in the auth plug and LiveView mount, not in the billing page. Copy the assign pattern from [`examples/accrue_host/lib/accrue_host_web/user_auth.ex:67`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/user_auth.ex#L67) and [`examples/accrue_host/lib/accrue_host_web/user_auth.ex:248`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/user_auth.ex#L248):

```elixir
def fetch_current_scope_for_user(conn, _opts) do
  with {token, conn} <- ensure_user_token(conn),
       {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
    conn
    |> assign(:current_scope, Scope.for_user(user))
    |> maybe_reissue_user_session_token(user, token_inserted_at)
  else
    nil -> assign(conn, :current_scope, Scope.for_user(nil))
  end
end
```

```elixir
defp mount_current_scope(socket, session) do
  Phoenix.Component.assign_new(socket, :current_scope, fn ->
    {user, _} =
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end || {nil, nil}

    Scope.for_user(user)
  end)
end
```

Phase 20 should extend these functions to derive the active organization and membership from Sigra/session state server-side. Do not let LiveView event params choose the organization.

#### `examples/accrue_host/lib/accrue_host_web/router.ex` (route, request-response)

**Primary analog:** `examples/accrue_host/lib/accrue_host_web/router.ex`

Preserve the current plug and `live_session` arrangement from [`examples/accrue_host/lib/accrue_host_web/router.ex:8`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/router.ex#L8) and [`examples/accrue_host/lib/accrue_host_web/router.ex:44`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/router.ex#L44):

```elixir
pipeline :browser do
  plug(:accepts, ["html"])
  plug(:fetch_session)
  plug(:fetch_live_flash)
  plug(:put_root_layout, html: {AccrueHostWeb.Layouts, :root})
  plug(:protect_from_forgery)
  plug(:put_secure_browser_headers)
  plug(:fetch_current_scope_for_user)
end
```

```elixir
live_session :require_authenticated_user,
  on_mount: [{AccrueHostWeb.UserAuth, :require_authenticated}] do
  live("/app/billing", SubscriptionLive, :show)
end
```

Keep Phase 20 on the existing `/app/billing` route unless planning explicitly chooses a sibling page.

### Host billing facade and billing LiveView

#### `examples/accrue_host/lib/accrue_host/billing.ex` (service, request-response)

**Primary analog:** `examples/accrue_host/lib/accrue_host/billing.ex`

This is the main host policy seam. Keep the file thin and explicit, like [`examples/accrue_host/lib/accrue_host/billing.ex:17`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex#L17):

```elixir
def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end

def customer_for(billable) do
  Billing.customer(billable)
end

def update_customer_tax_location(billable, attrs) when is_map(attrs) do
  with {:ok, customer} <- customer_for(billable) do
    Billing.update_customer_tax_location(customer, attrs)
  end
end
```

Also copy the local ownership lookup from [`examples/accrue_host/lib/accrue_host/billing.ex:54`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex#L54):

```elixir
defp find_customer(%{__struct__: mod, id: id}) do
  billable_type = mod.__accrue__(:billable_type)
  owner_id = to_string(id)

  from(customer in Customer,
    where: customer.owner_type == ^billable_type and customer.owner_id == ^owner_id,
    limit: 1
  )
  |> Repo.one()
end
```

Phase 20 should add server-side `organization_from_scope/1` style wrappers here rather than teaching the LiveView to resolve organizations directly.

#### `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` (component, request-response)

**Primary analog:** `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`

Keep all billing mutations going through the facade layer, using `current_scope`, operation ids, flash handling, and `load_state/1`. The existing handlers at [`examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:25`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex#L25) are the exact pattern:

```elixir
def handle_event("start_subscription", %{"plan" => plan_id} = params, socket) do
  user = socket.assigns.current_scope.user

  case Billing.subscribe(user, plan_id,
         automatic_tax: true,
         operation_id: operation_id(params, "subscribe")
       ) do
```

The state reload pattern at [`examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:297`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex#L297) should stay intact:

```elixir
defp load_state(socket) do
  {:ok, %{customer: customer, subscription: subscription}} =
    Billing.billing_state_for(socket.assigns.current_scope.user)

  socket
  |> assign(:plans, Plans.all())
  |> assign_action_operation_ids()
  |> assign(:customer, customer)
  |> assign(:subscription, subscription)
end
```

For Phase 20, replace `current_scope.user` with active-organization resolution from the scope, preserve the two-step cancel flow, and reuse the Phase 19 tax-state panel/copy structure instead of building a second billing screen.

#### `examples/accrue_host/test/support/fixtures/accounts_fixtures.ex` (test, CRUD)

**Primary analog:** `examples/accrue_host/test/support/fixtures/accounts_fixtures.ex`

Create org and membership fixtures beside the user fixtures. Reuse the current fixture shape from [`examples/accrue_host/test/support/fixtures/accounts_fixtures.ex:30`](/Users/jon/projects/accrue/examples/accrue_host/test/support/fixtures/accounts_fixtures.ex#L30) and [`examples/accrue_host/test/support/fixtures/accounts_fixtures.ex:44`](/Users/jon/projects/accrue/examples/accrue_host/test/support/fixtures/accounts_fixtures.ex#L44):

```elixir
def user_fixture(attrs \\ %{}) do
  user = unconfirmed_user_fixture(attrs)
  token = extract_user_token(fn url -> Accounts.deliver_login_instructions(user, url) end)
  {:ok, {user, _expired_tokens}} = Accounts.login_user_by_magic_link(token)
  user
end

def user_scope_fixture(user) do
  Scope.for_user(user)
end
```

Add `organization_fixture/1`, `organization_membership_fixture/1`, and `organization_scope_fixture/1` helpers here instead of in the test modules.

### Host tests

#### `examples/accrue_host/test/accrue_host/billing_facade_test.exs` (test, request-response)

**Primary analog:** `examples/accrue_host/test/accrue_host/billing_facade_test.exs`

Use the file as the template for ORG-01 and org facade coverage. The existing assertions at [`examples/accrue_host/test/accrue_host/billing_facade_test.exs:39`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/billing_facade_test.exs#L39) and [`examples/accrue_host/test/accrue_host/billing_facade_test.exs:67`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/billing_facade_test.exs#L67) are the exact shape:

```elixir
assert {:ok, %Customer{} = customer} = Billing.customer_for(user)
assert {:ok, %Customer{} = same_customer} = Accrue.Billing.customer(user)
assert customer.owner_type == "User"
assert customer.owner_id == user.id
```

```elixir
assert {:ok, %{customer: nil, subscription: nil}} = Billing.billing_state_for(user)
```

Add organization-owned equivalents here and keep the "source stays thin" file-content assertion pattern from [`examples/accrue_host/test/accrue_host/billing_facade_test.exs:112`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host/billing_facade_test.exs#L112).

#### `examples/accrue_host/test/accrue_host_web/org_billing_live_test.exs` (new test, request-response)

**Primary analog:** `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`

Copy the existing host LiveView happy-path style from [`examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs:26`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs#L26):

```elixir
{:ok, view, html} =
  conn
  |> log_in_user(user)
  |> live(~p"/app/billing")

html =
  view
  |> form("#tax-location-form", %{"tax_location" => %{...}})
  |> render_submit()
```

Reuse the direct DB verification against `owner_type` / `owner_id` from [`examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs:53`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs#L53), but assert `"Organization"` and the active-org id.

#### `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` (new test, request-response)

**Primary analogs:** `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`

For redirect/denial shape, copy [`examples/accrue_host/test/accrue_host_web/admin_mount_test.exs:10`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_mount_test.exs#L10):

```elixir
assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/billing")
```

For cross-org replay/data setup, copy the seed style from [`examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:49`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L49) and [`examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:127`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L127). Phase 20 should invert those expectations for an out-of-scope org: redirect early, no partial detail, no replay audit row.

#### `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` (test, request-response)

**Primary analog:** `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs`

Keep the admin mount proof using forwarded session keys from [`examples/accrue_host/test/accrue_host_web/admin_mount_test.exs:21`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_mount_test.exs#L21). Phase 20 should add org-scope session assertions here if admin scope is threaded through the same session map.

#### `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` (test, event-driven)

**Primary analog:** `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`

This is the current end-to-end replay proof. Reuse the event setup and audit assertions from [`examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:80`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L80) and [`examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:116`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L116):

```elixir
{:ok, _event} =
  Events.record(%{
    type: "invoice.payment_failed",
    subject_type: "Subscription",
    subject_id: subscription.id,
    actor_type: "webhook",
    actor_id: webhook.processor_event_id,
    caused_by_webhook_event_id: webhook.id
  })
```

```elixir
replay_html = render_click(element(replay_view, "[data-role='replay-single']"))
assert replay_html =~ "Webhook replay requested."
updated = Repo.get!(WebhookEvent, webhook.id)
assert updated.status == :received
```

Phase 20 should preserve the same positive path for in-scope org admins and add denial cases for out-of-scope org admins.

### Host migrations

#### `examples/accrue_host/priv/repo/migrations/<ts>_create_organizations.exs`
#### `examples/accrue_host/priv/repo/migrations/<ts>_create_organization_memberships.exs`

**Primary analogs:** `examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs`, `examples/accrue_host/priv/repo/migrations/20260416000100_add_billing_admin_to_users.exs`

Use the normal host migration style from [`examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs:4`](/Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs#L4):

```elixir
def change do
  create table(:users, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :email, :citext, null: false
    ...
    timestamps(type: :utc_datetime)
  end
end
```

If the planner chooses additive membership/admin columns on existing tables, follow the idempotent `up/down` guard pattern from [`examples/accrue_host/priv/repo/migrations/20260416000100_add_billing_admin_to_users.exs:8`](/Users/jon/projects/accrue/examples/accrue_host/priv/repo/migrations/20260416000100_add_billing_admin_to_users.exs#L8) rather than assuming a fresh schema.

### Core ORG-01 proof

#### `accrue/test/accrue/billable_test.exs` (test, CRUD)

**Primary analog:** `accrue/test/accrue/billable_test.exs`

This file already includes the `"Organization"` billable-type test schema at [`accrue/test/accrue/billable_test.exs:29`](/Users/jon/projects/accrue/accrue/test/accrue/billable_test.exs#L29):

```elixir
defmodule TestOrg do
  use Ecto.Schema
  use Accrue.Billable, billable_type: "Organization"

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "test_orgs" do
  end
end
```

Phase 20 should extend this file instead of creating a new core test. The round-trip and fetch-or-create assertions already prove the right storage contract.

### Admin auth/session scope

#### `accrue_admin/lib/accrue_admin/auth_hook.ex` (middleware, request-response)

**Primary analog:** `accrue_admin/lib/accrue_admin/auth_hook.ex`

Keep admin/session assigns centralized here. The current hook at [`accrue_admin/lib/accrue_admin/auth_hook.ex:11`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/auth_hook.ex#L11) is the seam for adding org scope:

```elixir
def on_mount(:ensure_admin, _params, session, socket) do
  user = Auth.current_user(session)

  if Auth.admin?(user) do
    {:cont,
     socket
     |> assign(:accrue_admin_session, session)
     |> assign(:current_admin, user)
```

Add `:current_owner_scope` or equivalent here so every LiveView/query module reads the same server-side boundary.

#### `accrue_admin/lib/accrue_admin/router.ex` (route, request-response)

**Primary analog:** `accrue_admin/lib/accrue_admin/router.ex`

When owner scope needs additional session keys, use the existing `session_keys` threading at [`accrue_admin/lib/accrue_admin/router.ex:86`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex#L86) and [`accrue_admin/lib/accrue_admin/router.ex:87`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex#L87):

```elixir
def __session__(conn, session_keys, mount_path)
    when is_list(session_keys) and is_binary(mount_path) do
  host_session =
    Map.new(session_keys, fn key ->
      string_key = to_string(key)
      {string_key, get_session(conn, key)}
    end)
```

Do not invent a second admin session transport.

### Admin query scoping

#### `accrue_admin/lib/accrue_admin/queries/customers.ex`
#### `accrue_admin/lib/accrue_admin/queries/subscriptions.ex`
#### `accrue_admin/lib/accrue_admin/queries/invoices.ex`
#### `accrue_admin/lib/accrue_admin/queries/webhooks.ex`

**Primary analogs:** same files

These are the exact seams for ORG-03. Preserve the current cursor/filter/select pipeline and add owner filters before pagination.

Base list pattern from [`accrue_admin/lib/accrue_admin/queries/customers.ex:17`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/customers.ex#L17):

```elixir
Customer
|> filter_query(filter)
|> Behaviour.apply_cursor(@time_field, cursor)
|> order_by([customer], desc: customer.inserted_at, desc: customer.id)
|> limit(^Enum.max([limit + 1, 2]))
|> select([customer], %{...})
```

Join-through-customer ownership proof from [`accrue_admin/lib/accrue_admin/queries/subscriptions.ex:23`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex#L23) and [`accrue_admin/lib/accrue_admin/queries/invoices.ex:22`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/invoices.ex#L22):

```elixir
Subscription
|> join(:inner, [subscription], customer in Customer,
  on: customer.id == subscription.customer_id
)
|> filter_query(filter)
```

Webhook detail seam from [`accrue_admin/lib/accrue_admin/queries/webhooks.ex:75`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/webhooks.ex#L75):

```elixir
def detail(id) when is_binary(id) do
  Repo.get(WebhookEvent, id)
end
```

Phase 20 should change `detail/1`-style entry points into owner-aware loaders that prove ownership through linked local billing rows or event causality before returning the row.

### Admin detail/replay LiveViews

#### `accrue_admin/lib/accrue_admin/live/customer_live.ex` (component, request-response)

**Primary analog:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`

Add org-scope denial before any row assignment. The current mount at [`accrue_admin/lib/accrue_admin/live/customer_live.ex:25`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex#L25) is global:

```elixir
case Repo.get(Customer, customer_id) do
  nil ->
    {:ok, redirect(socket, to: admin_path(admin, "/customers"))}

  customer ->
    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:customer, customer)
```

Keep the Owner KPI and Phase 19 tax-risk summary intact from [`accrue_admin/lib/accrue_admin/live/customer_live.ex:79`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex#L79) and [`accrue_admin/lib/accrue_admin/live/customer_live.ex:250`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex#L250).

#### `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (component, request-response)

**Primary analog:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex`

Subscription detail should keep its staged-action pattern, but gate the initial loader and action execution on owner scope. Reuse:

- load/preload at [`accrue_admin/lib/accrue_admin/live/subscription_live.ex:277`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex#L277)
- staged confirm UI at [`accrue_admin/lib/accrue_admin/live/subscription_live.ex:210`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex#L210)
- admin audit recording at [`accrue_admin/lib/accrue_admin/live/subscription_live.ex:481`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex#L481)

#### `accrue_admin/lib/accrue_admin/live/webhook_live.ex` (component, event-driven)

**Primary analog:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`

This is the single-row replay boundary. Preserve the replay/audit flow from [`accrue_admin/lib/accrue_admin/live/webhook_live.ex:34`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex#L34):

```elixir
def handle_event("replay", _params, socket) do
  webhook = socket.assigns.webhook

  case DLQ.requeue(webhook.id) do
    {:ok, replayed} ->
      socket =
        socket
        |> record_single_replay(replayed)
        |> assign_webhook(Repo.get(WebhookEvent, replayed.id))
        |> push_flash(:info, "Webhook replay requested.")
```

Phase 20 should add owner verification before `assign_webhook/2` and block replay on ambiguous ownership.

#### `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` (component, event-driven)

**Primary analog:** `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`

Keep bulk replay as a two-step confirm flow and scope counts to the current owner. Reuse the pattern at [`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:38`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L38) and [`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:258`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L258).

#### `accrue_admin/lib/accrue_admin/live/events_live.ex` (component, event-driven)

**Primary analogs:** `accrue_admin/lib/accrue_admin/live/events_live.ex`, `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`

Events are already filtered by params but not by owner. Use the current summary/filter page structure from [`accrue_admin/lib/accrue_admin/live/events_live.ex:14`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/events_live.ex#L14) and add owner-aware filters the same way webhooks do with `params` + summary refresh.

### Admin tests

#### `accrue_admin/test/accrue_admin/live/customer_live_test.exs`
#### `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`
#### `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`

**Primary analogs:** same files

Phase 20 should extend these files instead of creating a parallel admin test suite. Reuse:

- auth adapter test seam from [`accrue_admin/test/accrue_admin/live/customer_live_test.exs:11`](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/customer_live_test.exs#L11)
- row seeding through local projections from [`accrue_admin/test/accrue_admin/live/customer_live_test.exs:36`](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/customer_live_test.exs#L36)
- step-up/audit assertions from [`accrue_admin/test/accrue_admin/live/subscription_live_test.exs:95`](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/subscription_live_test.exs#L95)
- no-sensitive-payload UI assertions from [`accrue_admin/test/accrue_admin/live/invoice_live_test.exs:119`](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/invoice_live_test.exs#L119)

For ORG-03, add negative cases that assert redirect or denial flash before any row content renders.

## Shared Patterns

### Billable ownership contract

**Sources:** [`accrue/lib/accrue/billable.ex:61`](/Users/jon/projects/accrue/accrue/lib/accrue/billable.ex#L61), [`accrue/lib/accrue/billing.ex:530`](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex#L530), [`accrue/lib/accrue/billing/customer.ex:47`](/Users/jon/projects/accrue/accrue/lib/accrue/billing/customer.ex#L47)
**Apply to:** `organization.ex`, host facade tests, admin owner filters

```elixir
customer_attrs = %{
  owner_type: billable_type,
  owner_id: owner_id,
  processor: processor_name,
  processor_id: Map.get(processor_result, :id),
  name: Map.get(processor_result, :name),
  email: Map.get(processor_result, :email)
}
```

Do not redesign this contract for Sigra. Organization billing should ride the same `owner_type` / `owner_id` row shape.

### Server-derived active scope

**Sources:** [`examples/accrue_host/lib/accrue_host/accounts/scope.ex:21`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/accounts/scope.ex#L21), [`examples/accrue_host/lib/accrue_host_web/user_auth.ex:67`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/user_auth.ex#L67), [`examples/accrue_host/lib/accrue_host_web/user_auth.ex:248`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/user_auth.ex#L248)
**Apply to:** host auth, host billing LiveView, admin session scope

Keep the active organization in `current_scope` and derive it in plugs/on_mount. Never trust a form, query param, or LiveView event payload for org identity.

### Host facade boundary

**Sources:** [`examples/accrue_host/lib/accrue_host/billing.ex:17`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex#L17), [`examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:297`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex#L297)
**Apply to:** host LiveViews and future org actions

Keep UI code off direct Accrue table queries. Resolve org scope in the facade, call public `Accrue.Billing` APIs, reload state.

### Admin session/auth threading

**Sources:** [`accrue_admin/lib/accrue_admin/router.ex:86`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex#L86), [`accrue_admin/lib/accrue_admin/auth_hook.ex:11`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/auth_hook.ex#L11)
**Apply to:** all admin LiveViews

Thread any host session keys through `accrue_admin/2`, then assign shared admin scope in `AuthHook`. Do not re-parse host session state in each LiveView.

### Admin query gating before render

**Sources:** [`accrue_admin/lib/accrue_admin/queries/subscriptions.ex:23`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/queries/subscriptions.ex#L23), [`accrue_admin/lib/accrue_admin/live/customer_live.ex:25`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex#L25), [`accrue_admin/lib/accrue_admin/live/webhook_live.ex:17`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex#L17)
**Apply to:** customer/subscription/invoice/webhook/event list and detail paths

Owner scope belongs in loaders/query modules, before `assign/3` and before rendering any detail content.

### Replay and audit pattern

**Sources:** [`accrue_admin/lib/accrue_admin/live/webhook_live.ex:214`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhook_live.ex#L214), [`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:258`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L258), [`examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:127`](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L127)
**Apply to:** single replay, bulk replay, owner-denial replay tests

Record an admin audit/event row whenever replay is allowed. When ownership is ambiguous or out of scope, deny before replay and do not record a success audit row.

### Phase 19 tax-state reuse

**Sources:** [`examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:180`](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex#L180), [`accrue_admin/lib/accrue_admin/live/customer_live.ex:102`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/customer_live.ex#L102), [`accrue_admin/lib/accrue_admin/live/subscription_live.ex:139`](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex#L139)
**Apply to:** org billing host page and admin owner detail pages

Do not create a new UI system for org billing. Reuse the existing tax-risk/state panels, card layout, staged actions, and flash patterns from Phase 19.

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex` | model | CRUD | No existing membership/join schema in the host example; use `user_token.ex` only for schema/belongs_to shape. |
| `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` | test | request-response | Existing tests cover admin mount denial and replay happy path separately, but not org-crossing denial end to end. |
| Sigra-backed host adapter glue inside `examples/accrue_host` | middleware | request-response | Repo only contains the optional core adapter scaffold in `Accrue.Integrations.Sigra`; no host-side organization API analog exists yet. |

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue_admin/lib/accrue_admin`, `accrue_admin/test`, `examples/accrue_host/lib`, `examples/accrue_host/test`, `examples/accrue_host/priv/repo/migrations`

**Primary files scanned:** 30

- `CLAUDE.md`
- `.planning/phases/20-organization-billing-with-sigra/20-RESEARCH.md`
- `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md`
- `.planning/phases/20-organization-billing-with-sigra/20-VALIDATION.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `accrue/lib/accrue/billable.ex`
- `accrue/lib/accrue/billing.ex`
- `accrue/lib/accrue/billing/customer.ex`
- `accrue/lib/accrue/integrations/sigra.ex`
- `accrue/test/accrue/billable_test.exs`
- `accrue/guides/sigra_integration.md`
- `accrue_admin/lib/accrue_admin/router.ex`
- `accrue_admin/lib/accrue_admin/auth_hook.ex`
- `accrue_admin/lib/accrue_admin/queries/customers.ex`
- `accrue_admin/lib/accrue_admin/queries/subscriptions.ex`
- `accrue_admin/lib/accrue_admin/queries/invoices.ex`
- `accrue_admin/lib/accrue_admin/queries/webhooks.ex`
- `accrue_admin/lib/accrue_admin/live/customer_live.ex`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex`
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`
- `examples/accrue_host/lib/accrue_host/accounts.ex`
- `examples/accrue_host/lib/accrue_host/accounts/user.ex`
- `examples/accrue_host/lib/accrue_host/accounts/scope.ex`
- `examples/accrue_host/lib/accrue_host/accounts/user_token.ex`
- `examples/accrue_host/lib/accrue_host/billing.ex`
- `examples/accrue_host/lib/accrue_host_web/user_auth.ex`
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`

