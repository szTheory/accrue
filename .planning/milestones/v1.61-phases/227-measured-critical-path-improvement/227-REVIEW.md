---
phase: 227-measured-critical-path-improvement
reviewed: 2026-09-12T16:49:36Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/test/accrue/backend_automation_contract_test.exs
  - scripts/ci/README.md
  - scripts/ci/preflight_phase227_candidate.sh
  - scripts/ci/verify_ci_critical_path.mjs
  - scripts/ci/verify_ci_critical_path.test.mjs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 227: Code Review Report

**Reviewed:** 2026-09-12T16:49:36Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The six-file scope was reviewed, including the task-local backend contract, detached-worktree preflight, CI graph, v3 ledger validation, and rendered-report checks. The mixed-task regression is present and the current kept ledger verifies, but the v3 verifier still lets unsubstantiated ledger labels change the final decision. Two independently reproduced evidence-integrity defects must be fixed before this ships.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: BLOCKER — A successful candidate can be relabeled nonqualifying to force rollback

**File:** `/Users/dev/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:460`

**Issue:** The validator requires success, complete required jobs, and required artifacts only for `classification: "qualifying"` (lines 465–468). For `"nonqualifying"`, it accepts any non-empty job conclusions and does not require an actual failed required job, failed workflow conclusion, or missing required artifact. The rollback branch then accepts the label alone as evidence (lines 524–526). Replacing a current all-success candidate's classification with `nonqualifying` and changing the decision to rollback is accepted by `verifyFinalDecision`, so append-only evidence can falsely discard a qualifying cohort.

**Fix:** Define the allowed failure predicates and validate them from the terminal vector. Require a nonqualifying candidate to have a non-success workflow conclusion, a failed/missing required job, or a missing required success artifact; reject it when all qualifying predicates hold. Add a regression that mutates an otherwise qualifying candidate to `nonqualifying` and expects rejection.

### CR-02: BLOCKER — `rollback_verified` is not bound to a successful restoration proof

**File:** `/Users/dev/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:520`

**Issue:** All non-kept states take the same branch. It permits `state: "rollback_verified"` with `restoration_authority: "closed_unspent"` and zero restoration records (lines 520–529); it never requires a restoration terminal record, provider proof, or successful required-job vector for that state. I reproduced this by changing the current final decision to `rollback_verified` while retaining no restoration records; `verifyFinalDecision` returned `rollback_verified`. This can falsely represent the rollback as proved.

**Fix:** Split validation by rollback state. Require `rollback_verified` to have exactly one bound `gap_v3_restoration_run` with a successful conclusion, all required jobs/artifacts, and provider state `proved`; allow zero restoration records only for the explicitly unverified/unspent state. Add a negative test for `rollback_verified` without restoration evidence.

---

_Reviewed: 2026-09-12T16:49:36Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
