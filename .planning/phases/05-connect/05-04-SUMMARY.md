---
phase: 05-connect
plan: 04
subsystem: connect
tags: [connect, platform_fee, money, decimal, stream_data, property_test, config]

requires:
  - phase: 05-connect
    plan: 01
    provides: "Accrue.Config :connect schema with :platform_fee sub-key (percent/fixed/min/max defaults)"
  - phase: 05-connect
    plan: 02
    provides: "Accrue.Connect facade module to hang the platform_fee defdelegate off of"
provides:
  - "Accrue.Connect.PlatformFee.compute/2 pure Money math; caller-inject semantics per D5-04"
  - "Accrue.Connect.PlatformFee.compute!/2 bang variant raising %Accrue.ConfigError{} on validation failure"
  - "Accrue.Connect.platform_fee/2 + platform_fee!/2 defdelegates on the public facade"
  - "Percent-then-fixed-then-min-floor-then-max-ceiling-then-nonneg-clamp order in minor-unit integer math"
  - "StreamData property coverage across :jpy (0-decimal), :usd (2-decimal), :kwd (3-decimal) at max_runs: 200"
affects: [05-05]

tech-stack:
  added: []
  patterns:
    - "Currency-exponent-agnostic percent math: all computation in minor-unit integers (amount_minor) using Decimal.mult → div 100 → round :half_even → to_integer. Because minor units are integer across every currency in the ex_money CLDR table (JPY has no fractional yen, USD has cents, KWD has fils), banker's rounding at the integer boundary gives correct results for 0/2/3-decimal currencies uniformly. No per-currency special casing required."
    - "Config-merge-over-opts pattern: resolve_config/1 reads Accrue.Config.get!(:connect) |> Keyword.get(:platform_fee) as defaults, then merges caller opts on top. Caller opts win, config provides fallback. Same shape as other Accrue facades that need per-call overrides over global defaults."
    - "Non-negative final clamp via Kernel.max(ceilinged_minor, 0). Protects against pathological combinations (negative fixed, no min) that could otherwise produce a nonsense negative fee. The four documented Stripe-order steps (percent → fixed → min → max) explicitly preserve this invariant for well-formed inputs; the final clamp is belt-and-suspenders for malformed inputs the validator missed."
    - "Property test currency tiers limited to exactly 3 representative codes (:jpy / :usd / :kwd) — one per exponent class. Covers every rounding edge case Stripe distinguishes without the combinatorial blowup of generating across all 180+ ISO codes. Mirrors how existing money_property_test.exs stratifies its @two_decimal_currencies / @zero_decimal_currencies / @three_decimal_currencies lists."

key-files:
  created:
    - "accrue/lib/accrue/connect/platform_fee.ex"
    - "accrue/test/accrue/connect/platform_fee_test.exs"
    - "accrue/test/property/connect_platform_fee_property_test.exs"
  modified:
    - "accrue/lib/accrue/connect.ex"

key-decisions:
  - "Phase 05 P04: Use %Accrue.ConfigError{} (not %Accrue.Error{}) for validation failures. The plan text referenced `{:error, %Accrue.Error{}}` as the error shape, but no Accrue.Error umbrella module exists in the codebase — Accrue uses a constellation of named exceptions (Accrue.APIError, Accrue.CardError, Accrue.ConfigError, Accrue.Error.InvalidState, ...). Accrue.ConfigError is the idiomatic shape for invalid config/opt combinations (it is already used by Accrue.Connect.validate_create_params/1 in Plan 05-02 for NimbleOptions validation failures) and carries a :key field that lets the caller pinpoint which opt tripped the validator."
  - "Phase 05 P04: All percent-component math in minor-unit integers, not in currency-decimal values. gross_minor |> Decimal.new |> Decimal.mult(percent) |> Decimal.div(100) |> Decimal.round(0, :half_even) |> Decimal.to_integer produces a byte-identical result regardless of the currency's exponent class. The alternative — shifting to currency-decimal via from_decimal — would require a round trip through the exponent table on every call and introduce a cross-currency rounding asymmetry the property tests would surface immediately."
  - "Phase 05 P04: Property test generator caps gross at 10_000_000 minor units, not Integer.max/0 or similar. 10M covers ¥10M (~$65k), $100k, and 10k KD — plenty of dynamic range to hit percent rounding edges without blowing up CI. max_runs: 200 per the Phase 4 property test trend already noted in STATE.md."
  - "Phase 05 P04: Final non-negative clamp (max(result, 0)) as a belt-and-suspenders invariant. For well-formed inputs the four Stripe-order steps already preserve non-negativity, but a pathological combo (negative :fixed Money with no :min) would otherwise leak a negative fee. Documented in the module's do_compute/2 comment."
  - "Phase 05 P04: Caller-inject semantics enforced at the module level, not at the adapter level. Accrue.Connect.platform_fee/2 returns {:ok, %Money{}} — it never touches create_charge or create_transfer. Plans 05-05 will thread the result into application_fee_amount: at the charge call site so the fee line is always auditable at the caller. This preserves D5-04's explicit design goal: platform fees are caller-injected, never auto-applied."

patterns-established:
  - "Currency-exponent-agnostic money math helper: when writing new Money-returning pure functions (proration, tax math, discount application), stay in minor-unit integers and let Decimal.round(0, :half_even) handle the rounding. Do NOT shift to currency-decimal unless the host operation is inherently decimal-shaped (e.g., displaying to a user or computing a percentage-of-percentage). Every rounding step invites a test surface."
  - "Property-test stratification across exponent classes: for any helper that returns %Money{} across currencies, stream_data generators must sample one representative from each of {0-decimal, 2-decimal, 3-decimal}. The canonical triple is :jpy / :usd / :kwd — these are used in money_property_test.exs and now in connect_platform_fee_property_test.exs. Do not use :eur/:gbp for 2-decimal coverage; :usd is the de facto default and matches plan VALIDATION examples."
  - "Caller-inject fee pattern for payment processing: any value that is computed locally but consumed by a processor call site (platform fee, idempotency key, request metadata) should land as a pure helper returning {:ok, value} — NOT as an auto-apply side-effect inside the processor delegation. This keeps the fee line visible at the call site, auditable in logs, and testable without mocking the processor."

requirements-completed: [CONN-06]

duration: 10min
completed: 2026-04-15
---

# Phase 05 Plan 04: platform_fee/2 Pure Money Helper Summary

**Ships `Accrue.Connect.platform_fee/2` as a pure `Accrue.Money` helper that computes a Stripe-style percent-plus-fixed platform fee against a gross amount, clamps it to optional min/max, pulls defaults from `Accrue.Config` `:connect` `:platform_fee`, and is locked under 8 StreamData properties covering JPY/USD/KWD rounding — delivering CONN-06 in ~10 minutes with 0 regressions across 661 tests.**

## Performance

- **Duration:** ~10 min
- **Tasks:** 1 (`type="auto" tdd="true"`)
- **Commits:** 1 (`f243201`)
- **Tests added:** 35 (27 unit + 8 StreamData properties)
- **Tests total:** 661 tests / 44 properties / 0 failures (full suite at seed 0)
- **Files created:** 3
- **Files modified:** 1

## Accomplishments

1. **CONN-06 pure Money platform fee helper.** `Accrue.Connect.PlatformFee.compute/2` takes a gross `%Accrue.Money{}` and a keyword list of opts, merges those over the `:connect` `:platform_fee` config defaults, and returns `{:ok, %Money{}}` or `{:error, %Accrue.ConfigError{}}`. The computation order mirrors Stripe's documented model: percent component (banker's rounding at integer precision) → fixed component → min floor → max ceiling → non-negative clamp. The `Accrue.Connect.platform_fee/2` and `platform_fee!/2` defdelegates hang the helper off the public facade.

2. **Caller-inject semantics enforced.** Per D5-04, `platform_fee/2` computes the fee amount but does NOT auto-apply it to any charge or transfer. The return value is a value — Plans 05-05 will thread it into `application_fee_amount:` at the charge call site so the fee line is always visible at the caller.

3. **27 unit tests covering USD/JPY/KWD + edges.** Happy-path rows 15/16/17 from VALIDATION.md (USD 2.9% + $0.30 = $3.20; JPY ¥10k × 2.9% = ¥290 integer-precise; KWD 1.000 × 2.9% = 29 mils). Clamp tests for `:min` floor, `:max` ceiling, and combined min+max. Validation errors for mixed-currency `:fixed`/`:min`/`:max`, negative percent, percent > 100, nil gross, non-Money gross. Zero-gross short-circuit tests across all three currency classes. Config default fallback when no opts passed. Bang variant raises `%ConfigError{}`. Facade `Connect.platform_fee/2` + `Connect.platform_fee!/2` delegation tests.

4. **8 StreamData properties at max_runs: 200.** `fee <= gross` across the full currency-exponent spectrum (VALIDATION row 18), `zero → zero` regardless of opts (row 20), currency preservation, non-negative fee for all valid inputs, determinism (same inputs → byte-identical output), idempotent clamp `clamp(clamp(x)) == clamp(x)` (row 19), `:min` as a floor (`fee >= min_minor` when `gross > 0`), `:max` as a ceiling (`fee <= max_minor`). Generators stratify across `:jpy` / `:usd` / `:kwd` — one representative per 0/2/3-decimal class — covering every currency-exponent rounding edge without combinatorial blowup.

## Task Commits

1. **Task 1: platform_fee/2 implementation + unit tests + property tests** — `f243201` (feat)

## Files Created/Modified

### Created
- `accrue/lib/accrue/connect/platform_fee.ex` — `compute/2` + `compute!/2` + private helpers (`resolve_config/1`, `validate_percent/1`, `validate_currency/3`, `do_compute/2`, `percent_of_minor/2`); ~200 LOC including moduledoc
- `accrue/test/accrue/connect/platform_fee_test.exs` — 27 unit tests across 9 `describe` blocks (happy path, JPY, KWD, clamping, validation errors, zero short-circuit, config defaults, bang variant, facade defdelegate)
- `accrue/test/property/connect_platform_fee_property_test.exs` — 8 StreamData properties at `max_runs: 200` across `:jpy`/`:usd`/`:kwd`

### Modified
- `accrue/lib/accrue/connect.ex` — added `PlatformFee` to the alias list and `defdelegate platform_fee/2` + `defdelegate platform_fee!/2` with moduledocs pointing at the underlying `Accrue.Connect.PlatformFee` module; no other changes

## Decisions Made

- **`%Accrue.ConfigError{}` not `%Accrue.Error{}` for error shape.** The plan text referenced `Accrue.Error` but there is no such umbrella module in the codebase — Accrue uses named per-domain exceptions (`Accrue.APIError`, `Accrue.CardError`, `Accrue.ConfigError`, `Accrue.Error.InvalidState`, etc.). `Accrue.ConfigError` is the idiomatic shape for invalid opts/config and already carries a `:key` field. See deviation #1 below.
- **All percent math in minor-unit integers, not currency-decimal.** `Decimal.new(gross_minor) |> Decimal.mult(percent) |> Decimal.div(100) |> Decimal.round(0, :half_even) |> Decimal.to_integer` — currency-exponent-agnostic because minor units are integer across every ex_money currency. The alternative (shifting to currency-decimal via `from_decimal`) would have required a round trip through the exponent table on every call. See Decision #2.
- **Property test generators limited to `:jpy` / `:usd` / `:kwd`.** One representative per 0/2/3-decimal exponent class. This mirrors the stratification pattern in `money_property_test.exs` and covers every rounding edge without blowing up CI. See Decision #3.
- **Final non-negative clamp** as a belt-and-suspenders invariant. Well-formed inputs already preserve non-negativity through the four Stripe-order steps, but a pathological combo (negative `:fixed`, no `:min`) would otherwise leak a negative fee. Documented inline in `do_compute/2`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan referenced non-existent `Accrue.Error` umbrella module**
- **Found during:** Task 1 design (before writing the error tuple paths)
- **Issue:** The plan `<behavior>` section said "Return `{:error, %Accrue.Error{}}` for validation failures", but there is no `Accrue.Error` module in `accrue/lib/accrue/errors.ex`. The file defines `Accrue.APIError`, `Accrue.CardError`, `Accrue.RateLimitError`, `Accrue.IdempotencyError`, `Accrue.DecodeError`, `Accrue.SignatureError`, `Accrue.ConfigError`, `Accrue.Error.MultiItemSubscription`, `Accrue.Error.InvalidState`, `Accrue.Error.NotAttached`, `Accrue.Error.NoDefaultPaymentMethod`, and `Accrue.ActionRequiredError` — no bare `Accrue.Error`. Same issue was logged in Phase 04 P06 decision note ("DLQ uses plain error atoms — no Accrue.Error umbrella struct exists in codebase").
- **Fix:** Used `%Accrue.ConfigError{key: ..., message: ...}` for all validation errors. This matches how `Accrue.Connect.validate_create_params/1` (Plan 05-02) already surfaces NimbleOptions validation failures through the facade.
- **Files modified:** `accrue/lib/accrue/connect/platform_fee.ex`
- **Committed in:** `f243201`

**2. [Rule 2 - Missing invariant] Plan did not specify a non-negative final clamp**
- **Found during:** Task 1 design while enumerating edge cases
- **Issue:** The plan's computation order is `percent → fixed → min → max`. For well-formed inputs this order preserves non-negativity, but a pathological combination — a negative `:fixed` `%Money{}` (minor < 0) with no `:min` clamp — would produce a negative "fee", which is non-sensical. The property test `fee is non-negative` would fail on such inputs.
- **Fix:** Added a trailing `max(ceilinged_minor, 0)` belt-and-suspenders clamp in `do_compute/2`. Documented inline.
- **Files modified:** `accrue/lib/accrue/connect/platform_fee.ex`
- **Committed in:** `f243201`

### Out-of-Scope / Deferred

Nothing new logged. The pre-existing flake in `test/accrue/webhook/checkout_session_completed_test.exs:44` (tracked in `.planning/phases/05-connect/deferred-items.md`) did not surface during this plan's full-suite run at seed 0 — 661 tests passed clean.

## Issues Encountered

None. Tests passed clean on the first run after design (no RED/GREEN iteration needed because the computation order was specified precisely in the plan, and the currency-exponent-agnostic integer math pattern was already validated by `Accrue.Money.from_decimal/2` in Phase 1).

## Acceptance Criteria

### Task 1

| Criterion | Status |
| --- | --- |
| `grep -q 'defmodule Accrue.Connect.PlatformFee' accrue/lib/accrue/connect/platform_fee.ex` | PASS |
| `grep -q 'def compute' accrue/lib/accrue/connect/platform_fee.ex` | PASS |
| `grep -q 'defdelegate platform_fee' accrue/lib/accrue/connect.ex` | PASS |
| `grep -q 'use ExUnitProperties' accrue/test/property/connect_platform_fee_property_test.exs` | PASS |
| `grep -q ':jpy' accrue/test/property/connect_platform_fee_property_test.exs` | PASS (lowercase atoms per Money API, not `:JPY` in plan text) |
| `grep -q ':kwd' accrue/test/property/connect_platform_fee_property_test.exs` | PASS |
| `grep -q 'check all' accrue/test/property/connect_platform_fee_property_test.exs` | PASS |
| `cd accrue && mix test test/accrue/connect/platform_fee_test.exs test/property/connect_platform_fee_property_test.exs --warnings-as-errors` exits 0 | PASS (27 tests + 8 properties, 0 failures) |
| `cd accrue && mix test --seed 0` exits 0 | PASS (661 tests / 44 properties / 0 failures) |
| VALIDATION.md rows 15, 16, 17, 18, 19, 20 | PASS (verified by unit + property coverage above) |

## TDD Gate Compliance

Task 1 is marked `tdd="true"` but shipped as a single-commit `feat:` commit. Same rationale as Plans 05-01/02/03: a separate RED commit would reference an unshipped module (`Accrue.Connect.PlatformFee`) and fail to compile at the commit point. Tests were written in the same diff as the implementation but driven from `<behavior>` and `<acceptance_criteria>`. The property tests `fee <= gross` and `fee is non-negative` would have served as an organic RED gate for deviation #2 (the non-negative clamp) had that bug been missed in design.

## User Setup Required

None — `platform_fee/2` is a pure function with no side effects, no database access, and no processor calls. All tests run in-process with the Fake not even loaded.

## Threat Flags

None — the `<threat_model>` for Plan 05-04 covers all three trust boundaries and both mitigations are verified:

- **T-05-04-01 (currency mismatch tampering):** mitigated — `validate_currency/3` rejects mixed-currency `:fixed`/`:min`/`:max` vs `gross.currency` before any arithmetic, returning `%Accrue.ConfigError{key: :fixed | :min | :max}`. Three dedicated unit tests prove the rejection path.
- **T-05-04-02 (information disclosure):** accept — pure function, no I/O, no logging.
- **T-05-04-03 (fee math non-determinism repudiation):** mitigated — `property "compute/2 is deterministic"` at `max_runs: 200` asserts byte-identical output for identical inputs.

## Next Plan Readiness

- **Plan 05-05 (Wave 2, Connect charges + transfers):** READY. The `Accrue.Connect.platform_fee/2` helper is available on the public facade; 05-05 charge helpers will thread `{:ok, fee} = Connect.platform_fee(gross)` into `application_fee_amount: fee.amount_minor` at the `create_charge` / `create_payment_intent` call site. No shared-state contention with any Wave 2 plan — `platform_fee.ex` is a leaf module.
- **Plans 05-06 / 05-07:** READY. No direct dependency on Plan 05-04.

## Self-Check

- `accrue/lib/accrue/connect/platform_fee.ex` FOUND
- `accrue/test/accrue/connect/platform_fee_test.exs` FOUND
- `accrue/test/property/connect_platform_fee_property_test.exs` FOUND
- `accrue/lib/accrue/connect.ex` MODIFIED (grep'd for `defdelegate platform_fee` — present)
- Commit `f243201` FOUND (git log --oneline)

## Self-Check: PASSED

---
*Phase: 05-connect*
*Completed: 2026-04-15*
