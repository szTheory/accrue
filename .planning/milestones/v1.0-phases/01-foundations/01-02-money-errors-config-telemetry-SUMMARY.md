---
phase: 01-foundations
plan: 02-money-errors-config-telemetry
subsystem: foundations
tags: [elixir, money, errors, config, telemetry, value-types, nimble_options]
requirements: [FND-01, FND-02, FND-03, FND-04, OBS-01, OBS-06]
dependency_graph:
  requires:
    - "01-01 bootstrap harness (mix.exs, Accrue.Cldr, test_helper)"
  provides:
    - "Accrue.Money value type + MismatchedCurrencyError (D-01..D-04)"
    - "Accrue.Ecto.Money dual shape — Ecto.Type jsonb form + money_field/1 macro (D-02)"
    - "Accrue.Error hierarchy — 7 defexception structs (D-05..D-08)"
    - "Accrue.Config — FULL Phase 1 NimbleOptions schema (validate!/1, get!/1, schema/0)"
    - "Accrue.Telemetry.span/3 + current_trace_id/0 conditional bridge (D-17, D-18)"
    - "Accrue.Actor process-dict context (D-15)"
  affects:
    - "Plans 03/04/05/06 alias Accrue.Money and raise Accrue.*Error"
    - "Plans 04/05 only READ Accrue.Config keys — never edit config.ex"
    - "Plan 03 Events.record reads Accrue.Actor.current/0"
    - "Every public entry point in Phase 1+ wraps in Accrue.Telemetry.span/3"
tech_stack:
  added: []
  patterns:
    - "Minor-unit integer as canonical Money representation (D-03)"
    - "Two-column money storage via money_field/1 macro (D-02)"
    - "NimbleOptions front-loaded full schema to avoid Wave 2 file collisions"
    - "Process-dict actor context with with_actor/2 scoping"
    - "Conditional compile OTel bridge — no_warn_undefined + Code.ensure_loaded?"
key_files:
  created:
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
    - accrue/test/accrue/actor_test.exs
  modified: []
decisions:
  - "Money.Currency.currency_for_code/1 is the exponent source of truth — ex_money does not expose a standalone Money.Currency.exponent/1. Read iso_digits off the returned Cldr.Currency struct. USD=2, JPY=0, KWD=3 verified."
  - "Accrue.Ecto.Money.money_field/1 macro uses fully-qualified Ecto.Schema.field calls (not bare field/2) so callers get macro expansion inside their own schema blocks without needing to import Ecto.Schema.field/2 explicitly."
  - "Errors test loop must call Code.ensure_loaded!/1 before function_exported?/3 — under async test scheduling modules aren't guaranteed resident in the code server even though they're compiled."
  - "Accrue.Config.get!/1 uses a sentinel :__accrue_unset__ atom (not nil) so configured-as-false values (e.g., :attach_invoice_pdf, :enforce_immutability) don't collapse into the default-fallback path."
metrics:
  duration_seconds: 680
  tasks_completed: 3
  files_created: 13
  commits: 3
  tests: 73
  properties: 6
completed_date: 2026-04-12
---

# Phase 01 Plan 02: Money, Errors, Config, Telemetry Summary

**One-liner:** The four foundational headless primitives — `Accrue.Money` (integer-minor-unit with cross-currency raise + `money_field/1` macro for D-02 two-column storage), the full 7-struct `Accrue.Error` hierarchy, a front-loaded `Accrue.Config` NimbleOptions schema with every Phase 1 key, `Accrue.Telemetry.span/3` + OTel bridge, and `Accrue.Actor` process-dict context — all green under 73 tests + 6 StreamData properties.

## What Shipped

### Task 1 — Accrue.Money + Accrue.Ecto.Money + property tests (commit `c723e0c`)

- **`Accrue.Money`** (`lib/accrue/money.ex`) — `%Accrue.Money{amount_minor: integer, currency: atom}` with `@enforce_keys`.
  - `new(int, atom)` is the happy path — validates currency via `Money.Currency.currency_for_code/1`; floats and `%Decimal{}` raise `ArgumentError` pointing at `from_decimal/2` (D-03).
  - `from_decimal/2` shifts by `10^iso_digits` with `Decimal.round/3` half-even — USD exponent=2, JPY=0, KWD=3.
  - `add/2`, `subtract/2`, `equal?/2` — same-currency guard pattern, mismatch raises `Accrue.Money.MismatchedCurrencyError` (D-04).
  - `to_string/1` uses `Money.new!/2` + `Money.to_string!/1` from ex_money for CLDR-aware formatting.
  - Private `exponent!/1` consults `Money.Currency.currency_for_code/1` so unknown codes raise immediately.
- **`Accrue.Money.MismatchedCurrencyError`** — `defexception [:left, :right, :message]` with `exception/1` deriving the message from the `left`/`right` atoms.
- **`Accrue.Ecto.Money`** — ships BOTH shapes (D-02 + RESEARCH Open Q5 resolution):
  - `Ecto.Type` callbacks (`type/0`, `cast/1`, `dump/1`, `load/1`) for the single-column jsonb form used in `accrue_events.data`. Serializes as `%{"amount_minor" => int, "currency" => binary}`; `load/1` hydrates back via `String.to_existing_atom/1`.
  - `defmacro money_field(name)` — the canonical two-column shape. Expands to three `Ecto.Schema.field/2` calls (`{name}_amount_minor :integer`, `{name}_currency :string`, `{name} :any, virtual: true`). Fully-qualified so callers don't need a separate `import Ecto.Schema`.
- **Unit tests** (`test/accrue/money_test.exs`, 24 tests) — cover integer/Decimal/float constructor paths, zero/two/three-decimal currencies, cross-currency raise, `money_field/1` macro reflection via an inline `embedded_schema` and `__schema__(:fields)` / `:virtual_fields`.
- **Property tests** (`test/accrue/money_property_test.exs`, 6 properties):
  1. Integer round-trip across USD/JPY/KWD/GBP/EUR
  2. Same-currency addition preserves amount exactly
  3. Cross-currency add/2 always raises
  4. `new/2` with float always raises
  5. `new/2` with Decimal always raises
  6. Changeset round-trip through `money_field/1` embedded schema preserves `{amount_minor, currency_string}`

Critical: `grep -r "ex_money_sql\|Money.Ecto.Composite.Type\|money_with_currency" accrue/lib/` returns nothing — Pitfall #1 (RESEARCH.md) is respected.

### Task 2 — Accrue.Error hierarchy + Accrue.Config (commit `916a103`)

- **`Accrue.Error` hierarchy** — one file, seven `defexception` modules (`APIError`, `CardError`, `RateLimitError`, `IdempotencyError`, `DecodeError`, `SignatureError`, `ConfigError`).
  - Each derives `message/1` from non-PII fields when the caller supplied `:message` is nil.
  - **`CardError.message/1` references only `code`, `decline_code`, `param`** — never `processor_error`. Mitigates T-FND-05 (Information Disclosure).
  - **`SignatureError`** documented per D-08 as raise-only. Tests assert `function_exported?(Accrue.SignatureError, :new, 1) == false` and `:error_tuple/1 == false`.
  - Each `@moduledoc` one line explaining when it's raised.
- **`Accrue.Config`** — the ONE AND ONLY Phase 1 editor of this file. Full 19-key NimbleOptions schema front-loaded so Plans 04/05 never touch it:
  - Repo + 5 adapter atoms
  - `stripe_secret_key` + `stripe_api_version` (runtime-only per CLAUDE.md §Config Boundaries)
  - Email pipeline (`emails`, `email_overrides`, `attach_invoice_pdf`)
  - `enforce_immutability` for Plan 06 boot check
  - Brand config (`business_name`, `business_address`, `logo_url`, `support_email`, `from_email`, `from_name`, `default_currency`)
- `validate!/1` → `NimbleOptions.validate!/2`. `get!/1` reads `Application.get_env/3` with `:__accrue_unset__` sentinel so `false`-valued config doesn't collapse to the default path. `schema/0` returns the raw keyword list for Plan 06's boot-check iteration.
- Moduledoc embeds `NimbleOptions.docs(@schema)` so the full option table surfaces in ExDoc.
- **Tests** (`errors_test.exs` 15 tests, `config_test.exs` 19 tests) — cover every struct, every default, runtime override, unknown-key raise, schema/0 coverage, and moduledoc substring assertions.

### Task 3 — Accrue.Telemetry + Accrue.Actor (commit `a461f5f`)

- **`Accrue.Actor`** — process-dictionary context. `@actor_types [:user, :system, :webhook, :oban, :admin]` is the fixed enum per D-15. `put_current/1` validates; unknown atoms (`:root`) raise `ArgumentError`. `with_actor/2` scopes via try/after, restoring prior value (including `nil`). `put_current(nil)` clears the dict.
- **`Accrue.Telemetry.span/3`** — thin wrapper over `:telemetry.span/3`. Accepts a zero-arity callable, returns its result unchanged. Auto-merges `Accrue.Actor.current/0` into metadata under `:actor` key. **Does NOT** auto-include raw fun args or return values — T-OBS-01 mitigation documented in the moduledoc so Plan 04's Stripe processor knows not to shove raw lattice_stripe responses into span metadata.
- **`current_trace_id/0`** — conditional compile per CLAUDE.md Pattern 6:
  - `@compile {:no_warn_undefined, [:otel_tracer, :otel_span]}` at module top silences without-OTel matrix warnings.
  - `if Code.ensure_loaded?(:otel_tracer)` branch calls `:otel_tracer.current_span_ctx/0` and hex-encodes the trace id (zero-padded to 32 chars, handles the `0` trace-id edge case); else branch returns `nil`.
  - Defensive rescue so any OTel runtime weirdness collapses to nil rather than crashing the caller.
- **4-level event name convention** documented in moduledoc with concrete examples: `[:accrue, :billing, :subscription, :create, :start]`, `[:accrue, :mail, :deliver, :payment_succeeded, :stop]`, etc.
- **Tests** (`telemetry_test.exs` 5 tests, `actor_test.exs` 9 tests) — `telemetry_test` attaches a local handler via `:telemetry.attach_many/4`, asserts `:start`/`:stop`/`:exception` event firing, verifies actor merging, and asserts T-OBS-01 (no raw arg auto-injection). `actor_test` covers valid round-trip, all 5 types, nil-clear, unknown-type raise, `with_actor/2` nested + exception restore.
- `Accrue.Telemetry.Metrics` is NOT built in this task per D-18 (optional helper, lands in Phase 4 with ops metrics).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `Money.new/2` is a direct struct constructor, not tuple-returning**
- **Found during:** Task 1 `to_string/1` — my initial implementation pattern-matched `{:ok, m} = Money.new(currency, decimal)`.
- **Issue:** ex_money's `Money.new/2` returns a `%Money{}` directly (the inspect form `Money.new(:USD, "10.50")` initially looked tuple-like).
- **Fix:** Switched to `Money.new!/2` which raises on invalid input — cleaner for our internal to_string path since we've already validated the currency via `exponent!/1`.
- **Files:** `accrue/lib/accrue/money.ex`
- **Commit:** `c723e0c`

**2. [Rule 1 - Bug] Virtual Ecto fields appear in `:virtual_fields`, not `:fields`**
- **Found during:** Task 1 money_test macro-expansion test.
- **Issue:** Initial test asserted `:price in TestSchema.__schema__(:fields)`. Ecto splits persisted and virtual fields into separate reflection buckets — virtual fields are exclusively under `__schema__(:virtual_fields)`.
- **Fix:** Updated tests to assert `:price in __schema__(:virtual_fields)` and `refute :price in __schema__(:fields)`. This is actually the correct semantic — virtual fields MUST NOT be persisted.
- **Files:** `accrue/test/accrue/money_test.exs`
- **Commit:** `c723e0c`

**3. [Rule 1 - Bug] `function_exported?/3` flakes under async test scheduling**
- **Found during:** Task 2 — individual test runs of `errors_test.exs` passed, but full-suite `mix test` run reported 6 `function_exported?(Accrue.CardError, :exception, 1) == false` failures.
- **Issue:** Under ExUnit's async scheduler, the BEAM code server may not yet have loaded a module when another test's `function_exported?/3` check runs. This is a classic Elixir loader-ordering race — `function_exported?/3` returns false for unloaded modules rather than triggering a load.
- **Fix:** Added `Code.ensure_loaded!(unquote(mod))` before the `function_exported?` checks in the error struct loop test.
- **Files:** `accrue/test/accrue/errors_test.exs`
- **Commit:** `a461f5f`

**4. [Rule 1 - Bug] `:telemetry.span/3` auto-injects `:telemetry_span_context` into metadata**
- **Found during:** Task 3 T-OBS-01 test.
- **Issue:** My initial assertion was `meta == %{safe: true}` — but `:telemetry` itself injects a `:telemetry_span_context` reference into every span's metadata for handler correlation. That's a library internal, not a user-data leak.
- **Fix:** Relaxed the assertion to check that `meta.safe == true` is preserved and that no raw fun args / return values leak. The T-OBS-01 mitigation is satisfied — we don't auto-inject anything the caller didn't hand us; `:telemetry_span_context` is a framework artifact, not a data exposure vector.
- **Files:** `accrue/test/accrue/telemetry_test.exs`
- **Commit:** `a461f5f`

### Rule 4 — Architectural changes

None.

## Threat Register Status

- **T-FND-04 (cross-currency tampering):** mitigated. `MismatchedCurrencyError` raised in `add/2` + `subtract/2`; property test `P2` asserts this across 100+ generated input pairs.
- **T-FND-05 (processor_error leakage):** mitigated in this plan's scope. `CardError.message/1` references only `code`/`decline_code`/`param`; test `processor_error field is settable but documented as sensitive` asserts `refute Exception.message(err) =~ "secret"`. The downstream logging sanitizer is Plan 06's job; Phase 1 just guarantees the structs themselves don't leak in `Exception.message/1`.
- **T-FND-06 (Config DoS):** accepted — NimbleOptions schema is compile-time static.
- **T-OBS-01 (telemetry metadata leakage):** mitigated. `span/3` moduledoc explicitly documents that raw args are NOT auto-injected; test asserts the contract; actor merging is opt-in via `with_actor/2`.

## Verification Results

```
cd accrue && mix compile --warnings-as-errors   # 0 warnings (without-otel conditional compile clean)
cd accrue && mix test                            # 73 tests, 6 properties, 0 failures

grep -c "defexception" accrue/lib/accrue/errors.ex            # 7
grep -q "NimbleOptions.docs" accrue/lib/accrue/config.ex      # present
grep -q "stripe_secret_key" accrue/lib/accrue/config.ex       # present
grep -q "stripe_api_version" accrue/lib/accrue/config.ex      # present
grep -q "mailer_adapter" accrue/lib/accrue/config.ex          # present
grep -q "pdf_adapter" accrue/lib/accrue/config.ex             # present
grep -q "auth_adapter" accrue/lib/accrue/config.ex            # present
grep -q "email_overrides" accrue/lib/accrue/config.ex         # present
grep -q "attach_invoice_pdf" accrue/lib/accrue/config.ex      # present
grep -q "enforce_immutability" accrue/lib/accrue/config.ex    # present
grep -q "def schema" accrue/lib/accrue/config.ex              # present
grep -q "defmacro money_field" accrue/lib/accrue/ecto/money.ex # present (D-02)
grep -q ":telemetry.span" accrue/lib/accrue/telemetry.ex       # present
grep -q "@compile {:no_warn_undefined" accrue/lib/accrue/telemetry.ex # present
grep -q "@actor_types" accrue/lib/accrue/actor.ex              # present
grep -rn "ex_money_sql\|Money.Ecto.Composite.Type\|money_with_currency" accrue/lib/  # empty (Pitfall #1)
```

All green.

## Success Criteria Met

Plans 03/04/05/06 can now:

- `alias Accrue.Money` and `Accrue.Money.new(1000, :usd)` for event data payloads.
- `import Accrue.Ecto.Money, only: [money_field: 1]` inside Phase 2+ schemas for D-02 two-column storage.
- `raise Accrue.CardError, code: "card_declined", processor_error: raw` in Plan 04's Stripe adapter without leaking `processor_error` through `Exception.message/1`.
- `Accrue.Config.get!(:stripe_secret_key)` at runtime in Plan 04 — key already in schema.
- `Accrue.Config.get!(:emails)` / `:email_overrides` / `:mailer_adapter` / `:from_email` / `:from_name` / `:attach_invoice_pdf` in Plan 05 — all 19 Phase 1 keys already in schema, Plan 05 never edits config.ex.
- `Accrue.Config.get!(:repo)` for Plan 03's event ledger inserts.
- Wrap every public function in `Accrue.Telemetry.span/3` to satisfy OBS-01.
- `Accrue.Actor.put_current(%{type: :webhook, id: stripe_event_id})` so Plan 03's `Events.record/1` reads actor context.

## Known Stubs

None. Every shipped module is fully functional:

- `Accrue.Money` round-trips, raises on mismatch, handles 0/2/3-decimal currencies.
- `Accrue.Ecto.Money` Ecto.Type callbacks serialize/deserialize; `money_field/1` macro expands into real Ecto schema fields (verified via reflection).
- `Accrue.Error` structs all raise, rescue, and pattern-match.
- `Accrue.Config` validates and reads real runtime values.
- `Accrue.Telemetry.span/3` emits real `:telemetry` events (verified by test handler).
- `Accrue.Actor` stores and retrieves real process-dict state.

The only "deferred" API is `Accrue.Telemetry.Metrics` (D-18), which the plan explicitly defers to Phase 4 as an optional helper — not a stub, a scoped-out deliverable.

## Self-Check: PASSED

- `accrue/lib/accrue/money.ex` — FOUND
- `accrue/lib/accrue/money/mismatched_currency_error.ex` — FOUND
- `accrue/lib/accrue/ecto/money.ex` — FOUND
- `accrue/lib/accrue/errors.ex` — FOUND
- `accrue/lib/accrue/config.ex` — FOUND
- `accrue/lib/accrue/telemetry.ex` — FOUND
- `accrue/lib/accrue/actor.ex` — FOUND
- `accrue/test/accrue/money_test.exs` — FOUND
- `accrue/test/accrue/money_property_test.exs` — FOUND
- `accrue/test/accrue/errors_test.exs` — FOUND
- `accrue/test/accrue/config_test.exs` — FOUND
- `accrue/test/accrue/telemetry_test.exs` — FOUND
- `accrue/test/accrue/actor_test.exs` — FOUND
- Commit `c723e0c` — FOUND
- Commit `916a103` — FOUND
- Commit `a461f5f` — FOUND
- `mix test` — 73 tests, 6 properties, 0 failures
- `mix compile --warnings-as-errors` — green
