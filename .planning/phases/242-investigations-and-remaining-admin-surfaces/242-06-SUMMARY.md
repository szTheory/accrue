---
phase: 242-investigations-and-remaining-admin-surfaces
plan: 06
subsystem: ui
tags: [phoenix-liveview, scoped-navigation, billing-copy]
requires:
  - phase: 242-01
    provides: ScopedPath owner-aware path construction
  - phase: 242-02
    provides: Webhook delivery review vocabulary
  - phase: 242-03
    provides: Coupon and promotion-code Copy vocabulary
  - phase: 242-04
    provides: Connect Copy vocabulary
  - phase: 242-05
    provides: Current owner and navigation conventions
provides:
  - Home current path carries the resolved owner scope into shell navigation
  - Invoice list and detail use shared human-readable collection-method labels
  - Central Copy assertions cover catalog state and event/delivery distinctions
affects: [phase-242-07, admin-navigation, billing-copy]
actuals:
  tokens: 2999
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 5961f2088796cb8b0afa4e4c6a135c5cfe69c74e
plan_head_after: 7711400e4353d5d971e4f306f2e28aeb5e904289
tech-stack:
  added: []
  patterns:
    - Derive Home shell route identity through ScopedPath and the resolved owner scope
    - Reuse Copy-owned collection labels in list and detail consumers
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/lib/accrue_admin/components/app_shell_test.exs
    - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/copy_test.exs
    - accrue_admin/test/accrue_admin/copy/billing_event_test.exs
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
key-decisions:
  - "Build Home's current route from the current mount and resolved owner scope so its active nav and destinations share identity."
  - "Use the existing filter labels for routine collection methods and render unknown values as Unknown instead of exposing provider enum text."
requirements-completed: [JRN-07, UXC-01]
coverage:
  - id: D1
    description: Home and shell navigation preserve the current mount and organization scope, with matching Home active state and owner banner.
    requirement: JRN-07
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/components/app_shell_test.exs — 9 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: Invoice list and detail render human collection labels, while central Copy tests preserve coupon definition/code states, zero/unknown distinctions, missing-parent wording, and unknown collection handling.
    requirement: UXC-01
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_admin/copy_test.exs test/accrue_admin/copy test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs — 62 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: Billing event and webhook delivery vocabulary remains distinct, and the review dismissal label keeps deliveries without implying cancellation.
    requirement: UXC-01
    verification:
      - kind: unit
        ref: "test/accrue_admin/copy/billing_event_test.exs — included in the 62-test Copy and invoice consumer run"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-10-10
status: complete
human_judgment: false
---

# Phase 242 Plan 06: Home Navigation and Billing Copy Summary

**Home navigation now retains owner scope, and invoice collection methods render through shared human copy across list and detail views.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-10T13:23:00Z (approximate)
- **Completed:** 2026-10-10T13:27:32Z
- **Tasks:** 2/2
- **Files modified:** 11

## Accomplishments

- Home now builds its current route through `ScopedPath` using the resolved owner scope, so the shell active destination and scoped Home links agree.
- Invoice collection labels are owned by `Copy` and rendered in both invoice list rows and invoice detail fields; unknown values no longer surface raw provider enums.
- Central catalog copy tests distinguish coupon definitions from promotion codes, first-run and filtered-empty states, missing or unavailable parent records, and recorded versus unknown limits. Billing event and webhook delivery terms are separately asserted.
- `Copy.Locked` remained unchanged. No dependencies were added, and Plan 242-07's visual inspection budget was not consumed.

## Task Commits

1. **Task 1: Align Home, sidebar and shell route identity** — `f1145fd3` (`fix`)
2. **Task 2: Reconcile payment, collection and dismissal vocabulary** — `7711400e` (`fix`)

## Verification Results

- Task 1: `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/components/app_shell_test.exs` — **9 tests, 0 failures**.
- Task 2 focused acceptance: `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy_test.exs test/accrue_admin/copy test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs` — **62 tests, 0 failures**.
- The task's shorter `mix test test/accrue_admin/copy` command omits the central `copy_test.exs` catalog assertions. It was included explicitly in the acceptance run, along with the invoice consumers changed to correct rendered copy.
- The runs were non-empty, and `git diff --check` passed before each task commit. The plan evaluation-scope check resolved both task commits.

## Evidence Limits

- Mounted Phoenix LiveView integration tests and shell component rendering cover route identity and copy. No browser capture, responsive visual review, actual zoom, screen-reader speech, provider request, or remote CI result was collected; Plan 242-07 owns the bounded visual pass.
- Scoped route assertions establish the existing owner-scoped Home/event paths and active shell link. They do not claim new organization authorization behavior.

## Decisions Made

- Used `ScopedPath` for Home's shell `current_path` so mount and owner scope follow the same existing contract as its content links.
- Reused existing “Automatic” and “Send invoice” Copy values for collection method rows/details; nil and unrecognized values render “Unknown.”

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Align rendered invoice collection labels with shared Copy**
- **Found during:** Task 2
- **Issue:** The existing invoice detail consumers humanized raw enum values, rendering “Charge Automatically” beside routine payment language; the helper already used by the list was private and unreachable to the detail consumer.
- **Fix:** Added a shared Copy-owned mapping and used it in both the invoice list and invoice detail; unknown values now render “Unknown.” Added unit and mounted consumer regressions.
- **Files modified:** `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/copy/invoice.ex`, `accrue_admin/lib/accrue_admin/live/invoices_live.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue_admin/test/accrue_admin/copy_test.exs`, `accrue_admin/test/accrue_admin/live/invoices_live_test.exs`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`
- **Verification:** The focused Copy and invoice consumer command passed 62 tests with no failures.
- **Committed in:** `7711400e`

**2. Verification command adjustment:** Added the central `copy_test.exs` file to the planned Copy directory command so catalog assertions owned by this plan were actually executed. This did not alter product scope.

**Total deviations:** 1 auto-fixed (Rule 2) and 1 verification-command adjustment.
**Impact on plan:** The shared consumer correction was required for routine collection copy to render coherently in both existing invoice routes. No capability, schema, dependency, or route family was added.

## Issues Encountered

- The standard sandbox denied writes to `.git` during the first commit attempt. The authorized elevated Git operation completed the task commit and plan ledger without changing source scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Home route identity and billing copy have focused automated coverage. Plan 242-07 can perform the reserved mounted visual review. Phase 242 remains in progress.

---
*Phase: 242-investigations-and-remaining-admin-surfaces*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Canonical summary exists; both task commits are ancestors of the plan tip.
- Acceptance runs recorded nonzero test counts (9 and 62) with no failures.
- Stub scan found no new placeholder or unconnected UI stubs; the existing empty form values are intentional inputs.
