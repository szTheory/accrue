# Phase 109: Support Contract Truth - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Align package docs, support matrix, planning mirrors, and host-facing guidance around one provider-honest Stripe + Braintree contract for checkout and billing portal behavior.

This phase hardens the truth of the already-shipped surface. It does not add new billing primitives, reopen new processors, or broaden processor scope beyond the existing Stripe + Braintree boundary.

</domain>

<decisions>
## Implementation Decisions

### Public contract wording
- **D-01:** The dominant public contract wording for checkout and billing portal should be **same facade, provider-honest behavior**, not Stripe-only wording.
- **D-02:** Public docs should say explicitly that `Accrue.Billing.create_checkout_session/2` and `Accrue.Billing.create_billing_portal_session/2` are first-party on both Stripe and Braintree, but with different implementation semantics:
  - Stripe returns upstream hosted URLs.
  - Braintree returns mounted first-party local URLs.
- **D-03:** Stripe should remain the **secondary framing** as the fastest first-user production path, but that framing must not override or dilute the shipped provider-honest support contract.
- **D-04:** Avoid wording that implies identical UX or full parity across processors. The contract is shared facade, not shared hosted experience.

### First-hour guidance shape
- **D-05:** Keep `accrue/guides/first_hour.md` as the single canonical onboarding spine.
- **D-06:** Keep the main First Hour path Fake/Stripe-first, then add an early, explicit Braintree branch for the mounted local portal/checkout contract.
- **D-07:** The Braintree branch should call out only the minimum required contract:
  - add `accrue_portal`
  - mount `accrue_portal "/billing"` as a sibling scope
  - set `portal_mount_path`
  - set absolute `portal_base_url`
  - satisfy auth/session requirements
  - satisfy CSP / Hosted Fields requirements
- **D-08:** `accrue/guides/braintree-local-portal.md` should become the SSOT for the mounted Braintree path, with packaged `accrue_portal` as the default story and hand-rolled portal guidance as the escape hatch.

### Failure-mode prominence
- **D-09:** Front-door docs must surface the high-probability, architecture-defining failure modes for the Braintree mounted path rather than hiding them in troubleshooting only.
- **D-10:** The following failures are part of the setup contract and should be called out early:
  - `portal_base_url` must be absolute
  - `portal_mount_path` must match the actual mount
  - auth/session keys must resolve the same user/customer across Plug and LiveView mounts
  - Hosted Fields requires the portal CSP/script contract
  - Braintree has no upstream hosted portal fallback; incomplete local setup yields typed unsupported behavior
  - discount preview is provisional and final submit is authoritative
  - checkout completion is local/synthetic and should be described as persisted completion, not vague redirect success
- **D-11:** Detailed remediation, telemetry walkthroughs, and operator recovery flows belong in troubleshooting/runbooks, not duplicated inline in First Hour.

### Role of the example host
- **D-12:** `examples/accrue_host` remains primarily the Fake-backed proof surface and reference app. It should not become the primary install story for Hex consumers.
- **D-13:** The example host should explicitly teach and demonstrate the Braintree mounted portal contract well:
  - local URL return shape
  - `portal_mount_path`
  - `portal_base_url`
  - sibling mount expectations
  - auth boundary
  - likely failure modes
- **D-14:** Package docs and guides remain the adoption/integration SSOT. The example host is proof, reference, and evaluator-facing demonstration.
- **D-15:** Sigra-specific example-host assumptions must remain clearly demo-only and never become normative for the public Braintree onboarding story.

### Cohesion and contributor discipline
- **D-16:** README, package README, First Hour, support matrix, Braintree portal guide, and example-host docs must all describe the same processor truth in the same PR whenever wording changes.
- **D-17:** Add one shared provider-behavior table across the front-door docs:
  - Stripe checkout/portal -> upstream hosted URLs
  - Braintree checkout/portal -> mounted local URLs
- **D-18:** The support matrix remains the canonical support SSOT; package docs and example-host docs are mirrors that must be kept aligned with it.

### Shift-left defaults for future GSD passes
- **D-19:** Future low-impact discuss/planning choices in this processor-supportability track should default to recommendation synthesis rather than reopening them interactively.
- **D-20:** Reopen decisions interactively only when they materially change product boundary, public support promise, proof-lane philosophy, or long-term API surface.
- **D-21:** In future GSD workflow passes, bias recommendations toward:
  - stable facade + provider-honest behavior
  - explicit capability labels
  - mounted-subsystem clarity over faux uniformity
  - least-surprise onboarding and failure semantics
  - package-doc SSOT with example-host proof support

### the agent's Discretion
- Exact wording placement across `README.md`, `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/braintree-local-portal.md`, `accrue_portal/README.md`, and example-host docs, as long as they all mirror the same contract.
- Exact formatting and location of the provider-behavior table.
- Exact split between front-door docs and troubleshooting/runbook material, as long as setup-contract failures remain prominent and deep remediation stays centralized.

</decisions>

<specifics>
## Specific Ideas

- Recommended top-line wording:
  - "Accrue exposes one billing facade across Stripe and Braintree, but keeps provider behavior honest: Stripe uses upstream hosted checkout and billing portal; Braintree uses Accrue's mounted local checkout and self-serve portal. Stripe remains the fastest first-user production path."
- Recommended First Hour branch label:
  - "Using Braintree local checkout/portal instead of Stripe-hosted surfaces?"
- Recommended package-doc posture:
  - package docs teach the integration contract
  - example host proves and demonstrates the contract
  - support matrix defines the contract
- User preference captured:
  - shift low-impact processor-supportability decisions left into coherent recommendations by default
  - reopen only strategically meaningful choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and strategy truth
- `.planning/ROADMAP.md` — v1.35 milestone boundary and Phase 109 goal
- `.planning/PROJECT.md` — current strategic posture and active milestone truth
- `.planning/REQUIREMENTS.md` — `SUP-01` and `SUP-02` requirements
- `.planning/processor-support-matrix.md` — canonical processor support SSOT and provider-honest checkout/portal wording
- `.planning/STRATEGY.md` — parent strategic track for the bounded dual-provider core

### Prior phase decisions
- `.planning/milestones/v1.31-phases/094-strategy-capability-matrix-target-lock/094-CONTEXT.md` — capability-explicit support posture and anti-parity boundary
- `.planning/milestones/v1.31-phases/095-official-processor-contract-conformance-harness/095-CONTEXT.md` — hard support boundaries and Fake-first proof posture
- `.planning/milestones/v1.31-phases/096-chosen-second-provider-thin-slice/96-CONTEXT.md` — host-owned Braintree UI seam and matrix-led support messaging
- `.planning/milestones/v1.33-phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md` — mounted `accrue_portal` contract and Braintree local checkout/portal behavior

### Public docs to align
- `README.md` — repo-root proof path and package entry framing
- `accrue/README.md` — core package landing page and support claims
- `accrue/guides/first_hour.md` — canonical onboarding spine
- `accrue/guides/braintree-local-portal.md` — mounted Braintree path SSOT
- `accrue/guides/production-readiness.md` — ship-order readiness framing
- `accrue/guides/telemetry.md` — billing/portal telemetry anchors and operational references
- `accrue_portal/README.md` — mounted customer portal contract page
- `examples/accrue_host/README.md` — host proof path and evaluator-facing reference
- `examples/accrue_host/docs/adoption-proof-matrix.md` — proof taxonomy and example-host truth

### Shift-left and verifier constraints
- `scripts/ci/README.md` — co-update rules and docs contract map
- `scripts/ci/verify_package_docs.sh` — package-doc drift gate
- `scripts/ci/verify_verify01_readme_contract.sh` — example-host README drift gate
- `scripts/ci/verify_adoption_proof_matrix.sh` — adoption-proof-matrix drift gate
- `scripts/ci/verify_processor_support_matrix.sh` — support-matrix wording gate

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `accrue_portal` package — mounted local portal implementation for Braintree checkout and self-serve billing
- `Accrue.Billing.create_checkout_session/2` and `Accrue.Billing.create_billing_portal_session/2` — stable public facade verbs whose support wording must be corrected
- `AccruePortal.Router.accrue_portal/2` and sibling mount pattern — existing mounted-subsystem integration seam
- typed config/support failures in tests around `portal_base_url`, local portal fallback, and portal session behavior — useful as docs truth anchors

### Established Patterns
- Fake-first, merge-blocking proof posture with provider-backed fidelity lanes advisory by default
- support truth is codified in both docs and executable shell/ExUnit gates
- package docs are intended as the public integration SSOT; example host is proof/reference
- mounted subsystems in the repo use explicit router/auth/config contracts rather than hidden automation

### Integration Points
- `README.md`, `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/braintree-local-portal.md`, `accrue_portal/README.md`, and example-host docs must be updated together
- support wording changes will need matching verifier updates only where the current scripts pin stale literals
- planning mirrors in `.planning/` must stay aligned with public doc wording

</code_context>

<deferred>
## Deferred Ideas

- No broad `accrue_portal` redesign or heavy theming work in this phase
- No new processor capabilities, finance/export work, or marketplace reopening
- No shift from Fake-first merge-blocking proof to live-provider merge-blocking proof

</deferred>

---

*Phase: 109-support-contract-truth*
*Context gathered: 2026-05-06*
