---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T19:35:14Z
depth: standard
files_reviewed: 26
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
  - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex
  - accrue/lib/accrue/entitlements/apple/verifier.ex
  - accrue/lib/accrue/entitlements/apple/verifier/production.ex
  - accrue/lib/accrue/entitlements/decision_cases.ex
  - accrue/lib/accrue/entitlements/projector.ex
  - accrue/priv/repo/migrations/20260803030000_create_accrue_apple_lineages_and_intakes.exs
  - accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs
  - accrue/test/accrue/entitlements/apple_intake_test.exs
  - accrue/test/accrue/entitlements/apple_lineage_test.exs
  - accrue/test/accrue/entitlements/apple_notification_test.exs
  - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
  - accrue/test/accrue/entitlements/apple_verifier_test.exs
  - accrue/test/fixtures/apple/server_evidence.exs
  - accrue/test/property/apple_convergence_property_test.exs
  - accrue/test/property/apple_lineage_property_test.exs
  - accrue/test/support/entitlements/fixtures.ex
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 218: Code Review Report

**Reviewed:** 2026-08-03T19:35:14Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

The Apple observation and repair paths were reviewed in full at standard depth, including the production HTTP adapter, verifier, intake/projector flow, checkpoint state machine, migrations, and supplied tests. Two production paths prevent reliable reconciliation or can irreversibly acknowledge unprocessed notifications. The targeted test run also exposes a non-deterministic signature-tampering helper.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Reconciliation sends a local lineage UUID to Apple

**File:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex:372`

**Issue:** `run/2` passes `lineage_id` (the UUID primary key of `accrue_entitlement_apple_lineages`) to both `Client.subscription_statuses/3` and `Client.transaction_history/5`. The production client interpolates that argument directly into Apple’s `/inApps/v1/subscriptions/{originalTransactionId}` and `/inApps/v2/history/{originalTransactionId}` endpoints (`client.ex:122`, `client.ex:135`). Apple therefore receives an Accrue UUID rather than the original transaction ID and rejects the request; every production reconciliation will retry and then enter `needs_repair` without observing the customer’s Apple state. The fakes hide this because they ignore the supplied lineage argument.

**Fix:** Lock/load the lineage inside the reconciliation transaction and pass `lineage.original_transaction_id` to the client while retaining `lineage.id` for checkpoint and job identity. For example:

```elixir
lineage = repo.get!(Accrue.Entitlements.Apple.Lineage, lineage_id)
apple_lineage = lineage.original_transaction_id

with {:ok, statuses} <- Client.subscription_statuses(client, apple_lineage, environment),
     {:ok, page} <- Client.transaction_history(client, apple_lineage, filters,
       checkpoint.pending_revision, environment) do
  # ...
end
```

Add a production-adapter regression test that asserts the URL contains the original transaction ID and never the database lineage UUID.

### CR-02: Missing raw-body capture converts every notification into an acknowledged quarantine

**File:** `accrue/lib/accrue/entitlements/apple/notification_plug.ex:141`

**Issue:** When the route has not installed a `body_reader` that populates `conn.assigns[:raw_body]`, `raw_body_or_empty/1` silently returns `""`. `call/2` then verifies the empty string, treats the resulting terminal verification error as a quarantine, persists it, and responds `200` (`lines 40, 62-79`). Apple stops retrying even though the real notification body was never read or verified, so the reconciliation wakeup is lost. The existing Stripe webhook plug explicitly diagnoses a missing raw body rather than accepting an empty one; this new plug lacks that safety boundary.

**Fix:** Make a missing/invalid raw-body assignment a retryable configuration failure, not an empty payload. Return `{:error, :raw_body_missing}` from `raw_body/2` unless the assignment is a valid binary/iodata list, map it to `503`, and document/use `Accrue.Webhook.CachingBodyReader` on the Apple route. Add a regression test with a normal non-empty request body but no `:raw_body` assign and assert `503`, no intake, and no wakeup.

## Warnings

### WR-01: The signature-tampering test can leave the decoded signature unchanged

**File:** `accrue/test/fixtures/apple/server_evidence.exs:83`

**Issue:** `tamper_signature/1` changes only the final Base64url character, choosing `A`/`B`. For an unpadded signature segment, low-order bits of the final Base64url character can be unused. `A` and `B` can therefore decode to identical signature bytes, leaving a valid JWS unchanged. The supplied targeted suite demonstrably fails at `apple_notification_test.exs:131` with `Production.verify_notification/2` returning `{:ok, ...}` instead of `{:error, :invalid_signature}`. This makes the negative authentication regression flaky.

**Fix:** Alter a character with meaningful encoded bits (for example, mutate a character before the last Base64url quantum) or decode the signature, flip a byte, and re-encode it before rebuilding the compact JWS. Keep the assertion that the altered compact string must fail verification.

---

_Reviewed: 2026-08-03T19:35:14Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
