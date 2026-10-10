---
phase: 241-billing-operator-journeys
plan: "04"
subsystem: billing-ui
tags: [phoenix-liveview, recovery, campaign-timeline, scoped-navigation]

requires:
  - phase: 240
    provides: Recovery dashboard, campaign detail, and current owner scope
  - phase: 241-02
    provides: Validated local return destinations and supported Recovery window decoding
provides:
  - Campaign detail breadcrumb and explicit return use the same scoped Recovery destination
  - Recovery campaign links preserve only supported selected windows and rebuild the current owner
affects: [241-07]

actuals:
  tokens: 2404.25
  tasks: 2
  commits: 2
commits: 2
plan_head_before: fe3af3a98ac6e80b8a438c5970595ea4e6df2865
plan_head_after: 908840f8ee3638b825e03748b8cbd263409ad65d

tech-stack:
  added: []
  patterns:
    - Use the current owner and the validated route meaning to rebuild campaign return links.
    - Keep Recovery window selection distinct from the unfiltered historical campaign timeline.

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
    - accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
    - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs

key-decisions:
  - "Campaign detail accepts only a validated Recovery origin; direct, blank, invalid, unrelated, foreign-mount, and hostile origins return to current-scope Recovery."
  - "Campaign history remains complete when the originating Recovery page selected a shorter reporting window."

requirements-completed: [JRN-03]

coverage:
  - id: D1
    description: Campaign detail uses matching breadcrumb and explicit Recovery returns, with direct and unsafe origins falling back under the current owner.
    requirement: JRN-03
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs#direct and untrusted origins return through both Recovery links in current scope
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs#D-20 D-21 renders Campaign as a detail drill-down with summary rows and primary timeline
        status: pass
    human_judgment: false
  - id: D2
    description: Recovery preserves the supported 7d, 30d, and 90d selection through campaign details while historical campaign events remain unfiltered.
    requirement: JRN-03
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs#campaign round trips preserve each supported window and current owner
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs#invalid Recovery window falls back to the existing 30 day selection
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs#selected Recovery window does not filter the historical campaign timeline
        status: pass
    human_judgment: false

duration: 5 min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 04: Recovery and Campaign Return Journeys Summary

**Campaign details now return to scoped Recovery through a matching breadcrumb and explicit link, preserving supported windows without filtering historical campaign evidence.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-10T01:38:00Z
- **Completed:** 2026-10-10T01:42:40Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Campaign detail now derives its Recovery breadcrumb and explicit return from one validated destination, with scoped Recovery as the safe fallback for direct and unsupported origins.
- Recovery campaign links carry the selected 7d, 30d, or 90d window and current owner; invalid windows retain the existing 30 day default.
- Tests keep historical campaign timeline evidence distinct from the selected Recovery reporting window and preserve the separate subscription detail target.

## Task Commits

1. **Task 1: Return direct campaign entry to Recovery** - `8f04683f` (feat)
2. **Task 2: Preserve supported Recovery windows through campaign detail** - `908840f8` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` - Builds one validated Recovery return destination and handles absent or blank origins safely.
- `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs` - Covers direct and hostile origins, the separate subscription target, and complete historical timelines.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` - Reads the Recovery window explicitly from route params before querying scoped observations.
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` - Covers 7d/30d/90d round trips, owner rebuilding, and the invalid-window default.

## Decisions Made

- Only a validated Recovery origin is accepted for the campaign breadcrumb and explicit return; other supported local routes are not campaign return destinations.
- The validated Recovery window describes the originating dashboard query. It does not narrow the campaign's historical event timeline.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Avoided passing a blank campaign origin into route validation**
- **Found during:** Task 1 verification
- **Issue:** An empty `return_to` reached `ScopedPath` and its customer-route matcher called `String.starts_with?/2` with a nil parsed path, crashing the LiveView.
- **Fix:** CampaignLive now sends missing or blank origins directly to its scoped Recovery fallback; regression coverage includes blank input.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex`, `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs`
- **Verification:** Campaign LiveView suite passed (11 tests, 0 failures).
- **Commit:** `8f04683f`

## Verification

- `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/analytics/campaign_live_test.exs` — 11 tests, 0 failures.
- `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs` — 41 tests, 0 failures.
- `mix format --check-formatted` for the four changed source and test files — passed.
- `git diff --check` for the plan changes — passed.

## Deferred Phase Evidence

Plan 241-07 owns the combined mounted browser and served-asset evidence. JRN-03 remains shared with that plan at the phase level until its owner completes.

## Self-Check: PASSED

- Both production task commits are ancestors of HEAD; plan evaluation scope resolved both commits.
- All four modified files exist and have focused integration coverage recorded above.
- No stubs, skipped tests, or new trust boundaries were introduced.
