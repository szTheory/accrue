---
phase: 198-propagate-detail-analytics
plan: "08"
subsystem: accrue_admin-ui
tags: [analytics, recovery, campaign, liveview, overview, detail]

# Dependency graph
requires:
  - phase: 198-03
    provides: "Phase 198 analytics contract tests and page grammar expectations"
  - phase: 194-exemplar-a-dashboard
    provides: "Locked overview browser verification patterns"
provides:
  - "Recovery overview root and section markers for hero, work queue, and supporting funnel"
  - "Recovery page order aligned to orientation/window selector, hero metrics, at-risk work queue, then funnel"
  - "Campaign detail drill-down with Detail.summary_card, Detail.summary_list, and CampaignTimeline"
  - "AtRiskTable documentation aligned to the Recovery work-queue role"
affects: [phase-198, phase-199, phase-200, analytics-ui, e2e-phase194]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static data-ax marker contracts for analytics grammar verification"
    - "Page-local LiveView helpers for detail summary facts"
    - "Existing Dunning analytics boundary retained for Campaign data"

key-files:
  created:
    - ".planning/phases/198-propagate-detail-analytics/198-08-SUMMARY.md"
  modified:
    - "accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex"
    - "accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex"
    - "accrue_admin/lib/accrue_admin/components/at_risk_table.ex"
    - "accrue_admin/e2e/admin-spec-overview-phase194.spec.js"

key-decisions:
  - "Recovery uses Recovery-specific data-ax markers instead of Dashboard data-ax-zone markers."
  - "Campaign facts stay page-local in CampaignLive and use existing Dunning analytics calls."
  - "AtRiskTable is documented as Recovery's work queue before the supporting funnel."

patterns-established:
  - "Recovery overview sections are identified by stable static markers: data-ax-recovery-hero, data-ax-recovery-work-queue, and data-ax-recovery-supporting-funnel."
  - "Campaign detail facts are derived in private LiveView helpers and rendered through Detail.summary_list without introducing AnalyticsPage."

requirements-completed: [PRP-02]

# Metrics
duration: 8m 23s
completed: 2026-06-29
status: complete
---

# Phase 198 Plan 08: Recovery and Campaign Analytics Grammar Summary

**Recovery now reads as a work-queue-first overview, while Campaign reads as a detail drill-down with summary facts and CampaignTimeline.**

## Performance

- **Duration:** 8m 23s
- **Started:** 2026-06-29T00:27:52Z
- **Completed:** 2026-06-29T00:36:15Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added Recovery-specific overview markers and browser assertions for hero, work queue, and supporting funnel order.
- Updated Recovery markup so the at-risk work queue sits before the existing FunnelChart supporting visualization.
- Replaced stale AtRiskTable documentation that described the table as below the Recovery Funnel.
- Added Campaign detail summary rows under the existing summary card while keeping CampaignTimeline as the primary drill content.

## Task Commits

Each task was committed atomically:

1. **Task 1: Mark and verify Recovery work-queue-first overview** - `b5528b47` (test), `848769fc` (feat)
2. **Task 2: Update AtRiskTable docs and component test posture** - `65b98190` (docs)
3. **Task 3: Convert Campaign to DETAIL drill-down shape** - `4c2b4058` (feat)

**Plan metadata:** recorded by the closeout commit after this summary is written.

_Note: Task 2 and Task 3 RED contracts were already present from earlier Phase 198 scaffolding and were verified failing before implementation._

## Files Created/Modified

- `.planning/phases/198-propagate-detail-analytics/198-08-SUMMARY.md` - Plan execution record and verification evidence.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` - Adds `data-ax-overview="recovery"` plus Recovery hero, work-queue, and supporting-funnel markers around the existing page content.
- `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` - Adds Campaign detail summary rows and page-local helpers for campaign state, event count, invoice count, and latest boundary.
- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` - Updates module documentation to describe the table as the Recovery work queue before the supporting funnel.
- `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` - Keeps Dashboard overview assertions separate and updates Recovery browser assertions to the Recovery-specific marker contract.

## Decisions Made

- Recovery keeps the existing WindowSelector, AtRiskTable, and FunnelChart composition; only markers and section order were adjusted.
- Recovery browser tests use Recovery-specific marker names instead of imposing Dashboard `data-ax-zone` semantics.
- Campaign summary facts are computed in private `CampaignLive` helpers so the page remains an explicit detail drill-down and does not introduce a generic analytics abstraction.
- Campaign continues to use `Dunning.campaign_timeline_grouped/1` and `Dunning.invoices_for_campaign/1`; no direct billing or repo boundary was added.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs --max-failures 5` - passed, 15 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/components/at_risk_table_test.exs --max-failures 3` - passed, 4 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/analytics/campaign_live_test.exs --max-failures 4` - passed, 9 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/components/at_risk_table_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs --max-failures 5` - passed, 28 tests, 0 failures.
- `cd accrue_admin && node --check e2e/admin-spec-overview-phase194.spec.js` - passed.
- `cd accrue_admin && npm run e2e:phase194` - passed, 10 Playwright tests, 0 failures.
- `rg -n "AnalyticsPage|Accrue\\.Repo|Accrue\\.Billing|ax-kpi-grid|data-ax-zone=\"kpi-cluster\"" accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` - no matches.
- `rg -n 'data-ax-zone="(kpi-cluster|task-launcher)"|TimeSeries|time-series|LineChart|new Recovery' accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex accrue_admin/e2e/admin-spec-overview-phase194.spec.js` - no matches.
- `! rg -n "below the Recovery Funnel|below.*Funnel" accrue_admin/lib/accrue_admin/components/at_risk_table.ex` - passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 2 and Task 3 RED tests already existed from the Phase 198 contract scaffolding, so implementation reused those contracts instead of adding duplicate assertions. Both were verified failing before the corresponding code/doc changes.
- The final stub scan found only benign empty/default checks in existing touched code and no UI placeholder, TODO, FIXME, or unwired mock data that blocks the plan goal.

## Known Stubs

None.

## Threat Flags

None - no new network endpoints, auth paths, schema changes, file access paths, package installs, or dynamic sensitive `data-ax-*` markers were introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 199/200 work can rely on Recovery having Recovery-specific overview markers and Campaign having a detail summary-list shape without a KPI wall or `AnalyticsPage` abstraction.

## Self-Check: PASSED

- Found summary file: `.planning/phases/198-propagate-detail-analytics/198-08-SUMMARY.md`
- Found task commit: `b5528b47`
- Found task commit: `848769fc`
- Found task commit: `65b98190`
- Found task commit: `4c2b4058`

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-29*
