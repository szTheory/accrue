---
phase: 239-integrated-quality-handoff
plan: 02
subsystem: testing
tags: [phoenix, plug, assets, csp, sri, copy-export, ci]
requires:
  - phase: 239-01
    provides: Phase 239 integration baseline and route smoke contracts
provides:
  - Exact mounted-response checks for Admin fonts and Portal package/runtime assets
  - Full generated Admin copy export parity against the checked-in browser fixture
  - Source/build/served evidence with local and checked-in CI results distinguished
affects: [239-04, admin-assets, portal-assets, copy-export]
actuals:
  tokens: 2332
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: ["Mounted asset tests compare actual router responses with package source bytes", "Generated exports compare in a unique OS temporary path and clean up on test exit"]
key-files:
  created: [.planning/phases/239-integrated-quality-handoff/239-SERVED-PARITY.md]
  modified: [accrue_admin/test/accrue_admin/assets_test.exs, accrue_admin/test/accrue_admin/copy_test.exs, accrue_portal/test/accrue_portal/csp_plug_test.exs]
key-decisions:
  - "Add served-response tests only for the Portal assets and Admin fonts that lacked byte-level mounted evidence."
  - "Keep CSP nonce/origin and checkout SRI as separate existing contracts."
  - "Compare the complete copy export through the existing task without writing to the checked-in fixture."
patterns-established:
  - "Package resource parity: request the mounted route and compare response bytes to the owning package file."
  - "Generated fixture parity: export to a unique temporary path and register cleanup before assertions."
requirements-completed: [SHIP-01]
coverage:
  - id: D1
    description: Admin fonts and Portal package/runtime assets are checked as exact mounted responses; existing Admin CSS/JS, CSP, and SRI contracts remain independently represented.
    requirement: SHIP-01
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/assets_test.exs (4 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "cd accrue_portal && mix test test/accrue_portal/csp_plug_test.exs test/accrue_portal/live/checkout_live_test.exs (19 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: Complete generated copy export matches the checked-in JSON fixture using a temporary output path.
    requirement: SHIP-01
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test test/accrue_admin/copy_test.exs --warnings-as-errors (14 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-10-09
status: complete
plan_head_before: ef8752b957174f11a4c8e8d56f2ab39c62527e4a
plan_head_after: d6b3ae491c98158159bce1b6aa51200c6df22c51
---

# Phase 239 Plan 02: Served Asset and Export Parity Summary

**Mounted Admin/Portal resources and the complete generated copy export now have byte-exact local contracts inside the existing package test gates.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-10-09T11:35:19Z (approximate)
- **Completed:** 2026-10-09T11:39:19Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added mounted response checks for Admin Geist fonts and Portal brand, CSS, JS, Phoenix JS, and LiveView JS, comparing served bytes to package files.
- Added a full JSON export parity test that writes to a unique temporary path and removes it through ExUnit cleanup.
- Recorded source/build/served ownership and distinguished local results from the checked-in CI workflow in [239-SERVED-PARITY.md](./239-SERVED-PARITY.md).
- Kept Portal CSP nonce/origin assertions and checkout SRI assertions independent from static content hashes.

## Task Commits

1. **Task 1: Reconcile package asset, font, mount, CSP, and SRI contracts** - `6587d151` (test)
2. **Task 2: Prove copy export parity without changing authored exports** - `d6b3ae49` (test)

## Files Created/Modified

- `.planning/phases/239-integrated-quality-handoff/239-SERVED-PARITY.md` - source-to-served matrix and evidence provenance.
- `accrue_admin/test/accrue_admin/assets_test.exs` - exact mounted font response assertions.
- `accrue_admin/test/accrue_admin/copy_test.exs` - complete export byte equality contract.
- `accrue_portal/test/accrue_portal/csp_plug_test.exs` - mounted Portal static response contract alongside distinct CSP coverage.

## Decisions Made

- Filled the concrete response-evidence gaps found during inspection: Portal route registration did not establish actual response bytes, and Admin font routes had no exact-response assertions.
- Kept the fixed Braintree CSP origins/nonce and pinned checkout SRI values as separate security contracts.
- Preserved the checked-in generated copy fixture as read-only; generated output exists only under the OS temporary directory during the test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added missing Portal asset and Admin font served-response checks**
- **Found during:** Task 1
- **Issue:** Existing evidence covered Admin CSS/JS responses and Portal route declarations, but did not compare mounted Portal responses or Admin font responses to their source bytes.
- **Fix:** Added focused router-response assertions for the five Portal resources and both Admin font resources.
- **Files modified:** `accrue_admin/test/accrue_admin/assets_test.exs`, `accrue_portal/test/accrue_portal/csp_plug_test.exs`
- **Verification:** Admin asset suite 4/4 passed; Portal CSP/SRI and asset suites 19/19 passed.
- **Committed in:** `6587d151`

The first Admin font run showed Plug appends `charset=utf-8` to the `font/woff2` MIME value; the assertion was aligned with the observed response and the suite then passed.

**Total deviations:** 1 auto-added coverage gap (Rule 2), plus observed header expectation correction. **Impact on plan:** Closed the explicit source-to-served evidence gap without adding a workflow job or changing runtime behavior.

## Issues Encountered

- The initial GSD staging attempt could not create `.git/index.lock` under the workspace filesystem restriction. Both scoped GSD task commits succeeded with elevated filesystem access; no unrelated files were staged.
- No temporary `accrue-copy-strings-*.json` file remained after the successful copy test.
- Remote CI was not observed; the workflow definitions are documented as source evidence only.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- SHIP-01 resource and copy parity is locally executable and included in the existing Admin/Portal package test jobs.
- Plan 239-04 can consume the source-to-served evidence report and task commits.

## Self-Check: PASSED

- Served parity report and all three modified test files exist.
- Task commits `6587d151` and `d6b3ae49` are ancestors of current HEAD.
- `gsd_run check evaluation-scope --plan 239-02 --commits-only --raw` resolved the plan and found both scoped commits with no unreachable or missing commit evidence.
- Acceptance criteria rechecked: mounted Admin/Portal response tests passed; CSP and SRI remained independent; complete temporary export comparison passed; no temporary copy output remained; Admin and Portal formatter checks passed.
- Stub/TODO scan found no placeholder implementations in the plan's changed files.
- No new network, auth, filesystem trust-boundary, or schema surface was introduced beyond the bounded temporary test output.

---
*Phase: 239-integrated-quality-handoff*
*Completed: 2026-10-09*
