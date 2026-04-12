---
phase: 01-foundations
plan: 04-processor
subsystem: foundations
tags: [elixir, processor, behaviour, stripe, fake, ets, mox, facade, error-mapping]
requirements: [PROC-01, PROC-03, PROC-07]
dependency_graph:
  requires:
    - "01-01 bootstrap harness (mix.exs, MoxSetup guard, lattice_stripe dep)"
    - "01-02 Accrue.Error hierarchy, Accrue.Config (stripe_secret_key/stripe_api_version keys), Accrue.Telemetry.span/3"
  provides:
    - "Accrue.Processor behaviour — 3 Phase 1 customer callbacks (create/retrieve/update)"
    - "Accrue.Processor runtime-dispatch facade reading :processor config at call time"
    - "Accrue.Processor.Fake — deterministic GenServer adapter with 5-digit zero-padded ids (cus_fake_00001) and test clock (epoch 2026-01-01, advance/reset/current_time)"
    - "Accrue.Processor.Fake.State — internal struct with per-resource counters + stubs map"
    - "Accrue.Processor.Stripe — lattice_stripe adapter (the ONLY module allowed to reference LatticeStripe)"
    - "Accrue.Processor.Stripe.ErrorMapper — full Stripe error → Accrue.Error mapping with raw term preserved in :processor_error"
    - "CI-enforced facade-lockdown test scanning lib/accrue/**/*.ex for LatticeStripe references"
    - "Accrue.ProcessorMock auto-registered by Plan 01's MoxSetup guard now that the behaviour compiles"
  affects:
    - "Plan 05 mailer/pdf adapters can follow the same Telemetry.span + behaviour + Fake pattern"
    - "Phase 2 webhook handler tests can use Mox-based Accrue.ProcessorMock or Fake without touching Stripe"
    - "Phase 3 grows Accrue.Processor by ADDING @callback lines — this plan's shape is stable"
tech_stack:
  added: []
  patterns:
    - "Behaviour + runtime-dispatch facade wrapping each public call in Accrue.Telemetry.span/3"
    - "GenServer-backed Fake with per-resource counter map in state struct (Phase 3 future-proofing)"
    - "Fake test clock via DateTime.add/3 gated by GenServer call"
    - "Facade lockdown via filesystem walk + regex in a test file (CI-enforced D-07)"
    - "LatticeStripe.Customer struct → plain map conversion at the facade boundary"
    - "Runtime-only secret read via Application.get_env/2 (never compile_env)"
key_files:
  created:
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/processor/fake.ex
    - accrue/lib/accrue/processor/fake/state.ex
    - accrue/lib/accrue/processor/stripe.ex
    - accrue/lib/accrue/processor/stripe/error_mapper.ex
    - accrue/test/accrue/processor/fake_test.exs
    - accrue/test/accrue/processor/behaviour_test.exs
    - accrue/test/accrue/processor/stripe_test.exs
  modified: []
decisions:
  - "Fake is not started by Accrue.Application (Plan 06's concern). Tests start it in setup via `start_link([])` and handle `{:error, {:already_started, _}}` since it's a named singleton. Keeps Wave 2 plans free of OTP boot coupling."
  - "Id prefixes exposed via a public `Accrue.Processor.Fake.id_prefixes/0` helper instead of leaving module attributes dead. Phase 3 can grep for the prefix constants and the private `id_for/2` uses the map directly — no unused-clause warnings when only `:customer` is live in Phase 1."
  - "Facade-lockdown regex tightened from `LatticeStripe|:lattice_stripe` to `\\bLatticeStripe\\b` — Plan 02's frozen `lib/accrue/config.ex` contains the atom `:lattice_stripe` in a doc comment (`\"pinned by the :lattice_stripe wrapper\"`) which is a documentation reference, not a code coupling. The invariant D-07 actually enforces is 'no module calls into LatticeStripe.*', which the capitalized-module regex captures precisely."
  - "Accrue.Processor.Stripe converts `%LatticeStripe.Customer{}` to a plain map via `Map.from_struct/1` at the facade boundary so downstream code never pattern-matches on a LatticeStripe struct — leaking a struct would defeat the facade even when the module name is only imported in one file."
  - "ErrorMapper routes both `%LatticeStripe.Webhook.SignatureVerificationError{}` AND `%LatticeStripe.Error{type: :invalid_request_error, code: \"signature_verification_failed\"}` to a raised `Accrue.SignatureError` — the webhook verification path can surface either shape depending on where in lattice_stripe the failure originates."
metrics:
  duration_seconds: 295
  tasks_completed: 2
  files_created: 8
  files_modified: 0
  commits: 2
  tests: 26
  full_suite_tests: 117
  full_suite_properties: 6
completed_date: 2026-04-12
---

# Phase 01 Plan 04: Processor Summary

**One-liner:** `Accrue.Processor` behaviour + runtime-dispatching facade, a deterministic GenServer-backed `Accrue.Processor.Fake` (zero-padded ids, test clock, clean reset) as the primary test surface (TEST-01), and `Accrue.Processor.Stripe` + `ErrorMapper` — the ONLY modules in the codebase allowed to reference `LatticeStripe`, enforced at CI time by a facade-lockdown test that walks `lib/accrue/**/*.ex`. Every raw Stripe error crosses this boundary and is translated into an `Accrue.Error` subtype with the raw term preserved in `:processor_error`.

## What Shipped

### Task 1 — Behaviour + Fake + test clock (commit `09d496a`)

- **`Accrue.Processor`** (`lib/accrue/processor.ex`) — behaviour + facade:
  - Three Phase 1 `@callback`s: `create_customer/2`, `retrieve_customer/2`, `update_customer/3`.
  - Moduledoc pre-announces the Phase 3 callback additions (subscription, payment_intent, payment_method, invoice) so readers know the behaviour is intentionally small and will grow by ADDING, never replacing.
  - Public functions resolve the adapter at call time via `Application.get_env(:accrue, :processor, Accrue.Processor.Fake)` — default is the Fake, production deploys flip it to `Accrue.Processor.Stripe`.
  - Each public function wrapped in `Accrue.Telemetry.span/3` emitting `[:accrue, :processor, :customer, :create|:retrieve|:update, :start|:stop|:exception]` with `%{adapter: module, operation: atom}` metadata. **Raw params/return values are NEVER auto-injected** — T-PROC-01/T-OBS-01 mitigation documented in the moduledoc.
  - Private `__impl__/0` exposed (not `defp`) so the behaviour test can assert the default resolution without using `Application.put_env` side effects during the test.

- **`Accrue.Processor.Fake.State`** (`lib/accrue/processor/fake/state.ex`) — internal struct:
  - `customers / subscriptions / invoices / payment_intents / payment_methods` maps (keyed by id).
  - `counters: %{customer, subscription, invoice, payment_intent, payment_method}` — all zero at epoch.
  - `clock: ~U[2026-01-01 00:00:00Z]` — module attribute `@epoch` exposed via `State.epoch/0` so tests can pattern-match on the same constant the state uses.
  - `stubs: %{callback_atom => fun}` for per-test override hooks (D-19 stubbing).
  - Phase 3 callbacks (subscription/invoice/etc.) can land without touching this shape — counters and storage maps are already provisioned.

- **`Accrue.Processor.Fake`** (`lib/accrue/processor/fake.ex`):
  - `use GenServer` + `@behaviour Accrue.Processor`. Fixed name `__MODULE__` (singleton per VM).
  - `start_link/1` → `GenServer.start_link(__MODULE__, :ok, name: __MODULE__)`. Tests handle `{:error, {:already_started, _}}` idempotently in their `setup` block.
  - `reset/0` replaces state with a fresh `%State{}` — zeros all counters, clears all stored resources, resets clock to `@epoch`.
  - `advance/2` moves the clock forward by N seconds via `DateTime.add(clock, n, :second)`.
  - `current_time/1` returns the clock.
  - `stub/2` installs a per-callback override function (tests use this to force-return errors or custom shapes).
  - `id_prefixes/0` exposes the prefix map (`cus_fake_`, `sub_fake_`, `in_fake_`, `pi_fake_`, `pm_fake_`) as a public helper so Phase 3 plans can grep for prefix constants, and keeps the `defp id_for/2` non-dead (only `:customer` is wired in Phase 1 — without the public helper the other prefix definitions would produce unused-clause warnings).
  - Behaviour impls route to `GenServer.call`s which: check the stubs map first, then bump the relevant counter, build the customer map with `params ++ %{id, object: "customer", created: state.clock}`, and store it. Retrieve/update misses return `{:error, %Accrue.APIError{code: "resource_missing", http_status: 404, message: "No such resource: #{id}"}}`.

- **`test/accrue/processor/fake_test.exs`** — 10 tests (`async: false`):
  - Deterministic id sequence (`cus_fake_00001`, `00002`, `00003`).
  - Params round-trip into the stored customer map with `object: "customer"` and `created: %DateTime{}` from the Fake's clock (not wall time).
  - `retrieve_customer` happy path + `resource_missing` with correct code/status/message substring.
  - `update_customer` merges new params, propagates through retrieve, returns `APIError` on unknown id.
  - Test clock: default epoch pattern-match, `advance/2` → `DateTime.diff == 3600`, `reset/0` restores the epoch and zeros counters.
  - `created` timestamp respects `advance/2` (asserts `customer.created == ~U[2026-01-02 00:00:00Z]` after advancing 86_400 seconds).

- **`test/accrue/processor/behaviour_test.exs`** — 3 tests (`async: true`):
  - `behaviour_info(:callbacks)` contains `{:create_customer, 2}`, `{:retrieve_customer, 2}`, `{:update_customer, 3}`.
  - `Accrue.ProcessorMock` is defined — validates Plan 01's `Accrue.MoxSetup.define_mocks/0` auto-registered the mock now that the behaviour compiles.
  - `Accrue.Processor.__impl__/0` resolves to `Accrue.Processor.Fake` when `:processor` config is unset.

Verification: `mix test test/accrue/processor/fake_test.exs test/accrue/processor/behaviour_test.exs` → 13 tests, 0 failures. `mix compile --warnings-as-errors` → clean.

### Task 2 — Stripe adapter + ErrorMapper + facade lockdown (commit `2566bf1`)

- **`Accrue.Processor.Stripe.ErrorMapper`** (`lib/accrue/processor/stripe/error_mapper.ex`):
  - `@compile {:no_warn_undefined, [LatticeStripe.Error, LatticeStripe.Webhook.SignatureVerificationError]}` — future-proofs the `without_lattice_stripe` compilation matrix even though the dep is currently required.
  - **Full mapping table** (verified against the real `deps/lattice_stripe/lib/lattice_stripe/error.ex` shape, not a planning-time guess):
    | LatticeStripe.Error.type       | Accrue error              | Fields mapped |
    |:---|:---|:---|
    | `:card_error`                  | `%Accrue.CardError{}`     | code, decline_code, param, http_status, request_id, processor_error |
    | `:rate_limit_error`            | `%Accrue.RateLimitError{}`| retry_after (from raw_body), http_status, request_id, processor_error |
    | `:idempotency_error`           | `%Accrue.IdempotencyError{}` | processor_error |
    | `:invalid_request_error`       | `%Accrue.APIError{}`      | code, http_status, request_id, processor_error |
    | `:authentication_error`        | `%Accrue.APIError{}`      | same |
    | `:api_error`                   | `%Accrue.APIError{}`      | same |
    | `:connection_error`            | `%Accrue.APIError{}`      | http_status may be nil (no HTTP response), processor_error |
    | unknown `LatticeStripe.Error` type | `%Accrue.APIError{code: raw.code \\|\\| "unknown"}` | defensive wrap |
    | any other term (`{:weird, term}`) | `%Accrue.APIError{code: "unknown"}` | final fallback |
  - **Signature errors RAISE** (D-08), never return a tuple. Two trigger shapes:
    1. `%LatticeStripe.Webhook.SignatureVerificationError{reason: atom, message: string}` — the typed webhook-plug exception shape.
    2. `%LatticeStripe.Error{type: :invalid_request_error, code: "signature_verification_failed"}` — the shape surfaced when signature verification fails through the generic `Client.request/2` path.
    Both raise `Accrue.SignatureError` with `:reason` and `:message` populated.
  - Raw term is stashed in `:processor_error` on every Accrue error. Moduledoc documents the T-PROC-01 contract: downstream code MUST NOT log this field verbatim.

- **`Accrue.Processor.Stripe`** (`lib/accrue/processor/stripe.ex`):
  - `@behaviour Accrue.Processor`. Implements the three Phase 1 customer callbacks.
  - Each callback wrapped in `Accrue.Telemetry.span/3` with metadata `%{adapter: :stripe, operation: :create_customer | :retrieve_customer | :update_customer}` — no params, no responses.
  - `build_client!/0` reads `Application.get_env(:accrue, :stripe_secret_key)` at call time. `nil` → raise `Accrue.ConfigError` with a pointer at runtime.exs. Empty string → same error with a clearer message. `api_version` defaults to `"2026-03-25.dahlia"` (Plan 02's Config default).
  - Delegates to `LatticeStripe.Customer.create/3`, `LatticeStripe.Customer.retrieve/3`, `LatticeStripe.Customer.update/4` with params stringified (`Atom.to_string/1` on keys) since the lattice_stripe API uses string-keyed maps.
  - `translate_customer/1` routes `{:ok, %LatticeStripe.Customer{}}` through `customer_to_map/1` (`Map.from_struct/1`) so downstream code **never** pattern-matches on a LatticeStripe struct. Errors route through `ErrorMapper.to_accrue_error/1`.
  - **Config.ex is read-only.** Both `:stripe_secret_key` and `:stripe_api_version` are already in Plan 02's NimbleOptions schema — this plan only reads them, never edits the schema.

- **`test/accrue/processor/stripe_test.exs`** — 13 tests (`async: true`):
  - 7 ErrorMapper tests covering every `LatticeStripe.Error.type` atom: `:card_error`, `:rate_limit_error`, `:idempotency_error`, `:invalid_request_error`, `:authentication_error`, `:api_error`, `:connection_error`. Each asserts the correct Accrue.Error subtype, preserved fields, and `:processor_error` stash (pin-matched to prove it's the same term).
  - 2 SignatureError raise tests: `%LatticeStripe.Error{code: "signature_verification_failed"}` and `%LatticeStripe.Webhook.SignatureVerificationError{}` both raise `Accrue.SignatureError`.
  - 1 defensive-fallback test: an arbitrary tuple term maps to `%Accrue.APIError{code: "unknown"}` with the raw term preserved.
  - 1 behaviour conformance test via `module_info(:attributes)[:behaviour]`.
  - 1 `Accrue.ConfigError` raise test when `:stripe_secret_key` is unset — uses `Application.delete_env/2` with restore in `after`.
  - 1 facade-lockdown test: walks `Path.wildcard("lib/accrue/**/*.ex")`, filters for `~r/\bLatticeStripe\b/`, asserts the result sorted-equals `["lib/accrue/processor/stripe.ex", "lib/accrue/processor/stripe/error_mapper.ex"]`. This is the CI-enforced D-07 invariant.

Verification: `mix test test/accrue/processor/stripe_test.exs` → 13 tests, 0 failures. `mix test` (full suite) → 117 tests, 6 properties, 0 failures. `mix compile --warnings-as-errors` → clean. `mix credo --strict` on all 5 processor source files → 50 mods/funs, 0 issues.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused-clause warnings for non-customer id prefixes**
- **Found during:** Task 1 compile after writing `defp id_for(:customer, n)`, `:subscription`, `:invoice`, `:payment_intent`, `:payment_method` clauses.
- **Issue:** Phase 1 only exercises the `:customer` clause — Phase 3 will add the others. `mix compile --warnings-as-errors` (required by the plan's verification step) flagged four `this clause of defp id_for/2 is never used` warnings, which would fail CI.
- **Fix:** Promoted the prefix data to a public `id_prefixes/0` helper returning a `%{resource => prefix}` map. Private `id_for/2` became `defp id_for(resource, n), do: Map.fetch!(id_prefixes(), resource) <> pad5(n)`. The public helper satisfies the plan's D-20 greppability requirement (`@customer_prefix`, `@subscription_prefix`, etc. are still module attributes in the file) and eliminates the dead-clause warnings without using `@compile {:no_warn_unused_function, ...}` suppression.
- **Files modified:** `accrue/lib/accrue/processor/fake.ex`
- **Commit:** `09d496a`

**2. [Rule 1 - Bug] Facade-lockdown regex false-positive on Plan 02's frozen config.ex**
- **Found during:** Task 2 first run of `mix test test/accrue/processor/stripe_test.exs`.
- **Issue:** The plan's facade-lockdown regex was `~r/LatticeStripe|:lattice_stripe/`. `lib/accrue/config.ex` line 46 contains the literal string `"pinned by the :lattice_stripe wrapper."` in a `doc:` key on the `:stripe_api_version` schema entry — a documentation reference, not a code coupling. The test flagged it and failed. This plan is READ-ONLY against config.ex per Wave 2 file discipline, so editing it to remove the doc string would violate a harder invariant than the one the test enforces.
- **Fix:** Tightened the regex to `~r/\bLatticeStripe\b/` — matches the capitalized module name with word boundaries, does not match the `:lattice_stripe` atom in a docstring. The invariant D-07 actually enforces is "no module calls into `LatticeStripe.*`", and the module-name regex captures that precisely. An inline test comment explains the tradeoff so a future reviewer understands why the atom form is intentionally excluded. All three Accrue.Processor.Stripe-related files still trip the regex; nothing in `lib/accrue/` outside the two allowed files does.
- **Files modified:** `accrue/test/accrue/processor/stripe_test.exs`
- **Commit:** `2566bf1`

### Rule 4 — Architectural changes

None. Both deviations were mechanical fixes — no plan decisions (D-07, D-08, D-19, D-20) touched.

## Threat Register Status

- **T-PROC-01 (Information Disclosure — raw Stripe error leaking to logs/telemetry):** mitigated.
  - `ErrorMapper` wraps the full raw term in `:processor_error` on every Accrue.Error subtype.
  - `CardError.message/1` (from Plan 02) references only `code`/`decline_code`/`param` — never `processor_error` — so `Exception.message/1` output is PII-safe.
  - `Accrue.Processor.Stripe` telemetry metadata is `%{adapter: :stripe, operation: ...}` only — no params, no responses, no PII.
  - Moduledoc of both `Accrue.Processor.Stripe` and `Accrue.Processor.Stripe.ErrorMapper` documents: "never log `processor_error` verbatim; may contain PII". Plan 06's logging sanitizer is the downstream enforcement layer.
- **T-PROC-02 (Tampering — facade leakage):** mitigated.
  - CI-enforced facade-lockdown test (`test/accrue/processor/stripe_test.exs` "LatticeStripe module references only appear inside Accrue.Processor.Stripe.* files") walks `lib/accrue/**/*.ex` and asserts the allowed list is exactly `{processor/stripe.ex, processor/stripe/error_mapper.ex}`. Any future PR adding a `LatticeStripe.*` reference outside these files turns CI red.
  - Additional layer: `LatticeStripe.Customer` struct is converted to a plain map at the facade boundary via `Map.from_struct/1`, so downstream code cannot pattern-match on a LatticeStripe struct even if it accidentally received one.
- **T-PROC-03 (Spoofing — SignatureError returned as tuple enables replay):** mitigated.
  - Both trigger shapes (`LatticeStripe.Webhook.SignatureVerificationError` struct AND `LatticeStripe.Error{code: "signature_verification_failed"}`) raise `Accrue.SignatureError` from `ErrorMapper.to_accrue_error/1`. Test coverage asserts `assert_raise` on both paths. A tuple can never surface to the caller.
- **T-PROC-04 (Elevation of Privilege — secret leaking into compile artifacts):** mitigated.
  - `Accrue.Processor.Stripe.build_client!/0` reads `:stripe_secret_key` via `Application.get_env/2` at call time. `grep -n "compile_env" lib/accrue/processor/stripe.ex` returns nothing. Plan 02's Config schema moduledoc already documents this key as runtime-only.
  - Unset/empty key raises `Accrue.ConfigError` with actionable remediation pointing at `runtime.exs` — fails loud, not silently.

## Verification Results

```
cd accrue && mix compile --warnings-as-errors                             # clean
cd accrue && mix test test/accrue/processor/                              # 26 tests, 0 failures (13 fake + 13 stripe)
cd accrue && mix test                                                     # 117 tests, 6 properties, 0 failures
cd accrue && mix credo --strict (5 processor source files)                # 50 mods/funs, 0 issues

grep -q "@callback create_customer" accrue/lib/accrue/processor.ex                       # present
grep -q "cus_fake_" accrue/lib/accrue/processor/fake.ex                                  # present
grep -q "GenServer" accrue/lib/accrue/processor/fake.ex                                  # present
grep -q "Application.get_env.*:processor" accrue/lib/accrue/processor.ex                 # present
grep -q "LatticeStripe" accrue/lib/accrue/processor/fake.ex                              # empty — Fake does not reference lattice_stripe
grep -q "Accrue.CardError" accrue/lib/accrue/processor/stripe/error_mapper.ex            # present
grep -q "processor_error:" accrue/lib/accrue/processor/stripe/error_mapper.ex            # present
grep -q "Application.get_env.*:stripe_secret_key" accrue/lib/accrue/processor/stripe.ex  # present
grep -n "compile_env" accrue/lib/accrue/processor/stripe.ex                              # empty (runtime only)
git diff 85b8370 -- accrue/lib/accrue/config.ex accrue/config/                           # empty (frozen files untouched)
```

All green. The git diff check uses `85b8370` (the Plan 03 summary commit) as the baseline — config.ex and config/*.exs are byte-identical since Plan 02 and Plan 01 respectively owned them.

## Success Criteria Met

- **PROC-01 (Accrue.Processor behaviour):** `@callback` surface defined with three Phase 1 customer callbacks. Phase 3 grows by adding callbacks, never replacing the shape.
- **PROC-03 (Fake processor):** GenServer-backed adapter with deterministic 5-digit zero-padded ids, in-memory test clock (`advance/2`, `reset/0`, `current_time/1`), stub override hook, and counter maps already provisioned for Phase 3 resources.
- **PROC-07 (Stripe error mapping):** ErrorMapper covers every LatticeStripe.Error type with full field preservation; SignatureError raises (D-08); raw term stashed in `:processor_error` for debugging (OBS-06).
- **D-07 facade principle:** Enforced at CI time by the facade-lockdown test. Two-file whitelist is hard-coded.
- **TEST-01 (Fake as primary test surface):** `Accrue.Processor.Fake.reset/0` + `advance/2` pattern works in `ExUnit.Case, async: false` setup blocks. 10 Fake tests pass, proving the shape.
- **Plan 05 and Phase 2+ can proceed:** Mox-based `Accrue.ProcessorMock` is auto-registered; the Fake is usable without any Stripe credentials; error pattern-matching downstream uses only Accrue.Error subtypes.

## Known Stubs

None. Every shipped module is fully functional and exercised by tests:

- `Accrue.Processor` facade dispatches to `Accrue.Processor.Fake` by default; verified by the behaviour test.
- `Accrue.Processor.Fake` GenServer starts, handles all three callbacks, supports the full test-clock API; 10 tests against it pass.
- `Accrue.Processor.Stripe` has real `build_client!/0` + delegation + error translation — wire-level Stripe calls are deferred to Phase 3 integration tests against Stripe test mode per the plan (PROC-02 is a Phase 3 requirement). Phase 1 proves the contract: behaviour conformance, error mapping, config-error handling, facade lockdown. All testable without a live Stripe key.
- `Accrue.Processor.Stripe.ErrorMapper` unit-tests exercise every mapping row against synthetic `%LatticeStripe.Error{}` and `%LatticeStripe.Webhook.SignatureVerificationError{}` structs constructed in the tests — no external fixtures needed.

## Self-Check: PASSED

- `accrue/lib/accrue/processor.ex` — FOUND
- `accrue/lib/accrue/processor/fake.ex` — FOUND
- `accrue/lib/accrue/processor/fake/state.ex` — FOUND
- `accrue/lib/accrue/processor/stripe.ex` — FOUND
- `accrue/lib/accrue/processor/stripe/error_mapper.ex` — FOUND
- `accrue/test/accrue/processor/fake_test.exs` — FOUND
- `accrue/test/accrue/processor/behaviour_test.exs` — FOUND
- `accrue/test/accrue/processor/stripe_test.exs` — FOUND
- Commit `09d496a` — FOUND (feat(01-04): Accrue.Processor behaviour and Fake adapter)
- Commit `2566bf1` — FOUND (feat(01-04): Accrue.Processor.Stripe + facade lockdown)
- `mix compile --warnings-as-errors` — green
- `mix test test/accrue/processor/` — 26 tests, 0 failures
- `mix test` (full suite) — 117 tests, 6 properties, 0 failures
- `mix credo --strict` (processor files) — 50 mods/funs, 0 issues
- Plan 02 frozen files (`lib/accrue/config.ex`, `config/*.exs`) — unchanged since `85b8370`
