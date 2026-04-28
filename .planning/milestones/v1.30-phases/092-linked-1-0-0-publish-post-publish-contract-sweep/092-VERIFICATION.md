# Phase 92 — Linked 1.0.0 publish + post-publish contract sweep — Verification

**Milestone:** v1.30  
**Status:** Complete (2026-04-28)

Reviewed merge SHA: `9a463406081758751d626757634447bb1aa99f08`
Reviewed verification SHA: `a6f11e84d4bf8853c49c57078240a4bead352f15`
Trigger method: merged Release Please PR `#15` on `main`; no retrigger required because the canonical linked `1.0.0` publish had already completed upstream
Release Please run id: 25055758784
Release Please run URL: https://github.com/szTheory/accrue/actions/runs/25055758784
Reviewed release PR: https://github.com/szTheory/accrue/pull/15
Verified at (UTC): 2026-04-28T14:08:21Z

## Release bootstrap proof

- Releasable Phase 92 commit `1f9675f4c8b519fa47a9ef6ad1879b3a573432a9` carries the exact trailer `Release-As: 1.0.0`.
- Merged Release Please PR `#15` is the single combined linked slice for both package paths:
  - PR title: `chore: release 1.0.0`
  - PR body opens with `Bootstrap target: linked 1.0.0 release for both package paths.`
  - PR file list includes `.release-please-manifest.json`, `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue/README.md`, `accrue_admin/README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`, `scripts/ci/verify_adoption_proof_matrix.sh`, and `scripts/ci/verify_verify01_readme_contract.sh`.
- `.planning/PROJECT.md`, `.planning/MILESTONES.md`, and `.planning/STATE.md` mirror updates are deferred to Phase 93 by scope.

## Ordered publish proof

`gh run view 25055758784 --json status,conclusion,headBranch,jobs,url,displayTitle,event,workflowName` returned `status=completed`, `conclusion=success`, and `headBranch=main` for workflow `Release Please`.

| Job | Started at (UTC) | Completed at (UTC) | Result | URL |
| --- | --- | --- | --- | --- |
| Release Please | 2026-04-28T13:30:06Z | 2026-04-28T13:30:42Z | success | https://github.com/szTheory/accrue/actions/runs/25055758784/job/73395467689 |
| Publish accrue | 2026-04-28T13:30:44Z | 2026-04-28T13:33:40Z | success | https://github.com/szTheory/accrue/actions/runs/25055758784/job/73395600721 |
| Publish accrue_admin | 2026-04-28T13:33:43Z | 2026-04-28T13:36:44Z | success | https://github.com/szTheory/accrue/actions/runs/25055758784/job/73396167749 |

`publish-accrue-admin` is still ordered after `publish-accrue` in `.github/workflows/release-please.yml` via `needs: [release, publish-accrue]`, and the live workflow run shows `Publish accrue` completed before `Publish accrue_admin`.

accrue published before accrue_admin.

## Public release evidence

| Package | Hex URL | Hex registry timestamp (UTC) | GitHub release/tag URL | GitHub release timestamp (UTC) |
| --- | --- | --- | --- | --- |
| accrue | https://hex.pm/packages/accrue/1.0.0 | 2026-04-28T13:33:37.549772Z | https://github.com/szTheory/accrue/releases/tag/accrue-v1.0.0 | 2026-04-28T13:30:26Z |
| accrue_admin | https://hex.pm/packages/accrue_admin/1.0.0 | 2026-04-28T13:36:41.540928Z | https://github.com/szTheory/accrue/releases/tag/accrue_admin-v1.0.0 | 2026-04-28T13:30:27Z |

UTC timestamp proof from both GitHub Actions and the Hex API agrees that the core package became available before the admin package.

## Reviewed-SHA verifier evidence

The reviewed same-day verification commit reran the Phase 92 release contracts after the linked publish had landed.

### release-manifest-ssot

- `bash scripts/ci/verify_release_manifest_alignment.sh`
- Result: `OK: release manifest and mix.exs @version aligned at 1.0.0`

### docs-contracts-shift-left

Normative membership comes from `.github/workflows/ci.yml` job `docs-contracts-shift-left`.

1. `bash scripts/ci/verify_package_docs.sh` -> `package docs verified for accrue 1.0.0 and accrue_admin 1.0.0`
2. `bash scripts/ci/verify_v1_17_friction_research_contract.sh` -> `verify_v1_17_friction_research_contract: OK`
3. `bash scripts/ci/verify_verify01_readme_contract.sh` -> `verify_verify01_readme_contract: OK`
4. `bash scripts/ci/verify_production_readiness_discoverability.sh` -> `verify_production_readiness_discoverability: OK`
5. `bash scripts/ci/verify_adoption_proof_matrix.sh` -> `verify_adoption_proof_matrix: OK`
6. `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` -> `verify_core_admin_invoice_verify_ids: OK`

### host-integration

- Fast preflight:
  - `rg -Fq 'accrue\` / \`accrue_admin\` \`1.0.0\`' examples/accrue_host/README.md`
  - `bash scripts/ci/verify_verify01_readme_contract.sh`
- Full wrapper:
  - `bash scripts/ci/accrue_host_uat.sh`
  - Result: bounded tests passed, full tests passed, Phoenix boot smoke passed on `http://127.0.0.1:4100/`, Playwright lane completed with `23 passed` and `16 skipped`, wrapper exited 0.

## Sign-off

- [x] REL-05
- [x] PPX-09
- [x] PPX-10
- [x] PPX-11
- [x] PPX-12
