---
phase: 194-exemplar-a-dashboard
plan: "02"
subsystem: ui
tags: [phoenix-liveview, accrue-admin, analytics, recovery, data-ax-zone]

requires:
  - phase: 194-01
    provides: "Dashboard exemplar with attention-rail pattern and ax-zone markers established"

provides:
  - "RecoveryLive render order corrected: AtRiskTable above FunnelChart (D-01)"
  - "Hero kpi-cluster zone marker on the leading metric pair section"
  - "task-launcher zone marker wrapping the at-risk work-queue table"
  - "No forced attention-rail marker on Recovery (no rail exists — Q-A explicit)"

affects: [194-03, 194-04, 195, wave-2-e2e]

tech-stack:
  added: []
  patterns:
    - "data-ax-zone=kpi-cluster on hero <section class=ax-kpi-grid> for leading metric zones"
    - "data-ax-zone=task-launcher wrapping work-queue tables; work-queue DOM index < chart DOM index"
    - "Honest zone markers: do not add attention-rail if the page has no exception/alert rail"

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex

key-decisions:
  - "D-01: AtRiskTable rendered above FunnelChart — operators act on at-risk records before seeing the conversion funnel"
  - "Q-A: zone markers are additive and honest — kpi-cluster for hero pair, task-launcher for work-queue; NO attention-rail (Recovery has none)"
  - "FunnelChart remains as supporting viz below the promoted work-queue, attributes preserved verbatim"

patterns-established:
  - "Work-queue zone (task-launcher) must precede any chart zone in DOM order — the load-bearing DOM-index invariant"
  - "Additive zone markers only mark what genuinely exists; absence of a rail means absence of an attention-rail marker"

requirements-completed: [EXE-01]

coverage:
  - id: D1
    description: "AtRiskTable.at_risk_table renders before FunnelChart.funnel_chart in RecoveryLive DOM (D-01 render-order swap)"
    requirement: EXE-01
    verification:
      - kind: automated_ui
        ref: "awk line-order check: table@146 < funnel@149"
        status: pass
      - kind: unit
        ref: "mix compile --warnings-as-errors: clean"
        status: pass
    human_judgment: false
  - id: D2
    description: "Additive data-ax-zone markers present: kpi-cluster on hero section, task-launcher wrapping AtRiskTable; no attention-rail marker"
    requirement: EXE-01
    verification:
      - kind: automated_ui
        ref: "grep -c 'data-ax-zone' recovery_live.ex = 2; grep -c 'attention-rail' = 0"
        status: pass
    human_judgment: false

duration: 191s
completed: 2026-06-25
status: complete
---

# Phase 194 Plan 02: Recovery Analytics Render-Order & Zone Markers Summary

**RecoveryLive corrected to work-queue-first layout: AtRiskTable promoted above FunnelChart with honest kpi-cluster and task-launcher zone markers, no forced attention-rail**

## Performance

- **Duration:** ~3 min (191s)
- **Started:** 2026-06-25T20:44:34Z
- **Completed:** 2026-06-25T20:47:45Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Swapped AtRiskTable above FunnelChart in `recovery_live.ex` render/1 — operators now see the at-risk work-queue before the conversion funnel (D-01)
- Hero `@kpi_pairs` loop (Recovered MRR / Exhausted MRR) unchanged and still leads above the promoted table (D-02)
- Added `data-ax-zone="kpi-cluster"` to the leading hero `<section class="ax-kpi-grid ax-section-gap">` — stable machine-checkable hook for the hero zone
- Wrapped AtRiskTable in `<section data-ax-zone="task-launcher">` — work-queue zone DOM index (L145) precedes FunnelChart (L149), satisfying the load-bearing Wave-2 e2e assertion
- No `attention-rail` marker added (Recovery has no exception rail — Q-A explicit, per CONTEXT/PATTERNS)

## Task Commits

1. **Task 1: Swap AtRiskTable above FunnelChart (D-01)** - `f3b4e8ff` (feat)
2. **Task 2: Add additive data-ax-zone markers (Q-A)** - `056951f3` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` - Render order swapped + additive zone markers added

## Decisions Made

- Chose to wrap AtRiskTable in a `<section data-ax-zone="task-launcher">` rather than adding an inline attribute — preserves the component call site verbatim and gives a named zone root for e2e selectors
- Confirmed no `attention-rail` marker: Recovery has no exception/alert rail; adding one would be dishonest to the page structure (Q-A resolution from CONTEXT.md)
- FunnelChart attributes preserved verbatim (entered/recovered/exhausted/active) — this was a pure re-order, no data plumbing change

## Deviations from Plan

None — plan executed exactly as written. Both tasks matched plan descriptions precisely: a pure render-block re-order (Task 1) and additive zone marker attributes only (Task 2).

## Issues Encountered

None.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. This plan modifies only static LiveView markup (a render-block re-order + static enum attribute values). T-194-03 (zone marker info disclosure) confirmed mitigated: markers carry only `kpi-cluster` / `task-launcher` static enum literals — no PII, no record IDs, no scope.

## Known Stubs

None. Both components (AtRiskTable, FunnelChart) are already wired to live data (`@at_risk`, `@funnel.*`) from `handle_params/3`.

## Self-Check: PASSED

- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`: FOUND
- Commit f3b4e8ff: FOUND
- Commit 056951f3: FOUND
- AtRiskTable line (146) < FunnelChart line (149): PASS
- data-ax-zone count = 2: PASS
- attention-rail count = 0: PASS

## Next Phase Readiness

- Recovery page now conforms to SPEC-OVERVIEW "no chart before the work-queue" invariant
- Wave-2 e2e spec can assert: `data-ax-zone="task-launcher"` DOM index < `FunnelChart` DOM index
- Ready for Plan 194-03 (next plan in the exemplar-a-dashboard phase)

---
*Phase: 194-exemplar-a-dashboard*
*Completed: 2026-06-25*
