---
phase: 218-apple-observation-and-repair
verified: 2026-08-03T17:13:57Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "Public purchase/restore admission now accepts opaque signed evidence and resolves verifier authority only from host configuration."
    - "Due checkpoints are now selected under SKIP LOCKED and atomically dispatched through ReconciliationSweeper into ReconcileWorker jobs."
  gaps_remaining:
    - "Active Apple evidence without an expiry can still create an unbounded grant."
    - "The phase-wide Apple test command fails because apple_lineage_test still exercises the removed public VerifiedEvidence input."
  regressions: []
gaps:
  - truth: "Scheduled status and history reconciliation accurately represents active, grace, retry, expiry, refund, and revocation bounds without widening access."
    status: failed
    reason: "Missing expiresDate is accepted as active evidence, normalizes to expires_at: nil, and projects an unbounded Apple grant."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/admission.ex"
        issue: "lifecycle/1 treats an absent or malformed expiresDate as :active."
      - path: "accrue/lib/accrue/entitlements/apple/reconciliation.ex"
        issue: "active lifecycle_bound/2 passes nil expiry through to the Observation/Projector."
      - path: "accrue/test/accrue/entitlements/apple_observation_tracer_test.exs"
        issue: "Its successful signed-evidence fixture omits expiresDate and asserts that a Grant is created."
    missing:
      - "Fail closed or quarantine subscription evidence whose active/renewal lifecycle has no valid verified expiry, and add an integration regression proving no Observation, Grant, or revision is created."
  - truth: "Phase 218 Apple lineage/repair behavior is covered by its runnable regression suite."
    status: partial
    reason: "The documented phase wildcard test command fails: apple_lineage_test passes a caller-constructed VerifiedEvidence to the public facade and still expects the pre-gap-closure verified_unbound result."
    artifacts:
      - path: "accrue/test/accrue/entitlements/apple_lineage_test.exs"
        issue: "Line 18 asserts obsolete public trust-by-struct behavior, so the authorized-repair scenario never executes."
    missing:
      - "Seed the unbound lineage through opaque configured signed evidence, then exercise authorized re-verification/repair; keep the public forged-struct rejection assertion separately."
behavior_unverified_items:
  - truth: "Apple certificate-purpose enforcement accepts a valid Apple-purpose three-certificate ES256 chain and rejects each wrong/missing purpose or key-usage variant before grant admission."
    test: "Run Production.verify_transaction/2 against deterministic valid and hostile three-certificate x5c JWS fixtures, then trace the valid result through Admission and assert hostile variants create no durable effects."
    expected: "The valid chain succeeds; missing/wrong leaf or intermediate purpose, CA leaf, and missing digitalSignature each return invalid_certificate_purpose before any Observation, Grant, or revision."
    why_human: "The production predicate contains the OIDs, but the repository has no positive real-chain fixture or test; apple_verifier_test only tests malformed/invalid-chain cases."
---

# Phase 218: Apple Observation and Repair Verification Report

**Phase Goal:** Safely observe Apple purchase evidence, bind verified lineage to accounts, reconcile missed or out-of-order lifecycle evidence, project canonical account entitlements, and expose honest externally-managed subscription repair/management behavior.
**Verified:** 2026-08-03T17:13:57Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 218-09 and 218-10 gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An authenticated account can use its opaque entitlement UUID for purchase/restore; eligible verified lineage binds once and conflicts quarantine without reassignment. | ✓ VERIFIED | The configured opaque-evidence tracer binds once, duplicates without revision change, preserves unbound/conflict non-granting outcomes, and rejects a caller-created `VerifiedEvidence` before writes. `Lineage` uses the environment/original-transaction identity plus `FOR UPDATE`. |
| 2 | Only Apple evidence verified for permitted algorithms, trust, certificate purpose/time, bundle, environment, and production identity can change grants. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The public facade now calls configured `Admission`, which verifies opaque bytes before `Intake`; `Production` contains the exact leaf/intermediate Apple OIDs, non-CA leaf, and digital-signature checks. But no real positive/hostile three-certificate ES256 test executes that policy. |
| 3 | Duplicate, delayed, and out-of-order evidence converges idempotently; invalid, unmatched, and conflicting input is non-granting and repairable. | ✓ VERIFIED | The focused tracer, reconciliation, isolation, and persisted-job convergence property passed. Intake persists closed outcomes and the projector ordering test keeps delayed active evidence behind a terminal record. |
| 4 | Scheduled status/history reconciliation repairs missed notifications and accurately represents lifecycle boundaries without notification ordering. | ✗ FAILED | The missed-notification scheduler is now real and tested, but a verified transaction without `expiresDate` is classified `active` and produces `expires_at: nil`; the tracer's successful grant fixture takes exactly that path. |
| 5 | Hosts get honest externally-managed Apple guidance, while Family Sharing and offer authoring remain explicit deferrals. | ✓ VERIFIED | `apple_management/0` delegates to the source registry's `:externally_managed` Apple outcome; the isolation test proves the exact guidance, typed deferrals, and no Stripe callback reachability. |

**Score:** 3/5 truths verified (1 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/apple/admission.ex` | Configured opaque-evidence admission boundary | ✓ VERIFIED | Substantive and wired from the public facade and reconciliation admission; it rejects caller options other than `:environment`. |
| `accrue/lib/accrue/entitlements/apple/verifier/production.ex` | Strict production JWS / Apple certificate policy | ⚠️ PRESENT, BEHAVIOR UNVERIFIED | The policy source is substantive and wired, but executable proof lacks the promised valid/hostile real-chain corpus. |
| `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | Status/history repair plus lifecycle bounds | ✗ UNSAFE | `enqueue_due/2` is substantive and wired, but `lifecycle_bound(:active, facts)` accepts a nil expiry. |
| `accrue/lib/accrue/entitlements/apple/reconciliation_sweeper.ex` | Host-owned due-checkpoint dispatch | ✓ VERIFIED | Calls `Reconciliation.enqueue_due/2`; integration test finds the persisted scalar worker job and runs it after a missed notification. |
| `accrue/lib/accrue/entitlements/apple/lineage.ex` | Environment-qualified bind-once ownership | ✓ VERIFIED | Substantive locked unique-identity claim logic, exercised by the opaque-evidence tracer. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Public `observe_apple_evidence/3` | `Apple.Admission` | opaque signed transaction and host-owned application config | ✓ WIRED | `entitlements.ex:92-99` obtains only `:apple_reconciliation` configuration and delegates to `observe_purchase_or_restore/4`; forged structs return `:invalid_input`. |
| `Apple.Admission` | `Intake` / `Projector` | verifier success → normalized internal evidence | ✓ WIRED | `Admission` calls verifier then `Intake.observe/2`; Intake is the sole route to projection. |
| Checkpoint `next_due_at` | `ReconcileWorker` | sweeper → locked atomic scalar job insertion | ✓ WIRED | `enqueue_due/2` selects due idle rows under `FOR UPDATE SKIP LOCKED`, inserts a worker job, and reserves the row transactionally. |
| Reconciliation worker | strict status/history admission | configured client → bound lineage → Intake → projector | ✓ WIRED | The missed-notification and persisted-job property tests execute the worker chain. |
| Admission lifecycle facts | bounded canonical grant | active evidence must carry verified expiry | ✗ NOT WIRED SAFELY | Missing `expiresDate` becomes `:active` with a nil bound and is projected. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Purchase/restore admission | internal `VerifiedEvidence` | configured verifier facts → product map → Intake | Yes, with no caller-selected verifier/configuration | ✓ FLOWING |
| Reconciliation sweeper | due checkpoint → scalar job args | durable checkpoint table under lock | Yes; integration test consumes the persisted job after no notification | ✓ FLOWING |
| Active lifecycle projection | `expires_at` | signed transaction `expiresDate` | No for an absent/malformed expiry: nil flows to Observation and Grant | ✗ HOLLOW / UNBOUNDED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Configured purchase, reconciliation, isolation, verifier and convergence paths | `cd accrue && mix test test/accrue/entitlements/apple_observation_tracer_test.exs test/accrue/entitlements/apple_reconciliation_test.exs test/accrue/entitlements/apple_verifier_test.exs test/accrue/entitlements/apple_source_isolation_test.exs test/property/apple_convergence_property_test.exs` | 29 tests + 1 property, 0 failures | ✓ PASS |
| Reported lineage regression | `cd accrue && mix test test/accrue/entitlements/apple_lineage_test.exs` | 2 tests, 1 failure: expected `verified_unbound`, got `invalid_input` | ✗ FAIL |
| Phase wildcard Apple command | `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` | 38 tests + 1 property, 1 failure (the lineage test) | ✗ FAIL |
| Missing-expiry lifecycle normalization | `cd accrue && MIX_ENV=test mix run --no-start -e '...normalize_lifecycle(active facts without expires_at)...'` | `%{kind: "active", expires_at: nil, ...}` | ✗ FAIL |
| Missed-notification due dispatch | focused reconciliation suite above | `ReconciliationSweeper.sweep/2` inserts and executes a `scheduled_due` job | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AAPL-01 | 218-01, 218-04 | Opaque UUID and bind-once, no heuristic reassignment | ✓ SATISFIED | Opaque admission tracer, locked lineage claim, conflict/unbound non-granting cases. The stale repair test is separately a regression gap. |
| AAPL-02 | 218-02, 218-03, 218-09 | Strict Notifications V2/nested evidence before grants | ? NEEDS HUMAN | The public bypass is closed and policy code is wired, but real positive/negative Apple-purpose certificate behavior is not exercised. |
| AAPL-03 | 218-01, 218-04, 218-07 | Idempotent convergence, quarantine, repairability | ✓ SATISFIED | Durable intake/wakeup outcomes and the persisted-worker permutation property passed. |
| AAPL-04 | 218-05, 218-06, 218-10 | Scheduled status/history repair and lifecycle bounds | ✗ BLOCKED | Due scheduling is repaired, but missing expiry yields an unbounded active grant. |
| AAPL-05 | 218-08 | Honest external management and explicit deferrals | ✓ SATISFIED | Registry guidance, typed deferrals, and Stripe isolation test pass. |

All five planned AAPL IDs are accounted for; no orphaned Phase 218 requirement IDs were found. The later Phase 219/220 roadmap entries do not specifically cover either remaining Apple gap, so neither is deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/apple/admission.ex` | 93-97 | Missing expiry defaults to active | 🛑 Blocker | Validly verified but incomplete subscription facts can create access without a time bound. |
| `accrue/test/accrue/entitlements/apple_observation_tracer_test.exs` | 154-164 | Happy-path fixture omits `expiresDate` while asserting a grant | 🛑 Blocker | The regression suite codifies the unsafe path rather than rejecting it. |
| `accrue/test/accrue/entitlements/apple_lineage_test.exs` | 16-18 | Obsolete public trust-by-struct expectation | 🛑 Blocker | The phase wildcard test command fails and does not exercise the intended authorized-repair path. |
| `accrue/test/accrue/entitlements/apple_verifier_test.exs` | 19-59 | Only malformed/invalid-chain fixtures | ⚠️ Warning | The certificate-purpose predicate lacks real-chain behavioral evidence. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the Phase 218 implementation and focused test files.

### Gaps Summary

Plans 218-09 and 218-10 genuinely close the original public-attestation bypass and unscheduled-checkpoint gaps. The phase still fails its safety goal: incomplete Apple subscription evidence is granted indefinitely. Additionally, the phase’s own wildcard verification command is red because the lineage-repair test was not migrated from the deliberately removed public `VerifiedEvidence` interface. The certificate-purpose source change is plausible but remains a human/evidence escalation item until a valid and hostile real-chain corpus runs it.

---

_Verified: 2026-08-03T17:13:57Z_
_Verifier: the agent (gsd-verifier)_
