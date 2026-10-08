---
phase: "236"
slug: "portal-billing-self-service"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-08"
reviewed_at: "2026-10-08T16:00:02Z"
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

Keep the host-branded Portal shell and package-served `--accrue-*` semantic roles. The current Portal card, list, status, action, empty-state, inline-error, breadcrumb, and Hosted Fields patterns are non-exhaustive examples of existing local patterns, not a complete component inventory or closed allowlist; other appropriate existing Portal code may also be reused. Do not add a framework, dependency, token catalog, Admin layout, or local invoice/PDF surface. Keep the authenticated actor, selected billable display name, Accrue Customer, and processor distinct in page copy and confirmation context.

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
| Home subscriptions empty state | Heading: “Welcome”. Body: “You don't have a subscription yet.” Next step: use the existing “Manage subscriptions” navigation link. |
| Subscriptions empty state | Heading: “No active subscriptions”. Body: “You don't have any active subscriptions on this account. When you subscribe to a plan, it will appear here.” Next step: use the existing “Manage subscriptions” navigation link; do not add a plan-purchase flow. |
| Payment methods empty state | Heading: “No payment methods on file”. Body: “Add a card to subscribe to plans or update an existing subscription's payment method.” Next step: “Add a card” using the existing add-card route. |
| Invoices empty state | Heading: “No invoices yet”. Body: “When your first invoice is issued, it will appear here.” Next step: “Check back after an invoice is issued.” Do not include the current Copy string's seven-year retention claim; this phase does not establish that guarantee. |
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

Applicable shape-rooted state considerations resolved: **14 explicit, 0 backstop, 0 unresolved — 14 total across the Portal collections and form surfaces below**. The checked-in probe classified two surface elements and verified all applicable categories.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Home and subscription/payment/invoice collections; add-card and checkout forms | ✅ covered | Automated tests verify actionable route-specific empty copy, keep failed reads distinct from empty results, and block unfilled secure forms without a valid nonce. |
| loading | Page actions, Hosted Fields, and checkout submission | ✅ covered | LiveView/browser checks verify pending feedback and duplicate-submit protection; static server-rendered collections remain readable without an invented loading skeleton. |
| error | Failed reads, denied/missing context, validation, provider, and checkout outcomes | ✅ covered | Failure-injection tests verify visible announced distinctions and safe recovery, without cross-Customer disclosure, false success, charge claims, or automatic replay. |
| populated | Seven Portal pages and hosted invoice access | ✅ covered | Two-owner browser/LiveView fixtures verify populated views and links stay scoped to the authorized Customer and selected billed entity. |
| partial | Subscription lifecycle, invoice metadata, and payment/checkout forms | ✅ covered | Incomplete fixtures keep missing observations unknown or unavailable; they never imply zero, inactivity, host access, complete counts, retention, or payment success. |
| overflow | Portal collections and forms at 320 CSS px | ✅ covered | Served browser checks assert no page-wide horizontal overflow and retain the billed identity, essential facts, labels, and actions. |
| zero-one-many | Subscription, invoice, and payment-method collections | ✅ covered | Automated fixtures cover zero, one, and multiple records with item-appropriate actions and no cross-owner fallback. |
| long-text | Billed-entity names, identifiers, dates, help, and errors | ✅ covered | Served browser fixtures verify long values wrap or reflow while identity, field associations, and action labels remain readable. |

### Portal Page Visual Anchors

Keep the existing calm Portal shell, host-provided brand, and customer task order. Each page has one clear focal anchor; supporting facts and actions follow it.

| Page | Primary visual anchor / hierarchy |
|------|-----------------------------------|
| Home | “Account overview” heading and billed-entity context lead; subscription, payment-method, and invoice counts form the supporting summary; recent subscriptions follow. |
| Subscriptions list | “Subscriptions” heading and lifecycle-labeled subscription rows lead; each row's “View details” action follows its identity and status. |
| Subscription detail | Subscription identity and lifecycle summary lead; period end and supported change/cancel actions follow, with recovery notice first when present. |
| Payment methods list | “Payment methods” heading and card brand/last four lead; default status and per-card actions follow; “Add a card” is the page's primary task action. |
| Add payment method | “Add payment method” heading and short purpose copy lead; labeled secure Hosted Fields are the task focus, followed by “Save card” and discard navigation. |
| Invoices | “Invoices” heading and invoice identity/status rows lead; hosted “Open invoice” actions follow each row. |
| Checkout | Selected-plan summary (plan, billed entity, and amount/interval) leads; secure payment fields and checkout action follow; errors or uncertain outcomes appear adjacent to the affected task. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable; Portal is Phoenix LiveView and no shadcn or third-party registry is used |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS (no external design-system inventory; local patterns are non-exhaustive)

**Approval:** approved 2026-10-08
