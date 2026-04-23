---
phase: 61-root-verify-hops-hex-doc-ssot
plan: "01"
subsystem: testing
tags: [verify_package_docs, INT-08, README, ci]

requires: []
provides:
  - INT-08 ownership comment + D-07 audit in verify_package_docs.sh
  - Root README merge-blocking sentence pinned via require_fixed
  - scripts/ci/README INT-08 registry row (placeholder removed)

key-files:
  created: []
  modified:
    - scripts/ci/verify_package_docs.sh
    - scripts/ci/README.md

requirements-completed: [INT-08]

duration: 15min
completed: 2026-04-23
---

# Phase 61 plan 01 summary

Documented the **release-gate** vs **host-integration** verifier split, pinned the root README merge-blocking proof line in `verify_package_docs.sh`, and registered **INT-08** in the contributor map.

## Task commits

Single commit **`f08dc93`**: `feat(61-01): INT-08 verifier ownership, root README pin, contributor map`

## Verification

- `bash scripts/ci/verify_package_docs.sh` — pass
- `bash scripts/ci/verify_verify01_readme_contract.sh` — pass
- `cd accrue && PGUSER=$USER mix test test/accrue/docs/package_docs_verifier_test.exs` — pass (Postgres role `postgres` absent on host; tests run with `PGUSER=$USER`)

## Self-Check: PASSED
