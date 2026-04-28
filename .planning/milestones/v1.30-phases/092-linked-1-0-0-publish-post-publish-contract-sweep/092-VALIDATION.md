# Phase 92 — Linked 1.0.0 publish + post-publish contract sweep — Validation

**Milestone:** v1.30  
**Purpose:** Nyquist validation contract for REL-05 and PPX-09..12 before Phase 92 execution is considered complete.

## Preconditions

- `accrue/mix.exs`, `accrue_admin/mix.exs`, and `.release-please-manifest.json` all start at `0.3.1`.
- Phase 92 owns the linked `1.0.0` cut plus public-contract verification only.
- `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/STATE.md`, friction-inventory maintainer pass work, and planning tag creation remain Phase 93 scope.
- The release path is one combined release PR plus same-day post-merge verification, not a staggered “publish now, honesty later” sequence.

## Requirement-to-Evidence Map

1. **REL-05**
   - `accrue/mix.exs` contains `@version "1.0.0"`.
   - `accrue_admin/mix.exs` contains `@version "1.0.0"`.
   - `.release-please-manifest.json` records `1.0.0` for both packages.
   - `092-VERIFICATION.md` records the published Hex URLs, GitHub release/tag URLs, and UTC verification timestamps for both packages.
   - `092-VERIFICATION.md` records that `accrue` published before `accrue_admin`.

2. **PPX-09**
   - `bash scripts/ci/verify_package_docs.sh` exits 0 at `1.0.0`.
   - `accrue/README.md` contains `{:accrue, "~> 1.0.0"}`.
   - `accrue_admin/README.md` contains `{:accrue_admin, "~> 1.0.0"}` and published-release prose aligned to `1.0.0`.
   - `accrue/guides/first_hour.md` contains `{:accrue, "~> 1.0.0"}` and `{:accrue_admin, "~> 1.0.0"}`.

3. **PPX-10**
   - `bash scripts/ci/verify_adoption_proof_matrix.sh` exits 0 at the reviewed `1.0.0` SHA.
   - `examples/accrue_host/docs/adoption-proof-matrix.md` remains aligned to script expectations after the release update.

4. **PPX-11**
   - The six-script `docs-contracts-shift-left` bundle exits 0 on the reviewed `1.0.0` SHA:
     - `bash scripts/ci/verify_package_docs.sh`
     - `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
     - `bash scripts/ci/verify_verify01_readme_contract.sh`
     - `bash scripts/ci/verify_production_readiness_discoverability.sh`
     - `bash scripts/ci/verify_adoption_proof_matrix.sh`
     - `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh`
   - `bash scripts/ci/verify_release_manifest_alignment.sh` also exits 0 on the same SHA.

5. **PPX-12**
   - First Hour install needles read `1.0.0`.
   - Host README release-facing wording remains honest for the `1.0.0` cut and still passes `verify_verify01_readme_contract.sh`.
   - Adoption matrix / integrator proof surfaces remain current for `1.0.0`, whether via explicit wording change or same-day re-proof with no content drift.

## Mandatory Automated Checks

```bash
rg -Fq '@version "1.0.0"' accrue/mix.exs
rg -Fq '@version "1.0.0"' accrue_admin/mix.exs
rg -Fq '"accrue": "1.0.0"' .release-please-manifest.json
rg -Fq '"accrue_admin": "1.0.0"' .release-please-manifest.json
rg -Fq '{:accrue, "~> 1.0.0"}' accrue/README.md
rg -Fq '{:accrue_admin, "~> 1.0.0"}' accrue_admin/README.md
rg -Fq '{:accrue, "~> 1.0.0"}' accrue/guides/first_hour.md
rg -Fq '{:accrue_admin, "~> 1.0.0"}' accrue/guides/first_hour.md
bash scripts/ci/verify_release_manifest_alignment.sh
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_v1_17_friction_research_contract.sh
bash scripts/ci/verify_verify01_readme_contract.sh
bash scripts/ci/verify_production_readiness_discoverability.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
bash scripts/ci/verify_core_admin_invoice_verify_ids.sh
```

## Reviewed-SHA Evidence Requirements

Execution must not close Phase 92 until `092-VERIFICATION.md` records:

1. A reviewed merge SHA for the `1.0.0` release PR or same-day follow-up verification commit.
2. A green `release-manifest-ssot` result at that SHA.
3. A green `docs-contracts-shift-left` result at that SHA, enumerating all six scripts.
4. Hex package URLs for `accrue 1.0.0` and `accrue_admin 1.0.0`.
5. GitHub release/tag URLs for `accrue-v1.0.0` and `accrue_admin-v1.0.0`.
6. UTC timestamps proving `accrue` published before `accrue_admin`.
7. If any host-facing doc changed, reviewed-SHA `host-integration` evidence tied to the same release slice.

## Closeout Rule

Do not flip REL-05 or PPX-09..12 to complete in `.planning/REQUIREMENTS.md` until the reviewed-SHA evidence above is present in `092-VERIFICATION.md`.
