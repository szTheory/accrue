---
phase: 252-production-backed-subscription-stories
plan: "01"
subsystem: ui
tags: [phoenix-liveview, phoenixstorybook, subscriptions, accessibility, tdd]

requires: []
provides:
  - A deterministic, DB-free Cadence subscription scenario validated into real billing structs and rendered by the production-owned subscription area.
  - Exact accessible names for contextual plan and renewal summary actions, with generic summary actions retaining their existing labels.
affects: [252-02, 252-05, 252-06, 253]

actuals:
  tokens: 12036
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - Standalone DB-free ExUnit scripts with local TAP formatters for deterministic validation.
    - Static Storybook variations delegate to validated production-owned LiveView presentation.
    - Contextual action names use the complete aria-label while duplicate hidden context is removed from the accessibility tree.

key-files:
  created:
    - dev_support/ui_scenarios/cadence_subscriptions.exs
    - accrue_admin/storybook/_support/subscription_scenarios.ex
    - accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs
    - accrue_admin/test/accrue_admin/components/subscription_area_test.exs
    - .planning/phases/252-production-backed-subscription-stories/252-01-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-01-02-red-evidence.json
  modified:
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - storybook/components/subscription_detail.story.exs
    - accrue_admin/lib/accrue_admin/components/detail.ex

key-decisions:
  - "The actual declared Storybook variation and production LiveView delegate to one production-owned presentation function; static rendering does not imply mounted authorization, dispatch, provider success, or persistence."
  - "Copy.action_hidden_context supplies the full accessible action phrase; a shared aria-label exposes it once while the redundant hidden context is aria-hidden."

patterns-established:
  - "Scenario facts are deterministic plain data; the Storybook adapter validates and constructs real domain structs without Repo access."
  - "Tests exercise the declared variation function and compare its full output with the production area renderer."

requirements-completed: [SBK-02, SBK-03, SCEN-01]

coverage:
  - id: D1
    description: "The actual active story variation renders the production-owned subscription area with ordered facts, full identity, eligible actions, and matching scoped destinations without starting Repo."
    requirement: SBK-02
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs#test the declared active variation renders the production area from real facts without Repo"
        status: pass
    human_judgment: false
  - id: D2
    description: "Cadence scenario facts validate into real domain structs, and absent, malformed, or unknown inputs are rejected rather than rendered as empty records."
    requirement: SCEN-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs#test absent, malformed, or unrecognized story input is rejected"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs#test the declared active variation renders the production area from real facts without Repo"
        status: pass
    human_judgment: false
  - id: D3
    description: "Plan and renewal link/button actions expose the complete Copy-generated accessible name exactly once while retaining visible labels and existing targets and values."
    requirement: SBK-03
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#test summary action links and buttons expose the complete context exactly once"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#test a generic summary action without context keeps its visible accessible name"
        status: pass
    human_judgment: false
  - id: D4
    description: "The production area retains its heading and facts semantics, action band, and full copied subscription identifier."
    requirement: SBK-03
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#test the production area retains the semantic hierarchy and full copied ID"
        status: pass
    human_judgment: false

commits: 4
plan_head_before: fe119a0577b7acfe9b39f88c7276db66a8e9e4c5
plan_head_after: b7a7acf8020edfa15ff3807b73f3f9504792320d
human_judgment: false

duration: 15min
completed: 2026-10-26
status: complete
---

# Phase 252 Plan 01: Production-backed Subscription Stories Summary

**A validated active Cadence scenario now renders through the same production subscription area as the LiveView, with exact contextual action names and DB-free contract tests.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-26T22:49:15Z
- **Completed:** 2026-10-26T23:04:00Z
- **Tasks:** 2
- **Files modified:** 9 plan files, excluding this summary and execution state

## Accomplishments

- Added deterministic Cadence subscription facts and a validating Storybook adapter that creates real Customer, Subscription, SubscriptionItem, and OwnerScope values without Repo access.
- Made `SubscriptionLive.subscription_area/1` the shared production renderer for the LiveView and the actual declared Storybook variation, preserving production facts, actions, scoped links, and flash/result placement.
- Updated contextual Detail actions so the accessible name is the full Copy phrase exactly once, and added standalone tests for the link, button, generic action, production semantics, and copied identifier.

## Task Commits

1. **252-01-01: Render one active fact set through the real production and story owner** — `8fe78b8c` (test), `e2bbe646` (feat).
2. **252-01-02: Preserve shared summary semantics and exact accessible names** — `8114be0d` (test), `b7a7acf8` (feat).

Plan task commits were measured from `fe119a0577b7acfe9b39f88c7276db66a8e9e4c5` to `b7a7acf8020edfa15ff3807b73f3f9504792320d`: 4 commits.

## Files Created/Modified

- `dev_support/ui_scenarios/cadence_subscriptions.exs` — deterministic facts, IDs, owner/actor metadata, and fixed clock inputs.
- `accrue_admin/storybook/_support/subscription_scenarios.ex` — validates scenario metadata and changesets, then creates real structs and scoped assigns without Repo.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — production-owned subscription area with the existing optional flash/action-result slot.
- `storybook/components/subscription_detail.story.exs` — active and compatibility variations delegate to the shared production area.
- `accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs` — actual variation-to-production equality, DB-free facts, and malformed-input tests.
- `accrue_admin/lib/accrue_admin/components/detail.ex` — complete contextual aria-label and hidden duplicate context handling.
- `accrue_admin/test/accrue_admin/components/subscription_area_test.exs` — contextual action names, generic action behavior, semantic hierarchy, and full copied ID.
- `.planning/phases/252-production-backed-subscription-stories/252-01-01-red-evidence.json` — classifier and semantic evidence for the active story RED.
- `.planning/phases/252-production-backed-subscription-stories/252-01-02-red-evidence.json` — classifier and semantic evidence for the action-name RED.

## Verification and TDD Evidence

- RED for task 1: `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` (expected nonzero test command exit 2). The active-variation assertion failed because the declared `:active` variation did not exist; Repo isolation had already passed.
- GREEN for task 1: `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_story_slice_test.exs` exited 0; 2 tests passed.
- RED for task 2: `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` (expected nonzero test command exit 2). The target action-name assertion failed because the `aria-label` was absent; the generic action and semantic/copy tests passed.
- GREEN for task 2: `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/components/subscription_area_test.exs` exited 0; 3 tests passed.
- `mix format --check-formatted` for changed Elixir files exited 0.
- `git diff --check` exited 0.
- `gsd_run check evaluation-scope --plan 252-01 --commits-only --raw` returned `status: resolved` and listed all four task commits.

## Decisions Made

- The review story remains a static rendering of production-owned presentation; it makes no claim about mounted authorization, dispatched actions, provider outcomes, or persistence.
- The active path and compatibility variation IDs all use the same validated facts adapter and presentation owner, without restoring story-local summary or action policy.
- `EDGE-SBK-03-unclassified` remains unresolved by design; this plan proves parity for one active case, while plan 252-06 is responsible for twelve independently identified rendered cases.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported HEEx fragment syntax with valid sibling roots**
- **Found during:** Task 1.
- **Issue:** The initial shared area markup used fragment syntax that HEEx does not compile.
- **Fix:** Rendered the existing area as valid sibling roots, preserving the established page grid and DOM order.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex`.
- **Verification:** Both DB-free scripts passed and the changed files passed formatter checks.
- **Committed in:** `e2bbe646`.

**2. [Rule 3 - Blocking] Added local TAP formatters to the standalone ExUnit scripts**
- **Found during:** Tasks 1 and 2 RED evidence capture.
- **Issue:** The canonical red-evidence classifier did not recognize ExUnit's default reporter output.
- **Fix:** Added small test-local TAP formatters so RED evidence could be classified without database bootstrap or changes to global test configuration.
- **Files modified:** `accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs`, `accrue_admin/test/accrue_admin/components/subscription_area_test.exs`.
- **Verification:** Both `gsd_run check tdd-red-evidence` checks returned `RED_EVIDENCE_OK`; both final test scripts passed.
- **Committed in:** `8fe78b8c` and `8114be0d`.

**Total deviations:** 2 auto-fixed blocking issues (Rule 3).
**Impact on plan:** Both adaptations were required to compile the shared view and produce valid DB-free TDD evidence. No external dependencies or global test configuration changes were introduced.

## Issues Encountered

No outstanding issues. The temporary HEEx compile failure and reporter-format incompatibility were resolved within the plan tasks.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

The production/story presentation seam and DB-free active facts are ready for plan 252-02 to expand lifecycle situations. Plans 252-05 and 252-06 still own variation discovery and the twelve-case width/theme rendering matrix. This plan does not complete Phase 252.

## Self-Check: PASSED

- Verified all nine plan files exist and are committed.
- Verified each of the four task commit hashes is an ancestor of `b7a7acf8020edfa15ff3807b73f3f9504792320d`.
- Verified the task commit ledger count is 4 and the recorded plan base/after SHAs match the persisted ledger and HEAD at summary creation.

---
*Phase: 252-production-backed-subscription-stories*
*Completed: 2026-10-26*
