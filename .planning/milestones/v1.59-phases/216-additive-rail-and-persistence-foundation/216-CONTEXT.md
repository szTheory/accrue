# Phase 216: Additive rail and persistence foundation - Context

**Gathered:** 2026-08-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the configuration, qualified product catalog, schemas, migrations, and deterministic fixtures that let one host represent Stripe and Apple entitlement evidence concurrently. The foundation must preserve legacy single-processor behavior and durable identity while making every provider identifier explicitly rail- and environment-scoped.

This phase does not implement the canonical grant projector, snapshot cutover/backfill, purchase eligibility, resource-aware lifecycle dispatch, Apple verification/reconciliation runtime, offline proof issuance, or adopter-facing diagnostics assigned to Phases 217–220.

</domain>

<decisions>
## Implementation Decisions

### Rail Registration and Legacy Aliasing
- **D-01:** Keep `config :accrue, :processor` unchanged as the supported alias for the default controllable gateway rail. Add opt-in `rails` and `default_rail` configuration beside it; omitting both preserves legacy single-processor behavior.
- **D-02:** A configured `default_rail` must name a registered controllable gateway rail and must agree with the legacy `processor` alias. Reject contradictory or ambiguous configuration at boot rather than selecting a rail by list order.
- **D-03:** Stripe and Apple are the only production rails in v1.59; the existing deterministic host-fake source remains a test/proof facility, not a third production billing rail. Apple registration is an entitlement source/observer and must not be coerced into `Accrue.Processor`.

### Rail-Qualified Product Catalog
- **D-04:** Extend each existing logical plan with a nested rail/environment-qualified product mapping. Use the Phase-215 contract vocabulary (`:production`, `:sandbox`; `:offline` remains a decision-case/proof environment, not a provider product catalog environment). — **Reversibility:** costly — host configuration, installer examples, validation errors, fixtures, and later projection lookups will depend on this public catalog shape.
- **D-05:** Preserve `price_ids` as shorthand for the configured default rail and that rail's configured default environment. Bare identifiers never apply to every rail or environment.
- **D-06:** Uniqueness is enforced on the qualified tuple `{rail, environment, product_id}`. The same raw identifier may exist on different rails or environments, but one qualified tuple cannot map to two logical plans. A bare alias and a qualified entry that resolve to conflicting plans fail boot validation; repeats within one plan may normalize to one value.

### Durable Record Identity and Uniqueness
- **D-07:** Add separate UUID-backed entitlement account, grant, observation, and device records using `Accrue.Migration`, the configured billing prefix, UTC microsecond timestamps, database constraints/indexes, and matching changeset validation. Database constraints—not application prechecks alone—are the concurrency authority.
- **D-08:** An entitlement account is stable and unique per `(owner_type, owner_id)`. Its UUID is the future Apple `appAccountToken`; it is never derived from email or another mutable identifier. Start revision at zero, but Phase 217 owns projector writes and revision advancement.
- **D-09:** Grants are rail-, environment-, account-, lineage-, and product-qualified. Preserve observation history separately; enforce one current logical grant with a partial unique index over the deterministic current-row key rather than globally uniquing a provider lineage. Every external transaction/event identity is scoped by rail and environment.
- **D-10:** Observations are the durable quarantine/retry and provenance boundary, separate from existing gateway webhook rows. Enforce provider-event identity when present and transaction-plus-kind identity otherwise; duplicates are idempotent and cannot create duplicate durable observations.
- **D-11:** Foundation migrations are additive and forward-only: do not rewrite existing customers/subscriptions, create legacy-account backfills, or switch entitlement reads. Phase 217 owns backfill, parity/shadow mode, projector transactions, and cutover.

### Observation Evidence Retention
- **D-12:** Observation rows store normalized/redacted fields, bounded metadata, and an evidence digest. They never store raw receipts, JWS bodies, notification bodies, adopter identity, or PII in row-visible `data`.
- **D-13:** When later Apple verification or replay requires retained signed material, the row may hold only a nullable opaque reference to separately encrypted material plus an explicit expiry. The reference is non-diagnostic and non-telemetry data; Phase 216 does not invent a universal retention duration.

### Account-Scoped Device Identity
- **D-14:** Scope installation and key registration uniqueness to the entitlement account so one physical installation/key can be registered to another authenticated account. Future proofs remain bound to both account UUID and recomputed key thumbprint; account scoping does not weaken proof verification.
- **D-15:** Preserve device revocation/history rather than deleting rows to permit re-registration. Use partial uniqueness for current registrations so key rotation or account switching creates an auditable state transition without erasing the prior identity.

### Fake-First Proof and Propagation
- **D-16:** Ship deterministic Fake observer/record fixtures that cover both rails, both provider environments, collision rejection, duplicate observation idempotency, current-grant uniqueness, device account switching, and durable revocation. No live Stripe, Apple sandbox, Crosswake runtime, or physical-device evidence is required in this phase.
- **D-17:** Propagate the additive configuration and migrations through the installer, generated host migration path, examples, configuration validation, and compatibility tests in the same phase. A legacy host with only `processor` and `price_ids` must remain valid without new required keys or behavior changes.

### the agent's Discretion
The planner may choose exact internal modules, schema module names, constraint names, and whether the qualified catalog is represented internally as validated keywords, maps, or structs. It may also choose the opaque evidence-store behaviour name. These choices must preserve the public semantics above, the Phase-215 closed rail/environment vocabulary, the no-inline-raw-evidence rule, deterministic error reporting, and host-owned Repo/runtime-resource boundaries.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Scope and Precedence
- `.planning/PROJECT.md` — active v1.59 vision, compatibility/privacy guardrails, ownership boundaries, and deferrals.
- `.planning/ROADMAP.md` — authoritative Phase 216 boundary, dependencies, and success criteria; its current phase numbering supersedes older suggested numbering in research files.
- `.planning/REQUIREMENTS.md` — RAIL-01, RAIL-02, and RAIL-03 acceptance contract and milestone exclusions.
- `.planning/phases/215-research-contracts-and-crosswake-feasibility/215-CONTEXT.md` — locked source-contract, authority, decision-case, and feasibility decisions carried into this foundation.
- `.planning/research/v1.59-AUTHORITY.md` — first entry point and precedence order for all v1.59 research.
- `.planning/research/v1.59-AMENDMENTS.md` — active Stripe/Apple-only rail claim and dated reassessment rules.

### Foundation Architecture and Risk
- `.planning/research/v1.59-SUMMARY.md` — canonical synthesis; specifically the Phase 216 foundation implications and accepted compatibility tradeoffs.
- `.planning/research/v1.59-ARCHITECTURE.md` — additive config/catalog and persistence contract. Use its foundation sections, but follow the current ROADMAP for phase numbers and do not pull Phase-217 projection/cutover work into this phase.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — accepted account/rail boundary, compatibility path, identifier qualification, and privacy constraints.
- `.planning/research/v1.59-PITFALLS.md` — ownership, ordering, raw-evidence, privacy, and cross-rail mutation hazards.
- `.planning/entitlement-source-capability-matrix.md` — dedicated entitlement-source vocabulary; do not merge it into the processor matrix.
- `accrue/guides/architecture.md` — host-owned Repo/runtime resources and core projection conventions.

### Existing Executable Contracts
- `accrue/lib/accrue/entitlements/source/registry.ex` — Phase-215 processor-free source registry and Stripe/Apple/host-fake vocabulary.
- `accrue/lib/accrue/entitlements/decision_cases.ex` — closed rail/environment/case vocabulary and language-neutral contract source.
- `accrue/priv/entitlements/v1.59-decision-cases.json` — checked-in exported cases for cross-language and fixture parity.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Config`: one NimbleOptions boot-validation boundary already owns processor and entitlement-plan configuration, including duplicate `price_ids` rejection and actionable `Accrue.ConfigError` messages.
- `Accrue.Migration`: schema-qualified table/reference/index helpers preserve the host-selected billing prefix.
- `Accrue.Billing.Customer`: UUID identity, string owner identity, processor-qualified uniqueness, optimistic locking, and changeset/constraint patterns are direct precedents for entitlement accounts.
- `Accrue.Entitlements.Source.Registry` and `Accrue.Entitlements.DecisionCases`: Phase-215 executable vocabulary and deterministic Fake-first fixtures should be reused rather than redefined.

### Established Patterns
- Hosts own the Ecto Repo and migrations; Accrue owns its schema contract and generated migration content. `Accrue.Application` remains childless.
- Public configuration is additive, runtime-readable, boot-validated, and fails early on ambiguity. Existing `processor` remains a module rather than becoming a map.
- PostgreSQL constraints and scoped/partial indexes are the concurrency authority; changesets provide readable validation but do not replace database enforcement.
- Stripe `EntitlementSummary` remains observational-only and cannot seed grants, accounts, revisions, or entitlement decisions.

### Integration Points
- Extend `Accrue.Config` and its entitlement catalog validation without changing current LocalMap semantics.
- Add core schema modules and `Accrue.Migration`-qualified migrations, then propagate them through the install task and generated host migration tests.
- Keep new entitlement observations separate from `Accrue.Webhook.WebhookEvent`; later Apple ingestion will target the new boundary.
- Foundation fixtures feed Phase 217's projector and compatibility work, Phase 218's Apple observer, and Phase 219's device/offline proof without implementing those runtimes now.

</code_context>

<specifics>
## Specific Ideas

- Prefer one cohesive, idiomatic Elixir configuration: logical plans remain the outer catalog concept, with provider identities nested beneath them rather than split into disconnected provider catalogs.
- Error messages should name the logical plans and full conflicting qualified tuple so a host can repair configuration without guessing which rail/environment collided.
- The selected evidence model deliberately separates durable diagnostic truth from replayable sensitive material: rows stay safe to query, while optional encrypted payload retention remains opaque, expiring, and purpose-bound.
- The selected device model supports authenticated account switching without treating a physical installation as proof of account ownership.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 216. Projection/backfill/cutover remain Phase 217; Apple verification and repair remain Phase 218; offline proof issuance and device runtime remain Phase 219; adopter diagnostics and release proof remain Phase 220.

</deferred>

---

*Phase: 216-Additive rail and persistence foundation*
*Context gathered: 2026-08-02*
