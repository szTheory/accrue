---
phase: 33-installer-host-contracts-ci-clarity
plan: 01
subsystem: docs
tags: [first-hour, installer, upgrade-guide, exunit]

requires: []
provides:
  - First Hour section 4 linking installer rerun semantics to upgrade.md anchor
affects: [33-02]

tech-stack:
  added: []
  patterns:
    - "First Hour defers rerun contract to upgrade.md#installer-rerun-behavior"

key-files:
  created: []
  modified:
    - accrue/guides/first_hour.md
    - accrue/test/accrue/docs/first_hour_guide_test.exs

key-decisions:
  - "New ## 4 appended after section 3 so manifest assert_order! chain unchanged"

patterns-established: []

requirements-completed: [ADOPT-04]

duration: 10min
completed: 2026-04-21
---

# Phase 33 — Plan 01 summary

**First Hour now documents installer rerun semantics and locks the upgrade-guide anchor in ExUnit.**

## Performance

- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added `## 4. Rerunning mix accrue.install` with pristine vs user-edited framing and `--write-conflicts`, linked to `[Upgrade guide — Installer rerun behavior](upgrade.md#installer-rerun-behavior)`.
- Extended `first_hour_guide_test` to assert the anchor substring remains in the guide.

## Task commits

1. **33-01-01** — `1cf684c` (docs)

## Self-Check: PASSED

- `bash scripts/ci/verify_package_docs.sh` — PASS
- `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors` — PASS
