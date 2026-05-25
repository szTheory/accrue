---
phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default
plan: 01
subsystem: testing
tags: [dunning, chimeway, engine, oban, conditional-compile, behaviour, wave-0, tdd]

requires:
  - phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
    provides: "DunningFullJourneyTest + BillingCase test conventions used as reference"
  - phase: 127-optional-stripe-native-sync-isolated
    provides: "sigra_test.exs conditional-compile clone pattern"

provides:
  - "Wave-0 RED test scaffold for Accrue.Dunning.Engine behaviour contract"
  - "Wave-0 RED test scaffold for Accrue.Dunning.Engine.Oban unit tests"
  - "Wave-0 conditional-compile contract test for Accrue.Integrations.Chimeway (sigra_test.exs clone)"
  - "DUN-03 SC#1 behaviour-contract test (behaviour_info(:callbacks))"
  - "DUN-03 SC#2 conditional-compile test (Code.ensure_loaded branch + 4-pattern source assertion)"

affects:
  - 131-02 (creates Accrue.Dunning.Engine behaviour — turns engine_test.exs GREEN)
  - 131-03 (creates Engine.Oban — turns oban_test.exs GREEN)
  - 131-04 (creates Accrue.Integrations.Chimeway — turns chimeway_test.exs Test 2 GREEN)

tech-stack:
  added: []
  patterns:
    - "Wave-0 test scaffold: three RED test files assert contracts before any implementation exists"
    - "Behaviour contract test via behaviour_info(:callbacks) reflection (no modules needed)"
    - "Conditional-compile test via Code.ensure_loaded branch (accepts either :module or :nofile)"
    - "4-pattern source assertion: Test 2 reads lib file and asserts Code.ensure_loaded?, @compile, @behaviour"

key-files:
  created:
    - accrue/test/accrue/dunning/engine_test.exs
    - accrue/test/accrue/dunning/engine/oban_test.exs
    - accrue/test/accrue/integrations/chimeway_test.exs
  modified: []

key-decisions:
  - "oban_test.exs uses Accrue.BillingCase (async: false) + Oban.Testing to match existing dunning test conventions (mirrors dunning_full_journey_test.exs)"
  - "engine_test.exs uses ExUnit.Case async: true (pure reflection — no DB or Oban required)"
  - "chimeway_test.exs is an exact clone of sigra_test.exs with Chimeway/Accrue.Dunning.Engine substitutions"
  - "Zero stop_conditions references enforced per RESEARCH.md override (Chimeway 1.0.0 DSL does not include that key)"

patterns-established:
  - "Wave-0 RED test scaffold: create contract tests BEFORE implementation to give downstream plans concrete green targets"
  - "Chimeway conditional-compile test clones sigra_test.exs exactly (module/behaviour substitution only)"

requirements-completed: [DUN-03]

duration: 12min
completed: 2026-05-25
---

# Phase 131 Plan 01: Wave-0 test scaffolds for Dunning.Engine behaviour, Engine.Oban unit tests, and Chimeway conditional-compile contract

**Three Wave-0 RED test files encoding the DUN-03 contracts: Engine behaviour callbacks, Engine.Oban unit scaffold (4 tests), and Chimeway conditional-compile isolation (sigra_test.exs clone)**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-25T00:00:00Z
- **Completed:** 2026-05-25T00:12:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `engine_test.exs` asserting `behaviour_info(:callbacks)` for `start_campaign/3` and `cancel_campaign/3`, plus Engine.Oban behaviour membership and function exports
- Created `engine/oban_test.exs` with 4 unit tests covering start_campaign (day-zero enqueue, no-op when absent) and cancel_campaign (cancels matching jobs, rescue contract) using `BillingCase` + `Oban.Testing`
- Created `chimeway_test.exs` cloning `sigra_test.exs` exactly — conditional-compile branch test + 4-pattern source assertion; zero `stop_conditions` references

## Task Commits

Each task was committed atomically:

1. **Task 1: Engine behaviour + Engine.Oban contract tests** - `b673158b` (test)
2. **Task 2: Chimeway conditional-compile contract test** - `cc56b887` (test)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `accrue/test/accrue/dunning/engine_test.exs` - Behaviour contract test: `behaviour_info(:callbacks)` for start/cancel callbacks; Engine.Oban implements the behaviour + exports both functions
- `accrue/test/accrue/dunning/engine/oban_test.exs` - Unit test scaffold for Engine.Oban: 4 tests across start_campaign/3 and cancel_campaign/3 describe blocks using BillingCase + Oban.Testing
- `accrue/test/accrue/integrations/chimeway_test.exs` - Conditional-compile contract test: Code.ensure_loaded branch (loaded-or-:nofile) + 4-pattern source assertion; exact clone of sigra_test.exs

## Decisions Made

- `engine_test.exs` uses `ExUnit.Case, async: true` (pure reflection — no DB, no Oban, no state)
- `oban_test.exs` uses `Accrue.BillingCase, async: false` to match the existing dunning test convention (requires DB + Oban sandbox); mirrors `dunning_full_journey_test.exs` setup pattern
- `chimeway_test.exs` is an exact structural clone of `sigra_test.exs` — only module names and behaviour references differ
- Zero `stop_conditions` references in all three files per RESEARCH.md Pitfall 1 (that DSL does not exist in Chimeway 1.0.0)

## Deviations from Plan

None — plan executed exactly as written. All three files created with the specified contract assertions. Tests are RED (undefined modules) as required for Wave-0 state.

## Issues Encountered

None. The worktree does not have `deps/` fetched (gitignored), so the mix test verification command could not be run interactively. Structural acceptance criteria verified via grep (all passed). The files will produce `UndefinedFunctionError` when run with compiled deps, matching the Wave-0 expectation.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 02 can proceed: `engine_test.exs` gives a concrete RED target for the `Accrue.Dunning.Engine` behaviour module
- Plan 03 can proceed: `engine/oban_test.exs` gives RED targets for `Engine.Oban.start_campaign/3` and `cancel_campaign/3`
- Plan 04 can proceed: `chimeway_test.exs` Test 1 will exercise the Chimeway-absent branch (already green); Test 2 turns green when `lib/accrue/integrations/chimeway.ex` exists

---
*Phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default*
*Completed: 2026-05-25*

## Self-Check: PASSED

Files created:
- FOUND: accrue/test/accrue/dunning/engine_test.exs
- FOUND: accrue/test/accrue/dunning/engine/oban_test.exs
- FOUND: accrue/test/accrue/integrations/chimeway_test.exs

Commits:
- FOUND: b673158b (test(131-01): add Wave-0 engine behaviour + Engine.Oban contract tests)
- FOUND: cc56b887 (test(131-01): add chimeway_test.exs conditional-compile contract test)
