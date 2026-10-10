---
phase: 241-billing-operator-journeys
plan: "06"
subsystem: billing-ui
tags: [phoenix-liveview, refunds, payment-methods, exact-money]

requires:
  - phase: 240
    provides: Existing billing action owners, step-up handling, scoped identity, and review components
  - phase: 241-03
    provides: Validated payment/customer return context and current owner scope
provides:
  - Exact refund review identity, requested amount, remaining refundable amount, currency, and evidence limits
  - Customer payment-method reviews that identify the selected record and supported effect
  - Fresh actor, owner, customer, method, and reviewed-state validation before payment-method dispatch
affects: [241-07]

actuals:
  tokens: 4580
  tasks: 2
  commits: 5
commits: 5
plan_head_before: d86261927e0bf232c3f7a0515deab74fe85d9f9c
plan_head_after: e1013955dfae0296f6dfaf713aa7285aab762465

tech-stack:
  added: []
  patterns:
    - Keep exact refund intent and remaining balance together in the owning ChargeLive review.
    - Reload customer and payment-method state under a freshly resolved actor/owner scope before dispatch.
    - Make review dismissal explicit and clear staged step-up continuations before returning.

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs

key-decisions:
  - "Keep refund amount parsing in integer minor units and show the exact reviewed amount and remaining balance without a parallel money policy."
  - "Revalidate the current actor, owner scope, customer, payment method, and reviewed default/use state before customer payment-method dispatch."
  - "Use Back to payment and Back to customer for review dismissal; dismissal clears staged intent and never dispatches the action."

patterns-established:
  - "Staged billing review presents exact target IDs, current customer/owner state, action, consequence, and evidence limits together."
  - "Busy confirmation controls retain an action-specific label while a request or step-up is pending."

requirements-completed: [JRN-04]

coverage:
  - id: D1
    description: Refund review identifies the exact payment, customer, owner, current state, requested amount and currency, remaining balance, consequence, and evidence limit; dismissal and boundary behavior preserve exact intent.
    requirement: JRN-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/charge_live_test.exs#refund review shows exact payment, customer, owner, state, requested and remaining money
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/charge_live_test.exs#refund amount boundaries preserve blank remaining intent and reject zero, negative, and excess
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/charge_live_test.exs#refund review keeps large and zero-decimal minor units exact
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/charge_live_test.exs#Back to payment dismisses a staged refund and its step-up continuation
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/charge_live_test.exs#refund timeout is counted at the provider boundary and cannot be blindly retried
        status: pass
    human_judgment: false
  - id: D2
    description: Both payment-method action reviews identify the selected method, customer, owner, current default/use state, action consequence, and safe return; stale state is rejected before dispatch.
    requirement: JRN-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/customer_live_test.exs#set-default and delete reviews identify the selected method and customer effect
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/customer_live_test.exs#payment-method confirmation rejects customer default changes made after review
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/customer_live_test.exs#payment-method confirms use authoritative provider counts and timeout never auto-retries
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#staged subscription confirmation stays inert across detail, return, and reopen navigation
        status: pass
    human_judgment: false

duration: 9 min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 06: Refund and Payment-Method Reviews Summary

**Refund and payment-method reviews now name the exact records, intent, customer/owner state, consequences, and evidence limits while revalidating current payment-method authority before dispatch.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-10T01:54:24Z
- **Completed:** 2026-10-10T02:03:47Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Refund review now shows the selected payment and record ID, customer and owner, current payment state, exact requested minor units and currency, remaining refundable amount, and the limit that provider acceptance is not settlement evidence.
- Refund review dismissal says **Back to payment** and clears a pending step-up challenge/continuation. Confirmation stays disabled during step-up and uses the existing submitting label during dispatch.
- Both set-default and delete payment-method reviews show the method and customer IDs, owner, current default/use state, action, and action-specific consequence. Dismissal says **Back to customer**.
- Payment-method confirmation resolves the current actor and owner scope, reloads the customer and selected method, and denies changed default/use state before calling the existing billing action owner.
- Added exact boundary coverage for blank-as-remaining, zero, negative, over-remaining, zero-decimal JPY, and the largest tested value supported by the persisted signed 32-bit amount column.

## Task Commits

1. **Task 1: Make refund review exact and preserve its held action** - `d69a5044` (feat)
2. **Task 2: Make payment-method review identify the selected method** - `3c6fc18c` (feat)

Post-wave integration correction: `e1013955` (fix) removes two obsolete pattern bindings found by the warnings-as-errors compile.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/charge_live.ex` - Renders exact refund review facts, evidence limits, clear dismissal, and step-up disabled state.
- `accrue_admin/test/accrue_admin/live/charge_live_test.exs` - Covers review identity/money, refund boundaries, large JPY minor units, and dismissal without running a pending continuation.
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` - Adds selected-method review state/effect and fresh actor/owner/customer/method validation before dispatch.
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - Covers set-default/delete review identity and effect, safe dismissal, and stale default rejection.

## Decisions Made

- Refund money remains represented and validated in integer minor units by ChargeLive's existing parser; review formatting uses the existing MoneyFormatter.
- A payment-method review is bound to its original customer default and selected method state. A changed snapshot is denied and requires a fresh review.
- Processor/provider observations remain distinct from settlement or payment completion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Revalidate the current actor and owner before payment-method dispatch**
- **Found during:** Task 2 (Make payment-method review identify the selected method)
- **Issue:** Confirmation reloaded the selected method but used the customer and owner snapshot from initial LiveView mount, so an intervening actor, owner, or relevant payment-method state change was not proven fresh.
- **Fix:** Resolve the owner scope again, compare the fresh actor and scope to the staged context, reload the customer and method, and compare reviewed default/use state before dispatch.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `accrue_admin/test/accrue_admin/live/customer_live_test.exs`
- **Verification:** CustomerLive suite passed (19 tests, 0 failures); stale default change is explicitly rejected.
- **Committed in:** `3c6fc18c`

**2. [Rule 3 - Blocking issue] Remove stale pattern bindings after fresh action revalidation**
- **Found during:** Post-wave integrated warnings-as-errors compile
- **Issue:** The set-default and delete event patterns bound method IDs that were no longer read after confirmation switched to the staged-action revalidation helper.
- **Fix:** Match those branches on action type only; the helper continues to resolve and validate the staged method ID.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`
- **Verification:** `MIX_ENV=test mix compile --warnings-as-errors` passed; full `MIX_ENV=test mix test` passed (642 tests, 0 failures).
- **Committed in:** `e1013955`

**Total deviations:** 2 auto-fixed (Rule 2: 1; Rule 3: 1). **Impact:** Preserved fresh confirmation checks and resolved the integrated warnings-as-errors failure without changing behavior.

## Issues Encountered

- The database stores charge minor-unit amounts in a signed 32-bit integer column. The large-amount test uses a value near that supported upper bound rather than an unrepresentable fixture.
- The seeded charge already had a 2,500 minor-unit refund, leaving 7,500 refundable. Boundary assertions were aligned to that fixture and retained the existing parser behavior.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The two action owners have focused automated coverage. Plan 241-07 remains responsible for the combined build, mounted-host/browser, held-busy/reconnect, keyboard/focus, and served-asset checks; JRN-04 phase-level closure remains pending that integration proof.

## Security Acceptance Follow-up

- Follow-up added authoritative `Accrue.Processor.Fake.call_count/1` assertions for refund and payment-method actions, including timeout/reconnect/no-repeat cases. Persisted refund rows are not used as provider-call evidence.
- The subscription navigation/reopen regression asserts zero provider calls for a staged and dismissed action.
- Combined focused verification after the follow-up: ChargeLive, CustomerLive, and SubscriptionLive, 80 tests, 0 failures; both Admin and host warnings-as-errors compiles passed. Commit is recorded in `241-SECURITY-FIX.md`.
- Follow-up commits: `9001df28` covers refund/payment-method dispatch and uncertain results; `3ee303c6` covers subscription navigation and stale confirmation.
- Post-wave validation passed: warnings-as-errors compilation and the complete Admin package test suite (642 tests, 0 failures).

## Self-Check: PASSED

- All four modified source/test files exist.
- Task commits `d69a5044`, `3c6fc18c`, and post-wave correction `e1013955` are ancestors of HEAD.
- Plan evaluation scope resolved the plan commits on this branch.
- ChargeLive owner suite: 20 tests, 0 failures. CustomerLive owner suite: 19 tests, 0 failures. Full Admin suite: 642 tests, 0 failures; warnings-as-errors compile passed.
- No new placeholder/TODO/FIXME stub pattern was introduced.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*
