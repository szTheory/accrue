---
phase: 218-apple-observation-and-repair
verified: 2026-08-03T18:06:02Z
status: gaps_found
score: 2/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "Active or renewal-disabled evidence without a verified expiry is now rejected before durable admission."
    - "The documented Apple wildcard regression suite now exercises opaque-evidence repair and passes."
    - "A valid and hostile three-certificate ES256 purpose corpus now executes."
  gaps_remaining:
    - "Certificate validation does not use the configured verification_time, so delayed historical evidence cannot be reliably verified at its intended verification time."
    - "A verified but unmapped product is rejected before Intake's terminal quarantine path; reconciliation retries, then needs manual repair, and can leave a prior grant stale."
  regressions: []
gaps:
  - truth: "Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants."
    status: failed
    reason: "Certificate-time verification is required by AAPL-02 but the production verifier ignores Config.verification_time and always asks OTP to validate at the host current clock."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/verifier/production.ex"
        issue: "validate_order_and_path/2 calls :public_key.pkix_path_validation/3 with [] and has no Config argument."
      - path: "accrue/test/accrue/entitlements/apple_verifier_test.exs"
        issue: "No test proves a chain valid at configured verification_time but expired at the host clock, or invalid at that time."
    missing:
      - "Pass an explicit validated certificate-verification-time policy to PKIX path validation and test both historical-valid and historical-invalid cases."
  - truth: "Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable."
    status: failed
    reason: "Verified unmapped products fail in Admission before Intake can persist :unmapped_product. In reconciliation this becomes retries followed by needs_repair, preventing later lifecycle records from repairing or retracting a prior grant."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/apple/admission.ex"
        issue: "evidence/6 requires a non-nil product_map entry at line 70 instead of emitting VerifiedEvidence with logical_plan: nil."
      - path: "accrue/lib/accrue/entitlements/apple/reconciliation.ex"
        issue: "The returned admission error is routed to schedule_retry/4 and ultimately attempts_exhausted rather than a terminal non-granting disposition."
    missing:
      - "Admit verified unmapped evidence with logical_plan: nil so Intake persists :unmapped_product and reconciliation continues through later provider lifecycle records."
      - "Add an integration regression with a prior grant, an unmapped transaction, and a later terminal record proving no stale grant remains."
---

# Phase 218: Apple Observation and Repair Verification Report

**Phase Goal:** Verified Apple evidence safely contributes to the account snapshot and repairs itself without ownership reassignment or provider-lifecycle confusion.
**Verified:** 2026-08-03T18:06:02Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 218-11 gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An authenticated account can purchase or restore through its opaque entitlement UUID; only eligible verified lineage binds once, while ownership conflicts quarantine without heuristic or automatic reassignment. | ✓ VERIFIED | Public `observe_apple_evidence/3` accepts opaque bytes only and calls configured `Apple.Admission`; `Lineage.claim/5` row-locks the environment/original identity and only binds when the verified token equals the account ID. `apple_observation_tracer_test` covers bind-once, forged-struct rejection, unbound evidence, private conflict, and rollback; `apple_lineage_test` covers authorized repair. |
| 2 | Only Apple evidence verified for permitted algorithms, trust, certificates, bundle, environment, and production identity can change grants. | ✗ FAILED | ES256, x5c, purpose, bundle/environment/app-ID checks and a real hostile corpus exist, but `Production.validate_order_and_path/2` ignores `Config.verification_time` and validates at the host current time. This does not meet AAPL-02's certificate-time contract for delayed historical evidence. |
| 3 | Duplicate, delayed, and out-of-order Apple evidence converges idempotently, while invalid, unmatched, and conflicting input remains non-granting and repairable. | ✗ FAILED | Idempotency, ordering, unbound, and conflict paths are tested. But `Admission.evidence/6` rejects an otherwise verified unmapped product at its mapping guard, before the substantive `Intake` `logical_plan: nil -> :unmapped_product` quarantine path. The reconciliation worker retries the error and ultimately records `needs_repair`, leaving later authoritative records unprocessed. |
| 4 | Scheduled status and history reconciliation repairs missed notifications and accurately represents active, grace, retry, expiry, refund, and revocation boundaries. | ✗ FAILED | Due rows are safely selected with `FOR UPDATE SKIP LOCKED`, and focused tests prove missed-notification repair, bounded lifecycle normalization, terminal ordering, and no unbounded active grant. Nonetheless, the unmapped-product admission failure blocks later history/status records and can retain a stale prior grant; certificate-time failure also prevents normal delayed-history verification after signing-cert expiry. |
| 5 | Hosts receive honest externally-managed Apple subscription guidance, with Family Sharing and offer authoring explicitly deferred. | ✓ VERIFIED | `apple_management/0` delegates to `SourceRegistry`, which returns the exact externally-managed text and action. `apple_family_sharing/0` and `apple_offer_authoring/0` return typed deferrals. The isolation test proves exact output and zero Stripe callbacks for Apple operations. |

**Score:** 2/5 truths verified.

### Required Artifacts

`verify.artifacts` reports every declared artifact substantive and present (32/32 across Plans 01 and 03–11; Plan 02 declares none). The two artifacts below remain unsafe at their actual data-flow boundary.

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/apple/lineage.ex` | Environment-qualified bind-once ownership | ✓ VERIFIED | Unique `(environment, original_transaction_id)` identity plus `FOR UPDATE`; claim/repair do not transfer a bound lineage. |
| `accrue/lib/accrue/entitlements/apple/admission.ex` | Configured opaque-evidence admission | ✗ UNSAFE | Is wired from public observation and reconciliation, but rejects verified unmapped evidence before `Intake` can quarantine it. |
| `accrue/lib/accrue/entitlements/apple/intake.ex` | Sole verified-to-projection admission | ✓ VERIFIED | Normalizes bounds, quarantines `logical_plan: nil`, and only sends bound mapped evidence to projection; currently bypassed for public/reconciliation unmapped input. |
| `accrue/lib/accrue/entitlements/apple/verifier/production.ex` | Strict JWS/certificate policy | ✗ UNSAFE | Real ES256 purpose tests pass, but configured certificate verification time is unused; multiple configured roots are also reduced to the first root. |
| `accrue/lib/accrue/entitlements/apple/reconciliation.ex` | Durable status/history repair | ✗ PARTIAL | Locking, bounded retries, ordering, and lifecycle normalization are substantive, but an Admission error retries instead of recording a terminal unmatched result and continuing. |
| `accrue/lib/accrue/entitlements/apple/reconciliation_sweeper.ex` | Host-owned due-checkpoint dispatch | ✓ VERIFIED | Delegates a host Cron tick to `enqueue_due/2`; no Accrue-owned scheduler is started. |
| `accrue/lib/accrue/entitlements.ex` | Typed host-facing Apple surface | ✓ VERIFIED | Uses host configuration rather than caller-selected verifier/struct authority and exposes management/deferral outcomes. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Public Apple observation | `Apple.Admission` | opaque signed transaction + host-owned configuration | ✓ WIRED | `Entitlements.observe_apple_evidence/3` delegates only after validating public inputs. |
| `Apple.Admission` | `Intake.observe` | verified facts → internal evidence | ⚠️ PARTIAL | Correct for mapped products; the map guard prevents verified unmatched facts from reaching Intake's quarantine branch. |
| `Production` | OTP PKIX validation | pinned trust root/certificate policy | ✗ NOT_WIRED CORRECTLY | `pkix_path_validation` receives `[]`, not the declared `verification_time`; `configured_root([root \| _])` ignores further pinned roots. |
| Scheduled checkpoint | `ReconcileWorker` | lock + job insertion + durable state transition | ✓ WIRED | `enqueue_due/2` locks due idle checkpoints with `FOR UPDATE SKIP LOCKED`, inserts scalar jobs, then marks `running` in the same transaction. |
| Reconciliation worker | strict admission / canonical projector | status and ascending history | ⚠️ PARTIAL | Valid mapped data flows through `Reconciliation.Admission` to `Intake`; unmapped data stops at Admission and prevents completion. |
| Apple management | source registry | exact externally-managed outcome | ✓ WIRED | `Entitlements.apple_management/0` calls `SourceRegistry.outcome(:apple, :management)`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `Apple.Admission` | internal `VerifiedEvidence` | strict configured verifier + host product map | Yes for mapped evidence; verified unmapped evidence is discarded | ✗ HOLLOW FOR UNMATCHED INPUT |
| `Reconciliation` | status/history signed transactions | configured client → strict admission → Intake/Projector | Yes for mapped verified records; blocked on an unmapped record | ✗ PARTIAL |
| Apple management | `Source.Outcome` | static source declaration, not provider data | Yes—exact policy outcome | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Apple regression suite (including Plan 218-11 closure tests) | `mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` | 42 tests, 1 property, 0 failures | ✓ PASS |
| Compilation | `mix compile --warnings-as-errors` | Exit 0 | ✓ PASS |
| Certificate verification-time behavior | focused test enumeration/source inspection | No test; source demonstrably omits `verification_time` from the PKIX call | ✗ FAIL |
| Unmapped reconciliation does not retain a stale grant | focused test enumeration/source inspection | No integration test; source rejects at `Admission.evidence/6` and retries error | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — no Phase 218 probe scripts or probe declarations were found.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| AAPL-01 | 01, 04, 09, 11 | Opaque UUID, bind-once lineage, no automatic reassignment | ✓ SATISFIED | Opaque public boundary, row-locked lineage, private conflict outcomes, and repair tests. |
| AAPL-02 | 02, 03, 09, 11 | Verify signed Apple evidence including certificate time/trust | ✗ BLOCKED | Certificate purpose and identity are covered, but configured certificate-time validation is absent; only first configured root is considered. |
| AAPL-03 | 01, 04, 07, 11 | Convergent evidence and non-granting quarantine | ✗ BLOCKED | Mapped/concurrent cases pass; verified unmapped evidence cannot reach durable `:unmapped_product` quarantine and blocks reconciliation. |
| AAPL-04 | 05, 06, 10, 11 | Scheduled reconciliation and bounded lifecycle projection | ✗ BLOCKED | Scheduler/lifecycle/order tests pass, but both the unmatched admission and certificate-time defects prevent reliable historical self-repair. |
| AAPL-05 | 08 | Honest externally managed Apple support and deferrals | ✓ SATISFIED | Exact typed management guidance, explicit deferrals, and Stripe-isolation test pass. `REQUIREMENTS.md` remains unchecked for this ID despite implementation evidence. |

No requirement mapped to Phase 218 is orphaned from the phase-plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/apple/verifier/production.ex` | 149 | `verification_time` declared but not passed to PKIX validation | 🛑 BLOCKER | Valid delayed Apple evidence can be rejected solely because the host clock is later. |
| `accrue/lib/accrue/entitlements/apple/admission.ex` | 70 | Verified unmapped product returns error instead of terminal quarantine | 🛑 BLOCKER | Reconciliation can leave a prior grant stale and requires manual repair. |
| `accrue/lib/accrue/entitlements/apple/verifier/production.ex` | 134, 140 | `[root \| _]` silently ignores additional pinned roots | ⚠️ WARNING | A normal root rotation can reject chains under a valid later configured anchor. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in Phase 218 production and focused test files.

### Gaps Summary

The prior re-verification gaps are genuinely closed: active access is now expiry-bounded, the opaque repair regression runs, and a real certificate-purpose corpus is exercised. The phase goal is still not achieved. Certificate time is a required verification dimension but the configuration field is inert, and verified unmatched product evidence cannot reach the existing non-granting quarantine mechanism. Together these defects prevent the promised safe, self-repairing Apple snapshot path.

The review's two critical findings therefore remain material blockers. Its multi-root finding is retained as a warning rather than promoted to a separate goal blocker: it rejects valid evidence during root rotation but does not admit untrusted evidence.

---

_Verified: 2026-08-03T18:06:02Z_
_Verifier: the agent (gsd-verifier)_
