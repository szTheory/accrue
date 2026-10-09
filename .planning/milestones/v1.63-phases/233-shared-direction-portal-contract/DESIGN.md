# Shared Admin and Portal semantic direction

**Scope:** shared meaning and observable quality bars for the existing two billing surfaces. This is a target for route-owning phases, not a report that the current UI meets every criterion or an accessibility certification. The measured render baseline is [`233-BASELINE.md`](./233-BASELINE.md); route and ownership facts are in [`233-INVENTORY.md`](./233-INVENTORY.md).

## Shared roles, distinct consumers

| Semantic role | Meaning and observable direction | Admin consumer | Portal consumer |
|---|---|---|---|
| Page / shell | Orient the user, preserve a stable content start, and make the current billing context legible. | Keep the operator's dense navigation, lookup, queue, and record shell; make tenant scope explicit. | Keep the host-branded self-service shell; identify the billed entity separately from host brand and signed-in actor wherever account context is available. |
| Surface / layer | Use page, grouped panel, and raised/overlay surfaces in a consistent depth order. Resting cards rely on clear boundaries; shadows signal actual elevation. | Continue the `--ax-*` surface, border, and shadow roles; reserve drawers/dialogs for focused work. | Continue token-driven cards and controls over the page surface with core `--accrue-*` roles. Do not inherit Admin's shell or density. |
| Action hierarchy | One visually primary next action per local task group; secondary, destructive, and navigation actions remain distinguishable by label and placement. Confirm consequential billing changes before mutation. | Prioritize the operator's queue or record action; keep destructive and step-up flows explicit. | Prioritize the customer's immediate self-service action; explain any effect on billing before submission. |
| Status / feedback | State names remain understandable without color. Pair color with visible text and, where useful, shape or icon; preserve a clear pending, success, warning, or failure message. | Existing status vocabulary may use intent colors, but a P1/P2 or invoice/webhook condition must retain a readable label and context. | Status pills must carry meaningful labels. Inline denial/result messages use `role="status"` for non-urgent updates and `role="alert"` for urgent errors; a navigated blocked state has a clear heading and predictable focus. |
| Typography | Use the package's own type scale for a predictable hierarchy. Keep amounts, dates, identifiers, and long names distinguishable; do not let small labels compete with headings. | Geist/Geist Mono and `--ax-type-*`; use mono for technical IDs, not prose. Dense operator copy can use 14px labels, with primary body text at 16px. | Host-provided font when configured, otherwise the core system stack. Customer body and control text target at least 16px; use 12px eyebrow/metadata only when it remains secondary and legible. |
| Spacing | Group related facts and actions; leave clear separation between different tasks. Preserve each package's local scale instead of making token values identical. | Existing 4px base scale with a 2px tight rung for table details; use larger 16/24/32px steps to separate groups. | Keep compact controls readable and maintain the Portal's calmer card spacing; use a 4px-based rhythm without copying Admin token names. |
| Focus | Keyboard focus is always visible, is not communicated by color alone, and remains unobscured by sticky chrome or overlays. | Use Admin focus roles from `--ax-*` with a visible outline/ring and adequate offset. | Keep `:focus-visible` treatment tied to the effective host/theme accent; preserve clear focus on links, buttons, inputs, and theme controls. |
| Motion | Motion confirms state or spatial relationships and stays brief. No billing result depends on animation. | Existing duration/easing roles are package-owned; reduced motion collapses movement and transitions. | Keep transitions restrained and honor `prefers-reduced-motion`; do not make checkout, denial, or success meaning animation-only. |
| Reflow | At 320 CSS px and 400% zoom, essential billing facts, labels, and actions remain available without page-level horizontal scrolling. Long names/IDs wrap or use a deliberate disclosure/overflow treatment. | Preserve task access when tables/cards stack; keep lookup and primary actions reachable. | Stack hosted fields, cards, and actions; retain visible billed-entity identity and full action labels. At 320px no two-column control may force horizontal overflow. |

## Contrast and state cues

For each rendered theme and host accent, calculate contrast from the **effective computed foreground and background**, including after token bridges and dark-theme overrides:

- Normal-size text: minimum **4.5:1**.
- Large text (at least 24 CSS px regular or 18.67 CSS px bold): minimum **3:1**.
- Essential control boundaries, selected-state indicators, and focus indicators: minimum **3:1** against adjacent colors.
- Do not use low-contrast status colors as body copy. Use a readable neutral text color plus a status label/icon where the brand accent cannot meet the text threshold.

The 320 CSS px reflow target applies to every route-owning slice, including forms and long billed-entity names; check at both the narrow viewport and 400% zoom.

The Portal host accent is presentation input and may be arbitrary. Derive or choose an accessible foreground for the actual accent and theme; never assume white text or an accent token is contrast-safe without checking it. Status retains a text label when color is removed. These numerical targets guide implementation and automated contrast checks; this document does not claim a completed conformance audit.

## Token and brand ownership

- `accrue_admin/assets/css/theme.css` owns Admin's private `--ax-*` roles, type, spacing, elevation, focus, and motion values. Admin CSS/JS are built and served by `AccrueAdmin.Assets`.
- `accrue/priv/static/brand.css` owns the stable public/core `--accrue-*` palette and host-brand bridge. `accrue_portal/priv/static/accrue_portal.css` owns Portal selectors and consumes those public roles; the host recompiles the embedded asset module when it changes. Portal JS and CSS remain package-served.
- Shared means shared semantic intent and acceptance checks. It does not mean a shared stylesheet, a public token rename, a duplicate token catalog, a UI dependency, or one combined component framework.
- Admin remains Accrue's operator product: compact, task-oriented, and branded with Accrue's established palette and Geist identity. Portal remains customer self-service inside the host's brand and language. A host logo/name/accent/font may shape the Portal; it must not recast the Portal as an operator console or alter authorization.

## Baseline observations and phase ownership

Current captures show a light Admin overview with dense queue/metric information and a dark, narrow Portal with stacked summary cards and an empty subscription state. Admin metric labels wrap tightly in places; the Portal baseline does not display a billed-entity name. These are observations to guide slices, not claims of failure or evidence that unrendered routes behave the same way.

- **Phase 234:** customer and subscription Admin task hierarchy, context, and operator actions.
- **Phase 235:** pricing/checkout entry and provider handoff/return, with secure payment hooks.
- **Phase 236:** Portal subscriptions, payment methods, invoices, billed identity, and customer feedback.
- **Phase 237:** Admin invoice, payment, and recovery investigations.
- **Phase 238:** Admin events, webhooks, catalog, Connect, and shared status conventions.
- **Phase 239:** integrated route, state, asset, and handoff coverage.

Each route-specific slice owns its final information hierarchy and scoped implementation contract. Changes remain within existing package token/asset ownership unless a later decision explicitly reopens that boundary.
