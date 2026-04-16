# Phase 10: Host App Dogfood Harness - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 16
**Analogs found:** 14 / 16

This map only enumerates files that are either explicit in `10-CONTEXT.md` / `10-RESEARCH.md` or are the smallest implied set needed to satisfy the locked integration proof. Exact user-facing page modules remain at planner discretion under D-08/D-09, so they are intentionally not frozen here.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/mix.exs` | config | request-response | `accrue_admin/mix.exs` | role-match |
| `examples/accrue_host/config/runtime.exs` | config | request-response | `accrue/priv/accrue/templates/install/runtime_config.exs.eex` | exact |
| `examples/accrue_host/config/test.exs` | config | request-response | `accrue_admin/config/test.exs` | role-match |
| `examples/accrue_host/lib/accrue_host/accounts/user.ex` | model | CRUD | none in repo; use `phx.gen.auth` output from research | no-analog |
| `examples/accrue_host/lib/accrue_host/billing.ex` | service | request-response | `accrue/priv/accrue/templates/install/billing.ex.eex` | exact |
| `examples/accrue_host/lib/accrue_host/billing_handler.ex` | service | event-driven | `accrue/priv/accrue/templates/install/billing_handler.ex.eex` | exact |
| `examples/accrue_host/lib/accrue_host_web/router.ex` | route | request-response | `accrue/lib/accrue/install/patches.ex` | exact |
| `examples/accrue_host/lib/accrue_host_web/user_auth.ex` | middleware | request-response | none in repo; use `phx.gen.auth` output from research | no-analog |
| `examples/accrue_host/priv/repo/migrations/*.exs` | migration | CRUD | `accrue/lib/accrue/install/templates.ex` + `accrue/priv/repo/migrations/*.exs` | exact |
| `examples/accrue_host/test/support/accrue_case.ex` | test | request-response | `accrue/lib/accrue/install/patches.ex` | exact |
| `examples/accrue_host/test/accrue_host_web/billing_flow_test.exs` | test | request-response | `accrue/lib/accrue/test/factory.ex` | partial |
| `examples/accrue_host/test/accrue_host_web/webhook_flow_test.exs` | test | request-response | `accrue/test/accrue/webhook/plug_test.exs` | exact |
| `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` | role-match |
| `examples/accrue_host/test/support/e2e_server.ex` | utility | batch | `accrue_admin/test/support/e2e_server.ex` | exact |
| `examples/accrue_host/playwright.config.js` | config | request-response | `accrue_admin/playwright.config.js` | exact |
| `examples/accrue_host/e2e/phase10-uat.spec.js` | test | request-response | `accrue_admin/e2e/phase7-uat.spec.js` | role-match |

## Pattern Assignments

### `examples/accrue_host/mix.exs` (config, request-response)

**Analog:** `accrue_admin/mix.exs`

**Project/deps pattern** (lines 7-20):
```elixir
def project do
  [
    app: :accrue_admin,
    version: @version,
    elixir: "~> 1.17",
    start_permanent: Mix.env() == :prod,
    elixirc_paths: elixirc_paths(Mix.env()),
    deps: deps()
  ]
end
```

**Path-dependency toggle pattern** (lines 68-74):
```elixir
defp accrue_dep do
  if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
    {:accrue, "~> #{@version}"}
  else
    {:accrue, path: "../accrue"}
  end
end
```

**Host-fixture minimal project shape** from `accrue/test/support/install_fixture.ex` (lines 27-48):
```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: deps()
    ]
  end
end
```

Use `accrue_admin/mix.exs` for repo-level conventions and use the install fixture as the simplest host-app dependency shape. For Phase 10, the host app should use local `../../accrue` and `../../accrue_admin` path deps by default.

---

### `examples/accrue_host/config/runtime.exs` (config, request-response)

**Analog:** `accrue/priv/accrue/templates/install/runtime_config.exs.eex`

**Runtime secret/config pattern** (lines 1-7):
```elixir
import Config

config :accrue, :processor, Accrue.Processor.Stripe
config :accrue, :stripe_secret_key, System.fetch_env!("STRIPE_SECRET_KEY")
config :accrue, :webhook_signing_secrets, %{
  stripe: System.get_env("STRIPE_WEBHOOK_SECRET")
}
```

For the dogfood harness, keep this installer-owned shape but swap the processor to `Accrue.Processor.Fake` for local proof, while still keeping secrets/env access explicit and host-owned.

---

### `examples/accrue_host/config/test.exs` (config, request-response)

**Analog:** `accrue_admin/config/test.exs`

**Repo + endpoint test config pattern** (lines 1-26):
```elixir
import Config

config :accrue_admin, :env, :test

config :accrue_admin, AccrueAdmin.TestRepo,
  database: "accrue_admin_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost")

config :accrue,
  env: :test,
  repo: AccrueAdmin.TestRepo
```

Copy the structure: explicit sandbox repo, env-driven PG defaults, endpoint config, and explicit `:accrue` test env wiring.

---

### `examples/accrue_host/lib/accrue_host/accounts/user.ex` (model, CRUD)

**Analog:** none in repo

Use Phoenix `mix phx.gen.auth Accounts User users --live --binary-id` output from research as the primary pattern source, then add `use Accrue.Billable` on the generated host-owned schema. There is no live repo analog for a Phoenix-auth-generated user schema yet.

Apply these repo constraints around the generator output:

- host owns the billable schema boundary (`10-CONTEXT.md` D-05)
- keep the schema in the host app, not in `accrue`
- do not bypass generated auth/session defaults unless the planner has a concrete reason

---

### `examples/accrue_host/lib/accrue_host/billing.ex` (service, request-response)

**Analog:** `accrue/priv/accrue/templates/install/billing.ex.eex`

**Imports/service wrapper pattern** (lines 1-8):
```elixir
defmodule <%= @billing_context %> do
  @moduledoc """
  Host-owned billing facade generated by `mix accrue.install`.
  """

  alias Accrue.Billing
```

**Core facade pattern** (lines 10-28):
```elixir
def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end

def swap_plan(subscription, price_id, opts) do
  Billing.swap_plan(subscription, price_id, opts)
end

def cancel(subscription, opts \\ []) do
  Billing.cancel(subscription, opts)
end

def customer_for(billable) do
  Billing.customer(billable)
end
```

This file is the canonical host-owned policy seam. Keep it thin. The dogfood app should call this facade from controllers/LiveViews/tests instead of reaching straight into private Accrue internals.

---

### `examples/accrue_host/lib/accrue_host/billing_handler.ex` (service, event-driven)

**Analog:** `accrue/priv/accrue/templates/install/billing_handler.ex.eex`

**Webhook handler pattern** (lines 1-21):
```elixir
defmodule <%= @billing_handler %> do
  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    _ = type
    _ = event
    _ = ctx

    :ok
  end
end
```

Keep the handler host-owned and side-effect focused. Do not move ingest, signature verification, or projection logic into this file.

---

### `examples/accrue_host/lib/accrue_host_web/router.ex` (route, request-response)

**Analog:** `accrue/lib/accrue/install/patches.ex`

**Webhook route snippet** (lines 75-94):
```elixir
import Accrue.Router

pipeline :accrue_webhook_raw_body do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 1_000_000
end

scope "#{scope_path}" do
  pipe_through :accrue_webhook_raw_body
  accrue_webhook "#{endpoint_path}", :stripe
end
```

**Admin mount snippet** (lines 97-104):
```elixir
import AccrueAdmin.Router

# Protect this mount with AccrueAdmin.AuthHook via accrue_admin/2.
# Hosts with custom routers may also pipe through Accrue.Auth.require_admin_plug().
accrue_admin "#{opts.admin_mount}"
```

**Import/idempotent patch pattern** (lines 169-206):
```elixir
patched =
  content
  |> ensure_import("Accrue.Router")
  |> insert_before_final_end(snippet)
```

Also keep the lower-level macro contract from `accrue/lib/accrue/router.ex` lines 37-48:
```elixir
defmacro accrue_webhook(path, processor) do
  quote do
    forward(unquote(path), Accrue.Webhook.Plug, processor: unquote(processor))
  end
end
```

The key rule is route-scoped raw-body parsing. Do not add a global custom body reader.

---

### `examples/accrue_host/lib/accrue_host_web/user_auth.ex` (middleware, request-response)

**Analog:** none in repo

Use the `phx.gen.auth` generator output from research as the primary source. There is no repo-local `UserAuth` module to copy.

Constrain the generated file with these existing repo patterns:

- mounted admin routes should only receive explicit session keys, not the whole session map
- `/billing` should fail closed by default
- the host auth boundary stays host-owned; `accrue_admin` consumes it through `session_keys`

The nearest supporting analog is `accrue_admin/lib/accrue_admin/router.ex` lines 86-105, which shows exactly how mounted admin session data is threaded:
```elixir
host_session =
  Map.new(session_keys, fn key ->
    string_key = to_string(key)
    {string_key, get_session(conn, key)}
  end)
```

---

### `examples/accrue_host/priv/repo/migrations/*.exs` (migration, CRUD)

**Analog:** `accrue/lib/accrue/install/templates.ex` plus `accrue/priv/repo/migrations/*.exs`

**Installer copy pattern** from `accrue/lib/accrue/install/templates.ex` (lines 14-24, 105-119):
```elixir
[
  {context_path(project.root, opts.billing_context), render("billing.ex.eex", assigns)},
  {context_path(project.root, "#{opts.billing_context}Handler"),
   render("billing_handler.ex.eex", assigns)},
  {project.runtime_config_path, render("runtime_config.exs.eex", assigns)}
] ++ migration_templates(project, assigns)
```

```elixir
copied =
  @migration_root
  |> Path.join("*.exs")
  |> Path.wildcard()
  |> Enum.map(fn path ->
    {Path.join(project.migrations_path, Path.basename(path)), File.read!(path)}
  end)
```

**Host-only revoke migration** from `accrue/priv/accrue/templates/install/revoke_accrue_events_writes.exs.eex` (lines 1-12):
```elixir
defmodule <%= @app_module %>.Repo.Migrations.RevokeAccrueEventsWrites do
  use Ecto.Migration

  def up do
    execute "REVOKE UPDATE, DELETE, TRUNCATE ON accrue_events FROM #{@app_role}"
  end
end
```

**Schema migration style** from `accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs` (lines 15-68):
```elixir
def up do
  create table(:accrue_events, primary_key: false) do
    add :id, :bigserial, primary_key: true
    add :type, :string, null: false
    ...
  end

  execute """
          CREATE TRIGGER accrue_events_immutable_trigger
            BEFORE UPDATE OR DELETE ON accrue_events
            FOR EACH ROW EXECUTE FUNCTION accrue_events_immutable();
          """
end
```

Planner note: the host app should copy installer-managed Accrue migrations rather than inventing local variants.

---

### `examples/accrue_host/test/support/accrue_case.ex` (test, request-response)

**Analog:** `accrue/lib/accrue/install/patches.ex`

**Generated test support pattern** (lines 121-137):
```elixir
defmodule AccrueCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Accrue.Test
    end
  end
end

# Add to config/test.exs:
#   config :accrue, :processor, Accrue.Processor.Fake
```

**Underlying helper API** from `accrue/lib/accrue/test.ex` (lines 9-16, 24-45):
```elixir
defmacro __using__(_opts) do
  quote do
    import Accrue.Test
    import Accrue.Test.MailerAssertions
    import Accrue.Test.PdfAssertions
    import Accrue.Test.EventAssertions
  end
end

def setup_fake_processor(context \\ []) do
  Application.put_env(:accrue, :processor, Accrue.Processor.Fake)
  setup_return(context, processor: Accrue.Processor.Fake)
end
```

Keep this file minimal; it should be a host-facing adapter over `Accrue.Test`, not a second custom test framework.

---

### `examples/accrue_host/test/accrue_host_web/billing_flow_test.exs` (test, request-response)

**Analog:** `accrue/lib/accrue/test/factory.ex`

**Fake-backed customer/subscription setup pattern** (lines 55-77, 92-112):
```elixir
def customer(attrs \\ %{}) do
  {:ok, stripe_customer} =
    Fake.create_customer(%{email: email, name: Map.get(attrs, :name)})

  {:ok, customer} =
    %Customer{}
    |> Customer.changeset(%{owner_type: owner_type, owner_id: owner_id, processor: "fake"})
    |> Repo.insert()
end
```

```elixir
def subscription(attrs \\ %{}) do
  %{customer: c} = customer(attrs)
  {:ok, sub} = Billing.subscribe(c, price, trial_end: trial_end)
  ...
end
```

**Cancel path pattern** (lines 140-145):
```elixir
%{customer: c, subscription: sub} = active_subscription(attrs)
{:ok, canceled} = Billing.cancel(sub)
canceled = Repo.preload(canceled, :subscription_items)
```

Use the factories only for setup/bootstrap. The proof path itself should still click/submit through the host app and call `AccrueHost.Billing`, per D-12.

---

### `examples/accrue_host/test/accrue_host_web/webhook_flow_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/webhook/plug_test.exs`

**Test router + scoped raw-body pattern** (lines 19-38):
```elixir
defmodule TestWebhookRouter do
  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
  )

  forward("/webhooks/stripe", to: Accrue.Webhook.Plug, init_opts: [processor: :stripe])
end
```

**Signed POST happy-path pattern** (lines 98-109):
```elixir
sig = LatticeStripe.Webhook.generate_test_signature(@valid_event_payload, @test_secret)

conn =
  Plug.Test.conn(:post, "/webhooks/stripe", @valid_event_payload)
  |> Plug.Conn.put_req_header("content-type", "application/json")
  |> Plug.Conn.put_req_header("stripe-signature", sig)
  |> TestWebhookRouter.call(TestWebhookRouter.init([]))

assert conn.status == 200
```

**Verification pattern for persistence/scoping** (lines 149-178):
```elixir
assert conn.status == 200
events = Accrue.TestRepo.all(Accrue.Webhook.WebhookEvent)
assert length(events) == 1
...
assert %{"raw_body_present" => false} = Jason.decode!(conn.resp_body)
```

This is the strongest analog for HOST-04/HOST-07 style verification: signed request through the real route, persistence assertions, and negative scoping assertions.

---

### `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` (test, request-response)

**Analog:** `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs`

**Session-auth test pattern** (lines 59-84):
```elixir
conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

{:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")

html = render_click(element(view, "[data-role='replay-single']"))
assert html =~ "Webhook replay requested."

updated = TestRepo.get!(WebhookEvent, webhook.id)
assert updated.status == :received
```

**Audit assertion pattern** (lines 73-83):
```elixir
audit_event =
  TestRepo.one!(
    from(event in Event,
      where:
        event.type == "admin.webhook.replay.completed" and
          event.subject_id == ^webhook.id
    )
  )

assert audit_event.actor_type == "admin"
assert audit_event.caused_by_webhook_event_id == webhook.id
```

**Mounted-router session threading pattern** from `accrue_admin/test/accrue_admin/router_test.exs` (lines 28-55):
```elixir
session =
  conn
  |> AccrueAdmin.CSPPlug.call([])
  |> AccrueAdmin.BrandPlug.call([])
  |> AccrueAdmin.Router.__session__([:admin_token], "/billing")

assert session["admin_token"] == "token-123"
refute Map.has_key?(session, "ignored")
```

Use this file to prove both auth protection and audited admin action, not just successful page render.

---

### `examples/accrue_host/test/support/e2e_server.ex` (utility, batch)

**Analog:** `accrue_admin/test/support/e2e_server.ex`

**Runtime boot pattern** (lines 6-20):
```elixir
def start! do
  configure_runtime!()
  migrate!()
  start_repo!()
  start_oban!()
  start_fake_processor!()
  start_endpoint!()

  Process.sleep(:infinity)
end
```

**Explicit local runtime wiring pattern** (lines 23-47, 73-99):
```elixir
Application.put_env(:accrue, :env, :test)
Application.put_env(:accrue, :repo, TestRepo)
Application.put_env(:accrue, :processor, Accrue.Processor.Fake)
...
case Oban.start_link(
       repo: TestRepo,
       testing: :manual,
       queues: false,
       plugins: false,
       notifier: Oban.Notifiers.PG
     ) do
```

Use the same explicit boot order. The host app should not rely on hidden shell scripts for browser UAT startup.

---

### `examples/accrue_host/playwright.config.js` (config, request-response)

**Analog:** `accrue_admin/playwright.config.js`

**Playwright webServer pattern** (lines 7-35):
```javascript
module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  workers: 1,
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: {
    command: `MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=${port} mix accrue_admin.e2e.server`,
    url: `${baseURL}/__e2e__/health`,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  }
});
```

Reuse this structure directly if the planner chooses the Playwright branch under D-20.

---

### `examples/accrue_host/e2e/phase10-uat.spec.js` (test, request-response)

**Analog:** `accrue_admin/e2e/phase7-uat.spec.js`

**Reset/seed/login helper pattern** (lines 3-16):
```javascript
async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}
```

**Admin replay UAT pattern** (lines 62-85):
```javascript
const data = await seed(request, "operator-flows");

await login(page, `/billing/webhooks/${data.single_webhook_id}`);
await page.getByRole("button", { name: "Replay webhook" }).click();
await expect(page.getByText("Webhook replay requested.")).toBeVisible();

const countsResponse = await request.get("/__e2e__/counts");
const counts = await countsResponse.json();
expect(counts.admin_events).toBeGreaterThanOrEqual(1);
```

For Phase 10, adapt this from pure-admin UAT to host-app UAT: login through host auth, drive a user subscription flow first, then inspect/replay via `/billing`.

## Shared Patterns

### Installer-Owned Host Boundary
**Source:** `accrue/priv/accrue/templates/install/billing.ex.eex:1-29`, `accrue/priv/accrue/templates/install/billing_handler.ex.eex:1-22`

Apply to the host-owned billing facade and webhook handler:
```elixir
alias Accrue.Billing

def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end

use Accrue.Webhook.Handler
```

### Webhook Routing and Verification
**Source:** `accrue/lib/accrue/install/patches.ex:75-104`, `accrue/lib/accrue/webhook/plug.ex:35-70`, `accrue/lib/accrue/webhook/ingest.ex:50-83`

Apply to router config and webhook tests:
```elixir
pipeline :accrue_webhook_raw_body do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
end

conn
|> send_resp(400, Jason.encode!(%{error: "signature_verification_failed"}))
|> halt()
```

### Mounted Admin Session Threading
**Source:** `accrue_admin/lib/accrue_admin/router.ex:37-55`, `accrue_admin/lib/accrue_admin/router.ex:86-105`

Apply to the `/billing` mount:
```elixir
pipeline :accrue_admin_browser do
  plug(:fetch_session)
  plug(:protect_from_forgery)
  plug(AccrueAdmin.CSPPlug)
  plug(AccrueAdmin.BrandPlug)
end

session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]}
```

### Fake-Backed Host Verification
**Source:** `accrue/lib/accrue/test.ex:9-45`, `accrue/lib/accrue/test/factory.ex:55-145`, `accrue/lib/accrue/test/webhooks.ex:24-37`

Apply to host tests and seed helpers:
```elixir
use Accrue.Test

def setup_fake_processor(context \\ []) do
  Application.put_env(:accrue, :processor, Accrue.Processor.Fake)
  ...
end

{:ok, sub} = Billing.subscribe(c, price, trial_end: trial_end)
```

### Audited Admin Replay Proof
**Source:** `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs:59-123`

Apply to the admin verification path:
```elixir
html = render_click(element(view, "[data-role='replay-single']"))
assert html =~ "Webhook replay requested."

assert audit_event.actor_type == "admin"
assert audit_event.caused_by_webhook_event_id == webhook.id
```

### Local Browser UAT Orchestration
**Source:** `accrue_admin/test/support/e2e_server.ex:6-20`, `accrue_admin/playwright.config.js:7-35`, `accrue_admin/e2e/phase7-uat.spec.js:18-85`

Apply only if planner chooses Playwright now:
```javascript
webServer: {
  command: `MIX_ENV=test ... mix ...e2e.server`,
  url: `${baseURL}/__e2e__/health`,
  reuseExistingServer: !process.env.CI
}
```

## No Analog Found

Files with no close live-repo analog; planner should use RESEARCH.md's Phoenix generator guidance:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/accrue_host/lib/accrue_host/accounts/user.ex` | model | CRUD | Repo has no `phx.gen.auth`-generated host schema to copy; Phase 10 is the first host app. |
| `examples/accrue_host/lib/accrue_host_web/user_auth.ex` | middleware | request-response | Repo has no Phoenix host session/auth helper module yet; use `phx.gen.auth` output from research. |

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/test`, `accrue/priv`, `accrue_admin/lib`, `accrue_admin/test`, `accrue_admin/e2e`, repo root `CLAUDE.md`

**Files scanned:** 20+

**Pattern extraction date:** 2026-04-16
