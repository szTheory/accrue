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

Applicable state considerations resolved: 6 explicit, 29 backstop. The post-approval probe classified seven described surfaces as `list-collection`, `static-content`, `interactive-control`, and `nav`; it found no unclassified elements. The audit below checks each row against the changed behavior and current owner assertions. Unavailable STATE-01 edge classification and descriptor-less prohibition flags remain independent verifier-review items, not UI category passes.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | E2 Events list | ✅ covered | The Events view distinguishes first-run and filtered-empty states with established copy; `events_live_test.exs` asserts both. |
| empty | E1 Home activity; E4 Webhook activity | ✅ covered | Home's scoped empty state is asserted alongside its Events destination; Webhook Activity asserts separate empty attempt and derived-event collections. See `dashboard_live_test.exs` and `webhook_live_test.exs`. |
| loading | E2 Events list | ✅ covered | The Events view renders its loading skeleton with `aria-busy` and established copy; `events_live_test.exs` asserts this state. |
| loading | E1 Home activity | — not applicable | Home loads its six recent rows synchronously in `DashboardLive.mount/3`; there is no separate loading or partial-result branch. |
| loading | E4 Webhook activity; E5 evidence disclosure | — not applicable | Webhook detail reads synchronously; Activity has an intentional pre-load instruction, then renders both collections synchronously on activation. No in-flight state is modeled. `webhook_live_test.exs` covers activation and resulting content; the mounted browser tests keyboard/touch activation and disclosure persistence. |
| loading | E6 navigation/actions; E7 outcome controls | — not applicable | Scoped links navigate directly and replay uses an explicit confirmation/step-up flow with synchronous LiveView outcomes. No separate pending state is modeled; owner assertions cover destinations and mutation outcomes. |
| error | E2 Events list | ✅ covered | An unavailable event summary is announced and its control retries the read; `events_live_test.exs` asserts the failure and recovery state. |
| error | E1 Home activity | — not applicable | Home has no activity-specific read-error state; its synchronous mount query has no fallback branch in `DashboardLive`. No error UI is claimed for this slice. |
| error | E4 Webhook activity | ✅ covered | A failed webhook detail read renders unavailable and Retry read restores evidence; accepted replay with a failed follow-up read remains accepted with current status unknown. The browser state remains unobserved and is not claimed. See `webhook_live_test.exs` and `webhook_replay_test.exs`. |
| error | E5 evidence disclosure | — not applicable | Evidence disclosure has no independent read request or error branch; its content comes from the loaded event/webhook detail. |
| error | E6 navigation/actions; E7 outcome controls | ✅ covered | The `Retry read` action is exercised through unavailable/recovered event and webhook detail tests; replay outcome tests assert blocked, denied, failed, unknown, and accepted outcomes against durable state, jobs, and audit facts. Ordinary scoped links have no separate error branch. |
| populated | E2 Events list | ✅ covered | Event rows render and pagination appends rows beyond the initial page; `events_live_test.exs` asserts both. |
| populated | E1 Home activity; E4 Webhook activity | ✅ covered | Home renders known event meaning and its scoped destination; webhook rows render shared meanings and exact evidence while delivery and attempts remain separate. Zero/many assertions complement existing one-row cases. |
| partial | E1 Home activity; E2 Events list; E4 Webhook activity | — not applicable | Home intentionally presents the six most recent rows; Events paginates and appends rows; webhook detail loads related facts as a unit or reports unavailable. None has a partial-collection failure branch in this contract. |
| overflow | E5 evidence disclosure | ✅ covered | At 320px, exact webhook event evidence remains inside the document without horizontal page overflow; `phase244-operator-evidence.spec.js @phase244-mobile` asserts this. |
| overflow | E1 Home activity; E2 Events list; E6 navigation/actions | — not applicable | This phase changes fixed operator labels and destinations on these surfaces, not their layout or data-width contract. Exact evidence remains in scoped detail. No narrow-width claim is made for these surfaces. |
| overflow | E3 event detail; E4 Webhook activity; E7 outcome controls | ✅ covered | At 320px, the full EventLive timestamp fits without document overflow; related webhook evidence and replay step-up controls remain reachable with no horizontal overflow. See the tagged mobile browser assertions. |
| zero-one-many | E1 Home activity; E2 Events list; E4 Webhook activity | ✅ covered | Home asserts empty and multiple scoped rows, with a pre-existing one-row fixture; Events asserts empty, populated, and >25-row pagination; Webhook Activity asserts empty, one, and multiple derived rows with labels/evidence attached to their own IDs. |
| long-text | E5 evidence disclosure | ✅ covered | Long exact identifiers remain selectable and wrap in the native disclosure at 320px; `phase244-operator-evidence.spec.js @phase244-mobile` asserts selection and layout. |
| long-text | E3 event detail; E6 navigation/actions; E7 outcome controls | — not applicable | The changed labels and controls are fixed short strings; the exact recorded time is fixed-format and covered at 320px. This phase adds no unbounded label text. |

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
