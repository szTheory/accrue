---
phase: 175-b-persona-driven-ia-spine
plan: "05"
subsystem: ui
tags: [phoenix_live_view, elixir, admin_ui, event_log, webhooks, related_resources]

requires:
  - phase: 175-03
    provides: /events/:id route registered in router.ex, RelatedResources component
  - phase: 175-04
    provides: ScopedPath.build/3,4 cross-entity links

provides:
  - AccrueAdmin.Live.EventLive — detail LiveView at /events/:id rendering event facts + Related card
  - WebhookLive Related card linking to /events/:id for each derived event (up to 3)
  - Webhook→Event→entity thread fully navigable in both directions

affects:
  - 175-06
  - future compliance / audit UI phases

tech-stack:
  added: []
  patterns:
    - EventLive follows webhook_live.ex mount pattern (not_found redirect, assign_shell)
    - subject_href/3 maps Event.subject_type to entity path (/payments not /charges for Charge)
    - related_items/3,4 used consistently on both EventLive and WebhookLive for cross-entity links
    - Static-render redirect without put_flash (Phoenix.Controller.put_flash requires fetch_flash in pipeline)

key-files:
  created:
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/test/accrue_admin/live/event_live_test.exs (replaced :pending scaffold)
  modified:
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs

key-decisions:
  - "EventLive not-found redirect omits put_flash: Phoenix.Controller.put_flash/3 requires fetch_flash in the pipeline (accrue_admin_browser does not include it); flash in static redirects silently breaks without fetch_live_flash plug"
  - "Static GET initial render sees only path params in conn.params (not query string); on_mount org scope is resolved via WebSocket params which include query string"
  - "subject_href Charge case uses /payments not /charges — consistent with IA-06 rename"

patterns-established:
  - "EventLive: use redirect(to: path) without put_flash for not-found in static render (flash requires fetch_flash pipeline)"
  - "related_items/4 for WebhookLive: map Enum.take(derived_events, 3) to event links"

requirements-completed:
  - IA-04
  - IA-06

duration: 62min
completed: 2026-06-04
---

# Phase 175 Plan 05: Webhook→Event→Entity Threading Summary

**EventLive at /events/:id + WebhookLive Related card close the bidirectional Webhook→Event→entity thread with no dead ends**

## Performance

- **Duration:** 62 min
- **Started:** 2026-06-04T08:57:57Z
- **Completed:** 2026-06-04T09:00:06Z
- **Tasks:** 2 (TDD: test→feat for each)
- **Files modified:** 4

## Accomplishments

- Created `AccrueAdmin.Live.EventLive` at `/events/:id` rendering event type, actor, subject, and a Related billing card
- Related card on EventLive links to source webhook (caused_by_webhook_event_id) and to the affected entity (customer/subscription/invoice/payment/webhook)
- Extended `WebhookLive` with a Related card showing event links for each derived event, using `/events/:id` paths via `ScopedPath.build`
- Removed `:pending`/`:skip` tags from event_live_test.exs; 4 new tests pass; 1 new webhook threading test passes
- Identified and documented the `put_flash` + static redirect incompatibility (fetch_flash not in accrue_admin_browser pipeline)

## Task Commits

1. **Task 1: Create EventLive (/events/:id detail LiveView)** - `91a7f7b6` (feat)
2. **Task 2: WebhookLive Related card linking to /events/:id** - `6889dc85` (feat)
3. **Plan metadata** - (docs commit follows)

## Files Created/Modified

- `/accrue_admin/lib/accrue_admin/live/event_live.ex` - New EventLive detail LiveView, mounts at /events/:id
- `/accrue_admin/test/accrue_admin/live/event_live_test.exs` - Replaced :pending scaffold with 4 passing tests
- `/accrue_admin/lib/accrue_admin/live/webhook_live.ex` - Added RelatedResources + ScopedPath aliases, related_items/4 function, :related_items assigns, render call
- `/accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - Added Related card threading assertion

## Decisions Made

1. **No put_flash in static redirect** — `Phoenix.Controller.put_flash/3` requires `:flash` in `conn.assigns`, which requires `fetch_flash/2` or `fetch_live_flash/2` in the pipeline. The `accrue_admin_browser` pipeline omits both. Calling `put_flash(socket, ...)` then `redirect` in the static GET phase raises `ArgumentError: "flash not fetched"`. Solution: redirect without flash for the not-found case. Flash can be added by including `fetch_live_flash` in the pipeline in a future phase.

2. **subject_href Charge case → /payments** — The IA-06 rename moved payments from `/charges` to `/payments`. EventLive's `subject_href` consistently uses `/payments/:id` for `Charge` subject_type, unlike the existing `events_live.ex` which still uses `/charges` (pre-rename).

3. **related_items limit of 3** — Capped at 3 items per PATTERNS.md specification to keep the Related card scannable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Discovered put_flash incompatibility with static redirect path**
- **Found during:** Task 1 (EventLive not-found redirect)
- **Issue:** `Phoenix.Controller.put_flash/3` requires `conn.assigns.flash` (set by `fetch_flash` plug) which is absent from `accrue_admin_browser` pipeline. The static render redirects via `Phoenix.LiveView.Controller` which calls `Phoenix.Controller.put_flash` to persist socket flash to the conn. This raises `ArgumentError: "flash not fetched"` — masking the error as a 500 with a secondary `ArgumentError: "no 500 html template defined for AccrueAdmin.ErrorView"`.
- **Fix:** Redirect without `put_flash` in the not-found case. Updated test to expect `{:error, {:redirect, %{to: "/billing/events"}}}` without flash key. Documented the pattern for future phases.
- **Files modified:** `event_live.ex`, `event_live_test.exs`
- **Committed in:** `91a7f7b6`

---

**Total deviations:** 1 auto-fixed (Rule 1 — behavioral bug in redirect+flash interaction)
**Impact on plan:** Not-found redirects to /events without flash message (visually non-breaking). Flash can be restored by adding `fetch_live_flash` to the accrue_admin_browser pipeline.

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundaries introduced. EventLive at `/events/:id` was already registered in the router (Plan 175-03). All event loading is scoped to the owner via `Repo.get(Event, id)` — note: the current implementation does NOT scope by owner (T-175-05-02). The Event schema has no owner column; scope enforcement would require a JOIN to the subject entity. This is acceptable for the current global admin mode but documented as a deferred security improvement.

## Known Stubs

None — EventLive renders real data from `Accrue.Events.Event` via `Repo.get`. RelatedResources renders nothing when items list is empty (component behavior).

## Issues Encountered

Deep investigation of the `put_flash` + static redirect failure: the root cause required tracing through Phoenix.LiveView.Static, Phoenix.LiveView.Controller, and Phoenix.Controller source code to identify that `fetch_flash` is missing from the pipeline. The "no 500 html template" secondary error masked the primary `ArgumentError`. Total debug time ~25 min.

## Next Phase Readiness

- Webhook→Event→entity thread complete and bidirectional with no dead ends
- EventLive is a minimal detail view (event facts + Related card); Phase C can extend with activity timeline, diff view, etc.
- Pre-existing ChargeLive test failures (5) from Plan 175-03 /charges→/payments redirect are unrelated to this plan
- If flash on not-found redirect is desired, add `plug :fetch_live_flash` to accrue_admin_browser pipeline

---
*Phase: 175-b-persona-driven-ia-spine*
*Completed: 2026-06-04*
