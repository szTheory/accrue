---
phase: 229-repository-truth-recovery-safety
plan: 04
subsystem: infra
tags: [git, recovery, repository-inventory, ci-observation]
requires:
  - phase: 229-02
    provides: read-only CI monitor contract
  - phase: 229-03
    provides: preservation manifest, verified bundle, and inventory tools
provides:
  - Recovery-backed final repository inventory and deterministic diagnostic
  - Actual-bundle recovery revalidation and timestamped typed final-capture invariants
affects: [230-reviewable-history-integration]
tech-stack:
  added: []
  patterns: [actual-bundle recovery validation, exact-path hash authorization, timestamped typed capture attestation, deterministic JSON-to-Markdown inventory]
key-files:
  created: []
  modified:
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/render_repository_inventory.mjs
    - scripts/ci/verify_repository_inventory.mjs
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json
    - .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md
key-decisions:
  - "Authorize only .planning/milestone.lock and .planning/state.json through exact before/after SHA-256 evidence."
  - "Require the actual recovery bundle and an additive private capture attestation before remote observation."
  - "Record unavailable remote observations explicitly instead of replacing them with local or cached claims."
patterns-established:
  - "Recovery inventory accepts workflow metadata drift only from a restrictive supplemental authorization record outside the repository."
requirements-completed: [REPO-01, REPO-02, REPO-03]
actuals:
  tokens: 30730
  tasks: 2
  commits: 5
commits: 5
plan_head_before: 215ff3afc67e7a3610eaa227c25eb8478cb1b402
duration: 35min
completed: 2026-09-13
status: remediation-pending-audit
---

# Phase 229 Plan 04: Recovery-backed Repository Truth Summary (Audit Rerun Pending)

**A deterministic repository and CI evidence snapshot with all 109 frozen refs independently verified in the actual bundle and only two timestamped, hash-proven GSD metadata refreshes authorized.**

## Performance

- **Duration:** 35 min
- **Tasks:** 2/2
- **Files modified:** 7
- **Verification:** Inventory fixtures, final independent verifier, and CI monitor documentation self-test passed.

## Accomplishments

- Documented the read-only, exact-repository CI list, inspect, and bounded watch commands.
- Revalidated the original bundle digest, bundle structure, every one of 109 frozen refs, preservation mappings, v1.61 tag object, and typed artifact snapshot before collection.
- Repaired the final-capture boundary so it performs bounded `git bundle verify`, checks actual listed bundle heads for every frozen original ref/object, and rejects malformed timing/invariant evidence before remote observation.
- Anchored the original private recovery-manifest SHA-256 in the committed canonical inventory and require it as an independent input before manifest parsing, bundle access, artifact/attestation checks, or adapter observation; private manifest ownership and mode are fail-closed.
- Captured a schema-v2 JSON authority and byte-reproducible Markdown projection; all remote facts are explicit unavailable records rather than substituted local facts.
- Restricted the authorized artifact delta to `.planning/milestone.lock` and `.planning/state.json`, each with a fixed path, type, before SHA-256, after SHA-256, and workflow-owned state.

## Task Commits

1. **Task 1: Document the supported inventory and CI observation commands** — `f40f9a92` (docs)
2. **Task 2: Capture and independently verify the final repository truth snapshot** — `024063f1`, `ed1ff4d9` (feat, fix)
3. **Security remediation: independently validate bundle membership and capture attestation** — `fix(229-04)` atomic remediation commit

## Decisions Made

- The original private manifest and bundle remain unchanged; restrictive supplemental authorization records live beside them with mode `0600`, including one final record after required GSD state tracking republished its metadata.
- The final additive private attestation records one ISO-8601 observation time and typed before/after invariants for every frozen artifact; only the two exact GSD metadata paths may differ.
- The verifier requires repository-bound GET provenance and can require the two exact workflow metadata authorization records.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Allowed valid slash-delimited Git branch names in worktree evidence**
- **Found during:** Task 2
- **Issue:** The inventory validator rejected the active `gsd/...` milestone branch despite it being a valid, safe Git branch name.
- **Fix:** Retained control-character, backslash, absolute-path, and repeated-separator rejection while allowing normal Git branch separators.
- **Files modified:** `scripts/ci/collect_repository_inventory.mjs`, `scripts/ci/verify_repository_inventory.mjs`
- **Verification:** Fixture suite and final inventory verification passed.
- **Commit:** `024063f1`

**Total deviations:** 1 auto-fixed (Rule 1).

### Security Audit Remediation

**2. [Rule 2 - Missing critical functionality] Independently revalidated actual recovery bundle membership before capture**
- **Found during:** Post-plan security audit
- **Issue:** The collector trusted private-manifest `bundle_member` flags and did not require the actual bundle or timestamped capture proof.
- **Fix:** Required a bundle path and final-capture attestation, compared the actual bundle digest to the manifest, ran bounded bundle verification/listing, checked every frozen original ref/object and preservation ref, and added fail-closed adapter-order fixtures.
- **Files modified:** `scripts/ci/collect_repository_inventory.mjs`, `scripts/ci/verify_repository_inventory.mjs`, `scripts/ci/README.md`
- **Commit:** `fix(229-04)` atomic remediation commit

**3. [Rule 2 - Missing critical functionality] Anchored original private recovery-manifest integrity**
- **Found during:** Second post-plan security audit (T-229-15).
- **Issue:** A coordinated replacement of the private manifest and bundle could produce mutually consistent but fraudulent recovery evidence.
- **Fix:** Added the original manifest SHA-256 to the committed canonical inventory and deterministic Markdown, require an exact expected digest before parsing the private manifest or touching dependent evidence, and fail closed on missing/wrong digest, broad permissions, or unavailable ownership validation.
- **Files modified:** `scripts/ci/collect_repository_inventory.mjs`, `scripts/ci/verify_repository_inventory.mjs`, `scripts/ci/render_repository_inventory.mjs`, `scripts/ci/README.md`, canonical inventory/validation evidence.
- **Commit:** this atomic `fix(229-04)` remediation commit.

### Authorized Workflow Metadata Follow-up

Required GSD closeout republished `.planning/state.json`. Rather than accepting the changed hash, the final snapshot was regenerated from an additive, private mode-`0600` capture attestation that records one observation time plus typed pre/post SHA-256 invariants for every frozen artifact. Only `.planning/milestone.lock` and `.planning/state.json` are authorized to differ; all other artifacts are explicitly unchanged. The original recovery manifest, bundle, and prior supplemental records were not modified.

## Remote Observation

The collector ran with `--observe-remote`; no live adapter was available, so each remote category is recorded as `unavailable` with its repository-bound GET request. No CI run, ref, PR, issue, provider, or publication action was performed.

## Known Stubs

None.

## Next Phase Readiness

The Phase 229 security audit and final verifier must rerun before Phase 230 consumes this inventory. Phase 230 alone owns any reconciliation or main synchronization.

## Self-Check: PASSED

- `ed1ff4d9`, `024063f1`, and `f40f9a92` exist in repository history; the atomic remediation commit contains the final capture, code, test, documentation, and validation evidence together.
- Final JSON and Markdown inventory files exist and passed deterministic verification.
