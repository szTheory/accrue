# Phase 219: Offline study contract - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the server-owned and language-neutral contract that lets a registered device independently verify a compact, device-bound ES256 entitlement proof, preserve already-downloaded study and local progress under the accepted stale-offline policy, and converge safely through authenticated reconnect and atomic proof replacement.

This phase owns device registration and proof-of-possession, the versioned JWS/JWKS protocol, key-provider and rotation boundaries, issuance and verification, typed host outcomes, due-rail reconnect coordination, deny tombstones, public golden fixtures, and deterministic security/atomicity proof. It does not add Crosswake as an Accrue core runtime dependency, build the adopter-facing UI or full operator runbooks assigned to Phase 220, add Google Play, introduce arbitrary TTL/risk matrices, claim hardware attestation or DRM, or change existing boolean/scalar entitlement-gate return types.

</domain>

<decisions>
## Implementation Decisions

### Study Continuity and Host Policy
- **D-01:** Publish exactly four proof states: `fresh`, `stale_offline`, `denied`, and `invalid`. `reconnect_required` is a bounded next action derived from a state and attempted operation, not a fifth proof state. — **Reversibility:** one-way — OFF-04, Crosswake consumers, public fixtures, host pattern matches, support vocabulary, and later UI all depend on this closed state contract.
- **D-02:** `fresh` requires a valid device-bound allow proof whose signed temporal bounds and monotonic high-water checks pass and whose `fresh_until` has not been crossed. It permits the proof's normalized entitled plans, features, and quantities.
- **D-03:** `stale_offline` requires the same valid allow proof after `fresh_until` but before any explicit signed `exp`, with no newer accepted denial or superseding revision. It preserves already-downloaded lessons and local learner-progress reads/writes; new premium downloads, enrollment, export, purchase, account or rail mutation, and every other value-expanding action require reconnect.
- **D-04:** An explicit signed `exp` is a real protocol or known provider/access bound. Crossing it yields `invalid` with reason `hard_expired`; it is never calculated as `fresh_until + 72 hours` and there is no independent post-freshness grace cutoff. — **Reversibility:** costly — issuer calculations, client policy, security review, fixtures, and learner continuity behavior depend on the distinction between freshness and hard validity.
- **D-05:** `denied` requires a verified current signed deny tombstone and prevents reselection of an older positive proof. `invalid` means no usable authorization proof. Both preserve the app shell, downloaded local data, and unsynced progress, but fail closed for all entitlement-gated study and value expansion. Accrue does not delete host-owned local learner data.
- **D-06:** Reasons are a closed, bounded public taxonomy used to choose guidance without exposing backend machinery. The v1 proof reasons are `ok`, `revalidation_due`, `signed_denial`, `hard_expired`, `proof_unavailable`, `signature_invalid`, `unknown_key`, `wrong_algorithm`, `wrong_type`, `wrong_issuer`, `wrong_audience`, `device_mismatch`, `future_not_valid`, `clock_rollback`, `superseded`, `device_revoked`, and `malformed`. Provider, receipt, reconciliation-cursor, and cryptographic-library details remain internal.

### Published Proof and Verification API
- **D-07:** Add one small Phoenix-style public context, `Accrue.Entitlements.Offline`, for device registration, proof issuance, reconnect, pure verification support, and public verification-key rendering. Return tagged results and typed value objects; never expose Ecto device/grant/observation rows, JOSE structs, provider evidence, reducers, signing secrets, or worker state. — **Reversibility:** costly — host integrations and HexDocs will depend on this additive facade, though exact function arities may be refined during planning.
- **D-08:** Existing `entitled?/2`, `has_active_plan?/2`, `features_for/1`, and entitlement-quantity gates retain their current boolean/scalar, fail-closed server semantics. Offline decisions are additive and action-policy-facing; connectivity and a client proof never become inputs to existing server gates.
- **D-09:** Publish a versioned compact ES256 JWS profile. The protected header fixes `alg: "ES256"`, `typ: "accrue-entitlement-proof+jwt"`, and `kid`. The payload contains protocol version, issuer, exact audience, token ID, opaque account subject, a confirmation object carrying the recomputed P-256 JWK thumbprint, account revision, `iat`, `nbf`, `fresh_until`, explicit `exp`, `allow` or `deny` disposition, normalized plans/features/quantities, and bounded denial metadata when applicable. — **Reversibility:** one-way — claim names, type, normalization, and validation rules become a cross-language wire contract consumed by published fixtures and mobile clients.
- **D-10:** Publish a cacheable JWKS containing only public P-256 verification keys with distinct stable `kid` values and verification/signing-use metadata. Accrue provides a pure JWKS renderer and may provide an optional Plug; the authenticated host chooses and mounts the public route. A fixed embedded key is fixture/bootstrap material, not the production rotation contract.
- **D-11:** Keep signing behind a host-implementable key-provider behaviour. Private JWKs never enter the billing database, public JWKS, logs, telemetry, diagnostics, or production fixtures. Apple App Store credentials and offline-signing keys remain separate domains. Normal rotation publishes the new public key before switching issuance and retains prior verification keys until no actually issued proof can remain valid plus documented skew/reconnect buffer.
- **D-12:** Verification is allowlist-based and fail-closed: select only a configured or cached key by `kid`; reject token-directed `jku`, `x5u`, or similar key fetches; require the fixed algorithm/type/version/issuer/audience; validate signature, key curve/use, claim types and sizes, time bounds, exact account/device binding, recomputed RFC-7638-style thumbprint, disposition, and monotonic ordering; reject duplicate security-sensitive JSON members and unknown critical behavior.
- **D-13:** Publish synthetic, language-neutral, versioned golden fixtures with production-shaped public JWKS, compact proofs, expected decoded claims, expected four-state decision, bounded reason, and cache disposition. Merge-block valid allow and deny plus wrong algorithm/key/type/issuer/audience/account/device, unknown `kid`, malformed/duplicate claims, time skew, hard expiry, stale-at-30-days, no-72-hour-cutoff, rollback, older revision/issuance, deny precedence, key rotation, and crash-before/after-replacement cases. Keep the private test key explicitly test-only.
- **D-14:** Proofs, fixtures, issuance metadata, telemetry, and diagnostics contain no adopter identity, email, profile data, raw receipt/JWS, Apple transaction or notification identity, Stripe payload, raw device private key, or provider body. Device binding limits copying; documentation must not claim DRM, remote revocation of a disconnected device, or hardware attestation.

### Authenticated Reconnect and Atomic Replacement
- **D-15:** Use an authenticated hybrid reconnect coordinator backed by existing durable per-rail repair. The host authenticates the account; the device submits its installation ID, one-time server nonce, device-key proof-of-possession, and an idempotency key. Client high-water values are comparison hints only and a returned client proof is never provider or billing truth.
- **D-16:** Refresh every source that is due under an explicit source schedule; do not refresh a healthy non-due rail merely because the app foregrounded. Reuse the source registry, Apple reconciliation checkpoints, durable wakeups, backoff, rate budgets, and host-owned Oban runtime. Reconnect may wait only for bounded inline work; longer or retryable work continues durably.
- **D-17:** Issue no positive proof while any required due source is retrying, quarantined, rate-limited, unavailable, or otherwise unresolved. Return a typed bounded `pending` reconnect outcome with reason, `retry_after`, and next action, queue or coalesce repair, and retain the prior verified client cache. Do not create a partial-result allow policy in v1.59.
- **D-18:** Once due sources converge, one database transaction locks and rereads the entitlement account and device, reads the committed canonical snapshot/revision, rechecks device state, records privacy-safe issuance metadata and high-water state, and produces either a fresh allow proof or a signed deny tombstone. Provider work need not be one transaction; the final authorization read and issuance state must be atomic.
- **D-19:** A locally authoritative revoked device may receive a device-bound deny tombstone after authenticated proof-of-possession without waiting for unrelated provider refresh. Otherwise, absence of effective entitlement becomes signed denial only after all required due source state is resolved.
- **D-20:** The client verifies the returned JWS before durable compare-and-replace. Cache ordering considers revision, denial precedence, issuance time, and freshness horizon: a verified same-revision revalidation may extend freshness; deny wins at equal revision; no lower revision or older issuance may replace newer accepted state. A crash before replacement preserves the previous complete proof; there is never a partially visible candidate.
- **D-21:** Database locks and constraints are correctness authority. Oban uniqueness and reconnect idempotency coalesce duplicate work but are not authorization or execution locks. Retryable work uses bounded exponential backoff, jitter, provider `Retry-After`, durable attempts, and an explicit terminal `needs_repair` outcome rather than disappearing.
- **D-22:** Emit allowlisted telemetry and diagnostics for action, rail/environment, reconnect disposition/reason, proof state, revision delta, key/config version, due-source count, latency, queue age, retry count, and bounded correlation. Never emit compact proof bytes, private/public key material, account tokens, raw provider evidence, notification bodies, or PII. Alertable conditions include due-source backlog, repeated pending reconnects, key-rotation mismatch, and stale-device population.

### Learner, Host, and Operator Experience
- **D-23:** The learner-facing model states the job and next action, not proof or provider internals. Preferred stale restriction copy is: “Reconnect to update access. Downloaded lessons and progress stay available on this device.” Invalid guidance uses “Reconnect to check access”; signed denial states that access is unavailable and preserves local data rather than promising reconnect will restore it.
- **D-24:** Phase 219 defines typed values, guidance keys, and copy seeds only. Phase 220 or the host renders conventional accessible controls with text-backed state, literal action labels, keyboard/focus correctness, reduced-motion support, and light/dark/system compatibility under the current brandbook. No color alone may communicate fresh, stale, denied, invalid, or pending.

### the agent's Discretion
The planner may choose exact internal module/file names, final function arities, struct field layout, reason atom spelling where not explicitly locked, JWKS Plug name, signing/audit record name, reconnect-attempt persistence shape, source due intervals, bounded inline timeout, backoff/page budgets, telemetry event names, and key-retirement buffer. These choices must preserve the closed four-state contract, published ES256/JWKS semantics, existing gate compatibility, host-owned runtime resources, no-partial-allow rule, database correctness boundaries, privacy limits, deterministic cross-language fixtures, and atomic client replacement.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, Requirements, and Locked Dependencies
- `.planning/PROJECT.md` — active v1.59 adopter need, 30-day/no-72-hour policy, compatibility/privacy guardrails, host ownership, and deferrals.
- `.planning/ROADMAP.md` — authoritative Phase 219 goal, dependencies, success criteria, and boundary.
- `.planning/REQUIREMENTS.md` — OFF-01 through OFF-06 acceptance contract and milestone exclusions.
- `.planning/phases/215-research-contracts-and-crosswake-feasibility/215-CONTEXT.md` — locked Crosswake tracer, proof-of-possession, secure storage, high-water, atomic replacement, source-capability, and feasibility contracts.
- `.planning/phases/216-additive-rail-and-persistence-foundation/216-CONTEXT.md` — locked account/device identity, durable revocation/history, privacy, and host-owned persistence decisions.
- `.planning/phases/217-canonical-projection-and-compatibility/217-CONTEXT.md` — locked snapshot/revision/projector semantics and existing gate compatibility.
- `.planning/phases/218-apple-observation-and-repair/218-CONTEXT.md` — established due-rail reconciliation, checkpoint, retry, provider-honesty, and Apple-to-Stripe isolation patterns; Phase 219 depends on the source contract, not Apple-specific client state.

### v1.59 Authority, Protocol, and Risk
- `.planning/research/v1.59-AUTHORITY.md` — current research precedence and history-preserving supersession rules.
- `.planning/research/v1.59-AMENDMENTS.md` — active no-72-hour and Stripe/Apple-only claims plus dated reassessment contract.
- `.planning/research/v1.59-SUMMARY.md` — canonical offline-policy synthesis, build order, accepted tradeoffs, and explicit rejected alternatives.
- `.planning/research/v1.59-STACK.md` — ES256 claims, verifier, key-provider/JWKS, rotation, fixture, and deterministic test guidance.
- `.planning/research/v1.59-ARCHITECTURE.md` — issue/reconnect paths, four-state reconciliation correction, revision/tombstone behavior, and package ownership.
- `.planning/research/v1.59-DECISION-TABLE.md` — continuity, rollback, deny, repair, and atomic decision cases.
- `.planning/research/v1.59-PITFALLS.md` — algorithm/type/audience, replay/copy, clock, key compromise, privacy, and operational hazards.
- `.planning/research/v1.59-SOURCES.md` — primary-source provenance for current protocol and provider claims.
- `.planning/research/v1.59-WATCHLIST.md` — provider, crypto, dependency, policy, privacy, and security change triggers.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — accepted account/rail/offline boundary, stale-study policy, reconnect contract, and v1-versus-later scope.
- `.planning/entitlement-source-capability-matrix.md` — closed source capability/outcome vocabulary and due-reconciliation ownership.

### Ecosystem, JTBD, DX, and Voice Inputs
- `prompts/original-billing-ecosystem-deep-research.md` — Pay, Laravel Cashier, dj-stripe, and cross-framework lessons: small native facades, provider honesty, and avoiding provider-schema leakage.
- `prompts/accrue-best-practices-deep-research-independent.md` — developer, support, SRE, operator, security, reconciliation, idempotency, and safe-action JTBD.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — three-world mental model, persona needs, exception-first outcomes, and consumer-facing domain language.
- `brandbook/voice.md` — current measured, exact, native, and durable voice authority; supersedes older prompt wording.
- `brandbook/copy.md` — current mechanism-plus-next-action error, empty, and success copy patterns.

### Existing Executable Contracts
- `accrue/lib/accrue/entitlements.ex` — existing Phoenix-style facade and boolean/scalar compatibility boundary.
- `accrue/lib/accrue/entitlements/device.ex` — account-scoped installation/key identity, lifecycle, last accepted revision, and durable revocation/supersession foundation.
- `accrue/lib/accrue/entitlements/snapshot.ex` — deterministic canonical plans/features/quantities and effective authorization bounds.
- `accrue/lib/accrue/entitlements/projector.ex` — sole transactional grant/revision writer and monotonic ordering authority.
- `accrue/lib/accrue/entitlements/decision_cases.ex` — stable continuity, repair, atomicity, and privacy-safe reason vocabulary.
- `accrue/priv/entitlements/v1.59-decision-cases.json` — language-neutral canonical decision cases.
- `accrue/priv/entitlements/v1.59-offline-golden-vectors.json` — current compact-JWS corpus to evolve into the production-shaped public protocol fixture.
- `accrue/test/support/entitlements/offline_golden_vector_verifier.ex` — current strict ES256/binding/high-water/atomic-cache verifier seed; test-only and not yet the public runtime API.
- `accrue/test/accrue/entitlements/offline_golden_vectors_test.exs` — current merge-blocking mutation-sensitive fixture contract.
- `accrue/lib/accrue/entitlements/source.ex` — closed source capability/outcome boundary used to determine due repair.
- `accrue/lib/accrue/entitlements/source/registry.ex` — configured rail capabilities and provider-honest source vocabulary.
- `accrue/lib/accrue/entitlements/apple/reconciliation.ex` — durable checkpoint, due scheduling, row-lock, pagination, retry, and final convergence patterns to reuse.
- `accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex` — transactional wakeup/outbox and coalescing pattern.
- `accrue/lib/accrue/repo.ex` — host-owned Repo transaction and guarded-write seam.
- `accrue/guides/architecture.md` — host-owned supervision/runtime resources and public-context conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Entitlements.Device`: already carries account-scoped installation/key identity, lifecycle, and a revision high-water field; Phase 219 should extend its semantics rather than add a parallel device registry.
- `Accrue.Entitlements.Snapshot` and `Projector`: provide the committed authorization set, known bounds, monotonic revision, and sole-writer transaction the issuer must reread.
- `DecisionCases`, the checked-in offline vectors, and `OfflineGoldenVectorVerifier`: provide deterministic valid/deny/wrong-key/wrong-device/rollback/fault seeds, but their current test-only claim names and fixed key must be reconciled to the published v1 profile.
- Apple `Reconciliation` and `ReconciliationWakeup`: already implement due timestamps, durable wakeups, row-lock claiming, bounded retry, `Retry-After`, final cursor commit, and host-owned Oban integration.
- `Source.Registry`, telemetry spans, audit/event conventions, Fake-first adapters, and `Repo.transact` supply the established extension idiom.

### Established Patterns
- Public host APIs live in small Phoenix-style context modules returning tagged typed results; schemas, reducers, cryptographic adapters, provider clients, and worker state remain private.
- Hosts own Repo, Oban supervision/cron, Finch, routes, authentication, authorization, secret storage, mobile secure storage, and UI rendering; `Accrue.Application` remains childless.
- Database constraints, row locks, and one transactional writer provide correctness. Oban uniqueness and idempotency reduce duplicate work but are never the authorization lock.
- Provider notifications are wakeups, not current truth. Due reconciliation obtains authoritative source state before projecting; raw client proof and provider payloads never become grants.
- Existing entitlement gates are stable fail-closed server APIs. Offline policy is a separate additive consumer boundary.

### Integration Points
- Add `Accrue.Entitlements.Offline` beside the existing `Accrue.Entitlements` facade and connect it to `Account`, `Device`, `Snapshot`, `Projector`, `Source.Registry`, Repo, and telemetry without widening provider-specific modules.
- Extend device registration with validated P-256 public-key/thumbprint semantics and proof-of-possession while preserving account scoping and lifecycle history.
- Add issuer/verifier/key-provider/JWKS internals behind the public context and replace the test-only fixture profile with a versioned public corpus plus independent consumers.
- Build reconnect over the source due-state and existing repair queues, then perform the final account/device/snapshot reread and issuance bookkeeping under one transaction.
- Feed typed states, bounded reasons, next actions, and copy seeds to the Phase-220 reference host and diagnostics without implementing those surfaces here.

</code_context>

<specifics>
## Specific Ideas

- Prefer one closed four-state decision plus bounded reason and next-action fields over multiple booleans or a fifth UI-action state.
- Prefer one purpose-specific compact JWS profile and public JWKS over a generic JWT API or fixed embedded production key.
- Prefer a hybrid reconnect that is synchronous only when every due source can converge within a bounded request and otherwise returns durable pending; never trade correctness for a partial-result allow.
- Apply the strongest ecosystem lessons together: Pay/Laravel Cashier's small native facade, dj-stripe's warning against mirroring provider internals, RevenueCat/Stripe's notification-as-wakeup and idempotent repair model, and Phoenix/Ecto/Oban ownership conventions.
- Design pillars applied together: correctness, security, privacy, additive compatibility, resilience, concurrency safety, predictable performance, observability, accessibility of rendered outcomes, maintainability, deterministic testability, documentation truth, supportability, and developer ergonomics.

</specifics>

<deferred>
## Deferred Ideas

None added during discussion. Existing deferrals remain: arbitrary TTL/device-risk matrices, hardware attestation and DRM claims, Google Play, Family Sharing, offer authoring, cross-rail migration/proration, adopter-facing UI, full operator runbooks, and physical-device/Crosswake release evidence beyond the already-defined feasibility boundary.

</deferred>

---

*Phase: 219-Offline study contract*
*Context gathered: 2026-08-03*
