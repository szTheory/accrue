---
phase: 45-docs-telemetry-runbook-alignment
plan: "04"
subsystem: docs
tags: [testing, readme, cross-links]

requires: []
provides:
  - Optional reciprocal links testing.md ↔ metering + README → testing.md
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - accrue/guides/testing.md
    - accrue/README.md

key-decisions:
  - "README gained exactly one Start-here bullet for guides/testing.md"

patterns-established: []

requirements-completed: []

duration: 8min
completed: 2026-04-22
---

# Phase 45 — Plan 04 (stretch)

**Reduced hop count** from adoption README and Fake metering tests to the metering spine without expanding README into a full guide index.

## Task Commits

1. **testing.md link** — `2031853`
2. **README bullet** — `d9af6a1`

## Self-Check: PASSED

- `cd accrue && mix docs` — exit 0
