---
phase: 45-docs-telemetry-runbook-alignment
plan: "01"
subsystem: docs
tags: [metering, exdoc, guides]

requires: []
provides:
  - Thin guides/metering.md (MTR-07) plus ExDoc cross-link from report_usage
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - accrue/guides/metering.md
  modified:
    - accrue/lib/accrue/billing.ex

key-decisions:
  - "Metering ops narrative defers to telemetry.md + operator-runbooks.md only"

patterns-established:
  - "Architecture map in guides; option schema stays in ExDoc only"

requirements-completed: [MTR-07]

duration: 15min
completed: 2026-04-22
---

# Phase 45: Docs + telemetry/runbook alignment — Plan 01

**Shipped MTR-07:** new `guides/metering.md` plus a single `guides/metering.md` pointer inside `@report_usage_doc` without duplicating NimbleOptions tables.

## Performance

- **Tasks:** 2
- **Files modified:** 2

## Task Commits

1. **Task 1: Create guides/metering.md** — `5d819ba`
2. **Task 2: Optional ExDoc cross-link** — `509b564`

## Files Created/Modified

- `accrue/guides/metering.md` — Public vs internal vs processor map for metering
- `accrue/lib/accrue/billing.ex` — `@report_usage_doc` cross-link

## Self-Check: PASSED

- `cd accrue && mix docs` — exit 0
- `cd accrue && mix compile --warnings-as-errors` — exit 0
