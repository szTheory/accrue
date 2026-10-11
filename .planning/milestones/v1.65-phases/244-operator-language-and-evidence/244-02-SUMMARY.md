---
phase: 244-operator-language-and-evidence
plan: 02
subsystem: admin-ui
tags: [phoenix-liveview, events, webhook, accessibility, playwright]

requires:
  - phase: 244-01
    provides: shared BillingEvent copy, exact event timestamp, and browser evidence fixture
provides:
  - shared event language and exact raw keys on Events list/detail and webhook related activity
  - scoped event and source-webhook navigation with delivery and ledger history kept distinct
  - patch-safe keyboard/touch disclosures and readable selectable evidence at 320px
affects: [244-03, admin-events, admin-webhooks]

actuals:
  tokens: 154693
  tasks: 2
  commits: 4
commits: 4
plan_head_before: f62fe351f53910f7892c3d772a22a407a36331a1
plan_head_after: 613f2309023e724d1d70428a2a061b8d073368b2

tech-stack:
  added: []
  patterns:
    - preserve native disclosure intent across LiveView patches
    - wrap selectable evidence at narrow widths without changing stored values

key-files:
  created:
    - accrue_admin/assets/js/hooks/preserve_disclosure.js
  modified:
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/components/timeline.ex
    - examples/accrue_host/e2e/phase244-operator-evidence.spec.js
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js

key-decisions:
  - "Keep raw event keys and filters exact while using BillingEvent copy for operator-facing labels."
  - "Keep webhook delivery status, attempt history, and derived ledger events as separate facts."
  - "Preserve the operator's native disclosure state through LiveView patches; keep the existing details/summary interaction."

patterns-established:
  - "Related event evidence remains selectable and includes exact key, IDs, subject, and full timestamp."
  - "Scoped links are verified by rendered destination and owner query, not inferred from label text."

requirements-completed: [LANG-01, EVID-01, CONS-01]
coverage:
  - id: D1
    description: Shared event labels appear across Events list/detail and related webhook activity while raw keys remain available.
    requirement: LANG-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/events_live_test.exs and event_live_test.exs (29 tests)
        status: pass
      - kind: e2e
        ref: phase244-operator-evidence.spec.js @phase244-desktop (committed SHA 613f2309)
        status: pass
    human_judgment: false
  - id: D2
    description: Exact keys, event and webhook identifiers, and timestamp precision remain accessible in native evidence disclosures.
    requirement: EVID-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/webhook_live_test.exs
        status: pass
      - kind: e2e
        ref: phase244-operator-evidence.spec.js @phase244-desktop and @phase244-mobile (committed SHA 613f2309)
        status: pass
    human_judgment: false
  - id: D3
    description: Delivery remains distinct from derived events, and event/webhook links and evidence controls work without page overflow at 320px.
    requirement: CONS-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/webhook_live_test.exs
        status: pass
      - kind: e2e
        ref: phase244-operator-evidence.spec.js @phase244-desktop and @phase244-mobile (committed SHA 613f2309)
        status: pass
    human_judgment: false

duration: 29min
completed: 2026-10-10
status: complete
---

# Phase 244 Plan 02: Operator Language and Evidence Summary

**Shared event labels now reach Events and webhook activity while exact scoped evidence remains available through patch-safe disclosures at desktop and 320px touch widths.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-10-10T21:08:59-04:00 (first recorded task RED commit)
- **Completed:** 2026-10-10T21:38:22-04:00
- **Tasks:** 2
- **Files modified:** 16

## Accomplishments

- Events list and detail use the shared event label while preserving the exact event key, raw filter value, scoped links, and Wave 1's full-precision timestamp.
- Webhook related activity uses the same event meaning and exposes exact event key, event/actor/subject/webhook IDs, and ISO timestamp. Delivery state and attempt history remain separate from derived ledger events.
- Native disclosures retain their open or closed intent through LiveView updates. Evidence wraps and remains selectable at 320px without page overflow.
- Desktop and touch browser proofs record committed SHA, disposable fixture state, routes, viewport, effective themes, and served asset digests. Feedback preview custody remained unchanged.

## Task Commits

1. **Task 1: Carry shared event meaning and exact evidence into list and detail** — `2613baf0` (RED tests), `1cd93201` (GREEN implementation).
2. **Task 2: Keep webhook related activity distinct and prove native evidence access** — `d7ba780b` (RED test), `613f2309` (GREEN implementation).

**Plan commits:** 4 measured commits from `f62fe351f53910f7892c3d772a22a407a36331a1` through `613f2309023e724d1d70428a2a061b8d073368b2`.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/events_live.ex` — shared label and exact key in Events rows and detail.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` — shared label, exact related-event evidence, and scoped event destination.
- `accrue_admin/lib/accrue_admin/components/timeline.ex` — contents-specific disclosure labels.
- `accrue_admin/assets/js/hooks/preserve_disclosure.js` and `accrue_admin/assets/js/app.js` — retain the activated native disclosure state through LiveView patches.
- `accrue_admin/assets/css/app.css` — constrain and wrap long evidence lines at narrow widths.
- `accrue_admin/priv/static/accrue_admin.css` and `accrue_admin/priv/static/accrue_admin.js` — rebuilt package-owned served assets.
- `accrue_admin/test/accrue_admin/live/events_live_test.exs`, `event_live_test.exs`, and `webhook_live_test.exs` — rendered label, evidence, and scoped relationship assertions.
- `examples/accrue_host/e2e/phase244-operator-evidence.spec.js` — desktop and 320px touch browser coverage with provenance.
- `.planning/phases/244-operator-language-and-evidence/244-02-red-evidence.json`, `244-02-red-report.tap`, `244-02-webhook-red-evidence.json`, and `244-02-webhook-red-report.tap` — actual RED evidence for both TDD tasks.

## Decisions Made

- Raw event keys remain exact in evidence and filters; human-readable labels come from the shared BillingEvent copy helper.
- Delivery status, delivery attempts, and derived ledger events remain distinct facts.
- The existing native `details`/`summary` interaction remains in use, with a small hook to retain the operator's chosen open/closed state across patches.

## TDD Gate Compliance

Both plan tasks declared `tdd="true"`; each had an actual failing ExUnit RED run recorded before implementation, and `gsd_run check tdd-red-evidence` accepted both evidence reports. GREEN verification finished with **52 tests, 0 failures** across the focused event, webhook, and asset suites. No zero-test result is claimed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve native disclosure intent across LiveView patches**
- **Found during:** Task 2
- **Issue:** The lazy-load patch closed the operator-opened Activity disclosure, so its contents became hidden immediately after activation.
- **Fix:** Added the `PreserveDisclosure` hook to capture native summary activation and restore the intended state after a patch; the browser test verifies keyboard focus/open state and subsequent close state.
- **Files modified:** `accrue_admin/assets/js/hooks/preserve_disclosure.js`, `accrue_admin/assets/js/app.js`, `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, generated JS bundle, browser spec.
- **Verification:** Desktop and touch browser lanes passed against committed SHA `613f2309023e724d1d70428a2a061b8d073368b2`.
- **Committed in:** `613f2309`.

**2. [Rule 1 - Bug] Wrap exact evidence at narrow widths**
- **Found during:** Task 2
- **Issue:** Long evidence lines extended the document to 574px at a 320px viewport.
- **Fix:** Constrained the existing timeline disclosure and enabled pre-wrapped, anywhere-breakable evidence while preserving selectable source text.
- **Files modified:** `accrue_admin/assets/css/app.css`, generated CSS bundle, browser spec.
- **Verification:** 320px touch lane passed with no horizontal document overflow and selectable exact values.
- **Committed in:** `613f2309`.

**Total deviations:** 2 auto-fixed bugs (Rule 1). The additional hook and generated bundles were needed to make the planned native browser interaction work with the package's served assets. No dependency was added.

## Issues Encountered

- Chromium launch was denied in the sandbox on the first attempt; the same planned isolated browser lanes passed with normal browser-launch access.
- The default npm cache contains root-owned entries, so the existing pinned asset build initially stopped with `EPERM`. Re-running the existing build with an isolated temporary cache succeeded; no project dependency changed.
- The browser fixture's existing startup does not rebuild `accrue_admin`'s committed package bundles. The source and generated bundles were rebuilt before final browser verification so the recorded served hashes matched the implementation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 244-02 is complete. Plan 244-03 can proceed with shared event language and evidence now established on the confirmed Events and webhook views.

## Self-Check: PASSED

- Summary file exists and all four plan commits are ancestors of the current checkout.
- Plan commit count and head range match the persisted 244-02 ledger.
- No new auth path, endpoint, schema, or trust-boundary surface was introduced.

---
*Phase: 244-operator-language-and-evidence*
*Completed: 2026-10-10*
