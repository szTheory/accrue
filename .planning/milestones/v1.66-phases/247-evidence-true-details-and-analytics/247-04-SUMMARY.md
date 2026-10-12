---
phase: 247-evidence-true-details-and-analytics
plan: "04"
subsystem: ui
tags: [phoenix-liveview, webhooks, accessibility, json]
requires:
  - phase: 247-08
    provides: shared timestamp, detail and page header components
provides:
  - Concise webhook identity, observed state and truthful replay review hierarchy
  - Accessible lazy Activity and Payload disclosures with Tree/Raw views and exact copy
affects: [247-07, webhook-investigation, json-viewer]
actuals:
  tokens: 157716
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [ARIA tab keyboard navigation, native details disclosure]
key-files:
  created:
    - accrue_admin/assets/js/hooks/json_viewer_tabs.js
  modified:
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/components/json_viewer.ex
    - accrue_admin/assets/js/app.js
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - accrue_admin/test/accrue_admin/components/display_components_test.exs
key-decisions:
  - "Replay wording describes queue acceptance as an attempt, never as completed delivery."
  - "Keep replay authorization and action handlers unchanged while clarifying their presentation."
patterns-established:
  - "JsonViewer exposes one active ARIA tab at a time and keeps copy as a separate action."
requirements-completed: []
coverage:
  - id: D1
    description: "Webhook identity, observed status, and replay eligibility read in one hierarchy with truthful queue semantics."
    verification:
      - kind: integration
        ref: "mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/scoped_path_test.exs (52 tests)"
        status: pass
    human_judgment: true
    rationale: "Rendered layout and visual hierarchy require the phase's integrated browser proof."
  - id: D2
    description: "Lazy Activity/Payload disclosures and Tree/Raw JSON tabs expose accessible state while preserving exact copy."
    verification:
      - kind: integration
        ref: "mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/components/display_components_test.exs test/accrue_admin/assets_test.exs (44 tests)"
        status: pass
    human_judgment: true
    rationale: "Source tests verify semantics and keyboard behavior; mounted rendered proof is reserved for phase 247-07."
metrics:
  duration: 15min
  completed: 2026-10-11
  commits: 2
  plan_head_before: c8e469355ace740309b953ca6ec1df371b2452d2
  plan_head_after: 06577a3cec8a4dc08680d49ae926a7f8c90828b7
status: complete
---

# Phase 247 Plan 04: Webhook investigation and replay summary

**Webhook detail now leads with its event identity and observed state, while replay and JSON controls communicate their exact behavior.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-11T21:47:00Z
- **Completed:** 2026-10-11T22:02:01Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Replaced redundant inspector framing and repeated event details with a clear webhook header, observed status, metadata, and scoped history link.
- Clarified replay eligibility and queue semantics, preserving confirmation, owner scope, step-up, action-time recheck, and audit behavior.
- Made Activity and Payload disclosures keyboard-identifiable, retained lazy loading, and added accessible Tree/Raw tabs with separate exact-payload copying.

## Task Commits

1. **Task 1: Put webhook identity, observed state and replay into one coherent hierarchy** - `e6f39cef` (feat)
2. **Task 2: Make activity and payload disclosure readable and exact** - `06577a3c` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` - webhook hierarchy, replay copy, and activity/payload disclosure labels.
- `accrue_admin/lib/accrue_admin/components/json_viewer.ex` - accessible tab and copy control semantics.
- `accrue_admin/assets/js/hooks/json_viewer_tabs.js` - keyboard navigation for the Tree/Raw tab set.
- `accrue_admin/assets/js/app.js` - hook registration.
- `accrue_admin/assets/css/app.css` - scoped disclosure and tab affordances.
- `accrue_admin/priv/static/accrue_admin.css` and `accrue_admin/priv/static/accrue_admin.js` - rebuilt static assets.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - hierarchy, history, disclosure, and payload assertions.
- `accrue_admin/test/accrue_admin/components/display_components_test.exs` - JSON viewer accessible state and exact copy assertions.

## Decisions Made

- Replay language describes acceptance into a queue and avoids implying processing completion.
- Existing replay action handlers and authorization checks remain intact; this plan changes only their presentation.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

Updated assertions to account for lazy loading and normalized ARIA attributes; the final focused test runs passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The webhook source and component tests pass, and the rebuilt assets are committed. Phase 247-07 can verify the mounted visual and keyboard experience.

---
*Phase: 247-evidence-true-details-and-analytics*
*Completed: 2026-10-11*

## Self-Check: PASSED

The summary exists, both task commits are ancestors of the current HEAD, and the plan's commit evaluation scope resolves to the two completed task commits.
