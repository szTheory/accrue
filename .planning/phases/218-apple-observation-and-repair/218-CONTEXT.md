# Phase 218: Apple observation and repair - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Accept Apple purchase, restore, and App Store Server Notifications V2 evidence; verify it before it can become authority; bind verified Apple lineage to one entitlement account; quarantine invalid, unbound, and conflicting evidence without heuristic ownership; and reconcile current status plus transaction history into the existing canonical account snapshot.

This phase owns Apple verification, lineage claims, bounded ingest, quarantine/retry, status/history repair, normalized Apple lifecycle facts, and host-facing Apple observation/repair outcomes. It does not add Family Sharing policy, offer authoring, ownership transfer, Apple-shaped billing subscriptions, Apple-to-Stripe mutations, offline proof issuance, Crosswake runtime integration, or adopter-facing admin/portal implementation.

</domain>

<decisions>
## Implementation Decisions

### Lineage Linking and Repair
- **D-01:** Add a durable Apple lineage-claim boundary ahead of account-scoped observations. Its authority key is `{rail: :apple, environment, original_transaction_id}` and it carries an optional immutable account binding, binding/repair state, privacy-bounded verified-token correlation, and ordering high-water data. Do not force verified-but-unbound evidence into an arbitrary account merely because the existing `Observation` requires `account_id`. — **Reversibility:** costly — ownership constraints, repair APIs, observation admission, fixtures, and later diagnostics will depend on this identity boundary.
- **D-02:** A verified `appAccountToken` equal to the authenticated entitlement-account UUID may atomically claim an unbound lineage once. The transaction locks the lineage, rechecks ownership, binds it, inserts the qualified account observation idempotently, projects it through the existing projector, and records audit/outbox work. PostgreSQL uniqueness and locking are the concurrency authority; an Elixir check followed by an insert is insufficient.
- **D-03:** Missing or unusable verified tokens produce a non-granting `verified_unbound` outcome. A lineage already bound to another account produces a privacy-safe `ownership_conflict` quarantine. Neither path may fall back to email, device, product, receipt order, delivery order, client claims, or the restoring session as ownership evidence. Never disclose the owning account and never automatically transfer, merge, refund, cancel, migrate, or prorate.
- **D-04:** Explicit repair is available only for a verified, currently unbound lineage. Accrue owns the transactional bind, re-verification/refetch, bounded reason, actor audit, and idempotent reconciliation mechanism; the host supplies authenticated authorization policy. Apple `Set App Account Token`, if used, is a follow-up provider repair operation rather than ownership authority. A bound conflict remains quarantined for a future separately approved transfer policy.

### Verification, Quarantine, and Evidence Retention
- **D-05:** Hide Apple crypto and provider-library details behind a narrow verifier behaviour with deterministic Fake and strict production adapters. First evaluate `app_store_server_library ~> 2.2` behind that boundary against Apple/captured fixtures, hostile-chain tests, API-shape checks, independent verification, supervision, privacy, and dependency gates. Admit it as a private adapter only if every gate passes; otherwise use a narrow Accrue-owned Finch plus JOSE/`:public_key` adapter. Dependency structs and JOSE details are never public API.
- **D-06:** Verification is non-bypassable and allowlist-based: require `ES256`; validate every outer and nested JWS independently; validate the ordered `x5c` chain to configured Apple roots, certificate time and purpose, signature, bundle ID, expected environment, and production `appAppleId`; reject unexpected critical/header behavior. Apple App Store credentials and trust configuration remain separate from Accrue offline-proof signing keys.
- **D-07:** Use four semantic disposition classes across ingest and repair: fully verified evidence may be normalized and projected; duplicate or stale verified evidence is a successful no-op; provider/network/rate-limit/online-check or temporarily unavailable repair failures are retryable; malformed, cryptographically invalid, wrong-app, wrong-environment, unsupported-family, unmapped, and ownership-conflicting evidence is non-granting quarantine. Exact public reason atoms are closed and stable, with a bounded `next_action`; terminal evidence is never retried blindly, and retry exhaustion becomes durable `needs_repair` rather than disappearing in Oban.
- **D-08:** Preserve only normalized facts, evidence digest, bounded correlation, verifier/config version, disposition/reason, attempts, and timestamps in queryable storage. Raw JWS, receipts, tokens, notification bodies, adopter identity, and PII never enter rows, metadata, logs, telemetry, exceptions, Oban args, or UI. Optional replay material lives behind the existing opaque encrypted evidence reference with a purpose-specific expiry and deletion contract.
- **D-09:** The notification endpoint acknowledges only after a bounded result is durably recorded. A terminal verification failure may be acknowledged after bounded quarantine to prevent a provider retry storm; transient persistence/provider failures remain unsuccessful so Apple can retry. Enforce request-size and rate limits so malformed internet traffic cannot turn quarantine into unbounded storage.

### Notification, Status, and History Convergence
- **D-10:** Use a hybrid convergence model. A verified App Store Server Notification V2 is an idempotent durable wakeup, not current entitlement truth. `Get All Subscription Statuses` is the present-state authority for auto-renewable subscriptions; ascending `Get Transaction History` supplies ordered history, revocation/refund/product-transition evidence, and repair. `Get Notification History` diagnoses delivery gaps and seeds bounded outage recovery, but never grants or retracts directly. — **Reversibility:** costly — repair checkpoints, worker semantics, fixtures, and support explanations will rely on this division of authority.
- **D-11:** Persist a reconciliation checkpoint per rail/environment/lineage with the initial query fingerprint, opaque revision, run state, page count/budget, attempts, last success, and next due time. Reuse identical filters on every page, upsert each verified transaction idempotently because an updated transaction may reappear, and commit the final revision only after an ascending scan reaches `hasMore: false`. A crash or 429/5xx before completion resumes without advancing the durable cursor.
- **D-12:** Notification receipt, authenticated purchase/restore completion, stale reconciliation age, near access bounds, retryable quarantine, cursor corruption, and notification-outage recovery all coalesce a lineage reconciliation job. Host-owned Oban supplies scheduled work, bounded concurrency, jittered exponential backoff, `Retry-After` handling, and per-app rate budgets. Oban uniqueness reduces duplicate insertion but is not a concurrency lock; database identities and projector/account locking remain correctness authority.
- **D-13:** During an Apple outage, retain only the last verified effective grant and never extend it beyond its known provider bound. Invalid or ambiguous evidence never widens access. Authentication/configuration failures alert and require repair rather than consuming retry attempts forever.

### Apple Lifecycle Normalization
- **D-14:** Normalize Apple lifecycle into rail-neutral source facts and effective bounds; do not widen `Billing.Subscription` or Stripe enums. Active grants through verified expiry. Billing grace grants only through the verified `gracePeriodExpiresDate`. Billing retry does not invent access after the last valid provider bound. Expiry, refund, and revocation retract only the affected Apple source at their verified bounds; renewal disabled preserves access until the actual bound; authoritative refund-reversal/current evidence may restore the Apple source.
- **D-15:** The existing `Projector` remains the sole writer of grants and account revisions. It receives only account-bound, fully verified, normalized observations and must compare a complete monotonic Apple ordering tuple within rail/environment/lineage/product so delayed positive evidence cannot overwrite a later revocation, refund, or product transition. Apple evidence never enters gateway subscription reducers.
- **D-16:** Apple remains externally managed. Reuse the existing source-capability result and exact guidance: “Manage this subscription in Apple.” with action label “Manage subscription.” Negative tests must prove Apple observation, repair, reconciliation, and management paths cannot reach Stripe cancellation, retry, swap, proration, refund, invoice, payment-method, or dunning code.

### Host API, DX, and Human-Facing Outcomes
- **D-17:** Expose Apple work through a small Phoenix-style `Accrue.Entitlements` context surface: purchase context/token retrieval, signed-evidence observation, lineage repair, and explicit reconciliation. Return tagged results with typed value objects containing stable disposition, bounded reason, next action, and snapshot/revision only when applicable. Do not expose Ecto lineage rows, Apple transaction IDs, cursors, raw payloads, provider-library values, or bang APIs for externally managed/repair outcomes. — **Reversibility:** costly — host integrations, support tooling, docs, and fixtures will pattern-match these result semantics.
- **D-18:** Consumer and operator language describes the job, result, and next safe action rather than backend machinery. Customer conflict copy is: “We couldn’t link this Apple purchase to this account. Contact support to review the purchase.” It must not reveal that another account owns the lineage. Operator outcomes distinguish “verified but no account token,” “ownership conflict,” “verification failed,” “Apple unavailable,” and “reconciliation stalled,” with literal actions such as “Retry reconciliation” or “Review ownership.”
- **D-19:** Emit allowlisted telemetry for verifier/config version, disposition/reason, rail/environment, lineage state, projection result/revision delta, reconciliation lag/pages/retries, queue age, and provider response class. Use internal or hashed correlations only. Diagnostics answer: what was verified, whether it is linked, whether access changed, whether repair is pending, and the next safe action.
- **D-20:** Merge-block with Apple and independent golden fixtures for wrong algorithm/root/certificate purpose/time/bundle/environment/app ID, nested-JWS failure, unbound and conflicting claim races, duplicate/out-of-order evidence, delayed positive after refund/revocation, grace/retry/expiry/refund/revocation bounds, 20+ history pages, changed filters, crash-before-cursor-commit, 429/5xx/outage, sandbox/production isolation, raw-data redaction, and zero Apple-to-Stripe lifecycle calls. Provider/sandbox fidelity complements but does not replace deterministic Fake-first proof.

### the agent's Discretion
The planner may choose exact module, struct, context-function, worker, telemetry-event, table, constraint, and reason-atom names; the bounded reconciliation cadence/backoff/page budget; and evidence-reference expiry by purpose. It may admit the community Apple server library only after the locked adapter gates pass. These choices must preserve the bind-once ownership boundary, closed outcome semantics, strict verification, final-page cursor commit, host-owned runtime resources, public API insulation, and provider-isolation proofs above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, Requirements, and Locked Prior Decisions
- `.planning/PROJECT.md` — active v1.59 vision, adopter justification, ownership/privacy guardrails, and explicit deferrals.
- `.planning/ROADMAP.md` — authoritative Phase 218 boundary, dependencies, goal, and success criteria.
- `.planning/REQUIREMENTS.md` — AAPL-01 through AAPL-05 acceptance contract and milestone exclusions.
- `.planning/phases/215-research-contracts-and-crosswake-feasibility/215-CONTEXT.md` — locked authority, decision-case, source-capability, verification, and feasibility contracts.
- `.planning/phases/216-additive-rail-and-persistence-foundation/216-CONTEXT.md` — locked account/observation/grant identity, qualified catalog, privacy, and evidence-reference decisions.
- `.planning/phases/217-canonical-projection-and-compatibility/217-CONTEXT.md` — locked projector, snapshot, cross-rail eligibility, provider-honest management, and Apple-to-Stripe isolation contracts.

### v1.59 Apple Authority and Risk
- `.planning/research/v1.59-AUTHORITY.md` — current research precedence and supersession rules.
- `.planning/research/v1.59-AMENDMENTS.md` — active Stripe/Apple-only claim and dated reassessment contract.
- `.planning/research/v1.59-SUMMARY.md` — canonical Apple observer/repair synthesis and accepted dependency gate.
- `.planning/research/v1.59-ARCHITECTURE.md` — Apple verification/linking/reconciliation boundaries, record shape, package ownership, and projector integration.
- `.planning/research/v1.59-DECISION-TABLE.md` — duplicate, ordering, survivor, repair, revocation, and ownership cases.
- `.planning/research/v1.59-PITFALLS.md` — JWS, ownership, notification-order, cursor, privacy, and cross-rail failure modes.
- `.planning/research/v1.59-SOURCES.md` — primary-source provenance for Apple and ecosystem claims.
- `.planning/research/v1.59-STACK.md` — Apple dependency admission, crypto, HTTP, test-corpus, and operations constraints.
- `.planning/research/v1.59-WATCHLIST.md` — Apple API/library/policy/security change triggers and owning responses.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — accepted account/rail architecture, token-only ownership, repair, and offline dependencies.
- `.planning/entitlement-source-capability-matrix.md` — closed source capabilities and Apple externally-managed contract.

### Ecosystem, JTBD, DX, and Voice Inputs
- `prompts/original-billing-ecosystem-deep-research.md` — Pay, Laravel Cashier, dj-stripe, and framework-integrated billing-library lessons; use as comparative input, not current Apple authority.
- `prompts/accrue-best-practices-deep-research-independent.md` — support, SRE, operator, developer, reconciliation, replay, and safe-action JTBD.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — consumer/support-flow and diagnostic-surface context; Phase 218 defines values, not UI.
- `brandbook/voice.md` — current measured, exact, Elixir/Phoenix-native, durable voice authority; supersedes older prompt wording.
- `brandbook/copy.md` — mechanism-led error, guidance, and literal action-copy patterns.

### Existing Executable Contracts
- `accrue/lib/accrue/entitlements/account.ex` — stable entitlement-account UUID used as `appAccountToken`.
- `accrue/lib/accrue/entitlements/observation.ex` — current account-required, privacy-bounded evidence and idempotency boundary to extend rather than bypass.
- `accrue/lib/accrue/entitlements/grant.ex` — rail/environment/lineage/product-qualified grant history and current-row identity.
- `accrue/lib/accrue/entitlements/projector.ex` — sole transactional grant/revision writer and current ordering/retraction semantics.
- `accrue/lib/accrue/entitlements/snapshot.ex` — canonical rail-neutral authorization and source-summary contract.
- `accrue/lib/accrue/entitlements/purchase_decision.ex` — revision-bound Apple purchase preflight and conflict diagnostics.
- `accrue/lib/accrue/entitlements/source/registry.ex` — existing Apple observation/restore/reconciliation capabilities and management guidance.
- `accrue/lib/accrue/entitlements/decision_cases.ex` — stable cross-rail outcome/reason cases to extend with Apple repair fixtures.
- `accrue/test/support/entitlements/fixtures.ex` — deterministic rail/environment fixture idiom.
- `accrue/guides/architecture.md` — host-owned Repo/Oban/runtime resources and public-context conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Entitlements.Account`, `Grant`, `Observation`, `Snapshot`, and `Projector`: the durable account, qualified evidence, sole-writer, and revision contracts are already present; Apple work should add admission/linking/repair ahead of them rather than build a second entitlement system.
- `Accrue.Entitlements.Source.Registry`: already publishes Apple observation, restore, reconciliation, and externally-managed management outcomes with exact guidance.
- `Accrue.Entitlements.PurchaseDecision`: already blocks equivalent cross-rail purchases and records concurrent Apple completion as a diagnostic conflict.
- Existing Oban, `Repo.transact`, row-lock, partial-unique-index, Fake-first, property-test, audit-event, and bounded-telemetry patterns supply the implementation idiom.

### Established Patterns
- Public APIs are small Phoenix-style context functions returning tagged typed results; internal schemas, reducers, jobs, and provider adapters stay private.
- Hosts own Repo, Oban supervision/scheduling, authentication, authorization, Finch, credentials, and rendering; `Accrue.Application` stays childless.
- Database identities and locks are correctness authority. Oban uniqueness is insertion deduplication, not execution serialization.
- Raw provider evidence is never queryable application state; durable normalized observations and grants are the local truth derived from verified provider evidence.
- Provider notifications are asynchronous signals. Projection order and account revisions derive from verified provider order/effective bounds, never receipt order.

### Integration Points
- Add Apple verifier/client behaviours, lineage claims, reconciliation checkpoints, and context functions beside the existing `Accrue.Entitlements` facade.
- Extend observation admission so only verified, account-bound Apple facts enter the existing projector; keep verified-unbound and quarantined facts durable outside the account-required observation shape.
- Use transactional outbox/Oban work after durable ingest and binding; schedule due repair through host-owned runtime configuration.
- Extend decision-case JSON/ExUnit/property fixtures and provider-honesty guards with Apple-specific verification, linking, history, and isolation cases.

</code_context>

<specifics>
## Specific Ideas

- The recommended design combines three layers with one direction of authority: verifier → lineage/linking/reconciliation → qualified observation/projector. No layer may skip forward or write grants directly.
- Follow Pay and Laravel Cashier's small framework-native facade lesson, but keep provider capabilities explicit. Follow RevenueCat's quick idempotent notification plus authoritative synchronization lesson, but reject transfer-friendly identity policy. Follow dj-stripe's warning against mirroring an evolving provider schema: normalize access facts and retain bounded evidence rather than model every Apple field.
- User-facing outcomes should hide backend state-machine nouns. A customer needs to know whether the purchase linked and the next action; support needs the bounded reason and safe repair; SRE needs verification/reconciliation health; developers need typed outcomes and deterministic fixtures.
- Design pillars applied together: correctness, security, privacy, compatibility, resilience, concurrency safety, performance/rate control, observability, maintainability, testability, documentation truth, accessibility of later rendering, supportability, and developer ergonomics.

</specifics>

<deferred>
## Deferred Ideas

- Automatic Apple ownership transfer, merge, or reassignment — future policy phase only after explicit product/security/finance approval.
- Family Sharing ownership semantics — deferred by POL-01.
- Introductory, promotional, and offer-eligibility authoring — deferred by POL-02.
- Adopter-facing admin/portal implementation and full repair runbooks — Phase 220 consumes the typed values defined here.
- Offline proof issuance and Crosswake runtime integration — Phase 219.

</deferred>

---

*Phase: 218-Apple observation and repair*
*Context gathered: 2026-08-03*
