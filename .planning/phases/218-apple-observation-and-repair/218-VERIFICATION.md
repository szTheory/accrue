---
phase: 218-apple-observation-and-repair
verified: 2026-08-03T19:39:00Z
status: gaps_found
score: 2/5 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "Production Notifications V2 now authenticates the outer envelope and validates application identity in its authenticated data map."
  gaps_remaining: []
  regressions:
    - "Reconciliation passes the local Apple lineage UUID to production Apple endpoints instead of the original transaction identifier."
    - "A missing cached raw webhook body is treated as an empty payload, durably quarantined, and acknowledged with HTTP 200."
    - "The V2 signature-tampering regression is non-deterministic because its mutation can decode to unchanged signature bytes."
gaps:
  - truth: "Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable."
    status: failed
    reason: "A notification request without the required captured raw body is converted to an empty body, quarantined, and acknowledged 200. Apple therefore stops retries even though the delivered notification was never authenticated or admitted as a repair wakeup."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/notification_plug.ex"
        issue: "raw_body_or_empty/1 returns \"\" for a missing or invalid :raw_body assignment (lines 141-146); call/2 routes its verifier error to quarantine (lines 35-40, 62-79)."
    missing:
      - "Fail missing or invalid raw-body capture as a retryable 503 before verification or quarantine."
      - "Wire and document the caching body reader on the Apple route and add a non-empty-body/no-assign regression proving no Intake or wakeup is persisted."
  - truth: "Scheduled status and history reconciliation repairs missed notifications and accurately represents active, grace, retry, expiry, refund, and revocation boundaries."
    status: failed
    reason: "The production reconciliation client receives the local lineage primary-key UUID, not Apple's originalTransactionId. Apple endpoint requests therefore use the wrong path parameter and cannot obtain authoritative status or history."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/reconciliation.ex"
        issue: "run/2 passes lineage_id unchanged into reconcile_page/9 (lines 318-348), which calls both client methods with it at lines 372 and 375-380."
      - path: "accrue/lib/accrue/entitlements/apple/client.ex"
        issue: "Production client interpolates that argument into /inApps/v1/subscriptions/{id} and /inApps/v2/history/{id} at lines 120-135."
    missing:
      - "Load/lock the lineage and pass lineage.original_transaction_id to Apple while retaining lineage.id for checkpoints and jobs."
      - "Add a production-client regression asserting URLs contain the original transaction ID and never the local lineage UUID."
behavior_unverified_items:
  - truth: "Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants."
    test: "Independently corrupt an outer, transaction, and renewal JWS signature, then assert Production rejects each before any wakeup or grant path."
    expected: "Each cryptographically altered compact JWS returns :invalid_signature and leaves no verified wakeup or grant."
    why_human: "The intended automated regression is not a valid proof: tamper_signature/1 only changes the final Base64url character and can decode to identical signature bytes. The focused suite reproduced a successful Production verification for one purportedly tampered value."
---

# Phase 218: Apple Observation and Repair Verification Report

**Phase Goal:** Verified Apple evidence safely contributes to the account snapshot and repairs itself without ownership reassignment or provider-lifecycle confusion.
**Verified:** 2026-08-03T19:39:00Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 218-14.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An authenticated account can purchase or restore through its opaque entitlement UUID; only eligible verified lineage binds once, while ownership conflicts quarantine without heuristic or automatic reassignment. | ✓ VERIFIED | Prior real-Repo tracer and locked-lineage coverage remain present; the notification repair is account-independent and Plan 14 asserts no Observation, Grant, or revision. |
| 2 | Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Plan 14 correctly separates outer-envelope authentication from authenticated `data` claim validation, but its only independent outer/nested tampering proof is flaky and reproduced as a false success. |
| 3 | Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable. | ✗ FAILED | Missing raw-body capture turns an unverified non-empty delivery into `""`, persists terminal quarantine, and returns 200; Apple will not retry the lost wakeup. |
| 4 | Scheduled status and history reconciliation repairs missed notifications and accurately represents active, grace, retry, expiry, refund, and revocation boundaries. | ✗ FAILED | The production endpoint path is constructed from the Accrue lineage UUID rather than `original_transaction_id`; fakes obscure this because they ignore the argument. |
| 5 | Hosts receive honest externally-managed Apple subscription guidance, with Family Sharing and offer authoring explicitly deferred. | ✓ VERIFIED | Typed source-registry management and explicit deferrals remain isolated from Stripe and are covered by the Apple source-isolation test. |

**Score:** 2/5 truths verified (1 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `apple/verifier/production.ex` | Strict independent outer/nested V2 verification | ⚠️ PRESENT, TEST UNRELIABLE | Correct structural split is wired; a deterministic negative signature test is still missing. |
| `apple/notification_plug.ex` | Durable, retry-safe V2 notification boundary | ✗ UNSAFE | Missing raw-body assignment becomes empty-body terminal quarantine/200. |
| `apple/reconciliation.ex` + `apple/client.ex` | Authoritative status/history repair | ✗ NOT WIRED CORRECTLY | Local UUID crosses the provider boundary as Apple’s original transaction identifier. |
| `apple/intake.ex`, `lineage.ex`, `projector.ex` | Opaque bind-once admission and sole-writer projection | ✓ VERIFIED | Existing real-Repo ownership, transaction, and canonical-projection tracer coverage remains wired. |
| Apple management/source declarations | Honest external management and deferrals | ✓ VERIFIED | Exact typed outcome and Stripe-isolation coverage remains present. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Production V2 JWS | `NotificationPlug` → Intake wakeup | authenticated outer data + independent nested JWS | ✓ WIRED | `verify_notification/2` now validates authenticated `data`, preserves outer UUID, and Plan 14’s valid production fixture reaches one Intake/wakeup. |
| `NotificationPlug` raw request | verifier/quarantine | cached raw bytes | ✗ NOT WIRED SAFELY | Absent `conn.assigns[:raw_body]` is silently converted to `""`. |
| Reconcile job lineage identity | Apple status/history URLs | `original_transaction_id` | ✗ NOT WIRED | `lineage_id` is sent directly to both client calls. |
| Verified evidence | canonical Projector | Intake in one repository transaction | ✓ WIRED | Admission remains the sole route to the existing Projector writer. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Production notification | outer `data`, nested JWS facts | signed V2 fixture → Production → Plug → Intake | Yes | ✓ FLOWING for valid captured bodies |
| Notification raw body | `conn.assigns[:raw_body]` | route body reader | No fallback-safe source | ✗ HOLLOW — missing source is replaced by empty bytes |
| Reconciliation client identity | provider endpoint path parameter | job `lineage_id` | No: database UUID, not Apple original transaction ID | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Apple notification/reconciliation/verifier regressions | `cd accrue && mix test test/accrue/entitlements/apple_notification_test.exs test/accrue/entitlements/apple_reconciliation_test.exs test/accrue/entitlements/apple_verifier_test.exs --seed 458442` | 37 tests, 1 failure: `production V2 independently closes outer and nested signature tampering` received `{:ok, ...}` for a purportedly tampered JWS. | ✗ FAIL |
| Warning-free compilation and diff whitespace | `cd accrue && mix compile --warnings-as-errors && git diff --check` | Exit 0 | ✓ PASS |
| Production reconciliation endpoint identity | Source trace from `Reconciliation.run/2` to `Client` URL construction | `lineage_id` is passed at reconciliation lines 372/375 and interpolated into both Apple URLs. | ✗ FAIL |
| Missing raw-body safety | Source trace through `NotificationPlug.raw_body_or_empty/1` | Missing assignment returns `""`, then terminal verification errors quarantine and acknowledge 200. | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — no Phase 218 probes were declared and no conventional probe scripts were found.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AAPL-01 | 01, 04, 11 | Opaque UUID and bind-once ownership | ✓ SATISFIED | Locked lineage, closed unbound/conflict outcomes, and sole Projector writer remain covered. |
| AAPL-02 | 02, 03, 09, 11, 12, 14 | Strict V2/nested verification | ? NEEDS HUMAN | The production data-envelope correction is present, but the required independent tampering test is nondeterministic and cannot certify the negative invariant. |
| AAPL-03 | 01, 04, 07, 11, 13, 14 | Convergent non-granting, repairable evidence | ✗ BLOCKED | A missing raw body loses a genuine delivery behind a terminal 200 acknowledgement. |
| AAPL-04 | 05, 06, 10, 11, 12, 13 | Scheduled reconciliation and lifecycle projection | ✗ BLOCKED | Production calls Apple with the local lineage UUID; status/history repair cannot work. |
| AAPL-05 | 08 | Honest external management and deferrals | ✓ SATISFIED | Typed management/deferral and Stripe isolation are implemented. |

Every ID declared by the fourteen plan frontmatters is accounted for. No additional Phase 218 requirement is orphaned from plan coverage. Later phases 219–220 address offline/release work, not these Apple provider-boundary gaps; none is deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | 318-380 | Local persistence identity crosses the Apple provider boundary | 🛑 BLOCKER | All production reconciliation requests use an invalid original-transaction ID. |
| `accrue/lib/accrue/entitlements/apple/notification_plug.ex` | 40, 133-146 | Missing security-critical input silently becomes empty input | 🛑 BLOCKER | A genuine notification can be permanently acknowledged without verification or wakeup. |
| `accrue/test/fixtures/apple/server_evidence.exs` | 83-87 | Last Base64url-character mutation may not alter decoded bytes | ⚠️ WARNING | The negative cryptographic regression is non-deterministic; the focused test run failed. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in Phase 218 implementation or test files.

### Gaps Summary

Plan 14 fixes the previous V2 envelope-claim-level defect: a valid production outer envelope now reaches one durable wakeup. That repair is insufficient for the phase goal. The scheduled repair path uses the wrong provider identifier, and the webhook boundary can acknowledge an uncaptured body instead of asking Apple to retry. Both defects are observable in live production paths, not test-only concerns.

The signature helper is a separate warning rather than an inferred production vulnerability: changing an unused Base64url bit is not a cryptographic alteration. It nevertheless invalidates the claimed regression evidence and leaves AAPL-02 behavior-unverified until a deterministic byte-changing negative test is added.

---

_Verified: 2026-08-03T19:39:00Z_
_Verifier: the agent (gsd-verifier)_
