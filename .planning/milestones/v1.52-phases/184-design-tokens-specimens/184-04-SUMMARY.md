---
phase: 184-design-tokens-specimens
plan: "04"
subsystem: brandbook/tokens/harness + brandbook/examples
tags: [design-tokens, specimens, svg, palette, typography, spacing, determinism, tdd]
dependency_graph:
  requires:
    - brandbook/tokens/tokens.json (Plan 01 SSOT)
    - brandbook/tokens/harness/lib.mjs (Plan 01 flattenTokens)
    - .planning/phases/180-brand-audit-dna-lock/artifacts/contrast-table.txt (AA annotations)
    - accrue_admin/assets/css/theme.css (type/spacing reference scale)
  provides:
    - brandbook/tokens/harness/svgo.config.mjs (deterministic SVG optimization config)
    - brandbook/tokens/harness/generate-specimens.mjs (deterministic palette/typography/spacing generator)
    - brandbook/tokens/harness/verify-specimens.mjs (SC#3 content-coverage assertion)
    - brandbook/examples/palette.svg (swatch grid with hex/token/role/AA on light + dark surfaces)
    - brandbook/examples/typography.svg (Geist sans + Geist Mono scale with px+rem labels)
    - brandbook/examples/spacing.svg (labeled spacing ruler for every step)
  affects:
    - Plan 186: brandbook assembly inlines all three examples/*.svg as self-contained SVG nodes
tech_stack:
  added:
    - svgo ^4.0.1 (already in harness package.json from Plan 01 — consumed here for first time)
  patterns:
    - generate-then-gate determinism: node generate-specimens.mjs + git diff --exit-code
    - AA annotations sourced from contrast-table.txt only, never recomputed or invented
    - Reference-only scale values from theme.css read as literals (D-11, no --accrue-type/space-* minted)
    - TDD RED/GREEN for verify-specimens.mjs (ERR_MODULE_NOT_FOUND RED → full implementation GREEN)
    - isMain guard on verify-specimens.mjs mirrors geist-spine-mono.mjs pattern
key_files:
  created:
    - brandbook/tokens/harness/svgo.config.mjs (copy of logo harness config — multipass, preserves viewBox/title/desc)
    - brandbook/tokens/harness/generate-specimens.mjs (generates all three specimen SVGs from tokens.json)
    - brandbook/tokens/harness/verify-specimens.mjs (SC#3 content-coverage check — exits 0/1)
    - brandbook/examples/palette.svg (palette specimen — light + dark surface bands, 7 raw + semantic roles)
    - brandbook/examples/typography.svg (type scale — Geist sans + Geist Mono, xs..3xl, px+rem labels)
    - brandbook/examples/spacing.svg (spacing ruler — 8 steps, 2xs..3xl, proportional bars + labels)
decisions:
  - "AA annotations in palette.svg are sourced verbatim from contrast-table.txt: Moss 3.03:1 AA-large (FAIL AA-body on light), Cobalt 3.66:1 AA-large (FAIL AA-body on light), Amber 2.66:1 FAIL (FAIL AA on light); Ink vs Moss/Cobalt/Amber on dark: 5.89/4.86/6.71 AA-body."
  - "svgo.config.mjs copied verbatim from logo harness (not linked) — each harness is standalone with its own node_modules; consistent with D-16 one-install-per-harness design."
  - "D-11 compliance: typography and spacing values read as string literals from the reference scale; no --accrue-type-* or --accrue-space-* tokens minted in tokens.json."
  - "TDD RED gate: ERR_MODULE_NOT_FOUND on verify-specimens.mjs (file absent) = confirmed failing state; empty commit records the gate."
metrics:
  duration: ~4 minutes
  completed: "2026-06-13"
  tasks_completed: 3
  files_created: 6
---

# Phase 184 Plan 04: Deterministic Specimen SVGs (D-13/14/15) — Summary

Three deterministic specimen SVGs generated from `tokens.json` SSOT via `generate-specimens.mjs`: `palette.svg` (7 raw + semantic roles on light + dark surfaces with AA annotations from contrast-table.txt), `typography.svg` (Geist sans + Geist Mono 7-step scale with px+rem labels), and `spacing.svg` (8-step spacing ruler with proportional bars), all `git diff --exit-code`-gated; `verify-specimens.mjs` proves SC#3 content coverage with a 0/non-zero exit contract.

## What Was Built

**Task 1 (c68ce01a):** Scaffolded `svgo.config.mjs` (verbatim copy from logo harness — multipass, preserves viewBox/title/desc) and created `generate-specimens.mjs` with `buildPaletteSvg()`:
- Reads `tokens.json` via `flattenTokens` from `lib.mjs`
- Separates 7 raw `color.brand.*` tokens from semantic role tokens; sorts deterministically
- Renders TWO surface bands: light (Paper `#fafbfc`) and dark (Ink `#0f1318`)
- Each swatch: colored rect + token name (`--accrue-*`) + hex + role/axMap + AA status text
- AA status text **sourced from contrast-table.txt** (T-184-12 mitigated): Moss `3.03:1 AA-large (FAIL AA-body on light)`, Cobalt `3.66:1 AA-large (FAIL AA-body on light)`, Amber `2.66:1 FAIL (FAIL AA on light)` — Ink vs Moss/Cobalt/Amber on dark: `5.89:1 AA-body on dark`, `4.86:1 AA-body on dark`, `6.71:1 AA-body on dark`
- Determinism gate (D-17): fixed coordinate math, `.toFixed(3)`, sorted order, svgo multipass, trailing `\n`

**Task 2 (b4263b2c):** Extended `generate-specimens.mjs` with `buildTypographySvg()` and `buildSpacingSvg()`:
- `typography.svg`: Geist sans + Geist Mono 7-step scale (xs=12px through 3xl=36px), each step with `--ax-type-<step>` label, `px` + `rem` reference, and sample text rendered at that size
- `spacing.svg`: 8-step spacing scale (2xs=2px through 3xl=64px), each step as a labeled proportional ruler bar colored in Moss
- Values read as string literals from theme.css reference scale (D-11, T-184-13 mitigated: no `--accrue-type-*` or `--accrue-space-*` tokens minted)
- Both SVGs: `<title>/<desc>`, fixed coordinate math, svgo pass, trailing `\n`, determinism gate passes

**Task 3 (RED: 89ca6575 → GREEN: 0d1a3835):** TDD RED/GREEN for `verify-specimens.mjs`:

RED: File did not exist → `ERR_MODULE_NOT_FOUND` → exit 1. Empty commit records gate.

GREEN: Full implementation:
- Enumerates expected raw `--accrue-*` tokens via `flattenTokens` from `lib.mjs`
- Asserts every raw brand token name appears in `palette.svg`
- Asserts light surface band (`Light surface`, `#fafbfc`) and dark surface band (`Dark surface`, `#0f1318`) present
- Asserts Moss/Cobalt/Amber AA-FAIL flags: `"FAIL AA-body on light"` and `"FAIL AA on light"`
- Asserts each `--ax-type-<step>` in `typography.svg` (all 7 steps; Geist + Geist Mono present)
- Asserts each `--ax-space-<step>` in `spacing.svg` (all 8 steps)
- Negative check demonstrated: removing `--accrue-moss` from a copy exits 1 naming the missing item

## Deviations from Plan

None — plan executed exactly as written.

The `band-light` / `band-dark` IDs that appear in the generator source are stripped by svgo's `cleanupIds` plugin — this is expected and correct behavior. The actual content (light/dark surface `<rect>` elements, labels, AA-FAIL text) is preserved. The task's acceptance criteria and verify commands use content strings, not SVG IDs, so all pass.

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED (test fails) | 89ca6575 | PASS — `ERR_MODULE_NOT_FOUND` on absent `verify-specimens.mjs` |
| GREEN (implementation passes) | 0d1a3835 | PASS — all 26 assertions pass, exits 0 |
| REFACTOR | N/A | No refactor needed — implementation is clean as authored |

## Known Stubs

None — all specimens render real token values from `tokens.json` (sourced from BRAND-AUDIT §7 and theme.css); no placeholder text, no empty arrays/objects flowing to downstream consumers.

## Threat Flags

No new security-relevant surface introduced. This plan adds:
- Build-time Node tooling only (no runtime, no network, no user input, no secrets)
- All three `examples/*.svg` are committed static files — no dynamic generation at Phase 186 runtime

## Self-Check: PASSED

All files present and all commits confirmed:
- FOUND: brandbook/tokens/harness/svgo.config.mjs
- FOUND: brandbook/tokens/harness/generate-specimens.mjs
- FOUND: brandbook/tokens/harness/verify-specimens.mjs
- FOUND: brandbook/examples/palette.svg
- FOUND: brandbook/examples/typography.svg
- FOUND: brandbook/examples/spacing.svg
- FOUND: c68ce01a (Task 1 — svgo.config.mjs + generate-specimens.mjs + palette.svg)
- FOUND: b4263b2c (Task 2 — typography.svg + spacing.svg)
- FOUND: 89ca6575 (Task 3 RED — empty commit marking ERR_MODULE_NOT_FOUND gate)
- FOUND: 0d1a3835 (Task 3 GREEN — verify-specimens.mjs)
