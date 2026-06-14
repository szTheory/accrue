---
phase: 184-design-tokens-specimens
plan: "02"
subsystem: brandbook/tokens
tags: [design-tokens, dtcg, css-gen, determinism, readme, verification, tdd]
dependency_graph:
  requires:
    - Plan 01: brandbook/tokens/tokens.json (DTCG SSOT)
    - Plan 01: brandbook/tokens/harness/lib.mjs (flattenTokens / deriveCssVar)
  provides:
    - brandbook/tokens/tokens.css (generated CSS custom properties — light + dark blocks)
    - brandbook/tokens/harness/generate-tokens-css.mjs (deterministic generator)
    - brandbook/tokens/README.md (reference-only scale table + brand-only docs)
    - brandbook/tokens/harness/verify-tokens.mjs (SC#1 structural completeness assertion)
  affects:
    - Plan 03: parity-check.mjs reads tokens.css and tokens.json
    - Plan 04: specimen generator imports lib.mjs + reads tokens.json and tokens.css
    - Plan 05: CI determinism gate checks `git diff --exit-code brandbook/tokens/tokens.css`
key_files:
  created:
    - brandbook/tokens/harness/generate-tokens-css.mjs (deterministic CSS emitter ~55 lines, D-03)
    - brandbook/tokens/tokens.css (GENERATED — :root light block + :root[data-theme="dark"] block)
    - brandbook/tokens/README.md (reference-only D-11 scale table + brand-only D-09b docs)
    - brandbook/tokens/harness/verify-tokens.mjs (SC#1 completeness assertion — 23 tokens + 1 structural pattern)
    - brandbook/tokens/harness/generate-tokens-css.test.mjs (TDD RED/GREEN test for generator)
    - brandbook/tokens/harness/verify-tokens.test.mjs (TDD RED/GREEN test for verifier)
  modified: []
decisions:
  - "generate-tokens-css.mjs stays under 60 lines (D-03) by importing flattenTokens from lib.mjs — no inline flattening"
  - "brand-only comment placed as a line above (not inline) each axMap:null token for clean multi-line CSS readability"
  - "verify-tokens.mjs accepts CSS_PATH_OVERRIDE env var so the TDD negative check can inject a mutated fixture without modifying the real tokens.css"
  - "README mints zero --accrue-scale-* tokens (D-11 compliance) — all scale rows reference --ax-* admin tokens as SSOT"
metrics:
  duration: ~20 minutes
  completed: "2026-06-13"
  tasks_completed: 3
  files_created: 6
---

# Phase 184 Plan 02: CSS Generator, README Scale Table, Verifier — Summary

Deterministic `tokens.css` generator from the DTCG SSOT, reference-only D-11 scale documentation in `README.md`, and a SC#1 structural completeness verifier — all derived from the Plan 01 `lib.mjs` and `tokens.json` foundation.

## What Was Built

**Task 1 — RED (eea24d70) + GREEN (739b4f94): `generate-tokens-css.mjs` + `tokens.css`**

Small deterministic emitter (~55 lines, D-03) that:
- Reads `tokens.json`, flattens via `lib.mjs` `flattenTokens()`
- Sorts all rows by `cssVar` with `localeCompare()` for determinism (D-17)
- Emits `/* GENERATED from tokens.json — do not edit. Run: npm run generate */` banner
- Emits `:root { }` light block from scope-light rows
- Emits `:root[data-theme="dark"] { }` dark block from scope-dark rows
- Adds `/* brand-only: no --ax-* counterpart */` comment above each `axMap:null` token (D-09b)
- Exactly one trailing newline, LF line endings

`tokens.css` contains 24 light-scope custom properties and 7 dark-scope custom properties. The determinism gate (`git diff --exit-code`) passes after second run with no changes.

**Task 2 — (2ade7481): `README.md` reference-only scale table**

Markdown documentation with four sections:
1. **Generation** — tokens.json SSOT, GENERATED guard, CI determinism gate, npm ci reinstall
2. **Raw palette + semantic roles** — pointer to tokens.css + tokens.json
3. **Reference-only scales (D-11)** — Markdown tables for typography (9 rows: font stacks + 7 type sizes), spacing (8 rungs 2xs..3xl with px+rem), radius (5 entries + pill), focus-ring spec (WCAG 2.4.11 + color-mix note), state tokens (hover/active/disabled/loading)
4. **Brand-only tokens (D-09b)** — all 8 axMap:null tokens documented (fog, cobalt, interactive-accent, interactive-focus-ring, code-block-*, callout-*)

Zero `--accrue-space-*`, `--accrue-radius-*`, `--accrue-type-*` tokens minted (D-11 compliance verified).

**Task 3 — RED (d4a58609) + GREEN (c6dae9a9): `verify-tokens.mjs`**

SC#1 structural completeness assertion:
- 7 raw palette tokens with exact hex values
- 10 semantic role tokens (surface × 3, content × 3, feedback × 4)
- 2 interactive brand-only tokens
- 4 D-09b brand-only tokens (code-block + callout)
- Dark block structural pattern (`/:root\[data-theme="dark"\]/`)

Total: 23 token assertions + 1 structural pattern. Exits 0 when complete; exits 1 naming each missing token. Accepts `CSS_PATH_OVERRIDE` env var for test negative-check fixtures. isMain guard mirrors `geist-spine-mono.mjs` pattern.

## TDD Gate Compliance

| Task | Gate | Commit | Status |
|------|------|--------|--------|
| Task 1 | RED (test fails) | eea24d70 | PASS — 2 failures (generator + tokens.css missing) |
| Task 1 | GREEN (tests pass) | 739b4f94 | PASS — 8/8 assertions; GEN_DETERMINISM_OK |
| Task 3 | RED (test fails) | d4a58609 | PASS — 1 failure (verify-tokens.mjs missing) |
| Task 3 | GREEN (tests pass) | c6dae9a9 | PASS — 4/4 assertions; negative check confirms non-zero exit + names missing token |

## Deviations from Plan

None — plan executed exactly as written. Both TDD RED gates failed on missing-file errors as expected before implementation; both GREEN gates passed all assertions.

## Known Stubs

None. All generated tokens carry real hex values from `tokens.json`. README prose references real `--ax-*` token names from `theme.css`. No placeholder text or empty data flows.

## Threat Flags

No new security-relevant surface introduced. This plan adds:
- Build-time Node tooling only (no runtime, no network, no user input, no secrets)
- `tokens.css` is committed source (no external fetch)
- T-184-04 (non-deterministic generation) mitigated: `localeCompare` sort, LF endings, single trailing newline, `$value.hex` read path — all in place. Determinism gate verified.
- T-184-05 (hand-edit tampering) mitigated: GENERATED banner present; CI gate documented in README.

## Self-Check: PASSED

Files exist:
- FOUND: brandbook/tokens/harness/generate-tokens-css.mjs
- FOUND: brandbook/tokens/tokens.css
- FOUND: brandbook/tokens/README.md
- FOUND: brandbook/tokens/harness/verify-tokens.mjs
- FOUND: brandbook/tokens/harness/generate-tokens-css.test.mjs
- FOUND: brandbook/tokens/harness/verify-tokens.test.mjs

Commits exist:
- FOUND: eea24d70 (Task 1 RED)
- FOUND: 739b4f94 (Task 1 GREEN)
- FOUND: 2ade7481 (Task 2 README)
- FOUND: d4a58609 (Task 3 RED)
- FOUND: c6dae9a9 (Task 3 GREEN)

Verification gates:
- GEN_DETERMINISM_OK: git diff --exit-code brandbook/tokens/tokens.css (clean after second run)
- README_OK: all grep assertions pass, no --accrue-space minted
- VERIFY_TOKENS_OK: 23 tokens + 1 structural pattern verified; negative check exits 1 naming --accrue-moss
