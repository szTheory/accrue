---
phase: 36-audit-corpus-adoption-integration-hardening
plan: 02
subsystem: docs
tags: [adopt, ci, contributing, verify_package_docs]

requires: []
provides:
  - scripts/ci README as SSOT for ADOPT-01..06 ↔ verifier ownership
  - CONTRIBUTING link into that map
  - "[verify_package_docs]" stderr prefix on doc gate failures
affects: []

tech-stack:
  added: []
  patterns:
    - "Central triage table for mega-script failures"

key-files:
  created:
    - scripts/ci/README.md
  modified:
    - CONTRIBUTING.md
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs

key-decisions:
  - "ExUnit drift test now accepts CONTRIBUTING-first failure order and asserts triage prefix"

patterns-established: []

requirements-completed: [ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04, ADOPT-05, ADOPT-06]

duration: 25min
completed: 2026-04-21
---

# Phase 36 — Plan 02 summary

**Contributor-facing ADOPT ↔ CI map lives in `scripts/ci/README.md`, CONTRIBUTING links to it, and `verify_package_docs` failures are prefixed for triage.**

## Performance

- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Added ADOPT gates table + triage bullets + “when verification fails” guidance.
- Prefixed `fail()` output with `[verify_package_docs]`.
- Adjusted `package_docs_verifier_test.exs` failure assertions for prefix and order-dependent CONTRIBUTING vs live-stripe checks.

## Deviations from Plan

**1. ExUnit assertion update (test maintenance)**  
- **Found during:** Running `mix test test/accrue/docs/package_docs_verifier_test.exs` after `fail()` change.  
- **Issue:** “Stale workflow” test expected `host-integration` in stderr, but `CONTRIBUTING.md` invariant fails first when the live-stripe fixture still contains `host-integration`.  
- **Fix:** Assert triage prefix and allow either `host-integration` or `CONTRIBUTING.md` in the failure output; added prefix checks to other negative-path tests.  
- **Files modified:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`

## Self-Check: PASSED

- Plan acceptance greps and `bash scripts/ci/verify_package_docs.sh` exit 0.
- `mix test test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` PASS.
