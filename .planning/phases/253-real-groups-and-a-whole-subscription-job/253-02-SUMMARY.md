---
phase: 253-real-groups-and-a-whole-subscription-job
plan: "02"
subsystem: ui
tags: [subscriptions, PhoenixStorybook, LiveView, DataTable, pagination, ExUnit]

requires:
  - phase: 253-01
    provides: Shared production collection renderer and connected Storybook LiveComponent transport
provides:
  - Ten supported settled subscription collection variations, including loading, failure, and incomplete projections
  - Mounted production route assertions for scoped cursor pagination at 24, 25, and 26 rows
  - Regression coverage for page append, retry, row preservation, and truthful unavailable amounts
affects: [253-03, 253-04, 253-05, 253-06, subscription-story-coverage]

actuals:
  tokens: 7193
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 4a1e61bfe4537ec2036ebc177620ebc894c75ec4
plan_head_after: 3b9d647ea6c5998e4a76a41399a4f60df9891b4a

tech-stack:
  added: []
  patterns:
    - Each settled Storybook variation uses an isolated iframe while mounting the same connected LiveComponent and DataTable.
    - Real production route tests cover cursor boundaries, ordering, and owner scope with persisted subscriptions.

key-files:
  created:
    - .planning/phases/253-real-groups-and-a-whole-subscription-job/253-02-01-red-evidence.json
  modified:
    - accrue_admin/storybook/_support/subscription_collection.ex
    - storybook/groups/subscriptions_collection.story.exs
    - accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs

key-decisions:
  - Keep production Amount unavailable wherever the source provides only a processor price ID and no numeric amount.
  - Isolate each Storybook variation in its own iframe to avoid duplicate LiveView-generated DOM IDs while retaining the connected production DataTable.
  - Leave SubscriptionsLive production code unchanged because mounted route assertions confirmed the existing scope and cursor behavior.

metrics:
  duration: 33m
  completed_date: 2026-10-27

status: complete

coverage:
  - id: D1
    description: The compiled collection story represents the supported empty, populated, boundary, loading, unavailable, partial-error, and incomplete-projection states.
    requirement: SBK-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs
        status: pass
        evidence: Ten variation IDs are asserted through the connected Storybook transport, including truthful unavailable amounts.
    human_judgment: false
  - id: D2
    description: The mounted production route preserves owner scope and stable adjacent-page behavior around the default 25-row boundary.
    requirement: SBK-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
        status: pass
        evidence: Persisted 24-, 25-, and 26-row cases verify cursor availability, append order, unique rows, and exclusion of another owner's matching record.
    human_judgment: false
  - id: D3
    description: Failure recovery retains production copy and existing rows, with retry and child event targets owned by the DataTable.
    requirement: UXQ-03
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/components/data_table_test.exs
        status: pass
        evidence: Initial and partial cursor failures assert exact retry behavior, preserved rows, and the DataTable child target.
    human_judgment: false
---

# Phase 253 Plan 02: Real Groups and a Whole Subscription Job Summary

Ten compiled subscription collection states and production cursor tests now cover empty, loading, error, incomplete projection, and adjacent 24/25/26-row pages.

## Completed Tasks

1. Added the remaining settled collection story variations and transport assertions for empty, populated, page-boundary, loading, unavailable, partial-cursor-error, and incomplete-projection states.
2. Added mounted production route coverage for page boundaries, adjacent cursor pages, owner isolation, stable append order, retry behavior, and unavailable amount semantics.

## Verification

- TDD RED evidence: 4 ExUnit assertions, 3 passed and 1 expected failure for the missing variation IDs; the evidence file was classified `RED_EVIDENCE_OK`.
- Task 1 focused suite: `PHASE252_TAP_REPORT=1 mix test test/accrue_admin/dev/subscription_collection_transport_test.exs test/accrue_admin/components/data_table_test.exs` — 37 tests, 0 failures, 0 skipped.
- Task 2 focused suite: `PHASE252_TAP_REPORT=1 mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/components/data_table_test.exs` — 48 tests, 0 failures, 0 skipped. The focused 24/25/26-row boundary assertion also passed independently (1 test, 0 failures).
- Both suites ran serially through the disposable `scripts/dev/phase252_lab.mjs` test environment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Isolated Storybook variations after connected previews produced duplicate DOM IDs**
- **Found during:** Task 1
- **Issue:** Rendering ten connected previews in one Storybook parent view duplicated generated IDs from the DataTable, filters, and source-derived timestamp copy controls.
- **Fix:** Used PhoenixStorybook's per-variation iframe container so every preview retains the connected production LiveComponent and DataTable with isolated DOM IDs.
- **Files modified:** `storybook/groups/subscriptions_collection.story.exs`
- **Commit:** `3cc2aac13`

### Verification Environment Adjustment

The disposable lab wrapper encountered `ps` permission denial and starts at the repository root, which is not the Mix application directory. Tests were run serially through the wrapper with the command scoped to `accrue_admin`; no dependency or environment changes were made.

## Commits

- `a20881fbc` — `test(253-02): add failing assertions for collection states`
- `3cc2aac13` — `feat(253-02): add settled subscription collection states`
- `3b9d647ea` — `test(253-02): cover production cursor boundaries`

## Self-Check: PASSED

- Summary file exists at the expected phase path.
- All three task commits are ancestors of the current branch head.
- The persisted plan ledger measures 3 task commits and 28,774 diff characters across 6 files.
