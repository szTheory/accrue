# Phase 244: Operator Language and Evidence - Pattern Map

**Mapped:** 2026-10-10  
**Candidates analyzed:** 13 source/test behaviors  
**Existing analogs found:** 12 / 13

The preview's mounted routes, served revision/assets, and visual behavior remain **unobserved**. These are source patterns and test owners only; use the bounded mounted review required by `244-RESEARCH.md` to decide which candidates actually need changes. Do not treat these excerpts as preview proof.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/copy/billing_event.ex` | utility (shared Copy owner) | transform | same file; `copy.ex` delegates | exact |
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | component (LiveView) | request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | component (LiveView) | CRUD | same file | exact |
| `accrue_admin/lib/accrue_admin/live/event_live.ex` | component (LiveView) | request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | component (LiveView) | request-response, event-driven | same file | exact |
| `accrue_admin/lib/accrue_admin/components/timeline.ex` | component | transform | same file | exact |
| `accrue_admin/test/accrue_admin/copy/billing_event_test.exs` | test | transform | same file | exact |
| `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs` | test | request-response | same file | exact |
| `accrue_admin/test/accrue_admin/live/events_live_test.exs` | test | CRUD | same file | exact |
| `accrue_admin/test/accrue_admin/live/event_live_test.exs` | test | request-response | same file | exact |
| `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` | test | request-response | same file | exact |
| `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` | test | event-driven | same file | exact |
| Browser assertions, if needed for changed mounted interactions | test | request-response | No browser test path established by the supplied phase research | no analog established |

All named source/test analogs were checked with `git ls-files` and are tracked. The candidate inventory is provisional: Home and event detail are source change candidates; Events list, webhook activity, and outcome branches need current mounted assessment as specified in the phase research.

## Pattern Assignments

### Shared event labels: `copy/billing_event.ex` and its consumers

**Analog:** `accrue_admin/lib/accrue_admin/copy/billing_event.ex`

This module is the existing Copy owner, organized by consumer and prefixed function names. Add only source-verified event vocabulary here if selected. Preserve the exact stored key separately; do not generalize the list into a provider dictionary. Current module excerpt (lines 79-100):

```elixir
def billing_events_eyebrow_organization, do: "Organization activity feed"
def billing_events_eyebrow_global, do: "Global activity feed"
def billing_events_heading_organization, do: "Event log"
def billing_events_heading_global, do: "Event log"
def billing_events_webhook_source_direct, do: "Direct"
def billing_events_when_unknown, do: "Unknown"

def billing_event_not_found,
  do: "Event not found. Open the events list and confirm owner scope before retrying."
```

**Delegation pattern:** `accrue_admin/lib/accrue_admin/copy.ex` delegates grouped copy owners through the shared public Copy API. Inspect its existing BillingEvent delegates before adding a new callable function; avoid consumer-local competing translations.

**Consumers:** `DashboardLive.recent_events/2` (lines 91-105) sets the timeline title to raw `event.type`; `EventsLive.event_cell/4` (lines 423-432) renders raw `row.type` while preserving scoped event detail URLs; `EventLive.render/1` (lines 136-165) uses raw type in breadcrumb/title and the detail fields; `WebhookLive.derived_event_timeline/3` (lines 811-823) displays derived ledger events separately from webhook delivery status. These owners should use a common label only where they describe the same event. Keep query/filter values and route/authorization logic untouched.

### Timeline evidence: `components/timeline.ex`

**Analog:** `accrue_admin/lib/accrue_admin/components/timeline.ex`

`Timeline.timeline/1` already provides native `<details>/<summary>`, optional timestamp/body/status/meta, and scoped destination link slots through item maps. Lines 22-42:

```heex
<p class="ax-label"><%= Map.get(item, :title, "Event") %></p>
<time :if={Map.get(item, :at)} class="ax-timeline-time"><%= Map.get(item, :at) %></time>
...
<details :if={Map.get(item, :details)} class="ax-timeline-details" open={Map.get(item, :expanded, false)}>
  <summary>Inspect details</summary>
  <pre><%= Map.get(item, :details) %></pre>
</details>
...
<a :if={Map.get(item, :href)} class="ax-timeline-link" href={Map.get(item, :href)}>
  <%= Map.get(item, :href_label, "Open details") %>
</a>
```

The existing summary is generic and timeline time values are caller-formatted strings. If exact key/time evidence is assigned to a timeline, give the disclosure a contents-specific name and supply evidence from existing authorized fields. Do not assume Home has raw payload access or introduce new reads. Event detail already has native disclosure sections and recorded-time fields; keep payload in that existing detail context.

### Home LiveView and rendered test

**Analog:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` and `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs`

The LiveView obtains events with `Events.list(... owner_scope: owner_scope)` and builds scoped links. Current item shape (DashboardLive lines 91-110):

```elixir
Enum.map(events, fn event ->
  %{
    title: event.type,
    at: format_datetime(event.inserted_at),
    body: event_subject_summary(event),
    status: event.actor_type,
    tone: if(event.actor_type == "admin", do: :cobalt, else: :slate),
    meta: "Audit event",
    href: ScopedPath.build(mount_path, "/events/#{event.id}", owner_scope),
    href_label: "Open event"
  }
end)
```

The owning test seeds an event and asserts factual rendered activity and same-scope destinations. `dashboard_live_test.exs:91-114` currently checks `customer.updated`, “Open event ledger,” and `/billing/events`; extend at this owner for a confirmed display label, exact-key access, record identity, and exact timestamp path. The current dashboard formatter truncates to minute precision (`dashboard_live.ex:122-126`), so a test should prove seconds/fraction/timezone through an existing detail/disclosure path rather than implying Home's compact time is exact.

### Events list LiveView and rendered test

**Analog:** `accrue_admin/lib/accrue_admin/live/events_live.ex` and `accrue_admin/test/accrue_admin/live/events_live_test.exs`

Use the current row render callback and `event_cell/4` as the local pattern. It keeps the row ID link scoped and preserves filter return state (`events_live.ex:423-437`). If the visible type is humanized, keep the underlying filter value and exact key available. Tests already exercise rendered rows, filters, pagination, and owner scope; extend the existing test for label/fallback parity, exact key availability, unchanged filters, and scoped destinations. `EventsLive` currently converts other enums through its local `humanize/1` helper (`events_live.ex:457-479`); phase decisions explicitly call for a producer-backed Copy mapping instead of applying this arbitrary-key transform to event types.

### Event detail LiveView and rendered test

**Analog:** `accrue_admin/lib/accrue_admin/live/event_live.ex` and `accrue_admin/test/accrue_admin/live/event_live_test.exs`

`EventLive` uses the existing scoped read, summary card, semantic facts, details disclosure, lazy activity, and payload disclosure. Current rendered structure (`event_live.ex:136-193`):

```heex
<Breadcrumbs.breadcrumbs :if={@event} items={[
  %{label: "Dashboard", href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)},
  %{label: @return_destination.label, href: @return_destination.path},
  %{label: @event.type}
]} />
<Detail.summary_card :if={@event} eyebrow={Copy.event_detail_eyebrow()} title={@event.type}>
  <:facts>
    <dt class="ax-label">Recorded</dt>
    <dd class="ax-body"><%= format_datetime(@event.inserted_at) %></dd>
  </:facts>
</Detail.summary_card>
<details :if={@event} class="ax-detail-section" data-ax-drill-section="event-details" open>
  ...
</details>
```

The unavailable-read branch says identity/evidence are unknown and invokes `retry_read`; this is a read recovery branch, not replay. Tests `event_live_test.exs:105-180` establish the summary-first structure, scoped relationship links, lazy activity/payload loading, and no eager raw payload. Add exact-key and sub-minute/timezone assertions at this rendered owner if selected. Existing source formatting at `event_live.ex:445-446` is minute precision/`Unknown`; do not fabricate missing timestamps.

### Webhook related activity and outcome tests

**Analog:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `webhook_live_test.exs`, and `webhook_replay_test.exs`

`WebhookLive.derived_event_timeline/3` maps derived ledger events separately and displays the causal event ID/source filter. Its attempt timeline has job state and details (`webhook_live.ex:776-823`). Reuse these owners to keep delivery status, derived event semantics, and replay outcome distinct. The mounted replay workflow retains its existing step-up, queue, job and audit paths.

For result wording, copy the assertions that bind rendered uncertainty to durable evidence in `webhook_replay_test.exs:448-479`:

```elixir
assert html =~ "Queued 1 delivery"
assert html =~ "1 accepted enqueue(s) could not be reread; processing status is unknown."
result = bulk_replay_event!().data
assert result["queued"] == 1
assert result["reread_unknown"] == 1
assert outcome_total(result) == result["selected"]
assert length(dispatch_jobs(webhook.id)) == 1
refute html =~ "processed successfully"
```

Preserve this evidence-bound pattern if wording changes: requested/accepted work is not completed work; a reread retry remains distinct from replay. `event_live_test.exs` is the analog for the separate event read-unavailable branch. Do not create additional reads or mutations for copy changes.

### Copy and LiveView test patterns

`copy/billing_event_test.exs` is the direct unit-test owner. It uses `use ExUnit.Case, async: true`, aliases `AccrueAdmin.Copy`, and groups assertions by copy contract. Extend it with a small mapping/fallback/parity set, including unknown and nil/malformed input behavior where supported; avoid snapshotting paragraphs.

LiveView tests use `Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")`, `live(conn, route)`, and HTML/event assertions in the route-owning module. Reuse the existing fixture/setup and assert semantics alongside exact identifiers, timestamps, hrefs/effects, and scope. Browser-level focus, touch, text selection, and viewport behavior have no path established in supplied research; use an existing browser suite only if one is found during planning. Do not create a new framework or CI lane.

## Shared Patterns

### Copy ownership and exact key

**Source:** `accrue_admin/lib/accrue_admin/copy/billing_event.ex:4-20` and `copy.ex` delegates  
**Apply to:** confirmed consumers of shared event semantics

Use explicit clauses for checked producer keys, a neutral unknown fallback, and honest missing-data copy. Carry the raw key independently for investigation. Do not derive meaning from punctuation/title casing.

### Scoped navigation and relationship evidence

**Source:** `accrue_admin/lib/accrue_admin/live/dashboard_live.ex:91-110`, `events_live.ex:423-455`, `event_live.ex:448-463`  
**Apply to:** Home, event list/detail, related activity

Build destinations through existing `ScopedPath` helpers and only from validated existing relationships. Keep current owner scope and exact identifiers; absent/inaccessible relationships remain explicit and unlinked.

### Outcome evidence and safe recovery

**Source:** `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs:448-479`; `event_live.ex:130-136`  
**Apply to:** replay outcomes and read-unavailable branches

Assert both user-facing copy and the matching audit/job/state evidence. Read retry and replay are distinct effects. Unknown-after-accepted enqueue must stay unknown rather than success.

### Native disclosures and exact time

**Source:** `accrue_admin/lib/accrue_admin/components/timeline.ex:25-42`; `event_live.ex:160-205`  
**Apply to:** evidence placement where existing component owners are selected

Reuse native disclosure behavior, name its actual contents, and retain selectable exact values. The existing minute-formatted times do not satisfy exact precision alone; source the full available value from the same record and represent missing time honestly.

## No Analog Found

| File/behavior | Role | Data Flow | Reason |
|---|---|---|---|
| Browser assertions for mounted disclosure focus, touch, long-ID layout, viewport/theme, and served-asset proof | test | request-response | No concrete browser test path or mounted proof is supplied by phase research. Discover an incumbent browser suite before assigning work; current mounted preview is unobserved. |

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/{copy,live,components}` and `accrue_admin/test/accrue_admin/{copy,live}`; targeted event producers and requirements inventory in `244-RESEARCH.md`.  
**Files scanned:** 12 tracked source/test files; one browser-test behavior has no confirmed analog path.  
**Pattern extraction date:** 2026-10-10
