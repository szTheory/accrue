---
phase: "236"
slug: "portal-billing-self-service"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-08"
---

# Phase 236 — UI Design Contract

> Carries the approved Phase 233 Portal visual contract into Portal billing self-service. Decisions below use `236-CONTEXT.md`, `233-UI-SPEC.md`, `REQUIREMENTS.md`, and inspected Portal source. This is an implementation contract, not evidence that this phase's acceptance criteria have been verified.

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | Phoenix LiveView/HEEx and existing `AccruePortal.Layouts` components; no external component library |
| Icon library | Existing inline/glyph treatment; add no icon dependency |
| Font | Host-provided `--accrue-brand-font` when configured, otherwise the existing system sans stack |

Keep the host-branded Portal shell and package-served `--accrue-*` semantic roles. Reuse the current Portal card, list, status, action, empty-state, inline-error, breadcrumb, and Hosted Fields patterns. Do not add a framework, dependency, token catalog, Admin layout, or local invoice/PDF surface. Keep the authenticated actor, selected billable display name, Accrue Customer, and processor distinct in page copy and confirmation context.

## Spacing Scale

Use the established Phase 233 scale; package-local mappings remain authoritative.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon/text gaps |
| sm | 8px | Compact labels and control spacing |
| md | 16px | Default content and control spacing |
| lg | 24px | Card sections and related groups |
| xl | 32px | Major layout groups |
| 2xl | 48px | Page-level separation |
| 3xl | 64px | Large page breaks where layout permits |

Exceptions: preserve current Portal control minimum height of 40px; icon-only controls, if introduced, require a 44px target. At 320 CSS px, retain every essential billing fact and action without page-level horizontal scrolling.

## Typography

Use the four shared sizes and two weights declared by Phase 233. Portal body and controls remain at least 16px.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Metadata / eyebrow | 12px | 600 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Page heading | 26px | 600 | 1.2 |

Long billed-entity names, subscription identifiers, dates, and error text wrap or use deliberate disclosure; do not truncate essential billing facts.

## Color

Percentages express visual hierarchy; host theme values remain token-driven, not fixed hex values.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--accrue-surface-muted` | Portal page and shell background |
| Secondary (30%) | `--accrue-surface` | Cards, list groupings, and raised content |
| Accent (10%) | Host `--accrue-brand-accent` with readable `--accrue-brand-accent-text` / `--accrue-brand-accent-contrast` bridge | Reserved for one primary action per task group, links, active/selected navigation, and visible focus |
| Destructive | Readable semantic danger role; existing neutral text plus explicit status where needed | Cancellation and payment-method removal consequences, and destructive error status only |

Accent reserved for the specific elements named above; do not apply it to every interactive control. Compute contrast against the effective host theme, including bright custom accents. Statuses include a text label and may include a shape cue; color alone never conveys billing state. Meet 4.5:1 for normal text, 3:1 for large text and essential control/focus boundaries.

## Copywriting Contract

Use `AccruePortal.Copy` and established route-specific language where it exists. Do not claim a charge, provider rollback, host access, complete invoice count, or document retention unless the observed source establishes it.

| Element | Copy |
|---------|------|
| Primary CTA | “Manage subscriptions” for the home task; on each page retain one visually primary next action, using existing route copy such as “Add a card” or “Save card” where applicable |
| Empty state heading | “No active subscriptions” |
| Empty state body | “You don't have any active subscriptions on this account. When you subscribe to a plan, it will appear here.” Preserve other existing route-specific empty copy for payment methods and invoices. |
| Error state | For unavailable selected billing context: “Billing access unavailable”. “We couldn't open billing for the selected account. Choose an account in your app and try again.” Provide “Return to your app” when host return is available. For failed reads, show an explicit unavailable/error state, never an empty list. For denied changes, say the change was not submitted and provide a safe retry or navigation path. |
| Destructive confirmation | Cancel subscription: reuse the processor-specific `AccruePortal.Copy` explanation of immediate cancellation or scheduled non-renewal and access timing; require explicit confirmation before mutation. Delete card: disclose that the selected card will be removed and require explicit confirmation. On denial, state the change was not submitted. |

The billed-entity name stays visible on billing pages and action confirmations when provided. It is host-owned presentation data, distinct from the signed-in actor and product brand, and grants no authority. A host-provided account-switch link is optional; never invent an account picker or organization requirement.

## Interaction Contract

- Render the same consequence and target on list and detail entry points before asking for confirmation. Offer only actions supported by the current owner, provider, and subscription state; reauthorize the exact target at mutation time.
- Subscription labels distinguish known `trialing`, `incomplete`, `unpaid`, `past_due`, `active`, and canceled states. Unknown observations remain unknown. Billing lifecycle wording does not promise application access.
- Payment-method list actions identify the card (brand/last four) and whether it is default. Default/removal outcomes are visible and announced after the actual POST result. Never expose token or full card data.
- Invoice access links to the existing hosted invoice for the authorized Customer. Missing and unauthorized records fail safely; do not imply local invoice details or retained documents.
- Direct add-card navigation initializes only the supported official Hosted Fields flow. Keep labels and help/error text visible across host light/dark/system themes and LiveView patches. Clear nonce and field state on failure, denial, or abandonment; do not submit without a valid nonce.
- LiveView feedback remains visible and announced after actions. Use polite status announcements for routine outcomes and alert semantics for urgent errors. Focus remains visible and moves predictably when a result replaces or removes its trigger.
- Return destinations use validated host-approved/local targets and the existing safe fallback. Query parameters never prove payment; leaving checkout is not subscription cancellation; checkout failure never asserts a charge.
- Keyboard users can complete route navigation, forms, confirmation, and recovery using Tab, Shift+Tab, and Escape. Honor reduced-motion preferences; no result may depend on animation.

## UI Considerations

Applicable shape-rooted state considerations resolved: **6 covered, 2 backstop, 0 unresolved — 8 total**. This maps the existing Portal collections, forms, navigation, and content; verification remains owned by Phase 236 execution.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Home, subscription/payment/invoice collections, unfilled add-card form | ✅ covered | Keep route-specific empty copy and supported next steps; an unfilled secure form cannot submit an absent nonce. A failed read is never rendered as empty. |
| loading | LiveView mutations, Hosted Fields, checkout handoff | 🧪 backstop | Keep pending state on the initiating control, prevent duplicate submission, and preserve usable form labels through pending/reconnect states. Verify using served browser evidence. |
| error | Billing reads, unavailable/denied context, LiveView and POST/redirect outcomes | 🧪 backstop | Distinguish login, blocked context, denial, missing record, and failed read. Show and announce only actual server/provider outcomes; provide safe recovery without disclosing another Customer or auto-retrying. |
| populated | Seven Portal routes and hosted invoice access | ✅ covered | Keep each view scoped to the same authorized Customer/provider and selected billed entity; invoices remain hosted by the existing provider surface. |
| partial | Subscription lifecycle, invoice metadata, payment form | ✅ covered | Missing observations stay unknown; missing optional data cannot imply inactive state, zero price, host access, document retention, or payment success. |
| overflow | Portal pages at 320 CSS px and 400% zoom | ✅ covered | Preserve essential labels, billed identity, lifecycle facts, and controls without page-wide horizontal scrolling. |
| zero-one-many | Subscription, invoice, and payment-method collections | ✅ covered | Preserve distinct empty, singular, and multiple-item presentation and item-specific actions; never select another owner's first item as fallback. |
| long-text | Billed-entity names, identifiers, errors, hosted-field help | ✅ covered | Wrap or disclose long values; keep actions and field labels readable and separate identity from actor/brand. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable; Portal is Phoenix LiveView and no shadcn or third-party registry is used |

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: PASS (no design system; component inventory intentionally omitted)

**Approval:** pending
