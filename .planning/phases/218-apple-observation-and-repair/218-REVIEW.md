---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T14:54:22Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - accrue/lib/accrue/entitlements.ex
  - accrue/lib/accrue/entitlements/apple/client.ex
  - accrue/lib/accrue/entitlements/apple/intake.ex
  - accrue/lib/accrue/entitlements/apple/lineage.ex
  - accrue/lib/accrue/entitlements/apple/notification_plug.ex
  - accrue/lib/accrue/entitlements/apple/reconcile_worker.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex
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
  critical: 4
  warning: 2
  info: 0
  total: 6
status: issues_found
---

# Phase 218: Code Review Report

**Reviewed:** 2026-08-03T14:54:22Z
**Depth:** standard
**Files Reviewed:** 28
**Status:** issues_found

## Summary

The Apple ingress and direct intake paths are covered, but the durable reconciliation path cannot execute end-to-end. Wakeups are never consumed, and even if a host manually invokes the drainer, the generated job has neither an Apple client nor an admission function. Pagination also stops permanently after the first page. The targeted tests pass because they call `Reconciliation.run/2` directly with injected dependencies rather than exercising the queued production path.

## Critical Issues

### CR-01: No code consumes durable reconciliation wakeups — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex:165`

**Issue:** `drain_wakeups/2` is the only code that converts rows in `accrue_entitlement_apple_reconciliation_wakeups` into Oban jobs. A repository-wide caller search finds no invocation. Every notification, verified intake, repair, and host-requested reconciliation therefore only leaves a wakeup row and never contacts Apple or repairs local state.

**Fix:** Schedule a dedicated Oban worker/cron entry that calls `drain_wakeups(Accrue.Repo.repo())`, or enqueue the reconciliation job directly as part of the same transaction that writes the wakeup. Add an integration test that creates a wakeup and proves an executed worker processes it.

### CR-02: Drained jobs always run with a nil client — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex:177-181`

**Issue:** The generated job args contain only `lineage_id`, `environment`, and `reason`. `ReconcileWorker.perform/1` at `reconcile_worker.ex:13` then passes `Map.get(args, "client")`, which is always `nil`. `Client.subscription_statuses/3` returns `{:error, :config_invalid}` for that value, so reconciliation immediately enters `:needs_repair` and cannot fetch any provider state.

**Fix:** Resolve the host-configured Apple client inside the worker (for example, from application configuration) rather than serializing a client in job args, and make the worker cancel with a clearly reported configuration error only when that configured client is absent. Cover the full drain → job → configured-client path.

### CR-03: The background reconciler discards every transaction it fetches — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex:275-278`

**Issue:** `reconcile_page/9` defaults `admit_transaction` to `fn _ -> :ok end` and merely calls it for each signed transaction. `ReconcileWorker.perform/1` supplies no override. Thus the only production worker path acknowledges fetched history and advances the checkpoint without creating observations, projecting grants, or applying revocations; provider history never repairs entitlement state.

**Fix:** Make reconciliation own a concrete verified-transaction admission pipeline (verification, lineage/account lookup, `Intake.observe/3`, and projection), or have the worker resolve and pass a required configured admission implementation. Treat admission failures as transactional/retryable rather than silently advancing the cursor. Add an executed-worker test asserting a history transaction changes the local entitlement state.

### CR-04: A paginated history run has no continuation — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex:293-300`

**Issue:** When Apple responds with `has_more`, this code persists `pending_revision` and `run_state: :running`, but it does not enqueue another wakeup or job. The worker returns `:ok` after that page, so Oban will not retry it. Later pages, including a later revocation, remain unprocessed indefinitely unless unrelated code happens to request the lineage again.

**Fix:** In the same transaction that stores `pending_revision`, enqueue the next bounded reconciliation job/wakeup (or return an Oban continuation/scheduled retry). Test a two-page response through the worker and assert that both pages are admitted and the checkpoint becomes idle only after the final page.

## Warnings

### WR-01: Reconciliation checkpoints can outlive deleted/nonexistent lineages — WARNING

**File:** `accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs:9`

**Issue:** `lineage_id` is a bare `:binary_id`, unlike the intake and wakeup tables. It has no foreign-key constraint to `accrue_entitlement_apple_lineages`, so malformed jobs or lifecycle cleanup can leave orphan checkpoints that look valid and are later locked/updated by reconciliation.

**Fix:** Define `lineage_id` with `Accrue.Migration.references(:accrue_entitlement_apple_lineages, type: :binary_id, name: ...)` and choose an explicit delete policy. Validate that a reconciliation job cannot create a checkpoint for an absent lineage.

### WR-02: The claimed convergence property never exercises reconciliation or ordering — WARNING

**File:** `accrue/test/property/apple_convergence_property_test.exs:7-14`

**Issue:** The generated list is only a list of static `DecisionCases` IDs. The assertion repeatedly checks that each immutable fixture validates; it never permutes observations, calls `Intake`, `Projector`, or `Reconciliation`, nor compares resulting state. It cannot detect the queue/admission/pagination failures above despite claiming arbitrary-order convergence.

**Fix:** Generate permutations of verified Apple observations/pages, run them through the actual intake/reconciliation pipeline against an isolated repo, and assert an identical final snapshot/high-water mark for every ordering.

---

_Reviewed: 2026-08-03T14:54:22Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
