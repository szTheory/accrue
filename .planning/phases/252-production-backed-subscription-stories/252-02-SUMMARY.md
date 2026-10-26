---
phase: 252-production-backed-subscription-stories
plan: "02"
subsystem: ui
tags: [phoenix-liveview, phoenixstorybook, subscriptions, cadence, tdd]

requires: [252-01]
provides:
  - Deterministic launch/team and lifecycle subscription facts validated into real domain structs without Repo access.
  - Active, scheduled-cancellation, and incomplete-evidence stories rendered through the shared production subscription area.
affects: [252-04, 252-06, 252-07, 253]

actuals:
  tokens: 12490.75
  tasks: 2
  commits: 6

tech-stack:
  added: []
  patterns:
    - Plain deterministic scenario facts validated through domain changesets, money, and provider capability owners.
    - Self-starting DB-free ExUnit scripts with local TAP reporters and restored Fake clock state.
    - Canonical Storybook variations delegate to shared production area rendering.

key-files:
  created:
    - accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs
    - .planning/phases/252-production-backed-subscription-stories/252-02-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-02-02-red-evidence.json
  modified:
    - dev_support/ui_scenarios/cadence_subscriptions.exs
    - accrue_admin/storybook/_support/subscription_scenarios.ex
    - storybook/components/subscription_detail.story.exs
    - accrue_admin/test/accrue_admin/components/subscription_area_test.exs
    - accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs

key-decisions:
  - "EDGE-SCEN-01-unclassified remains unresolved in the probe; this plan proves deterministic fetch, adapter consumption, and DB-free/package separation without deciding that assumption."
  - "Incomplete historical projections remain valid facts and render production-owned unavailable values and ordered evidence caveats."

requirements-completed: [SCEN-01, SCEN-02, SBK-03]

coverage:
  - id: D1
    description: "Launch and growing-team facts are deterministic, DB-free, use explicit actor/billed identities and fixed time, and validate through real domain rules including invalid controls and exact money boundaries."
    requirement: SCEN-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs#test launch and growing-team facts share a deterministic DB-free Cadence source"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs#test canceling boundary follows the canonical predicate at, before, and after fixed time"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs#test money controls accept exact zero and large minor units and reject invalid amounts or currencies"
        status: pass
    human_judgment: false
  - id: D2
    description: "Active, scheduled_cancellation, and incomplete_evidence are stable canonical variations routed through the same production owner while compatibility IDs remain available."
    requirement: SCEN-02
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs#test all canonical lifecycle variations delegate to the shared production area"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs#test canonical lifecycle variation IDs sit beside preserved compatibility IDs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Production rendering preserves scheduled cancellation eligibility and timestamp behavior, incomplete evidence caveat order and unavailable values, optional caveats, and provider-pruned empty groups."
    requirement: SBK-03
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#test scheduled cancellation renders its effective timestamp and only eligible renewal actions"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#test incomplete evidence preserves status and exact production caveat order"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#test optional caveats cover zero, one, and many missing projections without an empty subscription"
        status: pass
    human_judgment: false

commits: 6
plan_head_before: 6b164e9d74cdd7293101aafc2eafe8a5f5687380
plan_head_after: 0f3db24573b2df39a6dd58018f7dd8d82f433cb9
human_judgment: false
duration: 16min
completed: 2026-10-26
status: complete
---

# Phase 252 Plan 02: Production-backed Subscription Stories Summary

**Deterministic Cadence facts now drive three truthful subscription lifecycle stories through the shared production area, with domain-checked inputs and DB-free controls.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-10-26T23:08:08Z
- **Completed:** 2026-10-26T23:24:06Z
- **Tasks:** 2
- **Plan files changed:** 8, excluding this summary and execution state

## Accomplishments

- Added deterministic launch/team and lifecycle facts with explicit actors, billed entities, provider support, stable identities, a fixed clock, and a separately held-out long-text case.
- Validated facts using real billing changesets, ownership/provider invariants, `Money.new/2`, provider capabilities, and chronology rules. Tests cover malformed relations and enums, unsupported providers, exact zero and large minor units, invalid money, and cancellation boundaries.
- Added `scheduled_cancellation` and `incomplete_evidence` variations alongside `active`; all use the existing narrow adapter and production-owned area. Assertions preserve eligibility, effective-time fallback, unavailable values, ordered caveats, and optional projection behavior.
- Preserved compatibility IDs and confirmed the plain facts source has no Admin, Storybook, or Repo dependency.

## Task Commits

1. **252-02-01: Reuse launch/team facts and reject impossible realistic inputs** — `6ed9f4ec` (RED), `ee17e2b3` (implementation), `a0cd5892` (DB-free source-boundary refinement).
2. **252-02-02: Inspect scheduled cancellation and incomplete evidence through the same area** — `fb197b62` (RED), `5f62d2cc` (implementation); `0f3db245` avoids reloading compiled scenario modules in standalone tests.

Measured task commits: 6, from `6b164e9d74cdd7293101aafc2eafe8a5f5687380` through `0f3db24573b2df39a6dd58018f7dd8d82f433cb9`.

## Verification and TDD Evidence

- Both RED evidence records passed `gsd_run check tdd-red-evidence` classification and identify the intended missing behavior.
- DB-free scripts passed: scenario controls (12 tests), subscription area (9 tests), and story slice (4 tests), for 25 passing tests total. Commands were run with `MIX_ENV=test mix run --no-start`; no Repo or shared test helper was started.
- `git diff --check` passed. `gsd_run check evaluation-scope --plan 252-02 --commits-only --raw` returned `status: resolved` and recognized all six commits.
- All coverage entries are automated and `human_judgment: false`. No visual judgment or provider/persistence behavior is claimed by these static story checks.

## Decisions Made

- `EDGE-SCEN-01-unclassified` remains unresolved in the probe. This plan tests determinism, adapter consumption, and DB-free/package boundaries; follow-up plans retain their assigned investigation.
- Missing historical projection facts are accepted where the domain permits them and rendered with production-owned unavailable values and caveats.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made standalone money tests initialize the installed Localize application**
- **Found during:** Task 1.
- **Issue:** The required `--no-start` script invokes `Money.new/2`, which relies on the already-present Localize application configuration.
- **Fix:** Start the installed application in the self-contained test setup and restore the Fake clock after every case; no dependency was installed and no Repo was started.
- **Files modified:** `accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs`, `accrue_admin/test/accrue_admin/components/subscription_area_test.exs`, `accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs`.
- **Verification:** All three standalone test commands passed.
- **Commits:** `6ed9f4ec`, `ee17e2b3`, `fb197b62`, `5f62d2cc`.

**Total deviations:** 1 auto-fixed blocking issue (Rule 3). No outstanding issues.

## User Setup Required

None. Plan 252-06 owns the separate visual review of its twelve-cell case; this plan's evidence is automated rendering and domain validation only.

## Self-Check: PASSED

- Summary and all eight plan output files exist.
- All six measured task commits are ancestors of the plan head recorded above.
