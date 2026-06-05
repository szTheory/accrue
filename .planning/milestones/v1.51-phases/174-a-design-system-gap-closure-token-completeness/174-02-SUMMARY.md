---
phase: 174
plan: 02
subsystem: accrue_admin/css
tags: [design-system, tokens, css, migration, testing, ci]
dependency_graph:
  requires: [174-01]
  provides: [app.css-token-migrated, dunning-banner-bypass-free, breakpoint-drift-guard]
  affects: [accrue_admin/assets/css/app.css, accrue_admin/priv/static/accrue_admin.css, accrue_admin/lib/accrue_admin/components/dunning_banner.ex, scripts/ci/verify_package_docs.sh]
tech_stack:
  added: []
  patterns: [CSS custom property var() references, breakpoint registry comment pattern, grep guard in CI script, negative test coupling]
key_files:
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/components/dunning_banner.ex
    - accrue_admin/test/accrue_admin/components/dunning_banner_test.exs
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - accrue_admin/priv/static/accrue_admin.css
decisions:
  - Flag .ax-search-trigger transition as Phase D deferred (asymmetric speeds: colors use --ax-theme-transition; transform uses --ax-motion-fast at different duration)
  - Collapse .ax-related-item transition to var(--ax-transition-colors) (colors/border only, consistent with research)
  - Use grep -qv pattern for breakpoint guard in verify_package_docs.sh (not require_absent_regex) because the guard needs to cross-check two conditions
metrics:
  duration: 15m
  completed: "2026-06-03"
  tasks_completed: 4
  tasks_total: 4
  files_changed: 6
---

# Phase 174 Plan 02: app.css Literal-to-Token Migration + DSY-02 Bypass Kill Summary

**One-liner:** Migrated all 13 line-height, 5 letter-spacing, and 10 breakpoint literal sites in app.css to var() token references; removed the last inline style= bypass from dunning_banner.ex; added a CI breakpoint drift guard with negative test coverage.

## What Was Built

### Task 1: app.css Migration (bcf51461)

**Breakpoint registry comment block** inserted after the last @font-face and before the html, body rule — documents all 5 bp values (--ax-bp-content/md/lg and the two max-width guards) as documented constants.

**All 10 @media breakpoint sites annotated** with inline token comments:
- `@media (min-width: 768px)` (2 sites) → `/* --ax-bp-md ↑ */`
- `@media (min-width: 1024px)` (3 sites) → `/* --ax-bp-lg ↑ */`
- `@media (min-width: 640px)` (2 sites) → `/* --ax-bp-content ↑ */`
- `@media (max-width: 599.98px)` (2 sites) → `/* --ax-bp-sm ↓ */`
- `@media (max-width: 1023.98px)` (1 site) → `/* --ax-bp-lg ↓ */`

**All 13 line-height literals migrated:**
- `line-height: 1.2` → `var(--ax-leading-tight)` (3 sites: .ax-sidebar-name/.ax-heading, .ax-display/.ax-kpi-value, .ax-badge)
- `line-height: 1.4` → `var(--ax-leading-normal)` (9 sites: .ax-label, .ax-filter-chip, .ax-breadcrumbs-*, .ax-button/.ax-status-badge, .ax-field-label (first), .ax-field-help/.ax-field-error/.ax-dropdown-item-description, .ax-dropdown-item-label, .ax-tab)
- `line-height: 1.5` → `var(--ax-leading-relaxed)` (2 sites: .ax-body, .ax-timeline-details pre/.ax-json-raw)

**All 5 letter-spacing literals migrated:**
- `letter-spacing: 0.08em` → `var(--ax-tracking-caps)` (2 sites: .ax-dev-toolbar-label, .ax-sidebar-group-label)
- `letter-spacing: 0.04em` → `var(--ax-tracking-wide)` (2 sites: .ax-eyebrow, .ax-field-label second occurrence)
- `letter-spacing: -0.02em` → `var(--ax-tracking-tight)` (1 site: .ax-summary-title)

**4 multi-line transition blocks collapsed:**
- `.ax-sidebar-link, .ax-card, ...` → `transition: var(--ax-transition-base)`
- `.ax-button` → `transition: var(--ax-transition-base)`
- `.ax-launcher` → `transition: var(--ax-transition-base)`
- `.ax-related-item` → `transition: var(--ax-transition-colors)` (colors/border only)

**.ax-measure utility class added** near typography utilities: `.ax-measure { max-width: var(--ax-measure); }`

### Task 2: dunning_banner.ex Bypass Kill (4acaec24)

Removed the `style=` attribute with hex fallbacks (`#fef2f2`, `#991b1b`, `#fecaca`) from the outer div in dunning_banner.ex. The banner now renders purely via `.ax-banner.ax-banner-danger` CSS class tokens. Added `refute html =~ ~s(style=)` regression assertion to dunning_banner_test.exs.

### Task 3: Breakpoint Guard + Test Coupling (6b042c8d)

Added a new CI guard section to `verify_package_docs.sh`:
```bash
app_css="$ROOT_DIR/accrue_admin/assets/css/app.css"
if grep -E '@media \((min|max)-width: [0-9.]+px\)' "$app_css" | grep -qv '\-\-ax-bp-'; then
  fail "$app_css must not have bare breakpoint @media without an --ax-bp-* annotation comment ..."
fi
```

Updated `PackageDocsVerifierTest.seed_tmp_dir!`:
- Added `File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/assets/css"))`
- Added `copy_fixture!("accrue_admin/assets/css/app.css", tmp_dir)`

Added new negative test: injects a bare `@media (min-width: 900px)` without an `--ax-bp-*` comment, asserts the guard exits non-zero with "app.css" and "--ax-bp-" in output.

### Task 4: Asset Bundle Rebuild (d31f306d)

Ran `mix accrue_admin.assets.build` to regenerate `priv/static/accrue_admin.css`. Bundle reflects all token migrations — zero bare `line-height: 1.x` literals in minified output.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Migrate app.css literals to token references + breakpoint registry | bcf51461 | accrue_admin/assets/css/app.css |
| 2 | Remove dunning_banner.ex inline style bypass + regression assertion | 4acaec24 | accrue_admin/lib/accrue_admin/components/dunning_banner.ex, accrue_admin/test/accrue_admin/components/dunning_banner_test.exs |
| 3 | Add breakpoint guard to verify_package_docs.sh + PackageDocsVerifierTest coupling | 6b042c8d | scripts/ci/verify_package_docs.sh, accrue/test/accrue/docs/package_docs_verifier_test.exs |
| 4 | Rebuild asset bundle | d31f306d | accrue_admin/priv/static/accrue_admin.css |

## Verification Results

All 8 verification steps passed:

1. `grep -E 'line-height: [0-9]\.[0-9]' app.css` → 0 lines (PASS)
2. `grep -E 'letter-spacing: -?[0-9.]+em' app.css` → 0 lines (PASS)
3. `grep -E '@media ...' app.css | grep -v '--ax-bp-'` → 0 lines (PASS)
4. `grep -rn 'style=' dunning_banner.ex` → 0 lines (PASS)
5. `bash scripts/ci/verify_package_docs.sh` → exit 0 (PASS)
6. `mix test dunning_banner_test.exs` → 3 tests, 0 failures (PASS)
7. `mix test package_docs_verifier_test.exs` → 9 tests, 0 failures (PASS)
8. `mix test` (full accrue_admin suite, --seed 0) → 169 tests, 0 failures (PASS)

## Deviations from Plan

### Auto-applied judgment (within plan scope)

**1. .ax-search-trigger transition flagged for Phase D (asymmetric speed)**
- **Found during:** Task 1, inspecting the transition block at line ~1446
- **Issue:** The block mixes `--ax-theme-transition` (colors, same as --ax-dur-2 --ax-ease-out) with `--ax-motion-fast` (transform, which is --ax-dur-1 --ax-ease-out — a shorter duration). These are intentionally different speeds.
- **Action:** Added `/* Phase D: asymmetric speed — collapse pending */` comment and left the block as-is, per plan guidance "If it mixes mixed speeds, flag it with a comment and leave as-is."
- **Files modified:** accrue_admin/assets/css/app.css (comment only)

This deviates from 5 transition collapses (achieved 4) but matches the plan's explicit guidance for this case.

## Known Stubs

None. All token migrations are complete and wired to real var() values from theme.css Plan 01.

## Threat Flags

None. All changes are CSS custom property references, template attribute removal, and CI guard additions — no new network endpoints, auth paths, or trust-boundary-crossing file access.

## Self-Check: PASSED

- [x] `accrue_admin/assets/css/app.css` contains breakpoint registry block (grep --ax-bp-content returns >= 1)
- [x] Zero bare line-height literals in app.css
- [x] Zero bare letter-spacing literals in app.css
- [x] Zero unguarded @media breakpoints in app.css
- [x] `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` has no style= attribute
- [x] `accrue_admin/priv/static/accrue_admin.css` rebuilt and committed
- [x] Commits bcf51461, 4acaec24, 6b042c8d, d31f306d exist in git log
- [x] All 4 plan-level acceptance criteria verified
