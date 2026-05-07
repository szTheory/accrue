# Phase 110: Lifecycle Semantics & Self-Serve Clarity - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish one canonical lifecycle semantics source of truth and tighten any touched portal, admin, or customer-facing copy/UI so subscription actions and lifecycle states are explicit, least-surprising, and provider-honest across Stripe, Fake, and Braintree.

This phase clarifies the meaning of the already-shipped lifecycle surface. It does not add new billing primitives, erase provider differences, reopen processor scope, or turn companion surfaces into a general UI-polish project.

</domain>

<decisions>
## Implementation Decisions

### Canonical lifecycle documentation shape
- **D-01:** Publish one canonical lifecycle semantics guide organized by **action + state glossary**, not by provider-specific narratives and not API-reference-first.
- **D-02:** The canonical guide should define the meaning of each Accrue lifecycle action and state once, then attach provider labels such as:
  - `native`
  - `host-owned`
  - `unsupported`
  - `testing/local-only` where Fake behavior needs qualification
- **D-03:** Provider-specific guides, troubleshooting docs, and API docs should point back to this lifecycle guide rather than compete with it as alternate truth sources.
- **D-04:** API docs should stay precise, but they are secondary for lifecycle meaning. The conceptual lifecycle guide is the SSOT for mental model, operator meaning, and UI copy anchors.

### Cancellation posture
- **D-05:** For paid subscriptions, the default Accrue-owned lifecycle posture should be **turn off renewal now, keep access through the paid-through date**.
- **D-06:** Wherever Accrue owns customer or operator copy, prefer wording like:
  - `Cancel renewal`
  - `End at period end`
  - `Access continues until DATE`
  over ambiguous wording like `Cancel` when that could be read as immediate access termination.
- **D-07:** **Immediate cancellation** remains available as an explicit, exceptional path for support-led, compliance, fraud, or intentionally hard-stop flows. It should not be the primary recommended self-serve action.
- **D-08:** Do not promise identical gateway behavior behind this posture:
  - Stripe can support scheduled cancellation and reversal natively.
  - Braintree may require Accrue to express the product contract in local semantics instead of implying Stripe-shaped native reversibility.
- **D-09:** Never collapse these into one vague state in copy:
  - `active`
  - `scheduled to end` / `canceling`
  - `ended`

### Unsupported and divergent lifecycle semantics
- **D-10:** Use **explicit capability-driven messaging with next-step guidance** for divergent or unsupported lifecycle operations.
- **D-11:** Avoid abstract parity wording like `semantics vary by processor` when a more direct explanation is available.
- **D-12:** Errors, guide copy, and touched UI text should say what the processor can do, what Accrue owns locally, and what the operator or user should do next.
- **D-13:** When Braintree or another processor cannot support a lifecycle action the same way Stripe does, prefer wording like:
  - `Braintree does not support this Accrue pause/unpause semantic.`
  - `Create a new subscription after cancellation rather than implying reversible resume support.`
  over generic `unsupported` phrasing with no next step.
- **D-14:** Fake should be described honestly as the deterministic proof lane and local/testing semantics source, not as evidence that every provider has equivalent lifecycle affordances.

### Touched UI and copy scope
- **D-15:** Phase 110 should include **one focused lifecycle clarity improvement across touched surfaces**, not a broad visual redesign and not docs-only.
- **D-16:** The preferred improvement shape is a shared lifecycle summary/copy layer that:
  - names lifecycle states plainly
  - shows access-end timing explicitly
  - gives provider-aware action helper text where needed
  - avoids offering copy that implies unsupported Braintree semantics
- **D-17:** Favor shared copy and shared HEEx/component-level presentation over page-by-page bespoke wording.
- **D-18:** Good bounded targets include:
  - lifecycle status summary language
  - helper text under cancel/resume/pause actions
  - explicit `access ends on ...` copy
  - provider-aware follow-up guidance after lifecycle actions
- **D-19:** Do not widen this into general portal/admin theming, retention-product work, or broad UX experimentation.

### Status vocabulary and least-surprise UX
- **D-20:** Touched copy and docs should clearly distinguish at least these lifecycle states:
  - `active`
  - `canceling`
  - `paused`
  - `past_due`
  - `ended`
- **D-21:** The lifecycle glossary should be the source that UI and docs use for these labels so wording cannot drift independently across surfaces.
- **D-22:** Where webhook convergence lag can plausibly affect perception, copy may acknowledge local refresh/convergence rather than implying impossible instant global truth.

### Ecosystem and strategy lessons to preserve
- **D-23:** Learn from Stripe-hosted lifecycle ergonomics where they are strong, but do not project Stripe-only behavior onto Braintree.
- **D-24:** Learn from Pay and Cashier that bounded multi-provider support works when the shared surface is narrow, explicit, and honest about divergence.
- **D-25:** Continue avoiding the ActiveMerchant trap: do not smooth over structural provider differences into misleading facade sameness.

### GSD shift-left preference
- **D-26:** Reaffirm the user's standing preference for future discuss/planning passes in this track:
  - research deeply
  - synthesize one cohesive recommendation package
  - auto-resolve low-impact forks
  - only escalate materially high-impact product, support-contract, or long-term API decisions
- **D-27:** Current `.planning/config.json` already partially encodes this behavior. Future GSD passes should continue honoring it without reopening low-impact lifecycle wording or supportability forks by default.

### the agent's Discretion
- Exact filename and placement of the canonical lifecycle guide, as long as it becomes the single lifecycle SSOT and other touched docs point back to it.
- Exact component/copy implementation for the focused lifecycle clarity improvement, as long as it stays bounded and provider-honest.
- Exact phrasing for capability-driven helper text and typed error copy, as long as it states the processor truth and recommended next step clearly.

</decisions>

<specifics>
## Specific Ideas

- Recommended canonical posture:
  - `Accrue exposes one lifecycle facade, but lifecycle meaning stays provider-honest.`
  - `Stripe, Fake, and Braintree share vocabulary where the product meaning is the same; provider labels explain where behavior is native, host-owned, or unsupported.`
- Recommended self-serve cancellation posture:
  - primary CTA/copy should read closer to `Cancel renewal` or `End at period end`
  - always show the exact access end date
  - reserve immediate cancel for explicit exceptional flows
- Recommended focused UI improvement:
  - a shared lifecycle summary/copy layer on touched admin and customer surfaces that makes `active / canceling / paused / past_due / ended` legible and ties action copy to provider truth
- Ecosystem lessons the project should preserve:
  - Stripe portal gets cancellation timing and retention posture right by making timing explicit
  - Pay/Cashier succeed by being opinionated and honest about processor divergence
  - ActiveMerchant is still the warning case for over-broad abstraction pressure
- User preference captured explicitly:
  - deep recommendation synthesis by default
  - low-impact forks shifted left into defaults
  - reopen only very impactful decisions

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement truth
- `.planning/ROADMAP.md` — v1.35 boundary and Phase 110 goal
- `.planning/REQUIREMENTS.md` — `LIF-01` and `LIF-02`
- `.planning/PROJECT.md` — current strategic posture and milestone framing
- `.planning/STATE.md` — active milestone position
- `.planning/STRATEGY.md` — bounded dual-provider core strategy
- `.planning/processor-support-matrix.md` — capability/support SSOT that lifecycle wording must stay aligned with

### Prior phase decisions that remain locked
- `.planning/milestones/v1.31-phases/094-strategy-capability-matrix-target-lock/094-CONTEXT.md` — capability-explicit provider posture
- `.planning/milestones/v1.31-phases/095-official-processor-contract-conformance-harness/095-CONTEXT.md` — support boundaries and Fake-first proof posture
- `.planning/milestones/v1.31-phases/096-chosen-second-provider-thin-slice/96-CONTEXT.md` — host-owned Braintree UI seam, bounded multi-provider stance, and shift-left recommendation preference
- `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md` — provider-honest checkout/portal contract and low-impact recommendation-synthesis preference

### Existing lifecycle-facing docs and semantics sources
- `accrue/lib/accrue/billing/subscription.ex` — canonical in-memory lifecycle predicates and status semantics
- `accrue/lib/accrue/billing/query.ex` — query-time equivalents of the lifecycle predicates
- `accrue/lib/accrue/billing/subscription_actions.ex` — current public lifecycle action surface and failure semantics
- `accrue/guides/portal_configuration_checklist.md` — Stripe-hosted cancellation timing and portal behavior lessons
- `accrue/guides/braintree-local-portal.md` — mounted Braintree portal contract and currently outdated lifecycle emphasis that Phase 110 should correct
- `accrue/guides/webhooks.md` — webhook ownership/convergence framing
- `accrue/guides/webhook_gotchas.md` — operator lifecycle/recovery constraints

### Touched UI/copy surfaces
- `accrue_portal/lib/accrue_portal/copy.ex` — customer lifecycle copy seam
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` — subscription detail lifecycle UX
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` — subscriptions list lifecycle actions
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` — admin lifecycle copy seam
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — admin subscription lifecycle actions and helper text
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` — host-facing example lifecycle copy that should not drift from the clarified semantics

### Existing tests and proof anchors
- `accrue/test/accrue/billing/subscription_cancel_test.exs` — cancel/cancel_at_period_end/resume/pause/unpause semantics
- `accrue/test/accrue/billing/subscription_predicates_test.exs` — lifecycle predicate truth
- `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` — portal lifecycle flow proof
- `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs` — portal lifecycle list proof
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — admin lifecycle action proof

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Billing.Subscription` already defines the correct lifecycle predicates and semantics (`canceling?/1`, `paused?/1`, `past_due?/1`, `canceled?/1`) that docs and UI should mirror.
- `Accrue.Billing.Query` already exposes matching database-level lifecycle semantics for list and dashboard surfaces.
- `Accrue.Billing.SubscriptionActions` already distinguishes `cancel/2`, `cancel_at_period_end/2`, `resume/2`, `pause/2`, and `unpause/2`, including typed invalid-state guidance.
- `AccruePortal.Copy` and `AccrueAdmin.Copy.Subscription` already provide centralized copy seams that can support a bounded lifecycle-clarity pass without redesigning the whole UI.

### Established Patterns
- The repo already prefers provider-honest support language over faux parity.
- Fake remains the deterministic merge-blocking proof lane; provider-backed behavior is bounded and explicit.
- LiveView surfaces are thin and copy-driven, making a shared lifecycle clarity layer a Phoenix-idiomatic fit.
- Existing code already warns against raw status branching and treats local projection + webhook convergence as core semantics.

### Integration Points
- Lifecycle docs, portal copy, admin copy, example-host wording, and support matrix language must stay aligned in the same truth pass.
- Touched UI copy should derive from the same lifecycle vocabulary as the new canonical guide.
- Any capability-driven wording change should stay synchronized with typed errors and support labels so docs/UI/API do not drift.

</code_context>

<deferred>
## Deferred Ideas

- Broad portal/admin redesign or heavy theming work
- New lifecycle primitives or widened processor capability promises
- Retention-product expansion, cancellation-reason productization, or generalized churn tooling
- Any attempt to erase structural Stripe/Braintree differences behind one misleading lifecycle abstraction
- GSD-wide workflow rewrites beyond the already-present config and the reinforced preference captured here

</deferred>

---

*Phase: 110-lifecycle-semantics-self-serve-clarity*
*Context gathered: 2026-05-06*
