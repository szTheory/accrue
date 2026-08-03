---
phase: 218-apple-observation-and-repair
verified: 2026-08-03T21:16:11Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/5
  gaps_closed:
    - "Missing or unusable Apple raw-body capture now fails retryably before verification, quarantine, Intake, or wakeup persistence."
    - "Outer, transaction, and renewal compact-JWS tests now flip a decoded signature byte and deterministically reject each boundary."
    - "Reconciliation retains the local lineage UUID for checkpoints/jobs but sends Apple's original transaction identifier to Production status/history URLs."
  gaps_remaining: []
  regressions: []
---

# Phase 218: Apple Observation and Repair Verification Report

**Phase Goal:** Verified Apple evidence safely contributes to the account snapshot and repairs itself without ownership reassignment or provider-lifecycle confusion.
**Verified:** 2026-08-03T21:16:11Z
**Status:** passed
**Re-verification:** Yes — after Plan 218-15 and Plan 218-16 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An authenticated account can purchase or restore through its opaque entitlement UUID; only eligible verified lineage binds once, while ownership conflicts quarantine without heuristic or automatic reassignment. | ✓ VERIFIED | Real-Repo tracer/property tests cover opaque purchase context, bind-once, conflict privacy/non-granting behavior, authorized repair, and rollback (`apple_observation_tracer_test`, `apple_lineage_test`, `apple_lineage_property_test`). `Lineage.claim/4` and terminal Intake paths are the only ownership transitions. |
| 2 | Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants. | ✓ VERIFIED | Production verifier tests exercise ES256/x5c purpose/time/root policies and closed failures. The notification regression mechanically proves header/payload preservation plus changed decoded signature bytes, then independently rejects outer, transaction, and renewal corruption before wakeup, observation, or grant authority. |
| 3 | Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable. | ✓ VERIFIED | Valid parallel V2 replay coalesces to one Intake/wakeup. Missing, empty, or malformed raw capture returns 503 with zero Intake/wakeup/observation/grant rows. Terminal invalid evidence is durably quarantined; unmapped history remains terminal quarantine while later revocation retracts stale access. |
| 4 | Scheduled status and history reconciliation repairs missed notifications and accurately represents active, grace, retry, expiry, refund, and revocation boundaries. | ✓ VERIFIED | `Reconciliation.run/2` locks local lineage/checkpoint then passes `original_transaction_id` only to both Apple calls. Production URL test proves both encoded URLs include the original ID and exclude local UUID; reconciliation tests cover scheduled recovery, cursor completion, retry/resume, lifecycle normalization, terminal ordering, and revocation. |
| 5 | Hosts receive honest externally-managed Apple subscription guidance, with Family Sharing and offer authoring explicitly deferred. | ✓ VERIFIED | `apple_source_isolation_test` asserts exact typed Apple management guidance, two `:deferred/:review_policy` outcomes, and zero calls to every forbidden Stripe lifecycle callback across observation, repair, reconciliation, and concurrent management use. |

**Score:** 5/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

All 52 declared plan artifacts exist and are substantive (`verify.artifacts` across Plans 01–16). Manual source and executable checks confirmed consumer wiring for the key dynamic artifacts below; the generic verifier reported several false negatives where plan `from` values are concepts rather than file paths.

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| `apple/lineage.ex`, `intake.ex`, `projector.ex`, `reconciliation_wakeup.ex` | Bind-once admission and sole transactional grant writer | ✓ VERIFIED | `Intake.persist_and_project/5` inserts qualified evidence, calls `Projector.project_in_transaction/3`, and queues reconciliation in the same transaction. |
| `apple/verifier.ex`, `apple/verifier/production.ex`, fixture corpus | Independent strict outer/nested verification | ✓ VERIFIED | Production adapter uses Jason and OTP `:public_key`; fixtures sign real ES256 chains and mutate decoded signature bytes deterministically. |
| `apple/notification_plug.ex`, `router.ex`, `guides/webhooks.md` | Exact raw-body ingress and durable acknowledgement | ✓ VERIFIED | Only a non-empty binary or valid captured chunk list reaches verification/quarantine. Router/docs bind the Apple endpoint to `CachingBodyReader.read_body/2` and a 262,144-byte parser limit. |
| `apple/reconciliation.ex`, `client.ex`, workers/sweeper | Locked reconciliation and provider-boundary identity | ✓ VERIFIED | Local `lineage.id` remains checkpoint/job identity while `lineage.original_transaction_id` is URL-encoded for the two Production endpoints. |
| `apple_source_isolation_test.exs`, source registry/facade | Honest management and no Stripe mutation | ✓ VERIFIED | Exact external-management/deferred results and complete forbidden-callback inventory are executable. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Verified bound Apple evidence | Observation → Projector → reconciliation wakeup | `Intake.persist_and_project/5` | ✓ WIRED | Source trace confirms the idempotent Observation, sole writer, and `Reconciliation.enqueue_in_transaction/4` share the outer transaction; tracer rollback test passes. |
| Captured Apple route body | `NotificationPlug` verifier/quarantine | `CachingBodyReader` → `conn.assigns[:raw_body]` | ✓ WIRED | Router macro/docs specify the scoped reader; `captured_raw_body/1` rejects absent/empty/malformed values before rate/verifier/quarantine branches. |
| Decoded ES256 signature mutation | `Production.verify_notification/2` | byte flip → base64url re-encode | ✓ WIRED | Test verifies modified bytes with unchanged protected/payload segments and gets `:invalid_signature` for every JWS boundary. |
| Local reconciliation job | Apple status/history transport | locked lineage’s `original_transaction_id` | ✓ WIRED | Code at `reconciliation.ex` passes original ID to `Client.subscription_statuses/3` and `transaction_history/5`; Production URL capture passes. |
| Apple paths | Stripe lifecycle gateway | forbidden-callback guard | ✓ WIRED | Executable guard asserts all callback counts stay zero. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Notification admission | exact raw request bytes | scoped Phoenix body reader | Valid binary/chunk capture reaches strict Production fixture and durable wakeup | ✓ FLOWING |
| Reconciliation transport | Apple original transaction identifier | locked durable lineage row | Production capture observes the encoded original ID; checkpoint retains local UUID | ✓ FLOWING |
| Account snapshot | verified normalized lifecycle facts | status/history admission → Observation → Projector | Repo tests produce/retract real grants and advance account revisions | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete Phase 218 executable corpus | `cd accrue && mix test test/accrue/entitlements/apple_notification_test.exs test/accrue/entitlements/apple_verifier_test.exs test/accrue/entitlements/apple_reconciliation_test.exs test/accrue/entitlements/apple_lineage_test.exs test/accrue/entitlements/apple_intake_test.exs test/accrue/entitlements/apple_observation_tracer_test.exs test/accrue/entitlements/apple_source_isolation_test.exs test/property/apple_lineage_property_test.exs test/property/apple_convergence_property_test.exs --seed 458442` | 57 tests, 2 properties, 0 failures | ✓ PASS |
| Former raw-capture/signature/URL gaps | `mix test` at the three named test locations, seed 458442 | 3 tests, 0 failures | ✓ PASS |
| Compile and formatting | `mix format --check-formatted … && mix compile --warnings-as-errors` | exit 0 | ✓ PASS |
| Workspace diff whitespace | `git diff --check` | exit 0 | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase 218 probe was declared and no conventional probe script exists. Executable ExUnit/property coverage is the documented acceptance mechanism.

### Plan Must-Haves and Requirements Coverage

Every Plan 01–16 frontmatter requirement is represented below; the 16-plan artifact scan passed 52/52 artifacts. Non-file-shaped key-link entries were manually traced to their actual source functions and their associated focused tests rather than treated as missing implementation.

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AAPL-01 | 01, 04, 11 | Opaque UUID, bind-once ownership, no reassignment | ✓ SATISFIED | Transactional tracer, conflict/private result tests, authorized repair, and mismatched-token property test pass. |
| AAPL-02 | 02, 03, 09, 11, 12, 14, 15 | Strict V2/nested evidence verification | ✓ SATISFIED | Candidate package is absent; private fallback admission evidence and Production ES256/root/time/identity tests pass, including deterministic byte corruption. |
| AAPL-03 | 01, 04, 07, 11, 13, 14, 15 | Convergent non-granting and repairable evidence | ✓ SATISFIED | Replay/concurrency, capture retry/no-write, durable terminal quarantine, and later-terminal retraction tests pass. |
| AAPL-04 | 05, 06, 10, 11, 12, 13, 16 | Scheduled status/history repair and lifecycle projection | ✓ SATISFIED | Scheduled/retry/cursor/lifecycle/ordering tests pass; Production URLs use Apple original ID, not the local key. |
| AAPL-05 | 08 | Honest external management and policy deferrals | ✓ SATISFIED | Typed exact guidance/deferral and zero-Stripe-mutation negative guard pass. |

No Phase 218 requirement is orphaned: ROADMAP and all plan frontmatter map only AAPL-01 through AAPL-05. Later phases 219–220 do not defer any failed Phase 218 contract.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No unreferenced `TBD`, `FIXME`, or `XXX`; no raw-evidence fallback; no Apple-to-Stripe mutation path found. | ℹ️ None | No blocker or warning. |

### Human Verification Required

None. `218-VALIDATION.md` explicitly declares no manual-only acceptance checks, and executable tests cover the prior runtime invariants. There are no human-verification or UAT items.

### Gaps Summary

None. The prior three blocking defects are closed with source-level wiring and named executable regressions. Durable terminal quarantine remains D-09’s terminal handling for verified invalid evidence; missing raw capture is deliberately distinct and retryable before any quarantine or persistence.

---

_Verified: 2026-08-03T21:16:11Z_
_Verifier: the agent (gsd-verifier)_
