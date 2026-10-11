---
phase: 244-operator-language-and-evidence
plan: 03
subsystem: ui
tags: [phoenix-liveview, elixir, playwright, operator-copy, evidence]
requires:
  - phase: 244-01
    provides: operator-language mapping and scoped activity evidence
  - phase: 244-02
    provides: Home, Events and webhook evidence surfaces
provides:
  - Evidence-true replay acceptance and read-recovery language
  - Durable state, job, dispatch and audit assertions for replay/read branches
  - Revision-bound desktop and touch route/effect evidence
affects: [phase-244-verification, admin-webhooks, admin-events]
actuals:
  tokens: 34008
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 869c4fd3954bacf511747d1bd60aa61bbd76bf38
plan_head_after: 332426178e6c6c177efe4b0bd298511fead02256
tech-stack:
  added: []
  patterns:
    - Compare operator copy to durable status, jobs and audit facts
    - Bind Playwright evidence to checkout, owner spec digest and served assets
key-files:
  created:
    - .planning/phases/244-operator-language-and-evidence/244-03-red-evidence.json
    - .planning/phases/244-operator-language-and-evidence/244-03-red-report.tap
  modified:
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
    - examples/accrue_host/e2e/phase244-operator-evidence.spec.js
    - .planning/phases/244-operator-language-and-evidence/244-INVENTORY.md
key-decisions:
  - Preserve all Copy.Locked literals and existing dispatch, authorization, step-up and audit behavior.
  - Keep read recovery read-only; an accepted replay with a failed reread remains accepted with current status unknown.
patterns-established:
  - Assert requested/queued outcomes against state, job and audit evidence rather than success-shaped copy.
  - Keep unavailable browser states explicitly unobserved when the mounted fixture cannot induce them safely.
requirements-completed: [LANG-01, EVID-01, CONS-01]
coverage:
  - id: D1
    description: Replay acceptance and read recovery copy agree with durable state and mutation evidence.
    requirement: STATE-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/webhook_replay_test.exs and webhook_live_test.exs; 49 focused tests
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/event_live_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Home and related activity links open the exact organization-scoped event destinations.
    requirement: CONS-01
    verification:
      - kind: e2e
        ref: examples/accrue_host/e2e/phase244-operator-evidence.spec.js @phase244-desktop; 2 passed at commit 33242617
        status: pass
    human_judgment: false
  - id: D3
    description: Related event details expose exact keys and record evidence on desktop and touch layouts.
    requirement: EVID-01
    verification:
      - kind: e2e
        ref: examples/accrue_host/e2e/phase244-operator-evidence.spec.js @phase244-mobile; 1 passed at commit 33242617
        status: pass
    human_judgment: false
  - id: D4
    description: The mounted browser confirms the replay confirmation step-up boundary without changing durable state.
    verification:
      - kind: e2e
        ref: examples/accrue_host/e2e/phase244-operator-evidence.spec.js replayConfirmation evidence at commit 33242617
        status: pass
    human_judgment: false
duration: 45min
completed: 2026-10-10
status: complete
---

# Phase 244 Plan 03: Operator Language and Evidence Summary

**Replay acceptance and read recovery now describe verified effects, while scoped event links and replay step-up are bound to durable evidence.**

## Performance

- **Duration:** about 45 minutes
- **Started:** 2026-10-10T21:45:00-04:00
- **Completed:** 2026-10-10T22:29:40-04:00
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Clarified accepted replay and follow-up read failure copy without implying delivery completion; successful read recovery clears stale local warnings.
- Verified replay/read outcomes against job and audit facts, including no second dispatch on read retry and unchanged facts before step-up.
- Confirmed Home→Events and activity→event/source-webhook destinations at desktop and touch sizes, and recorded exact revision, fixture, theme and asset identities in the inventory.

## Task Commits

1. **Task 1: Bind replay and read outcomes to durable facts** — `84687d70` (RED evidence), `36f69a5a` (implementation)
2. **Task 2: Confirm rendered destinations, effects, and revision-bound acceptance** — `33242617` (spec and inventory)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` — evidence-true replay and read-retry labels and accepted/unknown status wording.
- `accrue_admin/lib/accrue_admin/live/event_live.ex` — read retry clears the stale local warning after recovery.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` and `event_live_test.exs` — assert recovery wording and durable effects.
- `examples/accrue_host/e2e/phase244-operator-evidence.spec.js` — scoped routes, replay step-up, durable pre-confirmation facts, and package/compiled/HTTP asset checks.
- `.planning/phases/244-operator-language-and-evidence/244-INVENTORY.md` — final dispositions, route/state/asset evidence and unresolved verifier flags.
- `.planning/phases/244-operator-language-and-evidence/244-03-red-evidence.json` and `244-03-red-report.tap` — recorded TDD RED evidence.

## Decisions Made

- Preserved `Copy.Locked` literals and incumbent dispatch, authorization, step-up, read and audit paths.
- Kept unavailable browser read state unobserved; existing focused LiveView tests assert the read-retry handler, so no test-only outage mechanism was added.
- Left the unclassified STATE-01 probe and three descriptor-less prohibition flags visible for independent verification.

## Deviations from Plan

The mounted browser did not induce a read outage, so it could not render the read-retry state or prove that handler in-browser. The focused LiveView tests verify that the action only rereads and does not enqueue another replay; the inventory labels browser coverage unobserved. No production seam or unrelated test lane was added.

## Verification

- **TDD RED:** the focused suite produced 3 expected failures across 49 tests before implementation; `.planning/phases/244-operator-language-and-evidence/244-03-red-evidence.json` and `244-03-red-report.tap` preserve the evidence, and `gsd_run check tdd-red-evidence` accepted it.
- **TDD GREEN:** the same three owner suites passed 49/49 after implementation.
- Focused owners: `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/event_live_test.exs` — **49 tests, 0 failures**.
- Full Admin regression: `cd accrue_admin && mix test` — **688 tests, 0 failures**.
- Post-commit desktop browser: **2/2 passed** at 1280×900, checkout `332426178e6c6c177efe4b0bd298511fead02256`.
- Post-commit mobile/touch browser: **1/1 passed** at 320×800, same checkout, `isMobile` and `hasTouch` enabled.
- CSS HTTP/package/compiled SHA-256 matched: `b40ac1dc7bb6a09ac7bccedb10ac1856ea9cbad212d69ce11db054a22807b952` (129964 bytes). JS matched: `e228bac9b978a658b37e96b9aa833fe6e8a87358447d00d93e616f55f5667c26` (161648 bytes).
- Preview remained stopped and untouched; Playwright used disposable `HOST-BROWSER-VERIFY01` fixtures and the isolated native `accrue_host_test` database.

## TDD Gate Compliance

Task 1 followed RED → GREEN: the pre-implementation run recorded 3 intended copy/recovery failures; after implementation, all 49 focused tests passed. The RED evidence checker accepted the machine-readable record, and the saved TAP report preserves the full failing run.

## Issues Encountered

- The first desktop run found tuple serialization in the new read-only fact helper; selecting JSON-safe maps fixed it.
- The next run showed that the confirmation copy displays the processor event ID rather than the database UUID; the assertion now checks the seeded visible ID.
- The first mobile proof build exceeded its 120-second startup limit. The partial isolated build was reused after confirming and replacing only its stale PID marker; the final run passed.

## User Setup Required

None.

## Next Phase Readiness

The plan's implementation and automated checks are complete. The inventory retains the unclassified STATE-01 probe and three descriptor-less prohibition flags for the independent phase verifier; this summary does not claim those flags were mechanically proved.

---
*Phase: 244-operator-language-and-evidence*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary file exists.
- Task commits `84687d70`, `36f69a5a`, and `33242617` are ancestors of HEAD.
- Stub/placeholder scan found no TODO, FIXME, “coming soon,” “placeholder,” or “not available” strings in changed deliverables.
