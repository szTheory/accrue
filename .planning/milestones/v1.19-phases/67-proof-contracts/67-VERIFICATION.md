---
phase: 67-proof-contracts
status: complete
---

# Phase 67 — Verification

**Milestone:** v1.19 — Release continuity + proof resilience

| Row ID | Acceptance | Merge-blocking proof | Closure |
|--------|-------------|----------------------|---------|
| PRF-01 | Matrix ↔ `verify_adoption_proof_matrix.sh` (+ related ExUnit) co-evolve under CI | `bash scripts/ci/verify_adoption_proof_matrix.sh`; `cd accrue && mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` | complete |
| PRF-02 | `scripts/ci/README.md` documents triage + co-update rule | `scripts/ci/README.md` — subsection **`### Triage: verify_adoption_proof_matrix.sh`** (discover with `rg -n '### Triage: verify_adoption_proof_matrix.sh' scripts/ci/README.md`) | complete |
