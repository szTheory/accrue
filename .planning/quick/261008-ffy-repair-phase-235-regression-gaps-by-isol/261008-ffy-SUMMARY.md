---
phase: quick-261008-ffy
plan: 01
subsystem: testing
tags: [elixir, phoenix, braintree, github-actions, actionlint]
requires:
  - phase: 235-customer-plan-selection-checkout
    provides: Scoped checkout return handling and Braintree return assertions
provides:
  - Braintree return tests run only with the explicit processor flag
  - Processor-neutral scoped checkout facade documentation
  - Required Braintree CI lane runs the focused ExUnit module
affects: [host-checkout, ci]
actuals:
  tokens: 204
  tasks: 3
  commits: 4
tech-stack:
  added: []
  patterns: [Flag-gated provider-specific ExUnit module]
key-files:
  created: []
  modified:
    - examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs
    - examples/accrue_host/lib/accrue_host/billing.ex
    - .github/workflows/ci.yml
key-decisions:
  - "Keep the Braintree return proof in the default test tree but define its module only when the Braintree processor flag is set."
  - "Suppress ShellCheck SC2016 on the existing Node template literal command because its interpolation is JavaScript, not shell expansion."
metrics:
  duration: 3min
  completed: 2026-10-08
status: complete
---

# Quick Task 261008-ffy Summary

**Braintree return proofs are isolated behind the processor flag, documented generically in the host facade, and run in the required CI lane.**

## Accomplishments

- The ordinary Fake-backed host suite discovers zero Braintree return tests; the flagged module runs all eight proofs.
- The scoped checkout function keeps its authorization and processor Customer behavior while its public documentation stays processor neutral.
- The required `playwright-e2e` Braintree lane runs the focused ExUnit suite before refreshing the browser fixture.
- Added a line-scoped ShellCheck suppression with rationale for an existing JavaScript template literal that triggered SC2016.

## Verification

- `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_braintree_test.exs` — 0 tests, 0 failures.
- `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 mix test test/accrue_host_web/live/subscription_live_braintree_test.exs` — 8 tests, 0 failures.
- `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` — 18 tests, 0 failures.
- `cd examples/accrue_host && mix test --warnings-as-errors` — 222 tests, 0 failures.
- `actionlint .github/workflows/ci.yml` — passed.
- Ruby workflow-step contract — passed using `/usr/bin/ruby`; the configured asdf Ruby shim had no version selected.

## Task Commits

1. Task 1 — `1955923d` (`test(261008-ffy): gate Braintree return tests by processor flag`)
2. Task 2 — `5a19c7ce` (`docs(261008-ffy): keep scoped checkout facade prose generic`)
3. Task 3 — `3b9e024c` (`ci(261008-ffy): run Braintree return tests in required lane`)
4. Task 3 verification fix — `42c28c17` (`ci(261008-ffy): suppress false shellcheck interpolation warning`)

## Deviations from Plan

**1. [Rule 3 - Blocking] Suppressed a false-positive ShellCheck warning so the required workflow lint passes.**
- **Found during:** Task 3 verification
- **Issue:** `actionlint` treated JavaScript `${fact.*}` template interpolation in a single-quoted `node -e` argument as shell interpolation.
- **Fix:** Added a line-scoped `SC2016` suppression with a short rationale immediately above the existing command.
- **Files modified:** `.github/workflows/ci.yml`
- **Verification:** `actionlint .github/workflows/ci.yml` and the Ruby CI-step contract passed.
- **Committed in:** `42c28c17`

## Issues Encountered

The asdf Ruby shim could not select a Ruby version from the project configuration. The required YAML step contract ran successfully with the system Ruby at `/usr/bin/ruby`.

## Next Phase Readiness

All planned automated acceptance checks pass. No runtime checkout evidence or authorization logic changed.
