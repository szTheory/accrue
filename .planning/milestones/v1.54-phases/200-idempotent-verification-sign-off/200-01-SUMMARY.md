---
phase: 200-idempotent-verification-sign-off
plan: "01"
subsystem: admin-storybook
tags:
  - storybook
  - component-registry
  - theme-parity
  - dev-routes
status: complete
requirements_completed:
  - STY-02
  - STY-03
dependencies:
  requires:
    - ComponentRegistry.entries/0
    - ComponentRegistry.group_contracts/0
    - committed storybook.css/storybook.js bundles
  provides:
    - Registry-driven Storybook component coverage
    - Registry-driven Storybook group coverage
    - Storybook color-mode dark-shim parity tests
    - Dev-only Storybook committed-asset route proof
  affects:
    - accrue_admin Storybook dev surface
    - /billing/dev/components drift-test surface
tech_stack:
  added: []
  patterns:
    - PhoenixStorybook page stories
    - ComponentRegistry single source of truth
    - ExUnit request/source boundary tests
key_files:
  created:
    - storybook/components/component_registry.story.exs
    - storybook/groups/component_groups.story.exs
    - accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs
    - accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/dev/storybook.ex
    - accrue_admin/storybook/_support/registry_story.ex
    - accrue_admin/test/accrue_admin/theme_test.exs
    - accrue_admin/lib/accrue_admin/router.ex
key_decisions:
  - Keep ComponentRegistry as the single source of truth for generated Storybook metadata through RegistryStory helpers.
  - Serve Storybook committed CSS/JS from dev-only /dev/storybook asset routes because the backend config uses absolute Storybook asset paths.
metrics:
  duration_seconds: 849
  completed_at: "2026-06-30T16:01:33Z"
  tasks_completed: 3
  files_created: 4
  files_modified: 4
---

# Phase 200 Plan 01: Storybook Coverage and Theme Parity Summary

Registry-driven PhoenixStorybook coverage with committed-bundle color-mode parity and dev-only asset boundary proof.

## What Changed

- Enabled PhoenixStorybook color mode while preserving the `ax-theme-dark-shim` bridge and added dark-token parity coverage against committed `storybook.css`.
- Expanded `AccrueAdmin.Storybook.RegistryStory` so Storybook variation IDs, DOM IDs, component coverage rows, and group coverage rows are derived from `ComponentRegistry`.
- Added aggregate Storybook pages for component families and component groups, with coverage metadata sourced dynamically instead of copied counts.
- Added Storybook asset tests proving committed CSS/JS bundles serve from the configured `/dev/storybook` paths and remain omitted from prod-like routers and host mounts.

## Tasks Completed

| Task | Result | Commits |
| ---- | ------ | ------- |
| Task 1: Extend Storybook backend and registry support | Color mode enabled, registry support expanded, dark-shim parity tests added | `e1075cbd`, `9c42ff5e` |
| Task 2: Add dynamic component and group story coverage | Component and group aggregate Storybook pages added with dynamic coverage tests | `2010a65d`, `defcb589` |
| Task 3: Prove Storybook assets and adopter leak boundaries | Asset route/body tests added; dev-only committed asset routes implemented | `8b46ee0c`, `0ff3e224` |

## Verification

| Command | Result |
| ------- | ------ |
| `cd accrue_admin && mix test test/accrue_admin/theme_test.exs test/accrue_admin/dev/component_registry_test.exs --max-failures 5` | Passed: 18 tests, 0 failures |
| `cd accrue_admin && mix test test/accrue_admin/dev/storybook_coverage_test.exs test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs --max-failures 5` | Passed: 19 tests, 0 failures |
| `cd accrue_admin && mix test test/accrue_admin/dev/storybook_asset_test.exs --max-failures 5` | Passed: 4 tests, 0 failures |
| `cd examples/accrue_host && MIX_ENV=prod mix compile --warnings-as-errors` | Passed |

## TDD Gate Compliance

- RED commit present for Task 1: `e1075cbd`
- GREEN commit present for Task 1: `9c42ff5e`
- RED commit present for Task 2: `2010a65d`
- GREEN commit present for Task 2: `defcb589`
- RED commit present for Task 3: `8b46ee0c`
- GREEN commit present for Task 3: `0ff3e224`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added Storybook committed asset routes**
- **Found during:** Task 3 GREEN
- **Issue:** The Storybook backend configured absolute `/dev/storybook/assets/storybook-*` paths, but the router only mounted PhoenixStorybook under the admin mount path and did not serve those committed bundle URLs.
- **Fix:** Added dev-only `/dev/storybook/assets/storybook-css-*` and `/dev/storybook/assets/storybook-js-*` routes inside the existing `Code.ensure_loaded?(PhoenixStorybook.Router)` and `allow_live_reload` Storybook guard.
- **Files modified:** `accrue_admin/lib/accrue_admin/router.ex`
- **Commit:** `0ff3e224`

## Threat Notes

No unplanned trust boundary was introduced. The new Storybook asset routes are under the plan's `/dev/storybook` routing boundary and are gated by `allow_live_reload` plus `Code.ensure_loaded?(PhoenixStorybook.Router)`. The asset test also asserts prod-like routers and the example host source do not expose `/dev/storybook`.

## Known Stubs

None. Stub-pattern scan found only expected test/helper literals, not UI placeholder data or unwired Storybook content.

## Auth Gates

None.

## Deferred Issues

None.

## Self-Check: PASSED

- Verified all created/modified files listed in the summary exist.
- Verified all task commits are reachable: `e1075cbd`, `9c42ff5e`, `2010a65d`, `defcb589`, `8b46ee0c`, `0ff3e224`.
