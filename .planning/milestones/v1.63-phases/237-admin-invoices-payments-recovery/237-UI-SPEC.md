---
phase: "237"
slug: "admin-invoices-payments-recovery"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-08"
---

# Phase 237 — UI Design Contract

> Visual and interaction contract for invoice, payment/refund, and recovery surfaces in the existing Admin. Scope and safety decisions are locked in `237-CONTEXT.md`.

## Design System

| Property | Value |
|----------|-------|
| Tool | none (existing package-owned Phoenix LiveView/HEEx components) |
| Preset | not applicable |
| Component library | none; reuse `AccrueAdmin.Components` |
| Icon library | Existing inline/glyph treatment; add no dependency |
| Font | Geist for Admin prose and controls; Geist Mono for technical IDs |

Preserve Admin's `--ax-*` semantic roles and package asset pipeline. Do not add shadcn, a UI dependency, or a second token catalog. Retain the compact financial-tool density and existing Admin shell.

## Existing Component Patterns

Enumerated by `find accrue_admin/lib/accrue_admin/components -maxdepth 1 -type f -name '*.ex' | sort` — 43 components — `accrue_admin`@1.6.0 — 2026-10-08.

Use `AccrueAdmin.Components.DataTable`/existing list patterns for invoice and charge collections, `StatusBadge` for labeled lifecycle/result states, and `MoneyFormatter` for every displayed amount. Keep true zero distinguishable from unavailable `--`; never substitute USD or zero. Use `DetailDrawer` for staged review, the shared overlay substrate for modal step-up, `WindowSelector` and `AtRiskTable` for recovery, and `EmptyState` for collection emptiness. Reuse `ScopedPath`, owner-scoped reads, and existing copy modules for route context and language. The inventory here is factual project-local code, not a closed allowlist; inspect before introducing another component.

This component list is non-exhaustive, not a closed allowlist. The executor may use any existing component after checking its source.

Primary visual anchor: on the invoice collection list, make the “Clear open receivables” heading and the open receivables summary the first visual focal point; put filters and secondary lifecycle details beneath that hierarchy. On detail/action views, retain the invoice or charge identity and exact amount as the focal summary.

## Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon/text gaps and tight grouping |
| sm | 8px | Compact controls and labels |
| md | 16px | Default content and control spacing |
| lg | 24px | Card sections and related groups |
| xl | 32px | Major layout groups |
| 2xl | 48px | Page-level separation |
| 3xl | 64px | Large page breaks where layout permits |

Exceptions: none. Keep phase-owned spacing on the 4px grid. Icon-only controls must provide a 44px minimum target when introduced. Existing larger controls remain unchanged.

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Metadata / eyebrow | 12px | 600 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Page heading | 26px | 600 | 1.2 |

Use only regular (400) and semibold (600) in this contract. Preserve existing local metric and technical-ID styles where useful; do not make amounts or status distinctions depend on tiny metadata. Long identifiers wrap or use deliberate disclosure.

## Color

Percentages describe visual hierarchy, not fixed hex ratios across themes. Use active Admin semantic tokens so light and dark themes remain coherent.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--ax-base` | Page and shell background |
| Secondary (30%) | `--ax-elevated`, `--ax-sunken`, `--ax-border` | Cards, grouped panels, table surfaces and navigation |
| Accent (10%) | `--ax-accent`, `--ax-accent-readable`, `--ax-focus-ring` | One primary action per task group, links, selected window/filter, active navigation, visible focus |
| Destructive | `--ax-danger` and status-danger roles | Void/refund destructive emphasis and errors only |

Accent reserved for: the primary action in the current invoice/refund task, links, selected recovery window/filter, active navigation, and focus treatment. Do not use accent as a blanket color for all controls. Statuses always include text and may use an icon/shape; color alone never conveys lifecycle, overdue, or action result. Maintain the inherited minimum contrast targets: text 4.5:1, large text 3:1, essential control boundary/focus 3:1 against adjacent colors.

## Copywriting Contract

Reuse existing strings in `AccrueAdmin.Copy.Invoice`, `Copy.Dunning`, and adjacent copy modules where they fit. State language must describe local evidence precisely.

| Element | Copy |
|---------|------|
| Primary CTA | “Review action” to open the existing staged review; confirmation button names the action, e.g. “Pay invoice” or “Confirm refund” |
| Empty state heading | Invoice collection: preserve “No invoices need collection.” / first-run: “No invoices yet.” Recovery with no observations: “No recovery activity in this period.” |
| Empty state body | Invoice queue: “View all invoices to review the ledger.” First-run: “Invoices appear when subscriptions activate or renew.” Recovery: “Choose another time window or owner scope to review available activity.” |
| Error state | “We couldn't load this billing data. Refresh the page or return to the list and try again.” For denied scope, use the existing generic access-denied copy and do not identify foreign records. |
| Destructive confirmation | Void invoice: “Void invoice [identifier]? This changes the invoice through the existing billing workflow.” Refund: “Refund [exact formatted amount] from charge [identifier]? This creates a refund through the existing billing workflow.” Keep the exact target, amount/currency when known, and consequence visible before confirmation. |

Outcome copy: accepted means “Payment request accepted” and names the local resulting invoice/payment evidence; requires-action means “Customer action required” with the existing safe next step; definitive rejection means “Payment failed” or “Refund failed” with the available reason and retry guidance only where supported; completed means “Refund recorded”/“Invoice finalized” only when the scoped resulting row confirms it; ambiguous means “Outcome not confirmed. Check the invoice or payment record before trying again.” Never auto-retry or claim processor completion from an audit row alone.

## Interaction Contract

- Invoice list/detail show persisted lifecycle status separately from derived overdue. Only an open invoice with a known passed due date receives an “Overdue” collection signal. Missing due date is “Due date unavailable”; draft/open/paid/void/uncollectible remain their stored statuses.
- Every money value uses `MoneyFormatter` with a known integer minor-unit amount and supported currency. Preserve zero and currency precision (including 0- and 3-decimal currencies). Missing/unsupported input displays `--` with an accessible “Amount unavailable” label; it is not USD, zero, or an empty cell.
- Supported payment/finalization/refund actions begin in the existing review drawer. The review names record and action, displays exact known amount and currency, and states consequence. The confirm control remains pending/disabled after submission to prevent duplicates.
- Before dispatch, including after step-up, refresh authorization and reload the same owner-scoped target; recheck eligibility and reviewed amount/currency facts. If changed or no longer eligible, cancel the staged action, refresh the view, and announce “This record changed. Review the current details before continuing.”
- Render accepted, requires-action, definitive failure, confirmed completion, and ambiguous outcome as distinct states tied to their available scoped invoice/payment/refund evidence. Refresh through owner-scoped reads. Do not claim that admin audit history proves processor settlement.
- Recovery window choices remain URL-backed 7/30/90 days in UTC. Keep selected owner, per-currency groupings, and validated return context on detail links. Historical campaign/payment-failure events are labeled as history and never overwrite current invoice/subscription state. Empty recovery data has no synthetic currency totals.
- Announce nonurgent result/status changes as a live status; urgent errors as an alert. Keep result content in reading order and move focus predictably only when the existing dialog/drawer interaction requires it.

## Responsive and Accessibility Contract

- At 320 CSS px, no page-level horizontal scroll; preserve essential record identity, lifecycle/result, exact amount/currency, due date, and available action. Dense table content may reflow into the established stacked/card presentation; do not hide required facts behind hover.
- Detail drawers become the existing full-screen mobile sheet. Confirmations and step-up dialogs contain focus, expose an accessible name, support Escape where safe, and restore focus to the opener after close.
- All filters, window links, record links, and action controls work by keyboard with visible focus. Selected filter/window uses text/ARIA state in addition to color. Controls have associated labels and errors are programmatically associated.
- Long customer names, invoice IDs, error reasons, and currencies wrap or expose deliberate disclosure without clipping amounts or action labels.
- Verify light and dark Admin themes, keyboard path, reduced motion, pending/denied/error behavior, and served current assets for the changed routes. Motion is informational and honors `prefers-reduced-motion`.

## UI Considerations

The compiled UI-consideration probe classified three surfaces into **20 applicable state considerations: 20 resolved with explicit criteria, 0 backstop, 0 unresolved, 0 unclassified**. These are acceptance contracts for planning, not claims that behavior has already been verified.

- **invoice-collection** (`list-collection`, `static-content`): invoice queue, receivables summary, filters, lifecycle rows, money, identifiers, and responsive table/card layout.
- **invoice-charge-detail-actions** (`interactive-control`, `static-content`): invoice/charge detail and staged payment, finalization, or refund review, including pending and outcome states.
- **recovery-dashboard** (`list-collection`, `nav`): UTC window navigation, owner scope, per-currency rows, historical events, and related-record links.

| Element / category | Resolution | Explicit acceptance criterion |
|---|---|---|
| invoice-collection / empty | resolved / explicit | Distinguish first-run, genuinely empty, and filtered-empty states; a failed read renders an error, never the empty state. |
| invoice-collection / loading | resolved / explicit | Keep read/filter progress with its initiating collection; do not imply payment success or suppress the last confirmed scope while pending. |
| invoice-collection / error | resolved / explicit | Show actionable read error and retry; do not render an empty list or disclose records outside authorized scope. |
| invoice-collection / populated | resolved / explicit | Show stored lifecycle separately from overdue, plus exact supported amount/currency, due-date fact, identity, and available action. |
| invoice-collection / partial | resolved / explicit | Missing due date, money, currency, or processor evidence renders unavailable; never infer overdue, USD, zero, or completion. |
| invoice-collection / overflow | resolved / explicit | At 320 CSS px, preserve identity, lifecycle/result, exact amount/currency, due date, and action without page-level horizontal scroll or hover-only facts. |
| invoice-collection / zero-one-many | resolved / explicit | Automated fixtures cover zero, one, and multiple invoice rows with appropriate singular/plural copy and item actions; do not synthesize totals. |
| invoice-collection / long-text | resolved / explicit | Long customer names, invoice IDs, and error reasons wrap or use deliberate disclosure without clipping amount, status, or action labels. |
| invoice-charge-detail-actions / loading | resolved / explicit | After submit, keep the initiating action pending/disabled to prevent duplicates; pending does not claim acceptance, completion, or processor settlement. |
| invoice-charge-detail-actions / error | resolved / explicit | If authorization, eligibility, or reviewed amount/currency changes before dispatch, cancel, refresh the scoped view, and announce the changed record; keep ambiguous outcomes unconfirmed. |
| invoice-charge-detail-actions / overflow | resolved / explicit | At 320 CSS px, the reviewed record, exact amount/currency when known, action, consequence, and confirm/cancel controls remain visible and operable. |
| invoice-charge-detail-actions / long-text | resolved / explicit | Long record IDs and processor/error reasons wrap or use deliberate disclosure while exact target and action consequence remain legible. |
| recovery-dashboard / empty | resolved / explicit | With no observations, show route-specific empty copy and no synthetic currency buckets/totals; distinguish no data from failed read. |
| recovery-dashboard / loading | resolved / explicit | During recovery queries, preserve selected owner and URL-backed 7/30/90-day UTC window; do not imply fresh results before the scoped read completes. |
| recovery-dashboard / error | resolved / explicit | Show a recoverable read error distinct from no activity and preserve only validated owner/window/return context. |
| recovery-dashboard / populated | resolved / explicit | Keep owner and UTC window, group observed amounts by currency, and label historical failures separately from current invoice/subscription state. |
| recovery-dashboard / partial | resolved / explicit | Missing/unsupported currency, date, or owner data renders unavailable; preserve known currency groups without inventing zero totals or current state. |
| recovery-dashboard / overflow | resolved / explicit | At 320 CSS px, preserve identity, owner, selected window, currency grouping, and essential links without page-level horizontal scroll. |
| recovery-dashboard / zero-one-many | resolved / explicit | Automated fixtures cover zero, one, and multiple recovery rows while preserving window/owner scope, currency separation, and appropriate copy. |
| recovery-dashboard / long-text | resolved / explicit | Long customer IDs and failure reasons wrap or use deliberate disclosure without obscuring currency, history labels, or related-record links. |

The interaction, keyboard/focus, theme, and reduced-motion contracts remain in the sections above. Plans must assign stable state assertions to automated ExUnit/LiveView checks and put browser-only navigation, focus, 320px reflow, theme, and served-asset claims in the existing host CI browser lane. Human UAT is not required for these stable acceptance criteria.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable; no shadcn or third-party registry blocks |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS (the local component list has reproducible provenance and remains non-exhaustive)

**Approval:** approved 2026-10-08
