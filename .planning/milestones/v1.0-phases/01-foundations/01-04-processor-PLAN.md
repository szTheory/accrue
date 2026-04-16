---
phase: 01-foundations
plan: 04
type: execute
wave: 2
depends_on: [01, 02]
files_modified:
  - accrue/lib/accrue/processor.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/lib/accrue/processor/fake/state.ex
  - accrue/lib/accrue/processor/stripe.ex
  - accrue/lib/accrue/processor/stripe/error_mapper.ex
  - accrue/test/accrue/processor/fake_test.exs
  - accrue/test/accrue/processor/stripe_test.exs
  - accrue/test/accrue/processor/behaviour_test.exs
autonomous: true
requirements: [PROC-01, PROC-03, PROC-07]
security_enforcement: enabled
tags: [elixir, processor, behaviour, stripe, fake, ets, mox]
must_haves:
  truths:
    - "Accrue.Processor is a behaviour with callbacks for the Phase 1 subset of Stripe operations (create/retrieve customer is the minimum proof surface; full set grows in Phase 3)"
    - "Accrue.Processor.Fake implements the behaviour using ETS + GenServer, produces deterministic IDs (cus_fake_00001), and supports Accrue.Processor.Fake.advance/2 for test-clock control"
    - "Accrue.Processor.Fake.reset/0 zeros all counters and clears ETS state for clean test isolation"
    - "Accrue.Processor.Stripe is the ONLY module in the codebase that imports or references LatticeStripe"
    - "Accrue.Processor.Stripe maps every possible LatticeStripe error shape to an Accrue.Error subtype with metadata preserved (OBS-06 / PROC-07)"
    - "Accrue.Processor.Stripe reads :stripe_secret_key via Application.get_env at runtime — Plan 02's Config schema already defines the key; this plan is READ-ONLY against config.ex"
    - "No module outside Accrue.Processor.Stripe grep-matches on `LatticeStripe` or `:lattice_stripe`"
    - "Mox-based test substitutes Accrue.ProcessorMock for Accrue.Processor behaviour and exercises every public callback contract"
  artifacts:
    - path: "accrue/lib/accrue/processor.ex"
      provides: "Accrue.Processor behaviour + runtime dispatch"
      contains: "@callback"
      min_lines: 60
    - path: "accrue/lib/accrue/processor/fake.ex"
      provides: "Deterministic in-memory adapter with test clock"
      contains: "GenServer"
      min_lines: 100
    - path: "accrue/lib/accrue/processor/stripe.ex"
      provides: "lattice_stripe adapter — isolated lattice_stripe import"
      contains: "LatticeStripe"
    - path: "accrue/lib/accrue/processor/stripe/error_mapper.ex"
      provides: "Maps LatticeStripe errors to Accrue.Error structs"
      contains: "Accrue.CardError"
  key_links:
    - from: "accrue/lib/accrue/processor.ex"
      to: "impl resolver"
      via: "Application.get_env(:accrue, :processor, Accrue.Processor.Fake)"
      pattern: "Application.get_env.*:processor"
    - from: "accrue/lib/accrue/processor/stripe.ex"
      to: "Accrue.Processor.Stripe.ErrorMapper"
      via: "ErrorMapper.to_accrue_error/1"
      pattern: "ErrorMapper"
    - from: "accrue/lib/accrue/processor/stripe/error_mapper.ex"
      to: "Accrue.CardError / RateLimitError / APIError / IdempotencyError / SignatureError"
      via: "struct construction from Stripe error shape"
      pattern: "Accrue\\.(Card|RateLimit|API|Idempotency|Signature)Error"
---

<objective>
Ship the `Accrue.Processor` behaviour, the primary test surface `Accrue.Processor.Fake` (deterministic IDs, test clock), and the real-world adapter `Accrue.Processor.Stripe` — which is the **only** module in the entire codebase allowed to `alias`/`import`/reference `LatticeStripe`. All Stripe errors cross this boundary and are translated into `Accrue.Error` structs so downstream code never sees raw Stripe shapes.

Purpose: This plan enforces the facade principle (D-07). If Phase 3+ ever matches on a `LatticeStripe.*` error directly, the facade has leaked. Lock it down at Phase 1.
Output: Behaviour + Fake + Stripe adapter + error mapper, with tests proving: Fake emits deterministic IDs under `Mox`-style contract tests; Stripe adapter translates every researched error shape to an Accrue error; no other module references lattice_stripe.

**Wave-2 file discipline:** This plan is READ-ONLY against `accrue/lib/accrue/config.ex` and `accrue/config/*.exs`. Plan 02 (Wave 1) already added `stripe_secret_key` and `stripe_api_version` to the Config schema. Plan 01 (Wave 0) pre-wired all config files. Plans 04 and 05 run in parallel (Wave 2) with ZERO shared files.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/01-foundations/01-CONTEXT.md
@.planning/phases/01-foundations/01-RESEARCH.md
@CLAUDE.md
@accrue/lib/accrue/errors.ex
@accrue/lib/accrue/telemetry.ex
@accrue/lib/accrue/config.ex

<interfaces>
<!-- Contracts this plan CREATES. -->

From accrue/lib/accrue/processor.ex:
```elixir
defmodule Accrue.Processor do
  @moduledoc """
  Behaviour every processor adapter must implement. Phase 1 defines only the
  callbacks needed to prove the Fake's shape and to exercise the facade.
  Phase 3 grows this to the full Stripe Billing surface (subscriptions, invoices,
  charges, payment intents, etc.).
  """

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Exception.t()}

  @callback create_customer(params(), opts()) :: result()
  @callback retrieve_customer(id(), opts()) :: result()
  @callback update_customer(id(), params(), opts()) :: result()

  # Phase 1 stops at customer operations. Phase 3 adds:
  # @callback create_subscription/2, retrieve_subscription/2, cancel_subscription/3,
  # @callback create_payment_intent/2, confirm_payment_intent/3, etc.

  @spec create_customer(params(), opts()) :: result()
  def create_customer(params, opts \\ []), do: impl().create_customer(params, opts)

  @spec retrieve_customer(id(), opts()) :: result()
  def retrieve_customer(id, opts \\ []), do: impl().retrieve_customer(id, opts)

  @spec update_customer(id(), params(), opts()) :: result()
  def update_customer(id, params, opts \\ []), do: impl().update_customer(id, params, opts)

  defp impl, do: Application.get_env(:accrue, :processor, Accrue.Processor.Fake)
end
```

From accrue/lib/accrue/processor/fake.ex:
```elixir
defmodule Accrue.Processor.Fake do
  @behaviour Accrue.Processor

  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  @spec reset() :: :ok
  @spec advance(GenServer.server(), Duration.t() | integer()) :: :ok
  @spec stub(atom(), atom(), (params, opts -> result)) :: :ok   # override specific callback for a test
  @spec current_time(GenServer.server()) :: DateTime.t()
end
```

From accrue/lib/accrue/processor/stripe.ex:
```elixir
defmodule Accrue.Processor.Stripe do
  @moduledoc """
  The ONLY module in the codebase that knows about `:lattice_stripe`. Every
  raw Stripe error surfaced through this module is translated via
  `Accrue.Processor.Stripe.ErrorMapper` into an `Accrue.Error` subtype.

  Config keys this module READS (already defined in Plan 02's schema — never written by this plan):
  - `Application.get_env(:accrue, :stripe_secret_key)` — runtime only
  - `Application.get_env(:accrue, :stripe_api_version)` — runtime only, default "2026-03-25.dahlia"
  """
  @behaviour Accrue.Processor
end
```

From accrue/lib/accrue/processor/stripe/error_mapper.ex:
```elixir
defmodule Accrue.Processor.Stripe.ErrorMapper do
  @spec to_accrue_error(term()) :: Exception.t()
  def to_accrue_error(lattice_stripe_error)
end
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Behaviour + Fake (deterministic IDs + test clock)</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-19, D-20 (test clock + deterministic IDs)
    - .planning/phases/01-foundations/01-RESEARCH.md §Pattern 1 (Behaviour + Mox pattern)
    - .planning/phases/01-foundations/01-RESEARCH.md §Assumption A3 (whether Registry is needed — planner's call)
    - hexdocs.pm/mox — Mox.defmock + contract verification
  </read_first>
  <files>
    accrue/lib/accrue/processor.ex
    accrue/lib/accrue/processor/fake.ex
    accrue/lib/accrue/processor/fake/state.ex
    accrue/test/accrue/processor/fake_test.exs
    accrue/test/accrue/processor/behaviour_test.exs
  </files>
  <behavior>
    - `Accrue.Processor.Fake.start_link([]) ; Accrue.Processor.Fake.reset()` yields a clean state
    - `Accrue.Processor.create_customer(%{email: "a@b"}, []) == {:ok, %{id: "cus_fake_00001", email: "a@b", ...}}`
    - Second create returns `id: "cus_fake_00002"` — counter increments deterministically
    - `Accrue.Processor.retrieve_customer("cus_fake_00001", []) == {:ok, %{id: "cus_fake_00001", ...}}`
    - `Accrue.Processor.retrieve_customer("cus_nonexistent", [])` returns `{:error, %Accrue.APIError{code: "resource_missing"}}`
    - `Accrue.Processor.Fake.current_time()` returns the in-memory clock value
    - `Accrue.Processor.Fake.advance(server, 3600)` (seconds) moves the clock forward 1 hour
    - After `reset/0`, counters restart at 1 and clock resets to `~U[2026-01-01 00:00:00Z]` (or whatever epoch is chosen — make it a module attribute so it's greppable)
    - Mox contract test: `Mox.defmock(Accrue.ProcessorMock, for: Accrue.Processor)` compiles without error (proves the behaviour callbacks are well-defined)
  </behavior>
  <action>
1. `lib/accrue/processor.ex`: the behaviour module per `<interfaces>`. Phase 1 defines ONLY three callbacks (`create_customer`, `retrieve_customer`, `update_customer`) — Phase 3 grows it. Document in moduledoc which callbacks are coming in Phase 3 so the Fake state shape can already accommodate them. Each public function is wrapped in `Accrue.Telemetry.span/3` emitting `[:accrue, :processor, :customer, :create, :start|:stop|:exception]` etc. (OBS-01).

2. `lib/accrue/processor/fake/state.ex`: a plain struct holding:
   ```elixir
   defstruct customers: %{},         # %{id => customer_map}
             subscriptions: %{},     # placeholder for Phase 3
             counters: %{customer: 0, subscription: 0, invoice: 0, payment_intent: 0, payment_method: 0},
             clock: ~U[2026-01-01 00:00:00Z],
             stubs: %{}              # %{callback_atom => fun} override map for D-19
   ```

3. `lib/accrue/processor/fake.ex`:
   - `use GenServer`. Single named instance `Accrue.Processor.Fake` (Registry is A3 — SKIP for Phase 1, simple singleton GenServer is sufficient; Phase 3+ may add registry if per-test isolation fails).
   - `start_link/1`: `GenServer.start_link(__MODULE__, :ok, name: __MODULE__)`.
   - `init/1`: returns `{:ok, %State{}}`.
   - `reset/0`: `GenServer.call(__MODULE__, :reset)` → resets state.
   - `advance/2`: `GenServer.call(__MODULE__, {:advance, duration})` — adds duration seconds to clock.
   - `current_time/0`: reads clock.
   - `stub/3`: overrides one callback for the next N calls (testing utility).
   - **Behaviour impls** (`create_customer/2`, `retrieve_customer/2`, `update_customer/3`): each is a `GenServer.call` that:
     * Bumps the counter,
     * Assigns `id = "cus_fake_#{:io_lib.format("~5.10.0B", [counter]) |> to_string()}"` (5-digit zero-padded per D-20).
     * Returns `{:ok, customer_map}`.
     * On retrieve miss returns `{:error, %Accrue.APIError{code: "resource_missing", message: "No such customer: #{id}", http_status: 404}}`.

   **Startup**: Since the Fake is a GenServer, it must be started. Options:
   (a) Start it in `Accrue.Application` child list (but Application is Plan 06's concern — avoid coupling).
   (b) Start it on-demand in test_helper.exs via `start_supervised!/1` or plain `Accrue.Processor.Fake.start_link([])`.
   Pick (b) for Phase 1: tests that need the Fake start it in their `setup` block. Plan 06 can optionally add it to the supervisor. Document this choice in the moduledoc.

4. `test/accrue/processor/fake_test.exs`:
   - Use `ExUnit.Case, async: false` (shared Fake state).
   - `setup` block calls `Accrue.Processor.Fake.start_link([])` (or `start_supervised!`) then `Accrue.Processor.Fake.reset/0`.
   - Tests: create_customer counter increment, retrieve happy path, retrieve miss returns APIError, advance/current_time, reset clears state.

5. `test/accrue/processor/behaviour_test.exs`:
   - Proves Mox can defmock the behaviour:
     ```elixir
     test "Accrue.ProcessorMock is a valid Mox mock of the behaviour" do
       assert is_atom(Accrue.ProcessorMock)
       assert function_exported?(Accrue.ProcessorMock, :create_customer, 2)
     end
     ```
   - (The Mox.defmock call itself happens in test/support/mox_setup.ex from Plan 01 and fires now that the behaviour exists.)

Update the Fake ID prefixes to match D-20 exactly: `cus_fake_`, `sub_fake_`, `in_fake_`, `pi_fake_`, `pm_fake_` with a 5-digit zero-padded counter. Define them as module attributes so they're greppable.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/processor/fake_test.exs test/accrue/processor/behaviour_test.exs</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/processor/fake_test.exs` reports all passing
    - `grep -q "@callback create_customer" accrue/lib/accrue/processor.ex`
    - `grep -q "cus_fake_" accrue/lib/accrue/processor/fake.ex`
    - `grep -q "GenServer" accrue/lib/accrue/processor/fake.ex`
    - `grep -q "Application.get_env.*:processor" accrue/lib/accrue/processor.ex`
    - `grep -rq "LatticeStripe" accrue/lib/accrue/processor/fake.ex` returns nothing (Fake must not import lattice_stripe)
  </acceptance_criteria>
  <done>Fake processor is a working adapter with deterministic IDs, test clock, and clean reset. Behaviour is Mox-compatible.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Accrue.Processor.Stripe adapter + error mapper + facade lockdown test</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-07 (only module that imports lattice_stripe)
    - .planning/phases/01-foundations/01-RESEARCH.md (error mapping table — PROC-07/OBS-06)
    - accrue/lib/accrue/config.ex (VERIFY Plan 02 ship has :stripe_secret_key and :stripe_api_version in the schema — if missing, Plan 02 was not applied correctly)
    - hex.pm/lattice_stripe — inspect the 0.2 API surface for Customers; error shape per the library
    - CLAUDE.md §Tech Stack (lattice_stripe version pin)
    - CLAUDE.md §Config Boundaries (stripe_secret_key is RUNTIME ONLY — never compile_env)
  </read_first>
  <files>
    accrue/lib/accrue/processor/stripe.ex
    accrue/lib/accrue/processor/stripe/error_mapper.ex
    accrue/test/accrue/processor/stripe_test.exs
  </files>
  <behavior>
    - `Accrue.Processor.Stripe` implements `Accrue.Processor` callbacks by delegating to `LatticeStripe.Customers.*` (or equivalent, verified against lattice_stripe 0.2 public API at impl time)
    - Every `{:error, %LatticeStripe.Error{...}}` return is mapped via `ErrorMapper.to_accrue_error/1` to one of `%Accrue.CardError{}`, `%Accrue.RateLimitError{}`, `%Accrue.APIError{}`, `%Accrue.IdempotencyError{}`, `%Accrue.DecodeError{}`
    - Raw `processor_error` field is preserved on the Accrue error for debugging (OBS-06: metadata preserved)
    - `%Accrue.SignatureError{}` is RAISED (not returned) per D-08 — the Stripe adapter never returns a signature error as a tuple
    - **Facade test**: `grep -rlq "LatticeStripe" accrue/lib/accrue/` returns ONLY `accrue/lib/accrue/processor/stripe.ex` and `accrue/lib/accrue/processor/stripe/error_mapper.ex`. Any other file matching is a test failure.
    - **config.ex unchanged**: `git diff accrue/lib/accrue/config.ex` shows no diff from this plan — Plan 02 already defined `:stripe_secret_key` and `:stripe_api_version`; this plan only READS them via `Application.get_env/2`.
    - Mox-based test: unit-tests `ErrorMapper` with synthetic `%LatticeStripe.Error{}` structs (or maps if the struct doesn't exist yet). The wire-level adapter calls are NOT tested in Phase 1 — Phase 3 adds live Stripe test-mode integration.
  </behavior>
  <action>
1. **Prerequisite verification (fail fast)**: before writing any code, run:
   ```bash
   grep -q "stripe_secret_key" accrue/lib/accrue/config.ex || { echo "Plan 02 schema missing stripe_secret_key — STOP"; exit 1; }
   grep -q "stripe_api_version" accrue/lib/accrue/config.ex || { echo "Plan 02 schema missing stripe_api_version — STOP"; exit 1; }
   ```
   If either fails, Plan 02 was not properly applied — escalate rather than editing config.ex here. This plan is STRICTLY read-only against config.ex.

2. `lib/accrue/processor/stripe/error_mapper.ex`:
   - `to_accrue_error/1` takes a term (the raw lattice_stripe error value) and returns an `Exception.t()`.
   - Implementation strategy: pattern-match on the known LatticeStripe error shapes. Per CLAUDE.md §lattice_stripe is a sibling library and already exists at `~> 0.2`, inspect its error modules at impl time with `h LatticeStripe.Error` in iex.
   - Expected mapping table (verify against lattice_stripe actual shapes):
     | LatticeStripe error | Accrue error |
     |---|---|
     | `card_error` type | `%Accrue.CardError{code, decline_code, param, message, processor_error: raw}` |
     | `rate_limit_error` type | `%Accrue.RateLimitError{retry_after, message, processor_error: raw}` |
     | `idempotency_error` type | `%Accrue.IdempotencyError{idempotency_key, message, processor_error: raw}` |
     | `invalid_request_error`, `api_error`, `authentication_error`, `permission_error`, `api_connection_error` | `%Accrue.APIError{code, http_status, request_id, message, processor_error: raw}` |
     | JSON decode failure | `%Accrue.DecodeError{message, payload}` |
     | signature_verification (if surfaced) | **RAISE** `%Accrue.SignatureError{}` — never return |
     | anything unknown | `%Accrue.APIError{code: "unknown", processor_error: raw}` (defensive fallback) |
   - Preserve `request_id`, `http_status`, and stash the raw error in `processor_error` field.
   - `@compile {:no_warn_undefined, [LatticeStripe.Error, LatticeStripe.Customers]}` if the lattice_stripe types aren't guaranteed compile-order — remove once verified.

3. `lib/accrue/processor/stripe.ex`:
   - `@behaviour Accrue.Processor`.
   - Each callback: `LatticeStripe.Customers.create(params) |> translate()` where `translate/1`:
     - `{:ok, customer} -> {:ok, lattice_stripe_customer_to_map(customer)}` (map to a plain map to avoid leaking LatticeStripe structs to downstream code).
     - `{:error, raw} -> {:error, ErrorMapper.to_accrue_error(raw)}`.
   - Wrap every public call in `Accrue.Telemetry.span/3` emitting `[:accrue, :processor, :customer, :create, ...]` with `adapter: :stripe` in metadata.
   - **Read config at runtime via `Application.get_env(:accrue, :stripe_secret_key)` and `Application.get_env(:accrue, :stripe_api_version, "2026-03-25.dahlia")`**. Both keys are already defined in Plan 02's NimbleOptions schema — this plan DOES NOT edit `lib/accrue/config.ex`. If `stripe_secret_key` is nil at call time, raise `Accrue.ConfigError, key: :stripe_secret_key, message: "Set config :accrue, :stripe_secret_key in runtime.exs before using Accrue.Processor.Stripe"`.
   - Do NOT use `Application.compile_env!/2` for these keys — secrets must be runtime per CLAUDE.md §Config Boundaries.

4. `test/accrue/processor/stripe_test.exs`:
   - Unit test `ErrorMapper.to_accrue_error/1` with synthetic LatticeStripe error shapes (copy the shapes from a quick `iex -S mix run` inspection of `h LatticeStripe.Error` or from lattice_stripe's hex docs). At minimum 6 cases covering each mapping row above.
   - `Accrue.SignatureError` case: `assert_raise Accrue.SignatureError, fn -> ErrorMapper.to_accrue_error(%{type: "signature_verification_failed"}) end` (it raises rather than returns per D-08).
   - Facade lockdown test: use `File.ls!` + recursive grep equivalent in Elixir to walk `lib/accrue/`, assert that ONLY the two files `processor/stripe.ex` and `processor/stripe/error_mapper.ex` contain the string `LatticeStripe`. Any other match is a failed assertion.
     ```elixir
     test "lattice_stripe is only referenced inside Accrue.Processor.Stripe" do
       files =
         Path.wildcard("lib/accrue/**/*.ex")
         |> Enum.filter(fn path ->
           File.read!(path) =~ ~r/LatticeStripe|:lattice_stripe/
         end)
         |> Enum.sort()

       assert files == Enum.sort([
         "lib/accrue/processor/stripe.ex",
         "lib/accrue/processor/stripe/error_mapper.ex"
       ]),
         "lattice_stripe may only be referenced inside Accrue.Processor.Stripe. Found in: #{inspect(files)}"
     end
     ```
     (Adjust the expected list if the error_mapper does not need a direct reference.)

Note: If calling `LatticeStripe.Customers.create/1` at Phase 1 requires a live Stripe key or test-mode key, the actual wire calls stay untested in Phase 1 — only `ErrorMapper` and the facade-lockdown test run. Phase 3 will add integration tests against Stripe test mode. This is fine: PROC-02 (real Stripe delegation) is a Phase 3 requirement, not Phase 1. Phase 1 only requires PROC-01 (behaviour), PROC-03 (Fake), and PROC-07 (error mapping) — all three are satisfied by this plan.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/processor/stripe_test.exs && mix compile --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/processor/stripe_test.exs` reports all tests passing
    - Facade-lockdown test passes: `LatticeStripe` appears only in `stripe.ex` + `stripe/error_mapper.ex`
    - `grep -q "Accrue.CardError" accrue/lib/accrue/processor/stripe/error_mapper.ex`
    - `grep -q "processor_error:" accrue/lib/accrue/processor/stripe/error_mapper.ex` (raw metadata preserved)
    - `grep -q "Application.get_env.*:stripe_secret_key" accrue/lib/accrue/processor/stripe.ex` (runtime read)
    - `git diff accrue/lib/accrue/config.ex` shows no changes from this plan (Plan 02 owns the schema)
    - `git diff accrue/config/` shows no changes from this plan (Plan 01 owns static config)
    - `mix compile --warnings-as-errors` passes
  </acceptance_criteria>
  <done>Stripe adapter delegates to lattice_stripe, error mapper covers every Stripe error class with metadata preserved, facade lockdown test proves lattice_stripe is isolated, config.ex untouched.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Downstream Accrue code → Accrue.Processor behaviour | Must never see raw Stripe shapes |
| Accrue.Processor.Stripe → LatticeStripe HTTP | External API trust boundary |
| Error return → caller | Raw payload must be quarantined in processor_error field |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-PROC-01 | Information Disclosure | Raw Stripe error leaking to logs/telemetry | mitigate | `ErrorMapper.to_accrue_error/1` wraps raw error in `processor_error` field; Accrue.CardError.message/1 only references `code`/`decline_code` (non-PII). `Accrue.Telemetry.span/3` metadata includes only `{adapter: :stripe, operation: :create_customer}`, NOT the request params (which may contain PII). Document in processor/stripe.ex moduledoc: "Never log `processor_error` field verbatim; it may contain PII." |
| T-PROC-02 | Tampering | Facade leakage — non-Stripe module imports lattice_stripe | mitigate | Facade-lockdown test in Task 2 walks `lib/accrue/**/*.ex` and asserts LatticeStripe appears only in the two Stripe-adapter files. Fails CI if any other module references lattice_stripe. |
| T-PROC-03 | Spoofing | SignatureError returned as tuple → caller decides to retry → replay attack | mitigate | D-08 locks SignatureError as raise-only. Task 2 test asserts `ErrorMapper.to_accrue_error/1` RAISES on signature-verification errors, never returns them as tuple. |
| T-PROC-04 | Elevation of Privilege | stripe_secret_key leaking into compile artifacts | mitigate | `Accrue.Processor.Stripe` reads the key via `Application.get_env/2` at call time, never via `Application.compile_env!/2`. Plan 02's schema marks the field runtime-only in docs. Per CLAUDE.md §Config Boundaries. |
</threat_model>

<verification>
- `mix test test/accrue/processor/` fully green
- `mix compile --warnings-as-errors` passes
- Facade lockdown test passes (lattice_stripe isolated)
- `mix credo --strict lib/accrue/processor/` passes
- `git diff accrue/lib/accrue/config.ex accrue/config/` shows no changes from this plan
</verification>

<success_criteria>
Phase 2 can write webhook handler tests against `Accrue.ProcessorMock` (Mox) without starting a real Fake instance. Phase 3 grows the behaviour from 3 callbacks to the full subscription surface by ADDING callbacks — not by replacing this plan's shape.
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundations/01-04-SUMMARY.md`.
</output>
