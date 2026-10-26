---
phase: "252"
slug: "production-backed-subscription-stories"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-26"
---

# Phase 252 — UI Design Contract

> Visual and interaction contract for the production-backed subscription summary, facts, and eligible-action area. Source of truth: current Accrue Admin HEEx components and semantic CSS tokens.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — Accrue Admin design system |
| Preset | None |
| Component library | In-repo Phoenix function components (`Phoenix.Component` / HEEx); no shadcn |
| Icon library | `AccrueAdmin.Components.Icon`, inline Heroicons v2; no runtime icon package |
| Font | Geist for UI text; Geist Mono for identifiers (`accrue_admin/assets/css/theme.css:13-14`) |

Admin semantic tokens in `accrue_admin/assets/css/theme.css` are authoritative for this surface. The default light palette consumes the generated brand tokens in `brandbook/tokens/tokens.css`; preserve host brand overrides through `--ax-accent` and do not hard-code token colors into the view.

## Surface Contract

**Scope:** the production-owned `Detail.summary_card`, `Detail.summary_list`, and `.ax-detail-action-band` composition in `accrue_admin/lib/accrue_admin/live/subscription_live.ex:269-315,846-892`. Stories call the same production renderer and current `Copy`, `ScopedPath`, lifecycle, and action-eligibility owners. Do not add story-local row formatting, eligibility, scoped links, fake controls, provider rules, or a parallel detail page. The subscription list, breadcrumbs, drawers, timeline, full action journey, and whole-page composition remain outside this slice.

**Rendered order:** (1) summary header with subscription title, lifecycle badge, and copyable subscription ID; (2) ordered definition-list facts; (3) `Subscription actions` band. Preserve this facts order: `Lifecycle state`; conditional `Billing evidence`; `Customer`; `Plan / price`; `Current period`; `Cancellation`; `Renews / ends`; `Amount (MRR)`; conditional `Seats / quantity`; conditional `Dunning`. Optional rows appear only when production data/helpers provide them. Keep the `Amount (MRR)` value `Unavailable` while the current production projection says it is unavailable; never substitute a guessed zero or plan amount.

**Review variations:** stable variation IDs are `active`, `scheduled_cancellation`, and `incomplete_evidence`; generate direct URLs from PhoenixStorybook’s compiled story/variation APIs. Each manifest entry identifies actor (`vendor billing support operator`), job (`understand subscription state and choose a supported next action`), input source (deterministic Cadence scenario facts), production renderer (shared Subscription summary/facts/action component), and proof lane (`static render`). These fields are review metadata, not UI copy. A static story proves only settled rendering; it must not claim mounted authorization, provider completion, persistence, or action success.

| State | Required visible content and interaction contract |
|-------|-----------------------------------------------|
| Active | Status and facts come from the active Subscription and Customer. Show `No cancellation scheduled`; eligible production actions may include `Change plan` and `Cancel renewal`. `More actions` contains only groups/items allowed by the existing `action_available?/2` owner. |
| Scheduled cancellation | Preserve the scheduled status and effective timestamp from the current `Timestamp`/cancellation helpers. The `Cancellation` fact reads `Scheduled for {timestamp}` when the date exists, otherwise `Scheduled; effective date not shown`. Do not offer `Cancel renewal`; the existing renewal row's visible `Change` action and `Resume subscription` menu item follow production eligibility. `Detail.summary_list` uses the shared `Copy.action_hidden_context` phrase once as the action's accessible name: `Change renewal for subscription {id}`. Keep this scoped to the renewal action rather than changing copy globally or labeling it `Change plan`. |
| Incomplete evidence | Keep the real subscription/status. Missing projections remain explicit: `Current period unavailable`, `Price unavailable`, `Renewal date unavailable`, and/or `Charge amount unavailable` as supplied by production helpers. When present, `Billing evidence` lists caveats in source order separated by `, `. Do not fabricate an amount/date or turn incomplete evidence into an empty subscription. |

**Responsive and interaction behavior:** use the existing production breakpoints and classes. At 320 CSS px, the summary title, facts, identifiers, definition-list values, and action labels wrap without clipping or horizontal page overflow; the facts list uses its current single-column row layout at widths below 600 CSS px. At 1280 CSS px, retain the existing three-column summary rows and card/action hierarchy. Keep long names and IDs complete; do not ellipsize. Action-band buttons and menu trigger retain the existing 44px minimum height. Preserve visible keyboard focus: the current 2px `--ax-focus-ring` outline, 2px offset, and focus shadow; do not clip it. Tab order follows rendered order. The copy control retains the accessible name `Copy subscription ID` and full clipboard value. `Detail.summary_list` uses each shared `Copy.action_hidden_context` phrase once as its summary action's accessible name: `Change plan for subscription {id}` for the Plan / price action and `Change renewal for subscription {id}` for the Renews / ends action, while keeping each visible label `Change`. Preserve `ScopedPath` owner scope.

**Visual coverage:** render and assert each combination of the three stable states (`active`, `scheduled_cancellation`, `incomplete_evidence`), both viewport widths (320 and 1280 CSS px), and both themes (light and dark): 12 separately identified cases. Keep per-case evidence for every state/width/theme combination; pooled or aggregate-only coverage does not satisfy this contract. Mounted authorization and action behavior remain separate from static render coverage.

**Semantic structure:** summary title remains the page-level `h1`; `Subscription actions` remains an `h2`; facts remain a `dl` with `dt`/`dd`; lifecycle badge includes visible text and its dot stays decorative; copy and action controls are `button type="button"`; action links stay anchors. The `More actions` disclosure retains `aria-haspopup="menu"`, a named `role="menu"`, named `role="group"` sections, and `role="menuitem"` buttons. Do not rely on color alone for lifecycle or danger state.

---

## Component Inventory

Enumerated by `rg --files accrue_admin/lib/accrue_admin/components -g '*.ex' | wc -l` — 46 components — accrue_admin@1.7.0 — 2026-10-26.

Cross-check: `find accrue_admin/lib/accrue_admin/components -type f -name '*.ex' | wc -l` also returns 46. Version is the package's `@version` in `accrue_admin/mix.exs:4`; the table is a non-exhaustive list of known-good components, not an allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `Detail.summary_card/1` | `AccrueAdmin.Components.Detail` | Shared title, status, and fact header. |
| `Detail.summary_list/1` | `AccrueAdmin.Components.Detail` | Semantic `dl` facts with optional scoped row actions. |
| `StatusBadge.status_badge/1` | `AccrueAdmin.Components.StatusBadge` | Lifecycle text plus production tone mapping. |
| `IdBadge.id_badge/1` | `AccrueAdmin.Components.IdBadge` | Copyable full ID; use the existing plain variant and accessible label. |
| `DropdownMenu.action_menu/1` | `AccrueAdmin.Components.DropdownMenu` | Groups only currently available actions; keeps hidden subscription context. |
| `Timestamp.timestamp/1` | `AccrueAdmin.Components.Timestamp` | Existing timestamp presentation for current period/cancellation dates. |

---

## Spacing Scale

Declared values, multiples of 4; use the existing `--ax-space-*` tokens in `accrue_admin/assets/css/theme.css:26-34`.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight gaps between nearby controls/content |
| sm | 8px | Compact summary row padding and local gaps |
| md | 16px | Default row/card spacing |
| lg | 24px | Space between major adjacent areas |
| xl | 32px | Section-level separation |
| 2xl | 48px | Major section breaks |
| 3xl | 64px | Page-level spacing |

Exceptions: none for new layout spacing. Existing component micro-gap output remains unchanged; this phase neither modifies design-token output nor uses the micro-gap token as a layout rung.

---

## Typography

Use only the existing four size steps below (12, 14, 16, 28px) and the two established weights (400, 600). Tokens and composed roles are in `accrue_admin/assets/css/theme.css:17-23,71-108`; the summary component's 12/14px local exceptions are in `accrue_admin/assets/css/app.css:6388-6405,5678-5713`.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px (`--ax-type-md`) | Regular 400 | 1.4 (`--ax-leading-normal`) |
| Label | 12px (`--ax-type-xs`, summary-key exception) | Semibold 600 | 1.4 |
| Summary value | 14px (`--ax-type-sm`) | Regular 400 | 1.4 |
| Heading | 28px (`--ax-type-2xl`, summary title) | Semibold 600 | 1.2 (`--ax-leading-tight`) |
| Display | Not used in this slice | — | — |

---

## Color

Keep the 60/30/10 balance through semantic tokens. Values below are the current default theme values; host brand overrides remain authoritative.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light `--ax-base: #fafbfc`; dark `#0f1318` | Page and primary surface |
| Secondary (30%) | Light `--ax-elevated: #ffffff`, `--ax-sunken: #f1f5f8`; dark `#171d24`, `#0b1015` | Summary/action cards and recessed surfaces |
| Accent (10%) | Default `--accrue-interactive-accent: #5d79f6`, via `--ax-accent` | Filled primary eligible action, summary `View`/`Change` links, and keyboard focus only; dark primary fill uses the existing accent/elevated-surface mix |
| Destructive | `--ax-danger-readable: #9b1c1c` light; `#ffaaaa` dark | Existing danger treatment for dangerous menu items only |

Accent reserved for: the eligible `Change plan` primary button, existing summary-row action links, and focus indication. `Cancel renewal` remains secondary. Lifecycle/status tones use the existing semantic badge palette, not the accent. Preserve the current white primary-button text (`--ax-accent-contrast`) and dark-theme primary treatment in `accrue_admin/assets/css/theme.css:138-180,234-250` and `accrue_admin/assets/css/app.css:2828-2862`.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Change plan` when the production eligibility helper exposes it; otherwise omit it. Never promote an unsupported action. |
| Secondary CTA / menu | `Cancel renewal` only when eligible; action-band heading `Subscription actions`; menu trigger `More actions`. Scheduled cancellation uses the existing visible `Change` renewal-row link with the shared accessible name `Change renewal for subscription {id}`, plus the `Resume subscription` menu item. `Detail.summary_list` applies the shared `Copy.action_hidden_context` value once; keep the visible `Change` label and do not rewrite copy globally. |
| Empty state heading | Not applicable — an empty subscription detail is not a valid scenario; do not fabricate an empty subscription record. |
| Empty state body | Not applicable — a missing/unscoped subscription follows the existing scoped not-found route. |
| Error state | Missing/unscoped record: existing `Copy.Locked.owner_access_denied()` and redirect to the scoped `/subscriptions` path. Incomplete facts use the exact production unavailable/caveat copy above. Mounted action failures keep their existing `SubscriptionLive`/`Copy` flash or `role="status"` result; no story-local error copy. |
| Destructive confirmation | `Cancel immediately` and `Comp this subscription` stay under `More actions` → `Danger zone`; use the existing staged confirmation from `Copy.subscription_confirm_workflow_message/2`, fresh review validation, and step-up flow. Do not duplicate its copy or expose a direct destructive primary action. |

---

## UI Considerations

Post-check deterministic probe: 3 surfaces, 20 applicable considerations, 0 unclassified. Kind confirmation uses authored unions: E1 static-content + interactive-control; E2 list-collection + static-content; E3 interactive-control + list-collection + nav. All resolutions below are explicit automated acceptance predicates; none is deferred or a manual-UAT gate. Copy remains owned by the Copywriting Contract.

| Element | Category | Status | Verification | Acceptance predicate |
|---|---|---|---|---|
| E1 | loading | resolved | explicit | Static variations receive settled validated assigns and render without a fabricated spinner/skeleton; existing production query/bootstrap behavior is preserved and not claimed as story coverage. |
| E1 | error | resolved | explicit | Invalid facts are rejected before render; generated missing/wrong variation URLs fail reconciliation; existing scoped not-found and action-failure regressions remain green. Static controls do not claim dispatched action success. |
| E1 | overflow | resolved | explicit | Every state at 320px and 1280px in light/dark has no horizontal page overflow or clipped facts/actions; keyboard focus remains visible and reachable. |
| E1 | long-text | resolved | explicit | Ordinary data and separately labelled held-out long-text cases keep complete identifiers/names available, wrap without truncation, and copy the full ID. |
| E2 | empty | resolved | explicit | Missing subscription input is rejected rather than rendered as an empty record; optional fact/menu groups are omitted when empty and production-required facts remain present. |
| E2 | loading | resolved | explicit | Static variations receive settled validated assigns and render without a fabricated spinner/skeleton; existing production query/bootstrap behavior is preserved and not claimed as story coverage. |
| E2 | error | resolved | explicit | Invalid facts are rejected before render; generated missing/wrong variation URLs fail reconciliation; existing scoped not-found and action-failure regressions remain green. Static controls do not claim dispatched action success. |
| E2 | populated | resolved | explicit | Each active, scheduled_cancellation and incomplete_evidence variation renders through the shared production owner with exact scenario attribution in all 12 width/theme cases. |
| E2 | partial | resolved | explicit | Missing projections show existing production unavailable/caveat copy in source order, never fabricated dates or money; optional rows depend on actual inputs. |
| E2 | overflow | resolved | explicit | Every state at 320px and 1280px in light/dark has no horizontal page overflow or clipped facts/actions; keyboard focus remains visible and reachable. |
| E2 | zero-one-many | resolved | explicit | Production-required facts remain; optional rows/groups follow source cardinality; zero empty menu groups render; no impossible empty subscription fixture is created. |
| E2 | long-text | resolved | explicit | Ordinary data and separately labelled held-out long-text cases keep complete identifiers/names available, wrap without truncation, and copy the full ID. |
| E3 | empty | resolved | explicit | Missing subscription input is rejected rather than rendered as an empty record; optional fact/menu groups are omitted when empty and production-required facts remain present. |
| E3 | loading | resolved | explicit | Static variations receive settled validated assigns and render without a fabricated spinner/skeleton; existing production query/bootstrap behavior is preserved and not claimed as story coverage. |
| E3 | error | resolved | explicit | Invalid facts are rejected before render; generated missing/wrong variation URLs fail reconciliation; existing scoped not-found and action-failure regressions remain green. Static controls do not claim dispatched action success. |
| E3 | populated | resolved | explicit | Each active, scheduled_cancellation and incomplete_evidence variation renders through the shared production owner with exact scenario attribution in all 12 width/theme cases. |
| E3 | partial | resolved | explicit | Missing projections show existing production unavailable/caveat copy in source order, never fabricated dates or money; optional rows depend on actual inputs. |
| E3 | overflow | resolved | explicit | Every state at 320px and 1280px in light/dark has no horizontal page overflow or clipped facts/actions; keyboard focus remains visible and reachable. |
| E3 | zero-one-many | resolved | explicit | Production-required facts remain; optional rows/groups follow source cardinality; zero empty menu groups render; no impossible empty subscription fixture is created. |
| E3 | long-text | resolved | explicit | Ordinary data and separately labelled held-out long-text cases keep complete identifiers/names available, wrap without truncation, and copy the full ID. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | Not applicable — shadcn is not initialized |
| Third-party registries | none | None declared; no blocks or dependencies are introduced |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-10-26; independent UI checker passed 7/7 dimensions. Post-check state probe resolved 20/20 explicit predicates.
