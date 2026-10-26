---
phase: "235"
slug: "customer-plan-selection-checkout"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-08"
reviewed_at: "2026-10-08"
---

# Phase 235 — UI Design Contract

> Contract for selected-plan checkout and its visible browser states. Inherits Phase 233's semantic roles and current host branding; Phase 235 context decisions are locked defaults.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | none; existing Phoenix LiveView/HEEx and package-owned markup |
| Icon library | Existing inline/glyph treatment; no new dependency |
| Font | Portal host-provided font when configured, otherwise existing system sans stack |

Keep checkout in the existing Portal shell and `--accrue-*` token bridge. Preserve current host branding and asset ownership. Do not add a design system, component catalog, dependency, generic plan catalog, or broad interaction scope. Stripe/provider-hosted checkout navigates to the provider-owned surface; Braintree checkout remains mounted in Portal with official Hosted Fields iframes. Do not make these paths look like interchangeable capabilities.

---

## Spacing Scale

Use Phase 233's shared 4px-multiple scale; package tokens remain package-owned.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon/text gaps |
| sm | 8px | Compact label/control spacing |
| md | 16px | Default content and control spacing |
| lg | 24px | Checkout card sections |
| xl | 32px | Major layout groups |
| 2xl | 48px | Page-level separation |
| 3xl | 64px | Large page breaks where layout permits |

Exceptions: Existing Portal buttons/navigation retain at least 40px height; icon-only controls use at least 44px. Do not shrink secure field controls below the existing usable target.

---

## Typography

Inherit the four-size, two-weight Phase 233 contract and existing host font mapping.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Metadata / eyebrow | 12px | 600 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Page heading | 26px | 600 | 1.2 |

Keep plan name, amount/currency, interval, promotion effect, and billed-entity name readable as separate facts. Use the 16px body/control target for Hosted Fields surrounding labels and feedback. Long names and terms wrap without hiding payment facts or actions.

---

## Color

Use semantic Portal roles and the active host theme; percentages describe hierarchy, not fixed hex shares.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--accrue-surface-muted` | Portal checkout page background |
| Secondary (30%) | `--accrue-surface` | Checkout summary, form grouping and raised surfaces |
| Accent (10%) | Host `--accrue-brand-accent` plus readable `--accrue-brand-accent-text` / `--accrue-brand-accent-contrast` bridge | Primary checkout action, selected offer emphasis, links and visible focus |
| Destructive | Existing readable semantic danger role | Error or destructive action only; never success/pending state |

Accent reserved for: the single primary checkout action, selected offer marker, actionable links, and visible keyboard focus. Do not paint every input or interactive element with the accent. Preserve explicit text and shape cues for pending, declined, canceled, unavailable, and complete states; color alone never conveys a payment result. Check host accent foreground and focus contrast against the computed theme.

---

## Copywriting Contract

Use concise existing Portal voice. Display trusted selected-offer terms from persisted server session/catalog data only; never derive them from a browser parameter or price ID. If a material term is missing or ambiguous, identify it as unavailable, disable payment, and provide safe recovery. Never render missing price as zero.

| Element | Copy |
|---------|------|
| Primary CTA | “Pay {verified total}” (mounted Braintree; use the existing amount-aware checkout CTA); hosted-provider branch action: “Continue to secure checkout” |
| Empty state heading | “Plan details unavailable” |
| Empty state body | “We couldn't verify the selected plan and its billing terms. Return to the app and choose a plan again.” Link/action: “Return to your app” when a validated host destination exists; otherwise use the existing safe fallback. |
| Error state | State the evidenced outcome and next step. For a rejected-before-submit action: “Your payment wasn't submitted. Check the details and try again.” For uncertain outcome: “We couldn't confirm whether your payment went through. Check your billing status or contact support before trying again.” No automatic retry. |
| Destructive confirmation | None added in this phase. Leaving/canceling checkout is navigation, not a payment mutation; clear Hosted Fields and nonce state when abandoned. |

On authoritative completion, use the existing host/Portal completion wording only after server/provider evidence confirms completion. Keep provider cancellation, expired/completed session, stale promotion, declined/rejected request, and uncertain outcome distinct. Return destinations are validated navigation inputs, not payment evidence. Do not display Fake-backed evidence as live-provider parity.

---

## UI Considerations

Applicable state considerations resolved: 16 covered, 0 backstop, 0 unresolved.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | mounted checkout form and selected-offer summary | ✅ covered | If a trusted material term is missing or ambiguous, show the documented unavailable state, disable payment, and provide validated recovery; never infer a zero price. |
| loading | mounted checkout form and selected-offer summary | ✅ covered | Announce tokenization/submission progress, keep the initiating action pending, prevent duplicate submission, and retain the selected offer and billable context. |
| error | mounted checkout form and selected-offer summary | ✅ covered | Keep invalid input, stale promotion, expired/completed session, and provider rejection distinct; display only evidence-supported outcome copy and allow retry only as a fresh authorized action. |
| populated | mounted checkout form and selected-offer summary | ✅ covered | Render the host-selected plan name and trusted available charge terms alongside the secure form; preserve the same selection and billed entity through sign-in and return. |
| partial | mounted checkout form and selected-offer summary | ✅ covered | Clearly identify each unavailable material term and prevent payment while any required charge term is unknown. |
| overflow | mounted checkout form and selected-offer summary | ✅ covered | At 320 CSS px and 400% zoom, keep price, currency, interval, labels, feedback, and actions readable with no page-level horizontal scrolling. |
| zero-one-many | mounted checkout form and selected-offer summary | ✅ covered | Show exactly the offer selected by the host. Missing selection goes to recovery; never substitute a default or expose a plan catalog. |
| long-text | mounted checkout form and selected-offer summary | ✅ covered | Long plan/billable names and provider-safe messages wrap without clipping or overlapping Hosted Fields, price, status, or recovery actions. |
| loading | provider-hosted handoff and validated return navigation | ✅ covered | Make the provider handoff action and pending navigation state clear; a return URL remains navigation only and cannot establish completion. |
| error | provider-hosted handoff and validated return navigation | ✅ covered | Cancellation, unavailable return, and blocked context remain distinct; display completion only after authoritative server/provider evidence. |
| overflow | provider-hosted handoff and validated return navigation | ✅ covered | At 320 CSS px and 400% zoom, keep the handoff/recovery action and its destination context visible without horizontal page scrolling. |
| long-text | provider-hosted handoff and validated return navigation | ✅ covered | Long host/provider names and destination guidance wrap without hiding the handoff or recovery action. |
| loading | checkout outcome and recovery feedback | ✅ covered | Announce pending and in-place feedback to assistive technology while keeping the selected offer context visible. |
| error | checkout outcome and recovery feedback | ✅ covered | Declined, canceled, expired, stale, completed, unavailable, and uncertain outcomes remain evidence-specific; uncertain results direct customers to billing status/support and never auto-replay. |
| overflow | checkout outcome and recovery feedback | ✅ covered | At 320 CSS px and 400% zoom, preserve status text, essential billing context, and the available next action without overlap or page-level horizontal scrolling. |
| long-text | checkout outcome and recovery feedback | ✅ covered | Long outcome and recovery guidance wraps and remains associated with its heading/action without obscuring payment facts. |

The 16 state criteria are explicit acceptance truths and must have executable coverage in the plans; empty/error copy remains defined in `## Copywriting Contract` above.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable; no shadcn initialization or third-party registry blocks |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: FLAG — primary visual anchor not named; reviewer recommends declaring it
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS — Tool none, component inventory omitted

**Approval:** approved 2026-10-08; one non-blocking visual hierarchy recommendation recorded above.
