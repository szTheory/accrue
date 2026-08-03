---
phase: 218
fixed_at: 2026-08-03T15:49:10Z
review_path: /Users/jon/projects/accrue/.planning/phases/218-apple-observation-and-repair/218-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 218: Code Review Fix Report

**Fixed at:** 2026-08-03T15:49:10Z
**Source review:** `/Users/jon/projects/accrue/.planning/phases/218-apple-observation-and-repair/218-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: No code consumes durable reconciliation wakeups — BLOCKER

**Files modified:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex`, `accrue/lib/accrue/entitlements/apple/reconciliation_wakeup_worker.ex`, `accrue/lib/accrue/entitlements/apple/intake.ex`
**Commit:** 0908e0be
**Applied fix:** Wakeups enqueue a durable drain worker transactionally.

### CR-02: Drained jobs always run with a nil client — BLOCKER

**Files modified:** `accrue/lib/accrue/entitlements/apple/reconcile_worker.ex`
**Commit:** 59f1b87e
**Applied fix:** The worker resolves the configured client at execution time and cancels when configuration is absent.

### CR-03: The background reconciler discards every transaction it fetches — BLOCKER

**Files modified:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex`, `accrue/lib/accrue/entitlements/apple/reconcile_worker.ex`
**Commit:** 599b0953
**Applied fix:** Transaction admission is required and admission errors prevent cursor advancement.

### CR-04: A paginated history run has no continuation — BLOCKER

**Files modified:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex`, `accrue/test/accrue/entitlements/apple_reconciliation_test.exs`
**Commit:** d7fe0316
**Applied fix:** Pending checkpoints enqueue a continuation job; coverage proves wakeup drain through configured admission, projection, two pages, and final idle state.

### WR-01: Reconciliation checkpoints can outlive deleted/nonexistent lineages — WARNING

**Files modified:** `accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs`
**Commit:** 244bd102
**Applied fix:** Checkpoints now reference Apple lineages with cascade deletion.

### WR-02: The claimed convergence property never exercises reconciliation or ordering — WARNING

**Files modified:** `accrue/test/property/apple_convergence_property_test.exs`
**Commit:** f4425b51
**Applied fix:** The property now permutes verified Apple evidence through intake, wakeup scheduling, observation, and projection and asserts terminal convergence.

---

_Fixed: 2026-08-03T15:49:10Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
