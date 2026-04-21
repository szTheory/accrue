---
phase: 33-installer-host-contracts-ci-clarity
plan: 02
subsystem: testing
tags: [ci, doc-gate, require_fixed]

requires: []
provides:
  - CI require_fixed pins for First Hour rerun anchor and troubleshooting install check
affects: []

tech-stack:
  added: []
  patterns:
    - "verify_package_docs.sh pins critical doc substrings"

key-files:
  created: []
  modified:
    - scripts/ci/verify_package_docs.sh

key-decisions:
  - "Added require_fixed for upgrade.md#installer-rerun-behavior in first_hour.md"
  - "Added require_fixed for mix accrue.install --check in troubleshooting.md"

patterns-established: []

requirements-completed: [ADOPT-05]

duration: 8min
completed: 2026-04-21
---

# Phase 33 — Plan 02 summary

**Doc drift gate now fails CI if the First Hour upgrade rerun anchor or troubleshooting install-check string disappears.**

## Performance

- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Extended `verify_package_docs.sh` with `require_fixed` for `upgrade.md#installer-rerun-behavior` in `accrue/guides/first_hour.md`.
- Added `require_fixed` for `mix accrue.install --check` in `accrue/guides/troubleshooting.md`.

## Task commits

1. **33-02-01** — (hash after commit)

## Self-Check: PASSED

- Acceptance greps — PASS
- `bash scripts/ci/verify_package_docs.sh` — PASS
