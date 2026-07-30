---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
verified: 2026-07-30T21:40:37Z
status: gaps_found
score: 11/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The advisory refresh Processor facade is optional-callback safe."
    status: failed
    reason: "Accrue.Processor declares list_active_entitlements/2 optional but the facade calls __impl__().list_active_entitlements/2 unconditionally, so an adapter without the optional callback raises UndefinedFunctionError instead of returning a typed unsupported result."
    artifacts:
      - path: "accrue/lib/accrue/processor.ex"
        issue: "list_active_entitlements/2 does not guard function_exported?/3 before invoking the configured adapter."
    missing:
      - "Guard the optional callback in the facade and add a regression test with an adapter that lacks list_active_entitlements/2."
  - truth: "The shared pull/webhook reconciler converges monotonically under same-timestamp webhook ordering."
    status: failed
    reason: "check_stale/2 allows equal event timestamps, but the DB upsert guard only accepts COALESCE(existing.synced_at, existing.last_stripe_event_ts) < EXCLUDED.synced_at. A distinct same-second Stripe event passes the pre-check then is discarded as stale, leaving the cache behind."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/reconcile.ex"
        issue: "Conflict guard uses strict '<' while the reducer treats equal webhook timestamps as processable."
      - path: "accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs"
        issue: "Existing equal-timestamp coverage asserts stale/no-change behavior; it does not cover distinct same-second updates with new payload and event id."
    missing:
      - "Define and implement the intended same-timestamp tie policy, then add a regression test for two distinct summary events for the same customer with the same created second."
---

# Phase 213: Stripe-native advisory entitlements sync Verification Report

**Phase Goal:** Accrue can optionally fetch Stripe active entitlements through the upgraded LatticeStripe 2.x client, reduce a complete customer-scoped list into the existing advisory EntitlementSummary cache through a shared monotonic reconciler, expose only an inert host-owned refresh worker, and independently prove the diagnostic cache cannot affect grant decisions.
**Verified:** 2026-07-30T21:40:37Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Client-backed refresh fetches active Stripe entitlements through LatticeStripe and writes EntitlementSummary | VERIFIED | `Processor.Stripe.list_active_entitlements/2` drains `ActiveEntitlement.stream!/3`; `StripeSync.refresh/2` calls `Processor.list_active_entitlements/2` then `Reconcile.write_pull/4`; adapter and refresh tests passed. |
| 2 | Sync is off by default, opt-in via `stripe_native_sync: :advisory`, and advisory output is not read by grant paths | VERIFIED | `StripeSync.refresh/2` returns `{:ok, :disabled}` before I/O when config is off; resolver gate files have no forbidden references; runtime grant-invariance test covers empty, stale, and contradictory rows. |
| 3 | Isolation script covers the new client-fetch/shared-writer surface | VERIFIED | `verify_entitlement_sync_isolation.sh` scans `list_active_entitlements` and `Reconcile`; hermetic negative tests exist; script run returned `verify_entitlement_sync_isolation: OK`. |
| 4 | `fetch_entitled/2` ambiguity is closed | VERIFIED | `admin.ex` and `guides/entitlements.md` state `fetch_entitled/2` is will-not-build; docs verifier tests reject ambiguity and reintroduced predicates. |
| 5 | Fake/Test-only suite proves cache population, grant invariance, and default-off behavior | VERIFIED | Targeted phase suite passed: 74 tests, 0 failures. No live Stripe or Chrome paths were required. |
| 6 | Advisory refresh Processor facade is optional-callback safe | FAILED | `Accrue.Processor.list_active_entitlements/2` calls `__impl__().list_active_entitlements/2` directly even though the callback is optional. |
| 7 | Disabled refresh returns before Processor or Repo I/O | VERIFIED | `stripe_sync_refresh_test.exs` asserts `{:ok, :disabled}`, Fake call count 0, and no summary row. |
| 8 | Pull and webhook writes share one reconciler and converge monotonically under same-timestamp ordering | FAILED | Shared writer exists, but equal webhook timestamps are internally inconsistent: `check_stale/2` permits equality while the upsert guard rejects equality. |
| 9 | Pull refresh emits bounded telemetry/provenance and no raw entitlement payload in telemetry | VERIFIED | `StripeSync.refresh/2` span metadata is bounded to ids/source; `Reconcile.emit_summary_synced/3` emits count, entitlement_count, source, result. Raw payload is persisted to the diagnostic row, not emitted as telemetry metadata. |
| 10 | Stripe adapter drains the ActiveEntitlement stream and projects bounded string-keyed maps | VERIFIED | `processor/stripe.ex` maps each item to id/object/feature/lookup_key/livemode and rescues `LatticeStripe.Error`; contract test passed. |
| 11 | RefreshWorker is inert, host-owned, existing-queue only, and delegates to refresh | VERIFIED | Worker uses `queue: :accrue_webhooks`, scalar `%{"customer_id" => id}`, loads `Customer`, calls `StripeSync.refresh/1`, and has no scheduler. |
| 12 | Isolation guard fails executable gate-path references while allowing docs/comments | VERIFIED | Script strips comments/doc strings; `entitlement_sync_isolation_guard_test.exs` covers clean, violation, comment, and missing-file paths. |
| 13 | Local grant results are identical under no, empty, stale, and contradictory advisory rows | VERIFIED | `stripe_sync_disabled_isolation_test.exs` compares `entitled?/2`, `features_for/1`, `has_active_plan?/2`, and `entitlement_quantity/2` under advisory-enabled config. |

**Score:** 11/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue/lib/accrue/processor.ex` | Optional list callback facade and metadata accessor | FAILED | Exists and contains callback/metadata accessor, but optional callback is invoked unconditionally. |
| `accrue/lib/accrue/entitlements/stripe_sync.ex` | Public observational refresh primitive | VERIFIED | Config branch runs before Processor/Repo I/O; refresh calls Processor and Reconcile. |
| `accrue/lib/accrue/entitlements/reconcile.ex` | Shared webhook/pull EntitlementSummary writer | FAILED | Shared and substantive, but same-timestamp conflict semantics are wrong. |
| `accrue/lib/accrue/processor/stripe.ex` | Real list_active_entitlements adapter | VERIFIED | Drains `ActiveEntitlement.stream!/3`, projects bounded maps, exposes list path metadata. |
| `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex` | Thin Oban refresh worker | VERIFIED | Existing queue, scalar args, delegates to `StripeSync.refresh/1`. |
| `scripts/ci/verify_entitlement_sync_isolation.sh` | Static gate isolation coverage | VERIFIED | Covers `list_active_entitlements` and `Reconcile`; local run passed. |
| `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` | Runtime grant invariance proof | VERIFIED | Covers enabled advisory cache states and full local grant surface. |
| `accrue/lib/accrue/entitlements/admin.ex` | Closed fetch_entitled rationale | VERIFIED | Moduledoc records will-not-build decision. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `stripe_sync.ex` | `processor.ex` | `Processor.list_active_entitlements/2` and metadata accessor | WIRED | Manual trace confirms call after config branch. |
| `stripe_sync.ex` | `reconcile.ex` | `Reconcile.write_pull/4` | WIRED | Pull refresh delegates cache write to shared writer. |
| `default_handler.ex` | `reconcile.ex` | entitlement summary webhook dispatch | WIRED | Entitlement-summary handler delegates into Reconcile. |
| `processor/stripe.ex` | LatticeStripe ActiveEntitlement | `ActiveEntitlement.stream!/3` | WIRED | Adapter calls SDK stream with customer and limit 100. |
| `refresh_worker.ex` | `stripe_sync.ex` | `StripeSync.refresh/1` | WIRED | Worker perform path delegates once after loading customer. |
| isolation test | `resolver/local_map.ex` | grant APIs resolve local surface | WIRED | Runtime test exercises the public grant surface. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `StripeSync.refresh/2` | `entitlements` | `Processor.list_active_entitlements/2` | Yes | FLOWING - Fake and Stripe adapters both feed `Reconcile.write_pull/4`. |
| `Processor.Stripe.list_active_entitlements/2` | streamed entitlement list | `ActiveEntitlement.stream!/3` | Yes | FLOWING - materialized via `Enum.map/2`; SDK errors prevent partial success. |
| `Reconcile.write_pull/4` | summary payload | complete entitlement list plus list path | Partial | HOLLOW EDGE - normal flow writes real data, but equal-timestamp conflict can discard a legitimate newer payload. |
| `RefreshWorker.perform/1` | customer id | Oban job args | Yes | FLOWING - loads `Customer` and delegates. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase refresh, adapter, worker, isolation, docs tests pass | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/accrue/processor/stripe_entitlements_contract_test.exs test/accrue/entitlements/stripe_sync_refresh_worker_test.exs test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs test/accrue/docs/package_docs_verifier_test.exs` | 74 tests, 0 failures | PASS |
| Isolation merge gate stays green | `bash scripts/ci/verify_entitlement_sync_isolation.sh` | `verify_entitlement_sync_isolation: OK` | PASS |
| Probes | `find scripts -path '*/tests/probe-*.sh'` | No phase probes discovered | SKIP |

### Probe Execution

Step 7c: SKIPPED - no phase-declared or conventional `probe-*.sh` files were discovered.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SYNC-01 | 213-01, 213-02 | Client-backed advisory refresh fetches Stripe active entitlements and writes advisory cache | SATISFIED | Stripe adapter, refresh primitive, Reconcile write path, and tests exist and passed. |
| SYNC-02 | 213-01, 213-02, 213-03 | Opt-in observational-only sync, no resolver/guard consumption, D-01/D-11 preserved | BLOCKED | Observational-only boundary is verified, but D-11 same-timestamp cache ordering is not preserved. |
| SYNC-03 | 213-03 | Isolation script covers new client-fetch entry point | SATISFIED | Script covers `list_active_entitlements`/`Reconcile`; red-path tests and script pass. |
| SYNC-04 | 213-03 | `fetch_entitled/2` question resolved | SATISFIED | Code docs and guide close it as will-not-build; verifier rejects reintroduction. |
| SYNC-05 | 213-01, 213-02, 213-03 | Fake/Test-only coverage, no live Stripe/Chrome, cache/grant/default-off assertions | SATISFIED | Targeted tests pass; contract tests use local transport/Fake seams. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `accrue/lib/accrue/processor/stripe.ex` | 549 | "not available" in a typed unsupported-operation message | INFO | Legitimate runtime error text, not a stub. |

### Human Verification Required

None. The blocking gaps are code-level and testable.

### Gaps Summary

Phase 213 delivered most of the intended advisory sync path: Fake and Stripe refreshes flow into the diagnostic cache, the worker is inert and host-owned, the grant boundary is protected by static and runtime tests, and `fetch_entitled/2` is closed.

The phase goal is not achieved because the shared reconciler is not correct for distinct same-second webhook updates, and the optional Processor facade can crash when configured with an adapter that does not implement the optional callback. These are not deferred to Phase 214, whose roadmap scope is documentation reconciliation.

---

_Verified: 2026-07-30T21:40:37Z_
_Verifier: the agent (gsd-verifier)_
