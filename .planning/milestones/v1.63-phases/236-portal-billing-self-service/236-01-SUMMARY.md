---
phase: 236-portal-billing-self-service
plan: 01
subsystem: payments
tags: [portal, invoices, phoenix-liveview, exunit, tenant-isolation]

# Dependency graph
requires: []
provides:
  - Customer-scoped invoice outcomes and existing hosted invoice access.
  - Visible billed identity, bounded-history language, and distinct empty/unavailable states.
affects: [portal-billing-self-service, portal-home, invoice-access]

# Actuals (#2632): chars/4 over the realized plan diff.
actuals:
  tokens: 1768
  tasks: 2
  commits: 2
plan_head_before: b3545057d645ca6e5849edb27a686fff48210c61
plan_head_after: ff6263d0c41c1bcf72955865857c2dba7a1e1c7b

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Represent customer-facing invoice reads as explicit success or unavailable results."
    - "Render hosted invoice actions only from Customer-scoped records and state the 20-record bound."

key-files:
  created: []
  modified:
    - accrue_portal/lib/accrue_portal/billing_read_model.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/lib/accrue_portal/live/invoices_live.ex
    - accrue_portal/test/accrue_portal/live/invoices_live_test.exs

key-decisions:
  - "Invoice reads return an explicit unavailable result instead of rendering a failed read as an empty list."
  - "Billed identity uses the host-resolved display name, then the authorized Customer name or email for personal contexts."
  - "Keep the existing 20-invoice query limit and describe it as up to 20 recent invoices without retention or completeness promises."

patterns-established:
  - "Customer-facing invoice states distinguish populated, successful-empty, and unavailable results."
  - "Retry navigation preserves the signed context locator so the normal authorization path runs again."

requirements-completed: [POR-01, POR-03, POR-04, POR-06]

coverage:
  - id: D1
    description: "The invoice page identifies the billed entity and displays hosted invoice records for the authorized Customer."
    requirement: POR-01
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/invoices_live_test.exs#invoices page renders only the current customer's invoice history"
        status: pass
    human_judgment: false
  - id: D2
    description: "Foreign invoices and invoices without hosted URLs never expose a usable invoice action."
    requirement: POR-03
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/invoices_wrong_tenant_test.exs#signed-in customers cannot see foreign invoices on invoice history pages"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/invoices_live_test.exs#invoices without a hosted URL do not render an open action"
        status: pass
    human_judgment: false
  - id: D3
    description: "Successful empty reads and failed reads render distinct, announced states, with an authorized retry path."
    requirement: POR-04
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/invoices_live_test.exs#successful empty invoice reads show the approved empty state without retention promises"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/invoices_live_test.exs#failed invoice reads are announced as unavailable instead of appearing empty"
        status: pass
    human_judgment: false
  - id: D4
    description: "Invoice copy states that the list shows up to 20 recent records and makes no retention or complete-history promise."
    requirement: POR-06
    verification:
      - kind: integration
        ref: "test/accrue_portal/live/invoices_live_test.exs#invoices page renders only the current customer's invoice history"
        status: pass
      - kind: integration
        ref: "test/accrue_portal/live/invoices_live_test.exs#successful empty invoice reads show the approved empty state without retention promises"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-10-08
status: complete
---

# Phase 236 Plan 01: Scoped Invoice Access Summary

**Authorized customers see only their invoice records, actionable hosted links, and truthful empty or unavailable outcomes.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-08T16:25:55Z
- **Completed:** 2026-10-08T16:37:40Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Kept invoice reads scoped to the authorized Customer; the current Customer's hosted URL renders while foreign records remain hidden.
- Made absent hosted URLs non-actionable and added visible billed identity plus up-to-20-recent-invoices copy.
- Added deterministic unavailable-read injection, an announced error state with context-preserving retry, and a separate successful-empty state.
- Removed the unsupported seven-year retention claim.

## Task Commits

1. **Task 1: Open a scoped hosted invoice from selected billing context** - `1ec6dd03` (`feat`)
2. **Task 2: Distinguish empty invoice history from failed reads** - `ff6263d0` (`fix`)

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/billing_read_model.ex` - Explicit invoice read result and operational failure mapping.
- `accrue_portal/lib/accrue_portal/copy.ex` - Bounded-history, empty, retry, and unavailable copy.
- `accrue_portal/lib/accrue_portal/live/invoices_live.ex` - Scoped invoice rendering and distinct result states.
- `accrue_portal/test/accrue_portal/live/invoices_live_test.exs` - Owner, identity, empty/error, missing-URL, and copy assertions.

## Decisions Made

- Preserve the existing Customer query boundary and hosted invoice destination.
- Use host-provided billed identity first; personal contexts fall back to Customer name or email when present.
- Keep the current list bound and avoid claims about complete history or document retention.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] Provide a visible billed identity in personal contexts**
- **Found during:** Task 1 (Open a scoped hosted invoice from selected billing context)
- **Issue:** The personal context fixture had no `display_name`, and its Customer had no name, so the invoice page could not identify the billed entity.
- **Fix:** Resolve the displayed identity from host `display_name`, then Customer name, then Customer email.
- **Files modified:** `accrue_portal/lib/accrue_portal/live/invoices_live.ex`, `accrue_portal/test/accrue_portal/live/invoices_live_test.exs`
- **Verification:** The invoice route test asserts the authorized Customer email is rendered.
- **Committed in:** `1ec6dd03`

---

**Total deviations:** 1 auto-fixed (1 missing critical). **Impact:** Necessary to honor the billed-identity requirement in personal installs; no scope expansion.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Automated Evidence

- `cd accrue_portal && mix test test/accrue_portal/live/invoices_live_test.exs test/accrue_portal/live/invoices_wrong_tenant_test.exs` - 5 tests, 0 failures.
- `cd accrue_portal && mix test.ci` - formatting, warning-as-error compilation and tests, and package audit passed; 87 tests, 0 failures; no retired packages found.

## Next Phase Readiness

Wave 2 plans 236-02 (payment methods) and 236-04 (checkout outcomes) are now unblocked. All invoice deliverables have deterministic passing evidence; no human UAT is needed for this plan.

---
*Phase: 236-portal-billing-self-service*
*Completed: 2026-10-08*

## Self-Check: PASSED

- Summary coverage maps all deliverables to passing automated checks.
- Task commits `1ec6dd03` and `ff6263d0` are ancestors of the recorded plan head.
