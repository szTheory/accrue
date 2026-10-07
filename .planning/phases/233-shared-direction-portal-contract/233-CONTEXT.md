# Phase 233: Shared Direction & Portal Contract - Context

**Gathered:** 2026-10-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish an inspectable, current-source baseline for the existing Admin and customer Portal journeys; define a shared semantic visual direction that preserves Admin identity and host customer branding; and settle the bounded, optional host contract by which the single Portal resolves a billed entity and freshly authorizes its actions.

This phase includes the current route/flow/component/state inventory, representative current served renders, shared role and accessibility criteria, the Portal context boundary, and matching canonical example/adopter guidance. Route-family refinements belong to Phases 234–238 and integrated coverage/handoff belongs to Phase 239. This does not add billing/provider capabilities, a universal account picker or role system, a new auth/runtime dependency, a shared UI framework, operator impersonation, or dynamic processor routing.

</domain>

<decisions>
## Implementation Decisions

### Shared visual foundation and baseline

- **D-01:** Share semantic visual meanings and acceptance criteria across Admin and Portal, while keeping package-owned token APIs, asset delivery, brand identity, shells, and audience-specific layouts/control density. Admin remains the operator surface; Portal remains host-branded customer self-service. Do not make Portal depend on Admin or import a single shared stylesheet just to align colors.
- **D-02:** Preserve the existing Admin --ax-* system and public core/Portal --accrue-* token names. Use small local mappings/adapters only where inspection shows a real mismatch. Do not rename public tokens, duplicate a large token catalog, add a dependency, or build a standalone design-system project.
- **D-03:** Establish a concise canonical DESIGN.md direction for semantic roles, typography/spacing targets, color-independent state cues, focus, motion, reflow, host-brand boundaries, and token ownership. Keep route-specific hierarchy and workflow decisions in their owning phases and scoped UI contracts.
- **D-04:** First record the current source/route/flow/component/state inventory and distinguish it from historical captures. Inspect representative served Admin and Portal renders from the canonical host before asserting visual behavior; include source and asset provenance. Saved July screenshots and old pass counts are historical evidence, not proof of today's rendered tree. No browser render, build, or application test was run during this discussion.
- **D-05:** Keep accessibility expectations observable: status is not conveyed by color alone; visible text, labels and feedback are clear; keyboard focus remains visible; host accents are checked against relevant foreground/control contrast; layouts reflow without losing essential billing facts or actions; dynamic denial/result messages are exposed to assistive technology. This is a target for the owning slices, not a certification claim.

### Billed identity and account switching

- **D-06:** Keep the selected billed entity visibly named throughout Portal billing pages and action confirmations, using host-provided display metadata. Make that name distinct from the host product brand, authenticated person, Accrue Customer, and processor. Long/duplicate names must remain understandable. Escape/render the value as presentation data; it never grants authorization.
- **D-07:** Keep personal-only use plain and compatible: no synthetic organization, required company vocabulary, or account picker. For mixed or organization/custom hosts, offer an optional link to the host's existing account selector when supplied. Account discovery and selection remain host-owned; do not embed a universal Portal selector.
- **D-08:** Use one optional Portal integration contract with two responsibilities: resolve the authenticated human actor's authorized billable context and authorize each named action against its server-loaded target. The exact callback names/signatures and context envelope remain implementation decisions for the researcher/planner; do not publish an API shape until current call sites and transport needs are reconciled.
- **D-09:** Preserve the existing authenticated-person billable behavior when no adapter is configured. For custom contexts, keep actor, billable, Accrue Customer, processor, and target distinct; do not override current_user to mean a company or hardcode host role names. Select the exact owner-type + owner-ID + processor Customer identity.
- **D-10:** Resolve the intended context and authorize the relevant read before any Customer provisioning/provider write. A denied, missing, deleted, explicit-invalid, or unavailable selection never falls back to personal billing, a first organization, another Customer, or operator scope. An authorized but unprovisioned billable remains distinct from denial/unavailability.
- **D-11:** Reuse one consistent resolution/authorization boundary for initial HTTP, LiveView mount/reconnect/events, protected navigation, and all four Portal POST paths. Host policy is checked freshly at the action boundary; a cached display permission or preview is never authority. Existing Customer/resource ownership and provider capability guards remain in force. Keep the actual human actor in operation attribution.
- **D-12:** Display names and switch/return destinations are host presentation/navigation inputs, not authority. Validate local return destinations and preserve existing provider-specific hosted-vs-mounted boundaries. A query parameter, Portal token, preview, or already-rendered control cannot establish payment or permission.

### Open forms, account changes, and lost access

- **D-13:** Pin each open form, preview, confirmation, and checkout to the billed entity/Customer/processor it visibly names. Reauthorize that same context and target immediately before action. Separate tabs may retain independently pinned contexts while the host still authorizes them; a context change must never retarget an old form.
- **D-14:** A switch begins a fresh context. Clear pending confirmations/previews and secure payment-field state when that flow is abandoned or its authorization/context is invalidated. Preserve only harmless navigation state when it still refers to the same displayed billable. Never auto-replay a denied or uncertain payment mutation.
- **D-15:** Distinguish unauthenticated access from an authenticated actor whose selected billable is no longer available. Use a clear, generic blocked/unavailable state that does not disclose another account's existence. Offer the host-provided switch/return link when present; use existing safe host login/return behavior for unauthenticated requests and a non-looping safe Portal/host fallback otherwise. Do not add a separate recovery-URL callback/configuration knob absent an adopter case the existing host link cannot serve.
- **D-16:** On a denied mutation, say the change was not submitted; do not imply a charge or success. Clear secure card fields/nonces and mutation payloads; do not retry automatically. Announce in-place status changes accessibly; for a navigated blocked page, provide a clear heading and predictable focus destination.
- **D-17:** Apply host fresh authorization on reconnect and protected events/POSTs as well as initial render. Permission revocation stops later action, but does not imply atomic rollback of a remote payment already accepted by a provider; report only actual server/provider evidence.

### the agent's Discretion

- Choose the smallest maintainable callback/context shape after tracing the current HTTP, LiveView and POST paths. Prefer existing Phoenix/session mechanisms and short local code over another dependency; add a dependency only for a demonstrated capability/maintenance benefit. Do not hand-roll payment security or replace the official payment SDK boundary.
- Decide whether the visible label uses “Billing for [host name]” or an equally clear host-appropriate phrasing, and where to place secondary owner metadata, as long as the billed entity is clear across pages/confirmations and does not become authority.
- Choose representative route/state renders and a bounded source-inventory format that prove current served behavior without repeating every route across every theme, role, viewport, and state.
- Reuse the canonical host's existing organization selection and policy. Demonstrate personal defaults plus organization/custom and mixed examples without making Cadence's roles or model shape a library requirement.
- If a dedicated host recovery destination appears necessary, first demonstrate why the existing optional switch/return path is insufficient; keep it out of the first public contract by default.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and approved product decisions

- .planning/ROADMAP.md §Phase 233 — phase goal, scoped requirements, and success criteria.
- .planning/REQUIREMENTS.md — BASE-01, SYS-01, SYS-02, POR-08, SAFE-02, SAFE-03, SHIP-04; these are the binding milestone requirements for this phase.
- .planning/PROJECT.md §Current Milestone v1.63 — adopted scope, architecture ownership, reopen decision, and guardrails.
- .planning/notes/2026-10-07-accrue-ui-refinement-scope.md §§1–6, 9–12 — accepted audience/visual/product boundaries, current-source findings, proposed phase allocation, automation and accessibility posture, and authority/evidence index.
- .planning/notes/2026-10-07-portal-billable-context-contract.md §§Recommendation, Small integration contract, Permission and lifecycle rules, Customer experience and example coverage, Milestone implications — detailed host-owned resolution/authorization boundary and failure cases.
- PRODUCT.md — product and audience boundaries, actor/billable distinction, brand and accessibility commitments.
- .planning/processor-support-matrix.md — processor-specific capability boundaries; do not imply provider parity.

### Visual identity and package ownership

- .impeccable/config.json — code-first design preference.
- .planning/milestones/v1.52-phases/180-brand-audit-dna-lock/BRAND-DNA.md — ratified Admin identity and brand constraints.
- brandbook/voice.md — established product voice.
- accrue_admin/assets/css/theme.css and accrue_admin/assets/css/app.css — current Admin token/visual system and package CSS ownership.
- accrue/priv/static/brand.css — stable public --accrue-* token and host-brand bridge.
- accrue_portal/priv/static/accrue_portal.css — buildless Portal presentation consuming host-overridable tokens.
- accrue_admin/README.md and accrue_portal/README.md — current package ownership, mounting, assets, and adopter instructions. The Portal README's current user-bound customer wording must be reconciled with the approved optional adapter before claiming mixed support.

### Existing Portal and canonical host integration seams

- accrue_portal/lib/accrue_portal/router.ex — seven Portal LiveViews, four POST routes, mount/session/hooks and HTTP/LiveView boundaries.
- accrue_portal/lib/accrue_portal/customer_session.ex, auth_plug.ex, auth_hook.ex, and authorize.ex — current authenticated-user Customer resolution, request/mount assigns, and Customer-scoped reads.
- accrue_portal/lib/accrue_portal/billing_read_model.ex — existing Customer-scoped Portal data access.
- accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex and checkout_controller.ex — existing mutation entry points.
- accrue/lib/accrue/billing/customer.ex — Customer ownership identity and provider field.
- examples/accrue_host/lib/accrue_host/accounts/scope.ex, organizations.ex, and billing.ex — host actor/current-organization and billing-policy examples.
- examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex and user_auth.ex — existing host-owned organization selection, denial, login, and return behavior.
- examples/accrue_host/lib/accrue_host_web/router.ex — canonical package mounts and host route boundaries.
- examples/accrue_host/e2e/verify01-org-switching.spec.js — existing browser evidence and patterns for host organization switching; verify current applicability at planning time.

### Primary external guidance consulted

- [Phoenix LiveView security considerations](https://phoenix-live-view.hexdocs.pm/1.2.9/security-model.html) — HTTP and LiveView mount/session validation are separate; authorize event payloads and protected resource actions.
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) — deny by default and validate permission on every request/resource.
- [W3C WCAG 2.2: Labels or Instructions](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html), [Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html), [Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html), and [Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) — visible labels, announced dynamic feedback, non-color status cues, and responsive content expectations.
- [GOV.UK Design System tag guidance](https://design-system.service.gov.uk/components/tag/) — useful comparison for status tags that do not rely on color alone; a precedent, not an Accrue dependency or required visual template.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Admin already has a scoped --ax-* theme, components, hook implementations for navigation/overlays/focus and extensive route/browser fixtures. Preserve these package-owned facilities and investigate their real consumers before replacing anything.
- Portal already has buildless local CSS/JS, host brand/theme plugs, a root layout, secure Hosted Fields hooks, and seven route-specific LiveViews. Core's --accrue-* public brand tokens support host overrides.
- The canonical host has a current organization selection controller/session and Accounts.Scope, plus host-owned policy in AccrueHost.Billing; reuse these semantics as the example without exporting its role names or schema assumptions into Portal.

### Established Patterns

- Portal's current CustomerSession.resolve/2 maps the authenticated user directly to a Customer. AuthPlug resolves the existing Customer for HTTP/POST access; AuthHook resolves again for LiveView; Authorize scopes resources to the assigned Customer.
- The Portal router puts host on_mount hooks before its default Customer hook. A host assign override alone cannot become the consistent authorization path for HTTP, LiveView reconnect/events, and POST requests.
- Portal GET/POST ownership checks and processor guards remain necessary after host authorization. Select the exact owner type, lossless owner ID, and configured processor; do not broaden to dynamic processor selection.
- Portal CSS is embedded/served by its package asset mechanism; there is no Tailwind build step for the Portal. Admin asset builds do not prove that Portal assets were recompiled and served.
- In the example, active organization selection is host-owned and denial already uses a generic unavailable message. The existing host behavior is a starting point, not proof the new Portal adapter is implemented.
- No .planning/codebase/ maps or prior phase context files existed for this phase, so the scout used current package/host source directly.

### Integration Points

- The host context boundary must supply the authenticated actor and authorized billable independently. Customer materialization, display metadata, current processor, action intent, target ownership, and actor attribution must remain distinguishable.
- Use the same safety semantics through Portal initial HTTP, LiveView mount/reconnect/events, and POST paths: payment-method create, set-default, delete, and checkout completion.
- The canonical example/adopter docs must show personal defaults plus organization/custom and mixed resolution while continuing to let each host own authentication, selection, membership, and policy.
- Host return/switch links must remain local/safe and never become an authorization input. Provider-hosted billing pages and payment-field SDKs retain their existing security/capability boundaries.

</code_context>

<specifics>
## Specific Ideas

- The user asked for a broad, adversarial specialist review across product, customer/operator, host-developer, security, accessibility, frontend, and package-maintenance lenses; to compare tradeoffs, use reputable primary sources, prefer a small/flat dependency tree, and synthesize recommendations. All available phase areas were selected; recommendations were resolved using the user's explicit delegation to use judgment.
- Independent reviews converged on: share semantic roles, not shells; show the billed entity persistently with an optional host-owned switch link; pin every open flow to its displayed billable/customer/provider; and fail closed with a generic, accessible recovery state when that context becomes unavailable. A separate recovery callback was not justified by current host evidence.
- The user prefers understandable local code or a small copied pattern over adding a dependency when both meet the need. The official payment SDK boundary is an intentional exception and must remain.
- No current rendered baseline was produced during this discussion. Any future design/implementation claim must come from current served output and correctly rebuilt package assets, not a saved historical screenshot.

</specifics>

<deferred>
## Deferred Ideas

- No new product capability was requested. A distinct Portal recovery-URL API, universal account selector/role model, shared component framework, and global cross-tab account-selection system remain out of scope unless concrete adopter evidence reopens them.
- Keep route-specific redesign/action behavior in Phases 234–238 and integrated all-route coverage/handoff in Phase 239.

</deferred>

---

*Phase: 233-shared-direction-portal-contract*
*Context gathered: 2026-10-07*
