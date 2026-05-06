# Phase 104: Connect Spike / Decision - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 104 decides whether Braintree marketplace support should become a first-party Accrue story via Hyperwallet, or be explicitly rejected as out of scope for the current project boundary.

This phase does **not** implement marketplace support. It only decides the posture, the smallest if-go contract if the spike is positive, and the rejection boundary if it is not.

The phase remains within Accrue's direct-gateway strategy: no merchant-of-record pivot, no finance-system expansion, and no broad processor-agnostic abstraction work.

</domain>

<decisions>
## Implementation Decisions

### Decision target
- **D-01:** Keep Phase 104 as a decision spike, not a platform-design phase.
- **D-02:** The best default is **go/no-go plus a narrow if-go slice contract**. That preserves a reusable outcome from the spike without committing Accrue to a large marketplace architecture.
- **D-03:** Avoid a full architecture target in this phase. It would overfit the project to false provider commonality and likely pull the codebase toward a payout-platform design before the boundary is actually justified.

### Parity bar
- **D-04:** If the spike is positive, the right bar is **core `Accrue.Connect` semantic parity with loud exclusions**.
- **D-05:** Do not chase near-Stripe parity. Braintree + Hyperwallet is not Stripe Connect, and pretending otherwise would create support debt and misleading APIs.
- **D-06:** If a smaller marketplace slice is pursued, it should stay honest about what it covers and what it does not. Minimal onboarding/payout-only support is viable only if it is labeled as such, not sold as full Connect parity.

### Product boundary
- **D-07:** Keep Braintree pay-ins and Hyperwallet payouts as separate truths in the docs and module boundaries.
- **D-08:** Use one `Accrue.Connect` umbrella story for discoverability, but keep provider ownership visible in types, docs, capability labels, and failure paths.
- **D-09:** Do not hide the split behind a unified abstraction. The lowest-surprise, most supportable shape is explicit provider boundaries under a marketplace umbrella.

### Rejection posture
- **D-10:** If the spike says no, reject marketplace parity as **strategically out of bounds unless the project boundary changes**.
- **D-11:** Do not use the weaker posture of "v1.x only" or "until adopter demand" as the final answer. Those are too soft for this project and invite zombie scope.
- **D-12:** Reopening this decision should require an explicit strategy change plus a new milestone, not informal roadmap drift.

### the agent's Discretion
- Exact marketplace terminology if a go decision is made, as long as it stays capability-explicit and provider-honest.
- Exact thin-slice shape if the spike is positive, provided it does not imply full Stripe parity.

</decisions>

<specifics>
## Specific Ideas

- The strongest coherent recommendation is: keep the phase as a spike, not a platform redesign.
- If go, the smallest defensible slice should be narrow and explicit, not a fake "full Connect" story.
- If no-go, write a hard boundary that prevents the topic from reappearing as a soft maybe later.
- Strong defaults should be shifted left into planning and execution unless the choice is strategically important.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and strategy truth
- `.planning/ROADMAP.md` — Phase 104 goal, dependency, and success criteria
- `.planning/milestones/v1.33-REQUIREMENTS.md` — BT-08 and BT-09 requirement text
- `.planning/STRATEGY.md` — active PROC-08 track, direct-gateway boundary, and out-of-scope posture
- `.planning/PROJECT.md` — project posture, least-surprise bar, and current milestone framing
- `.planning/STATE.md` — current execution position and recent decisions

### Prior phase context
- `.planning/milestones/v1.32-phases/100-billing-portal-semantics/100-RESEARCH.md` — Phase 100 boundary precedent and why hosted UI work stayed separate
- `.planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md` — first-party portal boundary and deferred Connect/Hyperwallet surface
- `.planning/phases/103-metering-engine/103-CONTEXT.md` — strong-defaults posture and how later phases should auto-resolve low-impact choices
- `.planning/milestones/v1.31-phases/094-strategy-capability-matrix-target-lock/094-CONTEXT.md` — locked provider strategy and capability-explicit support posture

### Existing code and support surfaces
- `accrue/lib/accrue/connect.ex` — current Connect public surface and naming constraints
- `accrue/lib/accrue/processor/braintree.ex` — Braintree adapter boundary and current capability shape
- `accrue/lib/accrue/processor/capabilities.ex` — capability-label vocabulary and support-slice contract
- `accrue/guides/custom_processors.md` — extension-point posture versus first-party support posture
- `accrue/guides/operator-runbooks.md` — operator-facing recovery and support expectations

### External ecosystem references that informed this decision
- Hyperwallet marketplace / payouts positioning and developer docs
- Stripe Connect docs and compare-with-connect material
- Phoenix context and generator guidance
- Ecto schema / embedded schema guidance
- ExDoc extras / guide organization
- Oban docs for product boundary separation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Connect` already gives a first-party place to name marketplace-adjacent concepts without inventing a second facade.
- `Accrue.Processor.capabilities/1` already supports explicit capability labeling, which is the right place to mark supported versus unsupported marketplace behaviors.
- `Accrue.Error` / typed unsupported errors already provide a clean failure path for rejected capabilities.

### Established Patterns
- Accrue's planning docs already prefer capability-explicit support slices over vague parity promises.
- The repo consistently treats boundary decisions as first-class artifacts before implementation work starts.

### Integration Points
- Phase 95 / 96 style capability-labeling is the right template if any marketplace slice is approved.
- Any future go decision should update the processor-support matrix and keep Braintree vs Hyperwallet ownership visible.

</code_context>

<deferred>
## Deferred Ideas

- Full Braintree marketplace parity.
- Any future payout-platform abstraction that would generalize marketplace support beyond the current direct-gateway boundary.
- A unified abstraction that hides provider ownership behind a single money-movement API.

</deferred>

---

*Phase: 104-connect-spike-decision*
*Context gathered: 2026-05-02*
