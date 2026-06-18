---
phase: 189-primitive-form-components-component-lab
verified: 2026-06-17T21:00:00Z
status: human_needed
score: 5/5 must-haves verified (automated evidence)
overrides_applied: 0
requirements:
  - id: CMP-01
    verdict: verified
    confidence: high
    caveats: e2e axe sweep and themeColumnDeltaProbe not yet executed in Playwright (specs wired, no run result)
  - id: CMP-02
    verdict: verified
    confidence: high
    caveats: overflowProbe wired but not executed; HTML/CSS overflow contract confirmed in code
  - id: CMP-03
    verdict: verified
    confidence: high
    caveats: focus-ring and cursor e2e probes wired but not executed; ARIA attributes verified in source
  - id: CMP-04
    verdict: verified
    confidence: high
    caveats: disabledAffordanceProbe is advisory (no hard assertion in e2e); CSS tokens confirmed
  - id: CMP-05
    verdict: verified
    confidence: high
    caveats: none — shell guard + 2 negative-fixture tests pass; no per-page overrides found
human_verification:
  - test: "Run the full Playwright e2e suite against a live accrue_admin server: `npm run e2e && npm run e2e:a11y`"
    expected: |
      - `admin-a11y.spec.js` sweeps `/billing/dev/components` in both light and dark themes; axe reports zero wcag2a/wcag2aa violations (including color-contrast).
      - `admin-interactions.spec.js` Phase 189 component-kitchen probe block: all 5 tests pass:
          1. theme column delta: lightBase !== darkBase (D-07 confirmed)
          2. focus ring: `.ax-button` and `.ax-field-control` have `outlineWidth >= 2px` on :focus-visible
          3. overflow probe: no content-overflow-escape failures on `.ax-dev-state-cell[data-ax-state="overflow"]`
          4. cursor probe: `.ax-status-badge` and `.ax-empty` have `cursor !== pointer`
          5. disabled affordance: no JS crash; NDJSON rows written for Phase 192 scoring
    why_human: "Playwright requires a running Phoenix server and a Chromium binary. `accrue_admin/test-results/` is empty — no e2e run has been performed in this phase. The spec files are correctly wired (verified in source), but the runtime behaviour (resolved CSS colors, computed outlineWidth, actual overflow geometry) can only be confirmed with a browser execution."

  - test: "Screenshot/visual review of `/billing/dev/components` in Chrome (desktop 1440, mobile 390) — light and dark"
    expected: |
      - Each component family section renders as a two-column grid (Light | Dark) with correct `ax-dev-state-grid` layout.
      - Dark column shows visibly dark backgrounds (not identical to light column).
      - Disabled specimens look unmistakably non-interactive (dimmed, cursor not-allowed).
      - StatusBadge tones (moss/cobalt/amber/slate/ink) are visually distinct and on-brand.
      - Empty-state hero has no hover or pointer affordance on its container.
      - Button loading state shows spinner + aria-busy.
      - Overflow specimens (long IDs, email addresses) truncate with ellipsis without escaping their cell.
    why_human: "Visual hierarchy, brand-polish, and dark/light color fidelity cannot be verified by grep or ExUnit. `score-visuals.mjs` is advisory and requires a captured PNG set."
---

# Phase 189: Primitive & Form Components + Component Lab — Verification Report

**Phase Goal:** Systematize every primitive and form component: exercise each across its full state matrix in both light and dark themes, verify a11y, fix every defect at the component root so it propagates to every consuming page, and grow `/dev/components` into the systematic gallery that proves it (extended in-app kitchen — no PhoenixStorybook, no new build deps).

**Requirements:** CMP-01, CMP-02, CMP-03, CMP-04, CMP-05

**Verified:** 2026-06-17
**Status:** human_needed — all automated evidence passes; Playwright e2e suite not yet executed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every primitive is exercised in the lab across its full state matrix in both light and dark | VERIFIED | `ComponentRegistry` has 14 Phase-189 families with `applicable_states`, `na_states` (each with reason), and `specimens`; `ComponentKitchenLive` renders a registry-driven two-column `.ax-dev-state-grid`; 7 registry tests pass (tests a-g) |
| 2 | Long/overflowing content renders without clipping, overlap, or layout break | VERIFIED | `.ax-inline-id` CSS has `overflow: hidden; text-overflow: ellipsis; white-space: nowrap`; `title` attr on InlineId for full-text access; overflow specimens baked into all applicable registry entries; overflowProbe wired in e2e spec |
| 3 | Interactive components have correct role, full keyboard operation, visible focus, accessible name; non-interactive elements expose no misleading affordances | VERIFIED | CR-01 fixed: toggle has `aria-labelledby`; `aria-invalid` on input error state; `.ax-checkbox` and `.ax-radio` added to shared `:focus-visible` block (WR-04 fixed); StatusBadge and EmptyState have no `cursor:pointer`, no hover, no `role="button"` |
| 4 | Disabled/readonly states visually unmistakable; button text contrast correct | VERIFIED | `--ax-disabled-bg/text/border` and `--ax-readonly-bg/text` tokens applied to `.ax-field-control:disabled`, `.ax-button:disabled`, `.ax-toggle:disabled`; WR-01/02 fixed (`.ax-field-inline` and `.ax-field-disabled` CSS rules exist); axe color-contrast rule included in a11y sweep spec |
| 5 | Component-level fixes are at the component root — no per-page patching | VERIFIED | Only `app.css` and `theme.css` exist in `accrue_admin/assets/css/`; `verify_package_docs.sh` CMP-05 guard exits 0; no per-page CSS override files; no inline `style=` on guarded primitive classes in live views; 25 package docs tests pass including 2 new CMP-05 negative fixtures |

**Score:** 5/5 truths verified (automated evidence)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/lib/accrue_admin/components/textarea.ex` | New primitive module | VERIFIED | Created in Plan 02 |
| `accrue_admin/lib/accrue_admin/components/checkbox.ex` | New primitive module | VERIFIED | Created in Plan 02 |
| `accrue_admin/lib/accrue_admin/components/radio.ex` | New primitive module | VERIFIED | Created in Plan 02 |
| `accrue_admin/lib/accrue_admin/components/toggle.ex` | New primitive module, role=switch | VERIFIED | CR-01 fix applied: `aria-labelledby` present (commit a1bc9667) |
| `accrue_admin/lib/accrue_admin/components/spinner.ex` | New primitive module | VERIFIED | CSS-animated, role=status, aria-live=polite |
| `accrue_admin/lib/accrue_admin/components/tooltip.ex` | New primitive module, z-layer | VERIFIED | `z-index: var(--ax-z-popover)` confirmed in CSS |
| `accrue_admin/lib/accrue_admin/components/empty_state.ex` | New non-interactive module | VERIFIED | No `phx-click`, no `role="button"`, no `cursor:pointer` |
| `accrue_admin/lib/accrue_admin/components/inline_id.ex` | New display primitive, overflow | VERIFIED | `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` in CSS; `title` attr present; IN-01 (max_width unvalidated) is documented/accepted as info-only |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 14-family schema with applicable_states/na_states/specimens | VERIFIED | All 14 Phase-189 families present with 7-field schema |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | Registry-driven two-column renderer | VERIFIED | Renders `.ax-dev-state-grid` with `data-theme="light"/"dark"` columns and `data-ax-state` attributes |
| `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | 7 tests (a-g) passing | VERIFIED | 7 tests, 0 failures confirmed by running suite |
| `accrue_admin/assets/css/app.css` | `.ax-dev-state-grid`, primitive CSS root-fixes | VERIFIED | Grid CSS at lines 232-272; WR-01/02/03/04/05 fixes confirmed |
| `accrue_admin/assets/css/theme.css` | Sub-tree `.accrue-admin [data-theme="dark"]` selector (D-07) | VERIFIED | Selector present at lines 283-284 with FULL dark token set |
| `scripts/ci/verify_package_docs.sh` | CMP-05 guard (per-page CSS + inline style=) | VERIFIED | Guard exits 0 on clean tree; CMP-05 error messages confirmed in grep |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | 25 tests (includes 2 CMP-05 negative fixtures) | VERIFIED | 25 tests, 0 failures confirmed by running suite |
| `accrue_admin/e2e/admin-a11y.spec.js` | Component-kitchen added to axe sweep | VERIFIED | `["component-kitchen", "/billing/dev/components"]` present at line 72 |
| `accrue_admin/e2e/admin-interactions.spec.js` | 5-probe Phase 189 block + themeColumnDeltaProbe | VERIFIED | `test.describe("Phase 189: component-kitchen probes")` block at lines 1072-1165; `themeColumnDeltaProbe` at line 863 |
| `accrue_admin/e2e/admin-visuals.spec.js` | Component-kitchen added to PNG capture | VERIFIED | `["component-kitchen", "/billing/dev/components"]` present |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ComponentRegistry` entries | `ComponentKitchenLive` renderer | `get_phase_189_families/0` (filters `applicable_states`) | WIRED | Renderer uses `applicable_states` from registry; theme-scoped IDs prevent LiveView duplicate-id errors |
| `ComponentKitchenLive` | `.ax-dev-state-grid` CSS | `class="ax-dev-state-grid"` in HEEx | WIRED | CSS block confirmed at app.css lines 232-272 |
| `.ax-dev-state-grid-col[data-theme="dark"]` | Dark token scope | `.accrue-admin [data-theme="dark"]` CSS selector in theme.css | WIRED | Sub-tree selector confirmed at theme.css lines 283-284 with full dark token block |
| Registry `applicable_states` | Test assertions (tests a-g) | Tests read `entries()` and check rendered HTML | WIRED | Test (g) asserts `data-theme`, `data-ax-state`, `data-ax-na-reason` in mounted page HTML |
| CMP-05 guard | Negative-fixture ExUnit tests | `seed_tmp_dir!` + `verify_package_docs.sh` subprocess call | WIRED | Both negative fixtures write violations and assert non-zero exit + "CMP-05" message |
| Phase 189 e2e probes | Component-kitchen route | `page.goto("/billing/dev/components")` in `test.beforeEach` | WIRED (spec only — not run) | Spec wired correctly; no Playwright execution has occurred |

---

## Data-Flow Trace (Level 4)

The component lab is a dev-only read-only surface (`Mix.env() != :prod` guard on the registry module). Data flows from the static `entries()` function in `ComponentRegistry` through the `ComponentKitchenLive` renderer into HTML. No dynamic DB data flows through Phase 189 artifacts. Level 4 is not applicable — all data is static registry configuration, not DB-sourced.

---

## Behavioral Spot-Checks (Static Analysis Only)

Playwright e2e is the primary behavioral verification layer for this phase. `accrue_admin/test-results/` is empty — no e2e run exists. Static checks confirmed:

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| CMP-05 guard executes and exits 0 | `bash scripts/ci/verify_package_docs.sh` | "package docs verified" | PASS |
| 25 package docs tests pass | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | 25 tests, 0 failures | PASS |
| 7 registry tests pass | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs` | 7 tests, 0 failures | PASS |
| Full accrue_admin suite | `cd accrue_admin && mix test` | 269 tests, 3 failures (all pre-existing — see note below) | PASS (no regressions) |
| Compile clean | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors` | Exit 0 | PASS |

---

## Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probes declared. The Phase 189 verification layer is Playwright e2e (`admin-a11y.spec.js`, `admin-interactions.spec.js`). These specs are wired but have not been executed — `accrue_admin/test-results/` is empty. See Human Verification Required section.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| CMP-01 | Plans 01, 03 | Every component exercised in lab across full state matrix in both light and dark | VERIFIED (automated) + HUMAN NEEDED (e2e axe + delta probe) | 14 families in registry with applicable_states; two-column renderer; axe sweep wired; e2e not run |
| CMP-02 | Plans 02, 03, 05 | Long/overflowing content renders correctly | VERIFIED (automated) + HUMAN NEEDED (overflow probe) | overflow CSS contract on inline-id + overflow specimens in registry; overflowProbe spec wired; e2e not run |
| CMP-03 | Plans 02, 04, 05; CR-01 fix | Correct role, keyboard, focus, accessible name; no misleading affordances | VERIFIED (automated) + HUMAN NEEDED (focus ring + cursor probes) | aria-labelledby on toggle (CR-01); aria-invalid on inputs; .ax-checkbox/.ax-radio in :focus-visible block (WR-04); no cursor:pointer on badge/empty-state; e2e not run |
| CMP-04 | Plans 04, 05; WR-01/02 fixes | Disabled/readonly visually unmistakable; button text contrast | VERIFIED (automated, CSS tokens confirmed) + HUMAN NEEDED (disabledAffordanceProbe advisory) | disabled/readonly CSS tokens applied; axe color-contrast in sweep spec; disabledAffordanceProbe is advisory (no hard assertion) |
| CMP-05 | Plan 07 | Component root fixes only — no per-page patching | VERIFIED (hard gate) | Shell guard exits 0; 2 negative fixtures pass; no per-page CSS files; no inline style= on guarded primitives |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `accrue_admin/lib/accrue_admin/components/inline_id.ex` | 30 | `style={"max-width: #{@max_width};"}`  — unvalidated CSS string interpolation into style attr (IN-01) | Info | Low — callers are first-party; `ax-inline-id` is explicitly excluded from CMP-05 guard; HEEx HTML-escapes the value. Accepted as info-only per REVIEW.md; no input validation was added. |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | 120 | `ax_class` sometimes represents two different elements' classes (wrapper + inner) for input/json-viewer — convention not documented in `@type entry` doc (IN-02) | Info | Low — convention comment exists at line 120 (`# ax_class must have two space-separated tokens`); formal `@type entry` doc doesn't name the "composite ax_class" case. Accepted as info-only. |

No TBD, FIXME, or XXX debt markers in phase-touched files. "JTBD" in app.css line 2630 is a comment label, not a debt marker.

---

## Human Verification Required

### 1. Playwright e2e suite — axe sweep + component-kitchen probe block

**Test:** With a running `accrue_admin` Phoenix server (dev or test mode), run:
```
cd accrue_admin
npm run e2e:a11y        # admin-a11y.spec.js — axe sweep including component-kitchen
npm run e2e             # admin-interactions.spec.js — Phase 189 probe block
```

**Expected:**
- `admin-a11y.spec.js`: Zero wcag2a/wcag2aa violations (including `color-contrast`) on `/billing/dev/components` in both light and dark themes.
- Phase 189 component-kitchen probe block (5 tests in `admin-interactions.spec.js`):
  1. **Theme column delta**: `lightBase !== darkBase` — confirms D-07 sub-tree selector resolves genuinely different `--ax-base` values in the browser at runtime.
  2. **Focus ring**: `.ax-button` and `.ax-field-control` have computed `outlineWidth >= 2px` on `:focus-visible`.
  3. **Overflow probe**: No `content-overflow-escape` failures on overflow specimens.
  4. **Cursor probe**: `.ax-status-badge` and `.ax-empty` report `cursor !== pointer`.
  5. **Disabled affordance**: No JS crash; NDJSON rows written (advisory observation for Phase 192).

**Why human:** Playwright requires a running Phoenix server and Chromium binary. `accrue_admin/test-results/` is empty — no e2e run has been executed in this phase. The spec files are correctly wired and structurally verified in source, but runtime browser behavior (resolved CSS colors, computed outlineWidth, actual overflow geometry, axe DOM analysis) cannot be confirmed without execution.

### 2. Visual screenshot review of `/dev/components`

**Test:** Open `/billing/dev/components` in Chrome at 1440px desktop width and 390px mobile width, in both light and dark themes.

**Expected:**
- Two-column grid (Light | Dark) renders for each of the 14 component families.
- Dark column shows visibly dark backgrounds — not identical to the light column.
- Disabled specimens appear unmistakably dimmed (opacity, muted text, not-allowed cursor).
- StatusBadge tones (moss/cobalt/amber/slate/ink) are visually distinct and on-brand.
- Empty-state hero has no hover/pointer affordance on its container.
- Button loading state shows spinner + accessible "Saving…" label.
- Long-ID and email overflow specimens truncate with ellipsis, no layout break.
- At 390px mobile, grid stacks to single column (light only) without clipping.

**Why human:** Visual hierarchy, brand polish, dark/light color fidelity, and overflow rendering cannot be verified by grep, ExUnit, or static analysis. This is the maintainer screenshot checkpoint prescribed by VALIDATION.md for phase boundary sign-off.

---

## Pre-Existing Test Failures (Not Attributable to Phase 189)

Full `accrue_admin` suite: **269 tests, 3 failures**. All 3 are pre-existing and confirmed independent of Phase 189 changes:

1. `AccrueAdmin.DashboardLiveTest` (×2) — `assert html =~ "$42.50"` seed-data mismatch. Phase 189 touches no dashboard code.
2. `AccrueAdmin.Queries.QueryModulesTest` — coupon/promotion code query filter mismatch. Phase 189 touches no query modules.

These failures were present before Plan 01 and appear consistently across all 7 plan SUMMARYs.

---

## Code Review Resolution

Phase 189 underwent a standard code review (189-REVIEW.md) that surfaced 1 BLOCKER and 7 WARNINGS. All were resolved via `gsd-code-fixer` (commits a1bc9667, 562db68b, 71e079dd, 64e35c40, a8cfd07d, 380295d4):

| Finding | Fix | Commit |
|---------|-----|--------|
| CR-01: Toggle `<button role="switch">` had no accessible name | Added `aria-labelledby` referencing label span | a1bc9667 |
| WR-01: `.ax-field-inline` undefined — inline controls stacked instead of inline | Added CSS rule: `display: inline-flex; flex-direction: row; align-items: center; gap: var(--ax-space-sm)` | 562db68b |
| WR-02: `.ax-field-disabled` undefined — disabled wrapper had no styling | Added CSS rule: `opacity: var(--ax-disabled-opacity); cursor: var(--ax-disabled-cursor)` | 562db68b |
| WR-03: `.ax-radio` had no CSS — radio rendered with browser-default accent | Added CSS rule: `accent-color: var(--ax-accent); inline-size/block-size: 1.25rem` | 562db68b |
| WR-04: `.ax-checkbox`/`.ax-radio` missing from `:focus-visible` block | Added both selectors to shared focus block in app.css | 71e079dd |
| WR-05: `.ax-money-display` and `.ax-inline-id-short` had no CSS — phantom class hooks | Defined real CSS rules for both classes | 64e35c40 |
| WR-06: Button `@loading` ignored on `href` (link) branch | Added disabled anchor branch when `@href && (@disabled || @loading)` | a8cfd07d |
| WR-07: `focusRingProbe` used `.focus()` which doesn't activate `:focus-visible` on buttons | Changed to keyboard-driven focus (`Shift` keydown) + box-shadow fallback assertion | 380295d4 |
| IN-01, IN-02, IN-03: Info-level notes | Accepted as info-only; no code changes required | — |

---

## Gaps Summary

No automated gaps. All 5 CMP requirements have verified implementation evidence in the codebase. The `human_needed` status reflects that the Playwright e2e suite (the primary runtime behavioral verification layer for CMP-01 through CMP-04) has not been executed in this phase — `accrue_admin/test-results/` is empty. The spec files are wired and structurally correct; runtime confirmation awaits the maintainer's e2e run and visual screenshot review.

---

_Verified: 2026-06-17_
_Verifier: Claude (gsd-verifier)_
