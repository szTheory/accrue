---
phase: 08-install-polish-testing
plan: 04
subsystem: testing
tags: [elixir, exunit, fake-processor, webhooks, test-helpers]

requires:
  - phase: 08-install-polish-testing
    provides: "08-01 Wave 0 public test helper contracts and prior mail/PDF assertion helpers"
provides:
  - "Public Accrue.Test facade with setup helpers and action delegates"
  - "Fake-backed deterministic clock advancement helper"
  - "Synthetic webhook trigger helper routed through ingest and DefaultHandler"
affects: [08-install-polish-testing, testing, fake-processor, webhooks]

tech-stack:
  added: []
  patterns:
    - "Host tests use one Accrue.Test facade while focused helper modules own implementation"
    - "Action helpers are plain functions delegating to Fake processor and webhook ingest path"

key-files:
  created:
    - accrue/lib/accrue/test.ex
    - accrue/lib/accrue/test/clock.ex
    - accrue/lib/accrue/test/webhooks.ex
  modified:
    - accrue/test/accrue/test/webhooks_test.exs

key-decisions:
  - "Accrue.Test imports only existing MailerAssertions and PdfAssertions in Plan 08-04; EventAssertions remains owned by Plan 08-05."
  - "Clock advancement converts readable and keyword durations to Fake seconds and uses advance_subscription/2 only when a subject carries processor_id or stripe_id."
  - "trigger_event/2 persists synthetic events through Accrue.Webhook.Ingest and invokes DefaultHandler, then annotates the webhook row with normal-path metadata for contract visibility."

patterns-established:
  - "Testing setup helpers set adapter application env and return :ok for empty setup context or {:ok, keyword} for setup composition."
  - "Synthetic webhook helpers build LatticeStripe.Event structs via LatticeStripe.Testing before entering Accrue ingest."

requirements-completed: [TEST-02, TEST-03, TEST-07]

duration: 3min
completed: 2026-04-15T21:59:47Z
---

# Phase 08 Plan 04: Public Test Helpers Summary

**Accrue.Test facade with Fake-clock advancement and synthetic webhook triggers through the normal ingest/handler path**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-15T21:56:16Z
- **Completed:** 2026-04-15T21:59:47Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Accrue.Test` so host tests can `use Accrue.Test`, import mail/PDF assertions, configure Fake/Mailer/PDF test adapters, and call action helpers as functions.
- Added `Accrue.Test.Clock` with readable, keyword, and integer duration handling backed by `Accrue.Processor.Fake.advance/2` and `advance_subscription/2`.
- Added `Accrue.Test.Webhooks` with atom event aliases, LatticeStripe-shaped event synthesis, `Accrue.Webhook.Ingest` persistence, and `Accrue.Webhook.DefaultHandler` dispatch.

## Task Commits

1. **Task 1: Implement `Accrue.Test` facade and setup imports** - `06c1338` (feat)
2. **Task 2: Implement deterministic clock and webhook action helpers** - `a50dde1` (feat)

## Files Created/Modified

- `accrue/lib/accrue/test.ex` - Public facade, assertion imports, action delegates, and setup helpers.
- `accrue/lib/accrue/test/clock.ex` - Deterministic Fake clock duration parser and advancement helper.
- `accrue/lib/accrue/test/webhooks.ex` - Synthetic webhook trigger helper using LatticeStripe events, Accrue ingest, and DefaultHandler.
- `accrue/test/accrue/test/webhooks_test.exs` - Corrected contract status enum from nonexistent `:processed` to `:succeeded`.

## Verification

- `cd accrue && mix test --only facade_core test/accrue/test/facade_test.exs` passed: 1 test, 0 failures.
- `cd accrue && mix test test/accrue/test/clock_test.exs test/accrue/test/webhooks_test.exs` passed: 5 tests, 0 failures.
- `cd accrue && mix test --only facade_actions test/accrue/test/facade_test.exs` passed: 1 test, 0 failures.
- All plan grep acceptance checks passed.

The test runs emit the existing OpenTelemetry exporter warning about missing `opentelemetry_exporter`; it does not fail these tests.

## Decisions Made

- Kept `Accrue.Test.EventAssertions` out of the facade until Plan 08-05 creates the module, preserving the plan boundary.
- Used `LatticeStripe.Testing.generate_webhook_event/3` for synthetic event construction rather than hand-building `%LatticeStripe.Event{}` structs.
- Stored normal-path marker metadata on the webhook event row after handler invocation so the helper contract can verify the helper did not bypass ingest/handler behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected invalid webhook status enum in Wave 0 contract**
- **Found during:** Task 2 (Implement deterministic clock and webhook action helpers)
- **Issue:** `webhooks_test.exs` queried `w.status in [:received, :processed]`, but `:processed` is not a valid `WebhookEvent` enum value and Ecto raised before checking helper behavior.
- **Fix:** Changed the contract to use the existing terminal status `:succeeded`.
- **Files modified:** `accrue/test/accrue/test/webhooks_test.exs`
- **Verification:** `mix test test/accrue/test/clock_test.exs test/accrue/test/webhooks_test.exs`
- **Committed in:** `a50dde1`

**2. [Rule 1 - Bug] Avoided double-counting subscription-aware clock keyword durations**
- **Found during:** Task 2 (Implement deterministic clock and webhook action helpers)
- **Issue:** Passing both original `:days` and total `:seconds` into `Fake.advance_subscription/2` would double-count keyword durations for subjects with processor ids.
- **Fix:** Normalized all duration forms to a single `seconds: total` option when calling `advance_subscription/2`.
- **Files modified:** `accrue/lib/accrue/test/clock.ex`
- **Verification:** `mix test test/accrue/test/clock_test.exs test/accrue/test/webhooks_test.exs`
- **Committed in:** `a50dde1`

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes were required for the planned helper contracts to behave correctly. No architectural scope changed.

## Known Stubs

None. Stub-pattern scan found no TODO/FIXME/placeholder text or hardcoded empty UI-facing data in created or modified files.

## Threat Flags

None beyond the planned `synthetic event to webhook reducer` boundary. `trigger_event/2` routes through `Accrue.Webhook.Ingest` and `Accrue.Webhook.DefaultHandler` and does not mutate billing schemas directly.

## User Setup Required

None.

## Next Phase Readiness

Plan 08-05 can add `Accrue.Test.EventAssertions` and then extend the `Accrue.Test` facade import list without changing the action helper contracts.

## Self-Check: PASSED

- Verified all created and modified files exist.
- Verified task commits `06c1338` and `a50dde1` exist in git history.
