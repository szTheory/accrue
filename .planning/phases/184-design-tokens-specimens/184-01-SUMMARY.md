---
phase: 184-design-tokens-specimens
plan: "01"
subsystem: brandbook/tokens
tags: [design-tokens, dtcg, color, lib, harness, tdd]
dependency_graph:
  requires: []
  provides:
    - brandbook/tokens/tokens.json (DTCG SSOT for Plans 02, 03, 04)
    - brandbook/tokens/harness/lib.mjs (shared helpers for Plans 02, 03, 04)
    - brandbook/tokens/harness/package.json + package-lock.json
  affects:
    - Plan 02: generate-tokens-css.mjs imports lib.mjs + tokens.json
    - Plan 03: parity-check.mjs imports lib.mjs + reads tokens.json
    - Plan 04: specimen generator imports lib.mjs + reads tokens.json
tech_stack:
  added:
    - postcss ^8.5.15 (CSS AST parser for parity check)
    - postcss-value-parser ^4.2.0 (CSS value AST — var(), color-mix())
    - culori ^4.0.2 (CSS Color L4 normalization + interpolate for color-mix)
    - svgo ^4.0.1 (SVG optimization for specimens)
  patterns:
    - DTCG v2025.10 structured $value object (colorSpace + components + hex)
    - org.accrue.ax $extensions namespace (axMap / divergesFrom / reason / scope)
    - isMain + --test smoke gate pattern (mirrors geist-spine-mono.mjs)
    - throw-don't-return-undefined discipline for resolveColor (T-184-01)
    - CSS space name → culori mode map (srgb→rgb, oklch→oklch, etc.)
key_files:
  created:
    - brandbook/tokens/tokens.json (DTCG v2025.10 SSOT — 7 raw + semantic roles + dark + brand-only + dimension refs)
    - brandbook/tokens/harness/lib.mjs (flattenTokens / deriveCssVar / resolveColor / iterAxMappedTokens)
    - brandbook/tokens/harness/lib.test.mjs (TDD RED test — also serves as integration smoke)
  modified:
    - brandbook/tokens/harness/package.json (already committed in Task 1 — postcss, postcss-value-parser, culori, svgo)
    - brandbook/tokens/harness/package-lock.json (already committed in Task 1)
decisions:
  - "CSS space-to-culori mode map required: culori uses 'rgb' for sRGB, not 'srgb'. Auto-fixed (Rule 1)."
  - "iterAxMappedTokens yields ALL entries including axMap:null — caller is responsible for filtering; keeps the iterator simple and matches parity-check.mjs pattern."
  - "color.dark.* parallel group chosen for dark-mode modeling (RESEARCH Open Question 2 recommendation)."
  - "code-block.surface = Fog (#e9eef2), code-block.text = Slate (#24303b); callout.surface = Sunken (#f1f5f8), callout.text = Ink (#111418) — derived from existing neutral family per D-09b."
  - "--ax-accent not defined in theme.css; interactive.accent set as brand-only cobalt (axMap:null)."
metrics:
  duration: ~25 minutes
  completed: "2026-06-13"
  tasks_completed: 3
  files_created: 3
---

# Phase 184 Plan 01: Token Harness Foundation — SSOT + Shared Helpers — Summary

DTCG v2025.10 `tokens.json` SSOT with 7 raw palette + semantic roles + dark counterparts + brand-only tokens, plus `lib.mjs` shared helper module exporting four tested functions (flattenTokens / deriveCssVar / resolveColor / iterAxMappedTokens) with throw-on-unresolved discipline.

## What Was Built

**Task 1 (prior agent — da73c943):** Scaffolded `brandbook/tokens/harness/package.json` with `postcss`, `postcss-value-parser`, `culori`, `svgo` dependencies and committed `package-lock.json`. Supply-chain human-verify gate (T-184-SC) was approved by the user.

**Task 2 (e3896ce9):** Authored `brandbook/tokens/tokens.json` as a DTCG v2025.10-conformant SSOT:
- 7 raw `color.brand.*` tokens with structured `$value` objects (`{colorSpace, components, hex}`)
- Palette-bearing semantic roles: `color.surface.*`, `color.content.*`, `color.interactive.*`, `color.feedback.*`
- `color.dark.*` parallel group for dark-mode role counterparts matching `theme.css` dark block exactly
- Brand-only new tokens: `color.code-block.*` and `color.callout.*` (axMap:null, D-09b)
- Reference-only `dimension.space.*` scale (8 rungs, D-11, referencesAx, not value-enforced)
- 38 occurrences of `org.accrue.ax` `$extensions` namespace (single, consistent per D-10)
- All 7 brand raw tokens pass the plan's verification command; moss=#5e9e84, fog/cobalt axMap:null confirmed

**Task 3 (TDD RED ea744b6e → GREEN d98cbd86):**

RED: `lib.test.mjs` written before implementation — failed immediately with `ERR_MODULE_NOT_FOUND`. TDD gate confirmed.

GREEN: `lib.mjs` implemented and all 27 `--test` smoke assertions pass:
- `flattenTokens(json)` — walks DTCG tree, yields flat rows with cssVar/hex/axMap/name/scope; resolves `{alias}` references; color.dark.* tokens get scope="dark"
- `deriveCssVar(pathSegs)` — brand/* → `--accrue-<leaf>`, roles → `--accrue-<group>-<leaf>`, always lowercase
- `resolveColor(raw, vars, brandRaw)` — resolves var() indirection, evaluates color-mix() via culori interpolate with CSS-space-to-culori-mode mapping, normalizes via formatHex; throws on unresolved
- `iterAxMappedTokens(json)` — yields all tokens (caller filters axMap===null), each with axMap/brandHex/name/scope

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CSS color space name mismatch for culori interpolate**
- **Found during:** Task 3 GREEN — `node lib.mjs --test` errored with `TypeError: converters[color.mode].rgb is not a function`
- **Issue:** culori 4.0.2 uses `"rgb"` as the internal mode name for sRGB; passing `"srgb"` (the CSS color-mix syntax name) causes a runtime TypeError
- **Fix:** Added `CSS_SPACE_TO_CULORI` mapping in `_resolveColorMix`: `{ "srgb": "rgb", "oklch": "oklch", ... }` — converts CSS color-mix space names to culori mode names before calling `interpolate`
- **Files modified:** `brandbook/tokens/harness/lib.mjs`
- **Commit:** d98cbd86 (included in GREEN commit)

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED (test fails) | ea744b6e | PASS — `ERR_MODULE_NOT_FOUND` on import of non-existent lib.mjs |
| GREEN (implementation passes) | d98cbd86 | PASS — 27/27 assertions in `--test` smoke; 24/24 in lib.test.mjs |
| REFACTOR | N/A | No refactor needed — implementation is clean as authored |

## Known Stubs

None — all tokens carry real hex values (sourced from BRAND-AUDIT §7 and theme.css), no placeholder text, no empty arrays/objects flowing to downstream consumers.

The two brand-only new tokens (`code-block` and `callout`) have values derived from the existing neutral family per D-09b; RESEARCH Open Question 1 flags them for one-line PR ratification, which is expected and documented in their `$description` fields.

## Threat Flags

No new security-relevant surface introduced beyond what was already in the plan's threat model. This plan adds:
- Build-time Node tooling only (no runtime, no network, no user input, no secrets)
- Supply-chain gate (T-184-SC) was already addressed in Task 1 and approved by the human

## Self-Check: PASSED

All files present and all commits confirmed in git history:
- FOUND: brandbook/tokens/tokens.json
- FOUND: brandbook/tokens/harness/lib.mjs
- FOUND: brandbook/tokens/harness/lib.test.mjs
- FOUND: brandbook/tokens/harness/package.json
- FOUND: brandbook/tokens/harness/package-lock.json
- FOUND: da73c943 (Task 1 — harness scaffold)
- FOUND: e3896ce9 (Task 2 — tokens.json)
- FOUND: ea744b6e (Task 3 RED — lib.test.mjs)
- FOUND: d98cbd86 (Task 3 GREEN — lib.mjs)
