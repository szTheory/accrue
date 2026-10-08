# Phase 236: Portal Billing Self-Service - Context

**Gathered:** 2026-10-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine the seven existing customer Portal pages and their existing payment-method, subscription, invoice, and checkout seams so customers can understand the billed entity and complete only supported self-service tasks. Keep the customer Portal inside the host's brand and permission boundary. Preserve the authenticated person as actor, the host-selected billable as owner, the Accrue Customer, processor, and action target as distinct identities.

This phase improves existing journeys. It does not add a provider, billing operation, local invoice/PDF route, organization model, universal account picker, role system, or new billing policy.

</domain>

<decisions>
## Implementation Decisions

Auto mode found the detailed Phase 236 requirements and accepted Phase 233/235 contracts already settle the product boundary. No new user preference was needed; the recommended defaults below carry those decisions forward.

### Billed identity, scope, and host branding

- **D-01:** Make the selected billed entity legible in the existing Portal journeys and keep its name distinct from the actor, product, Customer, and processor. Preserve host-owned selection and branding; personal-only installs continue to work without an organization model or account picker.
- **D-02:** Preserve fresh authorization for the same displayed billable and target across HTTP, LiveView mount/reconnect/events, and POST. Context pins identify the displayed context; they are not lasting grants. Do not fall back to a different account after an explicit selection or denial.

### Existing payment and subscription actions

- **D-03:** Expose only actions supported by the current provider, owner, and subscription state. List and detail entry points disclose the same consequence before confirmation, then reauthorize the exact target at mutation time. Do not imply provider parity or add a new billing capability.
- **D-04:** Describe observed subscription lifecycle accurately. Unknown or missing observations remain unknown; billing state does not promise host access, complete invoice counts, or document-retention guarantees.

### Invoice access, outcomes, and secure fields

- **D-05:** Show only existing invoices belonging to the authorized Customer and use the existing hosted-invoice access. Missing or unauthorized records fail safely. A failed read is a visible unavailable/error state, not an empty list.
- **D-06:** Direct add-card navigation must initialize the supported official Hosted Fields flow when authorized. Keep card data inside the provider SDK, clear single-use nonce/field state on failure or abandonment, and report only outcomes supported by server/provider evidence. Checkout failure must not claim a charge; query parameters do not prove payment; leaving checkout is not subscription cancellation.
- **D-07:** Keep host return destinations validated and local/host-approved, with the existing safe fallback. LiveView actions and POST/redirects provide visible, announced success or failure tied to the actual result.

### Verification posture

- **D-08:** Apply the project shift-left default: give every testable acceptance claim deterministic executable evidence at the cheapest credible seam; run stable recurring checks in merge-blocking CI when that protects ongoing behavior. Target zero human UAT. Hand off only an actual product decision, unavailable external/live-provider evidence, an irreversible external action, or irreducible subjective judgment, with the reason recorded. Do not reopen verified coverage without new evidence.

### the agent's Discretion

- Choose page hierarchy, concise copy, and component reuse that fit the established Portal patterns and host brand.
- Preserve the Phase 233 semantic visual roles and public `--accrue-*` Portal tokens. Cover the route-owned keyboard, 320 CSS pixel reflow, theme, focus, and reduced-motion states with current rendered/browser evidence where interaction or served assets are involved.
- Choose unit, LiveView, controller, property, and browser coverage by invariant and recurring maintenance value. Prefer existing deterministic fixtures and CI lanes; do not add a dependency or broad CI redesign without concrete evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary, requirements, and prior product decisions

- `.planning/ROADMAP.md` §Phase 236 — goal, dependencies, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — POR-01 through POR-07; POR-08 and SAFE-02/SAFE-03 define the established host and ownership boundary.
- `.planning/PROJECT.md` §§Current Milestone: v1.63 Admin and Portal UI refinement, Development Posture, and Verification posture — product guardrails, customer/host boundary, and automated acceptance posture.
- `.planning/STATE.md` — standing auto-first verification decision and the rule not to churn on verified closure without new evidence.
- `.planning/phases/233-shared-direction-portal-contract/233-CONTEXT.md` — accepted host resolve/authorize contract, identity separation, safe returns, and Portal boundaries.
- `.planning/phases/233-shared-direction-portal-contract/233-UI-SPEC.md` — semantic roles, host branding, responsive, keyboard, focus, theme, and motion baseline.
- `.planning/phases/234-admin-customers-subscriptions/234-CONTEXT.md` — current milestone interaction, accessibility, and evidence conventions; do not import Admin-only scope.
- `.planning/phases/235-customer-plan-selection-checkout/235-CONTEXT.md` — checkout evidence, safe return, Hosted Fields, and shift-left verification decisions.
- `.planning/notes/2026-10-07-portal-billable-context-contract.md` — host-selected billable, fresh action authorization, actor attribution, and capability rules.
- `.planning/notes/2026-10-07-accrue-ui-refinement-scope.md` §§2, 4–9, 12 — source findings, phase allocation, interaction baseline, and evidence strategy.
- `.planning/processor-support-matrix.md` — existing processor-specific support and limits.
- `PRODUCT.md` — actor, customer, host, and product boundaries.

### Portal implementation and proof seams

- `accrue_portal/lib/accrue_portal/router.ex` — seven existing LiveView routes and four existing POST routes.
- `accrue_portal/lib/accrue_portal/context.ex`, `authorize.ex`, `auth_plug.ex`, `auth_hook.ex`, and `customer_session.ex` — shared identity resolution and authorization boundaries.
- `accrue_portal/lib/accrue_portal/billing_read_model.ex` and `live/` modules — existing customer-scoped reads and page behavior.
- `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` and `controllers/checkout_controller.ex` — existing mutation and redirect paths.
- `accrue_portal/priv/static/accrue_portal.js` and `accrue_portal/priv/static/accrue_portal.css` — package-served secure-field hooks and Portal styling.
- `accrue_portal/test/accrue_portal/` — current route, ownership, LiveView, and controller proof patterns.
- `examples/accrue_host/e2e/` — current served-host browser fixture and provider-lane patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Portal.Router` already mounts Home, subscriptions list/detail, payment-method list/add, invoices, checkout, and a blocked route, plus the existing payment-method and checkout POST actions.
- `AccruePortal.Authorize`, the context adapter, and signed context pin preserve the host-selected billed entity and fresh per-action checks.
- Existing Portal LiveViews and `AccruePortal.Copy` provide customer-facing lifecycle, confirmation, status, and feedback patterns to refine.
- `BraintreeHostedFields` in `accrue_portal/priv/static/accrue_portal.js` owns secure-field initialization, tokenization, submission, and teardown.
- Portal LiveView, controller, tenant-isolation, and canonical-host Playwright tests provide starting points for deterministic evidence.

### Established Patterns

- Portal reads and mutations must stay bound to the same authorized Customer/provider/owner; a forged ID or stale pin cannot switch the target.
- Provider-hosted invoice/checkout surfaces remain outside Portal markup; the Portal can control only its own handoff and return behavior.
- Visible state and announcements must be tied to observed outcomes. Missing data, failed reads, denied actions, and empty results are distinct.
- Portal assets are package-served and host-compiled; source-only assertions do not prove that the mounted host serves the current CSS/JS.

### Integration Points

- Host authentication and billable selection feed the shared Portal context; each owned route and mutation consumes that context.
- The example host supplies deterministic owner, subscription, invoice, payment-method, and Braintree fixtures for current-render browser checks.
- Existing CI and browser lanes should own recurring checks when a stable acceptance contract benefits future changes.

</code_context>

<specifics>
## Specific Ideas

- The user asked GSD to reduce verification toil: automate integration, E2E, smoke, and seam checks in CI when they provide recurring value, and hand back only irreducible verification. This preference is recorded in `.planning/STATE.md` and is part of this phase's acceptance approach.
- Keep page-specific hierarchy appropriate to the task while carrying forward the shared Portal visual contract; do not force an Admin layout onto customers.

</specifics>

<deferred>
## Deferred Ideas

No new capability was added during discussion. New providers, new Portal routes/actions, account discovery/role policy, local invoice detail/PDF, and unrelated host-page redesign remain outside this phase.

</deferred>

---

*Phase: 236-portal-billing-self-service*
*Context gathered: 2026-10-08*
