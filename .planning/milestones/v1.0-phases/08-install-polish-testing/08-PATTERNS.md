# Phase 08: Install + Polish + Testing - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 26
**Analogs found:** 26 / 26

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/mix.exs` | config | request-response | `accrue/mix.exs` | exact |
| `accrue/lib/mix/tasks/accrue.install.ex` | controller | file-I/O | `accrue/lib/mix/tasks/accrue.webhooks.replay.ex` | role-match |
| `accrue/lib/mix/tasks/accrue.gen.handler.ex` | controller | file-I/O | `accrue/lib/mix/tasks/accrue.mail.preview.ex` | role-match |
| `accrue/lib/accrue/install/options.ex` | utility | transform | `accrue/lib/mix/tasks/accrue.webhooks.replay.ex` | partial |
| `accrue/lib/accrue/install/project.ex` | service | file-I/O | `accrue/lib/accrue/config.ex` | role-match |
| `accrue/lib/accrue/install/patches.ex` | service | file-I/O | `accrue/lib/accrue/router.ex` | partial |
| `accrue/lib/accrue/install/templates.ex` | utility | file-I/O | `accrue/lib/mix/tasks/accrue.mail.preview.ex` | partial |
| `accrue/lib/accrue/install/fingerprints.ex` | utility | transform | `accrue/lib/accrue/processor/idempotency.ex` | role-match |
| `accrue/priv/accrue/templates/install/billing.ex.eex` | template | request-response | `accrue/lib/accrue/billing.ex` | role-match |
| `accrue/priv/accrue/templates/install/billing_handler.ex.eex` | template | event-driven | `accrue/lib/accrue/webhook/handler.ex` | exact |
| `accrue/priv/accrue/templates/install/revoke_accrue_events_writes.exs.eex` | migration | file-I/O | `accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs` | exact |
| `accrue/lib/accrue/test.ex` | provider | request-response | `accrue/lib/accrue/billing.ex` | role-match |
| `accrue/lib/accrue/test/clock.ex` | utility | event-driven | `accrue/lib/accrue/processor/fake.ex` | exact |
| `accrue/lib/accrue/test/webhooks.ex` | utility | event-driven | `accrue/lib/accrue/processor/fake.ex` | exact |
| `accrue/lib/accrue/test/event_assertions.ex` | utility | CRUD | `accrue/lib/accrue/test/mailer_assertions.ex` | role-match |
| `accrue/lib/accrue/telemetry.ex` | service | event-driven | `accrue/lib/accrue/telemetry.ex` | exact |
| `accrue/lib/accrue/telemetry/otel.ex` | service | event-driven | `accrue/lib/accrue/integrations/sigra.ex` | role-match |
| `accrue/guides/testing.md` | utility | request-response | `accrue/guides/email.md` | role-match |
| `accrue/guides/auth_adapters.md` | utility | request-response | `accrue/guides/email.md` | role-match |
| `accrue/test/mix/tasks/accrue_install_test.exs` | test | file-I/O | `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs` | role-match |
| `accrue/test/mix/tasks/accrue_gen_handler_test.exs` | test | file-I/O | `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs` | role-match |
| `accrue/test/accrue/test/clock_test.exs` | test | event-driven | `accrue/test/accrue/processor/fake_test.exs` | exact |
| `accrue/test/accrue/test/webhooks_test.exs` | test | event-driven | `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` | role-match |
| `accrue/test/accrue/test/event_assertions_test.exs` | test | CRUD | `accrue/test/accrue/test/mailer_assertions_test.exs` | role-match |
| `accrue/test/accrue/test/facade_test.exs` | test | request-response | `accrue/test/accrue/test/mailer_assertions_test.exs` | role-match |
| `accrue/test/accrue/telemetry/otel_test.exs` | test | event-driven | `accrue/test/accrue/integrations/sigra_test.exs` | role-match |

## Pattern Assignments

### `accrue/mix.exs` (config, request-response)

**Analog:** `accrue/mix.exs`

**Dependency placement pattern** (lines 47-95):

```elixir
defp deps do
  [
    {:nimble_options, "~> 1.1"},
    {:telemetry, "~> 1.3"},
    {:jason, "~> 1.4"},
    {:plug, "~> 1.16"},

    # Optional deps — conditionally compiled; see CLAUDE.md §Conditional Compilation.
    {:phoenix, "~> 1.8", optional: true},
    {:opentelemetry, "~> 1.7", optional: true},
    {:telemetry_metrics, "~> 1.1", optional: true},

    # Dev / test
    {:mox, "~> 1.2", only: :test},
    {:stream_data, "~> 1.3", only: [:dev, :test]},
    {:ex_doc, "~> 0.40", only: :dev, runtime: false}
  ]
end
```

Add `{:igniter, "~> 0.7.9", runtime: false}` near required/build-time deps. Keep comments explicit about installer-only usage.

**Docs extras pattern** (lines 122-128):

```elixir
defp docs do
  [
    main: "Accrue",
    source_ref: "v#{@version}",
    extras: ["guides/telemetry.md"]
  ]
end
```

Planner should add `guides/testing.md` and the community auth guide here, not leave new guides undiscoverable.

---

### `accrue/lib/mix/tasks/accrue.install.ex` (controller, file-I/O)

**Analog:** `accrue/lib/mix/tasks/accrue.webhooks.replay.ex`

**Imports/entry pattern** (lines 27-44):

```elixir
use Mix.Task

@switches [
  since: :string,
  dry_run: :boolean,
  all_dead: :boolean,
  yes: :boolean,
  force: :boolean
]

@impl Mix.Task
def run(argv) do
  Mix.Task.run("app.start")

  {opts, args, _invalid} = OptionParser.parse(argv, strict: @switches)
```

For install, use `Mix.Task.run("loadpaths")` unless a task genuinely needs the host app started. Parse strict switches for `--dry-run`, `--yes`, `--non-interactive`, `--manual`, `--force`, and `--write-conflicts`.

**Prompt/safety pattern** (lines 105-116):

```elixir
defp confirm_if_nuclear!(opts, filter) do
  if opts[:all_dead] == true and opts[:yes] != true do
    count = Accrue.Webhooks.DLQ.count(filter)

    if count > 10 do
      response = Mix.shell().prompt("This will requeue #{count} dead-lettered events. Continue? [y/N]")
      unless String.trim(response) in ["y", "Y", "yes", "YES"] do
        Mix.raise("Aborted by user.")
      end
    end
  end
end
```

Copy the explicit `--yes` bypass semantics. The install task should prompt only for D8-02 product choices and should raise on invalid options or aborted changes.

**Error reporting pattern** (lines 76-84):

```elixir
case Accrue.Webhooks.DLQ.requeue_where(filter, replay_opts) do
  {:ok, %{requeued: n} = result} ->
    Mix.shell().info("Replay result: #{inspect(result)} (requeued=#{n})")

  {:error, :replay_too_large} ->
    Mix.raise("Replay exceeds dlq_replay_max_rows. Re-run with --force to override.")

  {:error, reason} ->
    Mix.raise("Replay failed: #{inspect(reason)}")
end
```

Installer final output should follow this explicit changed/skipped/conflict/manual-follow-up reporting style.

---

### `accrue/lib/mix/tasks/accrue.gen.handler.ex` (controller, file-I/O)

**Analog:** `accrue/lib/mix/tasks/accrue.mail.preview.ex`

**Loadpaths/no app start pattern** (lines 41-56):

```elixir
@impl Mix.Task
def run(argv) do
  Mix.Task.run("loadpaths")
  Application.ensure_all_started(:mjml_eex)
  Application.ensure_all_started(:phoenix_html)

  {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

  types = parse_only(Keyword.get(opts, :only))
  formats = parse_format(Keyword.get(opts, :format, "both"))

  File.mkdir_p!(@preview_dir)
```

Use this for generator tasks that write files/templates without requiring Repo/Oban boot.

**Validation pattern** (lines 103-107):

```elixir
defp parse_format("html"), do: [:html]
defp parse_format("txt"), do: [:txt]
defp parse_format("pdf"), do: [:pdf]
defp parse_format("both"), do: [:html, :txt]
defp parse_format(other), do: Mix.raise("Invalid --format: #{inspect(other)}")
```

Generated handler options should fail loud on unknown handler module/path choices.

---

### `accrue/lib/accrue/install/options.ex` (utility, transform)

**Analog:** `accrue/lib/mix/tasks/accrue.webhooks.replay.ex`

**Strict parsing pattern** (lines 29-43):

```elixir
@switches [
  since: :string,
  until: :string,
  type: :string,
  dry_run: :boolean,
  all_dead: :boolean,
  yes: :boolean,
  force: :boolean
]

{opts, args, _invalid} = OptionParser.parse(argv, strict: @switches)
```

Centralize installer switches in this module. Do not scatter `OptionParser.parse/2` across installer services.

**Transform helper pattern** (lines 88-102):

```elixir
defp build_filter(opts) do
  []
  |> maybe_put(:since, opts[:since], &parse_date/1)
  |> maybe_put(:until, opts[:until], &parse_date/1)
  |> maybe_put(:type, opts[:type], & &1)
end

defp maybe_put(filter, _key, nil, _fun), do: filter
defp maybe_put(filter, key, value, fun), do: Keyword.put(filter, key, fun.(value))
```

Use the same small pure transforms for billable module, context module, webhook path, admin mount path, Sigra/admin booleans, and manual/dry-run modes.

---

### `accrue/lib/accrue/install/project.ex` (service, file-I/O)

**Analog:** `accrue/lib/accrue/config.ex`

**Schema/docs validation pattern** (lines 331-343):

```elixir
## Options

#{NimbleOptions.docs(@schema)}

@doc """
Validates a keyword list against the Phase 1 schema and returns the
normalized form. Raises `NimbleOptions.ValidationError` on failure.
"""
@spec validate!(keyword()) :: keyword()
def validate!(opts) when is_list(opts) do
  NimbleOptions.validate!(opts, @schema)
end
```

Use `Accrue.Config.validate!/1` against planned config before applying. If install options get their own schema, follow this exact docs + `validate!/1` shape.

**Unknown-key failure pattern** (lines 350-361):

```elixir
def get!(key) when is_atom(key) do
  unless Keyword.has_key?(@schema, key) do
    raise Accrue.ConfigError,
      key: key,
      message: "unknown accrue config key: #{inspect(key)}"
  end

  case Application.get_env(:accrue, key, :__accrue_unset__) do
    :__accrue_unset__ -> default_for(key)
    value -> value
  end
end
```

Discovery should fail explicitly when Repo/router/application cannot be determined safely, then route to manual snippets.

---

### `accrue/lib/accrue/install/patches.ex` (service, file-I/O)

**Analog:** `accrue/lib/accrue/router.ex`

**Webhook raw body snippet pattern** (lines 5-21):

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

scope "/webhooks" do
  pipe_through :accrue_webhook_raw_body
  accrue_webhook "/stripe", :stripe
end
```

Installer router patches must produce this exact scoped raw-body pipeline or print it in `--manual`.

**Macro expansion pattern** (lines 45-49):

```elixir
defmacro accrue_webhook(path, processor) do
  quote do
    forward unquote(path), Accrue.Webhook.Plug, processor: unquote(processor)
  end
end
```

Patch router to use `accrue_webhook`, not a hand-written `forward` unless generating manual snippets.

**Admin mount pattern:** use `accrue_admin/2` from `accrue_admin/lib/accrue_admin/router.ex` lines 23-35 and route through the macro rather than copying admin routes.

```elixir
defmacro accrue_admin(path, opts \\ []) do
  opts = Macro.expand_literals(opts, __CALLER__)
  validated = validate_opts!(path, opts)
  mount_path = validated[:mount_path]
  session_keys = validated[:session_keys]
  on_mount = validated[:on_mount]
  dev_routes? = validated[:allow_live_reload]
```

---

### `accrue/lib/accrue/install/templates.ex` (utility, file-I/O)

**Analog:** `accrue/lib/mix/tasks/accrue.mail.preview.ex`

**Directory/write pattern** (lines 56-77, 128-131):

```elixir
File.mkdir_p!(@preview_dir)

Enum.each(types, fn type ->
  fixture = fetch_fixture(type)
  module = Worker.template_for(type)
  write(type, "html", safe_render(module, :render, fixture))
end)

defp write(type, ext, content) when is_binary(content) do
  path = Path.join(@preview_dir, "#{type}.#{ext}")
  File.write!(path, content)
  Mix.shell().info("  #{path}")
end
```

For install templates, wrap writes behind fingerprint/no-clobber checks before calling `File.write!/2`.

---

### `accrue/lib/accrue/install/fingerprints.ex` (utility, transform)

**Analog:** `accrue/lib/accrue/events.ex`

**Idempotency collision pattern** (lines 118-130, 177-188):

```elixir
defp insert_opts(%{idempotency_key: key}) when is_binary(key) do
  [
    on_conflict: :nothing,
    conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
    returning: true
  ]
end

case Accrue.Repo.insert(changeset, insert_opts(attrs)) do
  {:ok, %Event{id: nil}} ->
    fetch_by_idempotency_key(key)

  {:ok, %Event{} = event} ->
    {:ok, event}
end
```

Use the same philosophy for generated files: a fingerprint match means safe update; mismatch means skip/report or reviewable diff, never silent overwrite.

---

### `accrue/priv/accrue/templates/install/billing.ex.eex` (template, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Facade/delegate pattern** (lines 24-42, 58-79):

```elixir
alias Accrue.Billing.Customer

alias Accrue.Billing.{
  ChargeActions,
  InvoiceActions,
  SubscriptionActions
}

alias Accrue.Events
alias Accrue.Processor
alias Accrue.Repo

defdelegate subscribe(user, price_id_or_opts \\ [], opts \\ []), to: SubscriptionActions
defdelegate cancel(sub, opts \\ []), to: SubscriptionActions
defdelegate resume(sub, opts \\ []), to: SubscriptionActions
defdelegate preview_upcoming_invoice(sub_or_customer, opts \\ []), to: SubscriptionActions
```

Generated `MyApp.Billing` should be a thin host-owned context that delegates to `Accrue.Billing` and leaves host policy hooks obvious.

---

### `accrue/priv/accrue/templates/install/billing_handler.ex.eex` (template, event-driven)

**Analog:** `accrue/lib/accrue/webhook/handler.ex`

**Handler scaffold pattern** (lines 5-19, 38-45):

```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  def handle_event("invoice.payment_failed", event, _ctx) do
    MyApp.Slack.notify(event.object_id)
  end
end

defmacro __using__(_opts) do
  quote do
    @behaviour Accrue.Webhook.Handler
    def handle_event(_type, _event, _ctx), do: :ok
    defoverridable handle_event: 3
  end
end
```

Generated handlers must use `Accrue.Webhook.Handler` to inherit fallthrough behavior.

---

### `accrue/priv/accrue/templates/install/revoke_accrue_events_writes.exs.eex` (migration, file-I/O)

**Analog:** `accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs`

**Migration template pattern** (lines 1-30):

```elixir
defmodule Accrue.Repo.Migrations.RevokeAccrueEventsWrites do
  use Ecto.Migration

  # EDIT ME: replace `accrue_app` with the Postgres role your application
  # connects as (e.g., the user in your `config/runtime.exs` Repo config).
  @app_role "accrue_app"

  def up do
    execute "REVOKE UPDATE, DELETE, TRUNCATE ON accrue_events FROM #{@app_role}"
  end

  def down do
    execute "GRANT UPDATE, DELETE, TRUNCATE ON accrue_events TO #{@app_role}"
  end
end
```

Copy this into host migrations with timestamp collision handling and preserve the edit-me warning.

---

### `accrue/lib/accrue/test.ex` (provider, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Public facade pattern** (lines 44-57, 58-79):

```elixir
# Public functions are declared here via `defdelegate`, pointing
# at a per-surface action module.

defdelegate subscribe(user, price_id_or_opts \\ [], opts \\ []), to: SubscriptionActions
defdelegate cancel(sub, opts \\ []), to: SubscriptionActions
defdelegate resume(sub, opts \\ []), to: SubscriptionActions
```

`Accrue.Test` should expose a small public surface via `defdelegate` to focused modules, while `__using__/1` imports assertions.

**Assertion import pattern:** combine `Accrue.Test.MailerAssertions` lines 26-30 and `Accrue.Test.PdfAssertions` lines 23-27.

```elixir
defmacro __using__(_opts) do
  quote do
    import Accrue.Test.MailerAssertions
  end
end
```

---

### `accrue/lib/accrue/test/clock.ex` (utility, event-driven)

**Analog:** `accrue/lib/accrue/processor/fake.ex`

**Fake clock pattern** (lines 105-135):

```elixir
@spec advance(GenServer.server(), integer()) :: :ok
def advance(server \\ __MODULE__, seconds) when is_integer(seconds) do
  GenServer.call(server, {:advance, seconds})
end

@spec advance_subscription(String.t() | nil, keyword()) :: :ok
def advance_subscription(stripe_id, opts)
    when (is_binary(stripe_id) or is_nil(stripe_id)) and is_list(opts) do
  GenServer.call(__MODULE__, {:advance_subscription, stripe_id, opts})
end
```

`advance_clock/2` should normalize readable durations/keyword forms to seconds/options and call these Fake APIs. It must not sleep.

**Test setup pattern** from `accrue/test/accrue/processor/fake_test.exs` lines 7-15:

```elixir
setup do
  case Fake.start_link([]) do
    {:ok, _pid} -> :ok
    {:error, {:already_started, _pid}} -> :ok
  end

  :ok = Fake.reset()
  :ok
end
```

---

### `accrue/lib/accrue/test/webhooks.ex` (utility, event-driven)

**Analog:** `accrue/lib/accrue/processor/fake.ex`

**Synthetic event routing pattern** (lines 2190-2218):

```elixir
defp maybe_synthesize(state, opts, type, object) do
  if Keyword.get(opts, :synthesize_webhooks, true) do
    synthesize_event(state, type, object)
  else
    state
  end
end

defp synthesize_event(state, type, object) do
  event = %{
    id: event_id,
    object: "event",
    type: type,
    created: DateTime.to_unix(state.clock),
    data: %{object: object}
  }

  handler = Accrue.Webhook.DefaultHandler

  if Code.ensure_loaded?(handler) and function_exported?(handler, :handle, 1) do
    _ = apply(handler, :handle, [event])
  end
end
```

`trigger_event/2` must synthesize Stripe/Accrue-shaped events through the same handler path, not mutate tables directly.

---

### `accrue/lib/accrue/test/event_assertions.ex` (utility, CRUD)

**Analog:** `accrue/lib/accrue/test/mailer_assertions.ex`

**Macro + matcher pattern** (lines 37-60, 114-131):

```elixir
defmacro assert_email_sent(type, opts \\ [], timeout \\ 100) do
  quote do
    expected_type = unquote(type)
    matchers = unquote(opts)
    t = unquote(timeout)

    receive do
      {:accrue_email_delivered, ^expected_type, assigns} ->
        unless Accrue.Test.MailerAssertions.__match__(assigns, matchers) do
          ExUnit.Assertions.flunk(
            "email of type #{inspect(expected_type)} delivered but did not match " <>
              "opts #{inspect(matchers)}; got assigns #{inspect(assigns)}"
          )
        end
    after
      t -> ExUnit.Assertions.flunk("no email of type #{inspect(expected_type)} delivered within #{t}ms")
    end
  end
end

def __match__(assigns, opts) do
  Enum.all?(opts, fn
    {:assigns, expected} when is_map(expected) ->
      Map.take(assigns, Map.keys(expected)) == expected

    {:matches, fun} when is_function(fun, 1) ->
      fun.(assigns)
  end)
end
```

For events, query `Accrue.Events.timeline_for/3` then use keyword filters, partial maps, subject structs, and predicates. Failure output must include observed events.

**Events query pattern** from `accrue/lib/accrue/events.ex` lines 238-249:

```elixir
def timeline_for(subject_type, subject_id, opts \\ [])
    when is_binary(subject_type) and is_binary(subject_id) and is_list(opts) do
  limit = Keyword.get(opts, :limit, 1_000)

  from(e in Event,
    where: e.subject_type == ^subject_type and e.subject_id == ^subject_id,
    order_by: [asc: e.inserted_at, asc: e.id],
    limit: ^limit
  )
  |> Accrue.Repo.all()
  |> Enum.map(&upcast_to_current/1)
end
```

---

### `accrue/lib/accrue/telemetry.ex` (service, event-driven)

**Analog:** `accrue/lib/accrue/telemetry.ex`

**Central span path** (lines 55-64):

```elixir
@spec span(event_name(), map(), (-> result)) :: result when result: var
def span(event, metadata \\ %{}, fun)
    when is_list(event) and is_map(metadata) and is_function(fun, 0) do
  base_metadata = maybe_put_actor(metadata)

  :telemetry.span(event, base_metadata, fn ->
    result = fun.()
    {result, base_metadata}
  end)
end
```

Modify this central path to call `Accrue.Telemetry.OTel.span/3` around or inside the telemetry span. Do not introduce separate public tracing APIs.

**Optional trace id pattern** (lines 41, 70-91):

```elixir
@compile {:no_warn_undefined, [:otel_tracer, :otel_span]}

if Code.ensure_loaded?(:otel_tracer) do
  def current_trace_id do
    case :otel_tracer.current_span_ctx() do
      :undefined -> nil
      ctx -> ctx |> :otel_span.trace_id() |> Integer.to_string(16)
    end
  rescue
    _ -> nil
  end
else
  def current_trace_id, do: nil
end
```

Keep with/without OpenTelemetry compilation warning-free.

---

### `accrue/lib/accrue/telemetry/otel.ex` (service, event-driven)

**Analog:** `accrue/lib/accrue/integrations/sigra.ex`

**Conditional module pattern** (lines 31-52):

```elixir
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @behaviour Accrue.Auth
    @compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}

    @impl Accrue.Auth
    def current_user(conn), do: Sigra.Auth.current_user(conn)
  end
end
```

Mirror this for `OpenTelemetry.Tracer`/`:otel_tracer` with `@compile {:no_warn_undefined, [...]}`. If the module is always defined, make the OTel calls conditional inside the functions.

**Attribute policy source:** `accrue/guides/telemetry.md` lines 89-120.

```markdown
Allowed attributes:
- `accrue.subscription.id`
- `accrue.customer.id`
- `accrue.invoice.id`
- `accrue.event_type`
- `accrue.processor`

PROHIBITED attributes:
- Any customer email, name, phone, postal address
- Any card PAN, CVC, expiry, fingerprint metadata
- Any webhook raw body or signature
```

Implement an allowlist sanitizer and test prohibited keys.

---

### `accrue/guides/testing.md` (utility, request-response)

**Analog:** `accrue/guides/email.md`

**Guide structure pattern** (lines 8-37, 129-153):

````markdown
## Quickstart

Minimal config for a host Phoenix app:

```elixir
# config/config.exs
config :accrue,
  mailer: Accrue.Mailer.Default
```

The host application's supervision tree is responsible for starting
Oban, ChromicPDF, and the Swoosh adapter — Accrue does not start them
itself.

## Testing

Accrue ships a test adapter `Accrue.Mailer.Test` that intercepts
`Accrue.Mailer.deliver/2` calls before Oban enqueue and sends an intent
tuple.
````

Testing guide should open with a copy-paste scenario, then scenario sections, then helper reference, then external-provider appendix.

---

### `accrue/guides/auth_adapters.md` (utility, request-response)

**Analog:** `accrue/guides/email.md`

**Override/adapter ladder pattern** (lines 74-127):

````markdown
## Override ladder

### Rung 1 — per-type kill switch

```elixir
config :accrue, :emails,
  trial_ending: false
```

### Rung 4 — full pipeline replace

```elixir
config :accrue, :mailer, MyApp.Mailer
```

Point `:mailer` at any module implementing the `Accrue.Mailer`
behaviour.
````

Community auth guide should use the same pattern: default adapter, Sigra adapter, custom `Accrue.Auth` behaviour, then phx.gen.auth/Pow/Assent examples.

---

### `accrue/test/mix/tasks/accrue_install_test.exs` and `accrue/test/mix/tasks/accrue_gen_handler_test.exs` (test, file-I/O)

**Analog:** `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs`

**Mix shell test pattern** (lines 1-24):

```elixir
defmodule Mix.Tasks.Accrue.Webhooks.ReplayTest do
  use Accrue.RepoCase

  import ExUnit.CaptureIO

  alias Mix.Tasks.Accrue.Webhooks.Replay

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    :ok
  end

  test "single event id requeues that event" do
    Replay.run([row.id])

    assert_received {:mix_shell, :info, [info]}
    assert info =~ "Requeued #{row.id}"
  end
end
```

Use `Mix.Shell.Process`, assert dry-run/manual output, and isolate temp host app files.

**Dry-run/no mutation pattern** (lines 27-51):

```elixir
Replay.run([
  "--since",
  "2020-01-01",
  "--type",
  "invoice.payment_failed",
  "--dry-run"
])

assert_received {:mix_shell, :info, [info]}
assert info =~ "would_requeue: 2"
assert info =~ "requeued=0"

# Nothing mutated
remaining_dead = Accrue.TestRepo.aggregate(query, :count, :id)
assert remaining_dead == 2
```

Installer tests must prove `--dry-run` leaves files untouched and `--manual` prints snippets only.

---

### `accrue/test/accrue/test/clock_test.exs` (test, event-driven)

**Analog:** `accrue/test/accrue/processor/fake_test.exs`

**Fake clock assertion pattern** (lines 74-97):

```elixir
describe "test clock" do
  test "advance/2 moves the clock forward by N seconds" do
    before = Fake.current_time()
    :ok = Fake.advance(Fake, 3600)
    after_advance = Fake.current_time()

    assert DateTime.diff(after_advance, before, :second) == 3600
  end

  test "reset/0 restores the clock and zeros counters" do
    :ok = Fake.advance(Fake, 7200)
    :ok = Fake.reset()
    assert %DateTime{year: 2026, month: 1, day: 1, hour: 0} = Fake.current_time()
  end
end
```

Add tests for readable durations, keyword durations, subscription-aware lifecycle events, and no sleeps.

---

### `accrue/test/accrue/test/webhooks_test.exs` (test, event-driven)

**Analog:** `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`

**Production handler path pattern** (lines 54-70):

```elixir
test "dispatches :receipt with customer_id scalar", %{customer: cus} do
  {:ok, stripe_ch} =
    Fake.create_charge(
      %{amount: 10_000, currency: "usd", customer: cus.processor_id},
      []
    )

  event =
    StripeFixtures.webhook_event(
      "charge.succeeded",
      StripeFixtures.charge(%{"id" => stripe_ch.id, "customer" => cus.processor_id})
    )

  assert {:ok, %Charge{}} = DefaultHandler.handle(event)
  assert_email_sent(:receipt, customer_id: cus.id)
end
```

`trigger_event/2` tests should assert persisted state, ledger output, mail/PDF side effects, and Oban enqueue where relevant.

---

### `accrue/test/accrue/test/event_assertions_test.exs` and `accrue/test/accrue/test/facade_test.exs` (test, CRUD/request-response)

**Analog:** `accrue/test/accrue/test/mailer_assertions_test.exs`

**Matcher test pattern** (lines 21-52):

```elixir
test "matches :customer_id" do
  send(self(), {:accrue_email_delivered, :receipt, %{customer_id: "cus_1"}})
  assert_email_sent(:receipt, customer_id: "cus_1")
end

test "subset-matches :assigns via Map.take" do
  send(self(), {:accrue_email_delivered, :receipt, %{foo: 1, bar: 2, baz: 3}})
  assert_email_sent(:receipt, assigns: %{foo: 1, bar: 2})
end

test ":matches runs 1-arity predicate" do
  send(self(), {:accrue_email_delivered, :receipt, %{count: 10}})
  assert_email_sent(:receipt, matches: fn a -> a[:count] > 5 end)
end

test "flunks when message present but opts do not match" do
  assert_raise ExUnit.AssertionError, ~r/did not match/, fn ->
    assert_email_sent(:receipt, customer_id: "cus_2")
  end
end
```

Copy this coverage shape for event filters, partial data maps, subject structs, predicates, refutes, and failure text.

---

### `accrue/test/accrue/telemetry/otel_test.exs` (test, event-driven)

**Analog:** `accrue/test/accrue/integrations/sigra_test.exs`

**Optional dependency matrix test pattern** (lines 23-45):

```elixir
test "Accrue.Integrations.Sigra is either loaded OR :nofile — never a crash" do
  case Code.ensure_loaded(Accrue.Integrations.Sigra) do
    {:module, Accrue.Integrations.Sigra} ->
      assert function_exported?(Accrue.Integrations.Sigra, :current_user, 1)

    {:error, :nofile} ->
      refute Code.ensure_loaded?(Sigra)
  end
end
```

Use the same either-loaded-or-absent shape for `Accrue.Telemetry.OTel`, plus a compile/source test for `Code.ensure_loaded?` and `@compile {:no_warn_undefined, ...}`.

**Span/metadata test pattern** from `accrue/test/accrue/telemetry_test.exs` lines 31-80:

```elixir
result = T.span(base_event, %{foo: 1}, fn -> :ok_result end)

assert result == :ok_result
assert_received {:telemetry, [:accrue, :test, :thing, :do, :start], _, %{foo: 1}}
assert_received {:telemetry, [:accrue, :test, :thing, :do, :stop], _, %{foo: 1}}

refute Map.has_key?(meta, :result)
refute Enum.any?(Map.values(meta), &match?("not-in-metadata", &1))
```

Add privacy guardrail tests for prohibited OTel attributes.

## Shared Patterns

### CLI Tasks

**Source:** `accrue/lib/mix/tasks/accrue.webhooks.replay.ex`
**Apply to:** installer tasks and handler generator

```elixir
use Mix.Task

@impl Mix.Task
def run(argv) do
  Mix.Task.run("app.start")
  {opts, args, _invalid} = OptionParser.parse(argv, strict: @switches)
  # dispatch by args/options, report via Mix.shell(), fail via Mix.raise()
end
```

Use `Mix.Task.run("loadpaths")` for tasks that should not boot host-owned Repo/Oban/ChromicPDF.

### Config Validation

**Source:** `accrue/lib/accrue/config.ex`
**Apply to:** installer planned config and docs output

```elixir
@spec validate!(keyword()) :: keyword()
def validate!(opts) when is_list(opts) do
  NimbleOptions.validate!(opts, @schema)
end
```

Never hand-roll config validation; use the schema and `NimbleOptions.docs/1`.

### Optional Dependencies

**Source:** `accrue/lib/accrue/integrations/sigra.ex`
**Apply to:** OTel adapter and Sigra installer detection

```elixir
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}
  end
end
```

Pair this with source/compile tests like `accrue/test/accrue/integrations/sigra_test.exs`.

### Process-Local Test Captures

**Source:** `accrue/lib/accrue/test/mailer_assertions.ex` and `accrue/lib/accrue/test/pdf_assertions.ex`
**Apply to:** `Accrue.Test`, event assertions, guide examples

```elixir
receive do
  {:accrue_email_delivered, ^expected_type, assigns} ->
    unless Accrue.Test.MailerAssertions.__match__(assigns, matchers) do
      ExUnit.Assertions.flunk("email of type #{inspect(expected_type)} delivered but did not match")
    end
after
  t -> ExUnit.Assertions.flunk("no email of type #{inspect(expected_type)} delivered within #{t}ms")
end
```

Keep captures process-owned and async-safe by default. Make cross-process/global modes explicit.

### Webhook/Admin Router Snippets

**Source:** `accrue/lib/accrue/router.ex` and `accrue_admin/lib/accrue_admin/router.ex`
**Apply to:** installer router patches and manual snippets

```elixir
pipeline :accrue_webhook_raw_body do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 1_000_000
end

accrue_webhook "/stripe", :stripe
accrue_admin "/billing"
```

Do not copy admin LiveView routes into host apps.

### Fake-First Test Runtime

**Source:** `accrue/lib/accrue/processor/fake.ex`
**Apply to:** clock helpers, webhook helpers, testing guide

```elixir
:ok = Accrue.Processor.Fake.reset()
:ok = Accrue.Processor.Fake.advance(Fake, 3600)
:ok = Accrue.Processor.Fake.advance_subscription(stripe_id, days: 14)
```

Billing tests should drive Fake/test clocks/events, not wall-clock sleeps or Stripe sandbox calls by default.

### OTel Privacy

**Source:** `accrue/guides/telemetry.md`
**Apply to:** `Accrue.Telemetry.OTel`, span tests, testing guide warnings

```markdown
Allowed: IDs, event type, processor.
Prohibited: emails, names, addresses, card data, raw webhook body/signature, secrets, free-text user fields.
```

Implement an explicit allowlist and drop/reject everything else.

## No Analog Found

All planned files have usable local analogs. The installer patching internals will rely on new Igniter APIs, so planner should combine the local Mix task/config/router patterns above with the Igniter research in `08-RESEARCH.md`.

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/test`, `accrue/priv`, `accrue/guides`, `accrue_admin/lib`, `accrue_admin/test`
**Files scanned:** 835
**Pattern extraction date:** 2026-04-15
