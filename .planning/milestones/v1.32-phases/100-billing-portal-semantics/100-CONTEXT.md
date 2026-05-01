# Phase 100: Billing Portal Semantics - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 100 addresses the Braintree gap for `Accrue.Billing.create_billing_portal_session/2` (PROC-20). Stripe provides a Hosted Billing Portal which Accrue wraps perfectly; Braintree does not have a hosted equivalent. 

This phase must resolve how Accrue handles billing portal requests when the configured processor is Braintree. It defines the explicit boundary of Accrue as a headless backend API, choosing to document the creation of a local portal rather than shipping an opinionated LiveView UI engine within the core library.

This phase does **not** broaden into:
- Building or shipping a unified LiveView billing portal within the `accrue` package.
- Changing Accrue's architecture to depend on frontend frameworks for core billing flows.
- Providing a generic, multi-processor UI abstraction layer.
</domain>

<decisions>
## Implementation Decisions

### API Contract & Error Handling

- **D-01:** Accrue must remain a headless backend facade. It will not ship opinionated UI components (like LiveView) to polyfill missing gateway features like Braintree's lack of a hosted portal.
- **D-02:** `Accrue.Processor.Braintree` must explicitly reject `billing_portal: %{create: true}` in its capability map to reflect reality.
- **D-03:** `Accrue.Billing.create_billing_portal_session/2` must return an explicit, typed error when the underlying processor is Braintree: `{:error, %Accrue.APIError{code: :unsupported_by_gateway, message: "..."}}`.
- **D-04:** The error message should be helpful and point developers to the official Accrue documentation for building a local portal.

### Documentation & Developer Experience

- **D-05:** To bridge the DX gap without taking on UI maintenance, Accrue must provide a comprehensive, first-class guide (`guides/braintree-local-portal.md`).
- **D-06:** The guide must demonstrate exactly how to build a custom local portal in Phoenix/LiveView using Accrue's existing `Accrue.Billing` CRUD primitives (developed in Phases 97-99 for subscription mutations and payment method management).
- **D-07:** The documentation should be structured to mirror the capabilities of Stripe's portal, showing developers how to achieve parity in their host application.

### Shift-left preference for future GSD passes

- **D-08:** Maintain the precedent that Accrue is an API wrapper and domain modeler, not a UI framework. Future gateway integrations missing hosted UIs should follow this exact "explicit error + documentation recipe" pattern.
</decisions>

<specifics>
## Specific Ideas

- The `guides/braintree-local-portal.md` should include copy-pasteable LiveView snippets that interface with `Accrue.Billing.add_payment_method/3`, `swap_plan/3`, etc.
- The guide should explain why Accrue doesn't ship this UI (avoiding CSS framework lock-in, routing complexities, and security surface expansion).
- Update the ExDoc for `create_billing_portal_session/2` to mention that behavior depends on the processor's capabilities, explicitly noting Braintree's limitation and linking to the guide.
</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and locked context

- `.planning/milestones/v1.32-ROADMAP.md` — Phase 100 goal and success criteria (PROC-20)
- `.planning/research/v1.32-PHASE-100-ADVISOR.md` — The foundational architectural decision record validating the headless approach
- `.planning/PROJECT.md` — Core constraints (Accrue as an API, not a frontend framework)

### Public facade and processor seams

- `accrue/lib/accrue/billing.ex` — The facade containing `create_billing_portal_session/2`
- `accrue/lib/accrue/processor/braintree.ex` — The adapter that needs its capabilities and callbacks updated
- `accrue/lib/accrue/processor/capabilities.ex` — The capability map
- `accrue/lib/accrue/errors.ex` — The error taxonomy for `:unsupported_by_gateway`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `Accrue.APIError` struct and taxonomy already exist and are used for unsupported operations.
- The capability querying system (`Accrue.Processor.capabilities/1`) is already in place to gate features.

### Established Patterns
- Unsupported processor operations fail clearly rather than silently no-oping.
- Accrue relies on host applications for UI (like browser payment acquisition for Braintree), a pattern Phase 100 reinforces.
</code_context>

<deferred>
## Deferred Ideas

- A drop-in unified LiveView portal shipped as part of `accrue_admin` (rejected to maintain separation of concerns and avoid UI lock-in).
- Any attempt to render Braintree Drop-in UI directly from Accrue.
</deferred>

---

*Phase: 100-billing-portal-semantics*
*Context gathered: 2026-05-01*