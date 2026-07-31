---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
verified: 2026-07-31T01:26:38Z
status: gaps_found
score: 12/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/13
  gaps_closed:
    - "The advisory refresh Processor facade is optional-callback safe."
    - "The shared pull/webhook reconciler converges monotonically under same-timestamp webhook ordering."
  gaps_remaining: []
  regressions:
    - "Isolation guard coverage is incomplete: executable seam references in Accrue.Entitlements.Guard are not scanned."
gaps:
  - truth: "The isolation guard covers the new client-fetch/shared-writer surface across the resolver/guard grant path."
    status: failed
    reason: "scripts/ci/verify_entitlement_sync_isolation.sh scans entitlements.ex, resolver.ex, and resolver/local_map.ex, but not accrue/lib/accrue/entitlements/guard.ex. Guard is the shared always-on decision engine for Plug and LiveView enforcement, so an executable Accrue.Processor.list_active_entitlements/2 reference injected there still returns verify_entitlement_sync_isolation: OK."
    artifacts:
      - path: "scripts/ci/verify_entitlement_sync_isolation.sh"
        issue: "gate_path_files omits accrue/lib/accrue/entitlements/guard.ex."
      - path: "accrue/lib/accrue/entitlements/guard.ex"
        issue: "Actual grant decision module is outside the static isolation scan."
    missing:
      - "Add accrue/lib/accrue/entitlements/guard.ex to the isolation script's scanned gate-path files."
      - "Add a hermetic red-path test proving executable list_active_entitlements, Reconcile, StripeSync, and EntitlementSummary references in guard.ex fail while comments/docs still pass."
---

# Phase 213: Stripe-native advisory entitlements sync Verification Report

**Phase Goal:** Close the Phase 127 "optional Stripe-native entitlements sync" deferral by wiring a client-backed, opt-in refresh path into the existing advisory entitlements cache via the new `LatticeStripe.Entitlements.*` 2.x surface -- while proving, by test, that the sync can never become a grant gate and that the isolation guard now covers the new surface.
**Verified:** 2026-07-31T01:26:38Z
**Status:** gaps_found
**Re-verification:** Yes -- after 213-04 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A client-backed refresh path fetches Stripe active entitlements via LatticeStripe and writes EntitlementSummary. | VERIFIED | `StripeSync.refresh/2` calls `Processor.list_active_entitlements/2`; `Processor.Stripe.list_active_entitlements/2` drains `ActiveEntitlement.stream!/3`; `Reconcile.write_pull/4` writes summary-shaped rows. Targeted tests passed. |
| 2 | Sync is off by default, opt-in via `stripe_native_sync: :advisory`, and advisory output is not read by current grant paths. | VERIFIED | `refresh/2` returns `{:ok, :disabled}` before Processor/Repo I/O when disabled; current gate files and `Guard` contain no executable advisory references; grant-invariance tests passed. |
| 3 | Isolation guard covers the new client-fetch/shared-writer surface across the resolver/guard grant path. | FAILED | The script scans only three files and omits `accrue/lib/accrue/entitlements/guard.ex`. A temp fixture with executable `Accrue.Processor.list_active_entitlements/2` injected into `guard.ex` returned `verify_entitlement_sync_isolation: OK` and exit code 0. |
| 4 | `fetch_entitled/2` ambiguity is closed. | VERIFIED | `admin.ex` and `guides/entitlements.md` say `fetch_entitled/2` is will-not-build; docs verifier tests reject ambiguity and predicate reintroduction. |
| 5 | Fake/Test-only suite proves cache population, grant invariance, and default-off behavior. | VERIFIED | Phase lane using Fake/Test seams passed: refresh, worker, isolation, grant-invariance, docs tests. No live Stripe/Chrome test path was required. |
| 6 | Advisory refresh Processor facade is optional-callback safe. | VERIFIED | `Processor.list_active_entitlements/2` uses `Code.ensure_loaded/1` and `function_exported?/3`; callback-omitting adapter test returns typed 501 `unsupported_operation` with bounded message. |
| 7 | Disabled refresh returns before Processor or Repo I/O. | VERIFIED | `stripe_sync_refresh_test.exs` asserts `{:ok, :disabled}`, Fake call count 0, and no summary row. |
| 8 | Pull and webhook writes share one reconciler and converge monotonically under same-timestamp ordering. | VERIFIED | `Reconcile.check_stale/3` and `ON CONFLICT` both use timestamp plus bytewise event-id ordering; same-second opposite-arrival tests and property/concurrency tests passed. |
| 9 | Pull refresh emits bounded telemetry/provenance and no raw entitlement payload in telemetry. | VERIFIED | `StripeSync.refresh/2` span metadata is bounded to customer ids/source; `Reconcile.emit_summary_synced/3` emits count/source/result. Raw entitlement list is persisted to diagnostic JSON, not telemetry metadata. |
| 10 | Stripe adapter drains the ActiveEntitlement stream and projects bounded string-keyed maps. | VERIFIED | Adapter calls `ActiveEntitlement.stream!(client, %{"customer" => id, "limit" => "100"}, opts)` and maps to id/object/feature/lookup_key/livemode; contract tests passed. |
| 11 | RefreshWorker is inert, host-owned, existing-queue only, and delegates to refresh. | VERIFIED | Worker uses `queue: :accrue_webhooks`, scalar `%{"customer_id" => id}`, loads `Customer`, calls `StripeSync.refresh/1`, and has no scheduler. |
| 12 | Isolation guard fails executable gate-path references while allowing docs/comments for scanned files. | VERIFIED | Repository script passed; hermetic isolation guard tests passed for the files currently scanned. Coverage gap for `guard.ex` is captured separately as failed truth #3. |
| 13 | Local grant results are identical under no, empty, stale, and contradictory advisory rows. | VERIFIED | `stripe_sync_disabled_isolation_test.exs` compares `entitled?/2`, `features_for/1`, `has_active_plan?/2`, and `entitlement_quantity/2` under advisory-enabled config. |

**Score:** 12/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue/lib/accrue/processor.ex` | Optional list callback facade and metadata accessor | VERIFIED | Optional callback is guarded and returns a typed unsupported error when absent. |
| `accrue/lib/accrue/entitlements/stripe_sync.ex` | Public observational refresh primitive | VERIFIED | Config branch precedes Processor/Repo I/O; enabled path fetches through Processor and writes through Reconcile. |
| `accrue/lib/accrue/entitlements/reconcile.ex` | Shared webhook/pull EntitlementSummary writer | VERIFIED | Webhook and pull writes share one writer with timestamp/event-id ordering and provenance. |
| `accrue/lib/accrue/processor/stripe.ex` | Real list_active_entitlements adapter | VERIFIED | Drains `ActiveEntitlement.stream!/3`, projects bounded maps, exposes SDK list-path metadata. |
| `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex` | Thin Oban refresh worker | VERIFIED | Existing queue, scalar args, delegates to `StripeSync.refresh/1`; malformed arg retry behavior remains a review warning. |
| `scripts/ci/verify_entitlement_sync_isolation.sh` | Static gate isolation coverage | FAILED | Covers new tokens for the three scanned files but omits `entitlements/guard.ex`, an actual grant decision module. |
| `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` | Runtime grant invariance proof | VERIFIED | Covers no/empty/stale/contradictory advisory rows and the full local grant surface. |
| `accrue/lib/accrue/entitlements/admin.ex` | Closed fetch_entitled rationale | VERIFIED | Moduledoc records will-not-build decision. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `stripe_sync.ex` | `processor.ex` | `Processor.list_active_entitlements/2` and metadata accessor | WIRED | Manual trace confirms call after config branch. |
| `stripe_sync.ex` | `reconcile.ex` | `Reconcile.write_pull/4` | WIRED | Pull refresh delegates cache write to shared writer. |
| `default_handler.ex` | `reconcile.ex` | entitlement summary webhook dispatch | WIRED | `reduce_entitlement_summary/4` delegates to `Reconcile.write_webhook/4`. |
| `processor/stripe.ex` | LatticeStripe ActiveEntitlement | `ActiveEntitlement.stream!/3` | WIRED | Adapter calls SDK stream with customer and limit 100. |
| `refresh_worker.ex` | `stripe_sync.ex` | `StripeSync.refresh/1` | WIRED | Worker perform path delegates after loading customer. |
| isolation script | `entitlements/guard.ex` | static scan of grant decision module | NOT_WIRED | Script does not scan `guard.ex`; injected executable seam reference there passed the script. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `StripeSync.refresh/2` | `entitlements` | `Processor.list_active_entitlements/2` | Yes | FLOWING - Fake and Stripe adapters both feed `Reconcile.write_pull/4`. |
| `Processor.Stripe.list_active_entitlements/2` | streamed entitlement list | `ActiveEntitlement.stream!/3` | Yes | FLOWING - materialized with `Enum.map/2`; SDK page errors return `{:error, APIError}` instead of partial success. |
| `Reconcile.write_pull/4` | summary payload | complete entitlement list plus list path | Yes | FLOWING - summary-shaped payload includes list URL, entitlements, provenance, and monotone ordering. |
| `RefreshWorker.perform/1` | customer id | Oban job args | Yes | FLOWING - loads `Customer` and delegates for valid scalar ids. |
| `verify_entitlement_sync_isolation.sh` | gate-path file list | hardcoded `gate_path_files` array | Partial | HOLLOW EDGE - current scanned files are protected, but `guard.ex` is a grant module outside the list. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Optional callback and Stripe contract regressions pass | `cd accrue && mix test test/accrue/processor/optional_entitlements_callback_test.exs test/accrue/processor/stripe_entitlements_contract_test.exs` | 5 tests, 0 failures | PASS |
| Same-second ordering/property regressions pass | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs` | 1 property, 18 tests, 0 failures | PASS |
| Compile gate passes | `cd accrue && mix compile --warnings-as-errors` | exit 0 | PASS |
| Phase Fake/Test lane passes | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/entitlements/stripe_sync_refresh_worker_test.exs test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs test/accrue/docs/package_docs_verifier_test.exs` | 53 tests, 0 failures | PASS |
| Repository isolation script stays green | `bash scripts/ci/verify_entitlement_sync_isolation.sh` | `verify_entitlement_sync_isolation: OK` | PASS |
| Guard-file injection should fail isolation | temp `ROOT_DIR` fixture with executable `Accrue.Processor.list_active_entitlements/2` added to `entitlements/guard.ex`, then `bash scripts/ci/verify_entitlement_sync_isolation.sh` | `verify_entitlement_sync_isolation: OK`, exit code 0 | FAIL |
| Review WR-01 capability mismatch reproduced | `cd accrue && MIX_ENV=test mix run -e 'Application.put_env(:accrue, :processor, Accrue.Processor.Stripe); IO.inspect(Accrue.Processor.supports?([:entitlements, :stripe_native_sync]))'` | `false` | WARNING |

### Probe Execution

Step 7c: SKIPPED - no phase-declared or conventional `probe-*.sh` files were discovered.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SYNC-01 | 213-01, 213-02, 213-04 | Client-backed advisory refresh fetches Stripe active entitlements and writes advisory cache | SATISFIED | Stripe adapter, refresh primitive, Reconcile write path, optional-callback safety, and tests exist and passed. |
| SYNC-02 | 213-01, 213-02, 213-03, 213-04 | Opt-in observational-only sync, no resolver/guard consumption, D-01/D-11 preserved | BLOCKED | Current code does not read advisory state from grants, and grant-invariance tests pass, but the static guard does not cover `Accrue.Entitlements.Guard`, so the guard-path isolation proof is incomplete. |
| SYNC-03 | 213-03 | Isolation script covers new client-fetch entry point | BLOCKED | Script catches new tokens in the three scanned files, but an executable new-token edge in `entitlements/guard.ex` is not scanned and passes. |
| SYNC-04 | 213-03 | `fetch_entitled/2` question resolved | SATISFIED | Code docs and guide close it as will-not-build; verifier rejects reintroduction. |
| SYNC-05 | 213-01, 213-02, 213-03, 213-04 | Fake/Test-only cache, grant, default-off assertions | SATISFIED | Targeted Fake/Test lane passed; contract tests use local transport/Fake seams. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `accrue/lib/accrue/processor/stripe.ex` | 549 | "not available" in typed unsupported-operation message | INFO | Legitimate existing runtime error text, not a stub. |
| `accrue/lib/accrue/processor/stripe.ex` | 99 | Missing `stripe_native_sync: true` in capabilities map | WARNING | Review WR-01 reproduced: the callback works, but machine-readable support advertises false. Non-blocking for the phase goal unless capability discovery is treated as part of the public refresh contract. |
| `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex` | 18 | No malformed-args catch-all | WARNING | Review WR-02: invalid persisted jobs can retry instead of canceling. Non-blocking for valid scalar host-owned jobs required by this phase. |

### Human Verification Required

None. The remaining gap is deterministic and code-level.

### Gaps Summary

The two prior verification blockers are closed. The Processor facade now handles adapters without the optional entitlement callback as typed unsupported operations, and the reconciler now applies one timestamp/event-id ordering policy in both reducer and database conflict logic. The targeted callback, Stripe contract, same-second, concurrency, property, compile, Fake/Test phase lane, and repository isolation checks passed.

The phase still cannot pass because the isolation guard does not cover one of the actual grant decision modules. `Accrue.Entitlements.Guard` owns the shared Plug/LiveView decision engine and delegates to the gate, but `verify_entitlement_sync_isolation.sh` does not scan it. A temporary fixture with an executable `Accrue.Processor.list_active_entitlements/2` reference in `guard.ex` returned OK. Phase 214 is documentation-only and does not defer or cover this gap.

---

_Verified: 2026-07-31T01:26:38Z_
_Verifier: the agent (gsd-verifier)_
