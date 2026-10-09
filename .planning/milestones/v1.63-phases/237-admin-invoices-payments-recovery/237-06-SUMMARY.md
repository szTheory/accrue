---
phase: 237-admin-invoices-payments-recovery
plan: "06"
subsystem: payments
tags: [elixir, phoenix-liveview, refunds, money-formatting, owner-scope]
requires:
  - phase: 237-02
    provides: payment outcome and money evidence contracts
provides:
  - Exact supported charge/refund/fee money in list, detail, and refund review
  - Owner-scoped current charge revalidation before refund dispatch, including after step-up
  - Honest local refund evidence and explicit unconfirmed copy for ambiguous outcomes
affects: [admin-payments, refunds, ADM-05]
actuals:
  tokens: 6457
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Reuse MoneyFormatter and render unavailable when currency or amount evidence is unsupported.
    - Reauthorize actor and owner scope, then reload and compare reviewed charge facts immediately before dispatch.
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
key-decisions:
  - "Refund review binds to the provider charge identity, supported currency, exact integer amount, status, and remaining balance."
  - "A stale or out-of-scope review is cancelled before Billing.create_refund; ambiguous provider errors remain unconfirmed and are never retried automatically."
patterns-established:
  - "Treat only a returned local Refund row as refund creation evidence; do not claim processor settlement."
requirements-completed: []
coverage:
  - id: D1
    description: "Charge lists and detail preserve exact supported currency precision and show unsupported or missing evidence as unavailable."
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/charges_live_test.exs#charge list formats supported precision and keeps unknown money unavailable"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/charge_live_test.exs#charge detail preserves zero and three-decimal charge, refund, and fee evidence"
        status: pass
    human_judgment: false
  - id: D2
    description: "Refund review identifies the exact target, remaining refundable amount, and consequence, and blocks unsupported or over-balance values."
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/charge_live_test.exs#refund review identifies the exact charge and refuses an amount above its remaining balance"
        status: pass
    human_judgment: false
  - id: D3
    description: "Refund dispatch reauthorizes and reloads the reviewed charge after step-up, cancelling stale state without a write."
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/charge_live_test.exs#refund confirmation revalidates the reviewed charge after step-up"
        status: pass
      - kind: unit
        ref: "cd accrue_admin && mix test --warnings-as-errors (564 tests)"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-10-08
status: complete
plan_head_before: e4cf32aaa1c4f55627e234bab7c844ca4ab1ede8
plan_head_after: 5023a5dfe3bb5139fd96186ac6ba507cc6107412
commits: 2
---

# Phase 237 Plan 06: Charge and Refund Review Summary

**Charge and refund views now show exact supported money, while staged refunds bind to freshly reauthorized, owner-scoped charge facts before dispatch.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-08T20:14:00-04:00
- **Completed:** 2026-10-08T20:26:00-04:00
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Charge list, detail, fee breakdown, and refund rows use shared currency formatting without defaulting unknown currency or missing evidence to USD or zero.
- Refund action and review require an eligible provider/status and known remaining balance; review names the provider charge identity, exact amount/currency, and local record consequence.
- Before refund dispatch, including after step-up, the app reauthorizes the actor and owner scope, reloads the scoped charge, and compares target, status, amount, currency, refundable balance, and eligibility. A stale review is refreshed and cancelled without a refund write.
- The confirm control enters a pending disabled state. Successful copy is tied to returned local refund evidence; provider ambiguity remains unconfirmed and is not automatically retried.

## Task Commits

1. **Task 1: Complete exact charge and refund money presentation** - `dbd9ede8` (`feat`)
2. **Task 2: Revalidate refund and render result evidence** - `5023a5df` (`fix`)

Plan metadata commit is recorded separately after state and roadmap updates.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/charges_live.ex` - Exact charge list money and unavailable evidence.
- `accrue_admin/lib/accrue_admin/live/charge_live.ex` - Exact refund review, eligibility, pending state, current scoped dispatch revalidation, and evidence copy.
- `accrue_admin/test/accrue_admin/live/charges_live_test.exs` - Currency precision and unavailable charge-list assertions.
- `accrue_admin/test/accrue_admin/live/charge_live_test.exs` - Refund bounds, supported money, and stale-after-step-up cancellation assertions.

## Decisions Made

- Bind the staged review to provider identity plus exact integer amount, currency, status, and current refundable balance.
- Keep ADM-05 pending because this plan shares it with later Phase 237 plans; the requirement checkbox and traceability remain unchanged.
- Use automated LiveView and package test coverage for deterministic outcomes; no confirmation-only UAT is needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented stale refund review facts from dispatching after step-up**
- **Found during:** Task 2 (Revalidate refund and render result evidence)
- **Issue:** The staged action could dispatch using reviewed values after the underlying charge changed.
- **Fix:** Reauthorize actor and scope, reload the charge through scoped `Charges.detail`, compare reviewed facts and eligibility, and cancel/refresh on change.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/charge_live.ex`, `accrue_admin/test/accrue_admin/live/charge_live_test.exs`
- **Verification:** Focused stale-after-step-up assertion and full package suite passed.
- **Committed in:** `5023a5df`.

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** Required to satisfy the plan's concurrency and dispatch-safety criteria; no schema or API changes.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/charge_live_test.exs` — 25 tests, 0 failures.
- `cd accrue_admin && mix test --warnings-as-errors` — 564 tests, 0 failures.
- `git diff --check` — passed.
- No live billing action was submitted.

## Issues Encountered

- `roadmap.update-plan-progress 237` does not recognize the existing Phase 237 layout (`missing_phase_details`). As directed, the Phase 237 plan checkbox/progress row will be updated manually without changing other phases.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Charge/refund behavior is automated and ready for the remaining Phase 237 plans.
- ADM-05 remains pending because later plans also cover it. The unrelated user modifications present before execution remain unstaged and untouched.

## Self-Check: PASSED

- Summary exists; task commits `dbd9ede8` and `5023a5df` are ancestors of HEAD.
- Measured plan ledger reports 2 commits from `e4cf32aaa1c4f55627e234bab7c844ca4ab1ede8` through `5023a5dfe3bb5139fd96186ac6ba507cc6107412`.
- Phase 237 Plan 06 is checked off and progress is 5/8; ADM-05 remains unchecked and pending.

---
*Phase: 237-admin-invoices-payments-recovery*
*Completed: 2026-10-08*
