# Phase 121 Verification Ledger

PR_NUMBER: 23
TARGET_VERSION: 1.1.1
RUN_ID: 25554198977

## Release PR evidence

2026-05-08T02:00:33Z

- REL-10 tooling created locally:
  - `bash scripts/ci/verify_release_pr_scope.sh --help`
  - `bash scripts/ci/capture_linked_release_proof.sh --help`
- Initial live check failed as expected:
  - `bash scripts/ci/verify_release_pr_scope.sh --pr 18`
  - Failure: `PR #18 is missing required release file: accrue_portal/mix.exs`
  - PR URL: https://github.com/szTheory/accrue/pull/18
  - Merge state: `UNSTABLE`
  - Files present: `.release-please-manifest.json`, `accrue/CHANGELOG.md`, `accrue/mix.exs`, `accrue_admin/CHANGELOG.md`, `accrue_admin/mix.exs`
- Repair attempt 1:
  - Triggered `Release Please` workflow dispatch
  - Run URL: https://github.com/szTheory/accrue/actions/runs/25532331259
  - Result: workflow `success`, publish jobs skipped, PR `#18` remained pair-only
- Repair attempt 2:
  - Closed stale PR `#18`
  - Triggered replacement `Release Please` workflow dispatch
  - Run URL: https://github.com/szTheory/accrue/actions/runs/25532360320
  - Replacement PR: https://github.com/szTheory/accrue/pull/19
  - Replacement verifier result: `bash scripts/ci/verify_release_pr_scope.sh --pr 19`
  - Failure: `PR #19 is missing required release file: accrue_portal/mix.exs`
  - Merge state: `UNSTABLE`
- Blocking outcome:
  - Root cause was `origin/main` lagging 230 commits behind local `main`, leaving GitHub without the committed `accrue_portal/` tree.
  - After pushing `main` to `origin/main`, Release Please generated a valid three-package PR.
- Recovery success:
  - Current release PR: https://github.com/szTheory/accrue/pull/21
  - Recorded target version: `1.1.0`
  - Verifier pass: `bash scripts/ci/verify_release_pr_scope.sh --pr 21`
  - Do not merge if scope verification fails:
    `bash scripts/ci/verify_release_pr_scope.sh --pr 21 --version 1.1.0`
  - Revalidation after merge:
    - `bash scripts/ci/verify_release_pr_scope.sh --pr 21 --version 1.1.0`
    - State: `MERGED`
    - Merge commit: `5cd030760bc5930d565b82d9a912dff860eafb14`
    - Merged at: `2026-05-08T02:31:34Z`

## Publish run evidence

2026-05-08T03:00:58Z

- Bound merge-triggered Release Please run:
  - `RUN_ID: 25533304999`
  - Run URL: https://github.com/szTheory/accrue/actions/runs/25533304999
  - Trigger: push on merge commit `5cd030760bc5930d565b82d9a912dff860eafb14`
- Ordered job results:
  - `release` (`Release Please`) -> `success`
  - `publish-accrue` -> `success`
  - `publish-accrue-admin` -> `success`
  - `publish-accrue-portal` -> `failure`
- Portal publish blocker:
  - Failed step: `Dry run accrue_portal Hex publish`
  - Error: `Missing files: LICENSE*`
  - The tagged `1.1.0` release commit includes `LICENSE*` in `accrue_portal/mix.exs` package files, but `accrue_portal/` at the released ref does not contain a matching license file.
- Blocking outcome:
  - `REL-11` is not satisfied because the ordered publish chain did not complete.
  - Stop before public-proof capture and post-publish mirror cleanup.
  - Recovery must publish `accrue_portal` successfully for `1.1.0` or supersede the partial line with a new linked release before Phase 121 can continue.

## Public registry proof

2026-05-08T12:06:49Z

- Recovery release PR: https://github.com/szTheory/accrue/pull/23
- Recovery release version: `1.1.1`
- Recovery workflow run: https://github.com/szTheory/accrue/actions/runs/25554198977
- Git tags bound to merge commit `99b573f927ab29e7d3fda9a356a7b39177daf567`:
  - `accrue-v1.1.1`
  - `accrue_admin-v1.1.1`
  - `accrue_portal-v1.1.1`
- GitHub releases published:
  - `https://github.com/szTheory/accrue/releases/tag/accrue-v1.1.1`
  - `https://github.com/szTheory/accrue/releases/tag/accrue_admin-v1.1.1`
  - `https://github.com/szTheory/accrue/releases/tag/accrue_portal-v1.1.1`
- Hex registry truth:
  - `accrue` -> `1.1.1`
  - `accrue_admin` -> `1.1.1`
  - `accrue_portal` -> `1.1.1`
- `REL-11` satisfied on the superseding linked trio release line after the failed `1.1.0` attempt was recovered with PR `#22` and republished via PR `#23`.

## Post-publish mirror notes

2026-05-08

- Updated package and host mirrors to reflect the shipped trio instead of the stale pair story:
  - `README.md`
  - `accrue/guides/first_hour.md`
  - `examples/accrue_host/README.md`
  - `examples/accrue_host/docs/adoption-proof-matrix.md`
- Tightened post-publish verifier needles to the released trio truth:
  - `scripts/ci/verify_package_docs.sh`
  - `scripts/ci/verify_adoption_proof_matrix.sh`
  - `scripts/ci/verify_verify01_readme_contract.sh`
- Host proof recovery required one router-level correction beyond the plan’s initial file list:
  - separate the mounted customer portal from admin billing paths in `examples/accrue_host`
  - thread the required admin session key at `/billing`
  - derive mount-specific admin pipeline names so dual admin mounts compile warning-free
- Supporting host proof updates also touched:
  - `examples/accrue_host/config/config.exs`
  - `examples/accrue_host/lib/accrue_host_web/router.ex`
  - `examples/accrue_host/test/accrue_host_web/portal_cold_start_test.exs`
  - `examples/accrue_host/test/install_boundary_test.exs`
  - `scripts/ci/accrue_host_seed_e2e.exs`
  - `accrue_admin/lib/accrue_admin/router.ex`

## Post-publish smoke reruns

2026-05-08

- `bash scripts/ci/verify_package_docs.sh` -> pass
- `bash scripts/ci/verify_adoption_proof_matrix.sh` -> pass

## Post-publish verifier reruns

2026-05-08

- `bash scripts/ci/verify_release_manifest_alignment.sh` -> pass
- `bash scripts/ci/verify_release_contract.sh` -> pass
- `bash scripts/ci/verify_package_docs.sh` -> pass
- `bash scripts/ci/verify_verify01_readme_contract.sh` -> pass
- `bash scripts/ci/verify_production_readiness_discoverability.sh` -> pass
- `bash scripts/ci/verify_adoption_proof_matrix.sh` -> pass
- `bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` -> pass
- `bash scripts/ci/accrue_host_uat.sh` -> pass

### Proof capture 2026-05-08T12:06:49Z

PR_NUMBER: 23
TARGET_VERSION: 1.1.1
RUN_ID: 25554198977

Workflow run: https://github.com/szTheory/accrue/actions/runs/25554198977

#### Workflow job ordering

| Job | Conclusion | Started | Completed |
|-----|------------|---------|-----------|
| release | success | 2026-05-08T11:55:40Z | 2026-05-08T11:56:08Z |
| publish-accrue | success | 2026-05-08T11:56:10Z | 2026-05-08T11:59:20Z |
| publish-accrue-admin | success | 2026-05-08T11:59:23Z | 2026-05-08T12:02:33Z |
| publish-accrue-portal | success | 2026-05-08T12:02:41Z | 2026-05-08T12:05:39Z |

#### Git tags

| Package | Tag | Commit |
|---------|-----|--------|
| accrue | accrue-v1.1.1 | 99b573f927ab29e7d3fda9a356a7b39177daf567 |
| accrue_admin | accrue_admin-v1.1.1 | 99b573f927ab29e7d3fda9a356a7b39177daf567 |
| accrue_portal | accrue_portal-v1.1.1 | 99b573f927ab29e7d3fda9a356a7b39177daf567 |

#### GitHub releases

| Package | Tag | Release URL | Published |
|---------|-----|-------------|-----------|
| accrue | accrue-v1.1.1 | https://github.com/szTheory/accrue/releases/tag/accrue-v1.1.1 | 2026-05-08T11:55:56Z |
| accrue_admin | accrue_admin-v1.1.1 | https://github.com/szTheory/accrue/releases/tag/accrue_admin-v1.1.1 | 2026-05-08T11:55:57Z |
| accrue_portal | accrue_portal-v1.1.1 | https://github.com/szTheory/accrue/releases/tag/accrue_portal-v1.1.1 | 2026-05-08T11:55:58Z |

#### Hex API truth

| Package | latest_version | updated_at | API |
|---------|----------------|------------|-----|
| accrue | 1.1.1 | 2026-05-08T11:59:18.458383Z | https://hex.pm/api/packages/accrue |
| accrue_admin | 1.1.1 | 2026-05-08T12:02:30.377067Z | https://hex.pm/api/packages/accrue_admin |
| accrue_portal | 1.1.1 | 2026-05-08T12:05:37.121567Z | https://hex.pm/api/packages/accrue_portal |
