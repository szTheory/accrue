---
phase: 217
fixed_at: 2026-08-03T02:47:30Z
review_path: .planning/phases/217-canonical-projection-and-compatibility/217-REVIEW.md
iteration: 3
findings_in_scope: 7
fixed: 7
skipped: 0
residual_findings: 0
status: all_fixed
---

# Phase 217: Code Review Fix Report

All seven review findings are verified fixed at `7ce8433c`.

The final corrective commit adds a durable `PurchaseOverride` capability. It stores only the SHA-256 capability digest and bounded decision facts, validates them under a row lock at continuation, checks expiry and account/revision/rail/plan/reason/source binding, and binds the capability to one operation ID. Mutable `PurchaseDecision` structs are descriptive only and cannot authorize a warning continuation without that capability.

Local verification passed:

- `mix test test/accrue/entitlements/purchase_decision_test.exs test/accrue/entitlements/compatibility_test.exs test/accrue/entitlements/projector_test.exs test/accrue/entitlements/snapshot_test.exs --exclude live_stripe` — 42 tests, 0 failures.
- `mix format --check-formatted` for the capability implementation, migration, and focused test — passed.

**Final status: all_fixed. No human/UAT verification remains.**
