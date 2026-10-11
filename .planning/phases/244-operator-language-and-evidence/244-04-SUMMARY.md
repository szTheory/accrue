---
phase: 244-operator-language-and-evidence
plan: "04"
subsystem: ui
tags: [phoenix-liveview, replay, playwright, accessibility, scope]
requires:
  - phase: 244-operator-language-and-evidence
    provides: Scoped webhook/event owner surfaces and mounted host proof infrastructure from plans 244-01 through 244-03.
provides:
  - Per-delivery unknown bulk replay outcomes with selected identity and safe scoped read guidance.
  - Executable browser coverage for exact Unicode evidence, long IDs, duplicate event associations, scoped actions, and 320px overflow.
affects: [phase-244-verification, executable-uat]
actuals:
  tokens: 7366
  tasks: 2
  commits: 11
plan_head_before: 0b4fe6fcd224cdb285f3e5f745a7d2505e92cc07
plan_head_after: 1b62ad78a754fcd8c8bbae6aa3b1847ed9e97fa4
tech-stack:
  added: []
  patterns: ["Keep selected IDs distinct from freshly authorized detail IDs.", "Pass browser fixture strings to Mix as positional data."]
key-files:
  created: [.planning/phases/244-operator-language-and-evidence/244-04-SUMMARY.md]
  modified:
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
    - examples/accrue_host/e2e/phase244-operator-evidence.spec.js
    - .planning/phases/244-operator-language-and-evidence/244-VALIDATION.md
key-decisions:
  - "Use the already authorized selected-row read as the only source for result detail links; do not widen reads or perform a diagnostic reread."
  - "Keep uncertain replay wording and actions read-only, preserving enqueue counts and audit payload contracts."
  - "Use existing event, webhook, and evidence surfaces for the narrow browser proof; no CSS or runtime dependency changes were needed."
patterns-established:
  - "A bulk outcome retains its original selected ID separately from any authorized linked record."
  - "Browser seed values containing Unicode are passed as argv data, not interpolated into Elixir source."
requirements-completed: [STATE-01, EVID-01, CONS-01]
coverage:
  - id: D1
    description: "Uncertain bulk replay outcomes identify each selected delivery and give evidence-safe read guidance."
    requirement: STATE-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/webhook_replay_test.exs — 16 tests, including unknown, mixed, read-failed, accepted-reread, and denied outcomes."
        status: pass
    human_judgment: false
  - id: D2
    description: "Unicode keys and long identifiers remain exact and selectable in mounted evidence at 320px without horizontal overflow."
    requirement: EVID-01
    verification:
      - kind: automated_ui
        ref: "phase244-operator-evidence.spec.js — @phase244-mobile long Unicode evidence case; selected key, actor ID, subject ID; document width 320px."
        status: pass
    human_judgment: false
  - id: D3
    description: "Duplicate event labels retain ordered record-specific scoped links and nearby related actions navigate to their own records."
    requirement: CONS-01
    verification:
      - kind: e2e
        ref: "phase244-operator-evidence.spec.js — @phase244-desktop duplicate rows and @phase244-mobile related webhook action; final batch 6/6."
        status: pass
    human_judgment: false
metrics:
  duration: 25m
  completed: 2026-10-11
  status: complete
---

# Phase 244 Plan 04: Replay Outcome Attribution and Evidence Backstops Summary

Unclassifiable bulk replay outcomes now retain selected delivery identity and read-only recovery guidance, while desktop and 320px browser checks execute the former raw-evidence, long-ID, repeated-row, and related-action backstops.

## Performance

- **Duration:** 25 minutes
- **Started:** 2026-10-11T03:06:06Z
- **Completed:** 2026-10-11T03:31:09Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a bounded per-delivery bulk replay result that preserves the selected identity, distinguishes unavailable reads from accepted enqueue, and links only to an already authorized scoped detail row.
- Added owner assertions for unknown, mixed, read-failed, accepted-reread, and denied replay outcomes while preserving counts, audit facts, dispatch behavior, and locked copy.
- Replaced the four browser backstops with mounted desktop and touch assertions for exact selectable Unicode evidence, long IDs, ordered duplicate rows, scoped actions, and narrow-width layout.

## Task Commits

1. **Task 1: Associate uncertain bulk replay results with exact deliveries and read recovery** — `e608c2f4`.
2. **Task 2: Prove exact evidence and action association in the mounted narrow browser** — `6554016a`, followed by focused fixture/selector correction commits `27f05601`, `66dd8c25`, `92c9c2bc`, `d1133a4a`, `a947354c`, `83e48442`, `7a3d5494`, `59b0bd1c`, and `1b62ad78`.

The task 2 corrections were each committed before the confirming browser run. The final run used `1b62ad78a754fcd8c8bbae6aa3b1847ed9e97fa4` and passed all six selected cases.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/copy.ex` — state-specific safe next-step wording.
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` — selected-ID result rows and scoped read destinations.
- `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` — rendered outcome, association, and authorization coverage.
- `examples/accrue_host/e2e/phase244-operator-evidence.spec.js` — duplicate row and adversarial Unicode desktop/touch browser checks.
- `.planning/phases/244-operator-language-and-evidence/244-VALIDATION.md` — executable ownership rows and final revision/asset evidence.

## Decisions Made

- Used only existing selected-row owner reads to determine whether a detail link was authorized; no diagnostic reread or broader query was added.
- Kept unknown outcomes read-only and did not claim processing completion or recommend another replay.
- Used a valid webhook UUID and numeric event IDs for routes while storing unusual text only in schema-supported evidence fields.
- Left the unavailable cross-scope/free-text event detail inaccessible; browser navigation uses an already authorized related event and its scoped webhook action.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Corrected adversarial fixture and selector assumptions found by the browser run.**
- **Found during:** Task 2
- **Issue:** The initial actor type violated the database enum; subsequent assertions assumed a raw unknown label and link locations that do not match the rendered generic label, compact touch card, and Related billing action.
- **Fix:** Used the valid `webhook` actor type, read unknown keys from the evidence disclosure, and targeted existing scoped actions based on their rendered locations. No production CSS or UI change was required.
- **Files modified:** `examples/accrue_host/e2e/phase244-operator-evidence.spec.js`
- **Verification:** Final exact-revision tagged suite passed 6/6; served/package/compiled asset bytes matched.
- **Committed in:** `27f05601`, `66dd8c25`, `d1133a4a`, `a947354c`, `83e48442`, `7a3d5494`, `59b0bd1c`, `1b62ad78`.

**Total deviations:** 1 corrective fixture/selector issue, resolved. No product behavior or architecture changes beyond plan scope.

## Issues Encountered

Browser attempts identified fixture/selector errors and a useful scope boundary: the free-text subject evidence row appeared in the already-scoped related list, while its detail remained unavailable under existing owner authorization. The final proof retained that boundary and navigated through an authorized event row instead.

## User Setup Required

None — no external configuration or dependency was added.

## Next Phase Readiness

The plan’s owner and browser coverage is complete with `human_judgment: false`. The phase verifier should now regenerate `244-VERIFICATION.md` and establish its required passing status and zero unverified behavior. The orchestrator owns subsequent executable UAT generation; no UAT was generated here.

## TDD Gate Compliance

- Task 1 RED: new rendered owner assertions failed before implementation; GREEN: the focused owner suite passed 16/16 after the result presentation change.
- Task 2 RED: the adversarial mounted browser assertions exposed fixture and selector assumptions during initial runs; GREEN: all six tagged desktop/touch cases passed on the committed final revision.

---
*Phase: 244-operator-language-and-evidence*
*Completed: 2026-10-11*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All 11 measured plan commits are reachable from the plan head, including task commits `e608c2f4` and final browser spec commit `1b62ad78`.

## Incremental Review Follow-Up: WR-02

Post-plan review found the pre-dispatch read-failure row used copy that implied an attempted dispatch. Commit `19449fb4` now reports “Delivery could not be read; replay was not requested.” The attempted unknown outcome and accepted-enqueue/reread-failed copy remain unchanged. The focused replay owner suite passed 16/16 after the fix; the existing no-job/no-replay-event assertions remain green.
