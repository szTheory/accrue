# Phase 91 — Pre-publish 1.0.0 prep — Validation

**Milestone:** v1.30  
**Purpose:** Nyquist validation contract for REL-06, REL-07, DOC-03, and DOC-04 before Phase 91 execution is considered complete.

## Preconditions

- `accrue/mix.exs` remains `@version "0.3.1"` throughout Phase 91.
- `accrue_admin/mix.exs` remains `@version "0.3.1"` throughout Phase 91.
- Phase 91 is docs/planning only. No `@version` bump, no install pin changes, and no numbered `## 1.0.0` changelog heading land on `main`.

## Requirement-to-Evidence Map

1. **REL-06**
   - `accrue/CHANGELOG.md` contains the locked `**1.0.0 — Stable.**` preamble under `## Unreleased`.
   - `accrue_admin/CHANGELOG.md` contains the locked lockstep preamble under `## Unreleased`.
   - `rg -n '^## 1\\.0\\.0' accrue/CHANGELOG.md accrue_admin/CHANGELOG.md` returns no matches.

2. **REL-07**
   - `RELEASING.md` contains `## Post-1.0 cadence (maintainer intent)`.
   - `RELEASING.md` contains `## Routine linked releases (Release Please + Hex)`.
   - `RELEASING.md` preserves `## Appendix: Same-day 1.0.0 bootstrap (exceptional)`.
   - `accrue/guides/upgrade.md` points at `#post-1-0-cadence-maintainer-intent`.

3. **DOC-03**
   - `README.md` contains commitment-level `1.0.x` maintenance posture wording.
   - `README.md` still contains the explicit non-goal warning for `PROC-08` and `FIN-03`.
   - `README.md` still frames those items as later-milestone-only work.
   - `accrue/README.md` contains `1.0.x` stability wording.
   - `accrue/README.md` still contains `{:accrue, "~> 0.3.1"}` exactly.

4. **DOC-04**
   - `.planning/PROJECT.md` contains `### Reaffirmed at 1.0.0 (2026-04-26)`.
   - The reaffirmation subsection explicitly names `PROC-08` and `FIN-03`.
   - The subsection keeps both items out of scope and later-milestone-only.

## Mandatory Automated Checks

```bash
rg -Fq '**1.0.0 — Stable.** This release commits Accrue to v1.x API stability' accrue/CHANGELOG.md
rg -Fq '**1.0.0 — Stable.** Released in lockstep with `accrue` 1.0.0.' accrue_admin/CHANGELOG.md
! rg -n '^## 1\.0\.0' accrue/CHANGELOG.md accrue_admin/CHANGELOG.md
rg -Fq '## Post-1.0 cadence (maintainer intent)' RELEASING.md
rg -Fq '## Routine linked releases (Release Please + Hex)' RELEASING.md
rg -Fq '## Appendix: Same-day 1.0.0 bootstrap (exceptional)' RELEASING.md
rg -Fq '#post-1-0-cadence-maintainer-intent' accrue/guides/upgrade.md
rg -Fq 'PROC-08' README.md
rg -Fq 'FIN-03' README.md
rg -Fq 'later milestone' README.md
rg -Fq '{:accrue, "~> 0.3.1"}' accrue/README.md
rg -Fq '### Reaffirmed at 1.0.0 (2026-04-26)' .planning/PROJECT.md
rg -Fq 'PROC-08' .planning/PROJECT.md
rg -Fq 'FIN-03' .planning/PROJECT.md
```

## Reviewed-SHA Evidence Requirements

Execution must not close Phase 91 until `091-VERIFICATION.md` records a single reviewed merge SHA and ties both of these CI contracts to that same SHA:

1. **`docs-contracts-shift-left`** stayed green.
   - Evidence must enumerate or link the six-script bundle:
     - `bash scripts/ci/verify_package_docs.sh`
     - `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
     - `bash scripts/ci/verify_verify01_readme_contract.sh`
     - `bash scripts/ci/verify_production_readiness_discoverability.sh`
     - `bash scripts/ci/verify_adoption_proof_matrix.sh`
     - `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`

2. **`host-integration`** stayed green.
   - Evidence must include a reviewed-SHA CI link or transcript pointer proving the `host-integration` job remained green after the Phase 91 docs changes at `@version "0.3.1"`.

## Closeout Rule

Do not flip REL-06, REL-07, DOC-03, or DOC-04 to complete in `.planning/REQUIREMENTS.md` until the reviewed-SHA evidence above is present in `091-VERIFICATION.md`.
