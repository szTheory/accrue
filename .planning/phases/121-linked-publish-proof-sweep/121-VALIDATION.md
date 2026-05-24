---
phase: 121
slug: linked-publish-proof-sweep
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 121 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash verifier bundle + GitHub Actions release/docs lanes + ExUnit-backed host/package suites |
| **Config file** | `.github/workflows/ci.yml` plus package `mix.exs` alias/test config |
| **Quick run command** | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Full suite command** | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_production_readiness_discoverability.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_core_admin_invoice_verify_ids.sh && bash scripts/ci/accrue_host_uat.sh` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh`
- **After every plan wave:** Run `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 121-01-01 | 01 | 1 | REL-10 | T-121-01 | Release PR and intended trio version must match the locked three-package contract before merge | release-proof | `bash scripts/ci/verify_release_pr_scope.sh --pr "$PR_NUMBER" --version "$TARGET_VERSION"` after Plan 01 records `PR_NUMBER` and `TARGET_VERSION` into `121-VERIFICATION.md` | ✅ via Plan 01 | ⬜ pending |
| 121-01-02 | 01 | 1 | REL-10 | T-121-02 / T-121-03 | The live release PR must be refreshed or replaced until one exact PR and target version are recorded and pass the scope gate | release-proof + ledger check | `LEDGER=.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md && PR_NUMBER="$(sed -n 's/^PR_NUMBER: //p' "$LEDGER")" && TARGET_VERSION="$(sed -n 's/^TARGET_VERSION: //p' "$LEDGER")" && test -n "$PR_NUMBER" && test -n "$TARGET_VERSION" && bash scripts/ci/verify_release_pr_scope.sh --pr "$PR_NUMBER" --version "$TARGET_VERSION"` | ✅ via Plan 01 | ⬜ pending |
| 121-02-01 | 02 | 2 | REL-10, REL-11 | T-121-05 / T-121-06 | Publish order and workflow evidence must bind to the exact merged PR, workflow run, and shipped trio version | workflow + ledger check | `LEDGER=.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md && PR_NUMBER="$(sed -n 's/^PR_NUMBER: //p' "$LEDGER")" && TARGET_VERSION="$(sed -n 's/^TARGET_VERSION: //p' "$LEDGER")" && RUN_ID="$(sed -n 's/^RUN_ID: //p' "$LEDGER")" && test -n "$PR_NUMBER" && test -n "$TARGET_VERSION" && test -n "$RUN_ID" && bash scripts/ci/verify_release_pr_scope.sh --pr "$PR_NUMBER" --version "$TARGET_VERSION" && gh run view "$RUN_ID" --repo szTheory/accrue --json conclusion,jobs,url` | ✅ via Plans 01-02 | ⬜ pending |
| 121-02-02 | 02 | 2 | REL-10, REL-11 | T-121-07 / T-121-08 | Public tags, GitHub releases, and Hex truth must all match the exact recorded PR, run id, and shipped version | release-proof + ledger check | `LEDGER=.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md && PR_NUMBER="$(sed -n 's/^PR_NUMBER: //p' "$LEDGER")" && TARGET_VERSION="$(sed -n 's/^TARGET_VERSION: //p' "$LEDGER")" && RUN_ID="$(sed -n 's/^RUN_ID: //p' "$LEDGER")" && test -n "$PR_NUMBER" && test -n "$TARGET_VERSION" && test -n "$RUN_ID" && git fetch --tags --force origin && for pkg in accrue accrue_admin accrue_portal; do curl -fsSL "https://hex.pm/api/packages/${pkg}" | jq -e --arg v "$TARGET_VERSION" '.latest_version == $v' >/dev/null; done && gh release view "accrue-v${TARGET_VERSION}" --repo szTheory/accrue >/dev/null && gh release view "accrue_admin-v${TARGET_VERSION}" --repo szTheory/accrue >/dev/null && gh release view "accrue_portal-v${TARGET_VERSION}" --repo szTheory/accrue >/dev/null && git rev-parse "accrue-v${TARGET_VERSION}" >/dev/null && git rev-parse "accrue_admin-v${TARGET_VERSION}" >/dev/null && git rev-parse "accrue_portal-v${TARGET_VERSION}" >/dev/null` | ✅ via Plan 02 | ⬜ pending |
| 121-03-01 | 03 | 3 | PPX-13, PPX-14 | T-121-09 / T-121-10 / T-121-11 | Post-publish docs and mirrors must reflect the released line and fail fast on pair/trio drift | doc truth + ledger check | `LEDGER=.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md && TARGET_VERSION="$(sed -n 's/^TARGET_VERSION: //p' "$LEDGER")" && test -n "$TARGET_VERSION" && curl -fsSL https://hex.pm/api/packages/accrue_portal | jq -e --arg v "$TARGET_VERSION" '.latest_version == $v' >/dev/null && rg -Fx "Published trio on Hex: accrue, accrue_admin, and accrue_portal at ${TARGET_VERSION}" README.md && ! rg -F 'the \`accrue\` / \`accrue_admin\` pair on the branch you are reading' README.md && rg -Fx "Published release line: accrue, accrue_admin, and accrue_portal ${TARGET_VERSION}" accrue/guides/first_hour.md && ! rg -F "linked ${TARGET_VERSION} pair" accrue/guides/first_hour.md && rg -Fx "This checked-in proof surface is the linked accrue / accrue_admin / accrue_portal ${TARGET_VERSION} release slice" examples/accrue_host/README.md && ! rg -F "This checked-in proof surface is the linked \`accrue\` / \`accrue_admin\` \`${TARGET_VERSION}\` release slice" examples/accrue_host/README.md && rg -Fx "This matrix is refreshed for the linked ${TARGET_VERSION} trio" examples/accrue_host/docs/adoption-proof-matrix.md && ! rg -F "This matrix is refreshed for the linked ${TARGET_VERSION} pair" examples/accrue_host/docs/adoption-proof-matrix.md` | ✅ via Plan 03 | ⬜ pending |
| 121-03-02 | 03 | 3 | REL-10, REL-11, PPX-13, PPX-14 | T-121-05 | One dated verification ledger must tie the exact PR number, workflow run id, shipped version, public proof, and rerun verifiers to the same release | artifact check | `test -f .planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md` plus grep checks for recorded `PR_NUMBER`, `RUN_ID`, and `TARGET_VERSION` markers | ✅ via Plans 01-03 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Add a deterministic release-proof command or script for REL-10 across Hex API, git tags, GitHub releases, and changelog surfaces
- [x] Add a deterministic workflow-order evidence capture command or script for REL-11 against the real release run
- [x] Expand docs-contract verification or explicit task coverage for remaining pair-oriented mirrors in `README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md`
- [x] Define the canonical `121-VERIFICATION.md` ledger structure and population path

Wave 0 is satisfied by the planned artifacts and tasks:
- Plan 01 introduces `verify_release_pr_scope.sh`, `capture_linked_release_proof.sh`, and the seeded `121-VERIFICATION.md` ledger.
- Plan 02 binds publish proof to the exact merged PR, workflow run, and shipped trio version.
- Plan 03 updates the remaining pair-oriented mirrors and reruns the full post-publish bundle.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Release PR refresh/repair choice is appropriate for the live GitHub state | REL-10 | The repo may need human judgment if the stale PR cannot be safely refreshed automatically | Inspect the current release PR, confirm whether it includes all three packages, then follow the plan's refresh or replacement path before merge |
| Final publish proof is complete enough for maintainer auditability | REL-11 | The ledger needs a human sanity pass even if commands are scripted | Read `121-VERIFICATION.md` after population and confirm that tags, GitHub releases, Hex API responses, workflow evidence, and rerun verifier results all point at the same version |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07
