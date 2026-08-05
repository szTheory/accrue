# Phase 221: Close gap: reference-host Apple notification ingress - Pattern Map

**Mapped:** 2026-08-05  
**Files analyzed:** 12  
**Analogs found:** 11 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/lib/accrue_host_web/router.ex` | route | request-response | same file: Stripe raw-body route | exact |
| `examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex` | middleware | request-response | `accrue/lib/accrue/entitlements/apple/notification_plug.ex` | data-flow match |
| `examples/accrue_host/config/runtime.exs` | config | transform | same file: Stripe runtime secret config | role-match |
| `examples/accrue_host/config/config.exs` | config | event-driven | same file: Oban queue/Cron config | exact |
| `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` | test | request-response | `test/accrue_host_web/webhook_ingest_test.exs` | exact |
| `examples/accrue_host/test/support/apple_notification_fake_verifier.ex` (or test-local equivalent) | utility | transform | `reference_scenario_conformance_test.exs` `FakeVerifier` | role-match |
| `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` | test | event-driven | same file: base Oban assertions | exact |
| `examples/accrue_host/test/install_boundary_test.exs` | test | batch | same file: source-contract assertions | exact |
| `scripts/ci/accrue_host_verify_test_bounded.sh` | config | batch | same file: bounded test list | exact |
| `examples/accrue_host/README.md` | config | batch | same file: host setup/proof narrative | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | config | batch | same file: proof-lane matrix | exact |
| `accrue/guides/operator-runbooks.md` | config | batch | same file: v1.59 bounded runbooks | role-match |

## Pattern Assignments

### `examples/accrue_host/lib/accrue_host_web/router.ex` (route, request-response)

**Analog:** same file, lines 100-113.

```elixir
pipeline :accrue_webhook_raw_body do
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 1_000_000
  )
end

scope "/webhooks" do
  pipe_through(:accrue_webhook_raw_body)
  accrue_webhook("/stripe", :stripe)
end
```

Create a sibling `:accrue_apple_notifications_raw_body` pipeline using exactly JSON, the same body reader, and `length: 262_144`; mount `/apple` in a separate `/webhooks` scope. The browser pipeline (lines 16-24) proves what must not appear: session, CSRF, browser headers, scope/auth, controllers, and generic Stripe handling.

**Macro contract:** `accrue/lib/accrue/router.ex:91-107`.

```elixir
defmacro accrue_apple_notifications(path, opts) do
  quote do
    forward(unquote(path), Accrue.Entitlements.Apple.NotificationPlug, unquote(opts))
  end
end
```

**Planner resolution point:** the current macro always forwards to `NotificationPlug`; it cannot mount a host wrapper. D-01's macro requirement and D-06's wrapper requirement cannot both be met using the current package code and compile-time literal options. Resolve this explicitly before implementation—do not silently substitute `forward` for the macro or expand Accrue's public API.

### `examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex` (middleware, request-response)

**Analog:** `accrue/lib/accrue/entitlements/apple/notification_plug.ex:17-45`.

```elixir
@impl true
def init(opts) do
  opts
  |> Keyword.put_new(:max_body_bytes, @default_max_body_bytes)
  |> Keyword.put_new(:rate_limiter, fn _conn -> :allow end)
  |> Keyword.put_new(:verifier, Accrue.Entitlements.Apple.Verifier.Production)
end

@impl true
def call(conn, opts) do
  with {:ok, raw_body} <- raw_body(conn, opts),
       :allow <- Keyword.fetch!(opts, :rate_limiter).(conn),
       result <- Keyword.fetch!(opts, :verifier).verify_notification(
         raw_body, Keyword.fetch!(opts, :verifier_config)
       ) do
    acknowledge_verification(conn, result, raw_body, opts)
  end
end
```

The host module should be a tiny `Plug` wrapper: `Application.fetch_env!(:accrue_host, :apple_notification_ingress)` then unchanged delegation to `NotificationPlug`. Do not reproduce verification, intake, quarantine, telemetry, or response handling. Its host rate callback receives `Plug.Conn`; normalize only trusted peer identity and return `:allow` or `{:deny, seconds}`.

**Error/durability behavior to preserve:** `notification_plug.ex:35-45, 66-80, 129-180`.

```elixir
{:error, :too_large} -> respond(conn, 413, :rejected)
{:error, :missing_raw_body} -> respond(conn, 503, :retryable)
{:deny, _retry_after_seconds} -> respond(conn, 429, :rejected)
{:error, :invalid_payload} -> respond(conn, 400, :rejected)

{:ok, %{disposition: :quarantined}} -> respond(conn, 200, :quarantined)

defp acknowledge_outcome(conn, disposition)
  when disposition in [:verified, :noop, :quarantined],
  do: respond(conn, 200, disposition)
```

### `examples/accrue_host/config/runtime.exs` (config, transform)

**Analog:** same file, lines 26-41 and production block beginning line 41.

```elixir
webhook_secret =
  if config_env() == :prod do
    System.fetch_env!("STRIPE_WEBHOOK_SECRET")
  else
    System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")
  end

config :accrue, :webhook_signing_secrets, %{stripe: webhook_secret}

if config_env() == :prod do
  database_url = System.get_env("DATABASE_URL") || raise """
  environment variable DATABASE_URL is missing.
  """
end
```

Place production-only Apple trust/client inputs in the existing production block and use `System.fetch_env!/1` for required values. Build one immutable `Verifier.Config`, then reuse that same value for ingress and `:apple_reconciliation` admission. `accrue/lib/accrue/entitlements/apple/verifier.ex:18-39` requires `:roots`, `:bundle_id`, `:environment`, `:verifier_version`, and `:config_version`; production is environment-specific, never a mixed endpoint. No credentials, root/certificate material, JWS, or provider payload belongs in committed config or tests.

### `examples/accrue_host/config/config.exs` (config, event-driven)

**Analog:** same file, lines 46-69.

```elixir
config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: [
    accrue_webhooks: 10,
    accrue_mailers: 20,
    accrue_pdf: 5,
    accrue_dunning: 2,
    accrue_meters: 5,
    accrue_scheduled: 5
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24},
    {Oban.Plugins.Cron, crontab: [{"*/15 * * * *", Accrue.Jobs.DunningSweeper}]}
  ]
```

Append `accrue_entitlements: 10` and `Accrue.Entitlements.Apple.ReconciliationSweeper`; do not replace existing queues, plugins, or Cron entries. `reconciliation_sweeper.ex:1-23` is the worker contract: it enqueues bounded due work; PostgreSQL transactions/constraints/locks remain correctness authority, not Oban uniqueness.

### `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` (test, request-response)

**Analog:** `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:1-15, 17-50, 104-109`.

```elixir
defmodule AccrueHostWeb.WebhookIngestTest do
  use AccrueHost.HostFlowProofCase, async: false

  defp post_webhook(payload, signature) do
    Plug.Test.conn(:post, "/webhooks/stripe", payload)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("stripe-signature", signature)
    |> AccrueHostWeb.Router.call(AccrueHostWeb.Router.init([]))
  end
end
```

Use the real `Router.call/2` shape with opaque synthetic JSON posted to `/webhooks/apple`, but assert Apple intake/quarantine/lineage/wakeup rows and jobs instead of `WebhookEvent`. Keep `async: false`, assert fake-verifier byte equality, and cover valid delivery, duplicate/concurrent idempotency, durable quarantine, raw-body regression, 400/413/429/503, response privacy, and reconciliation wiring. Never make direct `NotificationPlug` or `observe_apple_evidence/2` calls satisfy router-boundary coverage.

### `examples/accrue_host/test/support/apple_notification_fake_verifier.ex` (utility, transform)

**Analog:** `examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs:6-10, 12-18, 35-43`.

```elixir
defmodule FakeVerifier do
  def verify_notification(_, _), do: {:error, :invalid_payload}
  def verify_renewal(_, _), do: {:error, :invalid_payload}
  def verify_transaction(signed, _) when is_binary(signed), do: Jason.decode(signed)
end

prior = for key <- [:entitlements, :apple_reconciliation, :rails], into: %{},
  do: {key, Application.get_env(:accrue, key)}

on_exit(fn -> Enum.each(prior, fn {key, value} -> restore(key, value) end) end)
```

Make this test-only and private to the ingress test unless it is genuinely reused. Implement all verifier callbacks, deterministic result/error cases, and controlled test-process byte capture; save/restore app config. Do not use signed provider samples, roots, credentials, or raw provider-like evidence.

### `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` (test, event-driven)

**Analog:** same file, lines 13-35 and 48-73.

```elixir
test "base Oban config validates and includes required recovery cron workers" do
  oban_config = base_oban_config()
  assert :ok = Oban.Config.validate(oban_config)
  assert DunningSweeper in cron_workers(oban_config)
end

defp base_oban_config do
  config_path = Path.expand("../../config/config.exs", __DIR__)
  config_path |> Config.Reader.read!(env: :dev) |> get_in([:accrue_host, Oban])
end
```

Extend these assertions: Apple adds `:accrue_entitlements` and `ReconciliationSweeper`, while all old queues/Cron workers remain. Retain lines 38-45 test-environment assertion that Oban uses manual mode with queues/plugins disabled.

### `examples/accrue_host/test/install_boundary_test.exs` (test, batch)

**Analog:** same file, lines 31-54.

```elixir
router = File.read!(@router_path)
assert router =~ "import Accrue.Router"
assert router =~ "pipeline :accrue_webhook_raw_body do"
assert router =~ "body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}"
assert count_occurrences(router, "pipeline :accrue_webhook_raw_body do") == 1
```

Add narrow source assertions for exactly one Apple pipeline, `length: 262_144`, `/webhooks/apple`, and the explicitly resolved wrapper/macro arrangement. Source assertions must check safe configuration shape only, never secret values.

### `scripts/ci/accrue_host_verify_test_bounded.sh` (config, batch)

**Analog:** same file, lines 13-28.

```bash
test_files=(
  test/install_boundary_test.exs
  test/accrue_host/billing_facade_test.exs
  test/accrue_host_web/webhook_ingest_test.exs
)

MIX_ENV=test mix ecto.migrate --quiet
MIX_ENV=test mix test --warnings-as-errors "${test_files[@]}"
```

Append the new focused ingress proof and any needed wiring proof; preserve the explicit bounded list and the literal `mix verify` path.

### Documentation: README, proof matrix, and operator runbook (config, batch)

**README analog:** `examples/accrue_host/README.md:108-113, 182-197, 209-216`.

```markdown
Run the focused proof after the walkthrough:

```bash
cd examples/accrue_host
mix verify
```
```

Add a compact Apple ingress section at the setup/proof boundary: `/webhooks/apple`, runtime input categories (not values), response classes, safe troubleshooting, and this literal deterministic command. The local limiter is only a single-node backstop; edge/shared infrastructure is authoritative for multi-node or internet-scale limits. Apple test-notification/status evidence is advisory.

**Proof-matrix analog:** `examples/accrue_host/docs/adoption-proof-matrix.md:17-36, 38-50`.

```markdown
The deterministic lane proves Apple-to-web and Stripe-to-iOS account-projection
convergence. It is merge-blocking semantic evidence, not Crosswake mobile
runtime evidence.
```

Add a merge-blocking Fake-backed host-router ingress row and label live Apple delivery advisory. Do not claim a new reducer, live delivery authority, or unsupported runtime capability.

**Runbook analog:** `accrue/guides/operator-runbooks.md:129-141, 220-229`.

```markdown
Start with a read-only diagnostic and a dry run where the action supports it.
Record only the scenario/runbook ID, safe correlation, actor, reason, and
before/after revision.

Confirm backlog age, queue health, limit, and safe correlation ...; do not
inspect or publish worker arguments.
```

Extend the v1.59 runbook with ingress response-class trends, quarantine growth, reconciliation age/backlog, and `needs_repair`. Exclude raw bodies, JWS, certificates, tokens, PII, worker arguments, and exception text; add no public status/raw-evidence interface.

## Shared Patterns

### Exact raw-body and acknowledgement boundary

**Sources:** `accrue/lib/accrue/router.ex:23-39`; `accrue/lib/accrue/entitlements/apple/notification_plug.ex:26-45, 134-180`.

```elixir
pipeline :accrue_apple_notifications_raw_body do
  plug Plug.Parsers,
    parsers: [:json], pass: ["*/*"], json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 262_144
end
```

Apply to the router, wrapper, tests, README, and runbook. Verification receives captured original bytes only. The package owns 400 malformed, 413 oversized, 429 temporary pressure, 503 missing/config/transient/persistence failure, and 200 only after durable verified/noop/quarantine outcome.

### Runtime verifier and reconciliation identity

**Sources:** `runtime.exs:26-41`; `verifier.ex:18-39`; `reconcile_worker.ex:28-46`.

```elixir
case Application.get_env(:accrue, :apple_reconciliation) do
  config when is_list(config) ->
    client = Keyword.get(config, :client)
    admission = Keyword.get(config, :admission)
  nil ->
    {:error, :missing_reconciliation_configuration}
end
```

The host owns fail-fast configuration; ingress and reconciliation use the same immutable verifier config/version pair. Missing/invalid config fails closed.

### Additive scheduling, database correctness, and privacy

**Sources:** `config/config.exs:46-69`; `reconciliation_sweeper.ex:1-23`; `guides/entitlements.md:65-82`; `reference_scenario_conformance_test.exs:12-43`.

Append host Oban entries; do not treat job uniqueness as an execution lock. Tests use synthetic values and restore modified app config. Documentation and telemetry expose only safe correlations/digests and never provider evidence or secrets.

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| Host wrapper mounted through `accrue_apple_notifications/2` | middleware / route | request-response | Current macro hardcodes `NotificationPlug` (`accrue/lib/accrue/router.ex:100-107`), so no existing pattern satisfies D-01 and D-06 together. |

## Metadata

**Analog search scope:** `examples/accrue_host`, `accrue/lib/accrue`, `accrue/guides`, `scripts/ci`  
**Files scanned:** 25  
**Pattern extraction date:** 2026-08-05
