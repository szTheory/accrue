---
phase: "239"
slug: "integrated-quality-handoff"
status: approved
reviewed_at: "2026-10-09"
shadcn_initialized: false
preset: none
created: "2026-10-09"
---

# Phase 239 — UI Design Contract

> This phase inspects representative current renders and keeps an optional feedback preview. It does not introduce a product UI or redesign. Use this contract for evidence capture and review surfaces only; preserve the production contracts already approved in Phases 233 and 235–238.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — existing Phoenix LiveView/HEEx package components |
| Preset | Not applicable; no shadcn initialization |
| Component library | Existing `AccrueAdmin.Components` and package-owned Portal markup; no external UI package |
| Icon library | Existing inline/glyph treatment and inline Heroicons in Admin; no new icon dependency |
| Font | Admin: existing Geist / Geist Mono assets; Portal: host-provided font when configured, otherwise existing system sans stack |

Keep Admin and Portal visual systems separate. Admin uses its `--ax-*` semantic tokens and compact operator shell; Portal uses its `--accrue-*` roles and host-branded customer shell. The host preview is the existing Fake-backed example and its current mounts, not a third design system. Use production package components, copy, route mounts, and served assets when inspecting current renders. Do not add a component, theme, density mode, shell, or UI framework for the audit.

Representative inspected surfaces are one authenticated Admin operator route, one customer Portal billing route, and the existing host-mounted preview/review entry. The Admin page heading and summary are the visual anchor; on Portal, the billed-entity identity and current billing summary are the anchor. The host preview uses plain navigation hierarchy to reach those existing mounts. The route/evidence ledger determines which mounted routes and unique interactions need current evidence; a representative render never substitutes for route-level test disposition.

---

## Component Inventory

Enumerated by `find accrue_admin/lib/accrue_admin/components -maxdepth 1 -type f -name '*.ex' | wc -l` — 43 components — accrue_admin@1.6.0 (local Mix package; version declared by `@version "1.6.0"` in `accrue_admin/mix.exs`) — 2026-10-09.

This is a non-exhaustive list of known-good local components, not a closed allowlist. Portal and host mounts remain package-owned; this inventory does not imply that they import Admin components.

| Component | Import path | Notes |
|-----------|-------------|-------|
| PageHeader | `AccrueAdmin.Components.PageHeader` | Preserve existing title, breadcrumb, and summary hierarchy on inspected Admin routes. |
| DataTable | `AccrueAdmin.Components.DataTable` | Reuse existing list, filter, row, and narrow-card behavior. |
| Detail / RelatedResources | `AccrueAdmin.Components.Detail`, `AccrueAdmin.Components.RelatedResources` | Keep facts and related links grouped using production render patterns. |
| Button / Input / Select | `AccrueAdmin.Components.Button`, `.Input`, `.Select` | Keep existing labels, sizes, disabled/pending states, and focus treatment. |
| FlashGroup / EmptyState / Spinner | `AccrueAdmin.Components.FlashGroup`, `.EmptyState`, `.Spinner` | Preserve existing outcome announcements and state-specific presentation. |

---

## Spacing Scale

Inherit Phase 233's shared 4px-multiple scale; use existing package tokens and spacing. Do not add or rename tokens for Phase 239.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline icon/text gaps and tight grouping |
| sm | 8px | Compact control and label spacing |
| md | 16px | Default content and control spacing |
| lg | 24px | Card sections and related groups |
| xl | 32px | Major layout groups |
| 2xl | 48px | Page-level separation |
| 3xl | 64px | Large page breaks where layout permits |

Use only the listed scale for any phase-owned spacing decisions. Existing Portal navigation/button targets remain at least 40px high and icon-only targets at least 44px; coarse-pointer controls remain usable at their existing target size.

---

## Typography

Inherit the approved Phase 233 shared hierarchy. Admin technical identifiers keep Geist Mono; Portal inherits the configured host/system font. These are use roles, not new tokens.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Metadata / eyebrow | 12px | 600 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Page heading | 26px | 600 | 1.2 |

---

## Color

Use existing package semantic tokens and the active host/theme. 60/30/10 describes visual hierarchy, not fixed hex values.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Admin `--ax-base`; Portal `--accrue-surface-muted` | Page and broad shell background |
| Secondary (30%) | Admin `--ax-surface` / `--ax-elevated`; Portal `--accrue-surface` | Cards, grouped panels, navigation, raised surfaces |
| Accent (10%) | Admin `--ax-accent` and readable variants; Portal host `--accrue-brand-accent` with existing readable text/contrast bridge | Existing primary action, active navigation/selection, actionable links, and visible focus only |
| Destructive | Existing Admin danger and Portal semantic danger roles | Destructive actions or error states only |

Accent reserved for: the existing primary action within a local task group, active navigation or selection, links, and visible keyboard focus. Do not introduce accent treatment to make evidence capture appear successful. Status remains labeled in text; do not rely on color alone. Preserve Phase 233 contrast requirements and current light/dark/system/host-forced behavior.

---

## Copywriting Contract

Use current route and package copy verbatim for production surfaces. No new product CTA, empty-state language, or mutation flow is introduced by this phase.

| Element | Copy |
|---------|------|
| Primary CTA | In preview handoff, “Open Admin preview” or “Open Portal preview” as plain navigation labels to existing mounts; do not add an in-product CTA. Production routes retain their existing local primary action. |
| Empty state heading | Preserve each route's existing package copy; distinguish an actual empty collection from unavailable or failed data. |
| Empty state body | Preserve existing route-specific next step and copy; do not invent preview data or synthetic records to fill an empty state. |
| Error state | Preserve the package's actionable error copy and recovery path. State unavailable evidence distinctly from an empty result; never imply a successful provider action. |
| Destructive confirmation | None for preview/review: keep the feedback path read-only and do not expose replay, refund, mutation, reset, or reseed actions as review steps. Existing production confirmations remain governed by their route contracts. |

Label the example preview as Fake-backed and local. Its purpose is optional subjective visual feedback; it is not live-provider evidence, release approval, or verification of stable behavior. Keep proof/reset commands and test-database lifecycle outside preview instructions.

---

## Motion and Zoom

- Under `prefers-reduced-motion: reduce`, remove nonessential travel, overshoot, and skeleton shimmer. Preserve only the package's intentional opacity fades; state changes and feedback remain immediate and understandable without motion. Verify computed transition/animation behavior in the existing browser lane.
- Verify the representative Admin and Portal journeys at 200% zoom (the existing browser pattern uses a 640px viewport with `html.style.zoom = "2"`, yielding a 320 CSS-pixel effective viewport) and at a direct 320 CSS-pixel viewport. Essential identity and actions remain visible and operable, keyboard focus remains visible, and the document has no page-wide horizontal overflow.

---

## UI Considerations

The UI-consideration probe classifies three phase surfaces into **20 applicable state considerations: 20 resolved with explicit criteria, 0 backstop, 0 unresolved, 0 unclassified**. Each criterion below is explicit acceptance for the audit/preview contract; it does not assert that implementation or renders have already passed. Existing detailed state permutations remain covered by their slice suites. The current route/evidence ledger is the authority for which route-level checks are already current.

- **admin-representative-render** (`list-collection`, `nav`, `static-content`, `interactive-control`): one authenticated mounted Admin surface used for current shell/theme, keyboard, and responsive inspection.
- **portal-representative-render** (`list-collection`, `nav`, `static-content`, `interactive-control`): one customer-scoped mounted Portal billing surface, preserving host branding and selected billed-entity identity.
- **host-feedback-preview** (`nav`, `static-content`, `interactive-control`): existing host entry and mount handoff for read-only subjective feedback; no new UI or mutation pathway.

| Element / category | Status | Verification | Explicit acceptance criterion |
|---|---|---|---|
| admin-representative-render / empty | resolved | explicit | Preserve the route's existing empty copy and action. An empty collection stays distinguishable from unavailable or failed reads; detailed outcomes remain in deterministic package tests. |
| admin-representative-render / loading | resolved | explicit | Current render evidence records the settled mount. If pending behavior is inspected, keep feedback with its initiating control and preserve duplicate-submit protection; detailed pending permutations remain in focused tests. |
| admin-representative-render / error | resolved | explicit | Preserve route-specific error and safe recovery copy. Unavailable evidence is reported as unavailable, never as a passed render or empty result. |
| admin-representative-render / populated | resolved | explicit | Use seeded local Fake-backed data; preserve rendered identity, scope, status, amount/currency, and action labels. Do not synthesize missing facts. |
| admin-representative-render / partial | resolved | explicit | Preserve explicit unavailable/unsupported values alongside known facts. A representative render never implies complete route or interaction coverage. |
| admin-representative-render / overflow | resolved | explicit | At direct 320px and 200% zoom (640px viewport at 2x zoom), keep essential facts and actions available without page-wide horizontal scrolling; record route and viewport with evidence. |
| admin-representative-render / zero-one-many | resolved | explicit | Reuse deterministic zero/one/many fixtures at the lowest credible layer; a representative render supplements but never replaces collection tests. |
| admin-representative-render / long-text | resolved | explicit | Preserve wrapping/disclosure for long names and identifiers; render evidence must not clip essential identity or actions. Detailed adversarial fixtures stay in focused tests. |
| portal-representative-render / empty | resolved | explicit | Preserve the customer route's existing empty copy and action. An empty collection stays distinguishable from unavailable or failed reads; detailed outcomes remain in deterministic package tests. |
| portal-representative-render / loading | resolved | explicit | Current render evidence records the settled customer-scoped mount. If pending behavior is inspected, keep feedback with its initiating control and preserve duplicate-submit protection; detailed pending permutations remain in focused tests. |
| portal-representative-render / error | resolved | explicit | Preserve route-specific error and safe recovery copy. Unavailable evidence is reported as unavailable, never as a passed render or empty result. |
| portal-representative-render / populated | resolved | explicit | Use seeded local Fake-backed data; preserve customer/billed-entity scope, rendered status, amount/currency, and action labels. Do not synthesize missing facts. |
| portal-representative-render / partial | resolved | explicit | Preserve explicit unavailable/unsupported values alongside known customer-scoped facts. A representative render never implies complete route or interaction coverage. |
| portal-representative-render / overflow | resolved | explicit | At direct 320px and 200% zoom (640px viewport at 2x zoom), keep essential facts and actions available without page-wide horizontal scrolling; record route and viewport with evidence. |
| portal-representative-render / zero-one-many | resolved | explicit | Reuse deterministic zero/one/many fixtures at the lowest credible layer; a representative render supplements but never replaces collection tests. |
| portal-representative-render / long-text | resolved | explicit | Preserve wrapping/disclosure for long customer names and identifiers; render evidence must not clip essential identity or actions. Detailed adversarial fixtures stay in focused tests. |
| host-feedback-preview / loading | resolved | explicit | Keep preview navigation and feedback controls understandable during mount; do not imply that subjective feedback is an automated verification result. |
| host-feedback-preview / error | resolved | explicit | When a preview mount or resource is unavailable, label evidence unavailable and preserve a safe retry/navigation path; do not describe it as empty or verified. |
| host-feedback-preview / overflow | resolved | explicit | At 320px effective width, preserve navigation, preview context, and feedback controls without page-wide horizontal scrolling. |
| host-feedback-preview / long-text | resolved | explicit | Long route names, labels, or feedback text wrap or disclose deliberately without hiding the preview context or controls. |

Interaction/evidence limits: representative browser inspection may record keyboard/focus, direct and zoomed viewport, theme, reduced-motion, route reachability, and actually served-resource behavior where the coverage ledger indicates an integration seam. Stable acceptance stays automated in existing or newly justified required gates. Optional owner feedback is subjective and does not gate those assertions. Live-provider fidelity is out of scope for Fake-backed evidence; report it as external-only only if separately required. Do not repeatedly reopen a verified coverage row absent new evidence.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable; no shadcn, external registry block, package, or dependency is introduced. |

---

## Checker Sign-Off

- [x] Spacing: PASS
- [x] Typography: PASS
- [x] Color: PASS
- [x] Component/library and inventory: PASS
- [x] Motion: PASS
- [x] Accessibility (keyboard/focus, contrast, labels, target size, zoom): PASS
- [x] Responsive: PASS

**Approval:** approved 2026-10-09. All seven checker dimensions PASS.
