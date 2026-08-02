# Phase 217: Canonical projection and compatibility - Context

**Gathered:** 2026-08-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Project rail- and environment-qualified entitlement grants into one revisioned, host-readable account snapshot; make purchase eligibility and billing lifecycle decisions from that canonical state; and provide an opt-in, parity-checked path from the existing single-processor resolver without changing legacy billing behavior.

This phase owns the transactional projector, material-revision rules, snapshot contract, cross-rail purchase preflight and override contract, resource-aware gateway dispatch, legacy backfill/shadow/cutover, and their compatibility proofs. It does not implement Apple evidence verification, StoreKit restore or reconciliation, offline proof issuance, Crosswake runtime integration, adopter-facing admin/portal UI, automatic rail migration, refund/transfer/proration policy, or Google Play.

</domain>

<decisions>
## Implementation Decisions

### Revisioned Account Snapshot
- **D-01:** Add a read-only, rail-neutral account snapshot as the canonical multi-rail decision object. Its semantic fields are an opaque account ID, monotonic revision, deduplicated logical plans, unioned features, maximum effective quantity per quota, and privacy-safe source summaries containing rail, environment, normalized state/effective bounds, and redacted correlation only. Public collections must be deterministic. — **Reversibility:** costly — hosts, later offline proofs, purchase decisions, diagnostics, and fixtures will depend on this value contract.
- **D-02:** Snapshot reads are pure: they never provision an account, call a provider, reconcile evidence, or write state. They accept an entitlement account or host-authenticated billable reference; explicit account provisioning remains a separate authenticated operation. Existing boolean/scalar gates keep their return shapes.
- **D-03:** One projector is the sole writer of effective grants and account revisions. In one database transaction it locks the account, rejects duplicate/stale/out-of-order evidence, writes or supersedes only the affected rail/environment/lineage grants, compares the effective before/after snapshot, increments revision at most once, records the audit event, and arranges transactional follow-up work.
- **D-04:** Revision advances only when the effective authorization signature changes: plans, features, quantities, or known effective/revocation/expiry bounds. Metadata enrichment, diagnostics, duplicates, quarantined or unmapped evidence, and other no-op observations do not advance revision. A source retraction cannot remove equivalent access still supplied by another live source. — **Reversibility:** costly — monotonic clients, offline proof issuance, audit interpretation, and repair logic will rely on this meaning of revision.
- **D-05:** Grants and immutable observations remain the durable truth. Do not introduce a separately authoritative denormalized snapshot reducer or reconstruct authorization by replaying provider delivery order. A cache may be considered later only after measured need and must never become a second decision system. Stripe `Billing.EntitlementSummary` remains advisory-only and cannot seed accounts, grants, revisions, snapshots, eligibility, or gates.

### Cross-Rail Purchase Eligibility
- **D-06:** Expose a typed, rail-neutral purchase decision with closed statuses `eligible`, `block`, and `warn`; stable reason codes; target rail and logical plan; source summary; and the snapshot revision used. Do not reduce this boundary to a boolean. — **Reversibility:** costly — host purchase flows, support guidance, telemetry, and cross-language fixtures will pattern-match this vocabulary.
- **D-07:** Equivalent means exactly that a live effective grant on a different rail maps through the qualified catalog to the same logical plan. Never infer equivalence from bare provider IDs, feature overlap, price, quantity, gateway customer rows, email, or device identity.
- **D-08:** An equivalent second-rail purchase blocks by default. Missing, stale, repairing, or ambiguous canonical state also blocks with an actionable reason instead of failing open. First-purchase flows explicitly provision/fetch the authenticated entitlement account before eligibility evaluation.
- **D-09:** Override is an explicit, revision-bound host action that records a bounded reason, privacy-safe actor reference, target rail/plan, equivalent source set, decision revision, and outcome. The purchase path must recheck current revision and equivalence before continuing; a changed revision is re-evaluated rather than trusted. Override changes the decision to an explicit warning and never cancels, transfers, refunds, migrates, merges, or prorates another rail.
- **D-10:** Server-controlled Stripe purchase commands use a durable intent/operation identifier for provider idempotency and reconcile ambiguous provider outcomes before retrying. Apple uses the same preflight before the host starts StoreKit, but a concurrent Apple completion is observed as a diagnostic conflict rather than treated as authority for cross-rail mutation. Phase 217 does not add a reservation subsystem.

### Legacy Backfill, Shadow, and Cutover
- **D-11:** Lock an explicit three-state compatibility contract: `disabled` keeps the existing `LocalMap` lane authoritative; `shadow` backfills and compares canonical results without changing gates; `enabled` makes canonical snapshots authoritative only for approved accounts or host-defined cohorts. Omitting multi-rail configuration preserves legacy behavior. — **Reversibility:** costly — configuration, deployment choreography, tests, and adopter runbooks will depend on these mode semantics.
- **D-12:** Backfill creates one stable entitlement account per billable identity and derives only mapped, entitling Stripe subscription state into grants. It is deterministic, chunked, resumable, and idempotent by account/current-grant identity; it never rewrites subscriptions, customers, provider resources, or advisory summaries.
- **D-13:** Parity compares normalized entitlement meaning rather than internal representation. Enablement requires a defined clean shadow window, no unresolved unmapped products or projection ambiguity, and passing resource-scoping/advisory-isolation proofs. Mismatches have stable, privacy-safe reason IDs and remain visible blockers rather than silently falling back.
- **D-14:** Rollback changes only gate authority back to `LocalMap`. It preserves accounts, grants, observations, revisions, and ongoing repair; it never deletes canonical evidence or mutates gateway subscriptions. Reject per-request automatic fallback because authorization authority must be deterministic and projection defects must remain visible.

### Provider-Honest Lifecycle Dispatch
- **D-15:** Persisted resource provenance is the authority for gateway lifecycle actions. Existing `Accrue.Billing` cancellation, period-end cancellation, resume, pause/unpause, swap, quantity/item, preview, and bang facades retain their signatures for `%Billing.Subscription{}` and resolve the gateway adapter from the resource's persisted processor. They never use current global processor configuration or a caller-supplied rail for an existing resource. — **Reversibility:** costly — every gateway mutation path and compatibility test must share this dispatch invariant.
- **D-16:** The configured default processor/rail remains valid for legacy resource creation and deterministic `customer/1`; it is not authority for an already-persisted resource. Resource lookup and host authorization occur before adapter resolution, and ambiguous/unscoped provider identifiers fail closed.
- **D-17:** Apple grants never become Stripe-shaped billing subscriptions and never enter gateway mutation functions. Add one rail-neutral management/capability query over a persisted resource. Apple management returns a successful, actionable `externally_managed` outcome with stable guidance key, exact text, literal action label, and Apple management URL. Do not provide a bang mutation that converts this guidance into an exception.
- **D-18:** Unknown resources/rails, unavailable capabilities, wrong resource types, and authorization failures return typed errors with stable codes and next actions. Externally managed remains distinct from unavailable, deferred, host-owned, and feasibility-blocked. Negative tests must prove Apple paths cannot reach cancellation, retry, swap, proration, refund, invoice, payment-method, or dunning adapters.
- **D-19:** Gateway mutations retain existing idempotency, transaction, audit, error, and bang/non-bang conventions. Snapshot, projector, eligibility, cutover, and lifecycle telemetry use bounded fields such as revision, action, rail/environment, disposition, reason, cohort/mode, and internal or hashed identifiers; they never contain email, raw receipts/JWS, Apple account tokens, provider payloads, or adopter identity.

### Host and User Experience
- **D-20:** This phase adds no UI, but its values must support consumer/JTBD-first rendering. Hosts see logical plans, access decisions, responsible rail, exact reason, and next safe action—not reducer, observation, cursor, or provider-transport internals.
- **D-21:** Use the current brandbook voice for guidance and errors: measured, exact, Elixir/Phoenix-native, and durable. Outcomes are text-backed rather than color-only. A later UI must use conventional accessible controls, literal link/action labels, keyboard/focus correctness, reduced-motion and light/dark/system compatibility, and no destructive affordance for externally managed resources.
- **D-22:** Preferred Apple warning copy is: “This account already has Pro through Apple. Continuing creates another subscription.” Preferred management guidance is: “Manage this subscription in Apple.” with action label “Manage subscription.” Exact plan/source substitutions may be generated from bounded public labels.

### the agent's Discretion
The planner may choose exact module, function, struct, transaction-helper, outbox, task, telemetry-event, and typed-error names; whether deterministic snapshot collections use sorted lists or another serialization-safe representation; how host cohorts are expressed; backfill chunk size and retry cadence; and whether the management query is named `management/2`, `lifecycle_outcome/2`, or an equivalent idiomatic context function. Those choices must preserve the locked semantics, closed outcomes/reasons, legacy signatures, transaction and provenance boundaries, and negative cross-rail isolation proofs above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, Requirements, and Prior Decisions
- `.planning/PROJECT.md` — active v1.59 vision, stable-core posture, ownership boundaries, privacy guardrails, and deferrals.
- `.planning/ROADMAP.md` — authoritative Phase 217 goal, dependencies, success criteria, and phase boundaries.
- `.planning/REQUIREMENTS.md` — ACCT-01 through ACCT-05 acceptance contract.
- `.planning/phases/215-research-contracts-and-crosswake-feasibility/215-CONTEXT.md` — locked decision-case, source-capability, authority, and feasibility contracts.
- `.planning/phases/216-additive-rail-and-persistence-foundation/216-CONTEXT.md` — locked rails/catalog, durable record, evidence-retention, device, and legacy-alias decisions.

### v1.59 Architecture and Risk Authority
- `.planning/research/v1.59-AUTHORITY.md` — current research precedence and supersession rules.
- `.planning/research/v1.59-AMENDMENTS.md` — active Stripe/Apple-only claim and reassessment contract.
- `.planning/research/v1.59-SUMMARY.md` — canonical account-projection, provider-honesty, compatibility, and accepted-tradeoff synthesis.
- `.planning/research/v1.59-ARCHITECTURE.md` — projector transaction, snapshot/read boundary, resource-aware dispatch, cutover, and package ownership guidance; follow current roadmap phase numbering.
- `.planning/research/v1.59-DECISION-TABLE.md` — survivor, duplicate, ordering, eligibility, revision, and repair cases.
- `.planning/research/v1.59-PITFALLS.md` — cross-rail mutation, ordering, revision, privacy, App Review, and operational hazards.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — accepted account/rail architecture, identifier, compatibility, and offline dependencies.
- `.planning/entitlement-source-capability-matrix.md` — closed source capability/outcome vocabulary and Apple externally-managed contract.
- `.planning/processor-support-matrix.md` — separate gateway-control capability authority; do not infer entitlement-source behavior from it.

### Ecosystem, JTBD, and Voice Inputs
- `prompts/original-billing-ecosystem-deep-research.md` — lessons from Pay, Laravel Cashier, dj-stripe, and successful billing-library facade/domain patterns; historical research input, not current scope authority.
- `prompts/accrue-best-practices-deep-research-independent.md` — developer, support, finance, and operator JTBD plus reconciliation and safe-action principles.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — consumer and support-flow context for later diagnostics rendering; Phase 217 defines values only.
- `brandbook/voice.md` — current voice authority; supersedes older brand wording under `prompts/`.
- `brandbook/copy.md` — current mechanism-led error, guidance, and action-copy patterns.

### Existing Public and Executable Contracts
- `accrue/lib/accrue/entitlements.ex` — existing fail-closed boolean/scalar gate facade and compatibility shapes.
- `accrue/lib/accrue/entitlements/resolver.ex` — configured resolver seam and current resolved-state vocabulary.
- `accrue/lib/accrue/entitlements/resolver/local_map.ex` — legacy entitlement authority and parity source.
- `accrue/lib/accrue/entitlements/account.ex` — stable account identity and revision foundation.
- `accrue/lib/accrue/entitlements/grant.ex` — rail/environment/account/lineage-qualified current grant model.
- `accrue/lib/accrue/entitlements/observation.ex` — durable evidence, idempotency, and quarantine boundary.
- `accrue/lib/accrue/entitlements/decision_cases.ex` — stable decision/reason cases consumed by projector and eligibility proofs.
- `accrue/priv/entitlements/v1.59-decision-cases.json` — language-neutral parity and cross-client fixtures.
- `accrue/lib/accrue/entitlements/source.ex` — closed entitlement-source capability/state contract.
- `accrue/lib/accrue/entitlements/source/registry.ex` — current Apple/Stripe/host-fake outcomes and guidance.
- `accrue/lib/accrue/billing.ex` — existing Phoenix-style billing context and lifecycle facade signatures.
- `accrue/lib/accrue/billing/subscription.ex` — persisted processor provenance and lifecycle predicates.
- `accrue/lib/accrue/billing/subscription_actions.ex` — current lifecycle mutations, idempotency, transaction/audit patterns, and global-dispatch sites to remediate.
- `accrue/guides/architecture.md` — host-owned Repo/runtime resources, context boundaries, and projection conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Entitlements.Account`, `Grant`, and `Observation`: Phase 216 already supplies the stable UUID, revision field, qualified current-grant identity, history, ordering, and provenance records the projector needs.
- `Accrue.Entitlements.Resolver` and `LocalMap`: preserve the resolver seam and use LocalMap as the legacy semantic parity source; do not duplicate its public gate facade.
- `Accrue.Entitlements.DecisionCases`: already contains duplicate, stale, survivor, atomic-transaction, ambiguous-eligibility, and all-grants-revoked cases with stable reason vocabulary.
- `Accrue.Entitlements.Source.Registry` and `Outcome`: reuse the closed capability states and actionable Apple guidance rather than inventing a second lifecycle vocabulary.
- Existing `Ecto.Multi`/`Repo.transact`, idempotency, event-recording, telemetry-span, Fake-first, and property-test patterns provide the proof idiom for projection and lifecycle work.

### Established Patterns
- Public APIs live in Phoenix-style context modules, use tagged results plus intentional bang variants, and hide internal reducer/schema mechanics from host callers.
- Host apps own Repo, Oban, supervision, authentication, account membership, rendering, and provider credentials; `Accrue.Application` stays childless.
- PostgreSQL constraints and scoped/partial indexes are the concurrency authority; application validation and row locking complement rather than replace them.
- Billing resources already persist processor provenance, but several lifecycle implementations still call global `Processor.__impl__/0`; Phase 217 must close those paths before enabling multi-rail behavior.
- Advisory Stripe entitlement summaries remain isolated from grants and gates by existing merge-blocking tests.

### Integration Points
- Add the snapshot/projector and purchase-decision boundaries beside the existing `Accrue.Entitlements` facade, preserving legacy gate signatures.
- Connect the projector to Phase 216 account/grant/observation records and Phase 215 decision-case fixtures; later Apple and offline phases consume only the resulting canonical contract.
- Extend configuration with the explicit cutover modes without changing the existing `processor`, default-rail, or `price_ids` compatibility aliases.
- Route existing gateway mutation paths through a registry keyed by persisted resource processor; keep new-resource creation on the explicit/default gateway rail.
- Feed privacy-safe decisions and stable reasons to later admin/portal/reference-host surfaces without implementing those surfaces in this phase.

</code_context>

<specifics>
## Specific Ideas

- Favor one typed snapshot and one typed purchase decision over maps of provider-specific booleans. A Phoenix developer should be able to pattern-match the outcome without learning projector internals.
- Preserve the ergonomic lesson from Pay and Laravel Cashier—small bounded facades—while avoiding the footgun of treating one default provider abstraction as universal lifecycle truth.
- Use logical-plan equivalence for duplicate-purchase protection, following product-independent entitlement systems, but keep provider lifecycle operations explicitly rail-owned.
- Optimize diagnostics for “Does this account have access, why, through which rail, at what revision, and what is the next safe action?” rather than exposing raw evidence or backend state machines.
- Design pillars applied together: correctness, compatibility, security, privacy, resilience, performance, observability, accessibility of rendered outcomes, maintainability, testability, documentation truth, and developer ergonomics.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 217. Apple verification/restore/reconciliation remain Phase 218; offline proof and reconnect remain Phase 219; adopter-facing UI, runbooks, and release proof remain Phase 220; Google Play remains SEED-007.

</deferred>

---

*Phase: 217-Canonical projection and compatibility*
*Context gathered: 2026-08-02*
