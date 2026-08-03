---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T16:20:00Z
depth: deep
files_reviewed: 29
files_reviewed_list:
  - accrue/lib/accrue/entitlements.ex
  - accrue/lib/accrue/entitlements/apple/client.ex
  - accrue/lib/accrue/entitlements/apple/intake.ex
  - accrue/lib/accrue/entitlements/apple/lineage.ex
  - accrue/lib/accrue/entitlements/apple/notification_plug.ex
  - accrue/lib/accrue/entitlements/apple/reconcile_worker.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup_worker.ex
  - accrue/lib/accrue/entitlements/apple/verifier.ex
  - accrue/lib/accrue/entitlements/apple/verifier/production.ex
  - accrue/lib/accrue/entitlements/decision_cases.ex
  - accrue/lib/accrue/entitlements/grant.ex
  - accrue/lib/accrue/entitlements/observation.ex
  - accrue/lib/accrue/entitlements/projector.ex
  - accrue/priv/repo/migrations/20260803030000_create_accrue_apple_lineages_and_intakes.exs
  - accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs
  - accrue/priv/repo/migrations/20260803032000_add_apple_ordering_to_entitlement_records.exs
  - accrue/test/accrue/entitlements/apple_intake_test.exs
  - accrue/test/accrue/entitlements/apple_lineage_test.exs
  - accrue/test/accrue/entitlements/apple_notification_test.exs
  - accrue/test/accrue/entitlements/apple_observation_tracer_test.exs
  - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
  - accrue/test/accrue/entitlements/apple_source_isolation_test.exs
  - accrue/test/accrue/entitlements/apple_verifier_test.exs
  - accrue/test/fixtures/apple/server_evidence.exs
  - accrue/test/property/apple_convergence_property_test.exs
  - accrue/test/property/apple_lineage_property_test.exs
  - accrue/test/support/entitlements/fixtures.ex
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 218: Code Re-Review Report

**Reviewed:** 2026-08-03T16:20:00Z
**Depth:** deep
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The durable-wakeup worker, transactional continuation, and checkpoint foreign key address CR-01, CR-04, and WR-01 from the first review. However, the submitted path remains nonfunctional in a deployed application: `Client` can invoke only the in-memory fake, and reconciliation delegates admission of raw provider data to an arbitrary configured callback instead of the phase's verifier-to-intake-to-projector pipeline. The status response is also discarded despite being declared the authority for current subscription state. The passing integration test configures a `%Client.Fake{}` and a test-local callback that writes observations directly, so it cannot establish production behavior.

## Critical Issues

### CR-01: A configured production Apple client cannot be called — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/client.ex:21-37`
**Issue:** `Client.subscription_statuses/3` and `transaction_history/4` dispatch only on `%Client.Fake{}`; every other configured value returns `{:error, :config_invalid}`. `ReconcileWorker` reads a client from application configuration at `reconcile_worker.ex:24-27`, but there is no behaviour/protocol/module dispatch or production client implementation for that value. Thus the exact configured-client path asserted by the fix report can only run with the test fake; a real deployment always marks the checkpoint `needs_repair` without fetching Apple history.
**Fix:** Define a client behaviour whose callbacks accept the configured implementation (or store a configured module and call it), implement the production App Store Server API adapter, and configure that module at runtime. Add an executed-worker integration test using a non-Fake implementation.

### CR-02: Reconciliation has no non-bypassable verified admission and projection path — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/reconcile_worker.ex:14-18`
**Issue:** The worker obtains `:admit_transaction` as an arbitrary unary function from application env and hands each raw signed transaction to it. No production implementation connects this data to `Verifier.verify_transaction/2`, a lineage/account lookup, `Intake.observe/3`, and `Projector.project_in_transaction/3`. The sole proof at `apple_reconciliation_test.exs:108-113` installs a test closure that directly constructs and inserts qualified observations; it performs no signature verification. This leaves the required verifier → lineage/admission → projector authority boundary absent from the shipped worker and makes its safety dependent on an undocumented host callback.
**Fix:** Implement an internal reconciliation admission service that accepts a signed transaction, verifies it with the configured verifier/configuration, loads the already-bound lineage/account, builds `VerifiedEvidence`, and calls `Intake.observe/3` within the reconciliation transaction. Configure stable modules/data rather than a test-only closure, and test rejection of an invalid signed history item before any observation/grant is written.

### CR-03: The declared current-state authority is fetched then discarded — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex:287-293`
**Issue:** The reconciliation code obtains `{:ok, _statuses}` solely as a gate before processing transaction history. It never verifies, normalizes, admits, or projects a status result. This contradicts the phase contract that `Get All Subscription Statuses` is current-state authority; a current expiry/revocation/renewal state that is not represented by the history response cannot repair local grants.
**Fix:** Define and implement status admission alongside transaction-history admission, with verified/normalized status evidence and the same idempotent projector path. Cover a response where status changes entitlement state while the history page is empty.

## Warnings

### WR-01: The replacement convergence property does not test the queued reconciliation path — WARNING

**File:** `accrue/test/property/apple_convergence_property_test.exs:19-39`
**Issue:** This property chooses between exactly two fixed sequences and calls `Intake.observe/3` directly. It never executes the durable wakeup worker or reconciliation worker, supplies no configured client/admission, and does not exercise history pages, continuation, or checkpoint ordering. It therefore cannot detect the remaining production reconciliation failures while claiming delivery-order convergence.
**Fix:** Generate permutations/pages of verified Apple provider evidence, execute wakeup drain plus reconciliation with a real test client/admission implementation, and compare final snapshot, grants, and checkpoint state across the permutations.

---

_Reviewed: 2026-08-03T16:20:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
