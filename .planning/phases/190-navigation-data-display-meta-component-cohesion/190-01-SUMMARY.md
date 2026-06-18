---
phase: 190-navigation-data-display-meta-component-cohesion
plan: 01
subsystem: ui
tags: [phoenix-liveview, component-registry, playwright, exunit, admin-ui]

requires:
  - phase: 187-audit-baseline
    provides: Phase 187 component-group names, slug grammar, state taxonomy, and owner-phase defects
  - phase: 189-primitive-form-components-component-lab
    provides: ComponentRegistry and /billing/dev/components registry-as-SSOT pattern
provides:
  - Canonical Phase 190 group contracts for the eight Phase 187 component groups
  - Wave 0 ExUnit coverage for group slugs, states, proof IDs, and Phase 191 handoff tags
  - Source-level Playwright group-contract harness and human-readable contract ledger
affects: [phase-190, phase-191, component-kitchen, admin-e2e, group-contracts]

tech-stack:
  added: []
  patterns:
    - Dev-only ComponentRegistry group contracts parallel to the existing Phase 189 component entries
    - Source-level Playwright scaffold that validates planning-ledger coverage before DOM probes exist

key-files:
  created:
    - accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs
    - accrue_admin/e2e/admin-group-contracts.spec.js
    - .planning/phases/190-navigation-data-display-meta-component-cohesion/190-GROUP-CONTRACTS.md
  modified:
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
    - accrue_admin/test/accrue_admin/dev/component_registry_test.exs

key-decisions:
  - "Use AccrueAdmin.Dev.ComponentRegistry.group_contracts/0 as the canonical Wave 0 group contract source."
  - "Keep the Playwright Wave 0 harness source-level only until later plans render data-component-group DOM specimens."
  - "Record Phase 191 handoff tags in contracts and the ledger without implementing focus, Escape, click-outside, fixture, or microcopy behavior in Wave 0."

patterns-established:
  - "Group contracts: name, slug, proof_id, required_states, primary_components, locators, behavior_contracts, hierarchy, route category, and Phase 191 handoff tags."
  - "Static group slugs stay lowercase letters/numbers/hyphens and exclude runtime billing identifiers."

requirements-completed: [GRP-01, GRP-02, GRP-03, GRP-04]

duration: 7 min
completed: 2026-06-18
status: complete
---

# Phase 190 Plan 01: Group Contract Source and Validation Scaffold Summary

**Canonical group-contract registry and Wave 0 validation scaffold for Phase 190 navigation, data-display, and meta-component cohesion.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-18T15:14:31Z
- **Completed:** 2026-06-18T15:21:37Z
- **Tasks:** 3 completed
- **Files modified:** 5

## Accomplishments

- Added `ComponentRegistry.group_contracts/0`, `component_group_slugs/0`, and `group_contract_by_slug/1` for the eight frozen Phase 187 component groups.
- Added Wave 0 ExUnit coverage for exact slugs, required operator-stress state ownership, proof IDs, static slug safety, and Phase 191 handoff tags.
- Added `admin-group-contracts.spec.js` plus `190-GROUP-CONTRACTS.md` so later browser-probe plans can reuse stable helper names and contract data.

## Task Commits

1. **Task 1 RED: Add failing group registry contract test** - `40f25569` (test)
2. **Task 1 GREEN: Add canonical group contracts** - `bfb80854` (feat)
3. **Task 2: Add Wave 0 group registry coverage** - `8c0dbe54` (test)
4. **Task 3: Add Playwright harness scaffold and group contract ledger** - `1c3e1759` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` - Adds canonical group contracts and slug lookup helpers without changing the existing `entries/0` schema.
- `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` - Adds the TDD RED contract test for group APIs and static slugs.
- `accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs` - Adds Wave 0 group registry contract tests.
- `accrue_admin/e2e/admin-group-contracts.spec.js` - Adds source-level Playwright ledger checks and reusable helper names.
- `.planning/phases/190-navigation-data-display-meta-component-cohesion/190-GROUP-CONTRACTS.md` - Documents group contracts, states, proof IDs, decision coverage, and Phase 191 handoff tags.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs` - PASS, 13 tests, 0 failures.
- `cd accrue_admin && node --check e2e/admin-group-contracts.spec.js && npm run e2e -- e2e/admin-group-contracts.spec.js --project=chromium-desktop` - PASS, 1 Playwright test passed.

## Decisions Made

- `ComponentRegistry` remains the dev-only SSOT for group contracts, matching the existing Phase 189 registry pattern.
- The group-contract Playwright file intentionally performs source-level ledger checks only; DOM visibility probes wait for later Phase 190 plans that render the group specimens.
- Overlay, focus, dismissal, fixture, and microcopy concerns are recorded as Phase 191 handoff tags rather than implemented in this Wave 0 scaffold.

## Deviations from Plan

None - plan executed as written. The extra `component_registry_test.exs` edit is the required TDD RED gate for Task 1.

## Issues Encountered

- ExUnit startup logged transient Postgrex `too_many_connections` messages in the local environment, but the targeted tests completed successfully with 0 failures. No code change was needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `190-02-PLAN.md`: later kitchen and browser-probe work can consume `ComponentRegistry.group_contracts/0`, `component_group_slugs/0`, `190-GROUP-CONTRACTS.md`, and the helper names in `admin-group-contracts.spec.js`.

## Self-Check: PASSED

- Found expected summary file.
- Found created Wave 0 group registry test.
- Found created Playwright group contract scaffold.
- Found created group contract ledger.
- Verified task commits exist: `40f25569`, `bfb80854`, `8c0dbe54`, `1c3e1759`.

---
*Phase: 190-navigation-data-display-meta-component-cohesion*
*Completed: 2026-06-18*
