# Phase 113: Cancellation Semantics Closure - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the shipped Stripe/Fake/Braintree cancellation story coherent across public facade verbs, capability labels, docs, example-host proof, and Braintree-specific limits.

This phase closes an already-shipped contract seam. It does not broaden Accrue into a billing-engine-owned local cancellation orchestration layer, does not reopen full lifecycle parity, and does not hide provider differences behind a faux-uniform abstraction.

</domain>

<decisions>
## Implementation Decisions

### Official cancellation contract boundary
- **D-01:** Phase 113 should promote only cancellation behavior that current adapter truth can actually defend. Provider-honest contract closure is more important than preserving a visually uniform cancellation story.
- **D-02:** Braintree's official first-party cancellation contract remains **immediate cancellation only** in the generic Accrue facade.
- **D-03:** `cancel_at_period_end` is **not** promoted as a Braintree first-party runtime capability in this milestone.
- **D-04:** If a host wants a Braintree-specific "turn off renewal, keep access through the paid-through date" policy, that must live in an explicit **host-owned** seam above Accrue rather than being presented as processor-backed first-party library behavior.
- **D-05:** Phase 113 should remove or rewrite any docs, examples, or UI flows that currently teach Braintree `cancel_at_period_end` as if it were an official first-party runtime path.

### Public facade semantics
- **D-06:** Keep explicit verb semantics at the Phoenix context boundary. Do **not** overload `cancel/2` with processor-dependent meanings.
- **D-07:** In this phase, `Accrue.Billing.cancel/2` remains the **immediate / hard-stop** cancellation verb.
- **D-08:** `Accrue.Billing.cancel_at_period_end/2` remains the explicit **renewal-stop / scheduled-end** verb where provider truth supports it.
- **D-09:** Unsupported providers must fail clearly when `cancel_at_period_end/2` is invoked. The runtime must not silently degrade a scheduled-end request into immediate cancellation.
- **D-10:** Do **not** add a third first-class public cancellation facade in this closure milestone just to mirror capability-matrix vocabulary. `cancel_immediately` may remain capability and documentation terminology that maps to `cancel/2`, but it should not force a new public API surface now.
- **D-11:** A future API-cleanup phase may revisit whether `cancel_now/2` or `cancel_immediately/2` would be a clearer public alias, but that naming churn is outside this closure pass.

### Capability labels and support truth
- **D-12:** Capability booleans, `support_label/1` values, `.planning/processor-support-matrix.md`, and public docs must move together in the same truth pass.
- **D-13:** `subscription.cancel` and `subscription.cancel_immediately` should align to the same immediate-cancel contract truth across Stripe, Fake, and Braintree because that is the shipped shared path today.
- **D-14:** `subscription.cancel_at_period_end` should remain supported on Stripe and Fake, and explicitly unsupported on Braintree.
- **D-15:** If the current support-label taxonomy cannot describe mixed lifecycle support cleanly, Phase 113 may refine the lifecycle label wording rather than forcing a misleading all-or-nothing label.
- **D-16:** The processor-support matrix remains the canonical human-readable SSOT for the split: Braintree supports immediate cancellation, not scheduled cancellation or reversible cancel-renewal semantics.

### Unsupported branch guidance
- **D-17:** Unsupported lifecycle operations should fail with **typed, machine-readable errors** plus **one concrete next-step hint**.
- **D-18:** Runtime errors should stay concise and structured; docs, support-matrix prose, admin copy, portal copy, and example-host proof should expand that hint into fuller guidance.
- **D-19:** Avoid vague wording like `semantics vary by processor` when the library can state the exact truth, such as:
  - what the processor supports
  - what Accrue does not support first-party
  - what the host should do instead
- **D-20:** Unsupported Braintree period-end and reversal branches should point users toward either:
  - immediate cancellation when that is the intended hard-stop behavior
  - an explicit host-owned non-renewal / access-policy seam when the product wants a softer end-of-term experience

### Host seams and touched UX
- **D-21:** `examples/accrue_host` should model host-owned cancellation policy explicitly instead of implying that the generic Accrue facade already owns every cancellation posture equally across processors.
- **D-22:** Touched customer/admin surfaces should gate or branch actions by processor capability instead of rendering unsupported Braintree period-end flows as if they were executable.
- **D-23:** Phase 110's least-surprise posture still applies to wording: where scheduled-end behavior is truly supported, customer-facing copy should prefer cancel-renewal / end-at-period-end language and keep immediate cancel exceptional.
- **D-24:** That least-surprise wording posture must **not** redefine the official runtime contract where Braintree cannot actually support the same behavior.

### Ecosystem and architecture lessons to preserve
- **D-25:** Keep the **Pay / Cashier** lesson: bounded multi-provider support works when the shared surface stays narrow and the docs admit divergence.
- **D-26:** Keep the **ActiveMerchant** warning: broad gateway sameness creates leaky abstractions, support burden, and semantic drift.
- **D-27:** Follow Elixir/Phoenix context design norms: explicit verbs, explicit typed failures, and host-owned policy seams where product semantics extend beyond a provider-backed adapter contract.

### GSD shift-left preference
- **D-28:** For future processor-track discuss/planning passes, default to **deep research plus one cohesive recommendation package** for low-impact implementation forks instead of reopening them interactively.
- **D-29:** Reopen decisions interactively only when they materially change:
  - public support promise
  - long-term public API surface
  - proof-lane philosophy
  - strategic processor boundary
- **D-30:** Current `.planning/config.json` already partially encodes this preference (`discuss_auto_resolve_low_impact`, `discuss_high_impact_confirm`, research-first defaults). Future GSD passes should continue honoring it.

### the agent's Discretion
- Exact lifecycle support-label wording, as long as it truthfully distinguishes immediate cancellation from scheduled-end support.
- Exact typed error code/message shape for unsupported Braintree scheduled-end flows, as long as the error stays machine-readable and carries one actionable next step.
- Exact example-host helper naming or copy split for host-owned non-renewal policy, as long as it remains clearly outside the official first-party processor contract.

</decisions>

<specifics>
## Specific Ideas

- Recommended contract story:
  - `cancel/2` = immediate hard-stop cancellation
  - `cancel_at_period_end/2` = explicit scheduled-end cancellation where supported
  - Braintree supports the first, not the second
- Recommended host-policy story:
  - if a product wants Braintree "non-renewing but still active until paid-through date" behavior, that is a host-owned policy layer, not generic Accrue parity
- Recommended error-story shape:
  - stable error code / type
  - short actionable hint
  - fuller provider-specific guidance in docs and touched UI
- Ecosystem lessons to preserve:
  - **Laravel Cashier** and **Pay** succeed by keeping explicit semantic paths and admitting provider divergence
  - **dj-stripe** shows how quickly one overloaded cancel surface accumulates caveats
  - **ActiveMerchant** remains the warning case for flattening too much gateway difference into one promise
- User preference captured explicitly:
  - research all meaningful options
  - synthesize one cohesive recommendation package
  - shift low-impact forks left into defaults
  - reopen only very impactful processor/API boundary choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and active contract truth
- `.planning/ROADMAP.md` — Phase 113 goal and success criteria
- `.planning/REQUIREMENTS.md` — `PROC-22` and `PROC-23`
- `.planning/STATE.md` — active milestone position
- `.planning/PROJECT.md` — project posture and bounded dual-provider philosophy
- `.planning/STRATEGY.md` — strategic parent for the dual-provider core track
- `.planning/research/ARCHITECTURE.md` — v1.36 integration points and build order
- `.planning/research/PITFALLS.md` — cancellation-scope and contract-drift risks
- `.planning/processor-support-matrix.md` — public support SSOT; current cancellation rows to normalize

### Prior locked context
- `.planning/milestones/v1.31-phases/096-chosen-second-provider-thin-slice/96-CONTEXT.md` — host-owned Braintree seam, bounded provider-honest surface, and shift-left preference
- `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md` — provider-honest support contract and co-update discipline
- `.planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md` — least-surprise lifecycle wording posture and explicit unsupported-branch guidance
- `.planning/phases/112-customer-update-contract-closure/112-CONTEXT.md` — recent processor-track shift-left preference and contract-closure posture

### Runtime facade and capability seams
- `accrue/lib/accrue/billing.ex` — public billing facade verbs (`cancel/2`, `cancel_at_period_end/2`, `resume/2`, `pause/2`)
- `accrue/lib/accrue/billing/subscription_actions.ex` — current cancellation semantics, event payloads, and unsupported-path behavior
- `accrue/lib/accrue/processor.ex` — capability facade (`supports?/1`, `support_label/1`, `first_party_supported?/1`)
- `accrue/lib/accrue/processor/capabilities.ex` — current lifecycle support-label map
- `accrue/lib/accrue/processor/stripe.ex` — Stripe cancellation capability truth
- `accrue/lib/accrue/processor/fake.ex` — Fake cancellation capability truth and deterministic proof behavior
- `accrue/lib/accrue/processor/braintree.ex` — Braintree cancellation truth and unsupported scheduled-cancel semantics
- `accrue/guides/custom_processors.md` — extension-point boundary and non-first-party warning

### Current lifecycle docs and teaching surfaces
- `accrue/guides/lifecycle_semantics.md` — lifecycle SSOT and current provider labels
- `accrue/guides/braintree-local-portal.md` — mounted Braintree path guide that currently teaches `cancel_at_period_end`
- `accrue/guides/portal_configuration_checklist.md` — Stripe scheduled-end posture and product rationale
- `examples/accrue_host/lib/accrue_host/billing.ex` — host-owned billing policy seam
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` — host-facing cancellation UX and wording
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — operator cancellation actions and capability-aware branching
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` — customer self-serve cancellation flow
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` — customer list-level self-serve cancellation flow

### Proof anchors
- `accrue/test/accrue/processor/capabilities_test.exs` — support-label proof
- `accrue/test/accrue/processor/braintree_test.exs` — Braintree capability and cancellation proof
- `accrue/test/accrue/billing/subscription_cancel_test.exs` — core cancel / cancel_at_period_end / resume semantics
- `accrue/test/accrue/billing_portal_test.exs` — lifecycle-guide and adjacent-doc proof
- `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` — portal cancellation behavior proof
- `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs` — portal list cancellation proof
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — admin cancellation-action proof
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` — host-facing cancellation wording proof

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Billing.cancel/2` and `Accrue.Billing.cancel_at_period_end/2` already exist as explicit public facade verbs.
- `Accrue.Processor.Capabilities` and `.planning/processor-support-matrix.md` already provide the executable + documentation seams for support truth.
- `examples/accrue_host/lib/accrue_host/billing.ex` already gives the project a host-owned policy seam for processor-aware decisions.
- Portal/admin copy seams and tests already exist, making it practical to gate unsupported Braintree flows instead of implying parity.

### Established Patterns
- The repo already prefers **provider-honest capability truth** over faux-uniform abstraction.
- Fake remains the deterministic merge-blocking proof lane; provider-backed behavior is bounded and explicit.
- Public-contract truth is maintained by co-updating code, docs, support-matrix prose, and tests in the same pass.
- Prior phases already locked a preference for **explicit unsupported guidance** instead of vague “semantics vary” messaging.

### Integration Points
- Phase 113 must align `subscription.cancel`, `subscription.cancel_immediately`, and `subscription.cancel_at_period_end` across:
  - adapter capability booleans
  - support labels
  - support matrix prose
  - lifecycle docs
  - touched portal/admin/example-host UX
- The Braintree local-portal guide and customer-facing flows are the main places where scheduled-end wording currently risks overstating runtime support.
- Any host-owned non-renewal seam must be documented as **outside** the official first-party processor contract.

</code_context>

<deferred>
## Deferred Ideas

- Broad public API rename or deprecation campaign around `cancel/2`, `cancel_now/2`, or `cancel_immediately/2`
- Billing-engine-owned local cancellation orchestration that simulates scheduled-end semantics for Braintree inside the core library
- Full lifecycle parity expansion for pause/resume/scheduled cancellation across Stripe and Braintree
- Any broader processor-surface redesign beyond this contract-closure milestone

</deferred>

---

*Phase: 113-cancellation-semantics-closure*
*Context gathered: 2026-05-06*
