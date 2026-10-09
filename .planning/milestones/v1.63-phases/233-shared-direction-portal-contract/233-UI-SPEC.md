---
phase: "233"
slug: "shared-direction-portal-contract"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-07"
---

# Phase 233 — UI Design Contract

> Visual and interaction contract for frontend phases. This contract was authored during execution-gate repair, after plans 233-04 (current-source baseline) and 233-06 (semantic consumers) had completed. It transcribes the locked `233-CONTEXT.md` decisions and `DESIGN.md`; it is not evidence of pre-planning approval or phase completion.

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | none; Phoenix LiveView/HEEx with existing package components |
| Icon library | Existing inline/glyph treatment; no new icon dependency |
| Font | Admin: Geist / Geist Mono; Portal: host-provided font when configured, otherwise system sans stack |

This phase adds no UI framework, dependency, shared stylesheet, public token rename, or duplicate token catalog. Keep Admin's `--ax-*` roles and package asset pipeline separate from core/Portal `--accrue-*` roles and Portal package assets. Admin remains the compact Accrue operator surface; Portal remains host-branded customer self-service with its own calmer shell and density. Shared means semantic roles and measurable checks only.

## Spacing Scale

The values in this table are the complete shared spacing contract: every declared shared spacing value is a multiple of 4 and uses this scale. Package token names and mappings remain package-owned. This table does not redefine each package's complete local token inventory.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon/text gaps and tight grouping |
| sm | 8px | Compact control and label spacing |
| md | 16px | Default content and control spacing |
| lg | 24px | Card sections and related groups |
| xl | 32px | Major layout groups |
| 2xl | 48px | Page-level separation |
| 3xl | 64px | Large page breaks where layout permits |

Package-local legacy token (outside this phase's shared spacing contract): Admin `--ax-space-2xs` is 2px for dense table details. Preserve its existing name and behavior where currently used; it is not a shared scale value or a shared spacing exception. Portal buttons/nav targets retain existing 40px minimum height; icon-only controls use at least 44px target size when introduced. These are implementation targets, not a claim every phase route already meets them.

## Typography

Four shared contract sizes and two weights define content hierarchy. Existing Admin metric/display and technical identifier styles may retain their local token sizes when needed; this compact declaration does not rename or remove package tokens.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Metadata / eyebrow | 12px | 600 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Page heading | 26px | 600 | 1.2 |

Admin prose uses Geist; technical IDs use Geist Mono, never body prose. Portal uses the configured host font or the existing system font stack. Keep amounts, dates, IDs, billed-entity names, and status labels distinguishable; long text wraps or has an explicit disclosure treatment. The Portal's observed body/control target is at least 16px; 12px metadata stays secondary and legible.

## Color

Use the active package's semantic roles; percentages describe visual hierarchy, not fixed hex ratios across light/dark themes or host brands.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Admin: `--ax-base`; Portal: `--accrue-surface-muted` | Page and shell background |
| Secondary (30%) | Admin: `--ax-surface` / `--ax-elevated`; Portal: `--accrue-surface` | Cards, grouped panels, navigation and raised surfaces |
| Accent (10%) | Admin: `--ax-accent` and readable mapped variants; Portal: host `--accrue-brand-accent` with `--accrue-brand-accent-text` / `--accrue-brand-accent-contrast` bridge | Reserved controls and selected/active emphasis listed below |
| Destructive | Admin: `--ax-danger` / status danger roles; Portal: readable semantic danger role, with existing neutral text plus explicit status | Destructive action and error state only |

Accent reserved for: one primary action per local task group, links/interactive emphasis, active navigation or selection, and visible focus treatment. Never color every interactive element with the accent. Portal host accent may be arbitrary: calculate effective computed foreground/background contrast in each theme; do not assume white text or raw accent is readable. Keep statuses labeled in text and, where useful, add a shape/glyph cue. Do not use status colors as the only state signal or as low-contrast body copy.

Contrast targets: normal text at least 4.5:1; large text (24px regular or 18.67px bold) at least 3:1; essential control boundaries, selected indicators, and focus indicators at least 3:1 against adjacent colors. Phase 04 measured asset provenance for representative captures; Phase 06 browser evidence checked representative served status/focus, computed contrast (including bright host accent), and 320px overflow. These checks are scoped evidence, not exhaustive route coverage or WCAG certification.

## Copywriting Contract

Use existing `AccruePortal.Copy` strings where routes already expose them. Context-unavailable copy below is the locked generic blocked-state language. Do not claim a charge or success until server/provider evidence confirms it.

| Element | Copy |
|---------|------|
| Primary CTA | Portal local task CTA: “Manage subscriptions” (existing home CTA); each route keeps one visually primary next action, not a phase-wide global button |
| Empty state heading | “No active subscriptions” (existing subscriptions empty state) |
| Empty state body | Preserve current `Copy.subscriptions_empty_body()` and its actionable next step; no invented account-selection prompt in personal-only mode |
| Error state | Blocked context heading: “Billing access unavailable”. Body: “We couldn't open billing for the selected account. Choose an account in your app and try again.” Link: “Return to your app”. For a denied mutation, explicitly state the change was not submitted, clear secure payment state, and provide a safe retry/navigation path without automatic replay. |
| Destructive confirmation | Cancel subscription: explain the billing/access timing and require explicit confirmation before mutation; on denial state that cancellation was not submitted. Reuse current route-specific `AccruePortal.Copy` wording where available; no phase-wide new confirmation sentence is locked. |

The selected billed entity's host-provided display name remains visible on Portal billing pages and action confirmations, separate from host product name, signed-in actor, Accrue Customer, and processor. Escape it as presentation data; it does not grant access. An optional host-owned account-switch link may appear when supplied. Do not create a universal picker, synthetic organization, or required organization vocabulary.

## UI Considerations

The compiled UI-consideration probe classified the six existing surfaces below into 30 applicable state considerations: **30 resolved with explicit criteria, 0 unresolved, 0 unclassified**. Classification includes the union of applicable element kinds from the already locked contract. Resolution describes acceptance, not a claim of completed runtime verification. No new product surface or route redesign is introduced.

- **E1**: Portal subscriptions, payment methods, invoices, and home collections (`list-collection`).
- **E2**: Portal LiveView reads, mutations, checkout; open forms, previews, confirmations, checkout (`form`, `interactive-control`).
- **E3**: Optional host-owned account-switch link, safe host return and login navigation (`nav`, `interactive-control`).
- **E4**: Long or duplicate billed-entity names, IDs, narrow Admin metrics; main billing summary/current-context heading (`static-content`).
- **E5**: Unavailable/revoked billable context and denied mutation feedback with predictable focus destination (`static-content`, `interactive-control`).
- **E6**: Admin overview and Portal summary/list views (`list-collection`, `static-content`).

| Element / category | Resolution | Explicit acceptance criterion |
|---|---|---|
| E1 / empty | resolved / explicit | Preserve the existing route-specific empty state and actionable next step; see Copywriting Contract. Do not invent an organization-selection requirement. |
| E1 / loading | resolved / explicit | Keep pending work attached to its initiating view or control and prevent duplicate submission; existing route behavior is the baseline, with protected payment/checkout transitions owned by plans 02/03/07. |
| E1 / error | resolved / explicit | Display the generic blocked or route-specific failure state and safe recovery specified in Copywriting Contract; do not leak another Customer or automatically replay a denied mutation. |
| E1 / populated | resolved / explicit | Preserve current served summary/list content and essential item actions. Baseline captures prove only their recorded fixtures; route hierarchy refinement stays with phases 234-238. |
| E1 / partial | resolved / explicit | Missing optional presentation data must not grant authority or obscure required billing facts. Authorized unprovisioned billables remain distinct from denial, with read authorization before provisioning. |
| E1 / overflow | resolved / explicit | At 320 CSS pixels, essential facts/actions remain available without page-level horizontal scrolling; long identity and technical values wrap or use deliberate disclosure. |
| E1 / zero-one-many | resolved / explicit | Retain meaningful existing empty, singular and plural collection states and item actions; no first-item fallback selects a billable. Route-specific hierarchy remains with its named owner. |
| E2 / empty | resolved / explicit | An unfilled payment form must not submit an absent provider nonce. Keep official secure fields and the current route instructions; no sensitive data is stored by Portal. |
| E2 / loading | resolved / explicit | Keep pending work attached to its initiating view or control and prevent duplicate submission; existing route behavior is the baseline, with protected payment/checkout transitions owned by plans 02/03/07. |
| E2 / error | resolved / explicit | Display the generic blocked or route-specific failure state and safe recovery specified in Copywriting Contract; do not leak another Customer or automatically replay a denied mutation. |
| E2 / partial | resolved / explicit | Partially entered or invalidated secure fields, nonces, previews and confirmations cannot be replayed. Fresh context starts a new flow; plans 02/03/07 own the assertions. |
| E2 / long-text | resolved / explicit | Long names, labels, errors and identifiers retain readable content and usable actions through wrapping or deliberate disclosure; identity stays separate from actor and brand. |
| E3 / loading | resolved / explicit | Navigation must preserve displayed context intent until the destination freshly resolves and authorizes it; an earlier assign is not authority (plans 01/03). |
| E3 / error | resolved / explicit | Unsafe external, scheme-relative, control-character or mount-loop recovery targets are rejected. Auth absence follows local login; unavailable custom selection follows generic blocked recovery. |
| E3 / overflow | resolved / explicit | At 320 CSS pixels, essential facts/actions remain available without page-level horizontal scrolling; long identity and technical values wrap or use deliberate disclosure. |
| E3 / long-text | resolved / explicit | Long names, labels, errors and identifiers retain readable content and usable actions through wrapping or deliberate disclosure; identity stays separate from actor and brand. |
| E4 / overflow | resolved / explicit | At 320 CSS pixels, essential facts/actions remain available without page-level horizontal scrolling; long identity and technical values wrap or use deliberate disclosure. |
| E4 / long-text | resolved / explicit | Long names, labels, errors and identifiers retain readable content and usable actions through wrapping or deliberate disclosure; identity stays separate from actor and brand. |
| E5 / loading | resolved / explicit | During a protected action, keep the initiating control pending and prevent duplicate submissions; secure fields and pending payloads are cleared when context becomes invalid. |
| E5 / error | resolved / explicit | Announce denial/result feedback accessibly, state a denied change was not submitted, and offer safe recovery without claiming provider rollback or automatically replaying it. |
| E5 / overflow | resolved / explicit | At 320 CSS pixels, essential facts/actions remain available without page-level horizontal scrolling; long identity and technical values wrap or use deliberate disclosure. |
| E5 / long-text | resolved / explicit | Long names, labels, errors and identifiers retain readable content and usable actions through wrapping or deliberate disclosure; identity stays separate from actor and brand. |
| E6 / empty | resolved / explicit | Preserve the existing route-specific empty state and actionable next step; see Copywriting Contract. Do not invent an organization-selection requirement. |
| E6 / loading | resolved / explicit | Keep pending work attached to its initiating view or control and prevent duplicate submission; existing route behavior is the baseline, with protected payment/checkout transitions owned by plans 02/03/07. |
| E6 / error | resolved / explicit | Display the generic blocked or route-specific failure state and safe recovery specified in Copywriting Contract; do not leak another Customer or automatically replay a denied mutation. |
| E6 / populated | resolved / explicit | Preserve current served summary/list content and essential item actions. Baseline captures prove only their recorded fixtures; route hierarchy refinement stays with phases 234-238. |
| E6 / partial | resolved / explicit | Missing optional presentation data must not grant authority or obscure required billing facts. Authorized unprovisioned billables remain distinct from denial, with read authorization before provisioning. |
| E6 / overflow | resolved / explicit | At 320 CSS pixels, essential facts/actions remain available without page-level horizontal scrolling; long identity and technical values wrap or use deliberate disclosure. |
| E6 / zero-one-many | resolved / explicit | Retain meaningful existing empty, singular and plural collection states and item actions; no first-item fallback selects a billable. Route-specific hierarchy remains with its named owner. |
| E6 / long-text | resolved / explicit | Long names, labels, errors and identifiers retain readable content and usable actions through wrapping or deliberate disclosure; identity stays separate from actor and brand. |

### Interaction and evidence mapping

The following authored mapping retains open-domain interaction and motion requirements outside the compiled shape taxonomy. Its backstops are pending evidence obligations where noted, never completion claims.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Portal subscriptions, payment methods, invoices, and home collections | ✅ covered | Preserve existing route-specific empty headings/bodies; subscriptions use “No active subscriptions”. Keep next steps clear and avoid implying the host requires an organization. |
| loading | Portal LiveView reads, mutations, checkout | 🧪 backstop | Show pending state on the initiating action, prevent duplicate submission, and do not make a billing result depend on animation. Verify in route-owning slices. |
| error | unavailable/revoked billable context | ✅ covered | Render the generic blocked state with heading, explanatory body, safe host return/switch link where provided, and predictable focus destination; do not disclose another account. Existing blocked page is distinct from unauthenticated login handling. |
| error | denied payment-method or checkout mutation | 🧪 backstop | Say the change was not submitted, clear nonce/card fields and mutation payload, announce in place, and never automatically replay; do not imply remote provider rollback. |
| populated | Admin overview and Portal summary/list views | ✅ covered | Phase 04 captured current served Admin overview and Portal home/subscription-empty views with package source/served asset hash provenance. This is representative current output, not every route. |
| visual hierarchy | Main billing summary and current-context heading | 🧪 backstop | Use the primary billing summary/current-context heading as the focal anchor on the applicable screen; secondary facts and actions follow its hierarchy. Route owners retain their detailed layout decisions. |
| partial | authorized billable with no provisioned Accrue Customer | 🧪 backstop | Preserve a distinct allowed-but-unprovisioned path; resolve and authorize read before any customer provisioning/provider write. Do not render as denial or silently switch context. |
| zero-one-many | subscriptions, invoices, payment methods, Admin tasks/status | ✅ covered | Keep collection count and item actions understandable for empty, singular, and multiple items; route slices own final hierarchy. |
| overflow | long or duplicate billed-entity names, IDs, narrow Admin metrics | 🧪 backstop | Preserve identity and essential facts using wrapping or deliberate disclosure; retain the observed Admin metric wrapping as follow-up evidence, not a new visual failure assertion. |
| overflow | Portal and route-owning pages at 320 CSS px / 400% zoom | ✅ covered | Locked reflow target: no page-level horizontal scroll and no loss of essential billing facts, labels, or actions. Phase 06 served checks passed for representative Admin and dark Portal states at 320px only. |
| interaction | open forms, previews, confirmations, checkout | 🧪 backstop | Pin each flow to displayed billable/Customer/processor and server target; freshly authorize before action. Context switch starts fresh flow and clears pending confirmation/preview and secure field state. |
| interaction | LiveView reconnect/events/navigation and four Portal POST paths | ✅ covered | Locked contract requires the same fresh server authorization boundary at every protected action, preserving Customer ownership/provider capability checks and actual human actor attribution. Plans 02/03/05/07 own implementation and positive/negative tests. |
| interaction | focus, status, and dynamic feedback | ✅ covered | Visible keyboard focus; status label plus shape/glyph where useful; announce nonurgent changes as status and urgent errors as alerts. Phase 06 measured representative served consumers, not all routes. |
| motion | Admin transitions and Portal theme/action feedback | 🧪 backstop | Keep movement brief and informational, honor `prefers-reduced-motion`, and never make checkout, denial, or success meaning animation-only. |

Numerical contrast, 320px reflow and focus targets apply to every route-owning slice, including forms and long names; representative baseline results must not be generalized to routes/states not rendered. Remaining context, form, and checkout pins/denial outcomes are planned acceptance criteria, not already verified behavior. Contract scope ends at Phase 233; route redesign stays with 234–238 and integrated route/handoff coverage with 239.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable; no shadcn initialization or third-party registry blocks |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS (no design system; inventory section intentionally omitted)

**Approval:** approved — independent gsd-ui-checker, 7/7 PASS; one scoped spacing clarification resolved. Compiled state probe completed after checker approval.
