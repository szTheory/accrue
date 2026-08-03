---
phase: 218-apple-observation-and-repair
verified: 2026-08-03T16:23:19Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants."
    status: failed
    reason: "The public host facade accepts a caller-constructed VerifiedEvidence value and immediately projects it; it has no verifier/configuration/attestation boundary. The production verifier also does not enforce an Apple signing certificate purpose."
    artifacts:
      - path: "accrue/lib/accrue/entitlements.ex"
        issue: "observe_apple_evidence/3 delegates directly to Intake.observe/3 for any %VerifiedEvidence{}."
      - path: "accrue/lib/accrue/entitlements/apple/verifier/production.ex"
        issue: "validate_leaf_purpose/1 accepts any EC public key and does not validate Apple EKU/key-usage purpose."
    missing:
      - "Make every grant-changing purchase/restore path invoke the configured strict verifier before constructing admission facts, or make the verified capability unforgeable/private."
      - "Validate the required Apple certificate purpose/key usage and add positive/negative certificate-chain tests."
  - truth: "Scheduled status and history reconciliation repairs missed notifications and accurately represents active, grace, retry, expiry, refund, and revocation boundaries."
    status: failed
    reason: "A completed checkpoint stores next_due_at, but no production code selects due checkpoints or schedules a new ReconcileWorker job. Reconciliation only starts from an existing wakeup, so a missed notification has no periodic repair trigger."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/reconciliation.ex"
        issue: "due/2 is defined but has no production caller; next_due_at is written only."
    missing:
      - "Add and host-wire a durable due-checkpoint scheduler/sweeper (with locking) and prove it creates and executes reconciliation work after a missed notification."
---

# Phase 218: Apple Observation and Repair Verification Report

**Phase Goal:** Verified Apple evidence safely contributes to the account snapshot and repairs itself without ownership reassignment or provider-lifecycle confusion.
**Verified:** 2026-08-03T16:23:19Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An authenticated account can use its opaque entitlement UUID for purchase/restore; eligible verified lineage binds once and conflicts quarantine without reassignment. | ✓ VERIFIED | `apple_purchase_context/2` returns the account UUID; `Lineage.lock_or_insert/4` uses the environment/original-transaction unique key and `FOR UPDATE`; `claim/5` binds only matching tokens and otherwise returns a non-owner-disclosing conflict. Focused lineage/tracer tests pass. |
| 2 | Only strictly verified Apple evidence can change grants. | ✗ FAILED | `Entitlements.observe_apple_evidence/3` accepts any caller-built `Intake.VerifiedEvidence` and `Intake.persist_and_project/5` creates an Observation then calls `Projector.project_in_transaction/3`; no verifier is invoked. In addition, the production verifier's certificate-purpose check only accepts an EC key, not an Apple signing purpose/key usage. |
| 3 | Duplicate, delayed, and out-of-order evidence converges idempotently; invalid, unmatched, and conflicting input is non-granting and repairable. | ✓ VERIFIED | Intake has durable closed outcomes and idempotent environment/event identity; notification ingress only acknowledges durable terminal outcomes; the persisted-job convergence property exercises wakeup drain, worker, admission, intake, and projection. The 35-test Apple command plus property passed. |
| 4 | Scheduled status/history reconciliation repairs missed notifications and represents lifecycle boundaries without notification ordering. | ✗ FAILED | Status/history workers and bounded lifecycle normalization exist, but `next_due_at` is never consumed in production: `Reconciliation.due/2` has no caller outside its test. A missed notification after the previous run cannot initiate repair. |
| 5 | Hosts get honest externally-managed Apple guidance, while Family Sharing and offer authoring remain explicit deferrals. | ✓ VERIFIED | `apple_management/0` delegates to the registry and the isolation test proves exact text/action label plus typed `:deferred` outcomes and no Stripe callback reachability. |

**Score:** 3/5 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/apple/lineage.ex` | Environment-qualified bind-once ownership | ✓ VERIFIED | Substantive row-lock/unique-key implementation; wired by Intake and repair facade. |
| `accrue/lib/accrue/entitlements/apple/intake.ex` | Closed evidence outcome and projector admission | ⚠️ WIRED, UNSAFE | It is substantive and wired to Observation/Projector, but the public input type is forgeable and reaches grants without verification. |
| `accrue/lib/accrue/entitlements/apple/verifier/production.ex` | Strict private JWS verifier | ✗ INCOMPLETE | ES256, x5c path, bundle/environment/app checks are present; Apple certificate purpose/key usage is not checked. |
| `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | Durable wakeup/status/history reconciliation | ⚠️ PARTIAL | Transactional wakeup drain, history continuation, retry job, and checkpoint logic are implemented; no periodic due-checkpoint dispatch exists. |
| `accrue/lib/accrue/entitlements/apple/notification_plug.ex` | Bounded Notifications V2 acknowledgement | ✓ VERIFIED | Calls the verifier, persists only digest-based durable intake/quarantine results, and maps terminal/retry outcomes to HTTP status. |
| `accrue/lib/accrue/entitlements.ex` | Typed host Apple surface and guidance | ✓ VERIFIED | Public contexts/outcomes are bounded and wired to lineage, reconciliation, and registry guidance; its direct admission seam is the AAPL-02 gap above. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `NotificationPlug` | `Verifier` → notification intake | opaque `signedPayload` | ✓ WIRED | `verify_notification/2` precedes `Intake.observe_notification/2`; focused notification tests cover durable success, quarantine, rollback, limits, and redaction. |
| Reconciliation worker | configured client → Admission → Intake → Projector | persisted scalar Oban args | ✓ WIRED | Worker resolves configured client/admission; Admission verifies transactions, locks the bound lineage, then calls Intake with enqueue suppression. Persisted-job property covers the chain. |
| Direct host facade | `Intake` → `Projector` | `%VerifiedEvidence{}` | ✗ UNSAFE | It is connected but has no verifier call or proof capability before projection. |
| Checkpoint `next_due_at` | future `ReconcileWorker` job | scheduled repair | ✗ NOT WIRED | No call site selects due checkpoints or enqueues work from `next_due_at`. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Notification ingress | verified notification facts | strict verifier result | Yes; then durable digest/intake/wakeup | ✓ FLOWING |
| Reconciliation | status/history JWS | configured Apple client → Admission verifier | Yes when a wakeup already exists | ⚠️ PARTIAL — no periodic trigger |
| Purchase/restore facade | `VerifiedEvidence` | arbitrary caller-created struct | No verifier provenance is established | ✗ DISCONNECTED TRUST BOUNDARY |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Apple-focused suites and convergence property | `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` | 35 tests + 1 property, 0 failures | ✓ PASS |
| Status client uses correct sandbox endpoint | `cd accrue && mix test test/accrue/entitlements/apple_reconciliation_test.exs --only status` | 3 tests, 0 failures | ✓ PASS |
| Candidate package remains absent | `rg 'app_store_server_library' accrue/mix.exs accrue/mix.lock` | no matches; Jason remains the existing dependency | ✓ PASS |
| Periodic due-checkpoint dispatch | `rg 'Reconciliation\\.due\\(' accrue/lib` | no caller; only the function definition | ✗ FAIL |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AAPL-01 | 218-01, 218-04 | Opaque UUID plus bind-once, no heuristic reassignment | ✓ SATISFIED | Locked environment-qualified lineage, authorization-before-repair, and focused integration/tracer coverage. |
| AAPL-02 | 218-02, 218-03 | Strict verified Notifications V2/nested evidence before grants | ✗ BLOCKED | Candidate was correctly rejected and no new dependency is present, but direct forged `VerifiedEvidence` admission and missing certificate-purpose enforcement violate the requirement. |
| AAPL-03 | 218-01, 218-04, 218-07 | Idempotent convergence, quarantine, repairability | ✓ SATISFIED | Durable intakes/wakeups, bounded notification ingress, and persisted-job property coverage. |
| AAPL-04 | 218-05, 218-06 | Scheduled status/history repair and lifecycle bounds | ✗ BLOCKED | Status/history processing and lifecycle order exist, but regular due reconciliation is unwired. |
| AAPL-05 | 218-08 | Honest external management and explicit deferrals | ✓ SATISFIED | Exact registry guidance, typed policy deferrals, and Stripe-isolation test. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements.ex` | 84 | Trust-by-struct admission | 🛑 Blocker | A caller can supply values labeled `VerifiedEvidence` and reach projection without strict verification. |
| `accrue/lib/accrue/entitlements/apple/verifier/production.ex` | 154 | Certificate-purpose check is only EC-key-type check | 🛑 Blocker | Non-Apple EC signing certificates are not rejected by explicit purpose policy. |
| `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | 205, 364 | Persisted schedule with no scheduler consumer | 🛑 Blocker | Missed-notification recovery is not scheduled. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the Phase 218 implementation/test files.

## Human Verification / Escalation Notes

The phase plans carry four unresolved judgment-tier privacy/transparency prohibitions (owner disclosure, raw evidence/PII retention, reassignment, and Apple-control representation). Focused tests provide meaningful coverage, but a release reviewer should still inspect configured production telemetry/log sinks and host integration copy; this is not a substitute for closing the two executable blockers above.

## Gaps Summary

Phase 218 is not achieved. The private hand-rolled fallback honors the recorded dependency decision—`app_store_server_library` is absent and Jason/OTP are used—but the grant authority boundary remains bypassable, and durable scheduled repair has no production dispatcher. These are blockers, not future-phase deferrals: neither concern is specifically assigned to a later roadmap phase.

---

_Verified: 2026-08-03T16:23:19Z_
_Verifier: the agent (gsd-verifier)_
