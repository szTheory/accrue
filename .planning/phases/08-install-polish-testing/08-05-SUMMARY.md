---
phase: 08-install-polish-testing
plan: 05
subsystem: testing
tags: [elixir, exunit, test-helpers, mailer, pdf, event-ledger]

requires:
  - phase: 08-install-polish-testing
    provides: "08-01 Wave 0 side-effect assertion contracts and 08-04 Accrue.Test facade"
provides:
  - "Event ledger assertion macros imported through Accrue.Test"
  - "Shared matcher semantics for mail, PDF, and event side-effect assertions"
  - "Observed side-effect diagnostics for failed assertions without raw event payload dumps"
affects: [08-install-polish-testing, testing, event-ledger, email-pdf]

tech-stack:
  added: []
  patterns:
    - "Process-mailbox side-effect assertions collect observed messages and match against normalized keyword/map/predicate filters"
    - "Event ledger assertion failures summarize event type/subject/actor instead of dumping raw data payloads"

key-files:
  created:
    - accrue/lib/accrue/test/event_assertions.ex
  modified:
    - accrue/lib/accrue/test.ex
    - accrue/lib/accrue/test/mailer_assertions.ex
    - accrue/lib/accrue/test/pdf_assertions.ex

key-decisions:
  - "Event assertions query the sandbox-visible accrue_events table directly and return the matched Event struct."
  - "Mail/PDF assertions keep process-local capture as the default and document owner/global naming without adding global state."
  - "Failure diagnostics summarize observed side effects with matcher details while avoiding raw event data payload output."

patterns-established:
  - "Assertion matchers normalize atom/string keyword filters, maps, and one-arity predicates through small public test helper internals."
  - "PDF predicate matching prefers normalized render data but falls back to raw HTML for backward compatibility."

requirements-completed: [TEST-04, TEST-05, TEST-06, TEST-07]

duration: 7min
completed: 2026-04-15T22:19:06Z
---

# Phase 08 Plan 05: Side-Effect Assertion Helpers Summary

**Mail, PDF, and event ledger assertions with normalized matchers and observed side-effect diagnostics**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-15T22:12:45Z
- **Completed:** 2026-04-15T22:19:06Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Accrue.Test.EventAssertions` with `assert_event_recorded/1,2`, `refute_event_recorded/1,2`, and `assert_no_events_recorded/1`.
- Imported event assertions through `use Accrue.Test` so host tests get mail, PDF, event, clock, and webhook helpers from one facade.
- Extended mail and PDF assertion helpers with normalized keyword/map/predicate matcher support and failure messages containing `Observed emails:` / `Observed PDFs:`.

## Task Commits

1. **Task 1: Add event ledger assertions and facade import** - `4e3406b` (feat)
2. **Task 2: Extend mail/PDF assertions with shared matcher semantics** - `ecf2316` (feat)

## Files Created/Modified

- `accrue/lib/accrue/test/event_assertions.ex` - Event ledger assertion macros, subject normalization, partial data matching, predicates, and sanitized observed-event summaries.
- `accrue/lib/accrue/test.ex` - Imports `Accrue.Test.EventAssertions` through the public facade.
- `accrue/lib/accrue/test/mailer_assertions.ex` - Normalized matcher support, observed email summaries, and explicit process-local capture docs.
- `accrue/lib/accrue/test/pdf_assertions.ex` - Normalized matcher support, `invoice_id` matching, observed PDF summaries, and explicit process-local capture docs.

## Verification

- `cd accrue && mix test test/accrue/test/event_assertions_test.exs` passed: 5 tests, 0 failures.
- `cd accrue && mix test --only facade_side_effects test/accrue/test/facade_test.exs` passed: 1 test, 0 failures.
- `cd accrue && mix test test/accrue/test/mailer_assertions_test.exs test/accrue/test/pdf_assertions_test.exs test/accrue/test/facade_test.exs` passed: 32 tests, 0 failures.
- `cd accrue && mix test test/accrue/test/mailer_assertions_test.exs test/accrue/test/pdf_assertions_test.exs test/accrue/test/event_assertions_test.exs test/accrue/test/facade_test.exs` passed: 37 tests, 0 failures.
- All task grep acceptance checks passed.

The test runs emit the existing OpenTelemetry exporter warning about missing `opentelemetry_exporter`; it does not fail these tests.

## Decisions Made

- Event assertions read the current test sandbox's `accrue_events` rows through `Accrue.Repo.all/1` and return the matched `%Accrue.Events.Event{}` for further assertions.
- Event failure output includes matcher, observed count, and type/subject/actor summaries only; raw event `data` payloads are intentionally not printed.
- Mail/PDF assertion collection still uses process-local messages from the existing test adapters. No `Process.put` capture registry or global store was introduced.
- PDF `matches:` predicates receive normalized render data first and fall back to raw HTML to preserve existing helper behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved legacy predicate and failure-message compatibility while adding richer matchers**
- **Found during:** Task 2 (Extend mail/PDF assertions with shared matcher semantics)
- **Issue:** The first matcher rewrite broke existing PDF predicates that expected raw HTML and older tests that matched `did not match` failure text.
- **Fix:** Added predicate fallback to raw HTML and kept `did not match` in assertion failures while appending observed side-effect summaries.
- **Files modified:** `accrue/lib/accrue/test/mailer_assertions.ex`, `accrue/lib/accrue/test/pdf_assertions.ex`
- **Verification:** `mix test test/accrue/test/mailer_assertions_test.exs test/accrue/test/pdf_assertions_test.exs test/accrue/test/facade_test.exs`
- **Committed in:** `ecf2316`

**2. [Rule 1 - Bug] Avoided string-key lookup crashes for PDF option matchers**
- **Found during:** Task 2 (Extend mail/PDF assertions with shared matcher semantics)
- **Issue:** `Keyword.get/3` raises when passed a string key, so mixed atom/string PDF matcher support could crash before returning an assertion failure.
- **Fix:** Added explicit list scanning for string-key keyword entries while keeping atom-key `Keyword.get/3` for normal options.
- **Files modified:** `accrue/lib/accrue/test/pdf_assertions.ex`
- **Verification:** `mix test test/accrue/test/mailer_assertions_test.exs test/accrue/test/pdf_assertions_test.exs test/accrue/test/facade_test.exs`
- **Committed in:** `ecf2316`

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes preserved the planned matcher semantics and kept existing public helper behavior compatible.

## Known Stubs

None. Stub-pattern scan found no TODO/FIXME/placeholder text or hardcoded empty UI-facing data in created or modified files.

## Threat Flags

None beyond the planned event ledger assertion read surface. Failure output summarizes event type, subject, and actor only and does not print raw Stripe payloads, request bodies, API keys, signing secrets, or event `data`.

## User Setup Required

None.

## Next Phase Readiness

Plan 08-07 can document the full Fake-first testing flow using `use Accrue.Test`, `advance_clock/2`, `trigger_event/2`, `assert_email_sent`, `assert_pdf_rendered`, and `assert_event_recorded`.

## Self-Check: PASSED

- Verified all created and modified files exist.
- Verified task commits `4e3406b` and `ecf2316` exist in git history.

---
*Phase: 08-install-polish-testing*
*Completed: 2026-04-15*
