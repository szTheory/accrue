# Phase 6: Email + PDF — Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** ~34 new + ~4 modified
**Analogs found:** 34 / 34 (Phase 1 did the plumbing — every new file has a strong in-repo analog)

## File Classification

### New files

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/invoices/render.ex` | service (data hydration) | request-response (read-through) | `accrue/lib/accrue/billing/invoice_projection.ex` + `accrue/lib/accrue/workers/mailer.ex` `enrich/2` | role-match |
| `accrue/lib/accrue/invoices/render_context.ex` | model (plain struct) | transform | `accrue/lib/accrue/money.ex` (defstruct + @type) | exact |
| `accrue/lib/accrue/invoices/components.ex` | component (Phoenix.Component) | transform | (no in-repo analog — greenfield; RESEARCH Pattern 1) | no-analog |
| `accrue/lib/accrue/invoices/layouts.ex` | component (Phoenix.Component print shell) | transform | same greenfield; steal `brand_style/1` helper shape from `Accrue.Config.dunning/0` pattern | no-analog |
| `accrue/lib/accrue/invoices/styles.ex` | utility (style map lookup) | transform | (none — 30-line helper) | no-analog |
| `accrue/lib/accrue/emails/html_bridge.ex` | utility (HEEx → string) | transform | (no in-repo analog — follow RESEARCH Pattern 1 verbatim) | no-analog |
| `accrue/lib/accrue/emails/fixtures.ex` | test support / dev data | transform | `accrue/lib/accrue/test/factory.ex` + `accrue/test/support/webhook_fixtures.ex` | role-match |
| `accrue/lib/accrue/emails/receipt.ex` (+ 11 siblings) | component (email type module) | transform | `accrue/lib/accrue/emails/payment_succeeded.ex` | exact |
| `accrue/lib/accrue/mailer/test.ex` | behaviour adapter | event-driven (send self()) | `accrue/lib/accrue/pdf/test.ex` + `accrue/lib/accrue/mailer/default.ex` | exact (PDF.Test mirror) |
| `accrue/lib/accrue/pdf/null.ex` | behaviour adapter | request-response (error-only) | `accrue/lib/accrue/pdf/test.ex` (minimal behaviour impl) | exact |
| `accrue/lib/accrue/error/pdf_disabled.ex` (or add to `errors.ex`) | model (defexception) | — | `accrue/lib/accrue/errors.ex` `Accrue.Error.NotAttached` / `Accrue.Error.InvalidState` | exact |
| `accrue/lib/accrue/storage.ex` | behaviour (facade) | CRUD | `accrue/lib/accrue/pdf.ex` (behaviour + `impl/0` facade) | exact |
| `accrue/lib/accrue/storage/null.ex` | behaviour adapter | no-op | `accrue/lib/accrue/pdf/null.ex` (once built) / `accrue/lib/accrue/auth/default.ex` | exact |
| `accrue/lib/accrue/test/mailer_assertions.ex` | test support (ExUnit helpers) | event-driven (assert_received) | (no in-repo analog — mirror `assert_received` idiom; symmetric with D-34 `{:pdf_rendered, ...}`) | role-match |
| `accrue/lib/accrue/test/pdf_assertions.ex` | test support | event-driven | same as above | role-match |
| `accrue/lib/mix/tasks/accrue.mail.preview.ex` | mix task (dev tool) | file-I/O | `accrue/lib/mix/tasks/accrue.webhooks.replay.ex` | exact |
| `accrue/priv/repo/migrations/<ts>_add_locale_and_timezone_to_customers.exs` | migration | DDL | `accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs` | exact |
| `accrue/priv/accrue/templates/emails/<type>.mjml.eex` (×13) | template | — | `accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex` | exact |
| `accrue/priv/accrue/templates/emails/<type>.text.eex` (×13) | template | — | `accrue/priv/accrue/templates/emails/payment_succeeded.text.eex` | exact |
| `accrue/priv/accrue/templates/layouts/transactional.mjml.eex` | template (shared layout) | — | same `.mjml.eex` shape | role-match |
| `accrue/priv/accrue/templates/layouts/transactional.text.eex` | template | — | same | role-match |
| `accrue/priv/accrue/templates/pdf/invoice.html.heex` | template (print shell) | — | (none — greenfield HEEx; component assembly only) | no-analog |

### Modified files

| File | Change | Analog for the change |
|------|--------|-----------------------|
| `accrue/lib/accrue/config.ex` | Add nested `:branding` keyword_list schema + `branding/0` + `branding/1` + `validate_hex/1` | Existing `:dunning` + `:connect` nested schemas at `config.ex:175-189` and `:219-239`; `dunning/0` helper at `:380`; `connect/0` helper at `:390`; `validate_descending/1` validator at `:426` |
| `accrue/lib/accrue/billing/customer.ex` | Add `preferred_locale` + `preferred_timezone` string fields + cast fields | Existing `@cast_fields` list at `customer.ex:68-73`; field declarations at `:46-56` |
| `accrue/lib/accrue/billing.ex` | `defdelegate render_invoice_pdf`, `store_invoice_pdf`, `fetch_invoice_pdf` | Existing delegate pattern at `billing.ex:59-89` |
| `accrue/lib/accrue/workers/mailer.ex` | Add MFA rung 2 + full 13-type `default_template/1` catalogue + DB-hydrating `enrich/2` + locale/TZ precedence ladder | Extending existing `resolve_template/1` at `workers/mailer.ex:57-64`, `default_template/1` at `:66-72`, `enrich/2` at `:76` |
| `accrue/lib/accrue/errors.ex` | Append `Accrue.Error.PdfDisabled` defexception (co-located with siblings) | Existing `Accrue.Error.NotAttached` at `errors.ex:140-154`, `Accrue.Error.InvalidState` at `:124-138` |

---

## Pattern Assignments

### `accrue/lib/accrue/mailer/test.ex` — behaviour-layer test adapter (D6-05)

**Analogs:** `accrue/lib/accrue/pdf/test.ex` (mirror) + `accrue/lib/accrue/mailer/default.ex` (same behaviour).

**Imports + behaviour pattern** (from `pdf/test.ex:1-18`):
```elixir
defmodule Accrue.PDF.Test do
  @moduledoc "..."

  @behaviour Accrue.PDF

  @impl true
  def render(html, opts) when is_binary(html) and is_list(opts) do
    send(self(), {:pdf_rendered, html, opts})
    {:ok, "%PDF-TEST"}
  end
end
```

**What to copy:** `@behaviour Accrue.Mailer` + `@impl true def deliver(type, assigns) when is_atom(type) and is_map(assigns)` + `send(self(), {:accrue_email_delivered, type, assigns})` + `{:ok, :test}`. Zero Oban interaction — symmetric with PDF.Test. Do NOT inherit the `only_scalars!/1` check from `mailer/default.ex:50-80`; that's `Default`'s job and the test adapter bypasses it intentionally.

**Message tuple convention:** mirror D-34's `{:pdf_rendered, html, opts}` — every Accrue test adapter sends a 3-tuple starting with a `:*_rendered`/`:*_delivered` atom to `self()`.

---

### `accrue/lib/accrue/pdf/null.ex` — D6-06 returns `PdfDisabled`

**Analog:** `accrue/lib/accrue/pdf/test.ex:1-18` (minimal behaviour impl). Same shape, different return.

**Core pattern:**
```elixir
defmodule Accrue.PDF.Null do
  @moduledoc "..."

  @behaviour Accrue.PDF
  require Logger

  @impl true
  def render(_html, _opts) do
    Logger.debug("Accrue.PDF.Null: skipping PDF render (adapter disabled)")
    {:error,
     %Accrue.Error.PdfDisabled{
       reason: :adapter_disabled,
       docs_url: "https://hexdocs.pm/accrue/pdf.html#null-adapter"
     }}
  end
end
```

**Log level:** `:debug` (CONTEXT D6-06 — host opted in explicitly). Do NOT use `:info`/`:warning`.

---

### `accrue/lib/accrue/error/pdf_disabled.ex` (or appended to `errors.ex`)

**Analog:** `accrue/lib/accrue/errors.ex:140-154` (`Accrue.Error.NotAttached`) + `:124-138` (`Accrue.Error.InvalidState`).

**Pattern to copy verbatim:**
```elixir
defmodule Accrue.Error.NotAttached do
  @moduledoc "..."
  defexception [:customer_id, :payment_method_id, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{customer_id: cus_id, payment_method_id: pm_id}) do
    "payment method #{inspect(pm_id)} is not attached to customer #{inspect(cus_id)}"
  end
end
```

**For PdfDisabled:** `defexception [:reason, :docs_url, :message]` + identical `message/1` two-clause override pattern. **Co-locate in `errors.ex`** with all other `Accrue.Error.*` structs — that file already houses the taxonomy; a new `error/` directory breaks precedent.

---

### `accrue/lib/accrue/storage.ex` + `accrue/lib/accrue/storage/null.ex`

**Analog:** `accrue/lib/accrue/pdf.ex:1-57` (behaviour + facade + `impl/0`).

**Behaviour facade pattern** (from `pdf.ex:22-56`):
```elixir
@type html :: binary()
@type opts :: keyword()

@callback render(html(), opts()) :: {:ok, binary()} | {:error, term()}

@spec render(html(), opts()) :: {:ok, binary()} | {:error, term()}
def render(html, opts \\ []) when is_binary(html) and is_list(opts) do
  adapter = impl()
  metadata = %{size: opts[:size], archival: opts[:archival] == true, adapter: adapter}

  Accrue.Telemetry.span([:accrue, :pdf, :render], metadata, fn ->
    adapter.render(html, opts)
  end)
end

@doc false
def impl, do: Application.get_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)
```

**What to copy for `Accrue.Storage`:**
- Three `@callback`s (`put/3`, `get/1`, `delete/1`) per CONTEXT D6-04.
- A matching three facade functions wrapping `Accrue.Telemetry.span([:accrue, :storage, :put|:get|:delete], ...)`.
- `impl/0` helper reading `Application.get_env(:accrue, :storage_adapter, Accrue.Storage.Null)`.
- Add `:storage_adapter` key to `Accrue.Config` schema (default `Accrue.Storage.Null`) alongside existing `:pdf_adapter` at `config.ex:24-28`.

**For `Accrue.Storage.Null`:** mirror `Accrue.PDF.Null` shape — `@behaviour Accrue.Storage`, all three callbacks return `{:error, :not_configured}` (CONTEXT D6-04 `fetch_invoice_pdf` example) except `put/3` which returns `{:ok, "invoices/<id>.pdf"}` as a no-op key echo.

---

### `accrue/lib/accrue/emails/<type>.ex` (13 modules)

**Analog:** `accrue/lib/accrue/emails/payment_succeeded.ex` (the reference). Copy verbatim, rename template path and subject.

**Full pattern** (from `emails/payment_succeeded.ex:27-50`):
```elixir
defmodule Accrue.Emails.PaymentSucceeded do
  @moduledoc "..."

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/payment_succeeded.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(_assigns), do: "Receipt for your payment"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/payment_succeeded.mjml.eex")
  end

  defp to_keyword(map) do
    Enum.map(map, fn
      {k, v} when is_atom(k) -> {k, v}
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
    end)
  end
end
```

**Per-type customization surface:** `subject/1` clause matches on assigns (e.g., `def subject(%{context: %{invoice: %{number: n}}}), do: "Payment received — Invoice #{n}"`); the relative template path changes; `render_text/1` is mechanical and can be extracted to a shared `Accrue.Emails.TextRenderer.render/2` helper if the planner wants to DRY it.

**WARNING (Pitfall #1):** Do NOT `import Phoenix.Component` inside these modules — mjml_eex is not HEEx-based. Route component rendering through `Accrue.Emails.HtmlBridge` (Pattern 1 in RESEARCH.md).

---

### `accrue/lib/accrue/emails/fixtures.ex`

**Analog:** `accrue/lib/accrue/test/factory.ex:1-65` (canned per-scenario builders, safe to ship in `lib/` not `test/`).

**What to copy:** moduledoc justifying "fixtures live in `lib/` so mix task + Phase 7 LiveView can reach them" (mirrors `factory.ex:20-22`); one function per email type returning a plain map of canned assigns; no DB side effects (unlike Factory's `Repo.insert!`); deterministic values so snapshot tests stay stable.

**Shape:**
```elixir
defmodule Accrue.Emails.Fixtures do
  @moduledoc """
  Canned assigns for every `Accrue.Emails.*` type. Used by
  `mix accrue.mail.preview`, unit tests, and (Phase 7) the LiveView
  preview route. Zero side effects; pure data.
  """

  def receipt, do: %{context: render_context_fixture(), ...}
  def payment_failed, do: %{...}
  # ...
end
```

---

### `accrue/lib/accrue/workers/mailer.ex` — EXTEND

**Analog:** the file itself at `accrue/lib/accrue/workers/mailer.ex:57-94`. Do not rewrite — extend in place.

**1. MFA rung 2 inside `resolve_template/1`** (extend the existing `case Keyword.fetch(overrides, type)` block at lines 60-63):
```elixir
case Keyword.fetch(overrides, type) do
  {:ok, mod} when is_atom(mod) -> mod
  {:ok, {mod, fun, args}} -> apply(mod, fun, [type | args])  # NEW: rung 2
  :error -> default_template(type)
end
```

**2. Full `default_template/1` catalogue** (replace the single clause at line 66):
```elixir
defp default_template(:receipt),              do: Accrue.Emails.Receipt
defp default_template(:payment_failed),       do: Accrue.Emails.PaymentFailed
defp default_template(:trial_ending),         do: Accrue.Emails.TrialEnding
# ... 13 total
defp default_template(:payment_succeeded),    do: Accrue.Emails.PaymentSucceeded  # legacy alias
```

**3. Replace pass-through `enrich/2`** at line 76 with the D6-03 locale/TZ precedence ladder + DB rehydration. Precedence: caller assigns > customer column > application default > hardcoded. Wrap `Cldr.*` / `DateTime.shift_zone/3` in `try/rescue` per Pitfall #5 and emit `[:accrue, :email, :locale_fallback]` telemetry.

**4. Preserve `atomize_known_keys/1`** at lines 82-94 — the `String.to_existing_atom/1` + `ArgumentError` rescue is the locked pattern (CONTEXT Anti-Pattern: never `String.to_atom/1` on untrusted keys).

---

### `accrue/lib/accrue/invoices/render.ex`

**Analog:** `accrue/lib/accrue/billing/invoice_projection.ex` (hydration from events + DB) + `accrue/lib/accrue/workers/mailer.ex` `enrich/2` (the D6-03 locale/TZ ladder).

**Public API shape** (CONTEXT D6-04):
```elixir
@spec build_assigns(invoice_id :: String.t() | Invoice.t(), keyword()) :: RenderContext.t()
def build_assigns(invoice_or_id, opts \\ [])

@spec format_money(integer(), atom(), String.t()) :: String.t()
def format_money(minor, currency, locale)  # rescue → fallback locale per Pitfall #5
```

**What to copy from `invoice_projection.ex`:** DB-fetch + preload pattern for invoice + line items. What to copy from `workers/mailer.ex`: the enrich-once discipline (freeze branding into the RenderContext per Pitfall #8; never re-read `Accrue.Config.branding/0` downstream).

**Money formatting:** use `Accrue.Money.to_string/1` (wrapping `Money.to_string/2` with `:locale` opt) via `Accrue.Cldr` — NEVER hand-roll minor→major division (CLAUDE.md "Don't Hand-Roll"; zero-decimal + three-decimal currencies break naive `/100`).

---

### `accrue/lib/accrue/invoices/render_context.ex`

**Analog:** `accrue/lib/accrue/money.ex:36-39` — `@enforce_keys` + `defstruct` + `@type t :: %__MODULE__{...}`.

**Pattern:**
```elixir
defmodule Accrue.Invoices.RenderContext do
  @enforce_keys [:invoice, :customer, :branding, :locale, :timezone, :currency]
  defstruct [:invoice, :customer, :line_items, :subtotal_minor, :discount_minor,
             :tax_minor, :total_minor, :currency, :branding, :locale, :timezone,
             :now, :hosted_invoice_url, :receipt_url, :formatted_total,
             :formatted_subtotal, :formatted_issued_at]

  @type t :: %__MODULE__{...}
end
```

Pre-format money/date strings into the struct (CONTEXT D6-01) — keeps CLDR off the hot template path.

---

### `accrue/lib/accrue/invoices/components.ex` + `layouts.ex`

**Analog:** no in-repo precedent — Accrue core is LiveView-free (admin-only per CLAUDE.md). Follow RESEARCH Pattern 1 verbatim.

**Required imports:** `use Phoenix.Component` (already a transitive dep through phoenix_html). Every component takes a single `attr :context, :map, required: true` assign and inlines its own styles via `brand_style/1` (Pitfall #2 — `<mj-raw>` bypasses MJML style inlining).

**Naming:** function components `invoice_header/1`, `line_items/1`, `totals/1`, `footer/1` in `Accrue.Invoices.Components`; `print_shell/1` in `Accrue.Invoices.Layouts` (HEEx wrapper applying print CSS + page size helpers — but NOT `@page` CSS, Pitfall #6; use ChromicPDF `:size` option on the adapter instead).

---

### `accrue/lib/accrue/test/mailer_assertions.ex`

**Analog:** no direct in-repo precedent. The shape to emulate is `ExUnit.Assertions.assert_received/2` (stdlib).

**Public API** (CONTEXT D6-05):
```elixir
defmodule Accrue.Test.MailerAssertions do
  @moduledoc "ExUnit-style assertions for Accrue.Mailer.Test captures."

  import ExUnit.Assertions

  defmacro assert_email_sent(type, opts \\ [], timeout \\ 100) do
    quote do
      assert_receive {:accrue_email_delivered, unquote(type), assigns}, unquote(timeout)
      Accrue.Test.MailerAssertions.__match__(assigns, unquote(opts))
    end
  end

  def __match__(assigns, opts) do
    # :to, :customer_id, :assigns (subset via Map.take/2), :matches (1-arity fn)
  end
end
```

**Matching rules** (locked in CONTEXT D6-05):
- `:to` matches `assigns[:to] || assigns["to"]`
- `:customer_id` matches `assigns[:customer_id]`
- `:assigns` is a subset match: `Map.take(captured, Map.keys(expected)) == expected`
- `:matches` is a 1-arity fn escape hatch

**Symmetric file `test/pdf_assertions.ex`** consumes `{:pdf_rendered, html, opts}` sent by `Accrue.PDF.Test`.

---

### `accrue/lib/mix/tasks/accrue.mail.preview.ex`

**Analog:** `accrue/lib/mix/tasks/accrue.webhooks.replay.ex:1-55` (OptionParser + `Mix.Task.run("app.start")` + `Mix.shell().info/1` + `Mix.raise/1`).

**Pattern to copy** (from `accrue.webhooks.replay.ex:27-55`):
```elixir
use Mix.Task

@switches [only: :string, format: :string]

@impl Mix.Task
def run(argv) do
  Mix.Task.run("app.start")
  {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)
  # ...
end
```

**Directory convention:** write outputs to `.accrue/previews/{type}.{html,txt,pdf}` (CONTEXT D6-08); add `.accrue/` to `mix accrue.install`'s generated `.gitignore`.

---

### Migration `<ts>_add_locale_and_timezone_to_customers.exs`

**Analog:** `accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs` (exact precedent — `alter table` adding nullable string columns with a matching moduledoc linking the decision ID).

**Pattern:**
```elixir
defmodule Accrue.Repo.Migrations.AddLocaleAndTimezoneToCustomers do
  @moduledoc """
  Phase 6 (06-01) — per-customer locale + timezone columns (D6-03).

  Both nullable; resolved via Accrue.Workers.Mailer.enrich/2 precedence
  ladder. No data backfill required.
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_customers) do
      add :preferred_locale,   :string, size: 35
      add :preferred_timezone, :string, size: 64
    end
  end
end
```

No index (neither column is a query predicate in v1.0).

---

### `accrue/lib/accrue/billing/customer.ex` — MODIFY

**Analog:** the file itself.

- Add `field :preferred_locale, :string` and `field :preferred_timezone, :string` inside the `schema` block (after line 54 `field :metadata, :map, default: %{}`).
- Append `preferred_locale preferred_timezone` to `@cast_fields` at lines 68-73.
- Do NOT add `validate_inclusion` — library cannot know which locales the host's CLDR backend compiled (CONTEXT D6-03).
- Preserve `Metadata.validate_metadata/2` + `optimistic_lock/2` + the composite unique constraint.

---

### `accrue/lib/accrue/billing.ex` — ADD delegates

**Analog:** existing delegate block at `billing.ex:59-89`.

**Add three delegates:**
```elixir
defdelegate render_invoice_pdf(invoice, opts \\ []), to: Accrue.Invoices.Render
defdelegate store_invoice_pdf(invoice), to: Accrue.Invoices.Render
defdelegate fetch_invoice_pdf(invoice), to: Accrue.Invoices.Render
```

Implementation lives in `Accrue.Invoices.Render` (or split into `Accrue.Invoices` facade). `store_*` / `fetch_*` forward to `Accrue.Storage.impl()`; the `Null` adapter returns `{:error, :not_configured}` (CONTEXT D6-04).

---

### `accrue/lib/accrue/config.ex` — MODIFY (schema + helpers)

**Analog:** existing `:dunning` schema at `config.ex:175-189`, `:connect` nested schema at `:219-239`, `dunning/0` helper at `:380`, `connect/0` helper at `:390`, `validate_descending/1` validator at `:426-449`.

**Pattern 1 — nested `:branding` schema** (mirror `:connect` at lines 219-239):
```elixir
branding: [
  type: :keyword_list,
  default: [
    business_name: "Accrue",
    from_name: "Accrue",
    # ...
  ],
  keys: [
    business_name:   [type: :string, default: "Accrue"],
    from_email:      [type: :string, required: true],
    # ... per CONTEXT D6-02
    accent_color:    [type: {:custom, __MODULE__, :validate_hex, []}, default: "#1F6FEB"],
    # ...
  ],
  doc: "Branding config (D6-02). Single source of truth for email + PDF brand."
]
```

**Pattern 2 — `branding/0` + `branding/1` helpers** (mirror `dunning/0` at line 380, `connect/0` at line 390):
```elixir
@spec branding() :: keyword()
def branding, do: get!(:branding)

@spec branding(atom()) :: term()
def branding(key), do: Keyword.fetch!(branding(), key)
```

**Pattern 3 — `validate_hex/1`** (mirror `validate_descending/1` at lines 426-449):
```elixir
@spec validate_hex(term()) :: {:ok, String.t()} | {:error, String.t()}
def validate_hex("#" <> rest = full) when byte_size(rest) in [3, 6, 8] do
  if rest =~ ~r/\A[0-9a-fA-F]+\z/ do
    {:ok, full}
  else
    {:error, "expected a hex color (#rgb, #rrggbb, or #rrggbbaa), got: #{inspect(full)}"}
  end
end
def validate_hex(other), do: {:error, "expected a hex color string, got: #{inspect(other)}"}
```

**Deprecation shim for 6 flat keys:** Warn at boot from `Accrue.Application` (find the existing config validator slot — the same slot that will gain Pitfall #4/Pitfall #5 boot checks). Remove pre-1.0.

---

### Email templates `priv/accrue/templates/emails/<type>.mjml.eex`

**Analog:** `accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex` (entire file — 27 lines).

**What to copy:** MJML scaffold `<mjml><mj-head><mj-title>…</mj-title><mj-attributes>…</mj-attributes></mj-head><mj-body>…</mj-body></mjml>`. Font family, text color, background color from the existing file. Replace static copy with `@context.*` reads; embed shared HEEx components via `<mj-raw><%= Accrue.Emails.HtmlBridge.render(&Accrue.Invoices.Components.invoice_header/1, @context) %></mj-raw>`.

---

## Shared Patterns

### Shared Pattern 1: Behaviour + `impl/0` facade + telemetry span

**Sources:** `accrue/lib/accrue/pdf.ex:1-57`, `accrue/lib/accrue/mailer.ex:1-67`, `accrue/lib/accrue/auth.ex:1-65`.

**Apply to:** `Accrue.Storage`, and any other new behaviour.

**Required structure:**
1. `@callback` for each behaviour function with `{:ok, _} | {:error, term()}` return.
2. Matching public facade function wrapping `Accrue.Telemetry.span([:accrue, :<domain>, :<op>], metadata, fn -> impl().<fn>(args) end)`.
3. `@doc false def impl, do: Application.get_env(:accrue, :<adapter_key>, DefaultAdapter)`.
4. Metadata map MUST NOT include PII (html bodies, assigns) — `pdf.ex:43-48` is the canonical example.

---

### Shared Pattern 2: Nested config schema + helper trio

**Source:** `accrue/lib/accrue/config.ex:175-189` (`:dunning`), `:219-239` (`:connect`), `:380` (`dunning/0`), `:390` (`connect/0`), `:426-449` (`validate_descending/1`).

**Apply to:** `:branding` schema + `branding/0` + `branding/1` + `validate_hex/1`.

Every new nested config key in Accrue follows this exact trio: (1) `keys:` sub-schema with `:custom` validators where needed, (2) zero-arg helper returning the full keyword list, (3) arity-1 helper for single-key `Keyword.fetch!` lookups.

---

### Shared Pattern 3: `Accrue.Error.*` taxonomy

**Source:** `accrue/lib/accrue/errors.ex:106-190` (`MultiItemSubscription`, `InvalidState`, `NotAttached`, `NoDefaultPaymentMethod`).

**Apply to:** `Accrue.Error.PdfDisabled` (CONTEXT D6-06).

**Required shape:**
```elixir
defexception [:field1, :field2, :message]

@impl true
def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
def message(%__MODULE__{field1: a, field2: b}), do: "<fallback string>"
```

**Co-location:** append to `errors.ex` with the other `Accrue.Error.*` structs. Do not create a new `lib/accrue/error/` directory — breaks precedent.

---

### Shared Pattern 4: Oban-safe scalar assigns + `String.to_existing_atom/1`

**Source:** `accrue/lib/accrue/mailer/default.ex:50-80` (`only_scalars!/1`) + `accrue/lib/accrue/workers/mailer.ex:82-94` (`atomize_known_keys/1`).

**Apply to:** `Accrue.Workers.Mailer.enrich/2` extension; any new enrich/rehydrate helper.

**Rules:**
- Pass entity IDs through `Accrue.Mailer.deliver/2`, never `%Ecto.Schema{}` structs (D-27).
- Rehydrate from DB inside the worker (`enrich/2`) after `String.to_existing_atom/1` — never `String.to_atom/1` on untrusted input.
- Rescue `ArgumentError` and drop unknown keys from the atom-keyed view (existing pattern at `workers/mailer.ex:88-93`).

---

### Shared Pattern 5: Test adapter send-to-self convention

**Source:** `accrue/lib/accrue/pdf/test.ex:14-17` (`send(self(), {:pdf_rendered, html, opts})`).

**Apply to:** `Accrue.Mailer.Test`.

**Rules:**
- 3-tuple starts with a `:*_rendered` / `:*_delivered` atom.
- Return `{:ok, <sentinel>}` so the caller's happy-path pattern match still works (`{:ok, "%PDF-TEST"}`, `{:ok, :test}`).
- Zero Oban / zero side-effect-outside-self. Makes `async: true` ExUnit safe.

---

### Shared Pattern 6: Telemetry event naming

**Sources:**
- `accrue/lib/accrue/mailer.ex:44` — `[:accrue, :mailer, :deliver]` (span)
- `accrue/lib/accrue/pdf.ex:50` — `[:accrue, :pdf, :render]` (span)

**Apply to:** New events this phase introduces:
- `[:accrue, :email, :locale_fallback]` (CONTEXT D6-03)
- `[:accrue, :storage, :put | :get | :delete]` (span, via `Storage` facade)
- `[:accrue, :email, :branding_snapshot]` (optional, for Pitfall #8 debugging)

**Rules (from `mailer.ex:17-24`):** Raw assigns and rendered bodies NEVER enter metadata. Customer ID is acceptable; PII strings (email address, amounts pre-formatted, invoice numbers) are not.

---

## No Analog Found

| File | Role | Data Flow | Mitigation |
|------|------|-----------|------------|
| `accrue/lib/accrue/invoices/components.ex` | Phoenix.Component library | transform | Greenfield — Accrue core has no LiveView/Component usage yet. Follow RESEARCH Pattern 1 (`invoice_header/1` example, lines 576-590). `use Phoenix.Component` is the only `use` directive. |
| `accrue/lib/accrue/invoices/layouts.ex` | HEEx print shell | transform | Greenfield — RESEARCH Architecture §Pattern 2. `print_shell/1` must pass paper size via ChromicPDF options, not `@page` CSS (Pitfall #6). |
| `accrue/lib/accrue/emails/html_bridge.ex` | HEEx → safe string | transform | Greenfield — RESEARCH Pattern 1 (lines 322-353). Spike the exact `Phoenix.HTML.Safe.to_iodata/1` call path before Wave 2 starts (RESEARCH `[ASSUMED]` flag at line 354). |
| `accrue/lib/accrue/test/mailer_assertions.ex` + `pdf_assertions.ex` | ExUnit assertion helpers | event-driven | No in-repo precedent. Follow stdlib `ExUnit.Assertions.assert_received/2` + `defmacro` wrapping `quote do assert_receive … end`. |
| `accrue/priv/accrue/templates/pdf/invoice.html.heex` | HEEx print template | — | Greenfield — first HEEx template in `priv/accrue/templates/`. Pure component assembly: `<.print_shell><.invoice_header /><.line_items /><.totals /><.footer /></.print_shell>`. |
| `accrue/lib/accrue/invoices/styles.ex` | brand style map | transform | Greenfield, trivial — `def for(:logo_cell, branding), do: "padding: 24px; …"` static lookup. |

---

## Metadata

**Analog search scope:**
- `accrue/lib/accrue/` (all subdirs)
- `accrue/lib/mix/tasks/`
- `accrue/priv/accrue/templates/`
- `accrue/priv/repo/migrations/`
- `accrue/test/support/`

**Files scanned (fully read):** 14
- `accrue/lib/accrue/emails/payment_succeeded.ex`
- `accrue/lib/accrue/mailer.ex`, `mailer/default.ex`, `mailer/swoosh.ex`
- `accrue/lib/accrue/workers/mailer.ex`
- `accrue/lib/accrue/pdf.ex`, `pdf/chromic_pdf.ex`, `pdf/test.ex`
- `accrue/lib/accrue/errors.ex`
- `accrue/lib/accrue/config.ex` (partial — schema + helpers)
- `accrue/lib/accrue/billing/customer.ex`
- `accrue/lib/accrue/auth.ex`
- `accrue/lib/accrue/money.ex`
- `accrue/lib/accrue/cldr.ex`
- `accrue/lib/mix/tasks/accrue.webhooks.prune.ex`, `accrue.webhooks.replay.ex`
- `accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs`
- `accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex`
- `accrue/lib/accrue/test/factory.ex`

**Pattern extraction date:** 2026-04-15

**Key insight:** Phase 6 is unusually analog-rich because Phase 1 shipped the full scaffolding. Every behaviour adapter has an in-repo twin (`pdf/test.ex` → `mailer/test.ex`, `pdf.ex` → `storage.ex`), every email type is a verbatim copy of `payment_succeeded.ex`, every config change has a locked `:dunning`/`:connect` precedent, and every migration follows the Phase 4 alter-table template. The only genuinely greenfield surface is the `Accrue.Invoices.Components` HEEx library — this is the phase's single spike risk and should be validated at the start of Wave 2 (RESEARCH `[ASSUMED]` at line 354).
