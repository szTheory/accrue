---
phase: 237-admin-invoices-payments-recovery
plan: "05"
subsystem: payments
tags: [phoenix-liveview, invoices, owner-scope, stripe, idempotency]
requires:
  - phase: 237-admin-invoices-payments-recovery
    provides: Owner-scoped invoice details and stable invoice action/result fixtures
provides:
  - Fresh actor, owner scope, eligibility, and invoice-fact checks before invoice action dispatch, including step-up continuation
  - Exact reviewed amount and currency in invoice confirmations, with ambiguous and requires-action outcomes kept distinct
affects: [invoice-actions, payments, admin-ui, phase-237-verification]
actuals:
  tokens: 5968
  tasks: 2
  commits: 2
commits: 2
tech-stack:
  added: []
  patterns: [fresh owner-scoped review fingerprint, evidence-specific invoice result messaging]
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
key-decisions:
  - "Re-resolve the host actor and owner scope, reload the same invoice, and compare its action, status, owner, processor IDs, exact minor-unit amounts, and currency before each dispatch boundary."
  - "Require a fresh scoped invoice row for success messaging; processor CardError is definitive, while other processor errors remain unconfirmed and are never replayed automatically."
requirements-completed: [ADM-05]
coverage:
  - id: D1
    description: "Invoice action confirmation is bound to the current actor, owner scope, eligibility, and exact reviewed invoice facts."
    requirement: ADM-05
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#payment review shows exact amount and cancels when amount or currency changes"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#step-up continuation cancels when invoice leaves the reviewed owner scope"
        status: pass
    human_judgment: false
  - id: D2
    description: "Invoice payment, finalization, requires-action, decline, and ambiguous results are described from scoped evidence without automatic retry or settlement overclaim."
    requirement: ADM-05
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#payment result is tied to the refreshed scoped invoice and duplicate confirm is inert"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#finalization result names the refreshed invoice state"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#requires-action payment result stays distinct from a completed invoice"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#definitive card decline is distinct from an ambiguous processor outcome"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#ambiguous payment error stays unconfirmed and is not automatically retried"
        status: pass
      - kind: integration
        ref: "cd accrue_admin && mix test --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-10-08
status: complete
plan_head_before: 9d3ca3a040d180ed83512bf0f5ed7080d37714be
plan_head_after: c660b7fdf21005b2bbd9f88e3de48c699a0be30c
---

# Phase 237 Plan 05: Invoice Action Review and Outcomes Summary

**Invoice actions now dispatch only against freshly reauthorized reviewed facts, and outcomes distinguish scoped completion, required customer action, definitive decline, and unconfirmed processor responses.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-09T00:38:00Z
- **Completed:** 2026-10-09T00:47:48Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Staged invoice reviews now record actor, owner-scope identity, target ID, action, currency, integer amount, status, and a fact fingerprint; the actor and target are re-resolved before confirmation and again after step-up.
- Review blocks unsupported money facts and displays the exact amount and currency identifier alongside the action consequence.
- Successful results are grounded in a freshly reloaded invoice within current owner scope. Requires-action is not completion; typed card decline is definitive; other errors remain unconfirmed and are not retried.
- Repeated confirmation after dispatch is inert, and focused LiveView tests exercise the stale-review and result branches.

## Task Commits

1. **Task 1: Revalidate staged invoice action after review and step-up** - `7638d94d` (`fix`)
2. **Task 2: Render invoice action outcomes from scoped evidence** - `c660b7fd` (`test`)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - Captures review facts, reauthorizes scope and actor at dispatch, rejects stale actions, and renders evidence-specific outcomes.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - Covers exact review facts, amount/currency drift, scope loss after step-up, deduplication, finalization, success, requires-action, definitive decline, and ambiguous outcomes.

## Decisions Made

- Use the existing idempotent Billing operations only after reloading the same invoice through the current owner scope and matching the reviewed action/facts.
- Do not infer processor settlement from a local audit event or a generic successful return; state what the freshly scoped invoice reports.
- Keep `ADM-05` pending in milestone requirements until sibling plan 237-08 is also summarized.

## Deviations from Plan

None. The implementation follows the existing invoice and step-up flows and adds automated coverage at the LiveView boundary.

## Issues Encountered

- `roadmap.update-plan-progress 237` returned `missing_phase_details` even though Phase 237 has a detail section and progress row. Per the execution instruction, the Phase 237 plan checkbox and its own progress count were updated manually; no other roadmap entries were changed.
- Before the implementation, failing focused assertions showed that the review omitted amount/currency and that owner-scope loss after step-up still reached the void operation. Both now pass with no processor call on stale scope.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` — **22 tests, 0 failures**.
- `cd accrue_admin && mix test --warnings-as-errors` — **581 tests, 0 failures**.
- `git diff --check` — passed.

No confirmation-only UAT remains for this plan; the invoice review and result behavior is covered by recurring automated tests.

## Next Phase Readiness

Plan 237-05 is complete. `ADM-05` remains Pending in `.planning/REQUIREMENTS.md` because plan 237-08 is still outstanding. Phase 237 browser and CI proof remains for plan 237-08.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Both measured task commits (`7638d94d`, `c660b7fd`) are ancestors of the current HEAD.
- Canonical milestone requirement `ADM-05` remains Pending until all declaring plans finish.

---
*Phase: 237-admin-invoices-payments-recovery*
*Completed: 2026-10-08*
