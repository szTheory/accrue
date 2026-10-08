---
phase: quick-261008-ffy
verified: 2026-10-08T15:17:40Z
status: passed
score: 3/3 must-haves verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/quick/261008-ffy-repair-phase-235-regression-gaps-by-isol/261008-ffy-PLAN.md
  - .planning/quick/261008-ffy-repair-phase-235-regression-gaps-by-isol/261008-ffy-SUMMARY.md
  - examples/accrue_host/lib/accrue_host/billing.ex
  - examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs
covered_digest: "v3:sha256:30fee9bdd04e56adecb049e5a0fb161d07c2152cab86bf24d08f85741e77fc7a"
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 261008-ffy Verification Report

**Goal:** Isolate the Phase 235 Braintree return tests to the configured processor, preserve the generic generated facade contract, and run the focused suite in the required Braintree CI lane.
**Verified:** 2026-10-08T15:17:40Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

| # | Must-have truth | Status | Evidence |
|---|---|---|---|
| 1 | Default host tests use Fake with no Braintree return cases; the flagged module runs all eight tests. | ✓ VERIFIED | `config/test.exs:30-34` selects Fake unless the exact flag is `"1"`, then selects Braintree. The test module is wrapped in that same exact condition. Independently ran the focused file without the flag: 0 tests, 0 failures; with the flag: 8 tests, 0 failures. Full default host suite: 222 tests, 0 failures (`mix test --warnings-as-errors`). |
| 2 | The host facade's public checkout documentation is processor neutral, scoped checkout behavior remains, and the installer template is generic. | ✓ VERIFIED | `billing.ex:221-250` documents membership, billing permission, and a processor Customer without naming a provider; the function still resolves current membership, checks `:checkout_complete`, finds the existing Braintree Customer, and returns its LocalSession. The installer template has generic facade prose and no provider jargon. The existing facade contract test checks both source files and passed: 18 tests, 0 failures. |
| 3 | The merge-blocking `playwright-e2e` job runs the focused test file with the Braintree flag before its Braintree browser lane, and workflow syntax/step contract pass. | ✓ VERIFIED | `ci.yml:10-14` lists `playwright-e2e` as merge-blocking; the job uses a shard matrix at `1488-1493`. At `1615-1618`, the named focused ExUnit step sets the exact flag and runs the exact test path immediately before fixture refresh (`1620`) and the Braintree browser step (`1625-1629`). `actionlint .github/workflows/ci.yml` passed. The plan's Ruby YAML step-contract check passed with `/usr/bin/ruby`; the configured shim had no Ruby version selected. |

**Score:** 3/3 must-haves verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs` | Flag-gated provider return proof | ✓ VERIFIED | Substantive eight-case module and fixture helpers; exact environment gate confirmed with both default and flagged test invocations. |
| `examples/accrue_host/lib/accrue_host/billing.ex` | Processor-neutral public prose and preserved scoped checkout behavior | ✓ VERIFIED | Documentation is provider-neutral; authorization, Customer resolution, and LocalSession lookup remain present. Facade source contract passed. |
| `accrue/priv/accrue/templates/install/billing.ex.eex` | Generic installer facade template | ✓ VERIFIED | Provider-neutral template; source contract asserts absence of provider-specific jargon and passed. |
| `.github/workflows/ci.yml` | Focused suite in the required Braintree lane | ✓ VERIFIED | Step has correct job, flag, command, and ordering; syntax and machine contract passed. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1` | Braintree test processor and return module | Exact environment check | ✓ WIRED | `config/test.exs` and test module use the same exact flag; observed zero tests unflagged and eight flagged. |
| Host facade and installer template | `BillingFacadeTest` provider-neutral source assertions | Reads both files | ✓ WIRED | The 18-test facade file reads and asserts both source contracts; suite passed. |
| `playwright-e2e` Braintree return step | Focused ExUnit module | Step-level env and `mix test` path | ✓ WIRED | Exact flag/path verified by Ruby contract and actionlint; immediately precedes fixture refresh and browser lane. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Default focused file defines no Braintree cases | `mix test test/accrue_host_web/live/subscription_live_braintree_test.exs` | 0 tests, 0 failures | ✓ PASS |
| Flagged return module executes all cases | `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 mix test test/accrue_host_web/live/subscription_live_braintree_test.exs` | 8 tests, 0 failures | ✓ PASS |
| Generic host suite works under Fake | `mix test --warnings-as-errors` | 222 tests, 0 failures | ✓ PASS |
| Facade source contract covers both facade sources | `mix test test/accrue_host/billing_facade_test.exs` | 18 tests, 0 failures | ✓ PASS |
| Required workflow is syntactically valid | `actionlint .github/workflows/ci.yml` | Exit 0 | ✓ PASS |
| CI job, ordering, flag, and command contract | Ruby YAML assertion from PLAN, using `/usr/bin/ruby` | Exit 0 | ✓ PASS |

These tests exercise the repository's configured test processor and fixtures. They do not provide live Braintree provider evidence.

## Requirements Coverage

No requirement IDs are declared in this quick-task plan.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `subscription_live_braintree_test.exs` | 60 | “Stripe placeholder” appears in a test description | ℹ️ Info | Negative assertion description only; not a placeholder implementation. No debt markers or stub implementations found. |

## Human Verification Required

None. The quick-task acceptance criteria are covered by automated tests and workflow checks. Live-provider checkout evidence was not part of the criteria and was not claimed.

## Gaps Summary

No must-have gaps found. The configured default and flagged test paths, facade contract, and required CI wiring all match the plan and passed their checks.

---

_Verified: 2026-10-08T15:17:40Z_  
_Verifier: gsd-verifier_
