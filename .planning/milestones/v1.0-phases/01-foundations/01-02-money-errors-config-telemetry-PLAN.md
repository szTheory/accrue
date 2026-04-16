---
phase: 01-foundations
plan: 02
type: execute
wave: 1
depends_on: [01]
files_modified:
  - accrue/lib/accrue/money.ex
  - accrue/lib/accrue/money/mismatched_currency_error.ex
  - accrue/lib/accrue/ecto/money.ex
  - accrue/lib/accrue/errors.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/telemetry.ex
  - accrue/lib/accrue/actor.ex
  - accrue/test/accrue/money_test.exs
  - accrue/test/accrue/money_property_test.exs
  - accrue/test/accrue/errors_test.exs
  - accrue/test/accrue/config_test.exs
  - accrue/test/accrue/telemetry_test.exs
autonomous: true
requirements: [FND-01, FND-02, FND-03, FND-04, OBS-01, OBS-06]
security_enforcement: enabled
tags: [elixir, money, errors, config, telemetry, value-types]
must_haves:
  truths:
    - "Accrue.Money.new(1000, :usd) returns a %Accrue.Money{amount_minor: 1000, currency: :usd}"
    - "Accrue.Money.new(100, :jpy) round-trips correctly as a zero-decimal currency"
    - "Accrue.Money.new(1000, :kwd) round-trips correctly as a three-decimal currency"
    - "Accrue.Money.new(1000.5, :usd) raises ArgumentError (floats rejected)"
    - "Accrue.Money.new(Decimal.new(\"10.50\"), :usd) raises ArgumentError (Decimal must go through from_decimal/2)"
    - "Accrue.Money.add/2 on mismatched currencies raises Accrue.Money.MismatchedCurrencyError"
    - "Accrue.Ecto.Money.money_field(:price) macro expands to TWO columns (:price_amount_minor :bigint + :price_currency :string) plus a virtual :price accessor, satisfying D-02"
    - "Every Accrue error (CardError, RateLimitError, SignatureError, APIError, IdempotencyError, DecodeError, ConfigError) is pattern-matchable via struct and implements Exception"
    - "Accrue.SignatureError raises (never returns tuple per D-08)"
    - "Accrue.Config schema contains every Phase 1 config key (:repo, :processor, :mailer, :mailer_adapter, :pdf_adapter, :auth_adapter, :stripe_secret_key, :stripe_api_version, :emails, :email_overrides, :attach_invoice_pdf, :enforce_immutability, brand fields) so Plans 04/05 only READ it"
    - "Accrue.Config.validate!/1 raises on invalid options with NimbleOptions-generated error message"
    - "Accrue.Config module docstring contains the NimbleOptions.docs-generated option table"
    - "Accrue.Telemetry.span/3 wraps a function call emitting [:accrue, domain, resource, action, :start|:stop|:exception]"
    - "Accrue.Telemetry.current_trace_id/0 returns nil when :opentelemetry is not loaded"
  artifacts:
    - path: "accrue/lib/accrue/money.ex"
      provides: "Money value type with new/2, from_decimal/2, add/2, subtract/2, equal?/2"
      contains: "defmodule Accrue.Money"
    - path: "accrue/lib/accrue/ecto/money.ex"
      provides: "Custom Ecto.Type (single-column jsonb form) AND the money_field/1 macro (two-column canonical form per D-02)"
      contains: "defmacro money_field"
    - path: "accrue/lib/accrue/errors.ex"
      provides: "All 7 defexception structs"
      contains: "defexception"
      min_lines: 80
    - path: "accrue/lib/accrue/config.ex"
      provides: "NimbleOptions-backed runtime config with FULL Phase 1 schema + validate! + get!"
      contains: "NimbleOptions.docs"
    - path: "accrue/lib/accrue/telemetry.ex"
      provides: "span/3 wrapper + event naming + current_trace_id/0"
      contains: ":telemetry.span"
    - path: "accrue/lib/accrue/actor.ex"
      provides: "Process-dict actor context (put_current/1, current/0) for Events.record in Plan 03"
  key_links:
    - from: "accrue/lib/accrue/money.ex"
      to: "ex_money"
      via: "Money.Currency.exponent/1 for zero/three-decimal handling"
      pattern: "Money\\.Currency"
    - from: "accrue/lib/accrue/telemetry.ex"
      to: ":telemetry.span/3"
      via: "direct call"
      pattern: ":telemetry\\.span"
    - from: "accrue/lib/accrue/config.ex"
      to: "NimbleOptions"
      via: "NimbleOptions.validate! + NimbleOptions.docs"
      pattern: "NimbleOptions\\."
---

<objective>
Ship the four foundational value types and instrumentation primitives every downstream module consumes: `Accrue.Money` (FND-01) **including the two-column `money_field/1` macro per D-02**, the `Accrue.Error` hierarchy (FND-02 + OBS-06), `Accrue.Config` (FND-03) **with the FULL Phase 1 schema so Plans 04/05 never touch config.ex**, and `Accrue.Telemetry` (FND-04 + OBS-01).

Purpose: Plans 03, 04, 05 cannot emit events, raise typed errors, validate config, or span telemetry without these modules. This plan is the single largest lever on Phase 1. Crucially, this plan is the ONE AND ONLY editor of `accrue/lib/accrue/config.ex` in Phase 1 — downstream plans READ keys via `Application.get_env/3` only.
Output: Four `lib/accrue/*.ex` modules + an `Accrue.Actor` helper + the `Accrue.Ecto.Money` Ecto.Type AND `money_field/1` macro, plus property tests for Money math per D-04 and unit tests for the error/config/telemetry layers.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/01-foundations/01-CONTEXT.md
@.planning/phases/01-foundations/01-RESEARCH.md
@CLAUDE.md
@accrue/mix.exs
@accrue/config/config.exs

<interfaces>
<!-- Contracts this plan CREATES. Downstream plans (03/04/05/06) consume these. -->

From accrue/lib/accrue/money.ex:
```elixir
defmodule Accrue.Money do
  @type t :: %__MODULE__{amount_minor: integer(), currency: atom()}
  defstruct [:amount_minor, :currency]

  @spec new(integer(), atom()) :: t()
  def new(amount_minor, currency)

  @spec from_decimal(Decimal.t(), atom()) :: t()
  def from_decimal(decimal, currency)

  @spec add(t(), t()) :: t()                # raises MismatchedCurrencyError on mismatch
  def add(a, b)

  @spec subtract(t(), t()) :: t()
  def subtract(a, b)

  @spec equal?(t(), t()) :: boolean()
  def equal?(a, b)

  @spec to_string(t()) :: String.t()        # delegates to ex_money formatting
  def to_string(money)
end
```

From accrue/lib/accrue/ecto/money.ex (dual-shape per D-02 + Open Q5 resolution):
```elixir
defmodule Accrue.Ecto.Money do
  @moduledoc """
  TWO shapes, both shipped in Phase 1 per D-02 and RESEARCH.md Open Question 5:

  1. A custom `Ecto.Type` (single-column jsonb form) for use inside
     `accrue_events.data` and other places where money is one of many
     properties in a jsonb blob. Convenient; NOT the canonical storage.

  2. The `money_field/1` MACRO — the canonical form per D-02. Expands to
     two physical columns (`{name}_amount_minor :bigint` +
     `{name}_currency :string`) plus a virtual `{name}` accessor that
     produces a `%Accrue.Money{}` struct on load. Downstream schemas use
     this for Subscription.price, Invoice.total, etc.
  """
  use Ecto.Type

  # Ecto.Type callbacks (single-column jsonb form):
  def type, do: :map
  def cast(term)
  def dump(term)
  def load(term)

  # Two-column macro (canonical form):
  defmacro money_field(name) when is_atom(name) do
    amount_key = :"#{name}_amount_minor"
    currency_key = :"#{name}_currency"
    quote do
      field unquote(amount_key), :integer
      field unquote(currency_key), :string
      field unquote(name), :any, virtual: true
    end
  end
end
```

From accrue/lib/accrue/errors.ex (all 7 structs):
```elixir
defmodule Accrue.APIError do
  defexception [:message, :code, :http_status, :request_id, :processor_error]
end

defmodule Accrue.CardError do
  defexception [:message, :code, :decline_code, :param, :http_status, :request_id, :processor_error]
end

defmodule Accrue.RateLimitError do
  defexception [:message, :retry_after, :http_status, :request_id, :processor_error]
end

defmodule Accrue.IdempotencyError do
  defexception [:message, :idempotency_key, :processor_error]
end

defmodule Accrue.DecodeError do
  defexception [:message, :payload]
end

defmodule Accrue.SignatureError do
  defexception [:message, :reason]  # ALWAYS raised, never returned (D-08)
end

defmodule Accrue.ConfigError do
  defexception [:message, :key]
end
```

From accrue/lib/accrue/config.ex (FULL Phase 1 schema — Plans 04/05 read only):
```elixir
defmodule Accrue.Config do
  @schema [
    # Repo + adapters
    repo: [type: :atom, required: true, doc: "Host Ecto.Repo module"],
    processor: [type: :atom, default: Accrue.Processor.Fake, doc: "Processor adapter"],
    mailer: [type: :atom, default: Accrue.Mailer.Default, doc: "Mailer pipeline module"],
    mailer_adapter: [type: :atom, default: Accrue.Mailer.Swoosh, doc: "Swoosh mailer module"],
    pdf_adapter: [type: :atom, default: Accrue.PDF.ChromicPDF, doc: "PDF adapter"],
    auth_adapter: [type: :atom, default: Accrue.Auth.Default, doc: "Auth adapter"],

    # Stripe (read at runtime only by Plan 04 — NEVER compile_env)
    stripe_secret_key: [type: :string, required: false, doc: "Runtime Stripe secret; validated at boot when processor == Stripe"],
    stripe_api_version: [type: :string, default: "2026-03-25.dahlia"],

    # Email pipeline config (Plan 05 reads these)
    emails: [type: :keyword_list, default: [], doc: "Per-type kill switches + MFA callbacks (D-25)"],
    email_overrides: [type: :keyword_list, default: [], doc: "Per-type template module overrides (D-23 rung 3)"],
    attach_invoice_pdf: [type: :boolean, default: true, doc: "Auto-attach invoice PDF to receipt email (D-39)"],

    # Event ledger (Plan 03 reads this)
    enforce_immutability: [type: :boolean, default: false, doc: "If true, Plan 06 boot check raises when PG role can UPDATE accrue_events (D-10)"],

    # Brand config (Plan 05 reads these for email defaults — D-24)
    business_name: [type: :string, default: "Accrue"],
    business_address: [type: :string, default: ""],
    logo_url: [type: :string, default: ""],
    support_email: [type: :string, default: "support@example.com"],
    from_email: [type: :string, default: "noreply@example.com"],
    from_name: [type: :string, default: "Accrue"],
    default_currency: [type: :atom, default: :usd]
  ]

  @spec validate!(keyword()) :: keyword()
  def validate!(opts)

  @spec get!(atom()) :: term()   # raises Accrue.ConfigError if missing+no default
  def get!(key)

  @spec schema() :: keyword()    # exposed for Plan 06's validate_at_boot!/0
  def schema(), do: @schema
end
```

From accrue/lib/accrue/telemetry.ex:
```elixir
defmodule Accrue.Telemetry do
  @type event_name :: [atom()]   # e.g. [:accrue, :billing, :subscription, :create]

  @spec span(event_name(), map(), (-> {result, map()})) :: result when result: var
  def span(name, metadata \\ %{}, fun)

  @spec current_trace_id() :: String.t() | nil
  def current_trace_id()
end
```

From accrue/lib/accrue/actor.ex:
```elixir
defmodule Accrue.Actor do
  @type actor_type :: :user | :system | :webhook | :oban | :admin
  @type t :: %{type: actor_type(), id: String.t() | nil}

  @spec put_current(t()) :: :ok
  def put_current(actor)

  @spec current() :: t() | nil
  def current()

  @spec with_actor(t(), (-> any())) :: any()
  def with_actor(actor, fun)
end
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Accrue.Money + Accrue.Ecto.Money (Ecto.Type + money_field/1 macro) + property tests</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-01, D-02, D-03, D-04
    - .planning/phases/01-foundations/01-RESEARCH.md §Pitfall 1 (ex_money_sql composite type trap — DO NOT USE)
    - .planning/phases/01-foundations/01-RESEARCH.md §Open Question 5 (RESOLVED: ship BOTH the Ecto.Type AND the money_field/1 macro here)
    - hexdocs.pm/ex_money — Money.Currency.exponent/1 is the source of truth for zero/three-decimal handling
  </read_first>
  <files>
    accrue/lib/accrue/money.ex
    accrue/lib/accrue/money/mismatched_currency_error.ex
    accrue/lib/accrue/ecto/money.ex
    accrue/test/accrue/money_test.exs
    accrue/test/accrue/money_property_test.exs
  </files>
  <behavior>
    - `Accrue.Money.new(1000, :usd) == %Accrue.Money{amount_minor: 1000, currency: :usd}` (per D-03)
    - `Accrue.Money.new(100, :jpy)` succeeds (zero-decimal currency)
    - `Accrue.Money.new(1000, :kwd)` succeeds (three-decimal currency — KWD)
    - `Accrue.Money.new(10.5, :usd)` raises `ArgumentError` with message mentioning `from_decimal/2` (D-03)
    - `Accrue.Money.new(Decimal.new("10.50"), :usd)` raises `ArgumentError` (Decimal rejected on `new/2`)
    - `Accrue.Money.from_decimal(Decimal.new("10.50"), :usd) == %Accrue.Money{amount_minor: 1050, currency: :usd}`
    - `Accrue.Money.from_decimal(Decimal.new("100"), :jpy) == %Accrue.Money{amount_minor: 100, currency: :jpy}` (zero-decimal: no shift)
    - `Accrue.Money.add(m_usd_100, m_usd_200) == m_usd_300`
    - `Accrue.Money.add(m_usd, m_eur)` raises `Accrue.Money.MismatchedCurrencyError` (D-04)
    - **Property 1 (round-trip)**: for JPY (0-dec), USD (2-dec), KWD (3-dec), `Money.new(int, currency)` round-trips through Ecto insert/load of a schema that uses `money_field/1` and preserves exact `amount_minor` + `currency` atoms
    - **Property 2 (cross-currency raises)**: `Money.add(m1_usd, m2_eur)` always raises MismatchedCurrencyError across all generated input pairs
    - **Property 3 (integer constructor)**: `forall int, atom_currency -> Money.new(int, cur) == %Money{amount_minor: int, currency: cur}`
    - **Property 4 (float/Decimal rejection)**: `Money.new/2` with a float or Decimal always raises ArgumentError
    - `defmacro money_field(:price)` expands inside a test Ecto.Schema and produces three Ecto fields: `price_amount_minor :integer`, `price_currency :string`, `price :any, virtual: true`
  </behavior>
  <action>
1. `lib/accrue/money/mismatched_currency_error.ex`: `defmodule Accrue.Money.MismatchedCurrencyError do defexception [:left, :right, :message] ... end` with `message/1` producing "cannot combine #{left} and #{right}".

2. `lib/accrue/money.ex`:
   - `defstruct [:amount_minor, :currency]` + `@type t`.
   - `new/2` — integer+atom signature is the happy path. Validate currency via `Money.Currency.exponent(currency)` (raises on unknown). Anything else → `raise ArgumentError, "Accrue.Money.new/2 requires (integer, atom); use from_decimal/2 for Decimal conversions"` per D-03. Explicitly pattern-match `is_float(x)` and `%Decimal{}` to raise with helpful message.
   - `from_decimal/2` — uses `Money.Currency.exponent/1` to shift Decimal to minor units. USD exponent=2 → multiply by 100 and round half-even. JPY exponent=0 → keep as-is. KWD exponent=3 → multiply by 1000.
   - `add/2`, `subtract/2`: guard-match same currency; any mismatch raises `MismatchedCurrencyError`.
   - `equal?/2`: struct equality.
   - `to_string/1`: delegates to `Money.new!(currency, amount_minor_as_decimal) |> to_string()` from ex_money.

3. `lib/accrue/ecto/money.ex` — **ships BOTH shapes per D-02 + Open Q5 resolution**:
   - `use Ecto.Type` callbacks (single-column jsonb form — used inside `accrue_events.data`):
     - `type/0 -> :map`.
     - `cast/1`: accepts `%Accrue.Money{}`, `{int, atom}`, `%{"amount_minor" => _, "currency" => _}`.
     - `dump/1`: returns `{:ok, %{"amount_minor" => i, "currency" => Atom.to_string(c)}}`.
     - `load/1`: hydrates the map back to a `%Accrue.Money{}`.
   - **`defmacro money_field(name)`** — canonical two-column form:
     ```elixir
     defmacro money_field(name) when is_atom(name) do
       amount_key = :"#{name}_amount_minor"
       currency_key = :"#{name}_currency"
       quote do
         field unquote(amount_key), :integer
         field unquote(currency_key), :string
         field unquote(name), :any, virtual: true
       end
     end
     ```
     Downstream schemas in Phase 2+ will call it inside their `schema ... do` block:
     ```elixir
     schema "subscriptions" do
       import Accrue.Ecto.Money, only: [money_field: 1]
       money_field :price
     end
     ```
     The virtual field is populated in a `changeset/2` helper (documented in moduledoc) by calling `put_change(changeset, :price, Accrue.Money.new(row.price_amount_minor, String.to_existing_atom(row.price_currency)))` — but Phase 1 tests only verify macro expansion; Phase 2 wires the helper.

4. `test/accrue/money_test.exs`: unit tests covering every `<behavior>` item above (one `test` per case). Include an explicit case for the `money_field/1` macro — define an anonymous-module Ecto.Schema inline using the macro and assert `__schema__(:fields)` returns `[:id, :price_amount_minor, :price_currency, :price]`.

5. `test/accrue/money_property_test.exs`:
   - `use ExUnit.Case`, `use ExUnitProperties`.
   - **Property 1 (round-trip via money_field/1 macro)**: Define a test schema using `money_field :price`, generate random `{int, :usd | :jpy | :kwd}` tuples, insert into an in-memory changeset (no DB needed for macro round-trip — Plan 03's integration suite covers live Repo round-trip), verify `price_amount_minor` + `price_currency` columns hold the generated values exactly.
   - **Property 2 (add/2 same-currency)**: `check all a, b with same currency -> add(a, b).amount_minor == a.amount_minor + b.amount_minor`.
   - **Property 3 (add/2 cross-currency raises)**: `check all a usd, b eur -> assert_raise MismatchedCurrencyError, fn -> add(a, b) end`.
   - **Property 4 (integer constructor happy path)**: `check all int, currency from [:usd, :jpy, :kwd, :gbp, :eur] -> Money.new(int, cur).amount_minor == int`.
   - **Property 5 (Decimal/float rejection)**: `check all float <- float() -> assert_raise ArgumentError, fn -> Money.new(float, :usd) end`. Same for `Decimal.new(int) |> Money.new(:usd)`.

DO NOT import `Money.Ecto.Composite.Type` or reference `money_with_currency` PG type (Pitfall #1, A4).
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/money_test.exs test/accrue/money_property_test.exs</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/money_test.exs` reports all tests passing
    - `mix test test/accrue/money_property_test.exs` runs at least 5 properties and passes
    - `grep -q "ex_money_sql\|Money.Ecto.Composite.Type\|money_with_currency" accrue/lib/accrue/` returns nothing (Pitfall #1)
    - `grep -q "defexception" accrue/lib/accrue/money/mismatched_currency_error.ex`
    - `grep -q "defmacro money_field" accrue/lib/accrue/ecto/money.ex` (D-02 two-column canonical form)
    - Property test exercises USD / JPY / KWD round-trip through `money_field/1` macro
  </acceptance_criteria>
  <done>Money type round-trips USD/JPY/KWD correctly, mismatched-currency math raises, Decimal/float rejected on new/2, AND the money_field/1 macro ships the two-column D-02 shape. Open Question 5 fully resolved.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Accrue.Error hierarchy + Accrue.Config (FULL Phase 1 NimbleOptions schema)</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-05, D-06, D-07, D-08 (errors) and D-17, D-18 (telemetry — to inform Task 3)
    - CLAUDE.md §Config Boundaries (compile-time vs runtime)
    - hexdocs.pm/nimble_options — NimbleOptions.docs/1 pattern
  </read_first>
  <files>
    accrue/lib/accrue/errors.ex
    accrue/lib/accrue/config.ex
    accrue/test/accrue/errors_test.exs
    accrue/test/accrue/config_test.exs
  </files>
  <behavior>
    - `raise Accrue.CardError, code: "card_declined", message: "..."` works; `rescue e in Accrue.CardError -> e.code` returns "card_declined"
    - All 7 error structs implement `Exception` (verified via `Exception.exception?/1`)
    - `Accrue.SignatureError` raises — no tuple form exists anywhere in the codebase (D-08)
    - `Accrue.Config.validate!([repo: MyApp.Repo])` returns normalized keyword list
    - `Accrue.Config.validate!([])` raises because `:repo` is required
    - `Accrue.Config.validate!([repo: MyApp.Repo, processor: "not-an-atom"])` raises NimbleOptions ValidationError
    - `Accrue.Config.get!(:default_currency)` returns `:usd` (default) when unset
    - `Accrue.Config.get!(:stripe_api_version)` returns `"2026-03-25.dahlia"` (default)
    - `Accrue.Config.get!(:emails)` returns `[]` (default)
    - `Accrue.Config.get!(:nonexistent)` raises `Accrue.ConfigError`
    - `Accrue.Config.schema/0` returns the keyword list (used by Plan 06's validate_at_boot!/0)
    - `Accrue.Config` moduledoc contains the NimbleOptions-generated docs table (checked via string match on option name)
  </behavior>
  <action>
1. `lib/accrue/errors.ex`: one file, all 7 `defexception` modules per `<interfaces>` block. Each module:
   - Defines the struct fields listed.
   - Overrides `message/1` if the message can be derived from other fields (e.g., `Accrue.CardError.message/1` -> `"#{code}: #{param}"` when no explicit message).
   - `@moduledoc` one line explaining when this error is raised.

2. `lib/accrue/config.ex` — **THE ONE AND ONLY Phase 1 editor of this file**:
   - Define `@schema` module attribute with the FULL Phase 1 keyset per `<interfaces>` block. This schema is intentionally comprehensive so Plans 04 and 05 can run in parallel (Wave 2) without touching this file.
   - Add `@moduledoc "..." <> NimbleOptions.docs(@schema)`.
   - `validate!/1`: `NimbleOptions.validate!(opts, @schema)`.
   - `get!/1`: reads from `Application.get_env(:accrue, key)` — runtime lookup. Falls back to the schema default via `default_for/1`. Raises `Accrue.ConfigError, key: key, message: "..."` only if value is nil AND key is not in the schema at all.
   - `schema/0`: returns `@schema` so Plan 06's `validate_at_boot!/0` can iterate keys.
   - `default_for/1`: private helper returning the schema default for a key, or nil.
   - **Runtime-only fields**: the `stripe_secret_key` is marked in docs as runtime-only (never read via `Application.compile_env!/2`). Same for `stripe_api_version`. Per CLAUDE.md §Config Boundaries.

3. `test/accrue/errors_test.exs`: one test per error struct asserting raise/rescue + field access works, plus one test asserting `Accrue.SignatureError` has no tuple-return constructor (verified by grep + explicit assertion that the module does not export a `new/1` or `error_tuple/1`).

4. `test/accrue/config_test.exs`: tests for
   - validate! happy path
   - required-field missing (`:repo` omitted → raises)
   - type mismatch (processor as string → raises)
   - `get!/1` with default (`:default_currency` → `:usd`)
   - `get!/1` for every Phase 1 key, asserting the defaults match the `<interfaces>` block
   - `get!/1` with missing key (not in schema) → raises Accrue.ConfigError
   - `schema/0` returns a keyword list with at least 18 keys (all Phase 1 config keys)
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/errors_test.exs test/accrue/config_test.exs</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "defexception" accrue/lib/accrue/errors.ex` returns 7
    - `mix test test/accrue/errors_test.exs test/accrue/config_test.exs` reports all passing
    - `grep -q "NimbleOptions.docs" accrue/lib/accrue/config.ex`
    - `grep -q "stripe_secret_key" accrue/lib/accrue/config.ex` (schema includes it)
    - `grep -q "stripe_api_version" accrue/lib/accrue/config.ex`
    - `grep -q "mailer_adapter" accrue/lib/accrue/config.ex`
    - `grep -q "pdf_adapter" accrue/lib/accrue/config.ex`
    - `grep -q "auth_adapter" accrue/lib/accrue/config.ex`
    - `grep -q "email_overrides" accrue/lib/accrue/config.ex`
    - `grep -q "attach_invoice_pdf" accrue/lib/accrue/config.ex`
    - `grep -q "enforce_immutability" accrue/lib/accrue/config.ex`
    - `grep -q "def schema" accrue/lib/accrue/config.ex`
    - `mix compile --warnings-as-errors` passes
  </acceptance_criteria>
  <done>Seven pattern-matchable error structs AND a NimbleOptions-validated Config module with the FULL Phase 1 schema, generated docs, and a public `schema/0` accessor. Plans 04/05 can now READ every key they need without touching this file.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Accrue.Telemetry + Accrue.Actor</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-15, D-16, D-17, D-18
    - CLAUDE.md §Conditional Compilation for Optional Deps (for OTel no-op pattern on current_trace_id)
    - hexdocs.pm/telemetry — :telemetry.span/3 semantics
  </read_first>
  <files>
    accrue/lib/accrue/telemetry.ex
    accrue/lib/accrue/actor.ex
    accrue/test/accrue/telemetry_test.exs
  </files>
  <behavior>
    - `Accrue.Telemetry.span([:accrue, :test, :thing, :do], %{foo: 1}, fn -> {:ok, %{bar: 2}} end)` emits `[:accrue, :test, :thing, :do, :start]` then `[:accrue, :test, :thing, :do, :stop]` with merged metadata
    - Exception inside the fun emits `[:accrue, :test, :thing, :do, :exception]` and reraises
    - `Accrue.Telemetry.current_trace_id/0` returns `nil` when `:opentelemetry` dep is absent (Phase 1 default — no OTel configured)
    - `Accrue.Actor.put_current(%{type: :webhook, id: "evt_123"}) ; Accrue.Actor.current().type == :webhook`
    - `Accrue.Actor.with_actor(%{type: :admin, id: "u_1"}, fn -> Accrue.Actor.current().type end) == :admin` and after the block, current/0 is restored
    - Invalid actor type (e.g., `:root`) raises `ArgumentError` — the enum is fixed at `:user | :system | :webhook | :oban | :admin` per D-15
  </behavior>
  <action>
1. `lib/accrue/actor.ex`:
   - `@actor_types [:user, :system, :webhook, :oban, :admin]`.
   - `put_current/1`: validates type is in the list, stores in `Process.put(__MODULE__, actor)`.
   - `current/0`: `Process.get(__MODULE__)`.
   - `with_actor/2`: saves current, puts new, calls fun, restores in `after` block.
   - Module is pure — no side effects beyond process dictionary.

2. `lib/accrue/telemetry.ex`:
   - `span/3`: wraps `:telemetry.span/3`. The inner function must return `{result, metadata}` per `:telemetry.span` contract. Accrue's `span/3` accepts a simpler callable `(-> any)` and wraps it to return `{result, %{}}` internally. Metadata is merged with actor context from `Accrue.Actor.current/0` when present.
   - `current_trace_id/0`: uses conditional compile per CLAUDE.md Pattern 6:
     ```elixir
     if Code.ensure_loaded?(:otel_tracer) do
       def current_trace_id do
         case :otel_tracer.current_span_ctx() do
           :undefined -> nil
           ctx -> ctx |> :otel_span.trace_id() |> Integer.to_string(16)
         end
       end
     else
       def current_trace_id, do: nil
     end
     ```
   - `@compile {:no_warn_undefined, [:otel_tracer, :otel_span]}` at module top to silence the without-otel matrix warnings.
   - Module docstring documents the 4-level event naming convention `[:accrue, :domain, :resource, :action, :phase]` with concrete examples per D-17.
   - Do NOT create `Accrue.Telemetry.Metrics` in this task — D-18 makes it optional and it can land in Phase 4 with the ops metrics work. Document as future-ready.

3. `test/accrue/telemetry_test.exs`:
   - Attach a test handler via `:telemetry.attach_many/4`, call `Accrue.Telemetry.span/3`, assert both `:start` and `:stop` events fired.
   - Exception case: `assert_raise RuntimeError, fn -> Accrue.Telemetry.span(..., fn -> raise "boom" end) end` — verify `:exception` fired.
   - `current_trace_id/0` returns nil when OTel is not loaded (Phase 1 baseline).
   - Actor tests in same file or a sibling `test/accrue/actor_test.exs` (planner's discretion; keep to Task 3 scope).
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/telemetry_test.exs && mix compile --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/telemetry_test.exs` reports all passing
    - `grep -q ":telemetry.span" accrue/lib/accrue/telemetry.ex`
    - `grep -q "@compile {:no_warn_undefined" accrue/lib/accrue/telemetry.ex` (without_otel silencer)
    - `grep -q "@actor_types" accrue/lib/accrue/actor.ex`
    - `mix compile --warnings-as-errors` passes (proves the without_opentelemetry conditional compile is clean)
  </acceptance_criteria>
  <done>Telemetry span wrapper emits start/stop/exception triples, Actor context propagates via process dict, without_opentelemetry matrix entry compiles warning-free.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Caller → Accrue.Money.new/2 | Untrusted numeric input must not silently coerce |
| Processor adapter → Accrue.Error | Raw Stripe data must not leak into Error.message field |
| Caller → Accrue.Config.validate! | Invalid config must fail loud at boot, not silently at runtime |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-FND-04 | Tampering | Accrue.Money arithmetic | mitigate | Cross-currency math raises MismatchedCurrencyError (D-04, property-tested); floats/decimals rejected on `new/2` |
| T-FND-05 | Information Disclosure | Accrue.CardError.processor_error field | mitigate | Document in moduledoc that `processor_error` field may contain raw Stripe data and must NOT be logged verbatim; downstream logging sanitizer lands in Plan 06/Plan 04; for this plan, ensure the `message/1` impl only references `code`/`decline_code`/`param` (non-PII), never the raw payload |
| T-FND-06 | Denial of Service | Accrue.Config.validate! with malicious schema | accept | NimbleOptions is well-tested; schema is compile-time static |
| T-OBS-01 | Information Disclosure | Telemetry metadata leakage | mitigate | `Accrue.Telemetry.span/3` does NOT auto-include raw args in metadata; only the explicit metadata map the caller passes. Document this in the moduledoc so Plan 04 Processor.Stripe does not accidentally shove raw lattice_stripe responses into span metadata |
</threat_model>

<verification>
- `mix test test/accrue/` runs green for money, money_property, errors, config, telemetry test files
- `mix compile --warnings-as-errors` passes (conditional compile for OTel is clean)
- `grep -q "defexception" accrue/lib/accrue/errors.ex` returns 7 matches
- `grep -q "NimbleOptions.docs" accrue/lib/accrue/config.ex`
- `grep -q "defmacro money_field" accrue/lib/accrue/ecto/money.ex` (D-02 two-column shape)
- No test uses wall-clock time or touches the filesystem beyond the StreamData shrink cache
</verification>

<success_criteria>
After this plan, Plans 03/04/05 can:
- `alias Accrue.Money` and construct `Accrue.Money.new(1000, :usd)` in event data payloads
- `import Accrue.Ecto.Money, only: [money_field: 1]` in downstream schemas (Phase 2+) for D-02 two-column storage
- `raise Accrue.CardError, code: "card_declined", processor_error: raw` in Plan 04's Stripe adapter
- `Application.get_env(:accrue, :stripe_secret_key)` / `Accrue.Config.get!(:stripe_secret_key)` to read the runtime secret in Plan 04 without editing this plan's config.ex
- `Accrue.Config.get!(:emails)` / `:email_overrides` / `:mailer_adapter` / `:from_email` / `:from_name` / `:attach_invoice_pdf` in Plan 05 — all keys already in the schema
- `Accrue.Config.get!(:repo)` to resolve the host Repo module for Plan 03's event ledger inserts
- Wrap every public function in `Accrue.Telemetry.span/3` to satisfy OBS-01
- `Accrue.Actor.put_current(%{type: :webhook, id: stripe_event_id})` so Plan 03's `Events.record/1` can read actor context
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundations/01-02-SUMMARY.md`.
</output>
