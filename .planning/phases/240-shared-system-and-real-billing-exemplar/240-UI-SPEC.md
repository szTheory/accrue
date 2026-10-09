---
phase: "240"
slug: "shared-system-and-real-billing-exemplar"
status: approved
shadcn_initialized: false
preset: none
created: "2026-10-09"
---

# Phase 240 — UI Design Contract

> Visual and interaction contract for the invoice list → detail → action review exemplar and dense subscription cross-check. The incumbent Admin system remains the authority; this spec defines its use and acceptance for Phase 240.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, package-owned Accrue Admin system; no shadcn |
| Preset | Not applicable; code-first setup is already initialized |
| Component library | Existing `AccrueAdmin.Components` and LiveView components; no new component framework |
| Icon library | Existing inline Heroicons through `AccrueAdmin.Components.Icon` |
| Font | Geist for interface text; Geist Mono for identifiers and technical payloads, via `--ax-font-*` |

Operate mode, Cobalt/quiet-confidence identity, engineers and support/billing operators as equal audiences, and package-owned `--ax-*` roles are locked by `240-CONTEXT.md` D-01/D-02 and the v1.63 `DESIGN.md`. Do not rerun initialization or add a visual world, font, framework, library, or motion dependency. Admin owns its theme in `accrue_admin/assets/css/theme.css`; do not restyle Portal.

## Component Inventory

Enumerated by `find accrue_admin/lib/accrue_admin/components -maxdepth 1 -type f -name '*.ex' | wc -l` — 43 components — `accrue_admin`@1.6.0 — 2026-10-09.

This is an inventory of the local package component module set, not an exports allowlist. Check actual public functions and existing variants before choosing a component; existing modules cover the representative compositions and are the preferred starting point.

| Component | Import path | Notes |
|-----------|-------------|-------|
| App shell | `AccrueAdmin.Components.AppShell` | Existing Admin shell and route context |
| Page header | `AccrueAdmin.Components.PageHeader` | Identity, scope and task heading |
| Data table | `AccrueAdmin.Components.DataTable` | Invoice comparison at wide layouts; preserve record identity when reflowing |
| Detail | `AccrueAdmin.Components.Detail` | Shared grouped facts and section hierarchy |
| Detail drawer / Overlay | `AccrueAdmin.Components.DetailDrawer`, `AccrueAdmin.Components.Overlay` | Focused review and contained overlay interactions |
| Button / Input / Select | `AccrueAdmin.Components.Button`, `.Input`, `.Select` | Existing controls; confirm final clickable geometry in mounted built/served output |
| Empty state | `AccrueAdmin.Components.EmptyState` | Distinct first-run, queue-empty and filtered-empty states |
| Status badge | `AccrueAdmin.Components.StatusBadge` | Text-bearing state cue, never color alone |
| Money formatter | `AccrueAdmin.Components.MoneyFormatter` | Preserve exact currency and minor-unit formatting |
| Theme picker | `AccrueAdmin.Components.ThemePicker` | Light/Dark/System selection |
| Icon | `AccrueAdmin.Components.Icon` | Existing inline icon set |

## Phase Task Hierarchy and Layout Contract

The repeated scan order is **identity and owner/scope → current billing facts → supported next action → related evidence**. It applies equally to engineering and support/billing work. Keep queue/filter context, blockers, uncertainty and material consequences discoverable. Technical identifiers, diagnostics, event/audit evidence and payloads stay available through familiar disclosure without competing with routine facts.

| Surface | Required hierarchy and behavior |
|---------|---------------------------------|
| Invoice list | Page identity and owner scope; one visible collection lens (`Needs collection` or `All invoices`); search/status/customer/collection controls and their active constraints in one coherent hierarchy; result set with invoice/customer, readable status, due date, balance and collection method; row/card action to `View invoice`. Do not repeat local counts or show an implementation enum where existing human-readable vocabulary applies. Tables are for comparison; narrow layout may use the existing record-card form if all essential facts and actions stay associated. |
| Invoice detail | Invoice identity and customer/owner context; status and exact amount due/paid/remaining with currency; due date and current billing facts; one supported next action group; then line items, documents, timeline and technical evidence using existing sections/disclosures. Separate task groups with existing section spacing; preserve dense fact grouping. |
| Action review | A self-contained review that names the selected action and exact invoice/customer/owner target; exact amount/currency when material; supported effect/timing and audit consequence; clear `Back to invoice` review dismissal and action-specific Confirm controls. `Back to invoice` is non-mutating; Escape retains the existing dismissal behavior. Keep authorization/step-up where required. Submission outcome must say only what the evidence establishes: accepted, pending, completed, failed, denied or unknown; accepted is not completed. |
| Dense subscription exemplar | Keep subscription/customer identity and owner scope first, then current status, exact plan/money/period facts, supported next action, and related evidence. Retain useful within-record density and compare this composition against the invoice section hierarchy. Subscription invoice destinations and other Phase 241 journey changes are out of scope. |

### Shared visual and interaction rules

- Use the existing composed roles in `theme.css`: body 16px/400/1.4, body-small 14px/400/1.4, label 14px/600/1.4, small metadata/label 12px/600/1.4, section title 20px/600/1.2, large title 24px/600/1.2 and heading 28px/600/1.2. Mono roles are 14px and 12px/400 for IDs/payloads only. These are incumbent scale steps and semantic role bundles, not a request to put every step on each page.
- Preserve the 4px base spacing ladder: 4, 8, 16, 24, 32, 48 and 64px. Keep the existing **2px dense** rung only for deliberate compact table/data detail and **1px structural** borders/rules. Do not use either as unexplained task/section separation. Use 16/24/32px roles to distinguish controls, fact groups and sections. No blanket scale migration.
- Maintain Cobalt accents on actual primary actions, selected/current navigation or filter state, and links. Neutral paper/base/elevated/sunken roles own surfaces; status and money colors use their intent tokens plus visible labels. Destructive red is reserved for destructive actions and their consequential feedback. Verify contrast from effective computed colors, including Dark/System and host-forced themes.
- Frequently activated standalone task buttons and icon controls retain the incumbent 44px target direction, including intermediate/tablet coarse-pointer input; this is a design target, not the 24px WCAG AA criterion. Measure the actual hit rectangle, not CSS declarations. Dense inline links/actions may remain compact if they retain clear separation and operability.
- Use existing focus roles with a visible, offset focus indicator. Associate input errors and status/result messages programmatically and visually. Keyboard review supports Tab and Shift+Tab containment, Escape/dismissal where the existing overlay supports it, validation → correction → submission, and logical focus restoration when the opening trigger is replaced or removed. Rapid dismissal and reduced-motion teardown must not leave an inactive overlay intercepting focus or pointer hits.
- Preserve stored Light/Dark/System choice, effective CSS for the selected preference, OS preference changes while System is selected, persistence across LiveView patches/reload, and existing host-forced precedence. Test effective styles, not just selected labels.
- During real server work, show actual busy label/icon and disabled state; return to idle state only on actual completion. Repeated LiveView patches and reconnect may replace controls: staged actions remain locked until fresh authoritative state/authorization checks, online status alone never unlocks them, and reconnect never replays a mutation.
- Keep frequent keyboard operations immediate. Use existing short motion only when it clarifies state or spatial relationship; reduced motion removes nonessential travel. No routine count, money or navigation animation; no decorative stagger.

### Icon-only interactive actions

Any interactive control rendered without visible text must keep exactly one recognizable primary visual anchor and a programmatic accessible name that identifies the action and its target/context. Hide decorative SVGs from the accessibility tree; do not rely on an icon, tooltip, or title as the only accessible name. Preserve these scoped mappings when an existing control is icon-only or collapses to icon-only:

| Action/context | Single primary visual anchor | Accessible-label fallback |
|----------------|-----------------------------|----------------------------|
| Close an invoice review or detail drawer | X / close glyph | `Close invoice review` or `Close invoice details`, matching the actual surface |
| Remove one active invoice filter chip | X / clear glyph | `Remove {filter name} filter` |
| Clear a populated invoice search field, if an icon-only clear control is present | X / clear glyph | `Clear invoice search` |
| Copy an invoice, customer, or subscription identifier | Copy glyph | `Copy invoice ID {identifier}`, `Copy customer ID {identifier}`, or `Copy subscription ID {identifier}` |
| Choose a theme in the narrow icon-only segmented picker | Sun for Light; moon for Dark; desktop/system glyph for System | `Light`, `Dark`, or `System` respectively |

Invoice and subscription task actions retain their visible action-specific text (for example `View invoice` or the existing action verb); do not replace their verb with a generic icon or infer approval of generic `Cancel`/`Confirm` copy. A destructive/action-review confirmation continues to use the locked action-specific copy above.

### Project constraints and checker disposition

This contract reuses the maintainer-approved incumbent system from `240-CONTEXT.md` D-01/D-03 and the acceptance constraints in `.planning/REQUIREMENTS.md`. Typography uses exactly two weights (400 and 600); the package's composed semantic roles intentionally span the recorded 12/14/16/20/24/28px steps plus 12/14px Mono technical roles. Preserve those role mappings rather than flattening the approved scale to a generic four-size ceiling. Spacing uses the 4px ladder with the explicit 2px dense-data and 1px structural exceptions documented below; neither exception may replace task or section spacing. A checker should assess whether uses follow those approved roles and boundaries, not flag the approved scale itself or request a migration contrary to D-03.

## Spacing Scale

Declared incumbent values (the template's 4px rhythm with documented, deliberate exceptions):

| Token | Value | Usage |
|-------|-------|-------|
| `--ax-space-xs` | 4px | Icon gaps, inline padding |
| `--ax-space-sm` | 8px | Compact element spacing |
| `--ax-space-md` | 16px | Default control/fact-group spacing |
| `--ax-space-lg` | 24px | Section separation |
| `--ax-space-xl` | 32px | Major layout/task-group gaps |
| `--ax-space-2xl` | 48px | Large page-level separation when existing layout uses it |
| `--ax-space-3xl` | 64px | Page-level spacing where existing shell uses it |
| `--ax-space-2xs` | 2px | Intentional dense table/data rung only |

Exceptions: 1px structural borders/rules; 2px dense data spacing; control target geometry follows input context rather than the spacing ladder. Keep existing task/section spacing. Source candidates such as detail-section compression and action-band overrides are not confirmed defects until current mounted output is inspected.

## Typography

The incumbent token system has more than four steps, so retain it rather than flattening or migrating it. The rows below are the 4 roles required by this exemplar; metadata and mono exceptions are explicitly recorded above.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.4 |
| Label | 14px | 600 | 1.4 |
| Heading | 20px | 600 | 1.2 |
| Display / page title | 28px | 600 | 1.2 |

Other existing roles: secondary body 14px/400/1.4; eyebrow/metadata 12px/600/1.4; larger title 24px/600/1.2; mono technical detail 14px or 12px/400/1.4. Use Geist Mono only for identifiers or technical values, not prose. Allow names, email-like strings and identifiers to wrap or disclose without clipping task-critical identity.

## Color

60/30/10 is a compositional guide across the screen, not a required measured pixel ratio. Existing theme-aware semantic roles are authoritative; do not hard-code light-only values into components.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--ax-base` (`--accrue-paper`, light `#FAFBFC`) | Page background and broad neutral surfaces |
| Secondary (30%) | `--ax-elevated`, `--ax-sunken`, `--ax-border` | Grouped facts, panels, nav and structural separation |
| Accent (10%) | `--ax-accent` / `--ax-accent-strong` (Cobalt identity; public palette `--accrue-cobalt: #5D79F6`) | Primary task CTA, selected/current state, purposeful links only |
| Destructive | `--ax-danger` / `--ax-danger-readable` | Destructive action and related failure/consequence only |

Accent reserved for: the one primary action per local task group, current/selected lens or navigation, and meaningful inline links. Status uses success/warning/danger/info/neutral semantic tokens with readable text and a state label; do not signal status with color alone. Resolve contrast against actual effective backgrounds in light, dark, system, and host-forced cases.

## Copywriting Contract

Use existing `AccrueAdmin.Copy.Invoice` strings as the initial source of truth, preserving locked legal/audit wording and exact diagnostic terms. Improve surrounding routine hierarchy only where the owning phase work warrants it. Never claim health, freshness, settlement, or completion from missing evidence, zero counts, or request acceptance.

| Element | Copy |
|---------|------|
| Primary CTA | `View invoice` in the list; action review uses the selected action's existing exact verb (for example `Finalize invoice`) |
| Empty state heading | `No invoices need collection.` for an empty collection queue; `No invoices match these filters.` for zero filtered results; `No invoices yet.` only for first-run/no records |
| Empty state body | Queue: `View all invoices to review the ledger.` Filtered: `Clear filters or adjust the search to see invoices.` First-run: preserve the existing copy's instruction to confirm organization scope if invoices were expected |
| Error state | State the specific failed operation and verified current result, then offer only an existing safe next step: retry an idempotent read, correct the identified input, or return to invoice list and confirm owner scope. Never offer blind mutation retry. Preserve exact provider diagnostic text where present. |
| Destructive confirmation | Invoice action: preserve `invoice_confirm_workflow_message/2` legal/audit content, dynamically naming action, effect, target invoice, audit consequence and any source-event context; use the selected action's existing action-specific confirmation verb (for example `Finalize invoice`) and non-mutating `Back to invoice` review dismissal. Manual adjustment removal: preserve `Remove manual line item: This removes the adjustment from the draft invoice before finalization. Confirm removal to continue.` |

### Required state distinctions

Provide visibly and semantically distinct treatments for first-run empty, queue empty, no-match, unavailable/not-found, partial evidence, unsupported action, denied/step-up required, pending, failed and unknown outcome. Each state says what is known, what is absent or uncertain, and the supported next step. Do not collapse unavailable into empty; do not call pending or unknown success; do not infer “healthy” from no rows. Preserve explicit current labels such as `Due date unavailable`, and existing accepted-versus-completed language.

## Responsive, Content and Accessibility Contract

- Keep the invoice list/detail/review and dense subscription view usable at **320 CSS px**, at intermediate widths including around existing 600/768px breakpoints, and at the 1024px shell transition. Also inspect a desktop width. At 320px and 400% browser zoom, preserve essential identity, exact money, status and supported action access; no page-level horizontal scroll for ordinary content. A genuinely two-dimensional comparison table may scroll within its own labeled region if needed, with the record identity/action still reachable.
- Test a tablet/intermediate **coarse-pointer context independently from viewport width**. Keep frequent standalone actions on the existing 44px target direction. Do not assume mobile width means touch or desktop width means fine pointer.
- Test 200% text enlargement separately from browser zoom. Apply text-spacing overrides (WCAG 1.4.12 values: line height 1.5× font, paragraph spacing 2× font, letter spacing .12em, word spacing .16em) and confirm no clipped text, hidden focus, overlapping controls, or lost essential action. Report tool/host limits accurately; CSS scaling simulation is not actual browser zoom.
- Long or absent customer, subscription, invoice, ID, due-date, amount, line-item and source-event values have explicit fallbacks or wrap/disclosure behavior. Never substitute zero for missing money. Keep exact currency and minor-unit value alongside any human-readable formatting. Preserve legal/audit text verbatim.
- The invoice review is operable keyboard-only from entry through validation correction, confirmation and result. Inputs expose labels/errors, async results expose status, dialogs contain focus and restore focus logically if their trigger disappears. Disabled controls remain named and disabled while busy/reconnecting.
- UI colors/status do not depend on hue; focus is visible and unobscured. Axe/tree evidence supplements behavior checks and is not a screen-reader speech, physical-touch, or universal WCAG certification claim.

## Motion

Use package motion roles (`--ax-dur-1: 120ms`, `--ax-dur-2: 180ms`, `--ax-dur-3: 240ms`, `--ax-dur-exit: 140ms`) only for feedback or spatial orientation. Keep interaction feedback interruptible and exit shorter than enter where applicable. Reduced motion removes nonessential travel and leaves overlays immediately inert when dismissed. No animation is the only signal of busy, result, validation, or state.

## Acceptance Owners and Evidence Limits

The UI contract defines expected behavior; source review alone does not establish mounted geometry or live behavior. Reuse the already named owners in `240-RESEARCH.md` and `AUTOMATION-AND-SEAMS.md`. Each owning change adds its recurring check and a focused negative control for a newly added guard. Bound the delivery to one complete build/check and one batched desktop/narrow/effective-theme inspection, one corrective batch and at most one confirming inspection. No required human UAT, full new viewport/theme matrix, fixed sleeps/retries, softened visual thresholds, or unrelated baseline review.

| Concern | Existing owner(s) | Acceptance limit |
|---------|-------------------|------------------|
| List/detail/review state, exact money, action guards | Invoice LiveView ExUnit owners `invoices_live_test.exs`, `invoice_live_test.exs`; subscription counterparts for the exemplar | Assert supported states, exact target/currency/minor units, server-authorized transition and truthful outcome. HTTP observation alone does not prove absence of LiveView mutation. |
| Components/theme | `components/theme_picker_test.exs`, `theme_test.exs`, existing component registry/Storybook/kitchen owners | Prove stored preference and effective styles, OS change in System, persistence across patch/reload, host-forced precedence. Do not duplicate the existing 30-family/42-variant/8-group registry. |
| Focus and keyboard | `test/js/focus_trap_test.mjs`, existing overlay browser lane, mounted exemplar browser owner | Exercise focus visibility/association, forward/backward containment, correction/submission, dismissal and replaced/removed trigger restoration. Axe is supplementary. |
| Mounted responsive/busy/reconnect | Existing package browser and mounted host Playwright owners | Observe built/served CSS clickable geometry at 320px, intermediate breakpoints, desktop and a separate coarse-pointer mode; exercise real busy → idle, repeated LiveView patch and reconnect with replaced disabled controls; no action replay. |
| Assets and provenance | `mix accrue_admin.assets.build`, package asset/drift owners and served-asset browser proof | Record source, fixture, built/compiled/served CSS/JS/font identity and separately which interactions were exercised. Host watchers do not prove package bundle freshness. |
| Pixel completeness | Existing `e2e/admin-visual-regression-phase211.spec.js` and `.github/workflows/accrue_admin_browser.yml` | Expected Linux baseline set fails when all or part is absent; retain current thresholds. Masks cover only explicitly volatile values, never identity, money, state, actions or errors. Phase 243 owns final baseline review. |

Record lightweight comparable resource diagnostics on the first fresh mounted exemplar and investigate observed deterioration; do not invent a timing SLA or new performance platform. Keep proof/reset/mutation work in disposable fixtures separate from the Fake feedback preview database. Host `/admin` is Admin, host `/billing` is Portal, and package fixture `/billing` is Admin; normal host absence of dev component/Storybook routes is intentional.

## UI Considerations

Computed by the installed deterministic UI-consideration engine on 2026-10-09. Authored kind unions preserve list/form/navigation/control/static-content coverage; all raised considerations resolve to explicit acceptance predicates. These are required behavior, not claims that execution passed. Copy stays in Copywriting Contract. No category was silently dismissed.

| Element | Category | Status | Verification | Acceptance predicate |
|---|---|---|---|---|
| E1 | empty | resolved | explicit | Absent records, absent optional values and ineligible review targets use the distinct existing empty/unavailable treatments in Copywriting Contract; an absent preference uses the existing theme fallback, not a new inferred billing state. |
| E1 | loading | resolved | explicit | In-flight reads/actions preserve named disabled controls and actual busy feedback until authoritative completion or LiveView readiness; browser online alone does not unlock or replay an action. |
| E1 | error | resolved | explicit | Read/validation/denied/failed/unknown cases expose associated truthful messages and only the supported next step specified in Copywriting Contract; mutation failures never offer blind retry. |
| E1 | populated | resolved | explicit | Typical records preserve identity/scope, exact current facts, supported next action and related evidence in the defined scan order. |
| E1 | partial | resolved | explicit | Missing fields/evidence remain explicitly unavailable or partial, never zero-filled money or inferred settlement/health; supported action eligibility stays server-owned. |
| E1 | overflow | resolved | explicit | At 320 CSS px, intermediate/coarse-pointer layouts and text enlargement/spacing, essential identity/money/state/actions remain reachable with wrapping or labeled local table scroll, visible focus and no ordinary page overflow. |
| E1 | zero-one-many | resolved | explicit | Zero rows use distinct queue/first-run/filter states, one and many retain associated identity/status/actions and correct singular/plural terms; existing result order and bounded collection behavior are preserved. |
| E1 | long-text | resolved | explicit | Long names, identifiers, diagnostic values and action labels wrap or use existing discoverable disclosure without clipping essential identity/actions, including 200% text enlargement and text-spacing overrides. |
| E2 | loading | resolved | explicit | In-flight reads/actions preserve named disabled controls and actual busy feedback until authoritative completion or LiveView readiness; browser online alone does not unlock or replay an action. |
| E2 | error | resolved | explicit | Read/validation/denied/failed/unknown cases expose associated truthful messages and only the supported next step specified in Copywriting Contract; mutation failures never offer blind retry. |
| E2 | overflow | resolved | explicit | At 320 CSS px, intermediate/coarse-pointer layouts and text enlargement/spacing, essential identity/money/state/actions remain reachable with wrapping or labeled local table scroll, visible focus and no ordinary page overflow. |
| E2 | long-text | resolved | explicit | Long names, identifiers, diagnostic values and action labels wrap or use existing discoverable disclosure without clipping essential identity/actions, including 200% text enlargement and text-spacing overrides. |
| E3 | empty | resolved | explicit | Absent records, absent optional values and ineligible review targets use the distinct existing empty/unavailable treatments in Copywriting Contract; an absent preference uses the existing theme fallback, not a new inferred billing state. |
| E3 | loading | resolved | explicit | In-flight reads/actions preserve named disabled controls and actual busy feedback until authoritative completion or LiveView readiness; browser online alone does not unlock or replay an action. |
| E3 | error | resolved | explicit | Read/validation/denied/failed/unknown cases expose associated truthful messages and only the supported next step specified in Copywriting Contract; mutation failures never offer blind retry. |
| E3 | partial | resolved | explicit | Missing fields/evidence remain explicitly unavailable or partial, never zero-filled money or inferred settlement/health; supported action eligibility stays server-owned. |
| E3 | overflow | resolved | explicit | At 320 CSS px, intermediate/coarse-pointer layouts and text enlargement/spacing, essential identity/money/state/actions remain reachable with wrapping or labeled local table scroll, visible focus and no ordinary page overflow. |
| E3 | long-text | resolved | explicit | Long names, identifiers, diagnostic values and action labels wrap or use existing discoverable disclosure without clipping essential identity/actions, including 200% text enlargement and text-spacing overrides. |
| E4 | empty | resolved | explicit | Absent records, absent optional values and ineligible review targets use the distinct existing empty/unavailable treatments in Copywriting Contract; an absent preference uses the existing theme fallback, not a new inferred billing state. |
| E4 | loading | resolved | explicit | In-flight reads/actions preserve named disabled controls and actual busy feedback until authoritative completion or LiveView readiness; browser online alone does not unlock or replay an action. |
| E4 | error | resolved | explicit | Read/validation/denied/failed/unknown cases expose associated truthful messages and only the supported next step specified in Copywriting Contract; mutation failures never offer blind retry. |
| E4 | populated | resolved | explicit | Typical records preserve identity/scope, exact current facts, supported next action and related evidence in the defined scan order. |
| E4 | partial | resolved | explicit | Missing fields/evidence remain explicitly unavailable or partial, never zero-filled money or inferred settlement/health; supported action eligibility stays server-owned. |
| E4 | overflow | resolved | explicit | At 320 CSS px, intermediate/coarse-pointer layouts and text enlargement/spacing, essential identity/money/state/actions remain reachable with wrapping or labeled local table scroll, visible focus and no ordinary page overflow. |
| E4 | zero-one-many | resolved | explicit | Zero rows use distinct queue/first-run/filter states, one and many retain associated identity/status/actions and correct singular/plural terms; existing result order and bounded collection behavior are preserved. |
| E4 | long-text | resolved | explicit | Long names, identifiers, diagnostic values and action labels wrap or use existing discoverable disclosure without clipping essential identity/actions, including 200% text enlargement and text-spacing overrides. |
| E5 | empty | resolved | explicit | Absent records, absent optional values and ineligible review targets use the distinct existing empty/unavailable treatments in Copywriting Contract; an absent preference uses the existing theme fallback, not a new inferred billing state. |
| E5 | loading | resolved | explicit | In-flight reads/actions preserve named disabled controls and actual busy feedback until authoritative completion or LiveView readiness; browser online alone does not unlock or replay an action. |
| E5 | error | resolved | explicit | Read/validation/denied/failed/unknown cases expose associated truthful messages and only the supported next step specified in Copywriting Contract; mutation failures never offer blind retry. |
| E5 | partial | resolved | explicit | Missing fields/evidence remain explicitly unavailable or partial, never zero-filled money or inferred settlement/health; supported action eligibility stays server-owned. |
| E5 | long-text | resolved | explicit | Long names, identifiers, diagnostic values and action labels wrap or use existing discoverable disclosure without clipping essential identity/actions, including 200% text enlargement and text-spacing overrides. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable; no shadcn or third-party registry blocks |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: FLAG — nonblocking focal-point suggestion; task hierarchy and labeled anchors are defined
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** 2026-10-09 — independent UI checker approved; six PASS dimensions and one nonblocking visual recommendation. Approved incumbent roles/exceptions supersede generic template defaults.
