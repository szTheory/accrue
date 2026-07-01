---
phase: "193"
plan: "05"
subsystem: accrue_admin
status: complete
tags:
  - ci-gates
  - css-guards
  - verify-package-docs
  - res-04
  - sty-01
dependency_graph:
  requires:
    - "193-01-SUMMARY.md (spec guides + router.ex with Code.ensure_loaded?(PhoenixStorybook.Router))"
    - "193-04-SUMMARY.md (Storybook Spike D — Assets bundle route, confirms router.ex guard form)"
  provides:
    - "scripts/ci/verify_package_docs.sh — three RES-04 CSS guards + six spec doc-needles + two STY-01 Storybook merge-blocking needles"
    - "accrue/test/accrue/docs/package_docs_verifier_test.exs — seed_tmp_dir! D-08 extensions + three CSS guard negative tests"
  affects:
    - "Phase 194+ (all phases that touch app.css will be CI-gated by these guards)"
    - "Phase 200 idempotent verification (guards are part of the CI baseline)"
tech_stack:
  added: []
  patterns:
    - "append-not-replace for planted violations in PackageDocsVerifier negative tests (preserves earlier guard coverage)"
    - "trailing newline required for Guard A perl /([^\\n]+)\\n/g pattern (structural requirement)"
    - "ax-spacing-exception: comment allowlist for structural micro-spacings (1px hairlines, segmented-control insets, -1px clip patterns)"
key_files:
  created: []
  modified:
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - accrue_admin/assets/css/app.css
decisions:
  - "Fix violations before adding guards (not allowlist-skip): three Guard A pre-existing violations (ax-spacing-exception comments), one Guard B violation (skip-link :focus → :focus-visible), two Guard C violations (min-width:0 added to .ax-inline-id and .ax-id-badge-text)"
  - "Planted violations use File.write!(path, content, [:append]) not File.write!(path, content) — full replacement breaks earlier token-consumption guards that expect the seeded app.css"
  - "Guard A trailing newline: perl -0ne slurp with /([^\\n]+)\\n/g skips the last line if no \\n — planted violation must end with \\n"
requirements-completed:
  - RES-04
  - STY-01
metrics:
  duration: "~9 minutes"
  completed: "2026-06-25"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 3
---

# Phase 193 Plan 05: CSS Guards + Spec Doc Needles + Test Coupling Summary

Three RES-04 CSS source guards, six spec doc-needles, two STY-01 Storybook merge-blocking needles added to verify_package_docs.sh; PackageDocsVerifierTest extended with D-08-required copy_fixture! calls and three CSS guard negative tests.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add CSS guards and spec doc-needles to verify_package_docs.sh | a736243a | scripts/ci/verify_package_docs.sh, accrue_admin/assets/css/app.css |
| 2 | Extend PackageDocsVerifierTest with seed_tmp_dir! copies and three negative guard tests | 00c7196d | accrue/test/accrue/docs/package_docs_verifier_test.exs |

## What Was Built

### Three RES-04 CSS source guards in verify_package_docs.sh

**Guard A — Spacing-literal ban:**
Rejects `padding`, `margin`, or `gap` using raw px values (e.g. `padding: 16px`) unless the line contains `var(--ax-` or an `/* ax-spacing-exception: */` comment. Structural micro-spacings (1px hairlines, 2px/3px segmented-control insets, -1px clip patterns) are allowlisted with inline comments.

**Guard B — :focus-visible enforcement:**
Rejects any `:focus` selector that is not `:focus-visible`. Uses `grep -En ':focus[^-]' | grep -v ':focus-visible'`, so lines like `:focus:not(:focus-visible)` (which contain `:focus-visible`) are correctly excluded.

**Guard C — Truncation without min-width:0:**
Perl block-level scan rejects any CSS block containing `text-overflow: ellipsis` without `min-width: 0` in the same block.

### app.css violation pre-fixes

Before adding the guards, all pre-existing violations were fixed:

- **Guard A** (7 lines): `gap: 1px` ×2 (dev state grid hairlines), `gap: 2px; padding: 3px` ×2 (theme-picker and segmented controls), `margin: -1px` ×2 (visually-hidden clip patterns) — all annotated with `/* ax-spacing-exception: ... */`
- **Guard B** (1 line): `.ax-skip-link:focus` → `.ax-skip-link:focus-visible`
- **Guard C** (2 blocks): `.ax-inline-id` and `.ax-id-badge-text` — both received `min-width: 0` (`.ax-id-badge-text` is a flex child; `.ax-inline-id` is `inline-block` where it's also harmless)

### Six spec doc-needles in verify_package_docs.sh

Three `require_fixed` checks asserting spec guide ExDoc wiring in `accrue_admin/mix.exs`:
- `'"guides/spec-overview.md"'`
- `'"guides/spec-list.md"'`
- `'"guides/spec-detail.md"'`

Three `require_fixed` checks asserting stable anchor headings in guide files:
- `"## SPEC-OVERVIEW — "` in `guides/spec-overview.md`
- `"## SPEC-LIST — "` in `guides/spec-list.md`
- `"## SPEC-DETAIL — summary-then-drill"` in `guides/spec-detail.md`

### Two STY-01/D-07 Storybook merge-blocking needles

- `require_fixed "$ROOT_DIR/accrue_admin/mix.exs" ':phoenix_storybook'`
- `require_fixed "$ROOT_DIR/accrue_admin/lib/accrue_admin/router.ex" 'Code.ensure_loaded?(PhoenixStorybook.Router)'`

### PackageDocsVerifierTest extensions

**seed_tmp_dir! D-08 additions:**
- `copy_fixture!("accrue_admin/guides/spec-overview.md", tmp_dir)` — required for spec-overview needle negative tests
- `copy_fixture!("accrue_admin/guides/spec-list.md", tmp_dir)` — required for spec-list needle negative tests
- `copy_fixture!("accrue_admin/guides/spec-detail.md", tmp_dir)` — required for spec-detail needle negative tests
- `File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/lib/accrue_admin"))` — ensures subdirectory exists before router.ex copy
- `copy_fixture!("accrue_admin/lib/accrue_admin/router.ex", tmp_dir)` — required for `Code.ensure_loaded?(PhoenixStorybook.Router)` needle negative tests

**Three new negative test cases (append pattern):**
Each test appends the violation to the seeded app.css (not replaces it) so earlier guards (token consumption, motion, CMP-05) still pass. Violation strings end with `\n` because Guard A's perl script uses `/([^\n]+)\n/g` and misses the last line without a terminating newline.

## Verification Results

All 12 plan verification checks pass:

```
1.  bash scripts/ci/verify_package_docs.sh                                    → exits 0  ✓
2.  grep -c "RES-04 spacing-literal guard" scripts/ci/verify_package_docs.sh → 1         ✓
3.  grep -c "RES-04 focus-visible guard" scripts/ci/verify_package_docs.sh   → 1         ✓
4.  grep -c "RES-04 truncation guard" scripts/ci/verify_package_docs.sh      → 1         ✓
5.  grep -c '"guides/spec-overview.md"' scripts/ci/verify_package_docs.sh    → 1         ✓
6.  grep -c '"guides/spec-list.md"' scripts/ci/verify_package_docs.sh        → 1         ✓
7.  grep -c '"guides/spec-detail.md"' scripts/ci/verify_package_docs.sh      → 1         ✓
8.  grep -c "':phoenix_storybook'" scripts/ci/verify_package_docs.sh         → 1         ✓
9.  grep -c "Code.ensure_loaded?..." scripts/ci/verify_package_docs.sh       → 1         ✓
10. grep -c "spec-overview.md" accrue/test/...package_docs_verifier_test.exs → 1         ✓
11. grep -c "router.ex" accrue/test/...package_docs_verifier_test.exs        → 1         ✓
12. cd accrue && mix test ...package_docs_verifier_test.exs                  → 32 tests, 0 failures ✓
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing Guard A violations fixed before adding guard**
- **Found during:** Task 1 — pre-flight check per plan's IMPORTANT note
- **Issue:** 7 lines in app.css used raw px for `gap`/`padding`/`margin`: two `gap: 1px` structural hairlines, two `gap: 2px; padding: 3px` segmented-control insets, two `margin: -1px` visually-hidden clip patterns
- **Fix:** Added `/* ax-spacing-exception: ... */` inline comments with rationale on each line
- **Files modified:** `accrue_admin/assets/css/app.css`
- **Commit:** a736243a

**2. [Rule 1 - Bug] Pre-existing Guard B violation fixed before adding guard**
- **Found during:** Task 1 — pre-flight check
- **Issue:** `.ax-skip-link:focus` used bare `:focus` for skip-link positioning; `.ax-shell-content:focus:not(:focus-visible)` was a false positive (line contains `:focus-visible` so `grep -v ':focus-visible'` correctly excludes it)
- **Fix:** Changed `.ax-skip-link:focus` to `.ax-skip-link:focus-visible`
- **Files modified:** `accrue_admin/assets/css/app.css`
- **Commit:** a736243a

**3. [Rule 1 - Bug] Pre-existing Guard C violations fixed before adding guard**
- **Found during:** Task 1 — pre-flight check
- **Issue:** `.ax-inline-id` (inline-block) and `.ax-id-badge-text` (flex child) both had `text-overflow: ellipsis` without `min-width: 0`
- **Fix:** Added `min-width: 0` to both blocks
- **Files modified:** `accrue_admin/assets/css/app.css`
- **Commit:** a736243a

**4. [Rule 1 - Bug] Negative test pattern: append not replace**
- **Found during:** Task 2 — test run showed planted violation tests failing with "missing interactive role consumption" error
- **Issue:** Plan specified `File.write!(path, content)` which replaces the entire app.css; but earlier guards (require_css_rule_consumes for `--ax-interactive-hover` etc.) require the full seeded app.css content to be present. Replacing app.css with a single-line violation drops all required token usage.
- **Fix:** Changed to `File.write!(path, content, [:append])` so the violation is appended to the seeded app.css
- **Files modified:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- **Commit:** 00c7196d

**5. [Rule 1 - Bug] Guard A needs trailing newline on planted violation**
- **Found during:** Task 2 — first run with append showed Guard A test passing (status 0) instead of failing
- **Issue:** Guard A's perl script uses `/([^\n]+)\n/g` which requires a newline terminator; the last line of the appended content (no trailing `\n`) is silently skipped
- **Fix:** Changed appended violation string to include trailing `\n` (e.g. `"\n.ax-foo { padding: 16px; }\n"`)
- **Files modified:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- **Commit:** 00c7196d

## Known Stubs

None. These are CI guards and test infrastructure; no runtime data flows.

## Threat Flags

None. Guards read app.css as an untrusted input but only via grep/perl with fixed patterns; no code execution from file content. Tests write to isolated tmp_dir; no mutation of the real repo filesystem.

## Self-Check: PASSED

Files modified:
- FOUND: scripts/ci/verify_package_docs.sh
- FOUND: accrue/test/accrue/docs/package_docs_verifier_test.exs
- FOUND: accrue_admin/assets/css/app.css

Commits:
- FOUND: a736243a (task 1 — CSS guards + spec needles + app.css fixes)
- FOUND: 00c7196d (task 2 — test extensions)
