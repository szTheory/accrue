---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T18:02:21Z
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

**Reviewed:** 2026-08-03T18:02:21Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

The Apple verifier, admission, intake, lineage, reconciliation, projection, persistence migrations, and focused tests were reviewed. Verified but unmapped products currently abort repair instead of being quarantined, leaving prior grants unreconciled. Certificate validation also ignores its declared verification-time control and only accepts the first configured root.

## Critical Issues

### CR-01: An unmapped Apple product stalls reconciliation and preserves stale grants

**Classification:** BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/admission.ex:59-90`

**Issue:** The mapping guard at line 70 rejects an otherwise verified transaction whenever the product is not in `product_map`, returning `{:error, :invalid_payload}`. In the worker path, `Reconciliation.Admission.admit_transaction/5` propagates that error and `Reconciliation.reconcile_page/9` schedules retries (lines 372-395) rather than recording the intended `:unmapped_product` terminal intake. After the retry limit it marks the checkpoint `:needs_repair`; it never processes later status/history entries that could retract an existing grant. A customer who buys an unconfigured product can therefore retain stale access until manual intervention.

**Fix:** Admit verified evidence with `logical_plan: nil`, then let `Intake.do_observe/4` take its existing `nil -> persist_terminal(..., :unmapped_product)` branch. The reconciliation admission path will then treat that terminal intake as a successful, non-granting observation and continue through the rest of the provider response. Add an integration test with a previously granted lineage followed by an unmapped transaction and a revocation.

### CR-02: Certificate validation ignores the configured verification time

**Classification:** BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/verifier/production.ex:143-149`

**Issue:** `Verifier.Config` declares `verification_time` (see `verifier.ex:18-22`) and the nearby comment promises configured-time validation, but `pkix_path_validation/3` is always called with `[]`. OTP therefore evaluates certificate validity at the host's current clock. Historic signed transactions become unverifiable when Apple's short-lived signing certificate expires, so a normal delayed reconciliation cannot repair or revoke state. The configured field has no effect.

**Fix:** Implement a `verify_fun` for `pkix_path_validation/3` that evaluates certificate validity against an explicitly validated `config.verification_time` (or a verified signed timestamp, if that is the intended policy), while retaining all normal path and purpose checks. Cover both a certificate expired now but valid at the supplied verification time and a certificate invalid at that time.

## Warnings

### WR-01: Additional pinned roots are silently ignored

**Classification:** WARNING

**File:** `accrue/lib/accrue/entitlements/apple/verifier/production.ex:104-109,134-141`

**Issue:** The configuration accepts `roots` as a list, but `configured_root/1` matches `[root | _]` and discards every later root. During a normal Apple root rotation, hosts can configure both anchors yet all valid chains under the new root are rejected until the old root is removed/reordered.

**Fix:** Decode every configured root and attempt validation against each pinned anchor, accepting only if one complete path validates; otherwise return the closed certificate error. Add a test where the valid root is the second configured entry.

---

_Reviewed: 2026-08-03T18:02:21Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
