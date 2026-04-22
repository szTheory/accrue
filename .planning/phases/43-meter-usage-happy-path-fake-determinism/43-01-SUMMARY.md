---
phase: 43-meter-usage-happy-path-fake-determinism
plan: "01"
subsystem: testing
tags: [exdoc, metering, nimble_options, billing]

requires: []
provides:
  - Public ExDoc SSOT for report_usage options aligned with MeterEventActions schema
affects: []

tech-stack:
  added: []
  patterns:
    - "Module attribute `@report_usage_doc` + `@doc @report_usage_doc` satisfies tooling that greps `@doc` lines for `report_usage` while keeping Elixir heredoc newline rules"

key-files:
  created: []
  modified:
    - accrue/lib/accrue/billing.ex

key-decisions:
  - "Document options in Accrue.Billing only; defer implementation prose to MeterEventActions for timestamp normalization"

patterns-established:
  - "Bang doc describes NimbleOptions.ValidationError, Accrue.APIError/resource_missing, and non-exception {:error, _} RuntimeError path"

requirements-completed: [MTR-01]

duration: 15min
completed: 2026-04-22
---

# Phase 43 Plan 01 Summary

**Meter usage public API options are now documented on `Accrue.Billing.report_usage/3` and `report_usage!/3` with the same keys and semantics as `@report_usage_schema`.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 2 (single commit — both doc blocks landed together after compile iteration)
- **Files modified:** 1

## Accomplishments

- Added structured `## Options` and `## Fake / test mode` documentation with defaults for `:value`, `:timestamp`, `:identifier`, `:operation_id`, and `:payload`.
- Documented bang raises for validation, `Accrue.APIError`, and other error tuples per `MeterEventActions.report_usage!/3`.

## Task Commits

1. **Task 1 & 2: ExDoc for report_usage/3 and report_usage!/3** - `5a76bd1` (docs)

## Files Created/Modified

- `accrue/lib/accrue/billing.ex` — `@report_usage_doc`, `@report_usage_bang_doc`, `@doc` references immediately above `report_usage/2` and `report_usage!/2`.

## Self-Check: PASSED

- `cd accrue && mix compile --warnings-as-errors` — PASS
- `mix test test/accrue/billing/meter_event_actions_test.exs` — 13 tests, 0 failures

## Deviations

- Plan asked for one commit per task; delivered one commit for both doc tasks after resolving heredoc/`rg '@doc'|rg report_usage` tooling constraint via `@doc @report_usage_doc` indirection.
