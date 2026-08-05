---
phase: 218
fixed_at: 2026-08-03T16:55:00Z
review_path: .planning/phases/218-apple-observation-and-repair/218-REVIEW-2.md
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 218: Code Review Fix Report

**Fixed at:** 2026-08-03T16:55:00Z
**Source review:** `.planning/phases/218-apple-observation-and-repair/218-REVIEW-2.md`
**Iteration:** 2

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: A configured production Apple client cannot be called

**Files modified:** `accrue/lib/accrue/entitlements/apple/client.ex`, `accrue/test/accrue/entitlements/apple_reconciliation_test.exs`
**Commit:** 0f90b919
**Applied fix:** Added behaviour dispatch and a private, OTP `:httpc` App Store Server API adapter with bounded provider error mapping; covered a non-Fake client implementation.

### CR-02: Reconciliation has no non-bypassable verified admission and projection path

**Files modified:** `accrue/lib/accrue/entitlements/apple/reconciliation/admission.ex`, `accrue/lib/accrue/entitlements/apple/reconcile_worker.ex`, `accrue/lib/accrue/entitlements/apple/reconciliation.ex`, `accrue/test/accrue/entitlements/apple_reconciliation_test.exs`
**Commit:** 3d0e80e2
**Applied fix:** Replaced the host admission closure with internal verification, bound-lineage/account validation, and `Intake.observe/3` admission; invalid signed history is rejected before observation or grant writes.
**Follow-up commit:** ebe9a9b4 — corrected the bound-lineage `:ok` contract and converted admission errors into persisted retry checkpoints.

### CR-03: The declared current-state authority is fetched then discarded

**Files modified:** `accrue/lib/accrue/entitlements/apple/reconciliation/admission.ex`, `accrue/lib/accrue/entitlements/apple/reconciliation.ex`, `accrue/test/accrue/entitlements/apple_reconciliation_test.exs`
**Commit:** bd18300b
**Applied fix:** Status responses now feed the same verified, idempotent admission path before history processing, including an empty-history case.

### WR-01: The replacement convergence property does not test the queued reconciliation path

**Files modified:** `accrue/test/property/apple_convergence_property_test.exs`
**Commit:** abbb0c3b
**Applied fix:** Replaced direct Intake calls with generated delivery/page permutations through durable wakeup drain, reconciliation continuations, checkpoints, and terminal snapshot/grant comparisons.

## Verification

`mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` — 32 tests and 1 property, 0 failures.

---

_Fixed: 2026-08-03T16:55:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
