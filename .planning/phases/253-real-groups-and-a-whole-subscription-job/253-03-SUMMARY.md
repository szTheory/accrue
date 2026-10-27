---
phase: 253-real-groups-and-a-whole-subscription-job
plan: "03"
subsystem: ui
tags: [subscriptions, PhoenixLiveView, PhoenixStorybook, ExUnit, static-scenarios]

requires:
  - phase: 253-01
    provides: Shared production collection renderer, compiled Storybook tree, and composition manifest
  - phase: 253-02
    provides: Current collection story states and isolated iframe transport
provides:
  - Shared whole subscription page renderer owned by SubscriptionLive
  - Compiled page story with three canonical scenarios and six review/result snapshots
  - Page-level manifest entries and source digests with fail-closed identity checks
affects: [253-04, 253-05, 253-06, subscription-story-coverage]

actuals:
  tokens: 13236.25
  tasks: 2
  commits: 4
commits: 4
plan_head_before: f602ee113c22175b2b287811ba0cc7a1e56947ac
plan_head_after: 3c710cce648ad8e259bb0089eaa1eb03dd936016

tech-stack:
  added: []
  patterns:
    - Routed production and static page stories call the same complete LiveView renderer.
    - Static action snapshots reuse production copy and scoped evidence links without dispatching provider actions.
    - Compiled page-story identities are validated independently from the existing one-row collection transport proof.

key-files:
  created:
    - .planning/phases/253-real-groups-and-a-whole-subscription-job/253-03-01-red-evidence.json
    - .planning/phases/253-real-groups-and-a-whole-subscription-job/253-03-02-red-evidence.json
    - accrue_admin/storybook/_support/subscription_page_scenarios.ex
    - accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs
    - storybook/pages/subscription.story.exs
  modified:
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/storybook/_support/subscription_compositions_manifest.ex
    - accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs

key-decisions:
  - Keep route scope, authorization, lazy reads, and action handlers in the routed SubscriptionLive owner.
  - Build static page snapshots from validated Cadence domain facts and production-owned copy and scoped links.
  - Keep the collection manifest's transport evidence focused on its unique one-row component while validating page variations separately.

patterns-established:
  - Whole-page Storybook variations use explicit attribution and route through the production LiveView page renderer.
  - Review and result snapshots describe presentation state only and never claim a provider mutation occurred.

requirements-completed: [SBK-05, UXQ-03]

coverage:
  - id: D1
    description: The routed detail and active page story render byte-identical whole-page content through SubscriptionLive.subscription_page/1.
    requirement: SBK-05
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs#the active page variation is byte-identical to the production renderer and preserves its whole composition
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs (40 tests, 0 failures)
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical active, scheduled-cancellation, and incomplete-evidence pages retain real scenario identity, scoped links, source order, and unavailable projections; related/item counts and lazy states follow production rendering.
    requirement: SBK-05
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs (6 tests, 0 failures; TestRepo remained stopped)
        status: pass
    human_judgment: false
  - id: D3
    description: Review, step-up, dispatching, confirmed, pending, and failed snapshots use production confirmation/result copy, disabled in-flight confirmation, polite status semantics, and scoped evidence links.
    requirement: UXQ-03
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs#review, step-up, dispatch and results retain production copy and safe status semantics
        status: pass
    human_judgment: false
  - id: D4
    description: The compiled page leaf exposes exactly nine supported variation IDs with direct paths and current source digests; malformed, missing, duplicate, empty, and omitted inputs fail closed.
    requirement: UXQ-03
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs (6 tests, 0 failures)
        status: pass
    human_judgment: false
  - id: D5
    description: The existing subscription area story and Phase 252 canonical coverage retain their production renderer parity.
    requirement: SBK-05
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs (5 tests, 0 failures)
        status: pass
    human_judgment: false

assumptions:
  - id: EDGE-SBK-05-unclassified
    status: unresolved
    reason: The probe taxonomy did not classify SBK-05. This plan verifies its explicit page assertions without relabeling that assumption as runtime-satisfied.

metrics:
  duration: 23min
  completed_date: 2026-10-27
status: complete
---

# Phase 253 Plan 03: One Production-Sharing Subscription Page Summary

**The routed subscription detail and a nine-variation Storybook page now share one complete production renderer, with static review and result states that preserve scoped evidence and truthful status.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-10-27T18:02:18Z
- **Completed:** 2026-10-27T18:23:53Z
- **Tasks:** 2
- **Files modified:** 6 source and test files, plus 2 RED-evidence records

## Accomplishments

- Extracted the existing whole-page markup into `SubscriptionLive.subscription_page/1`; `render/1` delegates to it, so the routed page retains its owner scope, event handlers, loading behavior, and action authority.
- Added a DB-free scenario adapter and compiled page story for active, scheduled-cancellation, incomplete-evidence, review, step-up, dispatching, confirmed, pending, and failed presentation states.
- Extended the Phase 253 manifest with compiled page identities and source digests while keeping the collection proof focused on the existing one-row transport.
- Asserted full-page parity and order, real scenario facts, zero/one/many item and related-resource rendering, lazy activity/JSON states, safe result copy, and unchanged subscription area coverage.

## Executed Verification

- Task 1 RED evidence: the target assertion failed because `SubscriptionLive.subscription_page/1` did not yet exist; evidence was classified `RED_EVIDENCE_OK`.
- Task 1 focused page suite: 3 tests passed; no `TestRepo` was started.
- Task 1 mounted route suite: `subscription_live_test.exs` passed with 40 tests and 0 failures.
- Task 2 RED evidence: the target assertion failed on the missing review/result snapshot IDs while the canonical page checks passed; evidence was classified `RED_EVIDENCE_OK`.
- Final page slice: 6 tests passed, 0 failures, using TAP output accepted by the installed RED-evidence classifier.
- Final manifest slice: 6 tests passed, 0 failures, including source digest, direct-route, stale-source, malformed, missing, duplicate, empty, and omitted variation controls.
- Preserved area story slice: 5 tests passed, 0 failures.
- Repeated mounted route suite after extraction: 40 tests passed, 0 failures.
- `mix format --check-formatted` passed for all changed Elixir source, test, and Storybook files; `git diff --check` passed.
- All DB-backed verification ran serially through `scripts/dev/phase252_lab.mjs` in disposable admin-test lanes. The wrapper's `ps` call required the authorized escalated execution context.

## Task Commits

Each TDD task has its RED and implementation commits:

1. **253-03-01: Inspect the complete active subscription through one production page renderer** — `6275ab58e` (test), `602b3e298` (feat).
2. **253-03-02: Inspect incomplete detail and supported review/result evidence without invented facts** — `2ad83b1dd` (test), `3c710cce6` (feat).

The measured task-commit range starts at `f602ee113c22175b2b287811ba0cc7a1e56947ac`, ends at `3c710cce648ad8e259bb0089eaa1eb03dd936016`, and contains 4 commits. The realized diff was 52,945 characters (13,236.25 tokens on the plan's chars/4 scale).

## Files Created and Modified

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — shared page renderer and production-owned result-copy helpers.
- `accrue_admin/storybook/_support/subscription_page_scenarios.ex` — validated, DB-free page facts and supported presentation snapshots.
- `storybook/pages/subscription.story.exs` — compiled whole-page Storybook leaf.
- `accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs` — whole-page, lazy-state, cardinality, and result semantics assertions.
- `accrue_admin/storybook/_support/subscription_compositions_manifest.ex` — page variation discovery, direct paths, source digests, and retained one-row collection provenance.
- `accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs` — positive and negative manifest controls.
- `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-03-01-red-evidence.json` and `253-03-02-red-evidence.json` — executable RED records.

## Decisions Made

- Route scope, authorization, event handlers, and lazy data loading remain owned by the routed `SubscriptionLive`; only page composition is shared.
- Static snapshots use validated Cadence scenario structs, production confirmation/result copy, and scoped links. They do not dispatch actions or claim provider completion.
- The static activity input is intentionally empty because Cadence scenario facts contain no event-history source; the assertions cover both unloaded and settled renderer behavior without inventing event records.
- The collection manifest continues to prove its unique one-row connected component. New collection states remain covered by their own collection tests, and page story entries are recorded in a separate projection.
- `EDGE-SBK-05-unclassified` stays unresolved in acceptance metadata; these explicit page checks do not classify or dismiss the probe result.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept canonical page checks scoped to the canonical trio after adding snapshots**
- **Found during:** Task 2
- **Issue:** The canonical-page test enumerated every story variation after the review/result snapshots were added, so its expected three-ID list no longer matched the full nine-ID story.
- **Fix:** The canonical fact assertions now select the first three declared canonical variations, while the separate snapshot assertion checks the full list.
- **Files modified:** `accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs`
- **Verification:** The final page slice passed all 6 tests.
- **Committed in:** `3c710cce6`.

**2. [Rule 3 - Blocking issue] Reconciled the manifest with the current collection variation and iframe transport**
- **Found during:** Task 2
- **Issue:** The compiled collection story now declares settled state variations and an iframe component route, while the prior manifest expected every variation to carry only launch/team attribution and compared transport evidence to the outer story route.
- **Fix:** The existing collection projection validates its unique `one_row` declaration and current inner iframe transport while preserving the outer direct route. Page variations are separately validated and included in the source digest inventory. Malformed page attribution now fails with the manifest's explicit rejection message.
- **Files modified:** `accrue_admin/storybook/_support/subscription_compositions_manifest.ex`, `accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs`
- **Verification:** The final manifest slice passed all 6 tests; the old area story slice passed all 5 tests.
- **Committed in:** `3c710cce6`.

**Total deviations:** 2 auto-fixed (Rule 1: 1, Rule 3: 1). **Impact:** Both changes preserve the existing collection proof while making the new page manifest verifiable against the current compiled story. No dependency or production authority changes were introduced.

## Issues Encountered

- The disposable lab wrapper starts commands at the repository root, so Mix invocations were scoped to `accrue_admin`.
- The lab process-check command returned `EPERM` without elevation; rerunning the same commands in the authorized execution context succeeded. No shared database was reset.
- The default TAP formatter hid one assertion detail during local diagnosis. A diagnostic run used ExUnit's standard formatter; recorded RED evidence continued to use the supported TAP reporter.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plan 253-04 can compare mounted action authority and effect behavior against the shared page's static review/result snapshots. Plan 253-05 can evaluate responsive rendering of the same production composition. The open `EDGE-SBK-05-unclassified` assumption remains separate from this plan's passing automated coverage.

## Self-Check: PASSED

- The summary file exists at the expected phase path.
- All four task commits are ancestors of the current plan-completion HEAD.

---
*Phase: 253-real-groups-and-a-whole-subscription-job*
*Completed: 2026-10-27*
