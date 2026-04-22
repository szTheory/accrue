---
phase: 51-integrator-golden-path-docs
plan: "01"
subsystem: docs
tags: [phoenix, onboarding, verify-01, first-hour]

requires: []
provides:
  - H/M/R entry capsules on the integrator spine
  - Bidirectional First Hour ↔ accrue_host README alignment
  - Thin quickstart hub routing only
affects: [integrator-docs, examples/accrue_host]

tech-stack:
  added: []
  patterns:
    - "Single spine: package First Hour and host README change together (D-02)"

key-files:
  created: []
  modified:
    - accrue/guides/first_hour.md
    - examples/accrue_host/README.md
    - accrue/guides/quickstart.md

key-decisions:
  - "Used blockquote-friendly capsule headings to mirror CONTEXT D-01–D-04 without forking the tutorial body in quickstart."

patterns-established:
  - "Capsule H/M/R labels shared verbatim between First Hour and host README."

requirements-completed: [INT-01]

duration: 25min
completed: 2026-04-22
---

# Phase 51 — Plan 01 Summary

**H/M/R entry capsules and a single clone→proof spine across First Hour, the host README, and a thin quickstart hub.**

## Performance

- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- First Hour gains **How to enter this guide** with Capsule H/M/R join points and deep link to host **#proof-and-verification**.
- Host README mirrors the same capsules before **First run**; VERIFY-01 contract script stays green.
- Quickstart adds capsule routing only (hub stays short).

## Task Commits

1. **Task 1: Entry capsules + spine header in First Hour** — `e91ca9f`
2. **Task 2: Mirror capsules + spine contract in host README** — `3d1bfc4`
3. **Task 3: Quickstart hub — capsule routing only** — `fc2c56b`

## Files Created/Modified

- `accrue/guides/first_hour.md` — capsule section + spine contract sentence.
- `examples/accrue_host/README.md` — mirrored orientation before First run.
- `accrue/guides/quickstart.md` — capsule picker under Start with First Hour.

## Deviations from Plan

None — plan executed as written.

## Issues Encountered

None.

## Next Phase Readiness

Wave 2 (51-03) can add troubleshooting cross-links on top of this spine.

## Self-Check: PASSED

- `bash scripts/ci/verify_verify01_readme_contract.sh` — PASS (after task 2)
- `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors` — PASS (post-phase)

---
*Phase: 51-integrator-golden-path-docs · Plan 01*
