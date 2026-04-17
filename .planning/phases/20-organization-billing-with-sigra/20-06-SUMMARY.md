---
phase: 20-organization-billing-with-sigra
plan: 06
subsystem: ui
tags: [sigra, liveview, organization-billing, webhook-replay, admin-scope]
requires:
  - phase: 20-organization-billing-with-sigra
    provides: Owner-aware admin query loaders plus denial redirect and event-feed scoping from plans 20-04 and 20-05
provides:
  - Owner-proofed webhook detail presentation with exact denial, ambiguity, and replay copy
  - Organization-scoped bulk replay confirmation counts and blocked replay audit behavior
  - Host-mounted end-to-end replay proof for allowed, ambiguous, and cross-org webhook paths
affects: [phase-21, org-billing, accrue-admin, accrue-host]
tech-stack:
  added: []
  patterns: [re-verify replay authorization at action time, assert blocked replay paths emit no success audit]
key-files:
  created:
    - .planning/phases/20-organization-billing-with-sigra/20-06-SUMMARY.md
    - examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
    - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
key-decisions:
  - "Webhook detail now consumes the owner-aware loader result directly, so denied rows redirect and ambiguous rows render blocked replay copy before any row metadata is exposed."
  - "Single and bulk replay flows re-check owner proof when the action fires, so blocked paths cannot emit `admin.webhook.replay.completed` just because the page was mounted earlier."
patterns-established:
  - "Carry the active organization slug through denied admin redirects so fail-closed routes return to the correct scoped index."
  - "In host-mounted LiveView tests, fetch flash into the conn before asserting redirect tuples so denied routes can prove exact copy without rendering leaked content."
requirements-completed: [ORG-03]
duration: 4 min
completed: 2026-04-17
---

# Phase 20 Plan 06: Webhook Replay Scope Summary

**Webhook detail and replay now fail closed for denied or ambiguous organizations, with host-mounted proof that only in-scope replay emits success audit events.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-17T20:31:34Z
- **Completed:** 2026-04-17T20:35:49Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Locked webhook detail routes to owner-aware outcomes so denied rows redirect, ambiguous rows render the exact blocked copy, and replay stays unavailable until ownership proof resolves.
- Scoped bulk replay confirmation counts and replay execution to the active organization instead of global dead-letter totals.
- Added host-mounted regression coverage for cross-org denial plus allowed and blocked replay paths, including no-success-audit assertions for ambiguous and out-of-scope rows.

## Task Commits

Each task was committed atomically:

1. **Task 1: Gate ORG-03 webhook detail and bulk replay presentation on owner proof with exact Phase 20 copy** - `b909dff` (feat)
2. **Task 2: Lock ORG-03 host-mounted end-to-end denial and replay proof (RED)** - `89f7c83` (test)
3. **Task 2: Lock ORG-03 host-mounted end-to-end denial and replay proof (GREEN)** - `dae96ce` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` - branches on owner-aware loader outcomes, stages replay confirmation, and blocks replay for denied or ambiguous rows with the exact UI-spec copy.
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` - scopes bulk replay counts and replay execution to rows proven for the active organization.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - proves denied redirects, ambiguous replay blocking, and in-scope replay success audit behavior.
- `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` - proves scoped bulk replay counts and blocked paths avoid replay-success audits.
- `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` - proves direct host-mounted links to other organizations' billing pages redirect with the exact denial flash.
- `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` - proves allowed replay succeeds while ambiguous and cross-org replay paths stay blocked end to end.

## Decisions Made

- Reused the query-layer webhook proof contract from plan 20-04 as the single source of truth for LiveView rendering and replay authorization.
- Kept the host proof focused on audit outcomes instead of internal queue state so ORG-03 remains testable through stable public behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed invalid webhook owner-proof fixture data in admin tests**
- **Found during:** Task 1 (Gate ORG-03 webhook detail and bulk replay presentation on owner proof with exact Phase 20 copy)
- **Issue:** The existing webhook test fixture recorded an invoice event with a non-UUID `subject_id`, which raised `Ecto.Query.CastError` once owner-proof joins started comparing invoice ids.
- **Fix:** Replaced the malformed fixture with a real invoice-backed event so owner-proof event matching exercised the intended path.
- **Files modified:** `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`
- **Verification:** `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhooks_live_test.exs`
- **Committed in:** `b909dff`

**2. [Rule 2 - Missing Critical] Preserved scoped org redirects for denied webhook detail routes**
- **Found during:** Task 1 (Gate ORG-03 webhook detail and bulk replay presentation on owner proof with exact Phase 20 copy)
- **Issue:** Denied webhook routes initially redirected to `/billing/webhooks` without the active organization slug, which broke the scoped admin flow even though the denial copy was correct.
- **Fix:** Added scoped path helpers so denied webhook redirects keep `?org=<slug>` and land back on the correct organization index.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`
- **Verification:** `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhooks_live_test.exs`
- **Committed in:** `b909dff`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both fixes were required for ORG-03 correctness and did not expand scope beyond the planned webhook denial and replay behavior.

## Issues Encountered

- Host-mounted redirect assertions needed `fetch_flash/2` on the test connection before `live/2`, because denied mounts return redirect tuples instead of rendered HTML.
- The local `gsd-sdk query ...` state handlers referenced by the workflow were unavailable in this environment, so roadmap and state tracking were updated directly in the markdown files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 20 is complete, including the highest-risk webhook replay path for ORG-03.
- Phase 21 can build browser/admin proof on top of the locked denial copy, owner-scoped replay confirmations, and host-mounted replay regression coverage from this phase.

## Self-Check: PASSED

- Verified `.planning/phases/20-organization-billing-with-sigra/20-06-SUMMARY.md` exists on disk.
- Verified task commits `b909dff`, `89f7c83`, and `dae96ce` exist in git history.

---
*Phase: 20-organization-billing-with-sigra*
*Completed: 2026-04-17*
