# Phase 218 Multi-Source Coverage Audit

| SOURCE | ID | Feature/Requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Verified Apple evidence contributes safely and self-repairs without reassignment or provider-lifecycle confusion | 01-08 | COVERED | Tracer proves admission; later plans close verification, ingress, repair, convergence, and isolation. |
| REQ | AAPL-01 | Opaque UUID purchase/restore and bind-once lineage | 01, 04 | COVERED | Serialized lineage claim plus explicit unbound-only repair. |
| REQ | AAPL-02 | Strict Notifications V2 and nested evidence verification | 02, 03 | COVERED | Package legitimacy gate precedes the private production adapter and hostile corpus. |
| REQ | AAPL-03 | Idempotent convergence and repairable quarantine | 01, 04, 07 | COVERED | Durable intake, notification acknowledgement, closed dispositions, and permutation/race proof. |
| REQ | AAPL-04 | Scheduled status/history reconciliation and lifecycle bounds | 05, 06 | COVERED | Final-page checkpoint plus source-local lifecycle ordering. |
| REQ | AAPL-05 | Honest Apple management with Family Sharing/offer deferrals | 08 | COVERED | Existing exact guidance and negative Stripe reachability gate. |
| RESEARCH | — | Verifier -> lineage/intake -> qualified Observation/Projector authority direction | 01, 03, 04, 06, 07 | COVERED | No Apple module writes grants; initial claim and repair call the Projector in-transaction seam. |
| RESEARCH | — | Candidate `app_store_server_library ~> 2.2` evaluated behind private seam with complete fallback | 02, 03 | COVERED | Rejection uses direct Jason plus OTP `:public_key`, including compact JWS/x5c/ES256 normalization, without dependency changes. |
| RESEARCH | — | Bounded notification acknowledgement, request size, and rate control | 07 | COVERED | Terminal durable results acknowledge; transient durability/provider failures do not. |
| RESEARCH | — | Hybrid status/history/notification-history convergence | 05 | COVERED | Current state, ordered history, and delivery diagnostics remain distinct. |
| RESEARCH | — | Durable final-page cursor, retry exhaustion, outage bounds | 05 | COVERED | Checkpoint persists pending/completed revisions and `needs_repair`. |
| RESEARCH | — | Complete Apple ordering tuple and rail-neutral lifecycle normalization | 06 | COVERED | Projector stays sole writer; Stripe enums remain unchanged. |
| RESEARCH | — | Fake-first/property/golden/privacy/isolation validation | 01, 03-08 | COVERED | Validation map names every focused suite. |
| CONTEXT | D-01 | Durable pre-observation lineage boundary | 01, 04 | COVERED | Costly decision cited in task actions. |
| CONTEXT | D-02 | Transactional verified-token claim and projection | 01, 04 | COVERED | `Projector.project_in_transaction/3` keeps bind, Observation, grant/revision, audits, Projector follow-up, and reconciliation wakeup in one rollback-tested transaction. |
| CONTEXT | D-03 | Unbound/conflict fail closed without heuristics | 01, 04 | COVERED | No owner disclosure or reassignment. |
| CONTEXT | D-04 | Authenticated explicit repair only for unbound lineage | 04 | COVERED | Bound conflicts stay quarantined. |
| CONTEXT | D-05 | Private candidate-library admission and fallback | 02, 03 | COVERED | Package gate plus executable Jason/OTP fallback with byte-unchanged dependency rejection path. |
| CONTEXT | D-06 | ES256/x5c/app/environment strict verification | 03 | COVERED | Outer and nested hostile corpus. |
| CONTEXT | D-07 | Four closed disposition classes | 01, 03, 04 | COVERED | Stable reasons and bounded next actions. |
| CONTEXT | D-08 | Bounded facts only; opaque expiring replay reference | 01, 03, 04 | COVERED | Privacy-negative tests cover rows/jobs/telemetry/inspect. |
| CONTEXT | D-09 | Durable notification acknowledgement and admission limits | 07 | COVERED | Plug contract and deterministic rate/size tests. |
| CONTEXT | D-10 | Hybrid convergence authority | 05 | COVERED | Costly decision cited in task action. |
| CONTEXT | D-11 | Immutable filter fingerprint and final-page cursor commit | 05 | COVERED | 20+ pages/crash/changed-filter tests. |
| CONTEXT | D-12 | Coalesced host-owned Oban repair | 05 | COVERED | Scalar args, bounded concurrency/backoff/rate budget. |
| CONTEXT | D-13 | Outage never widens last verified provider bound | 05, 06 | COVERED | Retry/config failures remain visible and non-granting. |
| CONTEXT | D-14 | Rail-neutral Apple lifecycle bounds | 06 | COVERED | Active/grace/retry/expiry/refund/revocation cases. |
| CONTEXT | D-15 | Existing Projector sole writer and complete ordering | 01, 06 | COVERED | Qualified observations only. |
| CONTEXT | D-16 | Exact external-management guidance and Stripe isolation | 08 | COVERED | Negative callback inventory. |
| CONTEXT | D-17 | Small typed Entitlements context surface | 01, 04, 08 | COVERED | Purchase context, observe, repair, reconcile. |
| CONTEXT | D-18 | Exact safe customer/operator language | 04, 08 | COVERED | Conflict does not expose owner. |
| CONTEXT | D-19 | Allowlisted telemetry and actionable diagnostics | 03-08 | COVERED | Hashed/internal correlations only. |
| CONTEXT | D-20 | Exhaustive hostile/race/order/paging/outage/redaction/isolation proof | 03-08 | COVERED | Every named case has a focused test task. |

Deferred context items are intentionally excluded: automatic transfer/merge/reassignment, Family Sharing, offer authoring, admin/portal/runbooks, offline proof/Crosswake runtime. No source item is missing.
