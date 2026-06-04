---
phase: 174-a-design-system-gap-closure-token-completeness
plan: "05"
subsystem: ui
tags: [design-system, component-registry, css-tokens, elixir, testing, exunit]

requires:
  - phase: 174-04
    provides: ComponentRegistry drift test (test a and b) — the token-validity test (c) extends this

provides:
  - Corrected ComponentRegistry with real CSS token names for all 15 entries (0 phantom tokens)
  - Token-validity ExUnit test that reads theme.css and app.css at test time and fails on any undefined token

affects: [component-registry, design-system, dev-components-page, 174-VERIFICATION]

tech-stack:
  added: []
  patterns:
    - "CSS token validation via File.read! in ExUnit — test reads static assets at test time to enforce registry truthfulness"
    - "Allowlist pattern for layout-injected tokens (--ax-accent/--ax-accent-readable) that cannot be grepped from static files"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
    - accrue_admin/test/accrue_admin/dev/component_registry_test.exs

key-decisions:
  - "status/ink uses only --ax-primary (not two tokens) because app.css .ax-status-badge-ink uses a single color token with color-mix for the background"
  - "card/slate and card/ink share the same token set [--ax-primary, --ax-muted, --ax-transition-colors] because .ax-kpi-delta-slate and .ax-kpi-delta-ink share a CSS rule block"
  - "Path resolution uses 3 ../ levels from __DIR__ (not 4) because the test is 3 directories deep inside accrue_admin/"
  - "known_in_layouts allowlist explicitly documents why --ax-accent/--ax-accent-readable are exempt from CSS grep check"

patterns-established:
  - "Pattern: Token-presence test — read CSS file contents at test time and assert each registry token appears as substring; simpler and more maintainable than parsing CSS AST"

requirements-completed: [DSY-03]

duration: 8min
completed: 2026-06-04
---

# Phase 174 Plan 05: ComponentRegistry Phantom Token Fix + Token-Validity Test Summary

**Fixed 6 phantom CSS tokens in ComponentRegistry and added a grep-based token-validity ExUnit test that prevents re-introduction via CI**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-04T21:55:00Z
- **Completed:** 2026-06-04T22:03:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced 6 phantom token entries (--ax-neutral, --ax-neutral-readable, --ax-ink, --ax-ink-readable, --ax-info for cobalt variants) with real CSS custom property names confirmed in theme.css and app.css
- Added third ExUnit test "all tokens listed in ComponentRegistry.entries() are defined in the design system" that reads CSS files at test time and fails immediately on any phantom token
- Verified the test catches reintroduced phantom tokens with a descriptive failure message showing family/variant/token
- Full admin suite: 172 tests, 0 failures

## Task Commits

1. **Task 1: Fix phantom token values in ComponentRegistry** - `82d2588d` (fix)
2. **Task 2: Add token-validity test to ComponentRegistryTest** - `4728726c` (test)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — 6 entries corrected: status/cobalt, status/slate, status/ink, card/cobalt, card/slate, card/ink
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — added test (c) + two private path helpers

## Decisions Made

- **status/ink uses only 2 tokens** (`--ax-primary`, `--ax-elevated`) because `.ax-status-badge-ink` in app.css uses only `--ax-primary` directly (color-mix for bg uses `--ax-primary` again, same token). The plan spec confirms this.
- **card/slate and card/ink share identical token sets** because `.ax-kpi-delta-slate` and `.ax-kpi-delta-ink` share a single CSS rule block in app.css using `--ax-primary` and `--ax-muted`.
- **Path depth is 3 `../` levels** (not 4 as in the plan's `read_first` hint): the test file is at `accrue_admin/test/accrue_admin/dev/`, which is 3 directories below `accrue_admin/`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected Path.expand depth from 4 to 3 `../` levels**
- **Found during:** Task 2 (token-validity test) — first test run
- **Issue:** Plan specified `Path.expand("../../../../assets/css/theme.css", __DIR__)` (4 levels up), but the test directory is 3 levels deep inside `accrue_admin/` so 4 levels overshoots into the parent monorepo root, producing "no such file or directory"
- **Fix:** Changed to `Path.expand("../../../assets/css/theme.css", __DIR__)` (3 levels)
- **Files modified:** `accrue_admin/test/accrue_admin/dev/component_registry_test.exs`
- **Verification:** Test runs and finds theme.css correctly; all 3 tests green
- **Committed in:** `4728726c` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - path depth bug from incorrect plan hint)
**Impact on plan:** Necessary fix; the test would not have run without it. No scope creep.

## Issues Encountered

None beyond the path depth deviation above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DSY-03 Gap 1 is fully closed: ComponentRegistry has 0 phantom tokens, and re-introduction is blocked by CI test
- 174-VERIFICATION.md Gap 1 can be marked resolved
- Ready for plan 174-06 or phase-gate verification

## Self-Check

- [x] `accrue_admin/lib/accrue_admin/dev/component_registry.ex` modified — confirmed commit `82d2588d`
- [x] `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` modified — confirmed commit `4728726c`
- [x] grep for phantom tokens returns 0 lines
- [x] entry count: 15 data entries (16 grep hits includes `@type` field definition)
- [x] all 3 ComponentRegistryTest tests green
- [x] full admin suite 172 tests, 0 failures

## Self-Check: PASSED

---
*Phase: 174-a-design-system-gap-closure-token-completeness*
*Completed: 2026-06-04*
