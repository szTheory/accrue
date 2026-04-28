# Phase 91 — Pre-publish 1.0.0 prep — Verification

**Milestone:** v1.30  
**Status:** Pending execution

## Preconditions

- Workspace `accrue/mix.exs` `@version`: `0.3.1` (must remain unchanged through Phase 91).
- Workspace `accrue_admin/mix.exs` `@version`: `0.3.1` (must remain unchanged through Phase 91).
- Reviewed merge SHA: `<fill with reviewed commit SHA>`
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

- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
- `bash scripts/ci/verify_verify01_readme_contract.sh`
- `bash scripts/ci/verify_production_readiness_discoverability.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`
- `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`

### host-integration

- Reviewed-SHA CI link or transcript pointer proving `host-integration` stayed green at `@version "0.3.1"` after the Phase 91 docs changes.

## Sign-off

- [ ] REL-06 complete
- [ ] REL-07 complete
- [ ] DOC-03 complete
- [ ] DOC-04 complete
