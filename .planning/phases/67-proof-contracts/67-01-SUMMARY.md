---
phase: 67-proof-contracts
plan: 01
subsystem: testing
tags: [proof-contracts, verify_adoption_proof_matrix, ORG-09, PRF-01, PRF-02]

requires: []
provides:
  - Merge-blocking needles for Layer C verify_core_admin_invoice_verify_ids and ORG-05/ORG-06 in verify_adoption_proof_matrix.sh
  - Contributor triage prose for verify_adoption_proof_matrix in scripts/ci/README.md
  - Phase verification ledger with concrete bash/mix commands
affects: []

tech-stack:
  added: []
  patterns:
    - "Single source of substring needles in bash; ExUnit shells out only."

key-files:
  created: []
  modified:
    - scripts/ci/verify_adoption_proof_matrix.sh
    - scripts/ci/README.md
    - examples/accrue_host/docs/adoption-proof-matrix.md
    - .planning/phases/67-proof-contracts/67-VERIFICATION.md

key-decisions:
  - "Committed refreshed adoption-proof-matrix.md in the same change set as script needles so CI does not fail on heading/Layer C drift."

patterns-established: []

requirements-completed: [PRF-01, PRF-02]

duration: 25min
completed: 2026-04-23
---

# Phase 67 — proof contracts (67-01) summary

**Hardened ORG-09 shift-left alignment:** the adoption proof matrix, bash verifier, and contributor README triage now agree on Layer C script names, ORG-05/ORG-06 taxonomy tokens, and where needles are owned.

## Performance

- **Tasks:** 4 (+ matrix co-commit)
- **Files modified:** 4 production paths + verification ledger

## Accomplishments

- Added `require_substring` for `verify_core_admin_invoice_verify_ids.sh`, **ORG-05**, and **ORG-06**; updated Layer B/C needles to match the matrix’s merge-blocking CI wording and Layer C job list.
- Expanded **`### Triage: verify_adoption_proof_matrix.sh`** with SSOT path, **`docs-contracts-shift-left`**, co-update rule, markdown link, and **`organization_billing_org09_matrix_test.exs`** reference.
- Recorded machine-cited proof commands in **`67-VERIFICATION.md`**.
- Committed **`adoption-proof-matrix.md`** refresh so the verifier passes on a clean checkout (co-evolution with the script).

## Task commits

1. **67-01-01** — `4f0d451` feat(67-01-01): tighten adoption proof matrix Layer C needles
2. **67-01-02** — `cc803e5` feat(67-01-02): require ORG-05 and ORG-06 tokens in adoption proof matrix
3. **67-01-03** — `de6130a` docs(67-01-03): expand verify_adoption_proof_matrix triage in scripts/ci README
4. **67-01-04** — `ae27ad4` docs(67-01-04): record PRF-01/PRF-02 verification commands for phase 67
5. **Matrix SSOT** — `ea5fb8f` docs(67): align adoption proof matrix with Layer C shift-left contract

## Verification

- `bash scripts/ci/verify_adoption_proof_matrix.sh` → **`verify_adoption_proof_matrix: OK`**
- `cd accrue && mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` — not re-run here (local Postgres role missing); CI exercises this path.

## Self-Check: PASSED

- Plan acceptance `rg` checks re-run with exit code 0 during execution.
