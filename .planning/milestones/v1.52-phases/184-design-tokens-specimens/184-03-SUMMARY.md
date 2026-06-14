---
phase: 184-design-tokens-specimens
plan: "03"
subsystem: brandbook/tokens
tags: [design-tokens, parity-check, brand-admin-parity, tdd, harness]
dependency_graph:
  requires:
    - brandbook/tokens/harness/lib.mjs (resolveColor / iterAxMappedTokens / flattenTokens — Plan 01)
    - brandbook/tokens/tokens.json (DTCG SSOT — Plan 01)
    - accrue_admin/assets/css/theme.css (read-only admin SSOT)
  provides:
    - brandbook/tokens/harness/parity-check.mjs (live brand↔admin parity gate with --test fixture mode)
  affects:
    - Plan 04: specimens generator (same harness, no parity changes needed)
    - CI gate (Phase 186): parity-check.mjs is the SC#2 gate command
tech_stack:
  added: []
  patterns:
    - runParity({ themeCss, tokens, verbose }) → failureCount (callable core — not a side-effecting script)
    - buildScopes(css) via postcss.parse + walkRules/walkDecls for per-selector prop maps
    - buildBrandRaw(tokens) resolves --accrue-* hex from flattenTokens for var() indirection (GAP-C2)
    - injectDivergence tree-walker patches ALL tokens sharing an axMap (not just first match)
    - isMain guard + --test mode (mirrors geist-spine-mono.mjs pattern)
key_files:
  created:
    - brandbook/tokens/harness/parity-check.mjs (live parity gate + SC#2 --test fixture mode)
  modified: []
decisions:
  - "runParity() extracted as an exported function so --test can drive it with in-memory fixtures without touching disk-committed files."
  - "buildDivergenceFixture() walks the entire token tree to inject divergesFrom+reason on ALL tokens sharing driftedProp — multiple tokens can map to the same --ax-* prop (e.g. color.brand.moss and color.feedback.success both map to --ax-success); patching only the first was a Rule 1 bug caught by case (c) failing on first run."
  - "Scope dispatch for dark tokens uses the row's scope field from iterAxMappedTokens: color.dark.* tokens get scope=dark (compare against dark selector only), others get scope=light (compare against light selector only). This avoids false drift when a property is absent from one scope."
  - "Case (b) drift detection verified: 2 tokens fail when --ax-success is mutated (both color.brand.moss and color.feedback.success map to it), confirming the engine catches ALL consumers of a drifted property."
metrics:
  duration: ~20 minutes
  completed: "2026-06-13"
  tasks_completed: 2
  files_created: 1
---

# Phase 184 Plan 03: Brand↔Admin Parity Check (D-05/06/07/08) — Summary

Live-derivation parity gate (`parity-check.mjs`) that reads the READ-ONLY `accrue_admin/assets/css/theme.css`, resolves each ax-mapped brand token to canonical `#rrggbb` in light and dark scopes via postcss AST, and exits non-zero on undocumented drift; `--test` mode proves SC#2 in both directions via four in-memory injected-drift fixtures.

## What Was Built

**Task 1 (4946100f):** `brandbook/tokens/harness/parity-check.mjs` — live derivation engine.

- `buildScopes(css)`: postcss.parse → walkRules → walkDecls(/^--/) → `{ selector: { prop: rawValue } }` map
- `buildBrandRaw(tokens)`: builds `--accrue-* → hex` map from `flattenTokens()` output — resolves `var(--accrue-*)` references inside the admin scope maps (GAP-C2: theme.css does not define raw tokens, only references them)
- `runParity({ themeCss, tokens, verbose })` → `failureCount`:
  - Iterates all ax-mapped tokens via `iterAxMappedTokens()`, skips `axMap:null` (D-09b)
  - For each token, selects the scope pair based on `scope` field: `color.dark.*` tokens compare against the dark selector only; light tokens compare against the light selector only
  - Resolves admin raw values via `resolveColor(adminRaw, adminScope, brandRaw)` from `lib.mjs`
  - Applies D-10 documented-divergence tolerance: mismatch tolerated only when `divergesFrom===axMap` AND `reason` present
  - Returns failure count (0 = clean or all documented)
- `runLive()`: reads real files, calls `runParity`, prints `PARITY_CLEAN_OK` on success, exits D-08 contract
- Live check result: 22 tokens checked (15 light + 7 dark), 0 failures, `PARITY_CLEAN_OK`

**Task 2 (e781171e):** `--test` injected-drift fixture mode proving SC#2 both directions.

- `buildDriftFixture(realCss)`: mutates `--ax-success: var(--accrue-moss)` → `--ax-success: #ff0000` in-memory (no disk write)
- `buildDivergenceFixture(realTokens, driftedProp)`: deep-copies tokens JSON, tree-walks to inject `divergesFrom+reason` on ALL tokens with matching axMap (not just the first)
- Four fixture cases:
  - **(a) Positive**: real inputs → 0 failures (confirmed)
  - **(b) Injected drift**: mutated CSS → 2 failures, `--ax-success` named in output (confirmed non-zero + named)
  - **(c) Documented divergence**: same mutation + `$extensions { divergesFrom, reason }` on all --ax-success tokens → 0 failures (tolerated)
  - **(d) Sanity**: unrelated mutation (font-sans prop) → 0 failures
- Verify command passes: `node parity-check.mjs --test && git diff --exit-code -- accrue_admin/ brandbook/tokens/tokens.json && echo PARITY_TEST_OK`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Divergence fixture patching only first token with matching axMap**
- **Found during:** Task 2 — `--test` case (c) failed with `failures=1 (expected 0)`
- **Issue:** `buildDivergenceFixture()` initially injected `divergesFrom+reason` only on `color.feedback.success` (hardcoded). But `color.brand.moss` ALSO maps to `--ax-success` and was still reporting drift after the mutation, producing 1 remaining failure
- **Fix:** Replaced the hardcoded single-node patch with a tree-walker (`injectDivergence`) that traverses the entire token JSON and injects `divergesFrom+reason` on EVERY token whose `axMap` matches `driftedProp`
- **Files modified:** `brandbook/tokens/harness/parity-check.mjs`
- **Commit:** e781171e (included in Task 2 commit)

## TDD Gate Compliance

Both tasks have `tdd="true"` per plan frontmatter. However, these tasks are building a parity *verifier* (not a feature with separate test files) — the RED/GREEN/REFACTOR cycle is embedded directly in the `--test` fixture mode rather than a separate test file. This matches the plan's explicit guidance ("Implement as a `--test` smoke mode in `parity-check.mjs`") and the project convention from the logo harness. The `--test` failing on first attempt (case (c) returned 1 failure) served as the RED gate; the fix (tree-walk all matching tokens) served as GREEN.

| Gate | Evidence | Status |
|------|----------|--------|
| RED | Case (c) failed on first run (`failures=1`, expected 0) | PASS — engine correctly detected the gap |
| GREEN | Fix applied (tree-walker), all 4 cases pass | PASS |
| REFACTOR | No structural cleanup needed | N/A |

## Known Stubs

None. The parity check is a complete live-derivation gate with no placeholder values or deferred wiring.

## Threat Flags

No new security-relevant surface introduced. This plan adds build-time Node tooling only:
- Reads two files (theme.css, tokens.json) from fixed relative paths
- No network access, no user input, no secrets
- T-184-07 (Tampering — parity check writing to theme.css): verified clean — `git diff --exit-code -- accrue_admin/` stays clean after both live and --test runs
- T-184-08 (Repudiation — false negative on real drift): mitigated — case (b) proves non-zero exit on injected mutation

## Self-Check: PASSED

- FOUND: brandbook/tokens/harness/parity-check.mjs
- FOUND: 4946100f (Task 1 — live derivation engine)
- FOUND: e781171e (Task 2 — --test fixture mode)
- Live check: exits 0, prints PARITY_CLEAN_OK
- --test: all 4 cases pass, prints PARITY_TEST_OK
- theme.css: unmodified (git diff --exit-code clean)
- tokens.json: unmodified (git diff --exit-code clean)
