---
phase: 237-admin-invoices-payments-recovery
plan: "04"
subsystem: payments
tags: [elixir, phoenix-liveview, invoices, money-formatting]
requires:
  - phase: 237-01
    provides: deterministic invoice fixture builders and read contracts
  - phase: 237-02
    provides: payment outcome and money evidence contracts
provides:
  - Strict open-invoice overdue signal on list and detail
  - Invoice money formatting that preserves supported currency precision and renders missing or unsupported evidence unavailable
affects: [admin-invoices, ADM-02, invoice-money-formatting]
actuals:
  tokens: 3391
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Validate currency codes against the supported ISO currency registry before formatting; never infer USD.
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/components/money_formatter.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
key-decisions:
  - "Overdue is derived only when stored status is open and a known due date is strictly earlier than Accrue.Clock.utc_now()."
  - "Use the shared MoneyFormatter for invoice list and detail values; unsupported currency or missing amount evidence renders as unavailable."
requirements-completed: [ADM-02]
coverage:
  - id: D1
    description: "Invoice list preserves stored lifecycle while showing overdue only for open invoices strictly past due."
    requirement: ADM-02
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/invoices_live_test.exs#overdue is a separate collection signal for open invoices strictly past due"
        status: pass
    human_judgment: false
  - id: D2
    description: "Invoice list and detail show exact supported money precision and keep missing or unsupported money unavailable."
    requirement: ADM-02
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/invoices_live_test.exs#invoice list formats supported precision and keeps unknown money unavailable"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/invoice_live_test.exs#invoice detail preserves supported money precision, unavailable evidence, and overdue separation"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-10-08
status: complete
plan_head_before: d701fc9bdce9b13b6743d60ef3c68c1d69d93f6e
plan_head_after: dd4a30456cc5b23950f1626fc0196233f3b4c31f
commits: 2
---

# Phase 237 Plan 04: Invoice Collection and Detail Summary

**Invoice collection and detail views now keep overdue status distinct from stored lifecycle and format only supported, evidenced amounts.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-08T20:06:00-04:00
- **Completed:** 2026-10-08T20:12:00-04:00
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- The invoice list and detail derive overdue only for open invoices with a known due date strictly before the canonical clock; equality, future dates, missing dates, and non-open states do not show overdue.
- Invoice list and detail use the shared `MoneyFormatter`; zero-, two-, and three-decimal currencies retain supported precision, while unknown currency and missing amount evidence render as `--`.
- Automated LiveView assertions cover Unicode identity, stored lifecycle, overdue boundaries, zero amounts, and owner-scoped list behavior.

## Task Commits

1. **Task 1: Complete invoice collection facts and list states** - `0f753861` (`feat`)
2. **Task 2: Complete invoice detail precision and evidence** - `dd4a3045` (`fix`)

Plan commit counts are measured from `d701fc9bdce9b13b6743d60ef3c68c1d69d93f6e` through `dd4a30456cc5b23950f1626fc0196233f3b4c31f`: 2 commits.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/components/money_formatter.ex` - Shared safe currency validation and formatting helper.
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` - Strict overdue signal and shared money formatting for collection rows.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` - Distinct overdue evidence and shared money formatting on invoice detail.
- `accrue_admin/test/accrue_admin/live/invoices_live_test.exs` - List boundary and supported/unavailable money assertions.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - Detail currency precision, unavailable evidence, Unicode identity, and overdue assertions.

## Decisions Made

- Use `Accrue.Clock.utc_now/0` and a strict earlier-than comparison for overdue. Stored status remains unchanged and is displayed separately.
- Validate binary currency codes against the supported ISO registry before converting them for formatting; do not silently substitute USD.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented currency fallback from misrepresenting invoice amounts**
- **Found during:** Task 1 (Complete invoice collection facts and list states)
- **Issue:** Local formatting could substitute USD for unknown codes, while the shared formatter's existing-atom lookup could fail to recognize valid currencies such as JPY or KWD when their atoms had not yet been loaded.
- **Fix:** Centralized invoice formatting through `MoneyFormatter` and validated binary codes against the ISO currency registry before conversion. Unknown codes now remain unavailable.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/money_formatter.ex`, `accrue_admin/lib/accrue_admin/live/invoices_live.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`
- **Verification:** Invoice list and detail LiveView suites pass, including JPY/KWD precision and unknown-currency cases.
- **Committed in:** `0f753861` and `dd4a3045`.

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** Correctness fix directly required by the plan's money evidence requirements; no external API, dependency, or schema changes.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` — 13 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` — 15 tests, 0 failures.
- `cd accrue_admin && mix test --warnings-as-errors` — 559 tests, 0 failures.
- Shift-left coverage is automated in the existing package test suite; no confirmation-only human UAT is needed for these deterministic behaviors.

## Issues Encountered

- The first targeted ExUnit selector matched no tests; the full planned test file was run and produced a behavior-specific failure before implementation.
- Initial full-suite iteration exposed an incorrect currency module qualification and a stale test struct from optimistic locking. Both were corrected and all planned gates passed afterward.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 237-04 is complete. ADM-02 remains pending because Plan 237-08 also declares the shared requirement; the readiness gate returned 0/1 requirements ready to mark.
- Proceed to the next runnable plan. No manual verification checkpoint is needed for this plan's tested behavior.

---
*Phase: 237-admin-invoices-payments-recovery*
*Completed: 2026-10-08*
