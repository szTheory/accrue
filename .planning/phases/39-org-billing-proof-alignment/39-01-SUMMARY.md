---
phase: 39-org-billing-proof-alignment
plan: 01
subsystem: docs
tags: [org-09, adoption-matrix, non-sigra]

requires: []
provides:
  - ORG-09 section in adoption-proof-matrix with blocking vs advisory tables and script literal
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - examples/accrue_host/docs/adoption-proof-matrix.md

key-decisions:
  - "Primary merge-blocking row encodes phx.gen.auth + membership-gated Organization + use Accrue.Billable; Pow/ORG-07 and custom/ORG-08 stay advisory without extra VERIFY-01 lanes."

patterns-established:
  - "ORG-09 matrix subsection anchors bash verifier needles for CI."

requirements-completed: [ORG-09]

duration: 5min
completed: 2026-04-21
---

# Phase 39: org-billing-proof-alignment — Plan 01

**Adoption proof matrix now documents ORG-09 with a merge-blocking primary archetype row, advisory Pow/custom lanes, Sigra demo honesty, and the `verify_adoption_proof_matrix.sh` literal.**

## Self-Check: PASSED

- `rg` acceptance lines from PLAN.md verified locally.

## Accomplishments

- Inserted `## Organization billing proof (ORG-09)` with primary and recipe-lane tables and link to `accrue/guides/organization_billing.md`.

## Deviations

- None.
