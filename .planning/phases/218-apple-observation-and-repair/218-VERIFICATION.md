---
phase: 218-apple-observation-and-repair
verified: 2026-08-03T19:06:00Z
status: gaps_found
score: 3/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/5
  gaps_closed:
    - "Certificate validation now evaluates every configured root and every certificate at the configured or signed-date policy time."
    - "Verified unmapped products now reach Intake with logical_plan: nil, persist terminal quarantine, and reconciliation continues to later terminal records."
  gaps_remaining: []
  regressions:
    - "Production App Store Server Notifications V2 validation rejects the real outer data-envelope before durable reconciliation wakeup admission."
gaps:
  - truth: "Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants."
    status: failed
    reason: "The production notification verifier applies bundle/environment/app identity checks to the outer V2 notification payload, even though its own nested accessor reads signedTransactionInfo from payload[data]. Genuine V2 envelopes put the application claims in that data map, so valid notifications are classified as wrong_bundle/wrong_environment/wrong_app."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/verifier/production.ex"
        issue: "verify_notification/2 calls verify/2 at line 16; verify/2 unconditionally calls validate_claims/2 at line 52, which reads top-level bundleId/environment/appAppleId at lines 396-415."
      - path: "accrue/test/accrue/entitlements/apple_notification_test.exs"
        issue: "Notification behavior is exercised only through FakeVerifier, not Production with an Apple V2 outer data envelope."
    missing:
      - "Split signed-envelope cryptographic verification from application-claim validation, validate the outer notification data map, and retain metadata such as notificationUUID at the outer level."
      - "Add a production-verifier integration fixture/test with a correctly signed V2 outer data envelope that proves Intake and the reconciliation wakeup commit."
  - truth: "Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable."
    status: failed
    reason: "A genuine verified V2 notification is terminally quarantined as a false application-identity failure, so it does not create the intended durable reconciliation wakeup. This loses the notification-driven repair signal rather than treating the evidence as verified input."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/notification_plug.ex"
        issue: "A verifier error falls through to quarantine/4 (lines 62-79), returning 200 without an Intake.observe_notification wakeup path."
      - path: "accrue/lib/accrue/entitlements/apple/verifier/production.ex"
        issue: "The false identity error originates before nested V2 evidence is admitted."
    missing:
      - "Repair the notification-envelope verification and prove duplicate production V2 deliveries coalesce to one durable wakeup."
---

# Phase 218: Apple Observation and Repair Verification Report

**Phase Goal:** Verified Apple evidence safely contributes to the account snapshot and repairs itself without ownership reassignment or provider-lifecycle confusion.
**Verified:** 2026-08-03T19:06:00Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 218-12 and 218-13 gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An authenticated account can purchase or restore through its opaque entitlement UUID; only eligible verified lineage binds once, while ownership conflicts quarantine without heuristic or automatic reassignment. | ✓ VERIFIED | Public facade accepts opaque signed evidence only; locked lineage claim/repair preserves binding. Focused tracer and lineage tests pass. |
| 2 | Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants. | ✗ FAILED | Direct/nested transaction checks, root rotation, purpose, and certificate-time checks are implemented, but genuine V2 notification envelopes fail identity validation at the wrong payload level. |
| 3 | Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable. | ✗ FAILED | Unmapped-history and ordering regressions pass, but valid V2 notifications are quarantined without their durable reconciliation wakeup. |
| 4 | Scheduled status and history reconciliation repairs missed notifications and accurately represents active, grace, retry, expiry, refund, and revocation boundaries. | ✓ VERIFIED | Locked due sweep, bounded status/history scans, terminal ordering, and the unmapped-to-terminal stale-grant regression are wired and pass. |
| 5 | Hosts receive honest externally-managed Apple subscription guidance, with Family Sharing and offer authoring explicitly deferred. | ✓ VERIFIED | Exact source-registry guidance and typed deferrals are covered by the Stripe-isolation test. |

**Score:** 3/5 truths verified (0 present, behavior-unverified).

### Plan Must-Haves Coverage

| Plans | Status | Evidence |
| --- | --- | --- |
| 218-01, 218-04 | ✓ VERIFIED | Transactional opaque observation, bind-once/unbound repair, closed conflict outcomes, sole Projector writer, and wakeup wiring are present and covered by Repo-backed tests. |
| 218-02 | ✓ VERIFIED | No candidate Apple package was installed; the checked-in admission record documents fallback selection. |
| 218-03, 218-09, 218-11, 218-12 | ✗ FAILED | Strict transaction verification, purpose, multi-root and policy-time checks pass, but the same production verifier misvalidates the V2 outer notification envelope. |
| 218-05, 218-06, 218-10, 218-13 | ✓ VERIFIED | Host-owned sweep/reconcile locks, cursor completion, lifecycle ordering, signed-date history admission, and record-local unmapped quarantine are exercised by focused tests. |
| 218-07 | ✗ FAILED | Plug durability/error handling exists, but only FakeVerifier proves successful notification intake; Production cannot admit a real V2 data envelope. |
| 218-08 | ✓ VERIFIED | Typed management/deferral and zero-Stripe-call isolation are tested. |

### Required Artifacts

`verify.artifacts` found all 42 declared artifacts across the 13 plans present and substantive. Manual wiring and data-flow tracing found the following material status:

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `apple/verifier/production.ex` | Strict JWS/certificate and notification verification | ✗ UNSAFE | Certificate-time/root closure is real; notification identity validation is applied before descending to the V2 `data` envelope. |
| `apple/admission.ex` | Verified transaction to internal evidence | ✓ VERIFIED | Configured verifier and product mapping create `logical_plan: nil` for unmapped products, then Intake persists terminal quarantine. |
| `apple/reconciliation/admission.ex` | Per-record signed-date admission | ✓ VERIFIED | Passes `verification_time: :signed_date`, uses Intake, and the later-terminal regression passes. |
| `apple/reconciliation.ex` / `reconciliation_sweeper.ex` | Durable scheduled repair | ✓ VERIFIED | Due checkpoint lock, scalar job insertion, and final cursor flow are covered. |
| `apple/notification_plug.ex` | V2 durable wakeup boundary | ✗ UNSAFE | Correctly routes a successful verifier result to Intake, but the production verifier supplies a false terminal error for genuine V2 envelopes. |
| `entitlements.ex` / `apple/lineage.ex` / `apple/intake.ex` / `projector.ex` | Opaque bind-once public surface and canonical projection | ✓ VERIFIED | Imports, calls, and Repo-backed state transitions are exercised; no caller-provided verifier or verified struct reaches Intake. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Public Apple observation | `Apple.Admission` | Host-owned config + opaque signed transaction | ✓ WIRED | `Entitlements.observe_apple_evidence/3` delegates to configured admission. |
| Admission | Intake / Projector | Verified facts to normalized evidence | ✓ WIRED | Mapped evidence projects; unmapped evidence reaches Intake's `logical_plan: nil` terminal branch. |
| Production verifier | OTP PKIX | pinned roots + explicit policy time | ✓ WIRED | Every root is attempted and `validate_certificate_times/2` precedes OTP validation. |
| Notification plug | Production verifier → Intake wakeup | V2 signedPayload | ✗ NOT WIRED CORRECTLY | `verify_notification/2` validates outer claims before its own `nested(payload, ...)` data access, returning a false terminal error. |
| Scheduled sweep | Reconcile worker → canonical projector | locked checkpoint/status/history | ✓ WIRED | Worker invokes reconciliation; reconciliation admission uses Intake and complete provider ordering. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Direct/reconciliation admission | `VerifiedEvidence` | configured strict verifier → product map → Intake | Yes | ✓ FLOWING |
| Reconciliation | status/history signed transactions | configured client → signed-date admission → Intake/Projector | Yes | ✓ FLOWING |
| Notification plug | verifier facts / reconciliation wakeup | production V2 outer JWS | No: `validate_claims(payload, config)` rejects before `payload["data"]` is consumed | ✗ DISCONNECTED |
| Management guidance | `Source.Outcome` | Source Registry static declaration | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Apple implementation regressions | `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` | 47 tests, 1 property, 0 failures | ✓ PASS |
| Warning-free compilation | `cd accrue && mix compile --warnings-as-errors` | Exit 0 | ✓ PASS |
| Production V2 notification envelope | Source + fixture test audit | Production has no real V2 outer-envelope fixture/test; code validates top-level app claims while nested data is the only notification payload access. | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — no Phase 218 probe declarations or conventional phase probe scripts were found.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AAPL-01 | 01, 04, 11 | Opaque UUID and bind-once ownership | ✓ SATISFIED | Opaque public boundary, locked lineage, closed conflicts, and repair tests. |
| AAPL-02 | 02, 03, 09, 11, 12 | Strict V2/nested evidence verification | ✗ BLOCKED | Certificate/root/time repairs are valid; production V2 outer-envelope application checks are not. |
| AAPL-03 | 01, 04, 07, 11, 13 | Convergent, non-granting repairable evidence | ✗ BLOCKED | Unmapped/ordering pass, but a genuine V2 notification is falsely quarantined and never becomes a wakeup. |
| AAPL-04 | 05, 06, 10, 11, 12, 13 | Scheduled reconciliation and bounded lifecycle projection | ✓ SATISFIED | Sweeper, checkpoint, status/history, signed-date, lifecycle, and stale-grant retraction coverage passes. |
| AAPL-05 | 08 | Honest external management and deferrals | ✓ SATISFIED | Exact typed management/deferral and Stripe isolation pass. |

All phase-plan requirement IDs are accounted for; no Phase 218 requirement is orphaned from plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/apple/verifier/production.ex` | 16, 52, 396-415 | Outer V2 notification validated with inner application claim predicate | 🛑 BLOCKER | Valid notification is terminally quarantined and cannot trigger its durable repair wakeup. |
| `accrue/test/accrue/entitlements/apple_notification_test.exs` | 8-28 | Fake-only successful notification verifier | 🛑 BLOCKER | Passing tests do not exercise actual V2 envelope compatibility. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in Phase 218 implementation/test files.

### Gaps Summary

The prior two blockers are closed in the current code: certificate verification now honors policy time/all roots, and verified unmapped history continues to later terminal state. The independent validation of `218-REVIEW.md`'s critical finding is affirmative: `verify_notification/2` calls the generic verifier before extracting `data`, while generic claim validation requires top-level application claims. Because the same module later explicitly reads nested signed values from `payload["data"]`, this is an internal code-path contradiction, not a speculative documentation concern.

The full focused suite passes because success-path notification coverage uses `FakeVerifier`; no test invokes Production with a genuine signed V2 outer data envelope. This is a blocker to safe notification-driven repair and prevents phase-goal achievement. No later roadmap phase specifically schedules this envelope repair, so it is not deferred.

---

_Verified: 2026-08-03T19:06:00Z_
_Verifier: the agent (gsd-verifier)_
