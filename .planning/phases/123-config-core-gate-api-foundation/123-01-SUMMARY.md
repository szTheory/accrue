---
phase: 123-config-core-gate-api-foundation
plan: 01
subsystem: config
tags: [entitlements, nimble_options, boot-validation, config, plan-gating]

# Dependency graph
requires:
  - phase: 122
    provides: "Accrue.Config @schema + validate_at_boot!/0 + maybe_validate_boot_setup!/1 boot path; Accrue.ConfigError"
provides:
  - ":entitlements NimbleOptions @schema key (plans/resolver/unmapped_action), runtime-read, default []"
  - "Accrue.Config.entitlements/0 thin runtime accessor"
  - "validate_entitlements_price_ids!/1 boot collision guard wired into maybe_validate_boot_setup!/1"
  - "config_entitlements_test.exs covering all four ENT-01 boot behaviors"
affects: [123-02, 123-03, 123-resolver, entitlements]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cross-plan boot guard lives in maybe_validate_boot_setup!/1 (not a per-field {:custom,...} validator) so it can see ALL plans at once"
    - "Host catalog data (:entitlements) read at runtime via get!/1, never compile_env! (D-01)"

key-files:
  created:
    - accrue/test/accrue/config_entitlements_test.exs
  modified:
    - accrue/lib/accrue/config.ex

key-decisions:
  - "limits uses type: :keyword_list + keys: [*: [type: :pos_integer]] — NimbleOptions 1.1 has no {:keyword_list, value_type} form; same D-02 intent in valid syntax"
  - "entitlements/0 is a thin get!/1 accessor (no full re-validation per call); resolver (Plan 03) handles nested-default normalization"
  - "Collision guard treats a price_id repeated within ONE plan as harmless; only the SAME price_id across DIFFERENT plans raises"

patterns-established:
  - "validate_entitlements_price_ids!/1: Enum.reduce building a price_id => plan reverse index, raising Accrue.ConfigError on cross-plan collision"

requirements-completed: [ENT-01]

# Metrics
duration: 4min
completed: 2026-05-22
---

# Phase 123 Plan 01: Config + Entitlements Schema Foundation Summary

**NimbleOptions-validated `:entitlements` plan->feature/quota config schema with a runtime `entitlements/0` accessor and a boot-time `price_id`-collision guard that fails loud (`Accrue.ConfigError`) when one price_id maps to two plans.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-22T22:22:01Z
- **Completed:** 2026-05-22T22:25:59Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Added the top-level `:entitlements` `@schema` key (`plans` atom-keyed map with `features`/`limits`/`price_ids`; `resolver` module default `Accrue.Entitlements.Resolver.LocalMap`; `unmapped_action` `:deny`/`:raise` default `:deny`), runtime-read with `default: []` (ENT-01, D-01..D-03).
- Added `Accrue.Config.entitlements/0`, a thin runtime accessor (`get!/1`, never `compile_env!`), matching the `branding/0`/`dunning/0` host-data idiom.
- Added the cross-plan `validate_entitlements_price_ids!/1` boot guard wired into `maybe_validate_boot_setup!/1`; the same `price_id` under two different plans raises `Accrue.ConfigError` whose message names both plan atoms and the price_id (D-04, threat T-123-01 mitigated).
- All four ENT-01 boot behaviors covered and green: valid config validates clean, invalid type raises `NimbleOptions.ValidationError`, duplicate price_id raises `Accrue.ConfigError`, absent/empty defaults to `[]`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write boot-validation + collision tests (Wave 0)** - `994efee` (test)
2. **Task 2: Add :entitlements schema key, entitlements/0 accessor, boot collision guard** - `01cc314` (feat)

_Note: Task 2's commit also contains one in-test bug fix (see Deviations) since the test was authored in Task 1 and corrected when the real validation path surfaced the issue._

## Files Created/Modified

- `accrue/lib/accrue/config.ex` - Added the `:entitlements` `@schema` key, the `entitlements/0` accessor, and the `validate_entitlements_price_ids!/1` boot guard invoked from `maybe_validate_boot_setup!/1`.
- `accrue/test/accrue/config_entitlements_test.exs` - `async: false` boot/collision test covering all four ENT-01 behaviors (8 tests), with app-env restore mirroring `storage/null_test.exs`.

## Decisions Made

- **`limits` type expressed as `keyword_list` with wildcard `:pos_integer` keys.** The locked NimbleOptions fragment specified `{:keyword_list, :pos_integer}`, which is not a valid NimbleOptions 1.1.1 type (no two-arg `:keyword_list` form exists). Used `type: :keyword_list, keys: [*: [type: :pos_integer]]` instead — the idiomatic NimbleOptions way to constrain every value of a keyword list to a positive integer, identical D-02 semantics (probe-confirmed: accepts `[seats: 10]`, rejects `[seats: -1]` / `[seats: "x"]`).
- **`entitlements/0` is a raw runtime read, not a normalized merge.** Unlike `branding/0` (which merges defaults), the accessor returns the raw stored keyword list per the plan ("a thin accessor suffices … do NOT re-run the full validator per call"); the resolver in Plan 03 normalizes nested defaults.
- **Collision guard is whole-plan-aware, not per-field.** Placed in `maybe_validate_boot_setup!/1` (a `{:custom, ...}` validator sees only one plan entry and cannot detect a cross-plan duplicate), per RESEARCH § Pattern 3 / D-04.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Invalid NimbleOptions type `{:keyword_list, :pos_integer}` in the locked schema fragment**
- **Found during:** Task 2 (schema addition)
- **Issue:** The CONTEXT.md/PLAN.md locked fragment used `limits: [type: {:keyword_list, :pos_integer}, ...]`. NimbleOptions 1.1.1 has no two-arg `:keyword_list` typed form, so the schema raised `ArgumentError: unknown type {:keyword_list, :pos_integer}` at compile/boot, blocking all of Task 2.
- **Fix:** Replaced with `type: :keyword_list, default: [], keys: [*: [type: :pos_integer]]` — the supported idiom that validates the keyword-list shape and constrains every value to a positive integer (same D-02 intent). Verified via a standalone `mix run --no-start` probe before applying.
- **Files modified:** accrue/lib/accrue/config.ex
- **Verification:** `mix compile --warnings-as-errors` clean; the limits-type behavior is exercised by the valid-config test.
- **Committed in:** `01cc314` (Task 2 commit)

**2. [Rule 1 - Bug] Test attempted to validate the entitlements fragment in isolation via `validate!/1`**
- **Found during:** Task 2 (running the test against the real schema)
- **Issue:** One Task 1 test called `Config.validate!(repo: ..., entitlements: ...)`, but `validate!/1` validates the FULL schema — `:branding` requires `from_email`/`support_email`, so the call raised on an unrelated key rather than testing entitlements.
- **Fix:** Replaced that test with one that drives the real `validate_at_boot!/0` path (which uses the test-env branding from `config/test.exs`) and asserts the value is readable via `entitlements/0`.
- **Files modified:** accrue/test/accrue/config_entitlements_test.exs
- **Verification:** `mix test test/accrue/config_entitlements_test.exs` → 8 tests, 0 failures.
- **Committed in:** `01cc314` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both auto-fixes were necessary for correctness — the schema-type fix unblocked Task 2 entirely with identical semantics, and the test fix made the assertion actually exercise the entitlements path. No scope creep; the public surface matches the plan exactly.

## Issues Encountered

None beyond the two auto-fixed deviations above.

## Threat Surface

- **T-123-01 (Tampering — duplicate price_id) mitigated:** `validate_entitlements_price_ids!/1` raises `Accrue.ConfigError` at boot, fail-loud (tested).
- **T-123-02 (EoP — malformed schema) mitigated:** NimbleOptions `@schema` boot validation rejects bad types via `validate_at_boot!/0` (tested).
- **T-123-03 (build-time secret leak) accept:** `:entitlements` is non-secret host catalog data read at runtime (`get!/1`), not `compile_env!` — no build-artifact leak surface.
- No new threat surface introduced beyond the plan's `<threat_model>`.

## Known Stubs

None. The `:resolver` default references `Accrue.Entitlements.Resolver.LocalMap`, which does not yet exist — this is an intentional bare-atom literal in the schema (NOT a compile-time reference) and is created by Plan 03 (123-03). Per the plan's `<interfaces>` note, this is expected and not a stub blocking this plan's goal.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The `:entitlements` config foundation is in place: Plan 03's resolver can read `Accrue.Config.entitlements/0` and trust that the catalog was boot-validated and collision-free.
- No migrations, no Ecto schema, no external dependency added.
- `D-14` one-way dependency invariant verified: nothing under `lib/accrue/billing/` references `Accrue.Entitlements.*`.

## Self-Check: PASSED

- FOUND: accrue/lib/accrue/config.ex
- FOUND: accrue/test/accrue/config_entitlements_test.exs
- FOUND: .planning/phases/123-config-core-gate-api-foundation/123-01-SUMMARY.md
- FOUND commit: 994efee (Task 1)
- FOUND commit: 01cc314 (Task 2)

---
*Phase: 123-config-core-gate-api-foundation*
*Completed: 2026-05-22*
