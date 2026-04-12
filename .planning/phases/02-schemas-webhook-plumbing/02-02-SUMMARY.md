---
phase: 02-schemas-webhook-plumbing
plan: 02
subsystem: payments
tags: [ecto, macro, polymorphic, billing, fake-processor]

# Dependency graph
requires:
  - phase: 02-01
    provides: Customer schema, Processor behaviour, Events.record_multi, Fake processor
provides:
  - "use Accrue.Billable macro for host schemas"
  - "Accrue.Billing context with customer/1 lazy fetch-or-create"
  - "Accrue.Billing.create_customer/1 with atomic event recording"
  - "Repo.transaction/2 delegate for Ecto.Multi"
affects: [02-03, 02-04, 02-05, 02-06, 03-subscriptions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "before_compile macro for injecting has_one after schema block"
    - "Ecto.Multi atomic customer + event creation"
    - "Polymorphic billable_type derivation with rename-safety override"

key-files:
  created:
    - accrue/lib/accrue/billable.ex
    - accrue/lib/accrue/billing.ex
    - accrue/test/accrue/billable_test.exs
  modified:
    - accrue/lib/accrue/repo.ex

key-decisions:
  - "Used @before_compile to inject has_one after Ecto.Schema schema block runs"
  - "Events.record/1 inside Ecto.Multi.run for transactional event recording"
  - "Processor name derived from adapter module at runtime for portability"

patterns-established:
  - "Billable macro: use Accrue.Billable with optional billable_type override"
  - "Billing context: all write operations via Ecto.Multi with EVT-04 event atomicity"
  - "owner_id coercion: to_string(id) in Billing context, not in association"

requirements-completed: [BILL-02]

# Metrics
duration: 5min
completed: 2026-04-12
---

# Phase 02 Plan 02: Billable Macro + Billing Context Summary

**Polymorphic `use Accrue.Billable` macro with lazy customer fetch-or-create against Fake processor, atomic event recording via Ecto.Multi**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-12T04:20:34Z
- **Completed:** 2026-04-12T04:25:59Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `use Accrue.Billable` macro injects `has_one :accrue_customer` with polymorphic `owner_type` where clause, `__accrue__/1` reflection, and `customer/1` convenience
- `Accrue.Billing.customer/1` lazy fetch-or-create and `create_customer/1` explicit create, both with atomic event recording (EVT-04)
- Round-trip create/fetch against Fake processor verified with 6 passing integration tests
- EVT-04 rollback invariant proven: transaction rollback removes both customer and event rows

## Task Commits

Each task was committed atomically:

1. **Task 1: Accrue.Billable macro** - `377d4b5` (feat)
2. **Task 2: Accrue.Billing context + integration tests (TDD)**
   - RED: `d5a81dc` (test) - 6 tests, 4 failing
   - GREEN: `6ac0f6f` (feat) - all 6 passing

## Files Created/Modified
- `accrue/lib/accrue/billable.ex` - `use Accrue.Billable` macro with before_compile has_one injection
- `accrue/lib/accrue/billing.ex` - Billing context: customer/1, create_customer/1, bang variants
- `accrue/lib/accrue/repo.ex` - Added transaction/2 delegate for Ecto.Multi
- `accrue/test/accrue/billable_test.exs` - 6 tests: macro reflection, CRUD, lazy fetch, EVT-04, rollback

## Decisions Made
- Used `@before_compile` callback to inject `has_one :accrue_customer` -- the association must run after Ecto.Schema's `schema/2` macro sets up module attributes. Calling `has_one` in `__using__` fails because Ecto's internal association registry is not yet initialized.
- Used `Events.record/1` inside `Ecto.Multi.run/3` rather than `Events.record_multi/3` -- both achieve transactional atomicity, but `run/3` allows access to the `%{customer: customer}` changes map for populating `subject_id`.
- Processor name derived from adapter module at runtime via pattern match (`Fake -> "fake"`, `Stripe -> "stripe"`) rather than a config key, keeping the processor string stable across config changes.
- Added `Accrue.Repo.transaction/2` delegate (Rule 3 - blocking) since only `transact/2` existed and `Ecto.Multi` requires `Repo.transaction/2`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] has_one must run after schema block**
- **Found during:** Task 1 (Billable macro)
- **Issue:** `has_one/3` called in `__using__` fails with "not a list" because Ecto.Schema's internal module attributes are not yet set up before the `schema/2` block runs
- **Fix:** Moved `has_one` call to `@before_compile` callback which executes after the schema block
- **Files modified:** `accrue/lib/accrue/billable.ex`
- **Verification:** `mix compile --warnings-as-errors` passes, all tests pass
- **Committed in:** d5a81dc

**2. [Rule 3 - Blocking] Missing Repo.transaction/2 for Ecto.Multi**
- **Found during:** Task 2 (Billing context)
- **Issue:** `Accrue.Repo` only had `transact/2` (for functions), not `transaction/2` needed by `Ecto.Multi` pipelines
- **Fix:** Added `transaction/2` delegate to `Accrue.Repo`
- **Files modified:** `accrue/lib/accrue/repo.ex`
- **Verification:** Billing context round-trip works, all tests pass
- **Committed in:** 6ac0f6f

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes required for basic functionality. No scope creep.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Billable macro and Billing context are ready for downstream plans
- Plan 03 (webhook plug) can proceed -- it uses Billing context for customer reconciliation
- Plans 04-06 build on the Billing context pattern established here
- Fake processor round-trip proven end-to-end

## Self-Check: PASSED

All 4 files verified present. All 3 commits verified in git log.

---
*Phase: 02-schemas-webhook-plumbing*
*Completed: 2026-04-12*
