---
phase: 246-collection-controls-and-search
plan: 03
subsystem: ui
tags: [phoenix-liveview, global-search, command-palette, playwright, ecto]

# Dependency graph
requires:
  - phase: 246-01
    provides: authenticated mounted billing fixtures and Phase 246 browser harness
  - phase: 246-02
    provides: collection-control patterns and Phase 246 evidence conventions
provides:
  - compact global billing search with truthful pending, partial, retry, and empty states
  - one active pointer/keyboard result that governs paint, ARIA, and Enter navigation
  - authenticated held-out LiveView states and ordinary preview browser evidence
  - guarded ordinary fixture normalization for isolated Phase 191 stress namespaces
affects: [global-search, command-palette, browser-evidence, ordinary-preview-fixtures]

# Plan commit ledger (#3968)
commits: 4
plan_head_before: cec36eb8de11ebac5ad14c66669aa863d09ac677
plan_head_after: a4c00f5c8485de88206eab2823015a845a53ff28

# Actuals (#2632), chars/4 from the realized text diff
actuals:
  tokens: 102761
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - test-host-only authenticated fixture route under the existing SQL Sandbox compile-time gate
    - current async generation and owner guards remain the authority for search results
    - ordinary Fake fixture cleanup runs only after repository identity and preview custody guards

key-files:
  created:
    - examples/accrue_host/e2e/phase246-global-search.spec.js
    - examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex
    - .planning/phases/246-collection-controls-and-search/captures/phase246-global-search/manifest.json
  modified:
    - accrue_admin/lib/accrue_admin/components/global_search.ex
    - accrue_admin/assets/js/hooks/command_palette.js
    - accrue_admin/assets/css/app.css
    - examples/accrue_host/priv/repo/seeds/ordinary.exs
    - examples/accrue_host/test/ordinary_preview_seed_test.exs

key-decisions:
  - "Keep CommandPalette.activeIndex as the single source for pointer highlight, ARIA selection, and Enter navigation."
  - "Use the existing SQL Sandbox fixture lane for deterministic exceptional states and the guarded ordinary Fake preview for realistic search."
  - "Remove only allowlisted Phase 191 Fake stress fixtures during ordinary preview normalization; preserve ordinary showcase and linked billing data."

requirements-completed: [SEARCH-01]
coverage:
  - id: D1
    description: Compact global search exposes truthful current loading and preserves successful groups with scoped retry after partial failure.
    requirement: SEARCH-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/components/global_search_test.exs (20 tests)
        status: pass
      - kind: integration
        ref: examples/accrue_host/e2e/phase246-global-search.spec.js @phase246-heldout
        status: pass
    human_judgment: false
  - id: D2
    description: Pointer and keyboard navigation share one painted, announced, and activated result in the ordinary browser journey.
    requirement: SEARCH-01
    verification:
      - kind: unit
        ref: accrue_admin/test/js/command_palette_test.mjs (11 tests)
        status: pass
      - kind: e2e
        ref: examples/accrue_host/e2e/phase246-global-search.spec.js @phase246-ordinary
        status: pass
    human_judgment: false
  - id: D3
    description: Narrow held-out and broad ordinary captures record source and served-asset digests without changing Phase 245 evidence.
    verification:
      - kind: automated_ui
        ref: .planning/phases/246-collection-controls-and-search/captures/phase246-global-search/manifest.json
        status: pass
    human_judgment: false

# Metrics
duration: 53min
completed: 2026-10-11
status: complete
---

# Phase 246 Plan 03: Global Search Summary

**Global billing search now has a compact truthful dialog and one active result across pointer, keyboard, ARIA, and Enter, verified in ordinary and isolated mounted browser journeys.**

## Performance

- **Duration:** 53 minutes (measured from the first task commit through the final implementation commit)
- **Started:** 2026-10-11T12:59:40-04:00
- **Completed:** 2026-10-11T13:52:37-04:00
- **Tasks:** 2
- **Files modified or created:** 15

## Accomplishments

- Reworked the search trigger and dialog using existing design tokens, with the existing sized spinner visible only during a current request and hidden at rest. Partial results remain available and retry stays scoped to failed groups.
- Unified pointer and keyboard selection through `activeIndex`; hover cannot paint a second selection, and the active result controls ARIA and Enter. Focus containment and return remain covered.
- Added a test-host-only authenticated route that mounts the actual DataTable and GlobalSearch components for loading, error, partial, zero/one/many, and long Unicode states. The ordinary browser journey checks realistic data and writes new Phase 246 evidence with source and served-asset digests.
- Normalized the ordinary preview’s stale Phase 191 stress fixtures through the existing identity and custody-guarded seed wrapper. Its persistent database had 28 Phase 191 customers despite `ACCRUE_HOST_SKIP_SEEDS=1`; the seeded fixture chain does not remove data already present in that volume. Cleanup is limited to documented Phase 191 Fake processor namespaces and related rows. Ordinary showcase records remain, and the Phase 243 custody check passed.

## Task Commits

1. **Task 1: Search trigger, groups and truthful async state** - `f7597559` (test), `68e17e02` (feat)
2. **Task 2: Single active pointer and keyboard result in actual browser** - `663378ec` (test), `a4c00f5c` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/components/global_search.ex` and `accrue_admin/assets/css/app.css` - compact search layout, async state messaging, and hidden spinner precedence.
- `accrue_admin/assets/js/hooks/command_palette.js` - one active result across pointer, keyboard, ARIA, and Enter.
- `examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex` and `examples/accrue_host/lib/accrue_host_web/router.ex` - authenticated held-out states mounted only in the SQL Sandbox test host.
- `examples/accrue_host/e2e/phase246-global-search.spec.js` and `examples/accrue_host/playwright.phase246.config.js` - ordinary and held-out browser journeys.
- `examples/accrue_host/priv/repo/seeds/ordinary.exs` - narrowly allowlisted local fixture normalization and documented operator password reconciliation.
- `examples/accrue_host/test/ordinary_preview_seed_test.exs` - rerun, coherent relation, and allowlisted fixture cleanup regression checks.
- `.planning/phases/246-collection-controls-and-search/captures/phase246-global-search/` - new Phase 246 screenshots and evidence manifest; Phase 245 captures were not overwritten.

## Decisions Made

- Kept the existing async generation and owner checks as the authority for results; no search predicate, package, production fixture picker, or ordinary test data was added.
- Used the separate authenticated Ecto Sandbox route for exceptional states and the guarded ordinary Fake preview for realistic search.
- Used only explicit Phase 191 host and e2e fixture prefixes plus their linked rows for ordinary fixture normalization. The regression test verifies normal showcase data survives repeated seed runs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed compact-dialog overflow and selection paint conflict**
- **Found during:** Task 2 rendered browser review
- **Issue:** The dialog could exceed the narrow viewport by a few pixels, and hover could visually compete with the keyboard-selected result.
- **Fix:** Constrained dialog width to its container and made hover transient while the active result owns selected paint.
- **Files modified:** `accrue_admin/assets/css/app.css`
- **Verification:** Held-out 320px viewport checked computed dialog/page width and pointer-to-keyboard-to-Enter behavior; Node and mounted browser checks passed.
- **Committed in:** `a4c00f5c`

**2. [Rule 1 - Bug] Reconciled stale Phase 191 Fake stress data in the ordinary preview**
- **Found during:** Task 2 ordinary preview capture
- **Issue:** The Phase 245 ordinary persistent volume contained 28 namespaced Phase 191 customers even though startup seed aggregation was disabled; a narrower query would have hidden the polluted dataset.
- **Fix:** Added cleanup only for documented Phase 191 Fake processor IDs and dependent rows within `ordinary.exs`, which already refuses execution unless the actual Repo identity, Compose project, Fake processor, and Phase 243 custody guards match. The test seeds Phase 191 fixtures, reruns ordinary seeds twice, and checks the rows are gone while ordinary billing relations remain coherent.
- **Files modified:** `examples/accrue_host/priv/repo/seeds/ordinary.exs`, `examples/accrue_host/test/ordinary_preview_seed_test.exs`
- **Verification:** 5 ordinary seed tests pass; guarded wrapper reports Phase 243 snapshot preserved; active ordinary DB has zero queried Phase 191 rows and retains `cus_fake_00001` and `in_seed_healthy_portal_launch_paid`.
- **Committed in:** `a4c00f5c`

**3. [Rule 3 - Blocking issue] Restored the documented local preview operator password**
- **Found during:** Task 2 ordinary browser authentication
- **Issue:** Startup hydration could leave the existing local Fake operator with an older credential, preventing the documented preview login.
- **Fix:** Ordinary seed reconciliation updates only `admin@example.com` to the documented demo password. A regression test proves the stale password fails and the documented password succeeds. The password was read only into a temporary shell variable for the authorized local browser run and was not printed.
- **Files modified:** `examples/accrue_host/priv/repo/seeds/ordinary.exs`, `examples/accrue_host/test/ordinary_preview_seed_test.exs`
- **Verification:** Seed test passes and the authenticated ordinary browser journey passes.
- **Committed in:** `a4c00f5c`

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 3)
**Impact on plan:** These local Fake preview repairs were required to preserve the planned realistic ordinary-data invariant and authenticate its read-only browser journey. They do not change production accounts or protected Phase 243 data.

## Verification

- TDD RED/GREEN: Task 1 failing component assertions committed as `f7597559`, then implementation committed as `68e17e02`; Task 2 failing active-result assertions committed as `663378ec`, then implementation committed as `a4c00f5c`.
- `node --test test/js/command_palette_test.mjs` - 11 passed.
- `MIX_ENV=test mix test test/accrue_admin/components/global_search_test.exs` - 20 passed.
- `MIX_ENV=test mix test test/ordinary_preview_seed_test.exs` - 5 passed.
- `npm_config_cache=/tmp/accrue246-npm-cache MIX_ENV=test mix accrue_admin.assets.build` - passed; default npm cache was not writable, so the existing build was rerun with a temporary cache.
- Ordinary mounted browser journey against `http://accrue-host-phase245-ordinary.localhost/` - 1 passed with broad `example.com` search, computed active paint/ARIA/Enter alignment, and a refreshed screenshot.
- Isolated `@phase246-heldout` mounted browser journey on the `accrue_host_test` sandbox lane - 1 passed at 320px with truthful spinner, partial retention/retry, and zero/one/many/long identity states.
- `MIX_ENV=test mix compile --warnings-as-errors` in `examples/accrue_host` - passed earlier in this plan run.
- `git diff --check` - passed before task commit.

## Issues Encountered

- The initial broad ordinary query correctly returned ordinary operator records rather than the narrower expected organization name; the browser assertion was aligned to the actual ordinary result while retaining the broad query and explicit Phase 191 exclusion.
- The default npm cache contained inaccessible root-owned files. The asset build passed with a task-local cache under `/tmp`.
- Port 4101 was occupied by a lingering test server; the held-out browser check ran on clean isolated port 4102 and passed against the test database.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

SEARCH-01 implementation and browser evidence are ready for Phase 246 Plan 04 cross-surface verification. The current ordinary preview contains its expected realistic records and no allowlisted Phase 191 stress fixtures. Plan completion does not claim the overall phase is complete.

## Self-Check: PASSED

- Summary file exists at the required plan path.
- Task commits `f7597559`, `68e17e02`, `663378ec`, and `a4c00f5c` are ancestors of the current plan head.
- Measured plan commit count is 4 from `cec36eb8de11ebac5ad14c66669aa863d09ac677` through `a4c00f5c8485de88206eab2823015a845a53ff28`.

---
*Phase: 246-collection-controls-and-search*
*Completed: 2026-10-11*
