---
phase: "248"
slug: "reproducible-scenarios-and-integrated-proof"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-11"
---

# Phase 248 — UI Design Contract

> Rendered proof contract only. This phase adds no production UI, visual redesign, scenario picker, or new product copy. Preserve the existing Admin surfaces from Phases 245–247. The frontend-token gate found no current frontend evidence; this contract therefore describes what new evidence must contain and does not claim that any scenario or appearance is already verified.

## Design System

| Property | Value |
|----------|-------|
| Tool | Accrue Admin in-repository design system; no shadcn |
| Preset | Not applicable |
| Component library | Custom Phoenix LiveView function components in `accrue_admin/lib/accrue_admin/components/` |
| Icon library | Existing inline Heroicons via `AccrueAdmin.Components.Icon` |
| Font | Self-hosted Geist and Geist Mono; retain system fallbacks |

Use existing shared shell, page, collection, detail, disclosure, status, analytics and theme owners. Preserve existing component geometry, tokens, copy and behavior except where the already-accepted Phase 246/247 findings own changes. Phase 248 verifies those surfaces; it does not add or change them. The ordinary Fake-host preview remains the default. Exceptional scenario setup and selection stay host-only and explicit.

The primary visual anchor in the ordinary invoice detail capture is the existing page title with its observed invoice status. Secondary billing evidence and the eligible action review follow that anchor. In empty, failure and boundary captures, retain the route's existing page title as the anchor and inspect whether its state message is visible before secondary identifiers or payload detail. This is a review target, not a new layout instruction.

## Component Inventory

Enumerated by `rg --files accrue_admin/lib/accrue_admin/components -g '*.ex' | sort | wc -l` — 43 component source files — `accrue_admin@1.6.0` (in-repository Phoenix UI; version from `accrue_admin/mix.exs`) — 2026-10-11. This sample is non-exhaustive and is not a closed allowlist; inspect the source inventory for other suitable components.

| Component | Import path | Notes |
|-----------|-------------|-------|
| AppShell | `AccrueAdmin.Components.AppShell` | Existing Admin frame, navigation and theme context |
| PageHeader | `AccrueAdmin.Components.PageHeader` | Existing route identity and supporting actions |
| DataTable | `AccrueAdmin.Components.DataTable` | Collections, row states and responsive rendering |
| EmptyState | `AccrueAdmin.Components.EmptyState` | Genuine empty and filtered-to-zero states |
| Detail / DetailDrawer | `AccrueAdmin.Components.Detail`, `AccrueAdmin.Components.DetailDrawer` | Existing record and overlay investigation surfaces |
| Timeline / JsonViewer | `AccrueAdmin.Components.Timeline`, `AccrueAdmin.Components.JsonViewer` | Activity and exact payload inspection |
| StatusBadge / InlineId | `AccrueAdmin.Components.StatusBadge`, `AccrueAdmin.Components.InlineId` | Semantic status and exact identity |
| WindowSelector / KpiCard | `AccrueAdmin.Components.WindowSelector`, `AccrueAdmin.Components.KpiCard` | Existing recovery analytics controls and metrics |

## Spacing Scale

Retain the incumbent semantic spacing tokens. Capture and review rendered spacing without normalizing or redesigning it.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact element spacing |
| md | 16px | Default element spacing |
| lg | 24px | Section padding |
| xl | 32px | Layout gaps |
| 2xl | 48px | Major section breaks |
| 3xl | 64px | Page-level spacing |

Exceptions: none in the declared scale. The incumbent `--ax-space-2xs: 2px` is legacy evidence only; do not treat it as a new contract token or change it in this phase.

## Typography

These roles describe the incumbent baseline to preserve during rendered review, not a new type scale.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px (`--ax-type-md`) | 400 | 1.4 |
| Label | 14px (`--ax-type-sm`) | 600 | 1.4 |
| Heading | 28px (`--ax-type-2xl`) | 600 | 1.2 |
| Display | 36px (`--ax-type-3xl`) | 600 | 1.2 |

Weights: 400 and 600. Keep Geist Mono for exact IDs, timestamps, keys and payload evidence. Existing other token sizes are observed legacy values, not new phase roles.

## Color

Preserve the existing light and dark theme tokens. The 60/30/10 split is a qualitative surface guide, not a pixel quota.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light `--ax-base` / Paper `#fafbfc`; dark `#0f1318` | Main canvas |
| Secondary (30%) | Light `--ax-elevated` `#ffffff` and `--ax-sunken` `#f1f5f8`; dark `--ax-elevated` `#171d24` and `--ax-sunken` `#0b1015` | Navigation, cards, tables and recessed surfaces |
| Accent (10%) | Existing theme-aware `--ax-accent` / Cobalt `#5d79f6` | Existing primary actions, links, selected and focus states only where assigned |
| Destructive | Existing theme-aware `--ax-danger` variants | Destructive actions and evidence-supported danger states only |

Accent reserved for: existing primary actions, links, selected navigation/filter/control state, and visible keyboard focus as already assigned. Status meaning must remain explicit in text and not depend on color.

## Copywriting Contract

Phase 248 adds no operator-facing product copy or action. Preserve the exact route copy under review and record it with the route/state evidence. Scenario names and host command output are evaluation metadata, not production UI.

| Element | Copy |
|---------|------|
| Primary CTA | No new CTA. Record the exact existing CTA on any route captured; do not add an action for proof selection. |
| Empty state heading | No new copy. Record the rendered heading and whether the state is genuinely empty or filtered-to-zero. |
| Empty state body | No new copy. Record the rendered explanation and supported next step; do not infer recovery actions. |
| Error state | No new copy. Record the actual visible failure and supported retry/return path; distinguish application failure from unavailable fixture or host. |
| Destructive confirmation | None introduced. Scenario cleanup must be explicit and isolated; rendered verification must not reset or delete preview data. |

## Rendered Proof Contract

Build a compact representative matrix, not a full Cartesian product. Use repeatable viewport dimensions `1280×900` (wide) and `320×820` (narrow), and capture light and dark themes. Include a distinct image per required scenario/state combination; a manifest or DOM assertion alone does not satisfy visual review.

| Scenario/state | Representative route | Required visible evidence | Theme/viewport coverage |
|----------------|----------------------|--------------------------|-------------------------|
| Ordinary populated billing story | Existing ordinary invoice detail route, such as `/admin/invoices/e8f9ba69-ee85-4efa-9939-d9a8979429f4` only if that record is still selected by the ordinary fixture | Record identity, observed status, truthful billing evidence and the existing eligible/disabled action state; verify that state selection did not alter the ordinary preview | Wide light and narrow dark; capture the paired theme or viewport variant if this route is the primary changed surface |
| Genuine empty state | A mounted billing collection route with an explicitly empty isolated evaluation dataset | Empty-state copy and layout; prove zero records from the selected isolated scenario and distinguish it from filters, access denial or a load failure | Wide light and narrow dark |
| Failed billing or webhook state | A mounted failed payment or failed webhook record from the isolated Fake-host fixture | Observed failure status, qualified history and only the supported next action; do not describe a failed record as an application error | Wide dark and narrow light |
| Boundary/long-content | Existing test-owned boundary detail route/state; a webhook detail route may reuse the Phase 247 shape `/admin/webhooks/:id` when that fixture is deliberately selected | Long IDs/text/payload and narrow layout; exact values remain available, content stays within viewport/container, and action/authorization/confirmation boundaries are unchanged | Narrow light and wide dark |
| Integrated changed-surface sample | Route(s) tied to accepted Phase 246/247 findings, selected from the canonical findings ledger | Capture the actual changed surface and matching interaction state; connect capture to finding, owner, executed check and current revision | At least one light and one dark inspection across the selected changed surfaces |

The example IDs above are historical Phase 247 fixture identifiers, not guaranteed current scenario identities. Resolve actual route and scenario from the selected host fixture for this run and record them in the manifest. Do not count an unsupported state as covered merely because a related route rendered.

For every image, record exact scenario identity, route, state, origin lane (ordinary or isolated/held-out), viewport dimensions, theme, source revision, served CSS and JS paths plus SHA-256 digests, screenshot digest, browser/version, and `inspection_status`. The reviewer must inspect the image and record inspection attribution/time. Capture from the same run as the asset and source provenance. Prior 245–247 captures remain historical unless their source and served asset identities match this exact tested revision.

Every required scenario gets an explicit reproducibility entry with preconditions, host-only selection command, expected route and visible result, cleanup scope, and data custody. Require `ACCRUE_HOST_SKIP_SEEDS=1` and the explicit `ACCRUE_HOST` target where applicable. Never log credentials. Do not expose scenario selection in production Admin. If a required route/state cannot be safely and deterministically rendered, record it as unsupported/unavailable with a concrete reason and leave it uncovered.

Visual review obligations: inspect every required image at full size for hierarchy, clipping, overflow, contrast, focus and truthful state; compare the surface to the incumbent tokens/components and the Phase 246/247 contract; note both defects and confirmed preservation. For interaction-dependent findings, separately execute and record keyboard/pointer behavior (touch at narrow width where relevant), selected/focus/disclosure/action confirmation state, and supported failure feedback. Screenshots, source hashes, asset hashes and automated accessibility detectors do not independently prove interaction correctness, owner acceptance or accessibility conformance.

## UI Considerations

Applicable proof-state considerations: 8 covered by explicit capture/review obligations. This specifies evidence coverage; it is not a claim that current images exist or that the UI passed review.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Billing collection and history | ✅ covered | Capture the named isolated empty state on its mounted route; confirm true zero data and preserve the empty copy from the Copywriting Contract. |
| loading | Async collection/detail/analytics read, if exposed by selected routes | 🧪 backstop | Record only an actually reproducible pending state; otherwise state not observed. Verify it belongs to the active read, with a current rendered cue. |
| error | Route/read/action failure | 🧪 backstop | Record an application error only if a separate deterministic fixture supports it; the required failure scenario is a failed billing or webhook record, not an app error. |
| populated | Ordinary billing route and changed Phase 246/247 surfaces | ✅ covered | Capture ordinary scenario identity, material visible evidence and actual action eligibility; tie each changed surface to its finding and owning check. |
| partial | Records with missing or unsupported evidence | 🧪 backstop | Review a representative partial record if available; absent/unsupported values remain absent or unavailable, never inferred. Mark unavailable combinations explicitly. |
| overflow | Long IDs, payloads, labels and action regions | ✅ covered | Inspect held-out boundary fixture at 320px and wide reference; exact values remain accessible without page-level horizontal overflow. |
| zero-one-many | Collection route | 🧪 backstop | Record which zero, one and many variants the isolated fixtures actually support; do not synthesize an unsupported state for screenshots. |
| long-text | Names, identifiers, payload keys and error/helper copy | ✅ covered | Use the existing test-owned boundary fixture; confirm wrapping/contained scrolling and exact-value access in the image and interaction review. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable; no shadcn or third-party registry |

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: PASS

**Approval:** pending
