# Phase 91 — Pre-publish 1.0.0 prep — Verification

**Milestone:** v1.30  
**Status:** Pending execution

## Preconditions

- Workspace `accrue/mix.exs` `@version`: `0.3.1` (must remain unchanged through Phase 91).
- Workspace `accrue_admin/mix.exs` `@version`: `0.3.1` (must remain unchanged through Phase 91).
- Reviewed merge SHA: `3cca930fff7e0996a7eced33ce778ad48e5c9329`
- This phase is docs/planning only. The `@version` bump, install-pin refresh, and public `1.0.0` changelog heading are Phase 92 work.

## Evidence checklist

1. **REL-06**
   - `accrue/CHANGELOG.md` contains the locked `**1.0.0 — Stable.**` preamble under `## Unreleased`.
   - `accrue_admin/CHANGELOG.md` contains the locked lockstep preamble under `## Unreleased`.
   - No literal numbered `## 1.0.0` heading exists on `main` before Phase 92.

2. **REL-07**
   - `RELEASING.md` contains `## Post-1.0 cadence (maintainer intent)`.
   - `RELEASING.md` contains `## Routine linked releases (Release Please + Hex)`.
   - `RELEASING.md` preserves `## Appendix: Same-day 1.0.0 bootstrap (exceptional)`.
   - `accrue/guides/upgrade.md` points at `#post-1-0-cadence-maintainer-intent`.

3. **DOC-03**
   - `README.md` advertises the `1.0.x` stability commitment in commitment-level voice.
   - `README.md` preserves the explicit `PROC-08` / `FIN-03` non-goal warning and later-milestone-only wording.
   - `accrue/README.md` advertises the `1.0.x` stability commitment and preserves `{:accrue, "~> 0.3.1"}` exactly.

4. **DOC-04**
   - `.planning/PROJECT.md` contains `### Reaffirmed at 1.0.0 (2026-04-26)`.
   - The subsection explicitly names `PROC-08` and `FIN-03` and keeps them as later-milestone-only non-goals.

## Verifier transcripts

Record one reviewed-SHA evidence anchor for each item below. CI links are preferred; local transcripts are acceptable when they clearly point to the same reviewed SHA.

### docs-contracts-shift-left

- `bash scripts/ci/verify_package_docs.sh` — passed on reviewed SHA (`package docs verified for accrue 0.3.1 and accrue_admin 0.3.1`).
- `bash scripts/ci/verify_v1_17_friction_research_contract.sh` — passed (`verify_v1_17_friction_research_contract: OK`).
- `bash scripts/ci/verify_verify01_readme_contract.sh` — passed (`verify_verify01_readme_contract: OK`).
- `bash scripts/ci/verify_production_readiness_discoverability.sh` — passed (`verify_production_readiness_discoverability: OK`).
- `bash scripts/ci/verify_adoption_proof_matrix.sh` — passed (`verify_adoption_proof_matrix: OK`).
- `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` — passed (`verify_core_admin_invoice_verify_ids: OK`).

### host-integration

- Local transcript on reviewed SHA: `bash scripts/ci/accrue_host_uat.sh` passed end-to-end with bounded tests, full `mix verify.full`, Phoenix boot smoke, and Playwright browser coverage (`34 tests, 0 failures`; `156 tests, 0 failures`; `23 passed`, `16 skipped`; `=== Accrue host UAT complete ===`).

## Sign-off

- [x] REL-06 complete
- [x] REL-07 complete
- [x] DOC-03 complete
- [x] DOC-04 complete
