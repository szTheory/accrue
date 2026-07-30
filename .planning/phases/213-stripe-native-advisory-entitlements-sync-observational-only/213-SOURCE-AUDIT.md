# Phase 213 — Multi-Source Coverage Audit

| Source | ID | Feature / constraint | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | — | Opt-in client-backed advisory refresh with grant isolation proof | 01–03 | COVERED | Tracer, real adapter/worker, and static/runtime isolation form the complete goal path. |
| REQ | SYNC-01 | Complete client-backed pull into EntitlementSummary | 01, 02 | COVERED | Fake tracer proves write; Stripe adapter drains the real stream. |
| REQ | SYNC-02 | Off by default and observational-only | 01, 03 | COVERED | Early no-I/O branch plus contradictory-cache grant invariance. |
| REQ | SYNC-03 | Isolation guard covers new surface and has a red path | 03 | COVERED | New tokens plus hermetic violation fixtures. |
| REQ | SYNC-04 | Resolve fetch_entitled/2 ambiguity | 03 | COVERED | Closed/will-not-build in moduledoc and guide with verifier. |
| REQ | SYNC-05 | Fake/Test-only deterministic proofs | 01–03 | COVERED | Fake refresh, worker, ordering, and grant-isolation tests; no live Stripe/Chrome. |
| RESEARCH | — | Processor facade; raw LatticeStripe only in stripe.ex | 01, 02 | COVERED | Optional facade contract and isolated real adapter. |
| RESEARCH | — | Shared off-gate reconciler with D-11 ordering proof | 01 | COVERED | Fail-first ordering cases precede final conflict guard. |
| RESEARCH | — | Config-off before Processor/Repo I/O | 01 | COVERED | Tracer explicitly asserts call count and missing row. |
| RESEARCH | — | Existing queue thin worker | 02 | COVERED | JSON-safe customer id and no scheduler/new queue. |
| RESEARCH | — | Extend isolation guard with negative fixture | 03 | COVERED | Both new symbols receive red-path fixtures. |
| CONTEXT | D-01 | Optional complete-list Processor callback | 01 | COVERED | Cited in task action and must-have. |
| CONTEXT | D-02 | Callback remains optional | 01 | COVERED | Cited in task action. |
| CONTEXT | D-03 | LatticeStripe boundary and exhaustive stream | 02 | COVERED | Cited in adapter task. |
| CONTEXT | D-04 | Fake entitlement state and seed helper | 01 | COVERED | Cited in tracer task. |
| CONTEXT | D-05 | Public StripeSync.refresh/2 contract | 01 | COVERED | Cited in tracer task. |
| CONTEXT | D-06 | Disabled early no-I/O return | 01 | COVERED | Cited and tested in tracer. |
| CONTEXT | D-07 | Thin worker on existing queue | 02 | COVERED | Cited in worker task. |
| CONTEXT | D-08 | No top-level Accrue delegate | 01, 02 | COVERED | Explicit task exclusion. |
| CONTEXT | D-09 | Existing span/event with pull source | 01 | COVERED | Cited in tracer task. |
| CONTEXT | D-10 | Scope includes primitive/worker, excludes UI/scheduler/facade | 01, 02 | COVERED | Explicit task boundaries. |
| CONTEXT | D-11 | Summary reconstruction, watermark carry-forward, concurrency | 01 | COVERED | Dedicated TDD ordering task with costly reversibility rating. |
| CONTEXT | D-12 | One shared writer | 01 | COVERED | `Accrue.Entitlements.Reconcile`. |
| CONTEXT | D-13 | JSON provenance, no migration | 01 | COVERED | Cited in tracer task. |
| CONTEXT | D-14 | Close/reject fetch_entitled/2 | 03 | COVERED | Cited in closure task. |
| CONTEXT | D-15 | Guard new symbols plus negative proof | 03 | COVERED | Cited in guard task. |

Excluded without gap: D-10's admin refresh button, scheduled poll-all reconcile, top-level facade delegate, and webhook-side truncated-summary pagination; Phase 214 docs reconciliation; Feature catalog authoring.

All five descriptor-less edge-probe rows are surfaced as `flagged_assumptions` in the plans. Bespoke surviving must-NOT items are under `must_haves.prohibitions`; routine engineering and canonical security/privacy items were not minted.
