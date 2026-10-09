---
phase: 238-admin-events-webhooks-remaining-billing-surfaces
plan: 01
subsystem: admin
tags: [phoenix-liveview, webhooks, dlq, step-up, audit, playwright]
requires: []
provides:
  - Confirmed bulk webhook replay through fresh server-side step-up and the existing DLQ.
  - Ordered per-delivery replay outcomes and matching audit counts.
affects: [phase-238-admin-surfaces, webhook-replay]
actuals:
  tokens: 6040
  tasks: 2
  commits: 2
plan_head_before: 49a40aba16fc660909833e39bc7f609c4315a762
plan_head_after: a87afbcde82c84271fcd3b00666f06d94645c1fb
tech-stack:
  added: []
  patterns:
    - Fresh StepUp authorization gates one-use bulk replay intent.
    - Per-row owner/status reloads preserve ordered queue, skip, and failure outcomes.
key-files:
  created:
    - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
  modified:
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
key-decisions:
  - Queue acceptance is reported separately from downstream processing.
  - Replay intent is consumed before step-up and every queue call rechecks scoped eligibility.
metrics:
  duration: 7min
  completed: 2026-10-09
  commits: 2
  plan_head_before: 49a40aba16fc660909833e39bc7f609c4315a762
  plan_head_after: a87afbcde82c84271fcd3b00666f06d94645c1fb
status: complete
requirements-completed: [ADM-07]
coverage:
  - id: D1
    description: A selected webhook delivery requires explicit confirmation and fresh step-up before it is queued.
    requirement: ADM-07
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/webhook_replay_test.exs#selection-driven retry confirms once and records one admin audit event
        status: pass
      - kind: e2e
        ref: playwright:e2e/phase238-admin-events-webhooks.spec.js#Phase 238 queues one selected webhook only after confirmation and fresh step-up
        status: pass
    human_judgment: false
  - id: D2
    description: Bulk results and audit data retain deterministic per-row queued, skipped, and failed outcomes.
    requirement: ADM-07
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
        status: pass
    human_judgment: false
---

# Phase 238 Plan 01: Confirmed webhook replay summary

**Selected webhook replay now uses explicit confirmation, fresh step-up, owner/status revalidation, and truthful queue outcome reporting.**

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-10-09T03:22:37Z
- **Completed:** 2026-10-09T03:29:45Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added the fresh step-up challenge after confirmation; rejected verification leaves webhook status unchanged and records no replay-completion audit.
- Re-resolves each selected row in the active owner scope immediately before queueing, deduplicates IDs, and consumes pending intent once.
- Records selected, eligible, attempted, queued, skipped, and failed counts with ordered scoped outcomes; visible copy says “queued” and never implies processing completed.
- Added a mounted host Playwright journey for selection, confirmation, step-up, and queue acceptance.

## Task Commits

1. **Task 1: Queue one eligible selected delivery through confirmation and fresh step-up** - `f9c91517` (`feat`)
2. **Task 2: Preserve exact bulk replay outcomes across stale, duplicate, mixed, and failed rows** - `a87afbc` (`fix`)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` - One-use confirmation flow, step-up modal, owner/status revalidation, ordered per-row results, and audit metadata.
- `accrue_admin/lib/accrue_admin/copy.ex` - Confirmation, queue acceptance, partial, empty, and singular/plural replay copy.
- `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` - Confirmation, rejected challenge, empty, duplicate, stale, foreign-owner, ordering, and injected queue-failure cases.
- `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` - List confirmation, accessible step-up, and audit count assertions.
- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` - Mounted host browser replay journey.

## Decisions Made

- Queue acceptance is a local queue result, not evidence that downstream processing completed.
- Pending selection is cleared before step-up; each replay attempt resolves ownership and current status again.

## Deviations from Plan

None - plan executed as written. A test-only queue callback injects a mid-batch failure so the regression test can prove earlier outcomes persist and later eligible rows continue.

## Issues Encountered

- The sandbox initially blocked Chromium startup; the browser verification was rerun with the authorized escalation and passed.
- The host fixture webhook belongs to the global Admin inspection scope, so the mounted E2E uses its existing global `/admin/webhooks` route. ExUnit separately covers a foreign organization row and confirms its identifier is omitted from audit evidence.
- GSD state initially had no readable current-plan counter, and the roadmap progress updater skipped the Phase 238 section. The counter is now 2 of 5 for the next plan; the completed plan checkbox and 1/5 progress row were updated directly.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs` — passed (7 tests).
- `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhooks_live_test.exs` — passed (18 tests).
- `cd examples/accrue_host && npx playwright test --list e2e/phase238-admin-events-webhooks.spec.js` — discovered 1 test.
- `cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` — passed (1 test).
- `.github/workflows/ci.yml` required Playwright shard runs unrestricted `npx playwright test --shard=...`.
- `git diff --check` — clean.

## User Setup Required

None - no external service configuration or provider API calls are required.

## Next Phase Readiness

ADM-07 is covered. The next Phase 238 plan can build on the existing queue and audit boundary; no schema or provider integration was added.

---
*Phase: 238-admin-events-webhooks-remaining-billing-surfaces*
*Completed: 2026-10-09*

## Self-Check: PASSED

- All five plan artifacts exist on disk.
- Both task commits are ancestors of the current HEAD.
- The plan evaluation scope resolves both task commits.
- Empty list literals in tests are intentional empty-selection and empty-audit assertions, not application stubs.
