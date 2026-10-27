---
phase: 253-real-groups-and-a-whole-subscription-job
plan: "01"
subsystem: ui
tags: [subscriptions, PhoenixStorybook, LiveView, DataTable, ExUnit, Playwright]

requires:
  - phase: 252-production-backed-subscription-stories
    provides: production subscription query, owner scope, and stateful DataTable
provides:
  - Shared production-owned subscription collection renderer
  - Compiled Storybook 1.2 mounted collection story and direct variation route
  - Source-verified composition manifest and browser proof
affects: [253-02, 253-04, 253-05, 253-06, subscription-story-coverage]

actuals:
  tokens: 12340
  tasks: 2
  commits: 4
commits: 4
plan_head_before: ff8fa6f63c3df73cbb52ca0af202ba5d651d0428
plan_head_after: bb298f44ef35630f7424be259e63eed80ba9efa8

tech-stack:
  added: []
  patterns:
    - Production visual composition is shared while route scope and query ownership remain in the routed LiveView.
    - Storybook mounts the real stateful DataTable through the compiled PhoenixStorybook 1.2 LiveComponent transport.
    - Generated composition evidence is reconciled against compiled identity and source digests.

key-files:
  created:
    - accrue_admin/storybook/_support/subscription_collection.ex
    - storybook/groups/subscriptions_collection.story.exs
    - accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs
    - accrue_admin/storybook/_support/subscription_compositions_manifest.ex
    - accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs
    - accrue_admin/e2e/subscription-compositions-phase253.spec.js
  modified:
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/playwright.phase252.config.js
    - guides/subscription-story-coverage.md
    - .gitignore

key-decisions:
  - "Keep production query, owner scope, filter patches, and route lifecycle in SubscriptionsLive; share only the rendered collection composition."
  - "Use PhoenixStorybook 1.2's connected LiveComponent story transport to mount the actual DataTable and preserve its child event target."
  - "Keep the existing truthful Amount unavailable display because the production list has a processor price ID but no numeric price source."

requirements-completed: [SBK-04, UXQ-03]

coverage:
  - id: D1
    description: The production route and directly reachable compiled Storybook variation render the shared collection with the real stateful DataTable.
    requirement: SBK-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs#the compiled one-row story mounts the connected production DataTable
        status: pass
      - kind: integration
        ref: /billing/dev/storybook/groups/subscriptions_collection?variation_id=one_row
        status: pass
    human_judgment: false
  - id: D2
    description: The production route ignores a query-module override and returns only the persisted subscription in the current owner scope, excluding the same-email row from another organization.
    requirement: SBK-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs#production route uses the scoped Subscriptions query despite query-module input
        status: pass
    human_judgment: false
  - id: D3
    description: Compiled story identity, current transport provenance, and source digests are verified; duplicate, missing, empty, and stale inputs fail closed.
    requirement: UXQ-03
    verification:
      - kind: integration
        ref: MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs (4 tests, 0 failures)
        status: pass
    human_judgment: false
  - id: D4
    description: A direct browser visit renders the real collection heading, filters, customer identity link, subscription state, existing amount semantics, and DataTable child target.
    requirement: UXQ-03
    verification:
      - kind: e2e
        ref: node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js (1 test passed)
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-27
status: complete
---

# Phase 253 Plan 01: One Real Collection Through Mounted Storybook 1.2 Summary

**One production-owned subscription collection now renders through both the routed LiveView and a compiled, directly reachable Storybook 1.2 story with the real stateful DataTable.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-10-27T16:53:03Z
- **Completed:** 2026-10-27T17:18:14Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Extracted the PageHeader, filter toolbar, flash, results, and DataTable composition into a shared renderer while retaining production route, query, filter, and current-owner scope in `SubscriptionsLive`.
- Proved the compiled Storybook variation mounts a connected `PhoenixStorybook 1.2.0` LiveComponent and the actual DataTable child. The ExUnit proof starts with exactly one row and loads the next row through the child's event target.
- Verified production data with two persisted rows sharing an email across organizations. A route query-module override did not replace the production query, and only the current owner's row appeared.
- Added a compiled composition manifest with current source digests and fail-closed identity controls, a direct Playwright DOM check, and a guide entry documenting the production boundary and proof limits.
- Recorded the real list's current price presentation as **Amount unavailable**: the row has a processor price ID, but the production list does not provide a numeric price. No amount was inferred.

## Executed Verification

- `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- bash -c 'cd accrue_admin && mix test test/accrue_admin/dev/subscription_collection_transport_test.exs test/accrue_admin/live/subscriptions_live_test.exs'` — **17 tests, 0 failures**. Includes exact initial row count, child load-more behavior, production query override negative control, and owner-scope exclusion.
- `MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs` from `accrue_admin` — **4 tests, 0 failures**. Verified current manifest/source digests, transport provenance, and duplicate/missing/empty/stale negative controls; `TestRepo` remained stopped.
- `node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js` — **1 browser test passed** against the direct Storybook route and rendered DOM.
- `node --check e2e/subscription-compositions-phase253.spec.js`, `node --check playwright.phase252.config.js`, `mix format` on changed Elixir files, and `git diff --check` passed.

## Task Commits

Each task was committed atomically, including its test-first RED evidence:

1. **Task 1: Prove one real collection through production and mounted Storybook 1.2** — `0580615b0` (test), `284487de5` (feat).
2. **Task 2: Open the compiled collection variation and reconcile its real render** — `260eecfd5` (test), `bb298f44e` (feat).

**Plan metadata:** `ff8fa6f63c3df73cbb52ca0af202ba5d651d0428` was the measured plan base; `bb298f44ef35630f7424be259e63eed80ba9efa8` was the measured task-completion HEAD. Four task commits were counted from the persisted plan ledger.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` — shared production collection composition with the routed query and scope fixed.
- `accrue_admin/storybook/_support/subscription_collection.ex` — dev/test-only connected story component and deterministic facts from validated launch/team data.
- `storybook/groups/subscriptions_collection.story.exs` — compiled `:live_component` story and `one_row` variation.
- `accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs` — compiled route, connected DataTable, pagination, and production scope proof.
- `accrue_admin/storybook/_support/subscription_compositions_manifest.ex` — compiled story identity, route, transport, and source-digest validation.
- `accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs` — manifest success and negative-control coverage.
- `accrue_admin/e2e/subscription-compositions-phase253.spec.js` — direct rendered browser assertion.
- `accrue_admin/playwright.phase252.config.js` — admits the Phase 253 spec while preserving existing matches.
- `guides/subscription-story-coverage.md` — mounted transport, production boundary, and proof-limit notes.
- `.gitignore` — excludes only the current-run Phase 253 transport and manifest JSON outputs.

## Decisions Made

- The shared seam is presentation-only. Production still owns `Subscriptions` query selection, owner scoping, route params, and filter updates.
- The actual DataTable is mounted through the supported compiled LiveComponent story, preserving its own event target and lifecycle.
- The one-row story uses validated launch/team facts. Its deterministic adapter is limited to the dev/test story path.
- The list continues to show its existing unavailable-amount state until a real numeric price source exists.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Ignore generated current-run JSON evidence**
- **Found during:** Task 1
- **Issue:** The lab produces transport and manifest JSON as disposable current-run evidence, which should remain local and would otherwise appear as untracked runtime output.
- **Fix:** Added ignore rules for only `accrue_admin/tmp/phase253/transport.json` and `accrue_admin/tmp/phase253/manifest.json`; the compiled tests still generate and consume them during execution.
- **Files modified:** `.gitignore`
- **Verification:** Both artifacts were generated and consumed in the successful lab runs; `git check-ignore` confirms they remain local.
- **Committed in:** `284487de5`.

**2. [Rule 3 - Blocking issue] Start the minimal dependency required by the no-start manifest check**
- **Found during:** Task 2
- **Issue:** The no-start manifest test needs the existing `:localize` app for current Money validation while must not start the test repository.
- **Fix:** The test starts only `:localize` and asserts `TestRepo` remains stopped.
- **Files modified:** `accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs`
- **Verification:** The manifest command passed with four tests and confirmed `TestRepo` was not started.
- **Committed in:** `bb298f44e`.

**Total deviations:** 2 auto-fixed (Rule 3: 2). **Impact:** Both changes keep disposable evidence and existing validation boundaries working; no dependency or production authority changed.

## Issues Encountered

- The lab wrapper starts child commands at the repository root, so the ExUnit command needed an explicit `cd accrue_admin` inside the disposable lane.
- The environment blocked the lab's process check with `EPERM` without escalation. Re-running the same lab operation with the authorized execution context completed successfully.
- In the browser viewport, the DataTable eagerly requested the next page. The browser assertion checks the real rendered row and numeric child target; the mounted ExUnit test separately proves an exact one-row initial state followed by the explicit load-more action.
- Pre-existing application/test warnings appeared, including the deprecated ExMoney auto-start behavior and unavailable Storybook test assets. They did not cause failures and were outside this plan's changed scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 253-02 can build on the shared production collection, compiled mounted story, and verified direct browser route. This plan establishes composition and transport coverage; it does not claim numeric price persistence or provider completion. Requirements `SBK-04` and `UXQ-03` remain shared with sibling plans and were therefore not marked complete in `REQUIREMENTS.md` yet.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All four task commits are ancestors of the current plan-completion HEAD.

---
*Phase: 253-real-groups-and-a-whole-subscription-job*
*Completed: 2026-10-27*
