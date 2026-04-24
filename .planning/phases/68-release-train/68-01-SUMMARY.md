---
phase: 68-release-train
plan: 01
subsystem: infra
tags: [release-train, REL-01, REL-02, RELEASING]

requires: []
provides:
  - RELEASING.md runbook bullets for publish-accrue-admin needs edge
  - Default manual merge sentence in routine release step 4
  - Changelog ship boundary section before verification lanes
  - Last verified date 2026-04-23
affects: [68-02]

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - RELEASING.md

key-decisions:
  - "Documented needs: [release, publish-accrue] as the automation guarantee for core-before-admin Hex order."

patterns-established: []

requirements-completed: [REL-01, REL-02]

duration: 15min
completed: 2026-04-23
---

# Phase 68: Release train — Plan 01 summary

**Runbook now cites the `publish-accrue-admin` job’s `needs:` edge, states the default manual-merge path, and adds a Release Please changelog ship-boundary section aligned with D-04.**

## Performance

- **Tasks:** 4
- **Files modified:** 1 (`RELEASING.md`)

## Accomplishments

- Linked automation subsection documents `publish-accrue-admin`, `needs: [release, publish-accrue]`, and `release-please.yml` for ordering.
- Routine step 4 leads with the default primary-path manual merge sentence.
- New `## Changelog ship boundary (Release Please)` names both changelog paths and Unreleased freeze/drain expectations.
- Last verified metadata bumped to 2026-04-23.

## Verification

- All plan `rg` acceptance criteria: **passed** (from repo root).
- `bash scripts/ci/verify_package_docs.sh`: **passed**.
- `cd accrue && mix test --warnings-as-errors`: **not executed** in this environment (PostgreSQL role `postgres` unavailable locally). Re-run in CI or with a configured test database before ship.

## Self-Check: PASSED

(Doc-only change; package docs script green.)
