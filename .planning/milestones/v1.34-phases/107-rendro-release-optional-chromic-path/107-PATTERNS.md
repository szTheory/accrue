# Phase 107: Rendro Release & Optional Chromic Path - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/invoices.ex` | service | request-response | `accrue/lib/accrue/invoices.ex` | exact |
| `accrue/lib/accrue/application.ex` | config | request-response | `accrue/lib/accrue/application.ex` | exact |
| `accrue/lib/accrue/workers/mailer.ex` | service | event-driven | `accrue/lib/accrue/workers/mailer.ex` | exact |
| `accrue/lib/accrue/telemetry/ops.ex` | utility | event-driven | `accrue/lib/accrue/telemetry/ops.ex` | exact |
| `accrue/lib/accrue/errors.ex` | model | request-response | `accrue/lib/accrue/errors.ex` | exact |
| `accrue/lib/accrue/config.ex` | config | transform | `accrue/lib/accrue/config.ex` | exact |
| `accrue/mix.exs` | config | batch | `accrue/mix.exs` | exact |
| `accrue/guides/pdf.md` | config | request-response | `accrue/guides/pdf.md` | exact |
| `accrue/guides/configuration.md` | config | transform | `accrue/guides/configuration.md` | exact |
| `accrue/guides/telemetry.md` | config | event-driven | `accrue/guides/telemetry.md` | exact |
| `RELEASING.md` | config | batch | `RELEASING.md` | exact |
| `accrue/test/accrue/billing/pdf_test.exs` | test | request-response | `accrue/test/accrue/billing/pdf_test.exs` | exact |
| `accrue/test/accrue/application_boot_guards_test.exs` | test | request-response | `accrue/test/accrue/application_boot_guards_test.exs` | exact |
| `accrue/test/accrue/config_test.exs` | test | transform | `accrue/test/accrue/config_test.exs` | exact |
| `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` | test | event-driven | `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` | exact |

## Pattern Assignments

### `accrue/lib/accrue/invoices.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/invoices.ex`

**Imports / module shape** ([lines 43-45](../../../../accrue/lib/accrue/invoices.ex:43)):
```elixir
alias Accrue.Invoices.Render

@type invoice_or_id :: Accrue.Billing.Invoice.t() | String.t()
```

**Core facade pattern** ([lines 79-89](../../../../accrue/lib/accrue/invoices.ex:79)):
```elixir
@spec render_invoice_pdf(invoice_or_id(), keyword()) ::
        {:ok, binary()} | {:error, term()}
def render_invoice_pdf(invoice_or_id, opts \\ []) do
  adapter = Accrue.InvoiceRenderer.impl()

  with :ok <- ensure_adapter_available(adapter),
       {:ok, context} <- safe_build_assigns(invoice_or_id, opts),
       {:ok, binary} <- Accrue.InvoiceRenderer.render(context, adapter_opts(opts)) do
    {:ok, binary}
  end
end
```

**Terminal adapter-availability branch** ([lines 132-146](../../../../accrue/lib/accrue/invoices.ex:132)):
```elixir
defp ensure_adapter_available(adapter) do
  if adapter == Accrue.InvoiceRenderer.ChromicPDF do
    if Process.whereis(ChromicPDF) do
      :ok
    else
      {:error, :chromic_pdf_not_started}
    end
  else
    :ok
  end
end
```

**Error wrapping pattern** ([lines 148-152](../../../../accrue/lib/accrue/invoices.ex:148)):
```elixir
defp safe_build_assigns(invoice_or_id, opts) do
  {:ok, Render.build_assigns(invoice_or_id, opts)}
rescue
  e -> {:error, e}
end
```

Use this same shape when replacing the bare atom with a typed `%Accrue.Error.*{}` terminal error.

---

### `accrue/lib/accrue/application.ex` (config, request-response)

**Analog:** `accrue/lib/accrue/application.ex`

**Boot validation chain** ([lines 57-69](../../../../accrue/lib/accrue/application.ex:57)):
```elixir
@impl true
def start(_type, _args) do
  :ok = Accrue.Config.validate_at_boot!()
  :ok = Accrue.Auth.Default.boot_check!()
  :ok = warn_on_secret_collision()
  :ok = warn_pdf_adapter_unavailable()
  :ok = warn_oban_queue_vs_pdf_pool()
  :ok = warn_company_address_locale_mismatch()

  children = []

  Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
end
```

**Boot warning pattern** ([lines 79-120](../../../../accrue/lib/accrue/application.ex:79)):
```elixir
@spec warn_pdf_adapter_unavailable() :: :ok
def warn_pdf_adapter_unavailable do
  key = :accrue_pdf_adapter_unavailable_warned?

  adapter =
    Application.get_env(
      :accrue,
      :invoice_pdf_adapter,
      Accrue.InvoiceRenderer.Rendro
    )

  env = safe_mix_env()

  cond do
    adapter != Accrue.InvoiceRenderer.ChromicPDF -> :ok
    env != :prod -> :ok
    Process.whereis(ChromicPDF) != nil -> :ok
    :persistent_term.get(key, false) -> :ok
    true ->
      :persistent_term.put(key, true)
      Logger.warning(\"\"\"
      [Accrue] :invoice_pdf_adapter is Accrue.InvoiceRenderer.ChromicPDF ...
      \"\"\")
      :ok
  end
end
```

**Migration-warning style** ([lines 127-150](../../../../accrue/lib/accrue/application.ex:127)):
```elixir
with false <- :persistent_term.get(key, false),
     true <- Application.get_env(:accrue, :attach_invoice_pdf, true),
     Accrue.InvoiceRenderer.ChromicPDF <-
       Application.get_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Rendro),
     queue_concurrency when is_integer(queue_concurrency) <- mailer_queue_concurrency(),
     pool_size when is_integer(pool_size) and queue_concurrency > pool_size <-
       Application.get_env(:accrue, :chromic_pdf_pool_size, 3) do
  :persistent_term.put(key, true)
  Logger.warning(\"\"\"...\"\"\")
  :ok
else
  _ -> :ok
end
```

Copy this `cond`/`with` + `:persistent_term` dedupe pattern for the new `:pdf_adapter`-without-`:invoice_pdf_adapter` migration warning.

---

### `accrue/lib/accrue/workers/mailer.ex` (service, event-driven)

**Analog:** `accrue/lib/accrue/workers/mailer.ex`

**Terminal vs retryable worker branch** ([lines 165-207](../../../../accrue/lib/accrue/workers/mailer.ex:165)):
```elixir
defp maybe_attach_pdf(%Mailglass.Message{} = msg, assigns, type) do
  ...

  case safe_render_invoice_pdf(invoice_id, assigns) do
    {:ok, binary} ->
      ...

    {:error, %Accrue.Error.PdfDisabled{}} ->
      append_hosted_url_note(msg, assigns, type)

    {:error, :chromic_pdf_not_started} ->
      :telemetry.execute(
        [:accrue, :ops, :pdf_adapter_unavailable],
        %{count: 1},
        %{type: type}
      )

      append_hosted_url_note(msg, assigns, type)

    {:error, reason} ->
      raise Accrue.PDF.RenderFailed, reason: reason
  end
end
```

**Duplicate Swoosh branch stays behaviorally identical** ([lines 210-246](../../../../accrue/lib/accrue/workers/mailer.ex:210)):
```elixir
defp maybe_attach_pdf(email, assigns, type) do
  ...
  case safe_render_invoice_pdf(invoice_id, assigns) do
    {:ok, binary} -> ...
    {:error, %Accrue.Error.PdfDisabled{}} -> append_hosted_url_note(email, assigns, type)
    {:error, :chromic_pdf_not_started} -> ...
    {:error, reason} -> raise Accrue.PDF.RenderFailed, reason: reason
  end
end
```

**Local terminal error construction** ([lines 249-255](../../../../accrue/lib/accrue/workers/mailer.ex:249)):
```elixir
defp safe_render_invoice_pdf(nil, _assigns) do
  {:error,
   %Accrue.Error.PdfDisabled{
     reason: :missing_invoice_id,
     message: "cannot render invoice PDF without assigns[:invoice_id]"
   }}
end
```

When the new typed Chromic error lands, thread it through both branches exactly the way `%PdfDisabled{}` is handled here.

---

### `accrue/lib/accrue/telemetry/ops.ex` (utility, event-driven)

**Analog:** `accrue/lib/accrue/telemetry/ops.ex`

**Canonical event inventory** ([lines 10-29](../../../../accrue/lib/accrue/telemetry/ops.ex:10)):
```elixir
## Canonical ops events

    [:accrue, :ops, :pdf_adapter_unavailable]
```

**Low-cardinality emit helper** ([lines 56-74](../../../../accrue/lib/accrue/telemetry/ops.ex:56)):
```elixir
@spec emit(suffix(), map(), map()) :: :ok
def emit(suffix, measurements, metadata \\ %{})

def emit(suffix, measurements, metadata)
    when is_list(suffix) and is_map(measurements) and is_map(metadata) do
  event = [:accrue, :ops] ++ suffix

  merged_metadata =
    Map.put_new_lazy(metadata, :operation_id, fn ->
      Accrue.Actor.current_operation_id()
    end)

  :telemetry.execute(event, measurements, merged_metadata)
  :ok
end
```

If Phase 107 moves emission out of the mailer-only call site, prefer `Accrue.Telemetry.Ops.emit/3` over raw `:telemetry.execute/3`.

---

### `accrue/lib/accrue/errors.ex` (model, request-response)

**Analog:** `accrue/lib/accrue/errors.ex`

**Retry wrapper pattern** ([lines 285-305](../../../../accrue/lib/accrue/errors.ex:285)):
```elixir
defmodule Accrue.PDF.RenderFailed do
  @type t :: %__MODULE__{}
  defexception [:reason, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(%__MODULE__{reason: r}), do: "PDF render failed: #{inspect(r)}"
end
```

**Typed terminal PDF error pattern** ([lines 307-325](../../../../accrue/lib/accrue/errors.ex:307)):
```elixir
defmodule Accrue.Error.PdfDisabled do
  @type t :: %__MODULE__{}
  defexception [:reason, :docs_url, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{}),
    do: "PDF rendering disabled on this Accrue instance (Accrue.PDF.Null configured)"
end
```

Model the new Chromic-unavailable error on `PdfDisabled`: same typed struct, same optional `:message`, and docs-oriented `:reason`/`docs_url` fields.

---

### `accrue/lib/accrue/config.ex` (config, transform)

**Analog:** `accrue/lib/accrue/config.ex`

**Adapter-boundary schema** ([lines 25-38](../../../../accrue/lib/accrue/config.ex:25)):
```elixir
invoice_pdf_adapter: [
  type: :atom,
  default: Accrue.InvoiceRenderer.Rendro,
  doc:
    "Invoice PDF adapter implementing `Accrue.InvoiceRenderer` behaviour. " <>
      "Defaults to the native Rendro-backed invoice renderer."
],
pdf_adapter: [
  type: :atom,
  default: Accrue.PDF.ChromicPDF,
  doc:
    "Legacy HTML-to-PDF adapter implementing `Accrue.PDF` behaviour. " <>
      "Used by the Chromic invoice renderer path and by custom HTML callers."
],
```

Keep the two-key split explicit here. Any Phase 107 messaging should clarify boundaries, not reintroduce inference.

---

### `accrue/mix.exs` (config, batch)

**Analog:** `accrue/mix.exs`

**Dependency block pattern** ([lines 49-64](../../../../accrue/mix.exs:49)):
```elixir
defp deps do
  [
    {:ecto, "~> 3.13"},
    ...
    {:mailglass, "~> 0.1"},
    {:rendro, path: "../../rendro"},
    {:chromic_pdf, "~> 1.17"},
    {:nimble_options, "~> 1.1"},
    {:telemetry, "~> 1.3"},
```

Phase 107 should replace only the `rendro` tuple and preserve the surrounding ordering/comment style.

---

### `accrue/guides/pdf.md` (config, request-response)

**Analog:** `accrue/guides/pdf.md`

**Rendro-first framing** ([lines 3-14](../../../../accrue/guides/pdf.md:3)):
```markdown
Accrue renders invoice PDFs ... but the default invoice renderer is now
native Rendro rather than Chrome.

If you only read one section: Rendro is the default. Jump to
**ChromicPDF fallback** only if you explicitly want the old HTML-based path.
```

**Adapter table + explicit switch** ([lines 18-37](../../../../accrue/guides/pdf.md:18)):
```markdown
| `Accrue.InvoiceRenderer.Rendro` | Production default. ... |
| `Accrue.InvoiceRenderer.ChromicPDF` | Optional fallback. ... |
| `Accrue.InvoiceRenderer.Null` | ... typed error ... |

The invoice renderer is resolved via `:invoice_pdf_adapter`:
```

**Host-supervised Chromic wording** ([lines 52-73](../../../../accrue/guides/pdf.md:52)):
```markdown
## ChromicPDF fallback

If you want the previous HTML-based invoice rendering path, switch:

config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF

Accrue still does **not** start ChromicPDF itself. The host app owns the
supervision tree and supervises the pool.
```

Keep this exact doc posture: explicit opt-in, no automatic fallback language.

---

### `accrue/guides/configuration.md` (config, transform)

**Analog:** `accrue/guides/configuration.md`

**Adapter-boundary bullets** ([lines 17-26](../../../../accrue/guides/configuration.md:17)):
```markdown
- `:auth_adapter` for host-owned authentication and admin authorization.
- `:invoice_pdf_adapter` for invoice rendering through `Accrue.InvoiceRenderer`.
- `:pdf_adapter` for the lower-level HTML-to-PDF seam used by ChromicPDF and custom HTML renderers.
- `:mailer` for delivery behavior in development, test, or production.
```

Use this section as the model for the migration warning text and any guide updates that distinguish invoice rendering from the lower-level HTML seam.

---

### `accrue/guides/telemetry.md` (config, event-driven)

**Analog:** `accrue/guides/telemetry.md`

**Ops catalog row** ([lines 74-81](../../../../accrue/guides/telemetry.md:74)):
```markdown
| `[:accrue, :ops, :pdf_adapter_unavailable]` | `count` | `type` (email template key), `operation_id` when set | `Accrue.Workers.Mailer` |
```

**Runbook row** ([lines 392-397](../../../../accrue/guides/telemetry.md:392)):
```markdown
| `[:accrue, :ops, :pdf_adapter_unavailable]` | Start ChromicPDF (or switch PDF adapter); emails still send with hosted invoice link fallback. |
```

Phase 107 should update both the catalog row and the operator-action row together if metadata or ownership expands beyond the mailer.

---

### `RELEASING.md` (config, batch)

**Analog:** `RELEASING.md`

**Publish-order contract** ([lines 156-162](../../../../RELEASING.md:156)):
```markdown
Manual fallback order:

1. Publish `accrue`.
2. Confirm Hex availability.
3. Publish `accrue_admin`.

Each recovery run checks out the explicit ref, verifies the package `@version`, runs `mix hex.publish --dry-run`, then runs `mix hex.publish --yes`.
```

**Hex confirmation before dependent publish** ([lines 180-186](../../../../RELEASING.md:180)):
```markdown
5. Confirm Hex package availability for `accrue` before proceeding.
6. Let `.github/workflows/release-please.yml` publish `accrue_admin` ...
```

Copy this release-proof style for the Rendro handoff: publish producer first, confirm registry truth from a clean environment, then switch the consumer.

---

### `accrue/test/accrue/billing/pdf_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/billing/pdf_test.exs`

**Env setup / restore pattern** ([lines 20-65](../../../../accrue/test/accrue/billing/pdf_test.exs:20)):
```elixir
setup do
  ...
  prior_invoice_pdf = Application.get_env(:accrue, :invoice_pdf_adapter)
  prior_storage = Application.get_env(:accrue, :storage_adapter)

  on_exit(fn ->
    if prior_invoice_pdf do
      Application.put_env(:accrue, :invoice_pdf_adapter, prior_invoice_pdf)
    else
      Application.delete_env(:accrue, :invoice_pdf_adapter)
    end
    ...
  end)
end
```

**Explicit adapter contract tests** ([lines 137-157](../../../../accrue/test/accrue/billing/pdf_test.exs:137)):
```elixir
describe "Accrue.Invoices.render_invoice_pdf/2 with Accrue.InvoiceRenderer.Null" do
  ...
  test "returns {:error, %PdfDisabled{}} WITHOUT raising", %{inv: inv} do
    assert {:error, %PdfDisabled{}} = Accrue.Invoices.render_invoice_pdf(inv)
  end
end

describe "Accrue.Invoices.render_invoice_pdf/2 with ChromicPDF adapter but process absent" do
  ...
  test "returns {:error, :chromic_pdf_not_started}", %{inv: inv} do
    assert {:error, :chromic_pdf_not_started} = Accrue.Invoices.render_invoice_pdf(inv)
  end
end
```

Update these tests first when the atom becomes a typed `%Accrue.Error.*{}`.

---

### `accrue/test/accrue/application_boot_guards_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/application_boot_guards_test.exs`

**Dedupe-key clearing pattern** ([lines 19-31](../../../../accrue/test/accrue/application_boot_guards_test.exs:19)):
```elixir
defp clear_dedupe_keys do
  for k <- [
        :accrue_pdf_adapter_unavailable_warned?,
        :accrue_oban_queue_vs_pdf_pool_warned?,
        :accrue_company_address_locale_warned?
      ] do
    try do
      :persistent_term.erase(k)
    rescue
      _ -> :ok
    end
  end
end
```

**Current mis-keyed env setup to fix** ([lines 36-46](../../../../accrue/test/accrue/application_boot_guards_test.exs:36)):
```elixir
original_pdf = Application.get_env(:accrue, :pdf_adapter)
...
if is_nil(original_pdf),
  do: Application.delete_env(:accrue, :pdf_adapter),
  else: Application.put_env(:accrue, :pdf_adapter, original_pdf)
```

**Guard assertions** ([lines 64-79](../../../../accrue/test/accrue/application_boot_guards_test.exs:64)):
```elixir
describe "warn_pdf_adapter_unavailable/0" do
  test "no warn when adapter is not ChromicPDF" do
    Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Null)
    ...
  end
end
```

Phase 107 should preserve this test shape but switch it to `:invoice_pdf_adapter` and add the migration-warning coverage for `:pdf_adapter`.

---

### `accrue/test/accrue/config_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/config_test.exs`

**Default-boundary assertion pattern** ([lines 78-89](../../../../accrue/test/accrue/config_test.exs:78)):
```elixir
test "adapter defaults resolve to module atoms" do
  Application.delete_env(:accrue, :invoice_pdf_adapter)
  Application.delete_env(:accrue, :pdf_adapter)
  Application.delete_env(:accrue, :auth_adapter)
  Application.delete_env(:accrue, :mailer)
  Application.delete_env(:accrue, :mailer_adapter)
  assert Accrue.InvoiceRenderer.Rendro == Config.get!(:invoice_pdf_adapter)
  assert Accrue.PDF.ChromicPDF == Config.get!(:pdf_adapter)
end
```

Use the same style for any new config-boundary or migration-warning assertions.

---

### `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` (test, event-driven)

**Analog:** `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`

**Per-test adapter override pattern** ([lines 52-70](../../../../accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs:52)):
```elixir
prior_mailer = Application.get_env(:accrue, :mailer)
prior_invoice_pdf = Application.get_env(:accrue, :invoice_pdf_adapter)
...
Application.put_env(:accrue, :mailer, Accrue.Mailer.Default)
Application.put_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Test)
```

**Fallback behavior assertion style** ([lines 175-210](../../../../accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs:175)):
```elixir
test "falls back to the hosted invoice URL note when PDF rendering does not run", %{ customer: cus } do
  ...
  assert {:ok, _} = Accrue.Workers.Mailer.perform(job)
  ...
  refute Enum.any?(msg.swoosh_email.attachments, &(&1.content_type == "application/pdf"))
end
```

Use this file to cover the typed Chromic-unavailable degradation path and any telemetry assertion tied to the mailer fallback.

## Shared Patterns

### Typed terminal PDF errors
**Source:** `accrue/lib/accrue/errors.ex:307`, `accrue/lib/accrue/invoices.ex:79`
**Apply to:** `invoices.ex`, `workers/mailer.ex`, `pdf_test.exs`, docs
```elixir
defmodule Accrue.Error.PdfDisabled do
  defexception [:reason, :docs_url, :message]
end

with :ok <- ensure_adapter_available(adapter),
     {:ok, context} <- safe_build_assigns(invoice_or_id, opts),
     {:ok, binary} <- Accrue.InvoiceRenderer.render(context, adapter_opts(opts)) do
  {:ok, binary}
end
```

### Host-owned infrastructure warnings
**Source:** `accrue/lib/accrue/application.ex:79`
**Apply to:** `application.ex`, boot-guard tests, PDF/config guides
```elixir
cond do
  adapter != Accrue.InvoiceRenderer.ChromicPDF -> :ok
  env != :prod -> :ok
  Process.whereis(ChromicPDF) != nil -> :ok
  :persistent_term.get(key, false) -> :ok
  true ->
    :persistent_term.put(key, true)
    Logger.warning(\"\"\"...\"\"\")
    :ok
end
```

### Low-cardinality ops telemetry
**Source:** `accrue/lib/accrue/telemetry/ops.ex:56`, `accrue/guides/telemetry.md:77`
**Apply to:** `workers/mailer.ex`, `invoices.ex`, telemetry guide
```elixir
Accrue.Telemetry.Ops.emit(:pdf_adapter_unavailable, %{count: 1}, %{type: type})
```

Keep metadata low-cardinality. The existing documented tag is `type`; do not add invoice IDs, customer IDs, or free-text errors.

### Explicit adapter-boundary docs/config
**Source:** `accrue/lib/accrue/config.ex:25`, `accrue/guides/configuration.md:17`, `accrue/guides/pdf.md:26`
**Apply to:** `config.ex`, `configuration.md`, `pdf.md`, boot warning copy
```elixir
invoice_pdf_adapter: [default: Accrue.InvoiceRenderer.Rendro]
pdf_adapter: [default: Accrue.PDF.ChromicPDF]
```

## No Analog Found

None. Every Phase 107 target already has a strong in-repo analog.

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue/test/accrue`, `accrue/guides`, repo root docs
**Files scanned:** 16
**Pattern extraction date:** 2026-05-06
