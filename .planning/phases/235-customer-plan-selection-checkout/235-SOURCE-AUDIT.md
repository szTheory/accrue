# Phase 235 Source Coverage Audit

Every in-scope item from the roadmap goal, four requirements, research, context decisions, UI contract, and spec-less edge probe has a plan. Deferred ideas and other phases' work are excluded by source scope.

| Source | Item | Coverage | Status |
|---|---|---|---|
| GOAL | Understand selected offer, complete supported checkout, or leave with honest outcome | 235-01 through 235-04 | COVERED |
| REQ | CKO-01 visible secure form, completion, invalid/provider failure/cancel/retry | 235-01, 235-03, 235-04 | COVERED |
| REQ | CKO-02 distinct hosted/mounted handoff and safe return | 235-01, 235-04 | COVERED |
| REQ | CKO-03 two transports, expiry/completion/stale promo/replay, honest charge and price | 235-02, 235-03 | COVERED |
| REQ | CKO-04 exact selection through sign-in/return, trusted terms and recovery | 235-02, 235-03, 235-04 | COVERED |
| RESEARCH | Host-owned plan label/amount/currency/interval persisted in existing session | 235-02 | COVERED |
| RESEARCH | Raw price ID and missing amount displayed as free | 235-02 | COVERED |
| RESEARCH | POST versus LiveView eligibility and outcome drift | 235-03 | COVERED |
| RESEARCH | Provider success before local completion persistence failure | 235-03 | COVERED |
| RESEARCH | Concurrency, duplicate submission and single-use nonce | 235-01, 235-03 | COVERED |
| RESEARCH | Braintree official iframe SDK and real visible form transport | 235-01 | COVERED |
| RESEARCH | Stripe hosted versus Braintree mounted; return is navigation | 235-04 | COVERED |
| RESEARCH | Portal package CSS/JS served by host, browser/CI proof | 235-04 | COVERED |
| CONTEXT | D-01 trusted selected terms | 235-02 | COVERED |
| CONTEXT | D-02 missing/ambiguous term recovery | 235-02 | COVERED |
| CONTEXT | D-03 selection/payer/processor and fresh authorization | 235-02, 235-03 | COVERED |
| CONTEXT | D-04 processor split, official SDK, no Fake parity | 235-01, 235-04 | COVERED |
| CONTEXT | D-05 safe return and evidence-only completion | 235-04 | COVERED |
| CONTEXT | D-06 fresh session/auth and outcome taxonomy | 235-01, 235-03 | COVERED |
| CONTEXT | D-07 no blind replay, clear nonce, fresh retry | 235-01, 235-03 | COVERED |
| CONTEXT | D-08 deterministic automation, recurring CI, UAT evidence | 235-01 through 235-04 | COVERED |
| UI | All 16 resolved state rows; 320 CSS px and 400% zoom | 235-01 through 235-04, particularly 235-04 Task 2 | COVERED |
| EDGE | CKO-01 idempotency/concurrency | 235-01, 235-03 | COVERED |
| EDGE | CKO-02 idempotency/concurrency | 235-04 | COVERED |
| EDGE | CKO-03 boundary/precision/idempotency/concurrency | 235-02, 235-03 | COVERED; numeric upper bound flagged in 235-02 |
| EDGE | CKO-04 boundary/empty/encoding/precision/idempotency/concurrency | 235-02 | COVERED; numeric upper bound flagged in 235-02 |

## Scope exclusions

- Deferred context ideas, generic plan catalog, new processor, new pricing policy, account-selection model, custom card entry, Phase 236 Portal self-service, and Phase 239 cross-surface closeout are outside this phase.
- The assumption-delta `alongside` signal is a no-change coverage-sequencing statement; see 235-01.
- The installed API coverage detector returned `detected:false` on the roadmap plus all four plan bodies. This phase refines existing integration paths and adds no external API surface, so no API matrix is required by the gate.
