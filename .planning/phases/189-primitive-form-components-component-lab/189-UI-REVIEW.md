---
phase: 189
slug: primitive-form-components-component-lab
audited: 2026-06-17
baseline: 189-UI-SPEC.md (approved)
screenshots: captured (Playwright, chromium-desktop 1280px and chromium-mobile — mobile PNGs exceeded tool limit; reviewed desktop light + dark captures)
---

# Phase 189 — UI Review

**Audited:** 2026-06-17
**Baseline:** 189-UI-SPEC.md (approved design contract)
**Screenshots:** Desktop light + dark captured and reviewed. Mobile PNGs exceeded image-tool resize limit and could not be directly loaded; mobile assessment based on CSS analysis and desktop captures.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Page heading does not match spec contract; state labels use "(n/a)" suffix instead of "n/a — {reason}" format |
| 2. Visuals | 3/4 | Two-column light/dark grid renders correctly; dark column is visually distinct; above-fold still shows pre-Phase-189 hand-authored sections before the matrix begins |
| 3. Color | 3/4 | Semantic token migration complete; ink→neutral fix landed; `ax-dev-state-cell-na` drops opacity approach correctly; minor: `.ax-empty-icon` corrected token but empty-state icon in pre-matrix section still uses `ax-empty-icon-muted` compound class not in spec |
| 4. Typography | 3/4 | All component CSS consumes composed role tokens; one gap: `.ax-dev-state-cell-label` has no dedicated CSS rule — it relies on `ax-type-code-xs` + `ax-muted` utility class composition from the HEEx, which works but diverges from the spec's explicit selector contract |
| 5. Spacing | 3/4 | Grid uses `--ax-space-md` cell padding and 1px gap as specced; n/a cell correctly uses `--ax-sunken` only (opacity dropped); pre-matrix legacy sections use ad-hoc `ax-dev-grid` / `ax-dev-variant-row` patterns not governed by the Phase-189 spacing contract |
| 6. Experience Design | 3/4 | Axe passes both themes; five probe helpers wired; D-07 resolved; loading/aria-busy landed; missing: mobile viewport was single-column collapse only — dark column is hidden at 390px with no tab-toggle mechanism, which was an allowed implementation choice per spec but means mobile users see zero dark-theme coverage |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Page heading copy does not match the UI-SPEC contract** — The spec mandates heading "Component Kitchen" and sub-description "Primitive and form components — full state matrix across light and dark." The rendered heading is "One dev page to sanity-check the admin component layer" (an informal working phrase) and the eyebrow reads "Shared primitives" (not specified). This is a developer-facing surface but the brandbook voice contract still applies: measured, exact, durable. Fix: update `component_kitchen_live.ex` lines 79-80 to use the spec-mandated strings.

2. **N/a state label format is "(n/a)" not "n/a — {reason}"** — The UI-SPEC copywriting contract specifies the n/a cell label format as `"n/a — {reason}"` (em-dash separator with explicit reason inline). The implementation emits two separate spans: `state (n/a)` in the label and `reason` in a second span beneath it. The reason is present but the label format itself does not match the contract. Per the spec, the label span should read `n/a — {reason}` in one line. Fix: update `component_kitchen_live.ex` lines 206 and 223 to render `"n/a — #{reason}"` as the cell label and remove the second reason span (or retain it as supplemental detail only).

3. **Mobile viewport shows only the light column — dark theme is invisible at 390px with no toggle mechanism** — The UI-SPEC explicitly allows either stacked columns or a tab toggle but requires that the mobile render "must not break or clip any component specimen" AND must render the dark column. The CSS collapses to `grid-template-columns: 1fr` at `max-width: 599.98px`, which shows only the first column (light). The dark column is present in the DOM but squished to zero width. No tab toggle exists. This means the primary deliverable of Phase 189 — dark-theme component coverage — is invisible at mobile. Fix: add `grid-template-columns: 1fr` with the dark column stacked vertically below light (`grid-template-columns: 1fr` with the dark col as a second row), or add a theme tab control to the lab page.

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

**BLOCKER — Page heading does not match spec**

- Spec mandates: page heading "Component Kitchen", sub-description "Primitive and form components — full state matrix across light and dark."
- Actual rendered: eyebrow "Shared primitives", h2 "One dev page to sanity-check the admin component layer"
- File: `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` lines 78-79
- The h2 text is informal and violates the brandbook voice principle "durable" — working notes language that should never have been shipped as copy.

**WARNING — n/a label format diverges from spec**

- Spec copywriting contract: `"n/a — {reason}"` (single span, em-dash inline)
- Actual: two separate `<span>` elements — first with `"state (n/a)"`, second with the reason string on its own line
- File: `component_kitchen_live.ex` lines 206-207 and 223-224
- The information is present but the format contract is not met. This is a developer-facing lab, but the contract is explicit.

**WARNING — family section headers rendered as full uppercase via `String.upcase/1` not eyebrow case**

- Spec states: "Component family name in eyebrow case: 'Button', 'Input', 'Textarea'..." (title case, not ALL CAPS)
- Actual: `String.upcase(family)` on line 187 produces "BUTTON", "INPUT", "TEXTAREA" etc.
- The eyebrow class provides `letter-spacing` + `uppercase` via `text-transform: uppercase` — so uppercase display was presumably intended. However the spec lists the values as "Button", "Input" (title case strings), and the `ax-type-eyebrow` role already applies `text-transform: uppercase` via CSS, meaning `String.upcase/1` is redundant and slightly wrong if the strings are ever rendered elsewhere without the class. Low risk but technically a spec divergence.

**PASS — Spec-required copy items present**

- Unavailable state copy: "Dev tools require `Accrue.Processor.Fake` as the configured processor." — matches spec exactly (line 86)
- State labels are lowercase ("default", "disabled", etc.) — matches spec
- Button specimens: "Save changes", "Go", "Export all subscription events to CSV" — matches spec
- Input placeholder: "you@example.com" — descriptive, matches spec pattern
- Empty-state hero copy not auditable from kitchen template directly (component renders from empty_state.ex slot content passed at call site)

---

### Pillar 2: Visuals (3/4)

**PASS — Two-column light/dark grid is visually operative**

From the desktop screenshots: all 14 primitive families render in the two-column grid. The light column has a white/near-white background; the dark column is clearly a dark surface with light text. The D-07 dark token re-scoping is visually confirmed — dark column text is light-colored, matching `--ax-primary` in dark scope.

**WARNING — Above-fold is dominated by pre-matrix legacy sections**

The kitchen page opens with: breadcrumbs, eyebrow, h2 (incorrect copy per above), KPI cards, a button/status row, an icon gallery, a Detail skeleton, and RelatedResources — all before the state matrix begins. On desktop this pushes the primary deliverable (the state matrix) well below the fold. The legacy sections are pre-Phase-189 hand-authored content that was not removed during the refactor (they are inside `:if={@available?}` guards at lines 89-174). The matrix only begins at line 184.

From the screenshot the above-fold experience on desktop shows the KPI cards, buttons, status badges, and icons — not the state matrix. A developer opening this page to verify component states must scroll significantly. This is a developer-experience gap for the primary deliverable.

**WARNING — Pre-matrix empty-state specimen uses non-spec compound class**

Line 170: `<Icon.icon ... class="ax-empty-icon ax-empty-icon-muted" />` — `ax-empty-icon-muted` is not in the UI-SPEC and not in app.css (Plan 05 adds `.ax-empty-icon` with `color: var(--ax-muted)` as its rule, so the separate `-muted` suffix is redundant and non-standard). This is a legacy specimen, not part of the state-matrix renderer, but it is visually present on the page.

**PASS — Cell structure, borders, and header row**

Grid cells are cleanly separated by 1px hairline borders (background: `--ax-border`). The "Light" / "Dark" column headers are visually distinct (sunken background). N/a cells render with the sunken background and muted label — visually distinct from active cells.

**PASS — State labels are visually subordinate to specimens**

The `ax-type-code-xs ax-muted` state label above each specimen creates clear visual hierarchy: tiny muted label → full-size specimen below. This is correct and readable in screenshots.

---

### Pillar 3: Color (3/4)

**PASS — StatusBadge color-mix migration complete**

All five tone blocks (moss, cobalt, amber, slate, ink) now consume `--ax-status-{role}-{bg/text/border}` semantic tokens. The previous `color-mix()` formulas are gone. Ink correctly maps to neutral (not danger) after the Plan 05 auto-fix.

**PASS — Focus ring contract intact**

The consolidated Phase-188 `:focus-visible` block at `~line 2941` applies to `.ax-field-control`, `.ax-input`, `.ax-checkbox`, `.ax-radio`. Stale `outline: none` rules were removed in Plan 04. The `--ax-focus-ring` (light: `#174ea6`, dark: `#9bb5ff`) + `--ax-focus-shadow` contract is preserved.

**PASS — Accent usage is contained**

No accent tokens found on status badges, helper text, error messages, or decorative elements. Accent is on: primary button fill, focus ring, toggle track (on state), interactive hover/active states — within the reserved list.

**WARNING — Dark column in screenshots shows correct dark surface but accent-colored button labels in dark column have lower visual pop**

From the dark desktop screenshot: primary buttons in the dark column show the correct accent background, but the contrast between the accent fill (`--ax-accent-strong`) and the button label text (`--ax-primary` scoped to dark) appears slightly reduced compared to the light column. This is expected from the token values but worth flagging for Phase 192 contrast measurement. The axe sweep passes, suggesting it clears 4.5:1, but it is close.

**PASS — n/a cell uses sunken background, not opacity**

Plan 05 explicitly removed the `opacity: 0.6` from `.ax-dev-state-cell-na` (it would have reduced the muted label contrast below WCAG AA). The sunken background distinguishes n/a cells without a contrast violation.

---

### Pillar 4: Typography (3/4)

**PASS — Composed role tokens in component CSS**

All modified CSS selectors (`.ax-button`, `.ax-button-sm`, `.ax-field-label`, `.ax-field-help`, `.ax-field-error`, `.ax-status-badge`, `.ax-inline-id`) use `font: var(--ax-type-*-font)` shorthand with `ax-type-exception`-guarded `letter-spacing` supplements. The FND-01 verifier passes. No raw `font-size`, `font-weight`, or `line-height` literals in component selectors.

**WARNING — `.ax-dev-state-cell-label` has no dedicated CSS rule**

The UI-SPEC defines a `.ax-dev-state-cell-label` selector contract. In `app.css`, no `.ax-dev-state-cell-label` rule exists — the element relies entirely on the utility classes `ax-type-code-xs` and `ax-muted` applied inline in the HEEx template. This works because the utilities are defined, but it means the lab's cell label styling is not co-located with the rest of the `.ax-dev-state-cell` block. The spec explicitly calls out this selector. Missing: add a `.ax-dev-state-cell-label { /* Uses .ax-type-code-xs + --ax-muted */ }` comment-rule or actual combined rule to close the spec contract.

**WARNING — Family headers use `String.upcase/1` redundantly with CSS `text-transform: uppercase`**

The `.ax-type-eyebrow` class already applies `text-transform: uppercase` via its role token. `String.upcase(family)` in the EEx template produces uppercase strings that are then further uppercased by CSS — the actual rendered strings are uppercased at both the HTML and CSS layers. This is functionally inert but is a brittle pattern: if the family strings are ever consumed in non-eyebrow contexts (logs, test output), they will be ALL CAPS. The spec strings are "Button", "Input" (title case inputs, CSS-driven uppercase output).

**PASS — Role set is exhaustive, no ad-hoc sizes**

No raw numeric sizes found in new component CSS. The role set (body, body-sm, label, label-sm, eyebrow, code, code-xs, title) is the exact Phase-188 role set and no new types were introduced.

---

### Pillar 5: Spacing (3/4)

**PASS — State grid spacing matches contract**

- Cell padding: `var(--ax-space-md)` (16px) — matches spec
- Cell gap: `1px` separator — matches spec
- Grid border: `1px solid var(--ax-border)` — matches spec
- Section family gap: `ax-card ax-dev-stack` class-based gap (pre-existing pattern) provides section-to-section spacing

**PASS — No arbitrary spacing values in new CSS**

All new Phase-189 CSS blocks (`ax-dev-state-grid`, `ax-toggle`, `ax-tooltip`, `ax-spinner`, `ax-empty`, `ax-inline-id`) use `--ax-space-*` tokens. No `px` literals in spacing context. The `translateX(1rem)` in the toggle thumb is a functional micro-geometry value, not a spacing token concern.

**WARNING — Pre-matrix legacy sections use `ax-dev-grid` / `ax-dev-variant-row` patterns**

The above-fold legacy sections (lines 89-174) use older grid/spacing classes that predate Phase-189. These are not regulated by the Phase-189 spacing contract but they are rendered on the same page. `ax-dev-grid` and `ax-dev-variant-row` are not in the Phase-189 spacing contract table — they exist in app.css as pre-existing patterns. No new violations, but the visual inconsistency between legacy sections and the new state matrix is visible in screenshots: the legacy sections have looser, less structured layouts than the clean matrix below them.

**WARNING — `ax-space-2xs` (2px) token used in `.ax-dev-token-dl`**

Line 285: `gap: var(--ax-space-2xs, 0.25rem)` — this is the frozen 2px exception token. The UI-SPEC documents it as a frozen exception for "dense micro-gaps (table cell internals, chip internals)." Using it for the token reference `<dl>` within each family section is within its chartered use case, but the fallback value `0.25rem` (4px) diverges from the token's 2px value — if the token is undefined, the gap becomes 2x larger. This is a pre-existing fallback pattern, not a Phase-189 introduction.

---

### Pillar 6: Experience Design (3/4)

**PASS — Axe sweep passes both themes**

Per the known_state block and Plan 06 summary: axe-core `wcag2a`/`wcag2aa` (including `color-contrast`) passes the kitchen route in both light and dark themes after Phase-189 fixes. Critical violations resolved: duplicate error IDs (input.ex, select.ex, textarea.ex), toggle accessible name, `.ax-field-inline`/`.ax-radio` CSS fixes, n/a-cell contrast.

**PASS — D-07 definitively resolved**

`themeColumnDeltaProbe` reads `getComputedStyle(col).getPropertyValue("--ax-base")` from both columns and asserts a resolved-color delta. The sub-tree dark selector (`.accrue-admin [data-theme="dark"]`) is confirmed to re-scope tokens at the browser level, not merely emit different attribute names.

**PASS — Loading state on button**

`button.ex` now accepts `attr(:loading, :boolean, default: false)`, emits `aria-busy="true"` when loading, and sets `disabled={@disabled || @loading}`. The lab includes loading-state specimens for the button family.

**PASS — Error state wiring**

`input.ex` and `select.ex` use a single `<div id={@id <> "-errors"}>` wrapper with inner `<p :for>` elements. `aria-describedby` references the wrapper ID. `textarea.ex` uses `Enum.with_index` for error IDs. No duplicate-ID violations.

**WARNING — Mobile dark column is not visible**

At `max-width: 599.98px`, `grid-template-columns: 1fr` collapses the grid to a single column. The DOM has both columns but the dark column gets zero visible width (it is after the light column in markup, and the grid only shows one column). No tab toggle exists. The UI-SPEC explicitly permits this approach ("show light only with a 'Dark' tab toggle") but requires the mobile render to show the dark column in some form. Currently it does not. A developer testing on mobile sees only the light theme.

This is an allowed implementation gap (the spec said "implementation choice is left to the planner") but the mobile render is not fulfilling the intent of "both themes visible at mobile viewport."

**WARNING — CMP-05 guard scope is limited**

The per-page CSS override guard in `verify_package_docs.sh` scans `accrue_admin/assets/css/*.css` excluding `app.css` and `theme.css`. Per the Plan 07 decisions, the inline-style guard's `ax-inline-id` exemption is intentional (structural max-width constraint). These are correct scoping decisions. However: the guard does NOT catch overrides placed directly in `app.css` as page-specific selectors (e.g., a future `.billing-page .ax-button { ... }` in app.css would not be flagged). The guardrail is meaningful but has a known blind spot.

**PASS — Five probe helpers wired to NDJSON ledger**

All five probes (`focusRingProbe`, `themeColumnDeltaProbe`, `overflowProbe`, `cursorProbe`, `disabledAffordanceProbe`) emit `p187__`-keyed rows to the NDJSON observation ledger. Phase 192 can diff against the Phase-187 baseline idempotently.

---

## Registry Safety

No third-party registries. `components.json` is not present. No shadcn components. No registry safety concerns.

Registry audit: 0 third-party blocks to check. Not applicable.

---

## Files Audited

**Screenshots reviewed:**
- `accrue_admin/test-results/admin-visuals/chromium-desktop/component-kitchen.png` (desktop light, 1280px)
- `accrue_admin/test-results/admin-visuals/chromium-desktop/component-kitchen-dark.png` (desktop dark, 1280px)

**Planning artifacts:**
- `.planning/phases/189-primitive-form-components-component-lab/189-UI-SPEC.md`
- `.planning/phases/189-primitive-form-components-component-lab/189-CONTEXT.md`
- `.planning/phases/189-primitive-form-components-component-lab/189-01-SUMMARY.md` through `189-07-SUMMARY.md`

**Source files:**
- `accrue_admin/assets/css/app.css` (lines 228-286 state-grid block; lines 1751-1800 radio/checkbox/toggle; lines 232-280 mobile media query)
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (lines 60-274 full render function)
- `accrue_admin/lib/accrue_admin/components/button.ex`, `input.ex`, `select.ex`, `textarea.ex` (via summary evidence)
- `accrue_admin/lib/accrue_admin/components/toggle.ex`, `checkbox.ex`, `radio.ex`, `spinner.ex`, `tooltip.ex`, `empty_state.ex`, `inline_id.ex` (via summary evidence)
- `scripts/ci/verify_package_docs.sh` (CMP-05 guard — via summary evidence)
