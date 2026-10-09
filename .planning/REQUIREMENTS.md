# Requirements: Accrue v1.63 Admin and Portal UI refinement

**Defined:** 2026-10-07
**Core Value:** A Phoenix developer can install Accrue and its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, a tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version. Everything else is in service of that.

## v1.63 Requirements

Requirements for the Admin and Portal UI refinement milestone. Each maps to exactly one roadmap phase.

### Baseline and Visual System

- [x] **BASE-01**: Maintainers can inspect a current route, flow, component, and state inventory with evidence provenance; historical screenshots cannot stand in for current rendering.
- [x] **SYS-01**: Operators and customers see consistent visual roles, typography, spacing, layers, and control states across real package consumers, with superseded local overrides removed.
- [x] **SYS-02**: Admin and Portal share semantic design roles while retaining audience-appropriate layouts and their existing Admin identity or host customer branding, without a new UI dependency.

### Admin

- [x] **ADM-01**: Operators can distinguish a known subscription lifecycle from missing ancillary observations; missing data does not turn an active subscription into an inactive one.
- [ ] **ADM-02**: Operators can distinguish draft, open, and overdue invoices and see missing due dates honestly; amounts preserve currency and minor-unit precision, including zero- and three-decimal currencies.
- [x] **ADM-03**: Operators can search, enter a nondefault owner scope, navigate customer/subscription/related records, and return without losing the correct owner, object, or filter context.
- [x] **ADM-04**: Operators can use only eligible subscription lifecycle actions, with existing confirmation, step-up, expiry, duplicate-protection, and truthful result-evidence behavior preserved.
- [x] **ADM-05**: Operators can review invoice payments/finalization and refunds with the exact amount, currency, and consequence, and distinguish accepted, requires-action, failed, and completed results.
- [ ] **ADM-06**: Operators can review recovery with its time window, owner, and currency intact, while historical failures remain distinct from current billing state.
- [ ] **ADM-07**: Operators can investigate events and webhook deliveries and replay only eligible deliveries with precise evidence, step-up, and honest partial-selection outcomes.
- [ ] **ADM-08**: Operators can inspect existing coupon, promotion-code, and Connect states and actions without the UI implying unsupported capabilities.

### Checkout

- [x] **CKO-01**: Customers can complete or recover from the visible checkout form through the actual browser payment hook, with valid, invalid, provider-failure, cancellation, and retry outcomes represented truthfully.
- [x] **CKO-02**: Customers receive distinct, capability-aware hosted-provider and mounted-checkout handoffs and safe returns; Fake evidence is not presented as live-provider parity.
- [x] **CKO-03**: Both reachable checkout submission paths handle expired or completed sessions, stale promotions, and repeated submissions according to the existing contract, without claiming an unproven charge or rendering missing price as zero.
- [x] **CKO-04**: Customers retain their plan choice through sign-in and return; displayed charge terms come from trusted available metadata, and unknown terms or outcomes lead to a safe recovery path instead of a guessed authorization or blind resubmission.

### Portal

- [x] **POR-01**: Customers can use all seven existing Portal pages and supported actions with legible, responsive content scoped to the selected billed entity and compatible with host branding.
- [x] **POR-02**: Customers can add, default, or remove supported payment methods and change or cancel eligible subscriptions without crossing account or provider capabilities; list and detail entry points disclose the same consequences before confirmation.
- [x] **POR-03**: Customers can reach existing invoice records and hosted invoice access for the correct Customer; missing and unauthorized records fail safely.
- [x] **POR-04**: Customers receive visible and announced outcomes after LiveView actions and POST/redirects; failed reads are not represented as empty lists and checkout failure does not assert a charge.
- [x] **POR-05**: Direct add-card navigation initializes the supported secure Hosted Fields flow, and its supported states remain readable across shell themes and LiveView patches.
- [x] **POR-06**: Customers see known trial, incomplete, unpaid, and canceled states accurately, without claims about host access, complete invoice counts, or unsupported retention/document availability.
- [x] **POR-07**: Customers return only to validated host destinations; query parameters cannot prove payment, and leaving checkout is not described as subscription cancellation.
- [x] **POR-08**: One Portal supports personal, organization/custom, and mixed host billing; personal-only installs need no company model or account picker, and customer billing managers receive no operator/Admin access.

### Interaction and Accessibility

- [ ] **INT-01**: Keyboard users can complete navigation and action flows with Tab, Shift+Tab, and Escape, including focus containment/restoration through patches, nested overlays, removed triggers, and reconnects.
- [ ] **INT-02**: People using narrow viewports, zoom, or coarse pointers can access essential content and actions at 320 CSS pixels without page-wide overflow or unusable controls.
- [ ] **INT-03**: Admin and Portal support light, dark, system, host-forced themes, representative accent and host-to-Portal theme handoff; repeated keyboard actions remain immediate and reduced motion removes nonessential motion.
- [ ] **INT-04**: Empty, no-match, unavailable, unsupported, denied, pending, error, and long-content states are covered deliberately at the least costly credible verification layer.

### Safety and Scope

- [x] **SAFE-01**: Mounted owner/customer denials and forged-action protections remain enforced; foreign records and payment-token data are not exposed.
- [x] **SAFE-02**: The optional host integration resolves the billed entity separately from the actor and freshly authorizes each action across HTTP, LiveView, and reconnect; invalid selections or unauthorized provisioning fail safely while the personal default remains compatible.
- [x] **SAFE-03**: Forms and checkout remain pinned to their displayed billable, Customer, and processor across tabs and account switches; lookups use full owner/provider identity and hosted-session grants do not exceed authorized actions.

### Delivery and Evidence

- [ ] **SHIP-01**: Generated Admin and Portal assets, fonts, mounts, CSP/SRI, copy exports, and host integration documentation match the source actually served by each package.
- [ ] **SHIP-02**: Every owned route and unique interaction has a coverage disposition supported by current required gates and inspected representative renders.
- [ ] **SHIP-03**: Component examples and adopter docs match production; task-owned debris is removed; a useful feedback preview remains separate from mutation/reset proof.
- [x] **SHIP-04**: Adopter documentation and the canonical example cover personal defaults plus organization/custom and mixed Portal resolution, while preserving actor attribution and requiring no new auth/runtime dependency.

## Future Requirements

This milestone adds no future feature commitment. Deferred capabilities require a separate trigger and milestone decision.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New processors, billing actions, checkout capabilities, or provider features | This milestone refines existing journeys and does not expand Accrue's billing/provider support boundary. |
| Core diagnosis/causality APIs, risk scores, Usage/meters, fee reconciliation, or new Admin rooms | These are deferred SEED-004 M2/M3 or separate product capabilities, not UI refinement requirements. |
| Universal tenancy, role management, account discovery/picker, consolidated payer arrangements, operator impersonation, or dynamic multi-provider routing | The bounded Portal integration leaves account selection and policy with the host and preserves one fixed Customer/provider target per action. |
| A Portal resume action, local invoice-detail/PDF route, or new payment/management behavior | These are not existing supported Portal journeys and were not accepted as new capabilities. |
| Unrelated example-host pages or redesign of provider-hosted pages | Only the named billing entry, handoff, and return seams are in scope; provider markup and theme remain external. |
| Rebrand, framework migration, forced common Admin/Portal shell, or a new density/settings mode | The work preserves the established Admin identity and customer host branding while refining existing patterns. |
| Homemade secure card inputs or replacing the official payment SDK for visual consistency | Provider tokenization and secure fields remain within their supported SDK boundary. |
| Paid visual evaluation, an endless aesthetic ratchet, or wholesale CI rearchitecture | Use existing deterministic tooling and finite named findings; add only evidence-backed checks needed for this milestone. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 233 | Complete |
| SYS-01 | Phase 233 | Complete |
| SYS-02 | Phase 233 | Complete |
| ADM-01 | Phase 234 | Complete |
| ADM-02 | Phase 237 | Pending |
| ADM-03 | Phase 234 | Complete |
| ADM-04 | Phase 234 | Complete |
| ADM-05 | Phase 237 | Complete |
| ADM-06 | Phase 237 | Pending |
| ADM-07 | Phase 238 | Pending |
| ADM-08 | Phase 238 | Pending |
| CKO-01 | Phase 235 | Complete |
| CKO-02 | Phase 235 | Complete |
| CKO-03 | Phase 235 | Complete |
| CKO-04 | Phase 235 | Complete |
| POR-01 | Phase 236 | Complete |
| POR-02 | Phase 236 | Complete |
| POR-03 | Phase 236 | Complete |
| POR-04 | Phase 236 | Complete |
| POR-05 | Phase 236 | Complete |
| POR-06 | Phase 236 | Complete |
| POR-07 | Phase 236 | Complete |
| POR-08 | Phase 233 | Complete |
| INT-01 | Phase 239 | Pending |
| INT-02 | Phase 239 | Pending |
| INT-03 | Phase 239 | Pending |
| INT-04 | Phase 239 | Pending |
| SAFE-01 | Phase 234 | Complete |
| SAFE-02 | Phase 233 | Complete |
| SAFE-03 | Phase 233 | Complete |
| SHIP-01 | Phase 239 | Pending |
| SHIP-02 | Phase 239 | Pending |
| SHIP-03 | Phase 239 | Pending |
| SHIP-04 | Phase 233 | Complete |

**Coverage:** 34/34 v1.63 requirements mapped exactly once.

---
*Requirements defined: 2026-10-07*
*Last updated: 2026-10-07 after Phase 233 completed seven requirements*
