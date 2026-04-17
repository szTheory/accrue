---
phase: 13
fixed_at: 2026-04-17T02:01:56Z
review_path: .planning/phases/13-canonical-demo-tutorial/13-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 13: Code Review Fix Report

**Fixed at:** 2026-04-17T02:01:56Z
**Source review:** `.planning/phases/13-canonical-demo-tutorial/13-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: Repo-root UAT wrapper hard-codes the Postgres readiness probe to the default port

**Files modified:** `scripts/ci/accrue_host_uat.sh`
**Commit:** `23d2c20`
**Applied fix:** Updated the optional `pg_isready` preflight to honor `PGPORT` and `PGDATABASE` alongside the existing host and user overrides.

### WR-02: Order-assertion helpers can crash with `ArithmeticError` before producing the intended drift failure

**Files modified:** `accrue/test/accrue/docs/canonical_demo_contract_test.exs`, `accrue/test/accrue/docs/first_hour_guide_test.exs`
**Commit:** `41e4344`
**Applied fix:** Changed both order helpers to fail with explicit assertion messages when the first or a later required label is missing, and guarded scoped binary matching against out-of-range offsets.

---

_Fixed: 2026-04-17T02:01:56Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
