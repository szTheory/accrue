---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T19:02:30Z
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 218: Code Review Report

**Reviewed:** 2026-08-03T19:02:30Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

The Apple admission, reconciliation, notification, verifier, persistence, and associated test paths were reviewed. The production notification verifier validates the wrong payload level for Apple Server Notifications V2, so genuine Apple notifications are rejected before they can trigger reconciliation. The included tests use a fixture shape that masks this production incompatibility.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Genuine Apple V2 notifications are rejected as having the wrong bundle/environment

**File:** `accrue/lib/accrue/entitlements/apple/verifier/production.ex:16-22`

**Issue:** `verify_notification/2` first calls `verify/2` on the outer signed notification. `verify/2` unconditionally invokes `validate_claims/2` (lines 52 and 396-405), which reads `bundleId`, `environment`, and `appAppleId` from the top-level payload. In Apple Server Notifications V2 those app-identifying claims are inside the outer payload's `data` object; the outer level contains notification metadata such as `notificationType`, `notificationUUID`, and `signedDate`. Consequently valid production notifications fail at `payload["bundleId"]` with `:wrong_bundle` (or at environment/app validation), return HTTP 200 after quarantine, and never create the reconciliation wakeup. This loses the notification-driven repair signal until a later sweep catches it. The tests' generated outer notification payload incorrectly places these claims at top level, so they do not exercise the real wire format.

**Fix:** Separate signature/chain verification from claim validation, then validate the notification's `data` map while retaining the top-level notification metadata. For example:

```elixir
with {:ok, payload} <- verify_signed(jws, config),
     %{} = data <- payload["data"],
     :ok <- validate_claims(data, config),
     {:ok, transaction_jws} <- nested(payload, "signedTransactionInfo"),
     ... do
  {:ok, %{notification: facts(payload), transaction: facts(transaction), renewal: facts(renewal)}}
end
```

Make `verify_transaction/2` and `verify_renewal/2` continue to validate their own top-level claims, and add an integration fixture/test matching Apple's V2 outer `data` envelope.

---

_Reviewed: 2026-08-03T19:02:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
