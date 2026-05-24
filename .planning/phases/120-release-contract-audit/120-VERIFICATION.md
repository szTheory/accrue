---
phase: 120-release-contract-audit
verified: 2026-05-08T01:05:39Z
status: passed
score: 3/3 plans verified
overrides_applied: 0
---

# Phase 120: Release Contract Audit Verification Report

**Phase Goal:** Reconcile the linked package scope, publish order, and maintainer runbook so the next public release tells one honest story.
**Verified:** 2026-05-08T01:05:39Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Phase 120 made an explicit scope decision grounded in current repo and registry evidence instead of leaving `accrue_portal` implicit in automation. | ✓ VERIFIED | [`120-01-SUMMARY.md`](/Users/jon/projects/accrue/.planning/phases/120-release-contract-audit/120-01-SUMMARY.md) records the `promote-three-package` token and the reasoning that existing repo/docs/workflow surfaces already treat `accrue_portal` as a real sibling package. |
| 2 | Maintainer-facing release docs and manual recovery now match the three-package automated publish chain. | ✓ VERIFIED | `RELEASING.md` now documents the linked `accrue` + `accrue_admin` + `accrue_portal` contract and ordered publish flow, while `.github/workflows/publish-hex.yml` now exposes `accrue_portal` with the same explicit ref/version checks and `ACCRUE_PORTAL_HEX_RELEASE=1` publish mode. |
| 3 | The chosen release contract is enforced by CI instead of relying on maintainers to notice drift manually. | ✓ VERIFIED | `scripts/ci/verify_release_contract.sh` enforces cross-file scope/order invariants, `scripts/ci/verify_release_manifest_alignment.sh` verifies all three package versions and linked component keys, `scripts/ci/verify_package_docs.sh` pins the maintainer-facing wording, and `.github/workflows/ci.yml` now invokes the new verifier in the merge-blocking `release-manifest-ssot` job. |

**Score:** 3/3 plans verified

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Manifest and linked-component alignment | `bash scripts/ci/verify_release_manifest_alignment.sh` | `OK: release manifest, linked components, and mix.exs @version aligned at 1.0.0 for accrue/accrue_admin/accrue_portal` | ✓ PASS |
| Cross-file release contract verifier | `bash scripts/ci/verify_release_contract.sh` | `OK: linked release contract aligned for accrue/accrue_admin/accrue_portal` | ✓ PASS |
| Maintainer/package docs drift gate | `bash scripts/ci/verify_package_docs.sh` | `package docs verified for accrue 1.0.0, accrue_admin 1.0.0, and accrue_portal 1.0.0` | ✓ PASS |
| Existing docs-contract compatibility lane | `bash scripts/ci/verify_adoption_proof_matrix.sh` | `verify_adoption_proof_matrix: OK` | ✓ PASS |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
| --- | --- | --- | --- |
| `REL-09` | Release contract surfaces state the same linked package scope and publish order. | ✓ SATISFIED | `RELEASING.md`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, and `.github/workflows/publish-hex.yml` now agree on the three-package linked publish chain, with CI verifiers enforcing that alignment. |
| `PPX-15` | Maintainer-facing recovery and proof surfaces stay honest about what is actually published. | ✓ SATISFIED | Manual recovery now includes `accrue_portal`, package docs/verifiers reference the same suite, and the phase verification bundle is green on the current branch. |

### Validation Basis

- [`120-VALIDATION.md`](/Users/jon/projects/accrue/.planning/phases/120-release-contract-audit/120-VALIDATION.md) defines the quick/full verification contract for the phase.
- [`120-01-SUMMARY.md`](/Users/jon/projects/accrue/.planning/phases/120-release-contract-audit/120-01-SUMMARY.md), [`120-02-SUMMARY.md`](/Users/jon/projects/accrue/.planning/phases/120-release-contract-audit/120-02-SUMMARY.md), and [`120-03-SUMMARY.md`](/Users/jon/projects/accrue/.planning/phases/120-release-contract-audit/120-03-SUMMARY.md) provide plan-level provenance for the decision, contract alignment, and CI enforcement work.

### Gaps Summary

No Phase 120 execution gaps remain. The current branch now records one explicit three-package release truth, exposes that truth in both automated and manual publish flows, and fails CI if future edits split those surfaces again.

---

_Verified: 2026-05-08T01:05:39Z_  
_Verifier: Codex_
