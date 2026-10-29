---
phase: 252-production-backed-subscription-stories
plan: "07"
subsystem: testing
tags: [elixir, mix, hex, production-packaging, storybook]
requires:
  - phase: 252-production-backed-subscription-stories
    provides: [subscription scenario fixtures and adapters, isolated lab tooling, rendered UI coverage]
provides:
  - Production route, compile-root, dependency, and canonical-host boundary assertions
  - Node-free isolated production compiles and actual unpacked Hex package checks for all three apps
  - Fail-closed package, fixture-import, Storybook dependency, and Node-path controls
affects: [252-08, production package boundaries]
actuals:
  tokens: 11497
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 0457aa92698eceda56777a01e10bd30333ec1bc0
plan_head_after: 35c1fc14c8d8857b305a300e835de1d7b8edb6b8
tech-stack:
  added: []
  patterns: [isolated MIX_ENV=prod outputs, Node-free build PATH, actual Hex archive inspection]
key-files:
  created:
    - accrue/config/prod.exs
    - accrue_admin/test/accrue_admin/dev/subscription_production_boundary_test.exs
    - scripts/ci/verify_phase252_production_boundary.mjs
    - scripts/ci/verify_phase252_production_boundary.test.mjs
  modified:
    - accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs
    - .planning/phases/252-production-backed-subscription-stories/252-07-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-07-02-red-evidence.json
key-decisions:
  - "Use the existing admin and portal Hex release switches only when building package metadata; compile from the local sibling dependency."
  - "Canonicalize the temporary directory before Mix builds so dependency links resolve correctly on macOS."
patterns-established:
  - "Production boundary checks inspect unpacked package files and compiled application metadata, not only allowlists."
  - "Keep committed Storybook CSS and JavaScript as inert assets while excluding scenario fixtures, adapters, and runner payloads."
requirements-completed: [LAB-02]
coverage:
  - id: D1
    description: "Dev tooling and kitchen remain visible while production routes, compile roots, dependencies, and canonical mounts retain their production boundary."
    requirement: LAB-02
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/dev/subscription_production_boundary_test.exs; guarded admin test lane: 25 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs; dev Storybook and kitchen assets/routes asserted"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fresh production builds and actual package contents are checked for accrue, accrue_admin, and accrue_portal without Node/npm on the compile PATH."
    requirement: LAB-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_phase252_production_boundary.mjs; PASS accrue (360 files), accrue_admin (146), accrue_portal (32)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Known package, fixture-import, PhoenixStorybook, and Node-path leaks fail the same verifier while a clean package with inert Storybook assets passes."
    requirement: LAB-02
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase252_production_boundary.test.mjs; 5 tests, 5 passed"
        status: pass
      - kind: unit
        ref: "node scripts/ci/verify_phase252_production_boundary.mjs --self-test; 8 controls passed"
        status: pass
    human_judgment: false
duration: 35min
completed: 2026-10-26
status: complete
human_judgment: false
---

# Phase 252 Plan 07: Production Compile, Package, and Route Boundaries Summary

**All three applications compile in isolated production outputs and pass inspection of their real unpacked Hex packages, with Storybook fixtures and Node tooling outside the production boundary.**

## Performance

- **Duration:** 35 minutes
- **Started:** 2026-10-27T02:34:54Z
- **Completed:** 2026-10-27T03:09:51Z
- **Tasks:** 2
- **Files modified by plan tasks:** 7

## Accomplishments

- Added positive dev/kitchen and negative production route, compile-root, dependency-scope, and canonical-host assertions.
- Added a shell-free verifier that compiles each app with `MIX_ENV=prod`, a unique temporary `MIX_BUILD_PATH`, and a PATH with no Node/npm executables, then builds and inspects the actual unpacked Hex package.
- Verified production package contents: `accrue` 360 files, `accrue_admin` 146 files, and `accrue_portal` 32 files. The clean control explicitly permits the existing inert Storybook CSS/JavaScript assets.
- Added fail-closed controls for leaked scenario manifests, production fixture imports, PhoenixStorybook production dependencies, and Node executables on the build PATH.

## Verification

- `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_production_boundary_test.exs` — 5 tests passed without loading the shared database test helper.
- `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- sh -c 'cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/dev/storybook_asset_test.exs test/accrue_admin/dev/subscription_production_boundary_test.exs test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs'` — 25 tests, 0 failures, using the guarded disposable admin test database.
- `node --test --test-reporter=tap scripts/ci/verify_phase252_production_boundary.test.mjs` — 5 tests passed.
- `node scripts/ci/verify_phase252_production_boundary.mjs --self-test` — 8 controls passed.
- `node scripts/ci/verify_phase252_production_boundary.mjs` — all three fresh production compiles and actual Hex archive inspections passed.

## Task Commits

1. **Task 1: Assert tooling absence with a known-present dev control** — `3cb436b0` (`test`).
2. **Task 2 RED: Add production package leak controls** — `f432bdd2` (`test`).
3. **Task 2 GREEN: Verify fresh production package boundaries** — `35c1fc14` (`feat`).

## Files Created/Modified

- `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs` — positive dev/kitchen and production route assertions.
- `accrue_admin/test/accrue_admin/dev/subscription_production_boundary_test.exs` — package configuration, route, source ownership, and canonical mount contracts.
- `scripts/ci/verify_phase252_production_boundary.mjs` — isolated production compile, actual Hex package inspection, and self-test controls.
- `scripts/ci/verify_phase252_production_boundary.test.mjs` — known leak and clean package controls.
- `accrue/config/prod.exs` — production environment config imported by the core app.
- `.planning/phases/252-production-backed-subscription-stories/252-07-01-red-evidence.json` — honest characterization evidence for Task 1.
- `.planning/phases/252-production-backed-subscription-stories/252-07-02-red-evidence.json` — valid Task 2 RED evidence from a private temporary mirror.

## Decisions Made

- Use the already documented `ACCRUE_ADMIN_HEX_RELEASE=1` and `ACCRUE_PORTAL_HEX_RELEASE=1` switches only for Hex package metadata generation; production compile checks use the local sibling dependency.
- Resolve the operating system's temporary directory to its canonical path before creating Mix output, avoiding broken dependency links through macOS's `/var` alias.
- Leave the existing Storybook CSS and JavaScript in the package as inert static assets; exclude fixture data, adapters, manifests, and browser runners.

## TDD Gate Compliance

- **Task 1:** The planned assertions characterize behaviors already present in the baseline routes and package configuration. The initial suite was green, and `gsd_run check tdd-red-evidence` classified it as `unexpected_green`; this is recorded in `252-07-01-red-evidence.json`. No failing result was invented. The required tests were then run successfully.
- **Task 2:** The committed baseline produced valid RED evidence: all five controls failed, including the intended leaked-manifest assertion. The implementation then passed all five tests, all eight self-test controls, and the full three-package production compile/archive check.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Added the missing core production config imported by `config/config.exs`**
- **Found during:** Task 2 production compile.
- **Issue:** `accrue/config/config.exs` imports `config/prod.exs`, but the file did not exist, preventing any real `MIX_ENV=prod` compile of the core package.
- **Fix:** Added the minimal production setting `config :accrue, :env, :prod`, matching the production environment ownership used by the companion applications.
- **Files modified:** `accrue/config/prod.exs`.
- **Verification:** The fresh core production compile and actual package inspection passed.
- **Committed in:** `35c1fc14`.

**Total deviations:** 1 auto-fixed (Rule 3).
**Impact on plan:** The missing config was required for the planned production evidence; no package dependency or boundary was changed.

## Issues Encountered

- Hex rejected the admin and portal's local sibling dependency during package creation. Their existing release switches select the intended Hex dependency metadata; using those switches allowed actual package creation without installing or publishing anything.
- The default macOS temporary path is exposed through `/var`, while the filesystem resolves it through `/private/var`; Mix dependency links were invalid through that alias. Canonicalizing the temporary root fixed the isolated builds.
- The production build output lives directly under `MIX_BUILD_PATH/lib`, not `MIX_BUILD_PATH/prod/lib`; the verifier now checks the actual compiled application path.

## User Setup Required

None — no external service configuration or dependency install was required.

## Next Phase Readiness

The compile, package, and route boundaries are ready for Phase 252 Plan 08's CI admission and generated automated acceptance evidence. `EDGE-LAB-02-unclassified` remains an unresolved broad assumption; this plan covers the concrete package and route behaviors through actual artifacts and route assertions without claiming that the assumption itself is resolved. Phase 252 remains in progress.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `3cb436b0`, `f432bdd2`, and `35c1fc14` are ancestors of the current plan head.
- Actual test and production package outputs match the verification claims above.

---
*Phase: 252-production-backed-subscription-stories*
*Completed: 2026-10-26*
