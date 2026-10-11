---
phase: "244"
slug: "operator-language-and-evidence"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-10"
---

# Phase 244 — UI Design Contract

> Retrospective design contract for the in-progress frontend phase. This records incumbent tokens and the approved interaction/evidence decisions for the remaining outcome slice; it does not authorize a redesign or widen the implementation scope.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, incumbent Accrue Admin design system |
| Preset | Not applicable; no shadcn `components.json` |
| Component library | Phoenix function components and source-owned CSS; no external component library |
| Icon library | Inline Heroicons already used by the Admin UI |
| Font | Geist / Geist Mono, with existing system fallbacks |

Existing design source: `accrue_admin/assets/css/theme.css` defines semantic type, spacing, color, and theme tokens; `app.css` and Phoenix components consume them. Keep existing light/dark/system theme behavior and host-brand token binding.

Primary-screen visual anchor: retain the existing operator-facing Admin hierarchy on Home, Events, event detail, and webhook detail: quiet base surface; clearly grouped, bordered/elevated cards and disclosure sections; compact readable labels above exact evidence; semantic status colors; and accent reserved for current actions, links, selection, and keyboard focus. This phase refines copy and evidence access within those existing surfaces and does not introduce a new layout or visual direction.

---

## Component Inventory

Could not enumerate: the UI is implemented with source-owned Phoenix components and CSS rather than an installed component-library package with an export inventory; package/version enumeration does not apply. The following list names known-used source-owned components for this phase. It is non-exhaustive and is not an allowlist; checking for and reusing other existing components is expected.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Timeline | `AccrueAdmin.Components.Timeline` | Existing activity rows, native `details`/`summary`, exact metadata and scoped links |
| Event detail | `AccrueAdmin.Live.EventLive` | Existing authorized event identity, timestamp, payload and activity disclosures |
| Webhook detail | `AccrueAdmin.Live.WebhookLive` | Keeps delivery state, attempt history and derived ledger events distinct |
| Copy | `AccrueAdmin.Copy` / `AccrueAdmin.Copy.BillingEvent` | Shared operator-facing labels and established vocabulary |

---

## Spacing Scale

Affected Phase 244 components use the existing 4px-grid scale only:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps and inline padding |
| sm | 8px | Compact element spacing |
| md | 16px | Default element spacing |
| lg | 24px | Section padding |
| xl | 32px | Layout gaps |
| 2xl | 48px | Major section breaks |
| 3xl | 64px | Page-level spacing |

Exceptions: None in Phase 244 changed components. The inherited 2px `--ax-space-2xs` token and other sub-grid spacing used outside changed components remain source-owned incumbent details; this phase does not redesign or redeclare them. The changed Timeline evidence disclosure uses the existing grid tokens (`--ax-space-sm` 8px and `--ax-space-md` 16px) for evidence spacing and padding. Preserve the observed 320px viewport behavior: long exact evidence wraps inside its disclosure with no horizontal page overflow.

---

## Typography

Use the existing Geist type scale and weights. Four sizes below cover the content touched by this phase; exact technical evidence uses the existing monospace token where already appropriate.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Evidence / compact label | 12px (`--ax-type-xs`) | 400 / 600 | 1.4 |
| Body | 14px (`--ax-type-sm`) | 400 / 600 | 1.4 |
| Section title | 20px (`--ax-type-lg`) | 600 | 1.2 |
| Page heading | 28px (`--ax-type-2xl`) | 600 | 1.2 |

Weights: regular 400 and semibold 600 only. Keep long-form body copy at the incumbent relaxed 1.5 line height when that existing role is used.

---

## Color

Keep the incumbent semantic tokens and effective light/dark/system theme. The ratio describes surface hierarchy, not a mandate to repaint existing components.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--ax-base` / `--accrue-paper` (light); `--ax-base` = `#0f1318` (dark) | Main page and content surface |
| Secondary (30%) | `--ax-elevated` / `--ax-sunken` | Existing cards, navigation, detail sections, and disclosure surfaces |
| Accent (10%) | `--ax-accent` with `--ax-accent-readable` | Existing primary action, links, selected navigation state, and visible keyboard focus indicator |
| Destructive | `--ax-danger` / `--ax-status-danger-*` | Existing destructive/error treatment only; do not introduce destructive action styling for ordinary navigation or read retry |

Accent reserved for: existing primary action, existing links, selected navigation state, and focus indicators. Keep success, warning, information, neutral, and error states on their incumbent semantic status tokens; outcome meaning must remain readable in text and not rely on color alone.

---

## Copywriting Contract

Copy follows `244-CONTEXT.md` D-01–D-10 and the completed `244-INVENTORY.md` vocabulary table. Known event labels remain producer-backed and shared; exact stored keys remain independently accessible. This is a presentation-only phase.

| Element | Copy |
|---------|------|
| Primary CTA | `View events` — scoped navigation to the Events list |
| Empty state heading | `No recent audit activity in this scope.` — existing Home timeline empty label |
| Empty state body | None; Home uses the existing one-line empty label. Events list first-run and filtered-empty states keep their distinct incumbent Copy strings. |
| Error state | `Event record unavailable` / `This event could not be loaded. Its identity and related evidence are unknown until the read succeeds.` Keep the existing read-recovery action labeled `Retry read`; it only re-reads. |
| Destructive confirmation | `Replay webhook`: retain the existing explicit confirmation and step-up boundary. State that replay is requested/queued only when queue/audit evidence supports it; never call queue acceptance processed or completed. |

Status semantics: completed, requested/queued, failed, blocked, and unable-to-confirm remain distinct. State only what event/job/dispatch/audit evidence establishes, name one supported next step, and leave an unknown cause unstated. A failed reread after accepted enqueue preserves the accepted request while current processing status remains unknown; read retry must never dispatch a second replay. Preserve `Copy.Locked` verbatim.

Evidence contract: exact event key, relevant scoped record identifiers, and full available timestamp precision/timezone stay discoverable at the investigation point. Home may keep compact time when existing event detail/disclosure exposes exact time. Evidence remains selectable, keyboard/touch accessible, and readable at 320px. Keep raw payload in its existing authorized detail context; do not duplicate it on Home.

Disclosure contract: keep native `details`/`summary` with an explicit contents-specific summary label. Keyboard activation moves through the native summary focus behavior and toggles with one activation. Through LiveView patches, preserve the operator's just-selected open or closed state; opening reveals available content and closing hides it. Long keys/IDs may wrap visually but their underlying selectable text remains exact.

---

## UI Considerations

Applicable state considerations resolved: 6 explicit, 29 backstop, 0 unresolved. The post-approval probe classified seven described surfaces as `list-collection`, `static-content`, `interactive-control`, and `nav`; it found no unclassified elements. These rows retain the surfaced state categories and owner scope. Empty/error copy is referenced above rather than repeated here.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | E2 Events list | ✅ covered | The Events view distinguishes first-run and filtered-empty states with established copy; `events_live_test.exs` asserts both. |
| empty | E1 Home activity; E4 Webhook activity | 🧪 backstop | Keep true empty collections distinct from unavailable or partial reads; owning Home and Webhook LiveView tests must assert the empty copy and state. |
| loading | E2 Events list | ✅ covered | The Events view renders its loading skeleton with `aria-busy` and established copy; `events_live_test.exs` asserts this state. |
| loading | E1 Home activity; E4 Webhook activity; E5 evidence disclosure; E6 navigation/actions; E7 outcome controls | 🧪 backstop | While an existing read or lazy disclosure is in flight, show an in-progress state and do not present it as empty or complete; verify through the owning LiveView/browser state test. |
| error | E2 Events list | ✅ covered | An unavailable event summary is announced and its control retries the read; `events_live_test.exs` asserts the failure and recovery state. |
| error | E1 Home activity; E4 Webhook activity; E5 evidence disclosure; E6 navigation/actions; E7 outcome controls | 🧪 backstop | Keep read failure distinct from empty data and mutation outcome; preserve the supported read-recovery action and evidence-backed uncertainty in the owning tests. |
| populated | E2 Events list | ✅ covered | Event rows render and pagination appends rows beyond the initial page; `events_live_test.exs` asserts both. |
| populated | E1 Home activity; E4 Webhook activity | 🧪 backstop | Render producer-backed event labels with scoped destinations, while webhook delivery, attempts, and derived events remain distinct; retain their owning LiveView assertions. |
| partial | E1 Home activity; E2 Events list; E4 Webhook activity | 🧪 backstop | When only part of a collection is available, state that shown results are incomplete and keep a read recovery path; verify partial-result branches in the corresponding LiveView tests. |
| overflow | E5 evidence disclosure | ✅ covered | At 320px, exact webhook event evidence remains inside the document without horizontal page overflow; `phase244-operator-evidence.spec.js @phase244-mobile` asserts this. |
| overflow | E1 Home activity; E2 Events list; E3 event detail; E4 Webhook activity; E6 navigation/actions; E7 outcome controls | 🧪 backstop | Keep rows and controls reachable when content exceeds the available width; wrap evidence or use incumbent collection overflow behavior, verified at narrow and wide viewports by affected owners. |
| zero-one-many | E1 Home activity; E2 Events list; E4 Webhook activity | 🧪 backstop | Preserve readable collections at zero, one, and many items; owning screen tests must cover those cardinalities without merging delivery and event counts. |
| long-text | E5 evidence disclosure | ✅ covered | Long exact identifiers remain selectable and wrap in the native disclosure at 320px; `phase244-operator-evidence.spec.js @phase244-mobile` asserts selection and layout. |
| long-text | E3 event detail; E6 navigation/actions; E7 outcome controls | 🧪 backstop | Preserve exact long evidence and truthful action labels without clipping, hiding, or changing underlying values; verify with the relevant detail and control owners. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable; no component registry or third-party blocks are used |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: FLAG — non-exhaustive source-owned inventory; no package export enumeration applies

**Approval:** approved 2026-10-10 (6 PASS, 1 non-blocking FLAG)
