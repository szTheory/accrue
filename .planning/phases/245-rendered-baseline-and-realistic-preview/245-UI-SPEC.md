---
phase: "245"
slug: "rendered-baseline-and-realistic-preview"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-11"
---

# Phase 245 — UI Design Contract

> This phase inventories and evaluates the rendered Admin that exists today, and prepares plausible ordinary preview data. It does not authorize production visual changes. Preserve Accrue Admin's incumbent design system while capturing evidence that Phase 246/247 can use to make bounded, source-owned changes. The supplied owner screenshots are defect evidence, not acceptance captures.

## Design System

| Property | Value |
|----------|-------|
| Tool | Accrue Admin in-repository design system; no shadcn |
| Preset | Not applicable |
| Component library | Custom Phoenix LiveView function components in `accrue_admin/lib/accrue_admin/components/` |
| Icon library | Existing inline Heroicons via `AccrueAdmin.Components.Icon` |
| Font | Self-hosted Geist and Geist Mono; retain system fallbacks |

Baseline sources: `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`, `brandbook/tokens/tokens.css`, and existing shared components including AppShell, PageHeader, DataTable, FilterChipBar, Detail, DetailDrawer, Tabs, EmptyState, JsonViewer, StatusBadge, InlineId, Timeline, Breadcrumbs, WindowSelector and KpiCard. Reuse the relevant owner component in each finding; record a page-local exception only when the operator task and source justify it. Do not add a library, token set, or page-specific aesthetic system in this phase.

## Component Inventory

Enumerated by `rg --files accrue_admin/lib/accrue_admin/components -g '*.ex' | sort | wc -l` — 43 component source files — `accrue_admin@1.6.0` (in-repository Phoenix UI; version from `accrue_admin/mix.exs`) — 2026-10-11. The sample below is non-exhaustive, not a closed allowlist; inspect the source inventory for other suitable components.

| Component | Import path | Notes |
|-----------|-------------|-------|
| AppShell | `AccrueAdmin.Components.AppShell` | Existing Admin frame and navigation |
| PageHeader | `AccrueAdmin.Components.PageHeader` | Page identity and supporting actions |
| DataTable | `AccrueAdmin.Components.DataTable` | Shared collection/table patterns |
| FilterChipBar | `AccrueAdmin.Components.FilterChipBar` | Applied constraints and removal |
| Detail / DetailDrawer | `AccrueAdmin.Components.Detail`, `AccrueAdmin.Components.DetailDrawer` | Existing record and overlay investigation patterns |
| Tabs | `AccrueAdmin.Components.Tabs` | Existing tabbed states |
| EmptyState | `AccrueAdmin.Components.EmptyState` | Existing no-data and no-results presentation |
| JsonViewer | `AccrueAdmin.Components.JsonViewer` | Exact payload inspection and copy controls |
| StatusBadge | `AccrueAdmin.Components.StatusBadge` | Semantic status presentation |
| InlineId | `AccrueAdmin.Components.InlineId` | Secondary exact identifiers |
| Timeline | `AccrueAdmin.Components.Timeline` | Existing activity/history presentation |
| Breadcrumbs | `AccrueAdmin.Components.Breadcrumbs` | Existing route hierarchy |
| WindowSelector / KpiCard | `AccrueAdmin.Components.WindowSelector`, `AccrueAdmin.Components.KpiCard` | Existing analytics controls and metrics |

## Spacing Scale

The capture and review process records the incumbent spacing; it does not impose new component geometry. Existing semantic spacing tokens in `theme.css` are:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact element spacing |
| md | 16px | Default element spacing |
| lg | 24px | Section padding |
| xl | 32px | Layout gaps |
| 2xl | 48px | Major section breaks |
| 3xl | 64px | Page-level spacing |

Exceptions: none in the declared scale. The existing `--ax-space-2xs: 2px` token is an observed legacy dense-table value outside this contract scale; record where it appears, do not treat it as a declared spacing choice, and do not change production tokens in Phase 245.

## Typography

The production system has a larger token scale. This phase preserves and documents it; these four common roles describe the inspection baseline, not a typography redesign. Geist Mono remains for exact technical values and identifiers.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px (`--ax-type-md`) | 400 | 1.4 |
| Label | 14px (`--ax-type-sm`) | 600 | 1.4 |
| Heading | 28px (`--ax-type-2xl`) | 600 | 1.2 |
| Display | 36px (`--ax-type-3xl`) | 600 | 1.2 |

These are the only four sizes and two weights declared by this contract. Existing 12px, 20px and 24px token sizes are observed legacy values outside the contract scale: record where they appear without treating them as declared roles or changing production tokens. Long-form prose uses the existing 1.5 line-height role. Do not normalize observed pages to these four sample roles as part of Phase 245.

## Color

The ratio is a qualitative surface distribution guide, not a measured pixel quota. Preserve the actual theme token assignments and capture both themes.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light: `--ax-base` / Paper `#fafbfc`; dark: `#0f1318` | Page canvas |
| Secondary (30%) | Light: `--ax-elevated` `#ffffff` and `--ax-sunken` `#f1f5f8`; dark: `--ax-elevated` `#171d24` and `--ax-sunken` `#0b1015` | Cards, navigation, tables and recessed surfaces |
| Accent (10%) | Existing host-bound `--ax-accent` (brand Cobalt `#5d79f6`) and theme-aware accent tokens | Existing primary actions, links, selected/focus states only where already assigned |
| Destructive | `--ax-danger` with theme-aware readable/surface tokens | Destructive actions and evidence-supported danger states only |

Accent reserved for: current primary action affordances, links, selected navigation/filter/control states, and visible focus treatment as assigned by existing CSS. Do not color ordinary metrics, missing evidence, warnings, or statuses as decorative emphasis. Semantic status colors must retain their existing meanings and labels; color alone never carries state.

## Copywriting Contract

Phase 245 adds no operator-facing CTA, empty state, error state, destructive action or production copy. Capture and quote the current rendered copy with route/state evidence, then record findings against the owning copy/component source. Seed data should use plausible, internally consistent billing stories and truthful record identities; retain valid unknown/unavailable evidence and keep adversarial long-name, Unicode, and failure cases in their fixture owners. Never invent a processor outcome to improve the preview.

| Element | Copy |
|---------|------|
| Primary CTA | Not applicable in this inventory/data phase; record the exact current CTA when present on a reviewed route. |
| Empty state heading | No new copy. Record current rendered heading and whether the state is truly empty, filtered-to-zero, or unavailable. |
| Empty state body | No new copy. Record observed explanation and any supported next step; do not infer recovery actions. |
| Error state | No new copy. Capture the actual problem and available recovery path; distinguish an unavailable capture from an application error. |
| Destructive confirmation | No destructive action is introduced. Do not reset, delete, or reseed the existing feedback-preview database. |

## UI Considerations

Applicable state considerations resolved: 8 covered, 0 backstop, 0 unresolved. Resolutions specify the required coverage evidence, not acceptance of visual quality or behavior. Every applicable inventory row must be marked inspected, unavailable with a concrete reason, or not applicable with a reason. A capture or detector result alone does not prove interaction correctness, accessibility, or acceptance.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Admin collection routes, detail histories, payload/history disclosures | ✅ covered | Include representative genuinely empty and filtered-to-zero states where route data supports them; note the exact state and distinguish empty from unavailable. Copy references the current rendered empty-state heading/body above. |
| loading | Collections, route transitions, search, disclosures and other observed async controls | ✅ covered | Record loading only when the rendered route exposes it; inspect idle versus in-flight indicators and whether delayed content is clearly associated with the active action. |
| error | Route loads, filters/search, copy controls, actions and captured data | ✅ covered | Record application errors separately from unavailable environment/fixture states; note visible recovery controls without asserting successful outcomes. Copy references the current rendered error behavior above. |
| populated | Existing Admin lists, details, analytics and relevant overlays | ✅ covered | Enumerate mounted routes and materially distinct states from the authoritative router; capture representative ordinary populated states and identify the scenario. |
| partial | Records with absent, stale, unknown or incomplete billing evidence | ✅ covered | Preserve and label observed evidence gaps; verify ordinary preview money, dates, relationships and processing histories internally agree without fabricating missing fields. |
| overflow | Tables, navigation, dialogs/drawers, payloads and long identifiers | ✅ covered | Include ordinary realistic values plus any existing relevant boundary state; record wrap, clipping, scrolling or truncation and whether exact values remain accessible. |
| zero-one-many | Collection routes | ✅ covered | Account for zero, one and representative many-row states across the route inventory; capture only where supported by existing scenario data and state reason for gaps. |
| long-text | Names, IDs, event types, payloads, status/help copy and navigation labels | ✅ covered | Inspect representative long content and established adversarial fixtures without allowing synthetic identities to dominate ordinary demo captures; note whether readable and exact forms remain available. |

### Capture and interaction evidence contract

- Build the route/state ledger from mounted router definitions and actual host mounting. Include list/detail routes and materially different overlays, disclosures, tabs, role/scope variants and data states. Reconcile prior 21-route records; do not treat them as current coverage.
- For every inspected route/state ledger row, record its primary visual anchor: the dominant existing composition that identifies the rendered surface (for example, the shared page shell plus its collection table, record detail, analytics group, or overlay). Name the actual component/composition observed; do not prescribe new geometry or presume one anchor fits every route.
- Use a bounded representative matrix: narrow and wide viewport, light and dark theme, with representative state combinations rather than the full Cartesian product. Choose repeatable viewport sizes aligned to the existing responsive breakpoints; report them in each capture's provenance. Explicitly account for missing combinations.
- Each screenshot must identify route, material state, scenario/fixture, source revision, served asset identity, viewport dimensions and theme. Keep source assets and browser state tied to the same run; supplied owner screenshots remain defect references.
- For interaction-dependent findings, capture observable keyboard and pointer behavior (and touch at narrow width where relevant): focus, selected versus hover state, control labels, disclosure state, remove-one/reset-all scope, URL/query/result agreement, and truthful loading/error feedback. Record untested inputs as gaps; screenshots and accessibility detectors do not certify behavior or WCAG conformance.
- Review previously unseen page compositions with task-oriented visual assessment. Link every accepted finding to screenshot(s), route/state, source owner, shared versus page-specific scope, and disposition. Reuse one finding for repeated shared-component defects rather than duplicating audits.
- Treat a missing browser/server/credential/scenario as `unavailable` with its reason. Do not substitute stale captures or claim comprehensive coverage. Preserve the existing feedback preview; use an isolated ordinary preview dataset/stack for data improvements and keep destructive reseeding explicit.

## Registry Safety

No shadcn initialization, external component registry, third-party block, or new dependency is in scope. Existing in-repository Phoenix components remain the implementation baseline.

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| Not applicable | None | No external registry declared |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-10-11; independent gsd-ui-checker verified all seven dimensions. Existing UI Considerations remain the resolved inspection contract; deterministic probe report was reviewed without treating unclassified elements as acceptance.
