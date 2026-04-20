---
phase: 25-admin-ux-inventory
plan: 01
subsystem: planning
tags: [phoenix, routes, accrue_admin]

requires: []
provides:
  - INV-01 route matrix aligned to examples/accrue_host and router source
affects: [phase-26, phase-27]

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - .planning/phases/25-admin-ux-inventory/25-INV-01-route-matrix.md
    - .planning/phases/25-admin-ux-inventory/README.md

key-decisions:
  - "Excluded LiveView transport routes from matrix per plan scope"
  - "Dev-only admin routes documented from source; reference host omits them (allow_live_reload: false)"

patterns-established:
  - "Dual shipping vs dev-only tables with host mount reference"

requirements-completed: [INV-01]

duration: 15min
completed: 2026-04-20
---

# Phase 25 — Plan 01 Summary

**INV-01 is a mechanically verifiable `/billing` route matrix** for `accrue_admin` as mounted in `examples/accrue_host`, including hashed asset GETs and source-only dev routes.

## Performance

- **Duration:** ~15 min
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Filled shipping LiveView rows with admin-relative and host-absolute paths.
- Documented `AccrueAdmin.Assets` non-LiveView subsection with snapshot hashes from `mix phx.routes`.
- Captured dev-only routes from `router.ex` with `allow_live_reload` caveat.

## Task Commits

1. **Task 1: Fill INV-01 tables from router + mix phx.routes** — `67c8d9c`
2. **Task 2: README status line for INV-01 progress** — `4fc7bb4`

## Files Created/Modified

- `25-INV-01-route-matrix.md` — Full matrix, assets, dev-only, host reference
- `README.md` — INV-01 completion line

## Self-Check: PASSED

- `rg '_TBD_'` on INV-01: no matches
- `mix phx.routes` includes each listed `/billing` LiveView path (verified at execution time)
