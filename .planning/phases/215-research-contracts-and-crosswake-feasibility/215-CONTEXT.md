# Phase 215: Research, contracts, and Crosswake feasibility - Context

**Gathered:** 2026-07-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish one current, versioned, evidence-backed v1.59 authority bundle; freeze the evidence-to-entitlement and entitlement-source contracts; audit the gateway/source boundary; and check in a Crosswake tracer that either proves every required client capability or explicitly blocks later mobile runtime coupling. This phase defines contracts and feasibility evidence. It does not implement the multi-rail persistence, projection, Apple runtime, offline issuance runtime, or adopter release proof assigned to Phases 216–220.

</domain>

<decisions>
## Implementation Decisions

### Research Authority and Supersession
- **D-01:** Add a human-readable `v1.59-AUTHORITY.md` manifest as the first v1.59 entry from `RESEARCH-INDEX.md`. It defines the bundle, active policy, precedence, review state, and effective date; it does not duplicate every research document.
- **D-02:** Use this precedence: current `PROJECT.md`/`STRATEGY.md`/`ROADMAP.md`/`REQUIREMENTS.md` scope guards; accepted v1.59 authority amendments; `v1.59-SUMMARY.md` and the decision-table contract; source provenance; specialist v1.59 research; then generic research and prompts as historical context.
- **D-03:** Record material claims in an amendment/supersession ledger with a stable claim ID, active wording, disposition, confidence, source IDs, effective date, superseded locations, rationale, and downstream phases/tests. Seed an explicit claim that supersedes every independent 72-hour cutoff formulation. Watchlist or dependency changes open a dated reassessment; they never silently change entitlement behavior.
- **D-04:** Keep source material and rejected alternatives rather than rewriting history. Reject both “latest prose edit wins” and an ADR/RFC per routine provider finding; reserve standalone ADRs/RFCs for broad, stable public-contract decisions.

### Decision-Table Contract
- **D-05:** Author the decision cases once as a versioned, data-only Elixir contract and deterministically render the maintainer-facing Markdown table plus a checked-in, language-neutral JSON fixture corpus. — **Reversibility:** costly — reducers, ExUnit cases, Crosswake vectors, documentation, and support reason IDs will all depend on the case schema.
- **D-06:** The contract is proof/policy data, not production decision logic and not a public runtime API. Production reducers consume production domain types; exhaustive ExUnit consumers prove every named case. Keep the renderer/exporter deliberately simple so it cannot become a second reducer.
- **D-07:** Each case has a stable ID and contract version plus rail/environment-qualified evidence, prior source state, ordering tuple, expected source disposition, effective snapshot and revision delta, purchase eligibility, lease/continuity outcome, repair result, and a privacy-safe support reason.
- **D-08:** Add permutation, duplicate, out-of-order, survivor-source, concurrency, and transaction-boundary properties around the named cases. Later projection work must commit source grants, effective snapshot/revision, and audit event atomically; support and diagnostics name the same stable case/reason vocabulary.

### Crosswake Feasibility Tracer
- **D-09:** Use a checked-in minimal iOS reference target with a narrow host-owned `AccrueOfflineClient`-style adapter, compiled against a pinned Crosswake shell/core. Do not add Crosswake as an Accrue runtime dependency and do not invent undocumented bridge APIs.
- **D-10:** The tracer must prove all of RAIL-05 plus authenticated host transport: StoreKit 2 purchase with the account UUID as `appAccountToken`; transaction update and restore/current-entitlement handling; non-exported Secure Enclave P-256 device key with public-key/thumbprint registration and nonce proof; Keychain `ThisDeviceOnly` secure state; durable local state; monotonic `iat`/revision/freshness high-water checks; verified atomic allow/deny replacement; foreground/background and reconnect recovery. Device evidence is submitted to the server and never grants locally by itself.
- **D-11:** Merge-block JSON/JWS golden vectors, server contract tests, Swift compile/unit tests, rollback/older-revision/wrong-key/wrong-device/deny-precedence tests, and crash/fault-injected atomicity tests. Simulator StoreKit/Keychain runs are useful but advisory. A dated physical-device proof is required for Secure Enclave behavior, Keychain migration exclusion, lifecycle recovery, atomic replacement after termination, and authenticated Crosswake shell transport.
- **D-12:** Any missing native transport, StoreKit bridge, device-key, secure-state atomicity, high-water, or lifecycle/reconnect proof blocks later mobile runtime coupling. Protocol vectors and server-side offline work may continue, but the project must report `feasibility_blocked` rather than relabel partial proof as runtime feasibility.
- **D-13:** `scenePhase` and network-path changes may coalesce an authenticated reconciliation attempt; reachability is never entitlement authority. Only a verified, server-issued newer allow or signed denial can atomically replace cached state.

### Entitlement-Source Capability Contract
- **D-14:** Add a small `Accrue.Entitlements.Source` behaviour/registry with closed capability and outcome value objects. Keep it separate from `Accrue.Processor`: the processor boundary controls gateway resources, while the source boundary observes, restores, reconciles, manages, and supplies entitlement evidence. Do not use a protocol for configured registry data or expose a loose public nested map.
- **D-15:** Use consumer/JTBD dimensions `observation`, `control`, `restore`, `reconciliation`, `management`, and `offline`. Use the closed state vocabulary `supported`, `externally_managed`, `host_owned`, `deferred`, `unavailable`, and `feasibility_blocked`; do not collapse these into booleans. — **Reversibility:** costly — hosts, HexDocs, portal/admin rendering, conformance tests, and support guidance will pattern-match the published vocabulary.
- **D-16:** Externally managed is a successful, actionable outcome rather than an error. For example, Apple management returns an `externally_managed` result with a stable guidance key and management URL; an actually unavailable operation returns a typed capability error naming source, capability, code, and next action. Apple capability results must never dispatch into Stripe cancellation, dunning, retry, swap, proration, invoice, or payment-method mutations.
- **D-17:** The runtime contract is authoritative for host inspection; the entitlement-source matrix and HexDocs mirror its public subset. Add source conformance fixtures, code-to-doc literal drift gates, and negative gateway-leakage tests. UI consumers render plain-language guidance with text and action labels—not color-only status or backend vocabulary—and follow the current `brandbook/` voice authority: measured, exact, native, and durable.

### the agent's Discretion
The planner may choose exact internal module/file names, the Mix task name for deterministic rendering, and whether the authority ledger is a section or adjacent amendment file. These choices must preserve the locked properties above: one discoverable authority entry point, stable claim/case IDs, a non-public/non-runtime decision-case source, language-neutral exported vectors, and a closed public source-capability vocabulary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and Active Authority
- `.planning/PROJECT.md` — v1.59 vision, adopter justification, ownership boundaries, offline policy, and deferrals.
- `.planning/STRATEGY.md` — stable-core and strategic-expansion guardrails.
- `.planning/ROADMAP.md` — current Phase 215 boundary, dependencies, and success criteria; it supersedes older phase numbering in research inputs.
- `.planning/REQUIREMENTS.md` — RSCH-01..03 and RAIL-04..05 acceptance contract.
- `.planning/research/RESEARCH-INDEX.md` — current bundle discovery and historical-versus-current reading order.
- `.planning/research/v1.59-SUMMARY.md` — canonical v1.59 decisions, tradeoffs, supersession, confidence, and remaining gates.

### Evidence, Policy, and Feasibility
- `.planning/research/v1.59-SOURCES.md` — deduplicated primary-source provenance and authority classification.
- `.planning/research/v1.59-DECISION-TABLE.md` — current human-readable normalization, eligibility, repair, and continuity cases to migrate into the versioned contract.
- `.planning/research/v1.59-WATCHLIST.md` — dated provider, dependency, policy, privacy, and security triggers.
- `.planning/research/v1.59-STACK.md` — Apple dependency admission, ES256 protocol, Crosswake vector, key-provider, and test-stack constraints.
- `.planning/research/v1.59-ARCHITECTURE.md` — source/projector/snapshot boundaries, public contracts, compatibility, diagnostics, and client ownership.
- `.planning/research/v1.59-PITFALLS.md` — security, ordering, linking, offline, and operational failure modes and gates.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — durable accepted architecture signal.

### Capability and Existing Support Contracts
- `.planning/entitlement-source-capability-matrix.md` — current source-specific design contract and aggregation rules.
- `.planning/processor-support-matrix.md` — separate shipped gateway-control support SSOT; do not merge it with the source contract.
- `accrue/guides/architecture.md` — host/core/admin/portal ownership and transactional conventions.
- `accrue/guides/entitlements.md` — current public entitlement semantics and advisory Stripe boundary.

### Project Voice, DX, and Comparative Lessons
- `brandbook/voice.md` — current voice and microcopy authority; supersedes old brand wording under `prompts/`.
- `prompts/original-billing-ecosystem-deep-research.md` — Pay, Cashier, dj-stripe, and cross-framework architecture/DX lessons; historical evidence, not current scope authority.
- `prompts/accrue-best-practices-deep-research-independent.md` — adopter JTBD, capability honesty, diagnostics, and operator/developer perspectives.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — persona and support-flow context where capability outcomes surface in UI.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Processor.Capabilities`: nested capability declarations, public/provider labels, and tests offer a useful implementation precedent, but the new source contract needs richer typed states and must remain separate.
- `Accrue.Entitlements.Resolver` and `LocalMap`: already expose set-union active plans, feature union, maximum quantities, fail-closed unmapped behavior, and a configurable resolver seam.
- `Accrue.Entitlements.Reconcile`, the immutable event ledger, Fake fixtures, frozen-clock seams, and Mox adapters: reusable proof patterns for deterministic cases and later transactional projection tests.
- `scripts/ci/verify_processor_support_matrix.sh` and provider-honesty tests: established code-to-document drift and negative-convergence gates to mirror for entitlement sources.

### Established Patterns
- Host-owned Repo, Finch, Oban, keys, secrets, and supervision; `Accrue.Application` remains childless.
- Public contexts and behaviours are preferred over macros or protocol-based configuration; typed errors fail clearly and early.
- Fake-first deterministic proof is merge-blocking; provider/device-backed fidelity is separately classified and may be advisory or release-gating.
- Local Ecto state is queryable truth derived from verified provider evidence; raw provider payloads remain bounded provenance rather than a fully mirrored schema.

### Integration Points
- New source capability registry connects beside—not inside—`Accrue.Processor` and feeds host inspection, portal guidance, admin diagnostics, and later rail observers.
- Decision cases connect to ExUnit, generated Markdown, Crosswake JSON vectors, support reasons, and later grant-projector conformance tests.
- The Crosswake tracer connects through a reference host boundary and language-neutral protocol fixtures, never through core `accrue` supervision or an undocumented shared runtime API.

</code_context>

<specifics>
## Specific Ideas

- Optimize for a Phoenix adopter and maintainer: idiomatic Ecto/Plug/Phoenix boundaries, explicit nouns and outcomes, excellent defaults, pattern-matchable results, deterministic Fake-first proof, and obvious escape hatches.
- Learn from Pay and Laravel Cashier’s ergonomic facades and provider honesty; avoid broad gateway sameness and migration-heavy implicit contracts. Learn from dj-stripe’s retreat from exhaustive provider mirroring: retain bounded query fields plus protected provenance rather than modeling every upstream field.
- Follow Kubernetes KEP, Rust RFC, and Python PEP lessons for explicit status/supersession without importing their full ceremony. Follow Terraform-style provider/resource separation for source versus gateway ownership.
- The relevant UX is developer, support, portal, and diagnostics UX rather than a new Phase-215 visual surface. Results should answer “what can I do, who owns it, and what is the next action?” without exposing projection or provider plumbing. Any later UI uses conventional accessible components, text-backed status, current light/dark/system tokens, and current brandbook microcopy.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. UI implementation belongs to the later portal/admin proof phases already present in the roadmap; no new UI capability was added here.

</deferred>

---

*Phase: 215-Research, contracts, and Crosswake feasibility*
*Context gathered: 2026-07-31*
