---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: 10
subsystem: testing
tags:
  - phoenix
  - liveview
  - playwright
  - fixtures
  - overlay
  - focus
  - scroll-lock
dependency_graph:
  requires:
    - Phase 199 browser contract
    - Phase 199 fixture helper baseline
    - 199-09 affordance and theme persistence completion
  provides:
    - deterministic Phase 199 interaction fixture matrix
    - shared route focus, scroll, and stale-overlay helper assertions
    - '@fixture Playwright route-flow stress coverage'
    - overlay focus fallback hardening for staged action teardown
  affects:
    - phase-199
    - phase-200
    - accrue_admin-e2e
    - overlay
    - fixtures
tech_stack:
  added: []
  patterns:
    - deterministic E2E fixture aliases
    - route-flow step tables
    - marker-preferred drawer primary-action fallback
    - settled overlay and focus assertions
key_files:
  created:
    - .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-10-SUMMARY.md
  modified:
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/support/e2e_plug.ex
    - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
    - accrue_admin/e2e/phase191-page-flow-helpers.js
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - accrue_admin/assets/js/hooks/focus_trap.js
    - accrue_admin/assets/js/hooks/overlay.js
    - accrue_admin/priv/static/accrue_admin.js
key_decisions:
  - '199-10: Phase 199 fixture browser checks use a single phase199-interaction-matrix seed with compatibility aliases for existing Phase 199 targets.'
  - '199-10: Overlay and focus assertions wait for settled LiveView cleanup before declaring route transitions clean.'
  - '199-10: Staged drawer primary actions are handled as a first-class browser flow shape.'
  - '199-10: Overlay focus teardown falls back to the stable main region when the prior focus target is hidden or removed.'
requirements_completed:
  - FIX-01
  - FIX-02
  - IXN-01
  - IXN-02
  - IXN-03
metrics:
  started_at: 2026-06-30T03:30:35Z
  completed_at: 2026-06-30T04:40:05Z
  duration: 69m30s
  tasks_completed: 3
  implementation_files_changed: 8
status: complete
---

# Phase 199 Plan 10: Fixture Route-Flow Stress Summary

Deterministic Phase 199 fixture matrix with five browser route-flow stress paths and hardened overlay focus cleanup.

## What Changed

Implemented a deterministic `phase199-interaction-matrix` E2E fixture seed covering the route-level data shapes needed for interaction overlay stress: long customer and email values, zero-decimal JPY invoices and charges, refunds, webhook raw payloads, audit/recovery records, and Connect attention states. The seed is available through both direct and forwarded E2E plug routes.

Extracted shared Playwright helpers for route focus, scroll-lock cleanup, stale overlay detection, and body-focus regression checks. The Phase 199 fixture browser spec now composes these helpers across five route flows: customer record sets, invoice staged actions, webhook replay, recovery subscription navigation, and Connect platform-fee actions.

Hardened overlay teardown in the admin UI hooks. Focus restoration now avoids hidden or removed prior targets and falls back to the main content region when staged overlay teardown would otherwise leave focus on `document.body`.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Extend deterministic edge fixtures | bd6f5d20 | `e2e_fixtures.ex`, `e2e_plug.ex` |
| 2 | Add focus, scroll, clipping helpers | 9513d3e4 | `phase191-page-flow-helpers.js`, `admin-interaction-overlay-phase199.spec.js` |
| 3 | Green composed route-flow and edge-layout checks | 690854b8 | `admin-interaction-overlay-phase199.spec.js`, helpers, E2E plug/tests, overlay hooks, static JS |

## Verification

| Command | Result |
| ------- | ------ |
| `cd accrue_admin && mix test test/accrue_admin/e2e_fixtures_test.exs --max-failures 5` | Passed: 16 tests, 0 failures |
| `cd accrue_admin && node --check assets/js/hooks/focus_trap.js && node --check assets/js/hooks/overlay.js && node --check e2e/phase191-page-flow-helpers.js && node --check e2e/admin-interaction-overlay-phase199.spec.js` | Passed |
| `cd accrue_admin && npm run e2e:phase199 -- --grep @fixture` | Passed: 1 passed, 1 skipped |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added forwarded unprefixed Phase 199 seed routes**
- **Found during:** Task 3
- **Issue:** The browser seed request for `/__e2e__/seed/phase199-interaction-matrix` returned 404 because `TestEndpoint` forwards `/__e2e__` to `AccrueAdmin.E2E.Plug` and strips the prefix. The new seed routes only existed in prefixed form.
- **Fix:** Added forwarded `/seed/phase199-interactions` and `/seed/phase199-interaction-matrix` handlers and a plug test that exercises the forwarded route shape.
- **Files modified:** `accrue_admin/test/support/e2e_plug.ex`, `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs`
- **Commit:** 690854b8

**2. [Rule 1 - Bug] Made focus and stale-overlay assertions wait for LiveView async cleanup**
- **Found during:** Task 3
- **Issue:** Immediate helper assertions could sample focus or overlay state before LiveView teardown settled, producing false failures while route transitions were still applying patches.
- **Fix:** Updated `assertNoBodyFocus` and `assertNoStaleOverlayState` to wait for settled focus and overlay cleanup state before failing.
- **Files modified:** `accrue_admin/e2e/phase191-page-flow-helpers.js`
- **Commit:** 690854b8

**3. [Rule 1 - Bug] Restored focus after staged overlay teardown**
- **Found during:** Task 3
- **Issue:** Staged invoice and Connect drawer step-up cleanup could leave focus on `document.body` when the previous focus target was connected but hidden or removed.
- **Fix:** Updated `focus_trap.js` to restore only visible focusable targets or fall back to `#main-content, main`; updated `overlay.js` to schedule the same final page-focus fallback after the last overlay shell is removed; rebuilt `priv/static/accrue_admin.js`.
- **Files modified:** `accrue_admin/assets/js/hooks/focus_trap.js`, `accrue_admin/assets/js/hooks/overlay.js`, `accrue_admin/priv/static/accrue_admin.js`
- **Commit:** 690854b8

**4. [Rule 2 - Missing Critical] Added staged drawer primary-action support in the fixture flow**
- **Found during:** Task 3
- **Issue:** The invoice route flow uses a two-stage drawer action before step-up confirmation, unlike direct webhook and Connect modal flows.
- **Fix:** Added route-flow handling for marker-preferred primary actions, staged confirm panels, fallback primary actions, and explicit close/cancel cleanup.
- **Files modified:** `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`
- **Commit:** 690854b8

## Known Stubs

None. The stub scan found only helper defaults, local empty arrays for assertion bookkeeping, focus timer nulls, and historical test text; no user-facing placeholder or unwired data source was introduced.

## Threat Flags

None. The new network surface is test-only E2E seed routing under `AccrueAdmin.E2E.Plug`; no production endpoint, schema, auth path, or trust boundary was added.

## Auth Gates

None.

## Deferred Issues

None.

## Self-Check: PASSED

- Confirmed all implementation files exist.
- Confirmed task commits `bd6f5d20`, `9513d3e4`, and `690854b8` exist in git history.
- Confirmed verification commands passed before summary creation.

