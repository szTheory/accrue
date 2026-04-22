---
phase: 39-org-billing-proof-alignment
plan: 03
subsystem: testing
tags: [exunit, org-09, docs]

requires:
  - phase: 39-org-billing-proof-alignment
    provides: Bash verifier script at repo root
provides:
  - ORG-09 cross-navigation in organization_billing guide
  - ExUnit needles + bash smoke from accrue package tests
affects: []

tech-stack:
  added: []
  patterns:
    - "Phase 31-style System.cmd bash gate from accrue/tests for repo-level script"

key-files:
  created:
    - accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs
  modified:
    - accrue/guides/organization_billing.md
    - accrue/test/accrue/docs/organization_billing_guide_test.exs

key-decisions:
  - "Matrix link uses GitHub absolute URL in markdown to satisfy ExDoc --warnings-as-errors (local ../../ path failed ExDoc file existence check)."

patterns-established: []

requirements-completed: [ORG-09]

duration: 15min
completed: 2026-04-21
---

# Phase 39 — Plan 03

**Organization billing guide documents ORG-09 navigation; ExUnit guards matrix paths and shells the bash verifier from the accrue package.**

## Self-Check: PASSED

- `mix test` on guide + org09 matrix tests; `MIX_ENV=test mix docs --warnings-as-errors`.

## Accomplishments

- Added `## Adoption proof matrix (ORG-09)` section with matrix path, subsection name, script literal, and non-Sigra honesty wording.
- Extended `organization_billing_guide_test.exs` ORG-09 needles.
- Added `organization_billing_org09_matrix_test.exs` invoking `verify_adoption_proof_matrix.sh` from monorepo root.

## Deviations

- Matrix deep link uses `https://github.com/szTheory/accrue/blob/main/...` instead of a repo-relative markdown URL so ExDoc does not treat the target as a missing sibling file under the accrue mix project.
