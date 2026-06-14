---
phase: 184-design-tokens-specimens
fixed_at: 2026-06-13T00:00:00Z
review_path: .planning/phases/184-design-tokens-specimens/184-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 184: Code Review Fix Report

**Fixed at:** 2026-06-13T00:00:00Z
**Source review:** .planning/phases/184-design-tokens-specimens/184-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (Critical: 2, Warning: 3)
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: SC#1 and SC#3 verifiers are entirely unwired from CI

**Files modified:** `brandbook/tokens/harness/package.json`, `.github/workflows/ci.yml`
**Commit:** b6a37925
**Applied fix:** Added `"verify"` and `"verify-specimens"` entries to the `scripts` block in package.json. In ci.yml `docs-contracts-shift-left` job, added two steps after the determinism gate and before the SC#2 parity steps: `Verify tokens completeness (SC#1)` running `npm run verify` and `Verify specimen content coverage (SC#3)` running `npm run verify-specimens`. Both verifiers confirmed passing via `npm run verify` and `npm run verify-specimens`.

---

### CR-02: Parity check false negative — deleted admin token passes silently

**Files modified:** `brandbook/tokens/harness/parity-check.mjs`
**Commit:** 09803e82
**Applied fix:** Added an `expectedLightAxMaps` audit at the start of `runParity` that builds the set of unique axMap values from all light-scope tokens in tokens.json, then checks each is present in `lightScope` before the value comparison loop. Missing declarations now count as failures. Dark-scope omissions remain intentionally tolerated (only the light audit is new). Added test case `(e)` to `runTests()` that removes the `--ax-success` declaration from a CSS fixture and asserts non-zero failures and that `--ax-success` is named in error output. All 5 test cases (a–e) pass.

---

### WR-01: `_resolveColorMix` corrupts `secondColorStr` for two-sided / second-only percentage forms

**Files modified:** `brandbook/tokens/harness/lib.mjs`
**Commit:** 4f594a71
**Applied fix:** In the first branch (`rest[1]` ends in `%`), after building `secondParts = rest.slice(2).map(stringifyNode)`, strip the trailing word if it matches `/^\d+(\.\d+)?%$/` before joining. This handles `color-mix(in srgb, red 40%, blue 60%)`. In the else branch, detect whether the last stringified node is a percentage; if so, compute `firstPercent = 100 - secondPercent`, use `restParts.slice(1, -1)` as `secondColorStr`. Added 4 smoke assertions covering: two-sided % produces `#rrggbb`, second-only % produces `#rrggbb`, two-sided % equals first-only % form, second-only % equals first-only % form. All assertions pass.

---

### WR-02: `_resolveAlias` has no cycle detection — circular aliases cause stack overflow

**Files modified:** `brandbook/tokens/harness/lib.mjs`
**Commit:** 3ce2015f
**Applied fix:** Added `seen = new Set()` parameter to `_resolveAlias`. On entry, check if `aliasStr` is in `seen` and throw a descriptive error including the full cycle path if so. Otherwise add `aliasStr` to `seen` and pass `seen` on recursive calls. Added a smoke assertion using a synthetic cyclic token tree (`A → {B}`, `B → {A}`) threaded through `flattenTokens`, confirming it throws. All smoke tests pass.

---

### WR-03: `localeCompare` without locale pinning undermines the determinism gate

**Files modified:** `brandbook/tokens/harness/generate-tokens-css.mjs`, `brandbook/tokens/harness/generate-specimens.mjs`
**Commit:** cb4ee799
**Applied fix:** Replaced bare `.localeCompare(x)` with `.localeCompare(x, "en", { sensitivity: "variant" })` at all 3 call sites (generate-tokens-css.mjs:34, generate-specimens.mjs:137, 141). All sorted values are pure ASCII CSS variable names and dot-paths, so the determinism gate (`git diff --exit-code`) stays clean after regeneration. All harness gates (`verify`, `verify-specimens`, `parity`, `parity-test`) pass after the change.

---

_Fixed: 2026-06-13T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
