# Phase 175: B — Persona-Driven IA Spine - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView 1.1 information architecture — nav tiering, sidebar collapse, attention badges, work-queue defaults, Customer-360 tab overflow, bidirectional related-resources threading, visible search, route redirects
**Confidence:** HIGH (all findings grounded directly in the codebase source files read in this session)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Nav hierarchy & attention badges (IA-01, IA-02)**
- Specialist zones (Recovery · Developer · Catalog) render as collapsible group headers with muted/smaller labels + a chevron; primary Billing zone is always-expanded and visually heavier (no collapse). Connect stands alone.
- Default collapse state: auto-expand a specialist zone when its badge count > 0, collapse when empty; persist the user's manual toggle in `localStorage`.
- Badge data source: reuse the existing dashboard attention queries (dead-letter webhooks → Developer badge; past-due / at-risk → Recovery badge) via a shared context function computed in `on_mount` / sidebar assigns — do NOT write parallel count queries.
- Badge refresh cadence: compute once per navigation (LiveView assign, no polling / no PubSub) — cheap and sufficient for v1.51.

**Work-queue defaults & route reshaping (IA-03, IA-07)**
- Per-list default queue filters: invoices → open + uncollectible; subscriptions → past_due + canceling (at-risk); payments → failed; customers → all.
- Default-filter mechanism: apply the default in the LiveView and `push_patch` so the URL reflects `?status=…`; the "All" filter chip clears the queue filter.
- "Payments" route reshaping: add `/payments` route pointing at existing `ChargesLive`/`ChargeLive`, and redirect `/charges` → `/payments` and `/charges/:id` → `/payments/:id` so existing bookmarks survive; relabel the nav leaf "Payments".
- "All" escape hatch: a persistent "All" filter chip reusing `filter_chip_bar` — one click clears the persona-queue filter.

**Threading & Customer-360 tiering (IA-04, IA-05, IA-06)**
- Customer-360 split: primary visible tabs = Subscriptions, Invoices, Payments (charges tab surfaces as "Payments"); recessed under "More" = Payment methods, Entitlements, Events, Metadata.
- "More" mechanism: a "More ▾" overflow dropdown at the end of the tab strip.
- Webhook→Event→entity thread: add a Related card on Webhook detail linking to the Event(s) it produced, and add a lightweight `/events/:id` detail (or focus drawer) so the event → affected-entity hop has a destination.
- Bidirectional Related card scope: all 8 detail screens — customer, subscription, invoice, charge (payment), coupon, promotion_code, connect_account, webhook.

**Compliance lens & Home refinements (IA-01)**
- Compliance actor-lens: a saved actor-filter preset surfaced as a labeled quick-filter chip ("By actor") on `/events` using the existing filter mechanism — NOT a new nav group.
- Home verb relabels: exact design strings — "Look up a customer," "Clear the invoice queue," "Recover at-risk revenue," "Investigate an incident."
- Visible search: render `GlobalSearch` as a visible labeled input (placeholder "Search customers, invoices… ⌘K") in the topbar + a prominent field on Home, still ⌘K-activatable.
- Anti-churn on frozen Home zones: touch Home only for the verb relabel + search-field surfacing; leave the attention rail, KPIs, and recent-activity zones frozen.

### Claude's Discretion
- Exact CSS/token choices for the recessed-zone visual weight, chevron affordance, and badge styling — must resolve from Phase 174 `ax-*` tokens (no literals).
- Exact shape of the lightweight event detail (full `/events/:id` LiveView vs. a focus drawer reusing `detail_drawer.ex`) is the planner's call, provided the Webhook→Event→entity thread is navigable and bidirectional.
- Exact `localStorage` key naming and the JS hook wiring for collapse persistence.

### Deferred Ideas (OUT OF SCOPE)
- Per-screen rubric uplift (charges, coupons, promotion-codes, connect, events, webhooks, invoice detail) → Phase C (176).
- Motion / micro-interactions on the new collapsible nav, More dropdown, drawers → Phase D (177).
- Seed/state coverage so every new state (at-risk queues, dead-letter badges) is reachable from seeds → Phase E (178).
- Screenshot QA sign-off of the reshaped IA → Phase F (179).
- Live badge updates via PubSub — deferred; per-navigation compute is sufficient for v1.51.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IA-01 | From Home, each of the six personas can reach their primary job in ≤2 clicks via a verb-labeled task launcher or a visible (not hotkey-only) global search field. | §verb-relabels, §visible-search: copy.ex has 4 launcher fn → update title strings + render visible field in topbar |
| IA-02 | The sidebar presents a weighted primary Billing zone with Recovery / Developer / Catalog as visually-recessed, collapsible specialist zones that surface attention-count badges only when work exists. | §sidebar-collapse, §badge-data-source: sidebar.ex + nav.ex rewrites; shared context fn pattern confirmed |
| IA-03 | List screens open pre-filtered to the persona work-queue, with an "All" view one filter-chip away. | §work-queue-defaults: handle_params + push_patch pattern confirmed; filter_chip_bar chip API confirmed |
| IA-04 | Every detail screen renders a Related-billing card with no dead ends; a dead-lettered webhook threads to its event(s) and onward to the affected entity. | §threading: related_resources.ex is unchanged; webhook_live.ex has derived_events query; events_live has no :id route today (gap confirmed) |
| IA-05 | Customer-360 presents primary tabs (Subscriptions, Invoices, Payments) with advanced tabs (Payment methods, Entitlements, Events, Metadata) recessed under a quieter "More" grouping. | §more-overflow: tabs.ex is a plain functional component; "More ▾" requires server-side open/close assign or client-side disclosure |
| IA-06 | Routes changed by the IA reshape redirect from their old paths, so existing bookmarks and links never break. | §route-redirects: router.ex macro + Phoenix redirect/2 pattern; confirmed no existing redirect mechanism today |
| IA-07 | A compliance/audit user can reach an actor-filtered view of the event log via a saved lens (without it occupying a top-level nav group). | §compliance-lens: events_live.ex already has actor_type filter_field; "By actor" chip is a persistent UI affordance on top of existing mechanism |
</phase_requirements>

---

## Summary

Phase 175 is a pure IA and wiring pass on the already-shipped `accrue_admin` v1.50 admin. All code changes touch existing files — no new modules are required except: (1) a shared `AttentionCounts` context function (new module or new function in an existing module), (2) a lightweight `EventLive` (or a drawer-based `/events/:id` destination), and (3) new CSS class stubs (`.ax-badge-warning`, `.ax-badge-danger`, `.ax-sidebar-group-chevron`, `.ax-tab-more-menu`).

The dominant pattern throughout is: **data flows from a shared function → `on_mount` assigns → stateless function components**. Nav badges follow this path. Work-queue defaults follow the existing `handle_params` → `push_patch` LiveView lifecycle. The "More ▾" dropdown is the only genuinely new interaction pattern, and it follows the existing `detail_drawer.ex` / `CommandPalette` precedent (server-side `is_open` assign OR a lightweight CSS-only disclosure — either is acceptable given Phase D defers motion).

The `/charges` → `/payments` redirect is the most structurally interesting change: Phoenix's router macro does not support `redirect/2` inside `live_session` blocks — the idiomatic solution is a plain `get/3` controller action outside the `live_session` or a `Plug.Conn.halt/1`-based plug. Research confirms this is the correct approach.

**Primary recommendation:** Implement sidebar collapse state as a JS hook writing to `localStorage` + a `phx-mounted`/`phx-hook` attribute on the group element; badge data via a shared `AccrueAdmin.AttentionCounts.compute/1` function called once in `on_mount` and threaded into `nav_items` via an extended nav item map; `/payments` redirect via a plain `get` redirect controller outside the `live_session` block; "More ▾" as a server-side `is_open` boolean on `customer_live` socket with a `phx-click` toggle handler.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Nav tiering + group collapse state | Frontend Server (LiveView render) | Browser (JS hook for localStorage) | Group expanded/collapsed is persisted client-side; initial state computed server-side from badge count |
| Attention badge counts | API / Backend (Ecto queries) | Frontend Server (LiveView assign) | Counts are DB queries run once per navigation in `on_mount`; never in the browser |
| Work-queue default filter | Frontend Server (LiveView `handle_params` + `push_patch`) | — | URL-param-synced filter state; DB query triggered by data_table on params change |
| Customer-360 "More ▾" open/close | Frontend Server (LiveView assign) | Browser (focus management) | `is_more_open` boolean assign toggled via `phx-click`; no separate JS needed |
| Route redirects `/charges` → `/payments` | API / Backend (Phoenix Router, plain Plug controller) | — | Must happen before LiveView mounts; outside `live_session` |
| Webhook → Event → entity threading | API / Backend (Ecto query in LiveView mount) | Frontend Server (RelatedResources render) | Event derivation query already exists in `webhook_live.ex`; just needs a navigable `/events/:id` destination |
| Compliance actor-lens chip | Frontend Server (LiveView filter state) | — | Reuses existing `filter_chip_bar` + DataTable URL-param mechanism; no new tier needed |
| Visible global search field | Frontend Server (LiveView component) | Browser (JS CommandPalette hook) | Existing `GlobalSearch` LiveComponent + `CommandPalette` JS hook; needs a visible static field in topbar |

---

## Standard Stack

### Core (all pre-installed — no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | `~> 1.1` | LiveView socket, `push_patch`, `live_component`, `on_mount` hooks | Already in `accrue_admin/mix.exs`; all IA work uses standard LiveView patterns |
| `phoenix` | `~> 1.8` | `redirect/2` in plain controller, Router `get/3` | Already in deps; redirect mechanism is plain Phoenix, not LiveView |
| Custom `ax-*` CSS | (committed bundle) | All new visual tokens (badge-warning, badge-danger, sidebar-group-chevron, tab-more-menu) | Locked design system; no Tailwind |

**No new mix dependencies are introduced by this phase.** [VERIFIED: codebase inspection]

---

## Package Legitimacy Audit

> No new external packages are introduced in this phase. Audit: not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Browser navigation (GET /payments or /charges)
        │
        ▼
Phoenix Router (outside live_session)
  ├── GET /payments/:id  → ChargesLive (live_session)
  ├── GET /payments      → ChargesLive (live_session)
  ├── GET /charges       → RedirectController.redirect_to_payments/2  (302)
  └── GET /charges/:id   → RedirectController.redirect_to_payments_id/2 (302)
        │
        ▼
live_session :accrue_admin
  on_mount: [AuthHook, NavBadgeHook]   ← NEW: computes attention counts once
        │
        ▼
AppShell.app_shell
  ├── Sidebar (receives nav_items with :badge field)
  │     ├── Billing group (always expanded, no collapse)
  │     ├── Recovery group (collapsible, JS hook ↔ localStorage)
  │     ├── Developer group (collapsible, JS hook ↔ localStorage)
  │     └── Catalog group (collapsible, JS hook ↔ localStorage)
  ├── Topbar (visible GlobalSearch field + ⌘K trigger)
  └── Main content
        ├── List LiveViews (InvoicesLive, SubscriptionsLive, ChargesLive, EventsLive)
        │     └── handle_params: if no status param → push_patch with default queue
        │           DataTable (URL-param driven, existing mechanism)
        │           FilterChipBar ("All" chip clears queue + persona-queue chip)
        ├── CustomerLive (tab tiering)
        │     ├── Primary tabs: Subscriptions, Invoices, Payments
        │     └── "More ▾" dropdown: Payment methods, Entitlements, Events, Metadata
        ├── All 8 detail LiveViews
        │     └── RelatedResources (unchanged component, extended item lists)
        └── EventLive (/events/:id) ← NEW destination for Webhook→Event→entity thread
```

### Recommended Project Structure (changes only)

```
accrue_admin/lib/accrue_admin/
├── attention_counts.ex          # NEW: shared fn compute/1, reuses dashboard_live queries
├── components/
│   └── sidebar.ex               # EXTEND: badge + collapse support
├── live/
│   ├── event_live.ex            # NEW: lightweight /events/:id detail
│   ├── customer_live.ex         # EXTEND: tab tiering + More ▾
│   ├── invoices_live.ex         # EXTEND: work-queue default via push_patch
│   ├── subscriptions_live.ex    # EXTEND: work-queue default via push_patch
│   ├── charges_live.ex          # EXTEND: work-queue default + nav label update
│   ├── events_live.ex           # EXTEND: actor-lens "By actor" chip
│   ├── dashboard_live.ex        # EXTEND: verb relabels + visible search field
│   └── webhook_live.ex          # EXTEND: Related card → Event(s)
├── nav.ex                       # EXTEND: badge field + /payments href
├── router.ex                    # EXTEND: /payments route + /charges redirect
├── copy.ex                      # EXTEND: 4 launcher titles updated
└── controllers/
    └── redirect_controller.ex   # NEW (or inline redirect): /charges → /payments

accrue_admin/assets/
├── css/app.css                  # EXTEND: .ax-badge-warning, .ax-badge-danger,
│                                #  .ax-sidebar-group-chevron, .ax-tab-more-menu
└── js/hooks/
    └── sidebar_collapse.js      # NEW: localStorage persist for group collapse state
```

---

## Research Findings by Domain

### 1. Phoenix Router Redirect for `/charges` → `/payments` (IA-06)

**The structural constraint:** The `accrue_admin` router macro wraps all LiveView routes inside a `live_session :accrue_admin` block (confirmed in `router.ex` lines 57–93). Phoenix `live_session` blocks do not support `redirect/2` inside them — only `live/3` and `live/4` are valid inside a `live_session`. [VERIFIED: codebase inspection of router.ex]

**The correct pattern:** Add plain `get/3` routes pointing to a simple redirect controller **outside** the `live_session` but inside the same scope. This is valid Phoenix routing:

```elixir
# Inside the scope mount_path, as: :accrue_admin block — but OUTSIDE live_session:
get("/charges", AccrueAdmin.RedirectController, :charges_index)
get("/charges/:id", AccrueAdmin.RedirectController, :charges_show)

# Inside live_session, add the new /payments routes:
live("/payments", AccrueAdmin.Live.ChargesLive, :index)
live("/payments/:id", AccrueAdmin.Live.ChargeLive, :show)
# Keep existing /charges routes REMOVED (replaced by redirects above)
```

```elixir
# accrue_admin/lib/accrue_admin/redirect_controller.ex
defmodule AccrueAdmin.RedirectController do
  use Phoenix.Controller

  def charges_index(conn, _params) do
    # Preserve query params (org scoping etc.)
    qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
    mount_path = conn.assigns[:accrue_admin_mount_path] || "/billing"
    redirect(conn, to: mount_path <> "/payments" <> qs)
  end

  def charges_show(conn, %{"id" => id}) do
    qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
    mount_path = conn.assigns[:accrue_admin_mount_path] || "/billing"
    redirect(conn, to: mount_path <> "/payments/" <> id <> qs)
  end
end
```

**Important detail:** The `mount_path` must come from assigns injected by `BrandPlug` or a simple conn assign. Looking at `router.ex` line 43, `BrandPlug` runs in the `accrue_admin_browser` pipeline which covers the scope. The redirect controller needs access to `mount_path`. The simplest approach: hardcode it from the conn's path prefix, or pass it as a plug assign from BrandPlug. Alternatively, since the scope already has `mount_path` bound at macro-expansion, the redirect URLs can be computed with a known prefix. Check `AccrueAdmin.Assets.normalize_mount_path/1` for the canonical value.

**Alternative simpler approach:** Use `Plug.Conn.halt` inline via a simple plug module that does a 302 redirect — avoids a full controller module. Either approach is acceptable.

**The nav.ex href update:** `nav.ex` line 34 already has `href: nav_href(mount_path, "/charges", org)` for the "Payments" leaf. Update to `/payments` — this is a single-line change. [VERIFIED: nav.ex line 34]

**Footgun:** If you remove the old `live("/charges", ...)` routes without adding the `get/3` redirects in the same deploy, existing bookmarks will 404 briefly. Always add both in the same change.

### 2. Sidebar Collapse with localStorage Persistence (IA-02)

**Current state:** `sidebar.ex` is a stateless functional component with no collapse, no badge support. `grouped_items/1` uses `Enum.chunk_by` on the `:group` field. [VERIFIED: sidebar.ex full read]

**The JS hooks precedent:** The codebase already has `accrue_shell_nav.js` (document-level click handler, `localStorage`-free but shows the pattern), and `CommandPalette` hook (the richer hook pattern — `mounted/0`, `destroyed/0`, `pushEventTo`). The `app.js` uses `hooks: { CommandPalette }` in LiveSocket options. [VERIFIED: app.js, accrue_shell_nav.js, command_palette.js]

**Recommended pattern — JS hook + phx-hook attribute:**

The group collapse is a pure client-side concern at the interaction level, but the server controls the initial state (badge count > 0 → expand). The cleanest approach:

1. Server renders each specialist group with `aria-expanded={initial_expanded}` based on badge count (or localStorage key absence defaults to badge-count rule).
2. A new `SidebarCollapse` JS hook on each collapsible group element reads `localStorage` on `mounted()` to override if the user has manually toggled, and persists toggles to `localStorage` on click.

```javascript
// assets/js/hooks/sidebar_collapse.js
export const SidebarCollapse = {
  mounted() {
    const key = "ax-sidebar-" + this.el.dataset.group;
    const stored = localStorage.getItem(key);
    if (stored !== null) {
      const expanded = stored === "true";
      this.setExpanded(expanded);
    }
    // else: server-rendered aria-expanded is the initial state (badge-driven)

    this.el.addEventListener("click", (e) => {
      if (e.target.closest("[data-collapse-toggle]")) {
        e.preventDefault();
        const expanded = this.el.getAttribute("aria-expanded") === "true";
        this.setExpanded(!expanded);
        localStorage.setItem(key, String(!expanded));
      }
    });
  },

  setExpanded(expanded) {
    this.el.setAttribute("aria-expanded", String(expanded));
    const list = document.getElementById(this.el.dataset.controls);
    if (list) list.hidden = !expanded;
  }
};
```

Register in `app.js`: `hooks: { CommandPalette, SidebarCollapse }`.

**Server side initial expanded state:** The server computes `attention_counts` in `on_mount`, passes them into nav items (extended to include `badge: integer | nil`), and `sidebar.ex` determines initial `aria-expanded` for each group:

```elixir
# In sidebar.ex render:
expanded = group_expanded?(group, items)
# group_expanded? = true if group == "Billing" (always) OR any item has badge > 0
```

**Footgun:** Do NOT put the collapse toggle inside a LiveView `handle_event` — it would require a round trip for every sidebar open/close, which is noticeable latency. Pure client-side JS + `localStorage` is the right call here (the CONTEXT.md decision also says "persist manual toggle in localStorage" not "via LiveView event").

**Footgun:** The `sidebar.ex` component currently uses `Enum.chunk_by` which preserves order but does not expose group-level metadata. You need to add group-level data (badge count, collapsible?) to the items map in `nav.ex`, and then change `grouped_items/1` to return `{group, items, group_meta}` tuples.

### 3. Nav Attention Badge Data Source (IA-02)

**Current state:** `dashboard_live.ex` computes `dashboard_stats/0` with `past_due_subscription_count` and `blocked_webhook_count`. [VERIFIED: dashboard_live.ex lines 234–270] The `attention_items/3` function derives the attention rows from those stats.

**The shared function approach:** Extract the badge-relevant counts into a new module `AccrueAdmin.AttentionCounts`:

```elixir
defmodule AccrueAdmin.AttentionCounts do
  @moduledoc false

  import Ecto.Query
  alias Accrue.Billing.{Query, Subscription}
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent

  @spec compute(any()) :: %{recovery: non_neg_integer(), developer: non_neg_integer()}
  def compute(_owner_scope) do
    %{
      recovery: Subscription |> Query.past_due() |> Repo.aggregate(:count, :id),
      developer:
        WebhookEvent
        |> where([e], e.status in [:failed, :dead])
        |> Repo.aggregate(:count, :id)
    }
  end
end
```

**Threading into sidebar via on_mount:** Add a new `on_mount` hook `AccrueAdmin.NavBadgeHook` (or compute inside `AuthHook` — but separate hooks are cleaner since `AuthHook` should stay auth-only):

```elixir
defmodule AccrueAdmin.NavBadgeHook do
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:default, _params, session, socket) do
    counts = AccrueAdmin.AttentionCounts.compute(socket.assigns[:current_owner_scope])
    {:cont, assign(socket, :nav_attention_counts, counts)}
  end
end
```

Register in `router.ex` `on_mount` list alongside `AuthHook`. Then `AppShell` receives `nav_attention_counts` via `socket.assigns` and passes it to `Nav.items/3` (add a third `counts` argument), which annotates each group item with a `:badge` field.

**Alternative (simpler, less refactor):** Pass counts directly to `AppShell` via a new attr, have `Nav.items/3` accept them. Either pattern works — the key constraint is: one DB query set, computed once per navigation, not per render.

**Footgun:** `dashboard_live.ex` already computes `dashboard_stats/0` with these same counts. After this phase, `DashboardLive` should call `AttentionCounts.compute/1` instead of its own inline query for the `past_due_subscription_count` and `blocked_webhook_count` fields, to keep them in sync. Otherwise two code paths can drift.

### 4. Work-Queue Default Filter via `push_patch` (IA-03)

**Current pattern:** All list LiveViews (`invoices_live.ex`, `subscriptions_live.ex`, `charges_live.ex`, `events_live.ex`) use `handle_params/3` that simply assigns params to the socket:

```elixir
def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end
```

`DataTable` live component reads `socket.assigns.params` and syncs its filter to URL query params. [VERIFIED: invoices_live.ex line 28, data_table.ex update/2 signature]

**The push_patch default-filter pattern:**

```elixir
@default_queue_params %{"status" => "open,uncollectible"}  # for invoices

def handle_params(params, _uri, socket) do
  if map_size(params) == 0 or (map_size(params) == 1 and Map.has_key?(params, "org")) do
    # No explicit filter params: push_patch to the default queue
    queue_params = maybe_merge_org(socket, @default_queue_params)
    {:noreply, push_patch(socket, to: socket.assigns.table_path <> "?" <> URI.encode_query(queue_params))}
  else
    {:noreply, assign(socket, :params, params)}
  end
end
```

**"All" escape hatch via filter_chip_bar:** The chip's `remove_href` field points to the bare path (no status param), which triggers `handle_params` with empty params... which triggers another `push_patch` to the default. This is a loop. The solution: introduce a sentinel param `?view=all` to distinguish "user explicitly requested all" from "no params (first load)".

```elixir
# "All" chip remove_href: "/invoices?view=all"
# handle_params: if params["view"] == "all" → don't push_patch, show all rows
def handle_params(%{"view" => "all"} = params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end
def handle_params(params, _uri, socket) when map_size(params) == 0 do
  {:noreply, push_patch(socket, to: ...default_queue_url...)}
end
def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end
```

**filter_chip_bar chip structure for work-queue + All:**

```elixir
# Persona-queue chip (active when status param matches queue):
%{id: :status_queue, label: "Queue", value: "open · uncollectible",
  tone: :cobalt, active: queue_active?(@params), remove_href: "/invoices?view=all"}

# "All" chip (active when view=all):
%{id: :view_all, label: "All", tone: :slate,
  active: Map.get(@params, "view") == "all", remove_href: "/invoices"}
```

**Footgun — DataTable filter shape:** `DataTable` reads `socket.assigns.params` and passes them to the `query_module.list/1`. The `status` filter field in invoices accepts a single status value (`:status` → string). For multi-status queues ("open,uncollectible"), the query module must support comma-separated or list-format status. Check `AccrueAdmin.Queries.Invoices.list/1` filter parsing — it may need extension to handle `["open", "uncollectible"]`. This is a real gap to verify in the plan.

**Footgun — org scoping:** The `push_patch` target URL must preserve the `?org=` param if present. Use `ScopedPath.build/4` rather than raw string concatenation.

### 5. Lightweight `/events/:id` Detail (IA-04)

**Current state:** `events_live.ex` is a list-only LiveView. No `/events/:id` route exists in `router.ex`. [VERIFIED: router.ex line 76 shows `live("/events", ...)` with no `/:id` sibling]

**Decision area:** CONTEXT.md says "planner's call — full LiveView vs. focus drawer reusing `detail_drawer.ex`." Research recommendation: **full LiveView** (simpler, consistent with all other detail screens, no state management needed for drawer open/close).

**Why full LiveView over drawer:**
- All 7 other entity types use a full `live("/entity/:id", EntityLive, :show)` route — consistency reduces cognitive overhead.
- `detail_drawer.ex` is currently stateless (`open` attr); using it for `/events/:id` would need `push_patch` or `navigate` to close, adding complexity.
- The event detail is read-only (no actions) — the simplest shape is fine.
- Motion (drawer animation) is deferred to Phase D anyway, so a drawer's motion advantage doesn't apply here.

**Minimal `EventLive` shape:**

```elixir
defmodule AccrueAdmin.Live.EventLive do
  use Phoenix.LiveView
  # ... standard assign_shell pattern ...

  def mount(%{"id" => event_id}, session, socket) do
    # Load event from Accrue.Events.Event
    # Load related entity (customer/subscription/invoice) via subject_type + subject_id
    # Load source webhook via caused_by_webhook_event_id
  end

  # Related card items (bidirectional):
  # - Source webhook (if caused_by_webhook_event_id present) → /webhooks/:id
  # - Subject entity (customer/subscription/invoice/charge) → entity detail path
end
```

**Threading the Webhook→Event→entity path:**

`webhook_live.ex` already has `derived_events/1` (lines 310–315) which queries `Event` by `caused_by_webhook_event_id`. This renders as a `Timeline` section today. The gap is that event rows in the timeline are not navigable — there's no `/events/:id` to link to. Once `EventLive` exists:

1. Update `webhook_live.ex` `derived_event_timeline/3` to include an `href` to `/events/:id` for each event.
2. `EventLive` renders a Related card with: source webhook link (`/webhooks/:webhook_id`) + affected entity link (use `subject_href` logic already in `events_live.ex` lines 243–258).
3. The entity's own Related card already links back to events via `/events?subject_type=X&subject_id=Y` (customer_live.ex does this on line 490). That is bidirectional enough.

**Footgun:** The `events_live.ex` `subject_href/3` function (lines 243–258) handles Customer/Subscription/Invoice/Charge/WebhookEvent → links. This logic is reusable in `EventLive` — extract to `AccrueAdmin.EventSubjectPath` or copy.

### 6. Customer-360 "More ▾" Overflow Menu (IA-05)

**Current state:** `customer_live.ex` has `@tabs ~w(subscriptions invoices charges payment_methods entitlements events metadata)` (line 34). The `tabs/4` private function creates a flat list passed to `Tabs.tabs/1`. `Tabs` component renders all tabs as `<a>` links. [VERIFIED: customer_live.ex, tabs.ex]

**The current tab relabel issue:** The "charges" tab must become "Payments" (label change), and the `href` uses `/charges/:id` → must become `/payments/:id`. The tab `id` atom stays `"charges"` internally (or can become `"payments"` since it's just a string in `@tabs`).

**"More ▾" implementation — server-side assign approach:**

The "More ▾" trigger needs open/close state. Options:

**Option A — Server-side `is_more_open` assign (recommended):**

```elixir
# In mount:
|> assign(:more_tabs_open, false)

# New handle_event:
def handle_event("toggle_more_tabs", _params, socket) do
  {:noreply, assign(socket, :more_tabs_open, !socket.assigns.more_tabs_open)}
end
```

In `customer_live.ex` render, replace `Tabs.tabs/1` usage with an inline tabs block that renders the primary tabs + "More ▾" trigger. The `Tabs` component is simple enough (29 lines) that inlining this variation is acceptable. Alternatively extend `Tabs` to accept an `overflow_tabs` list attr.

**Option B — CSS-only disclosure (simpler, no state, no motion):**

Since Phase D defers motion, an instant open/close via CSS `:focus-within` or a `<details>`/`<summary>` element is acceptable for v1.51. However, `<details>` has limited styling control across browsers for the desired menu surface, and CONTEXT.md requires `aria-haspopup="menu"` + `aria-expanded`. This steers toward Option A.

**Recommended: Option A** — server-side `is_more_open` assign. It's idiomatic LiveView, provides full a11y control, and avoids CSS browser quirks.

**The active recessed-tab case:** When the active tab is in the "More" group (e.g., user is on the Entitlements tab), the "More ▾" trigger must show `.ax-tab-active` underline. Derive this from: `active_tab_in_more? = @tab in ~w(payment_methods entitlements events metadata)`.

**Footgun:** When the user navigates to a recessed tab (via the "More" menu), the menu must close. Since navigation goes through `handle_params` (tab switching uses href links + handle_params), just reset `more_tabs_open: false` in `handle_params`.

**A11y requirement (from UI-SPEC):** `<button aria-haspopup="menu" aria-expanded={@more_tabs_open}>More ▾</button>`. The menu items are links with role `menuitem`. Esc closes: add a JS keydown handler or rely on `phx-key="Escape" phx-window-keydown="close_more_tabs"` on a wrapper.

### 7. `related_resources.ex` — All 8 Detail Screens (IA-04)

**Current state (confirmed by reading each file):**

| Screen | Related card today | Gap |
|--------|--------------------|-----|
| `customer_live.ex` | YES — subscriptions, invoices, charges, activity | Charges link → `/charges/:id`, not `/payments/:id` yet |
| `webhook_live.ex` | NO — has "linked activity" plain link, derived events Timeline | NO Related card; no link to `/events/:id` (doesn't exist yet) |
| `subscription_live.ex` | — (not read — assumed from pattern) | Likely has customer link; may lack invoice/charge links |
| `invoice_live.ex` | — (not read — assumed) | Likely has customer/subscription links |
| `charge_live.ex` / (payments) | — (not read — assumed) | Likely has customer/invoice links |
| `coupon_live.ex` | — (not read — assumed) | Likely minimal or absent |
| `promotion_code_live.ex` | — (not read — assumed) | Likely minimal or absent |
| `connect_account_live.ex` | — (not read — assumed) | May be absent |

[ASSUMED for the 6 screens not directly read — planner should verify during implementation]

**`related_resources.ex` component is unchanged** — its API (`items` list of `%{icon:, label:, href:, value:}`) is reused as-is. The only work is in each detail LiveView's `related_items/...` function. [VERIFIED: related_resources.ex full read]

**Webhook detail Related card items to add:**

```elixir
# webhook_live.ex related_items/3 — build from derived_events + webhook entity
defp related_items(webhook, derived_events, mount_path, scope) do
  derived_event_links =
    Enum.map(derived_events, fn event ->
      %{
        icon: :events,
        label: "Event",
        value: event.type,
        href: ScopedPath.build(mount_path, "/events/#{event.id}", scope)
      }
    end)
    |> Enum.take(3)  # cap to avoid huge cards

  derived_event_links
end
```

The "all events from this webhook" link is already present in `webhook_live.ex` line 224 (the "View linked activity" plain link). The new Related card supplements, not replaces, that.

### 8. Visible Global Search Field (IA-01)

**Current state:** `GlobalSearch` is a `LiveComponent` that renders `hidden` when `is_open: false` (line 95 of global_search.ex: `class={if @is_open, do: "ax-command-palette-wrapper", else: "hidden"}`). The topbar has an `.ax-search-trigger` button that sends `"open"` to the component via `phx-target="#global-search"`. [VERIFIED: topbar.ex lines 26–35, global_search.ex line 95]

**What needs to change:**

1. **Topbar:** The `.ax-search-trigger` button is already styled as a visible pill with text "Search customers, invoices, events…" and a `⌘K` kbd hint. It is already a visible element — but it is a `<button>`, not an `<input>`. The CONTEXT.md requirement is "render GlobalSearch as a visible labeled input." The existing trigger already satisfies the visual/discoverability intent (it reads as a search field to users). The simplest approach: update the placeholder text to "Search customers, invoices… ⌘K" (spec requires this exact text) and confirm the button is already using `.ax-search-trigger` which has the right visual appearance. **Minimal change: update the placeholder text in `topbar.ex` line 33.**

2. **Home page search field:** `dashboard_live.ex` needs a prominent `.ax-input`-based field in the search zone (above or below the launchers — the UI-SPEC says "Home hero/search zone"). This is a static `<button>` or `<input>` that, on focus/click, fires `phx-click="open" phx-target="#global-search"` to open the GlobalSearch command palette. Use `.ax-input` with leading search icon + placeholder "Search customers, invoices… ⌘K".

**Footgun:** Adding an actual `<input type="text">` to Home that fires `phx-change` or `phx-focus` to open the global search requires careful handling — if the input is in the regular DOM (not inside the GlobalSearch LiveComponent), its `phx-change` events go to the parent LiveView (`DashboardLive`), not to `GlobalSearch`. The cleanest approach is a **non-interactive styled input** (styled `<button>` with `role="search"` and a visible `aria-label`) that fires `phx-click="open" phx-target="#global-search"` — same as the topbar trigger, just larger and more prominent. This avoids the LiveComponent targeting complexity entirely.

### 9. Home Verb Relabels (IA-01)

**Current state in copy.ex:**

| Fn | Current string | Required string |
|----|----------------|-----------------|
| `home_launcher_customers_title/0` | "Find a customer" | "Look up a customer" |
| `home_launcher_invoices_title/0` | "Work open invoices" | "Clear the invoice queue" |
| `home_launcher_recovery_title/0` | "Recover failed payments" | "Recover at-risk revenue" |
| `home_launcher_developer_title/0` | "Debug webhooks & events" | "Investigate an incident" |

[VERIFIED: copy.ex grep lines 698–712]

**These are 4 one-line string changes in `copy.ex`.** No template changes needed. Low risk, but the `NavTest` in `nav_test.exs` and any `CopyTest` assertions on these strings must be updated if they assert on the exact current values. Check `test/accrue_admin/live/dashboard_live_test.exs` for any launchers copy assertions.

**GlobalSearch command palette quick-links** (lines 138–145 of global_search.ex) also use the old strings: "Find a customer", "Work open invoices", "Recover failed payments", "Debug dead-letter webhooks". These are NOT going through Copy module — they are inline strings. Update them to match the new verb labels.

### 10. Compliance Actor-Lens Chip (IA-07)

**Current state:** `events_live.ex` already has an `actor_type` filter field (line 116: `%{id: :actor_type, label: ..., ...}`). The DataTable syncs this to the URL. [VERIFIED: events_live.ex]

**The "By actor" chip is not a new filter mechanism** — it is a persistent quick-access chip in the `filter_chip_bar` that pre-populates the `actor_type` filter. Since `filter_chip_bar` renders only when `has_items` (i.e., some chip is active), this chip should always render (like the work-queue chips on list screens) so it's discoverable even when no filter is active.

**Implementation sketch:**

```elixir
# In events_live.ex render, above the DataTable:
<FilterChipBar.filter_chip_bar
  items={compliance_lens_chips(@params)}
  label="Quick filters"
/>

# compliance_lens_chips/1:
defp compliance_lens_chips(params) do
  actor_active = Map.has_key?(params, "actor_type") and params["actor_type"] != ""
  [%{
    id: :by_actor,
    label: "By actor",
    tone: if(actor_active, do: :cobalt, else: :slate),
    active: true,  # always render
    href: if(actor_active, do: nil, else: "/events?actor_type=admin"),
    remove_href: if(actor_active, do: "/events", else: nil)
  }]
end
```

**Footgun:** `filter_chip_bar` currently only renders chips when `active` is true (via `chip_active?/1` which checks `Map.get(item, :active, true)`). The default is `true`, so chips are rendered unless explicitly `active: false`. If we always render the "By actor" chip as `active: true`, it will always show. This is the desired behavior (always visible as a "saved lens" toggle).

**Footgun:** The "By actor" chip needs an `href` (for activation) and a `remove_href` (for deactivation). But `filter_chip_bar` chips render a "Clear" link only when `remove_href` is set. When inactive, the chip should link to activate (apply actor filter); when active, "Clear" removes it. This requires a slight departure from the current chip API — chips are currently "active filters you can remove" not "available lenses you can apply." The planner should account for this: either extend `filter_chip_bar` to support an `href` attribute for inactive chips, or render the "By actor" chip as a standalone styled link outside `filter_chip_bar` when inactive.

---

## Common Pitfalls

### Pitfall 1: `push_patch` Loop on Default Filter
**What goes wrong:** `handle_params` with empty params triggers `push_patch` to `?status=open`, which triggers `handle_params` again with the status param, which is fine — but if the "All" chip points back to the bare path, navigating to "All" triggers another `push_patch` back to the queue, creating a loop.
**Why it happens:** The default-filter logic only checks for empty params without distinguishing "user requested all" from "first load."
**How to avoid:** Introduce a `?view=all` sentinel param that short-circuits the default-filter push_patch.
**Warning signs:** Infinite re-renders / handle_params called twice on page load.

### Pitfall 2: Redirect Controller Missing `mount_path`
**What goes wrong:** `/charges` redirect hardcodes `/billing/payments` instead of `{mount_path}/payments`, breaking hosts that mount at a different path.
**Why it happens:** The mount path is a runtime config value, not a compile-time constant.
**How to avoid:** Read mount path from conn assigns (injected by `BrandPlug`) or from the `accrue_admin` session key. Test with a non-`/billing` mount path.

### Pitfall 3: NavBadgeHook DB Queries in Test Environment
**What goes wrong:** Adding `NavBadgeHook` to the `on_mount` list means every LiveView test mount runs DB queries for attention counts, which may fail if the test DB is empty or if the test doesn't set up the correct schema.
**Why it happens:** `on_mount` hooks run eagerly.
**How to avoid:** The hook should fail gracefully (return `%{recovery: 0, developer: 0}` on error); or stub in tests via mock. Since the project uses `Mox` and the queries are DB-level, make sure the test repo/sandbox is connected.

### Pitfall 4: Sidebar Collapse JS Hook Not Registered
**What goes wrong:** `phx-hook="SidebarCollapse"` renders in HTML but the hook is not in the `hooks` map passed to `LiveSocket`.
**Why it happens:** Adding a new hook file without updating `app.js`.
**How to avoid:** Always update the `hooks` map in `app.js` when adding a new hook. Verify in the browser console: LiveView will warn about missing hooks.

### Pitfall 5: `charges` Tab ID in customer_live
**What goes wrong:** Changing `@tabs` from `"charges"` to `"payments"` in `customer_live.ex` breaks `normalize_tab/1` which checks `tab in @tabs`, and breaks any deep-link URLs with `?tab=charges`.
**Why it happens:** The internal tab ID is used in URL params and in the `@tabs` guard.
**How to avoid:** Either keep the internal ID as `"charges"` (display label only changes to "Payments") and only update the `humanize/1` label; or update the tab ID to `"payments"` and add a backward-compat `normalize_tab` clause: `defp normalize_tab("charges"), do: "payments"`.

### Pitfall 6: Multi-Status Filter in DataTable Query Modules
**What goes wrong:** Work-queue defaults require filtering on multiple statuses (e.g., invoices: `open + uncollectible`). The current `Invoices.list/1` query module may only handle a single `:status` atom.
**Why it happens:** DataTable query modules were designed for single-value URL params.
**How to avoid:** Extend the query module to accept a comma-joined status string and split it; or use a list-format URL param like `status[]=open&status[]=uncollectible`. Verify `AccrueAdmin.Queries.Invoices.list/1` filter parsing before implementing — this may require a query-module change.

### Pitfall 7: Asset Build Not Run After CSS Changes
**What goes wrong:** New CSS classes (`.ax-badge-warning`, `.ax-tab-more-menu`, etc.) exist in `app.css` but the committed bundle `priv/static/accrue_admin.css` is stale.
**Why it happens:** The bundle is committed; source changes don't auto-rebuild.
**How to avoid:** Run `cd accrue_admin && mix accrue_admin.assets.build` after every CSS edit and commit `priv/static`. This is a required step in every wave that touches CSS/JS.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-entity navigation links | Custom link builder | `ScopedPath.build/3,4` (already in codebase) | Handles `?org=` scoping; already used throughout |
| URL-param-synced filters | Custom filter state machine | `DataTable` + `handle_params` + `push_patch` | Existing tested mechanism; DataTable owns filter URL sync |
| Admin auth context | Hand-rolling session parsing | `AuthHook.on_mount` + `OwnerScope.resolve/2` | Already handles org scoping, session keys, redirect-on-failure |
| Search results | Re-implementing async search | `GlobalSearch` LiveComponent (reuse as-is) | Already handles async parallel search, keyboard nav, ⌘K |
| Attention count queries | Parallel query set | `AttentionCounts.compute/1` (new shared fn, reuses existing query shapes from dashboard_live) | DRY; prevents drift between sidebar badge and dashboard attention rail |
| Redirect handling | JavaScript-based redirects | Phoenix `redirect/2` in a plain controller | Server-side redirect is indexable, works without JS, correct HTTP semantics |

---

## Code Examples

### Example 1: Extended nav item with badge field

```elixir
# nav.ex — add badge field to specialist group items
# Source: codebase inspection of nav.ex + dashboard_live.ex attention query shapes

defmodule AccrueAdmin.Nav do
  def items(mount_path, current_path, attention_counts \\ %{}) do
    org = org_slug(current_path)
    recovery_badge = Map.get(attention_counts, :recovery, 0)
    developer_badge = Map.get(attention_counts, :developer, 0)

    [
      %{label: "Home", href: nav_href(mount_path, "", org), icon: :home,
        group: nil, collapsible: false, badge: nil},
      # Billing group — always expanded, no badge
      %{label: "Customers", href: nav_href(mount_path, "/customers", org),
        icon: :users, group: "Billing", collapsible: false, badge: nil},
      %{label: "Subscriptions", href: nav_href(mount_path, "/subscriptions", org),
        icon: :subscriptions, group: "Billing", collapsible: false, badge: nil},
      %{label: "Invoices", href: nav_href(mount_path, "/invoices", org),
        icon: :invoices, group: "Billing", collapsible: false, badge: nil},
      %{label: "Payments", href: nav_href(mount_path, "/payments", org),  # /payments not /charges
        icon: :payments, group: "Billing", collapsible: false, badge: nil},
      # Recovery — collapsible, warning badge
      %{label: "Recovery", href: nav_href(mount_path, "/analytics/recovery", org),
        icon: :recovery, group: "Recovery", collapsible: true,
        badge: if(recovery_badge > 0, do: recovery_badge, else: nil)},
      # Developer — collapsible, danger badge
      %{label: "Webhooks", href: nav_href(mount_path, "/webhooks", org),
        icon: :webhooks, group: "Developer", collapsible: true,
        badge: if(developer_badge > 0, do: developer_badge, else: nil)},
      %{label: "Event log", href: nav_href(mount_path, "/events", org),
        icon: :events, group: "Developer", collapsible: true, badge: nil},
      # Catalog — collapsible, no badge for v1.51
      %{label: "Coupons", href: nav_href(mount_path, "/coupons", org),
        icon: :coupons, group: "Catalog", collapsible: true, badge: nil},
      %{label: "Promotion codes", href: nav_href(mount_path, "/promotion-codes", org),
        icon: :promotions, group: "Catalog", collapsible: true, badge: nil},
      # Connect — standalone, no group
      %{label: "Connect", href: nav_href(mount_path, "/connect", org),
        icon: :connect, group: "Connect", collapsible: false, badge: nil}
    ]
  end
end
```

### Example 2: Sidebar group rendering with collapse support

```elixir
# sidebar.ex — collapsible group section (HEEx sketch)
# Source: codebase inspection of sidebar.ex + UI-SPEC §1

# For each {group, items, group_meta} in grouped_items(@items):
# group_meta = %{collapsible: bool, badge: integer | nil, tone: :warning | :danger | nil}

<section
  :if={group}
  class="ax-sidebar-nav-group"
  id={"sidebar-group-#{slugify(group)}"}
  phx-hook="SidebarCollapse"
  data-group={slugify(group)}
  data-controls={"sidebar-group-links-#{slugify(group)}"}
  aria-expanded={to_string(group_initially_expanded?(group_meta))}
>
  <button
    :if={group_meta.collapsible}
    type="button"
    data-collapse-toggle="true"
    class="ax-sidebar-group-label ax-sidebar-group-toggle"
    aria-expanded={to_string(group_initially_expanded?(group_meta))}
    aria-controls={"sidebar-group-links-#{slugify(group)}"}
  >
    <span><%= group %></span>
    <span :if={group_meta.badge} class={badge_class(group_meta.tone)}
          aria-label={badge_aria_label(group, group_meta.badge)}>
      <%= group_meta.badge %>
    </span>
    <.icon name={:chevron_right} size="sm" class="ax-sidebar-group-chevron" />
  </button>
  <p :if={not group_meta.collapsible} class="ax-sidebar-group-label"><%= group %></p>

  <div
    id={"sidebar-group-links-#{slugify(group)}"}
    hidden={not group_initially_expanded?(group_meta)}
  >
    <a :for={item <- items} href={item.href} class={nav_class(item, @current_path)}>
      <.icon name={item.icon} size="sm" class="ax-sidebar-link-icon" />
      <span class="ax-sidebar-link-label"><%= item.label %></span>
    </a>
  </div>
</section>
```

### Example 3: Work-queue default push_patch pattern

```elixir
# invoices_live.ex — default filter via push_patch
# Source: codebase inspection, UI-SPEC §3 contract

@default_queue_status "open,uncollectible"

def handle_params(%{"view" => "all"} = params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end

def handle_params(params, _uri, socket) when map_size(params) == 0 do
  default_params =
    case socket.assigns[:current_owner_scope] do
      %{mode: :organization, organization_slug: slug} when is_binary(slug) ->
        %{"status" => @default_queue_status, "org" => slug}
      _ ->
        %{"status" => @default_queue_status}
    end
  {:noreply, push_patch(socket, to: socket.assigns.table_path <> "?" <> URI.encode_query(default_params))}
end

def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end
```

### Example 4: Route redirect outside live_session

```elixir
# router.ex — inside the scope mount_path, as: :accrue_admin block, OUTSIDE live_session
# Source: codebase inspection of router.ex structure + Phoenix routing docs [CITED: hexdocs.pm/phoenix]

scope mount_path, as: :accrue_admin do
  # ... existing asset routes ...

  pipe_through(:accrue_admin_browser)

  # Redirect old /charges routes to /payments (IA-06, no breaking bookmarks)
  get("/charges", AccrueAdmin.RedirectController, :charges_index)
  get("/charges/:id", AccrueAdmin.RedirectController, :charges_show)

  live_session :accrue_admin,
    root_layout: {AccrueAdmin.Layouts, :root},
    on_mount: on_mount,
    session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]} do
    # /charges routes REMOVED; replaced by /payments:
    live("/payments", AccrueAdmin.Live.ChargesLive, :index)
    live("/payments/:id", AccrueAdmin.Live.ChargeLive, :show)
    live("/events/:id", AccrueAdmin.Live.EventLive, :show)  # NEW
    # ... rest unchanged ...
  end
end
```

### Example 5: Customer-360 tab tiering with "More ▾"

```elixir
# customer_live.ex — tab structure (HEEx sketch)
# Source: codebase inspection of customer_live.ex + UI-SPEC §4

@primary_tabs ~w(subscriptions invoices charges)
@more_tabs ~w(payment_methods entitlements events metadata)

# In render/1:
<nav class="ax-tabs" aria-label="Customer sections">
  <a :for={tab <- @primary_tab_list}
     href={tab.href}
     class={["ax-tab", @tab == tab.id && "ax-tab-active"]}
     aria-current={if(@tab == tab.id, do: "page", else: nil)}>
    <span><%= tab.label %></span>
    <span :if={tab.count} class="ax-tab-count"><%= tab.count %></span>
  </a>

  <%# "More ▾" trigger %>
  <div class="ax-tab-more-wrapper">
    <button
      type="button"
      class={["ax-tab ax-tab-more-trigger", @tab in @more_tabs && "ax-tab-active"]}
      aria-haspopup="menu"
      aria-expanded={to_string(@more_tabs_open)}
      phx-click="toggle_more_tabs"
    >
      More <.icon name={:chevron_down} size="sm" />
    </button>
    <ul :if={@more_tabs_open} class="ax-tab-more-menu" role="menu">
      <li :for={tab <- @more_tab_list} role="none">
        <a
          href={tab.href}
          class="ax-tab-more-item"
          role="menuitem"
          aria-current={if(@tab == tab.id, do: "page", else: nil)}
        >
          <%= tab.label %>
          <span :if={tab.count} class="ax-tab-count"><%= tab.count %></span>
        </a>
      </li>
    </ul>
  </div>
</nav>

# Close on Esc:
# Add phx-window-keydown="close_more_tabs" phx-key="Escape" to the wrapper div
# Or handle in a JS hook (SidebarCollapse hook can be extended to handle Esc for menus)
```

---

## Token Gaps (Confirmed from UI-SPEC)

The UI-SPEC §Token Gaps section identifies these gaps. Research confirms they are genuine (not in Phase 174 output):

| Gap | Required For | Resolution |
|-----|--------------|------------|
| `.ax-badge-warning` / `.ax-badge-danger` | Attention badges on Recovery/Developer groups | Add CSS modifier classes composing from `--ax-warning`/`--ax-warning-readable` and `--ax-danger`/`--ax-danger-readable`. All tokens exist. |
| `.ax-sidebar-group-chevron` | Collapsible group header chevron | Add CSS class with `transform: rotate(0deg)` → `rotate(90deg)` on `[aria-expanded="true"]`; use `--ax-transition-transform` (Phase 174 token). |
| `.ax-tab-more-menu` | "More ▾" dropdown surface | Add CSS composing `--ax-elevated`, `--ax-border`, `--ax-radius-md`, `--ax-shadow-md`, `--ax-z-popover`, `--ax-space-sm`. |
| `.ax-sidebar-group-toggle` | Collapsible group button (reset default button styles) | New class to strip button chrome and match group-label appearance. |

All gaps resolve from existing tokens — no raw hex or px values permitted.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir standard) + Phoenix.LiveViewTest |
| Config file | `accrue_admin/test/test_helper.exs` |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/nav_test.exs test/accrue_admin/live/invoices_live_test.exs --seed 0` |
| Full suite command | `cd accrue_admin && mix test --seed 0` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| IA-01 | Verb relabels on Home launchers | unit | `mix test test/accrue_admin/live/dashboard_live_test.exs -x` | ✅ |
| IA-01 | Visible search field present in topbar | unit (component) | `mix test test/accrue_admin/components/navigation_components_test.exs -x` | ✅ |
| IA-02 | Nav items include `badge` and `collapsible` fields | unit | `mix test test/accrue_admin/nav_test.exs -x` | ✅ (needs new assertions) |
| IA-02 | Sidebar renders collapsible button with `aria-expanded` | unit (component) | `mix test test/accrue_admin/components/navigation_components_test.exs -x` | ✅ (needs new assertions) |
| IA-03 | InvoicesLive push_patches to default queue on bare load | integration (LiveView) | `mix test test/accrue_admin/live/invoices_live_test.exs -x` | ✅ |
| IA-03 | "All" chip clears queue filter and prevents re-redirect | integration | `mix test test/accrue_admin/live/invoices_live_test.exs -x` | ✅ (needs new tests) |
| IA-04 | WebhookLive Related card links to `/events/:id` | integration | `mix test test/accrue_admin/live/webhook_live_test.exs -x` | ✅ (needs new assertions) |
| IA-04 | EventLive renders Related card with source webhook + entity links | integration | `mix test test/accrue_admin/live/event_live_test.exs -x` | ❌ Wave 0 |
| IA-05 | CustomerLive renders primary tabs + "More ▾" button | integration | `mix test test/accrue_admin/live/customer_live_test.exs -x` | ✅ (needs new assertions) |
| IA-05 | "More ▾" toggle shows/hides recessed tabs | integration | `mix test test/accrue_admin/live/customer_live_test.exs -x` | ✅ (needs new assertions) |
| IA-06 | GET /charges redirects 302 to /payments | router test | `mix test test/accrue_admin/router_test.exs -x` | ✅ |
| IA-06 | GET /charges/:id redirects 302 to /payments/:id | router test | `mix test test/accrue_admin/router_test.exs -x` | ✅ (needs new test) |
| IA-07 | EventsLive renders "By actor" chip | integration | `mix test test/accrue_admin/live/events_live_test.exs -x` | ✅ (needs new assertion) |

### Sampling Rate
- **Per task commit:** `cd accrue_admin && mix test --seed 0 2>&1 | tail -5`
- **Per wave merge:** Full suite: `cd accrue_admin && mix test --seed 0`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/accrue_admin/live/event_live_test.exs` — covers IA-04 EventLive routing and Related card
- [ ] `test/accrue_admin/router_test.exs` — add redirect coverage for `/charges` → `/payments` and `/charges/:id` → `/payments/:id`

*(All other test files exist — assertions need extension, not new files.)*

---

## Environment Availability

> This phase is code/config-only changes with one CSS/JS build step.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix accrue_admin.assets.build` | CSS/JS bundle rebuild after every CSS/JS change | ✓ | (project custom Mix task) | — |
| Chrome/Chromium | `npm run e2e:visuals:png-only` (screenshot audit) | ✓ (assumed — Phase 174 shipped Playwright tests) | — | Skip screenshot audit; run axe-only |
| PostgreSQL | DB queries in tests + on_mount hooks | ✓ (Docker Compose) | 14+ | — |

**Missing dependencies with no fallback:** None that would block this phase.

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Auth unchanged — AuthHook continues to gate all LiveViews |
| V3 Session Management | no | Session unchanged |
| V4 Access Control | no | No new data endpoints; read-only queries only |
| V5 Input Validation | yes (minor) | Default queue status values are hardcoded strings, not user input; redirect URL construction uses known mount_path + static suffixes — not user-controlled |
| V6 Cryptography | no | No crypto changes |

**Open Redirect check (IA-06):** The redirect controller must construct its target URL from a known `mount_path` constant (not from `params["return_to"]` or any user-controlled input). The `:id` param in `/charges/:id` → `/payments/:id` is a path segment — use `URI.encode/1` on it before interpolating into the redirect URL to prevent path traversal.

---

## Open Questions

1. **Multi-status filter in DataTable query modules**
   - What we know: `DataTable` passes `socket.assigns.params` to `query_module.list/1`; current filter fields accept single `:status` values.
   - What's unclear: Whether `Invoices.list/1` and `Subscriptions.list/1` support multi-value status filtering (comma-joined string or list-format param).
   - Recommendation: Planner should read `accrue_admin/lib/accrue_admin/queries/invoices.ex` and `subscriptions.ex` before writing the work-queue default implementation. If multi-status is unsupported, a query-module extension task must be added to Wave 1.

2. **Related-resources coverage on 6 unread detail screens**
   - What we know: `customer_live.ex`, `webhook_live.ex` fully read. 6 others (subscription, invoice, charge, coupon, promotion_code, connect_account) assumed to have varying Related card coverage.
   - What's unclear: Current state of Related cards on each of those 6.
   - Recommendation: Planner should read all 6 detail LiveViews in Wave 1 to audit existing Related card items and determine the delta needed for IA-04.

3. **`localStorage` key collision risk**
   - What we know: JS hook will use keys like `ax-sidebar-recovery`, `ax-sidebar-developer`, `ax-sidebar-catalog`.
   - What's unclear: Whether hosts with multiple accrue_admin mounts (e.g., `/billing` and `/billing-org`) share localStorage and would have unexpected collapse state cross-contamination.
   - Recommendation: Prefix the localStorage key with `mount_path` (e.g., `ax-sidebar-billing-recovery`) using `this.el.closest("[data-mount-path]").dataset.mountPath`. The `ax-shell` div already has `data-mount-path={@mount_path}` (confirmed in `app_shell.ex` line 24).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Subscription and invoice query modules do not currently support multi-status filtering | §4 Work-queue defaults | Low risk: query module extension is additive and well-scoped |
| A2 | 6 detail LiveViews (subscription, invoice, charge, coupon, promotion_code, connect_account) have partial or absent Related card coverage | §7 Related resources | Low risk: coverage audit is easy to do during implementation; any gaps are additive fills |
| A3 | Phase 174 shipped `--ax-transition-transform` token used for sidebar group chevron rotation | §Token gaps | Medium risk: if token name differs, executor must use actual token name from theme.css |

---

## Sources

### Primary (HIGH confidence — codebase inspection)
- `accrue_admin/lib/accrue_admin/nav.ex` — current nav item structure (verified full file)
- `accrue_admin/lib/accrue_admin/components/sidebar.ex` — current stateless render (verified full file)
- `accrue_admin/lib/accrue_admin/router.ex` — router macro + live_session structure (verified full file)
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — attention query shapes (verified full file)
- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — tab structure + related_items (verified full file)
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` — derived_events query (verified full file)
- `accrue_admin/lib/accrue_admin/live/events_live.ex` — filter_fields + no :id route (verified full file)
- `accrue_admin/lib/accrue_admin/components/related_resources.ex` — API (verified full file)
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` — chip API (verified full file)
- `accrue_admin/lib/accrue_admin/components/tabs.ex` — simple functional component (verified full file)
- `accrue_admin/lib/accrue_admin/components/app_shell.ex` — how GlobalSearch is mounted (verified full file)
- `accrue_admin/lib/accrue_admin/components/topbar.ex` — current search trigger (verified full file)
- `accrue_admin/lib/accrue_admin/components/global_search.ex` — toggle/open/close pattern (verified full file)
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` — drawer shape (verified full file)
- `accrue_admin/assets/js/app.js` — hooks registration pattern (verified full file)
- `accrue_admin/assets/js/hooks/command_palette.js` — hook lifecycle pattern (verified full file)
- `accrue_admin/assets/js/hooks/accrue_shell_nav.js` — document-level JS pattern (verified full file)
- `accrue_admin/lib/accrue_admin/auth_hook.ex` — on_mount hook shape (verified full file)
- `accrue_admin/lib/accrue_admin/copy.ex` — launcher copy functions (verified via grep)
- `accrue_admin/test/accrue_admin/nav_test.exs` — existing test assertions (verified full file)
- `.planning/phases/175-b-persona-driven-ia-spine/175-CONTEXT.md` — locked decisions (verified full file)
- `.planning/phases/175-b-persona-driven-ia-spine/175-UI-SPEC.md` — design contract (verified full file)
- `.planning/research/v1.51-admin-ui-depth-design.md` — authoritative design source (verified full file)

### Secondary (MEDIUM confidence)
- Phoenix LiveView docs [CITED: hexdocs.pm/phoenix_live_view] — `push_patch/2`, `on_mount` hook registration pattern [ASSUMED based on training knowledge — standard LiveView 1.x API]
- Phoenix Router docs [CITED: hexdocs.pm/phoenix] — `redirect/2` in plain controllers, `get/3` routes outside `live_session` [ASSUMED based on training knowledge]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries are pre-installed; no new deps
- Architecture: HIGH — all patterns grounded in read source files
- Pitfalls: HIGH — derived from actual code structure observed
- Work-queue multi-status filter: MEDIUM — query module internals not fully read (A1)

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable codebase; 30-day validity)
