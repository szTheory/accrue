# Phase 220: First-adopter proof and release gates - Context

**Gathered:** 2026-08-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove that the anonymized B2C Alpha reference host and the public v1.59 release contract make Stripe/Apple account access and offline study safe, diagnosable, operable, and honestly supportable. This phase integrates and proves the contracts from Phases 215–219; it does not add a new rail, change entitlement authority, simulate unavailable Crosswake runtime capabilities, or expand provider lifecycle control.

</domain>

<decisions>
## Implementation Decisions

### Reference-host proof and deterministic scenarios
- **D-01:** Phase 220 owns one versioned, synthetic, data-only reference-host scenario corpus. Host integration tests, Crosswake Swift-vector tests, generated proof-matrix material, and CI consume the same scenario IDs and expected results; production contexts remain the sole domain-decision authority, so the corpus never becomes a second reducer. — **Reversibility:** costly — scenario IDs, cross-language vectors, documentation, and merge gates will all depend on this contract.
- **D-02:** Every scenario declares its version, ordered evidence/actions, frozen clock, expected account snapshot/revision, purchase eligibility, offline action policy, redacted diagnostic fields, required artifacts, and exactly one evidence lane: `deterministic_conformance`, `runtime_capability`, or `advisory_parity`. Only synthetic, credential-free `deterministic_conformance` rows are merge-blocking.
- **D-03:** Apple-to-web and Stripe-to-iOS scenarios prove deterministic account-projection convergence now, but public material must not claim mobile/Crosswake runtime feasibility until the tracer's required bridge and physical-device evidence exists. Fake, browser, simulator, or vector output cannot promote a blocked runtime-capability claim. — **Reversibility:** one-way — evidence-lane language becomes a public trust and release-contract commitment.
- **D-04:** Browser/Playwright coverage is a complementary rendered-host proof for accessible copy and flows, not the semantic oracle for StoreKit, cryptographic proof, offline cache crash/rollback, ordering, or key rotation. Use focused ExUnit/ConnTest/Ecto transactional consumers for host boundaries and pure Swift consumers for language-neutral fixtures.

### Operator diagnosis and safe repair
- **D-05:** Publish one internal, read-only, privacy-bounded entitlement diagnostic projection consumed by the reference host/admin, CLI/runbooks, and deterministic tests. It answers the operator's job-oriented questions: current canonical snapshot/revision; rail/environment and normalized provenance; provider/reconciliation freshness; eligibility; device/proof horizon; quarantine/retry state; and next safe action.
- **D-06:** The projection uses closed state, reason, next-action, timestamp/age, and safe-correlation fields. It never returns Ecto schemas, raw transaction/notification evidence, account tokens, proof bytes, PII, encrypted-evidence locators, provider payloads, Oban arguments/errors, exception text, or arbitrary metadata. It extends the entitlement diagnostic seam with canonical multi-rail state rather than folding Apple/offline facts into the existing Stripe-advisory branch. — **Reversibility:** one-way — a diagnostic field exposed to operators or docs becomes a privacy and support contract.
- **D-07:** Each repair is a distinct host-authorized context action with a bounded target, database-lock/idempotency correctness, actor-and-reason audit, confirmation or dry-run where meaningful, and a post-action convergence assertion. A repair may enqueue/coalesce work but never routinely reconstructs an account or automatically transfers, merges, refunds, cancels, migrates, or prorates one.
- **D-08:** Deterministic repair drills prove missed-notification recovery, cursor recovery, provider outage/rate-limit behavior, ownership-conflict containment, duplicate-charge escalation without automatic finance mutation, stale/revoked-device replacement, signing-key compromise/rotation, and reconciliation-backlog drain. Durable `needs_repair`, bounded retry/backoff, and database authority remain visible; Oban uniqueness is coalescing only, never the correctness lock.

### Public release contract and developer experience
- **D-09:** Use a versioned v1.59 public-contract fixture to generate the capability/compatibility matrix and power deterministic drift gates. Keep walkthroughs, App Review guidance, privacy/security limits, runbooks, threat/watchlist material, and release notes hand-authored; generated reference owns exact supported/unsupported assertions while prose owns explanation and procedure. — **Reversibility:** costly — fixture schema, generated matrix, and CI gates become coordinated release artifacts.
- **D-10:** Public and generated material must state one additive contract: legacy hosts remain compatible; Apple is externally managed; no cross-rail lifecycle migration/refund/proration occurs; stale offline permits downloaded-study/local-progress continuity only; and no diagnostic, fixture, telemetry, or guide exposes raw transaction data, signed proof material, tokens, or PII. Drift gates reject contrary claims.
- **D-11:** Developer UX follows a compact first-adopter path: adopt the reference-host recipe, run one deterministic verification command, use one capability/limits matrix, and follow a scenario/runbook by ID for failure resolution. Evidence lanes remain visible so a maintainer never mistakes advisory/live-store evidence for merge-blocking proof.

### User-facing and operator experience
- **D-12:** Render diagnosis and repair outcomes in job-and-next-action language, never backend/worker/provider internals. Use text-backed states, literal action labels, semantic headings and tables, keyboard/focus-safe controls, reasoned disabled actions, focus return after mutation, and light/dark/system-safe styling; color only reinforces meaning. Current brandbook voice and copy authority supersede older prompt wording.

### the agent's Discretion
The planner may choose exact fixture schema/module names, generator implementation, scenario granularity, test/helper placement, CLI versus host-admin presentation split, telemetry names, CI job wiring, and documentation organization. These choices must preserve the shared-corpus/non-reducer boundary, closed evidence lanes, Crosswake feasibility truthfulness, host-owned runtime boundaries, privacy redaction, provider honesty, deterministic Fake-first merge proof, and accessible job-focused outcomes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and locked phase decisions
- `.planning/PROJECT.md` — v1.59 vision, stable-core posture, host/package ownership, privacy guardrails, and deferrals.
- `.planning/ROADMAP.md` — authoritative Phase 220 goal, dependencies, success criteria, and phase boundary.
- `.planning/REQUIREMENTS.md` — PROOF-01 through PROOF-05 acceptance contract.
- `.planning/phases/215-research-contracts-and-crosswake-feasibility/215-CONTEXT.md` — decision-case, source-capability, authority, and feasibility contracts; the scenario corpus must preserve its data-not-reducer boundary.
- `.planning/phases/218-apple-observation-and-repair/218-CONTEXT.md` — Apple verification, repair, provider-isolation, redaction, and reconciliation locks.
- `.planning/phases/219-offline-study-contract/219-CONTEXT.md` — public proof states, golden-fixture, reconnect, privacy, and learner-continuity locks.

### v1.59 authority and risks
- `.planning/research/v1.59-AUTHORITY.md` — research precedence and active Stripe/Apple/offline policy.
- `.planning/research/v1.59-AMENDMENTS.md` — accepted scope amendments and reassessment rules.
- `.planning/research/v1.59-SUMMARY.md` — canonical architecture and accepted tradeoffs.
- `.planning/research/v1.59-DECISION-TABLE.md` — decision-case authority for survivor, ordering, eligibility, repair, and proof outcomes.
- `.planning/research/v1.59-PITFALLS.md` — privacy, ordering, provider-isolation, App Review, and operational hazards.
- `.planning/research/v1.59-WATCHLIST.md` — monitored external-change triggers.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — approved product strategy, capabilities, and explicit limits.

### Existing public/executable proof and operations contracts
- `examples/accrue_host/docs/adoption-proof-matrix.md` — existing Fake-first versus live-provider proof lanes and host verification structure.
- `examples/crosswake_tracer/capability-report.json` — currently `feasibility_blocked` runtime-capability status and required evidence kinds.
- `examples/crosswake_tracer/README.md` — tracer scope and evidence boundaries.
- `accrue/guides/entitlements.md` — public entitlement/source, Apple-management, host configuration, and fail-closed contracts.
- `accrue/guides/operator-runbooks.md` — safe operational triage and repair procedure patterns.
- `accrue/guides/release-notes.md` — release-note style and public contract expectations.
- `accrue/lib/accrue/entitlements/admin.ex` — existing deliberately bounded diagnostic seam.
- `accrue/lib/accrue/entitlements/offline.ex` — public offline facade and client-safe boundary.
- `accrue/priv/entitlements/v1.59-decision-cases.json` — language-neutral decision-case corpus precedent.
- `accrue/priv/entitlements/v1.59-offline-golden-vectors.json` — versioned cross-language golden-vector precedent.
- `scripts/ci/verify_entitlement_source_matrix.sh` — existing public-contract drift-gate precedent.
- `scripts/ci/verify_adoption_proof_matrix.sh` — existing adoption-proof documentation-gate precedent.
- `scripts/ci/verify_release_contract.sh` — existing coordinated release-contract gate.

### Product, DX, and voice inputs
- `brandbook/voice.md` — current voice authority; supersedes older prompt wording.
- `brandbook/copy.md` — current guidance/error/action-copy patterns.
- `prompts/accrue-best-practices-deep-research-independent.md` — operator JTBD, safe-action, privacy, and provider-honesty research input.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — library/host/operator boundary and user-flow context.
- `prompts/original-billing-ecosystem-deep-research.md` — Pay/Cashier and ecosystem DX/footgun lessons; historical context, not scope authority.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Entitlements.Admin` — bounded read-only diagnostic seam to extend with canonical multi-rail facts rather than exposing storage rows.
- `Accrue.Entitlements.Offline` and `v1.59-offline-golden-vectors.json` — public verification facade and cross-language fixture pattern.
- `Accrue.Entitlements.DecisionCases` and `v1.59-decision-cases.json` — stable decision/reason vocabulary and data-contract precedent.
- Apple reconciliation, offline reconnect/issuance, and durable account/grant/observation/device records — existing state and repair inputs for diagnostics/drills.
- `examples/accrue_host` Fake-backed verification aliases and proof matrix — established merge-blocking host evidence lane.
- `examples/crosswake_tracer` Swift tests and capability report — client/vector consumer and feasibility-report pattern.

### Established Patterns
- Phoenix-style context modules expose typed/tagged public results and hide Ecto/provider internals.
- The host owns Repo, Oban, supervision, authentication/authorization, routes, secrets, and rendering; Accrue owns bounded domain behavior and guidance values.
- PostgreSQL constraints and locks are correctness authority; Oban uniqueness coalesces work but is not an execution or authorization lock.
- Deterministic Fake-first tests are merge-blocking; live-provider evidence is advisory and must be labeled honestly.
- Existing docs gates use versioned facts plus literal checks to prevent public-contract drift.

### Integration Points
- Add the reference scenario corpus adjacent to existing v1.59 fixture/corpus assets and attach consumers in `accrue`, `examples/accrue_host`, and `examples/crosswake_tracer` without duplicating production reducers.
- Extend diagnostics through `Accrue.Entitlements.Admin`; let the reference host/admin render bounded values under host authorization.
- Build repair drills from the existing Apple reconciliation and offline reconnect/issuance paths, then surface them in runbooks and CI.
- Connect public-contract generation and verification to existing capability/source matrix, adoption proof, package docs, and release-contract gates.

</code_context>

<specifics>
## Specific Ideas

- Favor the compact, discoverable DX of Pay/Cashier-style facades while preserving Accrue's provider-honest multi-rail boundary; do not fabricate a uniform lifecycle model.
- Treat account-level operator diagnosis as a support/incident-response tool, not a Stripe Dashboard clone or a raw database explorer.
- Put user and operator jobs first: state what access exists, why it is restricted, and the next safe action; hide backend mechanics unless a bounded detail is necessary for the action.
- Apply correctness, compatibility, security, privacy, resilience, observability, performance, accessibility, maintainability, testability, documentation truth, developer ergonomics, and release safety together.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 220. Google Play, Family Sharing, offer authoring, automatic ownership transfer, migration/proration, broad fraud/risk controls, and any runtime claim beyond the Crosswake tracer's available evidence remain out of scope.

</deferred>

---

*Phase: 220-First-adopter proof and release gates*
*Context gathered: 2026-08-04*
