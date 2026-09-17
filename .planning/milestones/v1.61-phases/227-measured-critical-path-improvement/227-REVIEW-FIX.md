---
phase: 227
fixed_at: 2026-09-12T17:14:15Z
review_path: /Users/jon/projects/accrue/.planning/phases/227-measured-critical-path-improvement/227-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 227: Code Review Fix Report

**Fixed at:** 2026-09-12T17:14:15Z
**Source review:** `/Users/jon/projects/accrue/.planning/phases/227-measured-critical-path-improvement/227-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: BLOCKER — A successful candidate can be relabeled nonqualifying to force rollback

**Files modified:** `scripts/ci/verify_ci_critical_path.mjs`, `scripts/ci/verify_ci_critical_path.test.mjs`
**Commit:** `42dd4c29`
**Applied fix:** Derived nonqualification from the allowed terminal failure predicates: non-success workflow conclusion, failed/missing required job, or missing required success artifact. A terminal vector satisfying every qualifying predicate can no longer carry a `nonqualifying` label. Added the exact adversarial relabel-to-rollback regression.

### CR-02: BLOCKER — `rollback_verified` is not bound to a successful restoration proof

**Files modified:** `scripts/ci/verify_ci_critical_path.mjs`, `scripts/ci/verify_ci_critical_path.test.mjs`
**Commit:** `28ade913`
**Applied fix:** Split rollback terminal validation. `rollback_verified` now requires exactly one restoration reservation, consumption, and `restoration_only` terminal with success, every required job and success artifact, and provider state `proved`; unverified rollback is the sole closed-unspent state and requires no restoration evidence. Added positive verified-restoration and no-restoration negative fixtures.

## Verification

Verification ran in the main checkout because `workflow.use_worktrees` is `false`.

- `node --check scripts/ci/verify_ci_critical_path.mjs` — passed.
- `node --test scripts/ci/verify_ci_critical_path.test.mjs` — passed (11 tests, 0 failures).
- Offline fixtures, preflight evidence, kept ledger/render, and candidate-workflow gates — passed.
- Read-only live Actions kept verification — passed.
- CI-pinned `mix format --check-formatted` — passed.
- CI-pinned focused `mix test test/accrue/backend_automation_contract_test.exs --warnings-as-errors` — passed (4 tests, 0 failures).
- `git diff --check` — passed.

---

_Fixed: 2026-09-12T17:14:15Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
