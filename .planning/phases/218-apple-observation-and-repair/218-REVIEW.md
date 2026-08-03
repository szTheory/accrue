---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T17:09:55Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - accrue/guides/entitlements.md
  - accrue/lib/accrue/entitlements.ex
  - accrue/lib/accrue/entitlements/apple/admission.ex
  - accrue/lib/accrue/entitlements/apple/client.ex
  - accrue/lib/accrue/entitlements/apple/intake.ex
  - accrue/lib/accrue/entitlements/apple/lineage.ex
  - accrue/lib/accrue/entitlements/apple/notification_plug.ex
  - accrue/lib/accrue/entitlements/apple/reconcile_worker.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation/admission.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation_sweeper.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex
  - accrue/lib/accrue/entitlements/apple/verifier.ex
  - accrue/lib/accrue/entitlements/apple/verifier/production.ex
  - accrue/lib/accrue/entitlements/decision_cases.ex
  - accrue/lib/accrue/entitlements/projector.ex
  - accrue/priv/repo/migrations/20260803030000_create_accrue_apple_lineages_and_intakes.exs
  - accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs
  - accrue/priv/repo/migrations/20260803032000_add_apple_ordering_to_entitlement_records.exs
  - accrue/test/accrue/entitlements/apple_intake_test.exs
  - accrue/test/accrue/entitlements/apple_lineage_test.exs
  - accrue/test/accrue/entitlements/apple_notification_test.exs
  - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
  - accrue/test/accrue/entitlements/apple_source_isolation_test.exs
  - accrue/test/accrue/entitlements/apple_verifier_test.exs
  - accrue/test/fixtures/apple/server_evidence.exs
  - accrue/test/property/apple_convergence_property_test.exs
  - accrue/test/property/apple_lineage_property_test.exs
  - accrue/test/support/entitlements/fixtures.ex
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 218: Code Review Report

**Reviewed:** 2026-08-03T17:09:55Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The Apple admission, verification, persistence, projection, scheduling, migrations, and focused tests were reviewed. The transaction admission path can turn a verified Apple transaction with no expiry into an indefinite active grant. The selected test command also fails because the lineage test calls the public admission API without the reconciliation/admission configuration that API requires.

## Critical Issues

### CR-01: Missing expiry is treated as an active, non-expiring entitlement

**File:** `accrue/lib/accrue/entitlements/apple/admission.ex:67-80`
**Issue:** `evidence/6` requires neither `expiresDate` nor a verified subscription product type. When a signed transaction omits `expiresDate`, `lifecycle/1` calls `expired?(nil)` and returns `:active`, then `expires_at` is persisted as `nil`. `Snapshot` treats a nil grant expiry as unbounded, so mapping a valid Apple non-subscription transaction (or any unexpected transaction payload) grants the mapped entitlement forever. This is a fail-open authorization error.
**Fix:** Restrict this admission path to verified auto-renewable subscription transactions and require a valid future/past `expiresDate` before emitting an active/expired entitlement observation. Reject missing or malformed expiry as `{:error, :invalid_payload}`. For example:

```elixir
with "Auto-Renewable Subscription" <- facts["type"],
     %DateTime{} = expires_at <- apple_time(facts["expiresDate"]),
     ... do
  # include expires_at in the evidence
else
  _ -> {:error, :invalid_payload}
end
```

## Warnings

### WR-01: Submitted focused test suite is not runnable in isolation

**File:** `accrue/test/accrue/entitlements/apple_lineage_test.exs:8-18`
**Issue:** The setup configures only `:entitlements`, but `Accrue.Entitlements.observe_apple_evidence/3` obtains its verifier and product map from `:apple_reconciliation.admission`. Consequently, the test's initial observation deterministically returns `{:error, :invalid_input}` rather than the expected verified-unbound outcome when the listed tests are run. This leaves the repair flow untested and makes the submitted suite fail.
**Fix:** Configure `:apple_reconciliation` with the test verifier/admission in this test's setup (and restore the previous application environment in `on_exit`), or invoke the intentionally lower-level intake seam with an explicitly verified evidence fixture if that is what the test intends to exercise.

---

_Reviewed: 2026-08-03T17:09:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
