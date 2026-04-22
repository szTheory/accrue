---
phase: 51-integrator-golden-path-docs
plan: "02"
subsystem: docs
tags: [verify-01, ci, contributing]

requires: []
provides:
  - Root README Proof path fenced CI-equivalent command
  - CONTRIBUTING Layer A/B/C vocabulary bridging host proof
affects: [contributors, ci-discoverability]

tech-stack:
  added: []
  patterns:
    - "Layer A = package release gate; Layer B = host verify commands; Layer C = PR merge contract vs local script triage"

key-files:
  created: []
  modified:
    - README.md
    - CONTRIBUTING.md

key-decisions:
  - "Placed fenced `cd examples/accrue_host && mix verify.full` immediately under Proof path prose before the deep link line."

patterns-established: []

requirements-completed: [INT-02]

duration: 15min
completed: 2026-04-22
---

# Phase 51 — Plan 02 Summary

**VERIFY-01 stays two-hop discoverable from repo root with a scannable CI-equivalent line and Layer A/B/C language in CONTRIBUTING.**

## Performance

- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Root **Proof path** section includes a short fenced `bash` block for `mix verify.full` after the host-integration paragraph.
- CONTRIBUTING adds **Host proof (VERIFY-01)** with Layer A/B/C bullets and deep link to host proof section plus `scripts/ci/README.md` triage.

## Task Commits

1. **Task 1: Root README — scannable CI-equivalent line** — `9b4ff64`
2. **Task 2: CONTRIBUTING — Host proof bridge** — `dc8c47c`

## Deviations from Plan

None.

## Issues Encountered

None.

## Next Phase Readiness

Troubleshooting anchors (51-03) can cite the same VERIFY-01 surfaces.

## Self-Check: PASSED

- `bash scripts/ci/verify_verify01_readme_contract.sh` — PASS

---
*Phase: 51-integrator-golden-path-docs · Plan 02*
