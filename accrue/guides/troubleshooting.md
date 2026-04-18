# Troubleshooting

Use this matrix when installer checks, boot-time setup validation, webhook
ingest, or the mounted admin UI reports an `Accrue.ConfigError` with a stable
diagnostic code.

| Code | What happened | Why Accrue cares | Fix | How to verify |
| --- | --- | --- | --- | --- |
| `ACCRUE-DX-REPO-CONFIG` | The host app did not expose a usable Repo to Accrue. | Billing state, webhook ingest, and replay persistence all depend on the host Repo. | Set `config :accrue, repo: MyApp.Repo` and make sure the Repo starts in the supervision tree. | Run `mix accrue.install --check` and `mix ecto.migrate`. |
| `ACCRUE-DX-MIGRATIONS-PENDING` | Accrue tables are missing or behind the installed package version. | The billing facade and webhook pipeline expect the schema to exist before the app handles requests. | Run the generated migrations in the host app. | Run `mix ecto.migrate`. |
| `ACCRUE-DX-OBAN-NOT-CONFIGURED` | `Oban` config is missing. | Webhook follow-up work, replay, and async jobs cannot be scheduled without Oban config. | Add `config :my_app, Oban, ...` and keep it environment-specific. | Boot the app and run `mix accrue.install --check`. |
| `ACCRUE-DX-OBAN-NOT-SUPERVISED` | `Oban` is configured but not started with the app. | Signed webhook ingest can persist the event, but dispatch and replay will stall. | Add `{Oban, Application.fetch_env!(:my_app, Oban)}` to your supervision tree. | Start the app, then run `mix test test/accrue_host_web/webhook_ingest_test.exs`. |
| `ACCRUE-DX-WEBHOOK-SECRET-MISSING` | The webhook signing secret is absent from runtime config. | Accrue refuses to treat unsigned or unverifiable webhook traffic as trusted billing input. | Set `config :accrue, :webhook_signing_secrets, %{stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")}` in `config/runtime.exs`. | Restart the app and rerun `mix accrue.install --check`. |
| `ACCRUE-DX-WEBHOOK-ROUTE-MISSING` | The `/webhooks/stripe` route was not mounted. | Accrue cannot receive signed processor events if the route does not exist. | Import `Accrue.Router` and add `accrue_webhook "/stripe", :stripe` inside a webhook scope. | Run `mix phx.routes | rg '/webhooks/stripe'`. |
| `ACCRUE-DX-WEBHOOK-RAW-BODY` | The webhook route is mounted without the raw-body reader. | Signature verification depends on the exact request body bytes before parsing. | Add a dedicated pipeline using `body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}`. | Run `mix test test/accrue_host_web/webhook_ingest_test.exs`. |
| `ACCRUE-DX-WEBHOOK-PIPELINE` | The webhook route is behind the wrong Phoenix pipeline. | Browser, CSRF, or auth plugs can alter the request path before webhook verification runs. | Mount `/webhooks/stripe` in a dedicated scope that only uses the raw-body parser pipeline. | Post the signed proof path and rerun `mix test test/accrue_host_web/webhook_ingest_test.exs`. |
| `ACCRUE-DX-AUTH-ADAPTER` | The admin mount cannot resolve a valid host auth boundary. | `/billing` must stay behind host-controlled admin authorization. | Configure `Accrue.Auth` for your app and forward the session keys your auth layer uses. | Run `mix test test/accrue_host_web/admin_mount_test.exs`. |
| `ACCRUE-DX-ADMIN-MOUNT-MISSING` | `accrue_admin "/billing"` is not mounted in the router. | The operator UI and replay tools are unavailable until the admin router macro is mounted. | Import `AccrueAdmin.Router` and mount `accrue_admin "/billing"` inside the authenticated browser scope. | Run `mix test test/accrue_host_web/admin_mount_test.exs`. |

## `ACCRUE-DX-REPO-CONFIG` {#accrue-dx-repo-config}

### What happened

Accrue could not resolve the host Repo configuration it needs for billing state.

### Why Accrue cares

Every supported first-hour path persists state through the host Repo.

### Fix

Set `config :accrue, repo: MyApp.Repo` and keep `MyApp.Repo` started with the
rest of the application.

### How to verify

```bash
mix accrue.install --check
mix ecto.migrate
```

## `ACCRUE-DX-MIGRATIONS-PENDING` {#accrue-dx-migrations-pending}

### What happened

The host database has not applied the generated Accrue migrations yet.

### Why Accrue cares

The generated `MyApp.Billing` facade and the webhook path both depend on the
installed tables being present.

### Fix

Apply the pending migrations from the host app.

### How to verify

```bash
mix ecto.migrate
```

## `ACCRUE-DX-OBAN-NOT-CONFIGURED` {#accrue-dx-oban-not-configured}

### What happened

The app has no usable `Oban` configuration.

### Why Accrue cares

Webhook replay and follow-up jobs need Oban queues to exist before they can run.

### Fix

Add your host app's `Oban` config and keep it checked into the same app that
owns the router and billing facade.

### How to verify

```bash
mix accrue.install --check
```

## `ACCRUE-DX-WEBHOOK-SECRET-MISSING` {#accrue-dx-webhook-secret-missing}

### What happened

Accrue could not find a signing secret for the Stripe webhook endpoint.

### Why Accrue cares

Webhook signature verification only works when the runtime config exposes the
secrets map keyed by processor.

### Fix

Set the runtime config to the exact key Accrue reads:

```elixir
config :accrue, :webhook_signing_secrets, %{
  stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")
}
```

### How to verify

```bash
mix accrue.install --check
```

## `ACCRUE-DX-WEBHOOK-RAW-BODY` {#accrue-dx-webhook-raw-body}

### What happened

The mounted webhook route cannot access the original request body bytes.

### Why Accrue cares

Webhook signature verification fails if the body is parsed before Accrue reads
it.

### Fix

Create a dedicated raw-body parser pipeline and mount `/webhooks/stripe` there.

### How to verify

```bash
mix test test/accrue_host_web/webhook_ingest_test.exs
```

## `ACCRUE-DX-OBAN-NOT-SUPERVISED` {#accrue-dx-oban-not-supervised}

### What happened

The host app has valid `Oban` config, but the supervision tree never starts an
Oban supervisor.

### Why Accrue cares

Accrue persists signed webhook events before handing follow-up work to Oban. If
Oban is not supervised, `accrue_webhook "/stripe", :stripe` can accept the
request but dispatch, retry, and replay work will not run.

### Fix

Start Oban from the host application supervisor with the same config you keep in
`config/runtime.exs` or the environment-specific config file:

```elixir
children = [
  MyApp.Repo,
  {Oban, Application.fetch_env!(:my_app, Oban)}
]
```

Keep the queue config host-owned and make sure the app boots the supervisor in
every environment where webhooks or async mailers should run.

### How to verify

```bash
mix accrue.install --check
mix test test/accrue_host_web/webhook_ingest_test.exs
```

## `ACCRUE-DX-WEBHOOK-ROUTE-MISSING` {#accrue-dx-webhook-route-missing}

### What happened

The host router does not expose the Stripe webhook endpoint Accrue expects.

### Why Accrue cares

Webhook signing secrets and handlers do nothing if Phoenix never mounts the
route. Signed processor events will never reach the host boundary without the
`accrue_webhook "/stripe", :stripe` route.

### Fix

Import `Accrue.Router` in the host router and mount the webhook macro inside a
dedicated webhook scope:

```elixir
scope "/webhooks", MyAppWeb do
  pipe_through [:accrue_webhooks]

  accrue_webhook "/stripe", :stripe
end
```

Keep the scope narrow and separate from the authenticated browser routes.

### How to verify

```bash
mix phx.routes | rg '/webhooks/stripe'
mix accrue.install --check
```

## `ACCRUE-DX-WEBHOOK-PIPELINE` {#accrue-dx-webhook-pipeline}

### What happened

The Stripe webhook route is mounted behind the wrong Phoenix pipeline.

### Why Accrue cares

Webhook requests must arrive on a raw-body-aware path. Running the route through
the `browser` pipeline, CSRF protection, or an auth pipeline can reject the
request or mutate it before signature verification runs.

### Fix

Move the webhook route into a dedicated pipeline that only handles the raw body
and JSON parsing needed for signed webhook requests:

```elixir
pipeline :accrue_webhooks do
  plug :accepts, ["json"]

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Phoenix.json_library(),
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
end

scope "/webhooks", MyAppWeb do
  pipe_through [:accrue_webhooks]

  accrue_webhook "/stripe", :stripe
end
```

Do not reuse the `browser` pipeline here. Keep CSRF and session auth on the
browser side, and keep the webhook path on its own auth-free pipeline.

### How to verify

```bash
mix accrue.install --check
mix test test/accrue_host_web/webhook_ingest_test.exs
```

## `ACCRUE-DX-AUTH-ADAPTER` {#accrue-dx-auth-adapter}

### What happened

Accrue could not resolve a real host auth adapter for the mounted admin UI.

### Why Accrue cares

The admin UI is intentionally host-owned at the auth boundary. `/billing` must
use the same session and authorization rules as the rest of the host app, not a
package-owned fallback.

### Fix

Point Accrue at the host adapter and keep the admin mount inside the
authenticated browser scope:

```elixir
config :accrue, :auth_adapter, MyApp.Auth
```

Then forward the session keys your auth layer uses when mounting the admin UI.
If the route is already mounted, confirm it sits behind your host auth pipeline
instead of a public scope.

### How to verify

```bash
mix accrue.install --check
mix test test/accrue_host_web/admin_mount_test.exs
```

## `ACCRUE-DX-ADMIN-MOUNT-MISSING` {#accrue-dx-admin-mount-missing}

### What happened

The host router never mounted the Accrue admin routes.

### Why Accrue cares

Without the `accrue_admin "/billing"` mount, first users cannot inspect billing
state, replay webhook failures, or confirm the protected admin UI is wired the
same way as the host app.

### Fix

Import `AccrueAdmin.Router` and mount the admin UI inside the authenticated
browser scope:

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  accrue_admin "/billing"
end
```

Keep the mount on the host-controlled browser side and do not expose it on the
webhook or public API scopes.

### How to verify

```bash
mix accrue.install --check
mix test test/accrue_host_web/admin_mount_test.exs
```

## Stripe Tax rollout and invalid-location recovery

Stripe Tax rollout needs explicit migration work for existing recurring objects.
Enabling Stripe Tax or automatic collection does not retroactively update
existing subscriptions, invoices, payment links, or previously created customer
addresses. Update those recurring objects deliberately before you expect tax to
calculate correctly.

For existing Checkout customers, collected Checkout addresses do not overwrite
the attached Stripe Customer unless the Checkout Session sets the literal
`customer_update[address]=auto` or `customer_update[shipping]=auto` flags.
Without those flags, Checkout can collect a fresh address for the session while
the stored Stripe Customer keeps the old or incomplete location.

### Stable error: `customer_tax_location_invalid`

When Accrue rejects a tax-location repair with
`customer_tax_location_invalid`, treat it as the supported public recovery
signal. Do not copy raw Stripe errors, customer addresses, or dashboard payloads
into logs or support notes.

Recommended recovery order:

1. Update the customer tax location through Accrue's public billing path.
2. Retry invoice finalization if the failing object is a draft invoice awaiting
   a valid location.
3. If you cannot collect a valid location yet, explicitly disable automatic tax
   for the affected recurring subscription or invoice instead of leaving the
   rollout half-enabled.

Use placeholder values only in notes and tickets. The goal is to confirm the
stable code and the recurring object that needs repair, not to copy tax address
PII around the team.

### Recurring invalid-location states

Stripe can surface two related recurring states after rollout:

- `requires_location_inputs`: recurring automatic tax was disabled because the
  customer no longer has a valid tax location.
- `finalization_requires_location_inputs`: invoice finalization needs a valid
  customer location before tax can be applied.

Treat these as local repair signals, not as reasons to inspect raw processor
payloads. The supported operator flow stays the same:

1. Repair the customer tax location through Accrue.
2. Retry finalization when the invoice is waiting on location input.
3. Explicitly disable automatic tax on the affected recurring object if the
   customer will remain without a taxable address for now.

For live provider-parity checks that exercise a valid and invalid customer
location in Stripe test mode, follow
[`guides/testing-live-stripe.md`](https://github.com/szTheory/accrue/blob/main/guides/testing-live-stripe.md). Keep
real customer data, copied dashboard payloads, and raw addresses out of notes,
screenshots, and shared logs.
