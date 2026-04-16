---
phase: 02-schemas-webhook-plumbing
plan: 06
subsystem: testing
tags: [exunit, plug-test, stream-data, property-testing, webhook-fixtures, oban-testing]

# Dependency graph
requires:
  - phase: 01-foundations
    provides: Money value type, TestRepo, MoxSetup, test_helper.exs
  - plan: 02-01
    provides: Billing schemas, WebhookEvent schema
provides:
  - ConnCase ExUnit template for Plug/HTTP integration tests
  - WebhookFixtures generating signed/tampered payloads via lattice_stripe
  - StreamData property tests for Money arithmetic (14 properties)
  - Webhook signing secrets configured in test environment
affects: [02-03, 02-04, 02-05, phase-03, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns: [ConnCase for plug tests with Ecto sandbox, WebhookFixtures wrapping lattice_stripe generate_test_signature, StreamData property tests for money math]

key-files:
  created:
    - accrue/test/support/conn_case.ex
    - accrue/test/support/webhook_fixtures.ex
    - accrue/test/property/money_property_test.exs
  modified:
    - accrue/test/test_helper.exs

key-decisions:
  - "WebhookFixtures uses a well-known default secret constant shared with test_helper.exs config"
  - "Property tests cover all three currency exponent classes: zero-decimal, two-decimal, three-decimal"
  - "ConnCase mirrors RepoCase sandbox pattern but adds Plug.Test and Plug.Conn imports"

patterns-established:
  - "WebhookFixtures.signed_event/2 is the canonical way to build signed webhook payloads in tests"
  - "Property tests live in test/property/ directory, separate from example-based tests"
  - "ConnCase for any test exercising Plug pipelines; RepoCase for pure Ecto/DB tests"

requirements-completed: [TEST-09]

# Metrics
duration: 3min
completed: 2026-04-12
---

# Phase 02 Plan 06: Test Infrastructure Summary

**ConnCase template, WebhookFixtures with lattice_stripe signature integration, and 14 StreamData property tests covering Money arithmetic edge cases across all currency exponent classes**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-12T04:35:29Z
- **Completed:** 2026-04-12T04:38:30Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- ConnCase ExUnit template providing Plug.Test/Plug.Conn helpers with Ecto sandbox for HTTP integration tests
- WebhookFixtures module generating signed and tampered webhook payloads via `LatticeStripe.Webhook.generate_test_signature/3`, with convenience helpers for event type-specific payloads
- 14 StreamData property tests exercising Money constructor, addition commutativity/associativity, subtraction identity, cross-currency rejection, and from_decimal roundtrip across zero-decimal (JPY, KRW), two-decimal (USD, EUR), and three-decimal (KWD, BHD) currencies
- Webhook signing secrets configured in test_helper.exs using WebhookFixtures.default_secret/0 for consistent test environment

## Task Commits

Each task was committed atomically:

1. **Task 1: ConnCase + WebhookFixtures + test_helper config** - `36522bf` (feat)
2. **Task 2: StreamData money property tests** - `00ad77f` (test)

## Files Created/Modified

- `accrue/test/support/conn_case.ex` - ExUnit case template for Plug/HTTP tests with sandbox
- `accrue/test/support/webhook_fixtures.ex` - Signed/tampered webhook payload generator
- `accrue/test/property/money_property_test.exs` - 14 StreamData property tests for Money
- `accrue/test/test_helper.exs` - Added webhook signing secrets configuration

## Decisions Made

- WebhookFixtures uses a well-known `whsec_test_secret_for_accrue_tests` constant exposed via `default_secret/0`, shared between the fixture module and `test_helper.exs` config -- single source of truth for the test signing secret
- Property tests cover all three ISO 4217 exponent classes (0, 2, 3) to catch zero-decimal currency bugs that are the most common billing arithmetic error
- ConnCase is kept separate from RepoCase (not inheriting) to maintain clear responsibility -- ConnCase adds Plug imports, RepoCase stays pure Ecto

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ConnCase is ready for Plan 03/04/05 webhook plug tests and dispatch worker tests
- WebhookFixtures provides the signed payload generation that Plan 04 (Ingest + Dispatch) needs
- Property test infrastructure established for future billing arithmetic tests

## Self-Check: PASSED

- All 4 files: FOUND
- Commit 36522bf: FOUND
- Commit 00ad77f: FOUND

---
*Phase: 02-schemas-webhook-plumbing*
*Completed: 2026-04-12*
