---
phase: 175-b-persona-driven-ia-spine
verified: 2026-06-04T09:20:47Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Sidebar collapsible groups collapse and expand in the browser; localStorage state persists on refresh"
    expected: "Recovery/Developer/Catalog groups collapse with animated chevron rotation; state survives page reload; Billing group has no toggle"
    why_human: "SidebarCollapse JS hook interaction and CSS animation cannot be verified by grep"
  - test: "Attention-count badges on sidebar group headers light up when dead-letter webhooks or at-risk subscriptions exist"
    expected: "Recovery badge (warning tone) appears when past_due subscriptions exist; Developer badge (danger tone) appears when failed/dead webhooks exist; badges absent when queues are empty"
    why_human: "Live DB-backed badge rendering requires runtime observation; badge tone and visibility are visual"
  - test: "Navigating Home → verb launcher → list screen lands on the work-queue view (not the all-items view)"
    expected: "Clicking 'Clear the invoice queue' reaches /invoices pre-filtered to open,uncollectible; the work-queue chip is cobalt-active; the All chip is slate/inactive"
    why_human: "Two-click persona path and chip visual state require browser navigation"
  - test: "Customer-360 More button reveals overflow tabs on click, closes on second click and on tab navigation"
    expected: "More button renders Payment methods, Entitlements, Events, Metadata links; aria-expanded toggles; clicking a More tab navigates and resets more_tabs_open to false"
    why_human: "Toggle behavior and DOM visibility require live browser interaction"
  - test: "Webhook detail → Event detail → affected entity link navigation thread is fully clickable"
    expected: "A webhook with derived events shows event links in Related card pointing to /events/:id; EventLive renders event type, actor, subject, and a 'Source webhook' link; the entity link routes to the correct entity screen"
    why_human: "Navigation chain across three screens requires a browser with seed data"
---

# Phase 175: B — Persona-Driven IA Spine Verification Report

**Phase Goal:** Replace the entity-shaped admin interior with a job/persona-shaped spine — one weighty primary Billing zone plus quiet specialist rooms that light up only when they have work — so each of the six personas reaches its job fast, no detail screen dead-ends, and no existing bookmark breaks. This resolves the v1.50 "disjoint" seam between a job-shaped Home and an entity-shaped interior.
**Verified:** 2026-06-04T09:20:47Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | From Home, each persona reaches their primary job via verb-labeled launcher or visible search field | VERIFIED | `dashboard_live.ex`: launchers use `Copy.home_launcher_*_title` ("Look up a customer", "Clear the invoice queue", "Recover at-risk revenue", "Investigate an incident"); visible `<div class="ax-home-search">` with `phx-click="open" phx-target="#global-search"` at line 99 |
| 2 | Sidebar shows weighted Billing zone + collapsible Recovery/Developer/Catalog + standalone Connect | VERIFIED | `nav.ex` items/3: Billing group items have `collapsible: false`; Recovery/Developer/Catalog items have `collapsible: true` with badge computation from `attention_counts`; Connect has `collapsible: false, group: "Connect"`; `sidebar.ex` renders `<button>` toggle for collapsible groups and `<p>` label for non-collapsible |
| 3 | Work-queue lists open pre-filtered to persona queue; "All" one chip away | VERIFIED | `invoices_live.ex` `@default_queue_status "open,uncollectible"` with 3-clause `handle_params` + `push_patch`; `subscriptions_live.ex` `@default_queue_status "past_due,canceling"`; `charges_live.ex` `@default_queue_status "failed"`; all three render `FilterChipBar.filter_chip_bar items={work_queue_chips(...)}` with view=all sentinel; `customers_live.ex` has NO queue default |
| 4 | Every detail screen has Related card; Webhook→Event→entity thread; Customer-360 tab tiering | VERIFIED | All 8 detail screens import and render `RelatedResources.related_resources`; `event_live.ex` exists at `/events/:id` with `related_items/3` linking to source webhook and subject entity; `webhook_live.ex` `related_items/4` links to `/events/#{event.id}`; `customer_live.ex` `@primary_tabs ~w(subscriptions invoices charges)`, `@more_tabs ~w(payment_methods entitlements events metadata)`, `tab_display_label("charges") -> "Payments"`, `more_tabs_open` assign, `handle_event("toggle_more_tabs")` |
| 5 | Redirected routes preserve bookmarks; compliance actor-lens on events | VERIFIED | `redirect_controller.ex` with `charges_index/2` and `charges_show/2`; router lines 62-63 `get "/charges"` and `get "/charges/:id"` → RedirectController; router lines 76-77 `/payments` and `/payments/:id` live routes; `events_live.ex` `compliance_chips/2` renders always-visible "By actor" chip with `active: true`; router_test.exs 6 tests 0 failures confirming 302 redirects |

**Score: 5/5 truths verified**

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/lib/accrue_admin/attention_counts.ex` | Shared fn returning recovery + developer counts | VERIFIED | `compute/1` returns `%{recovery: Subscription \|> Query.past_due() \|> Repo.aggregate(:count)`, `developer: WebhookEvent where status in [:failed, :dead] \|> Repo.aggregate(:count)}` |
| `accrue_admin/lib/accrue_admin/nav_badge_hook.ex` | on_mount assigns nav_attention_counts | VERIFIED | `on_mount(:default, ...)` calls `AttentionCounts.compute/1` with rescue fallback; assigns `nav_attention_counts` |
| `accrue_admin/lib/accrue_admin/nav.ex` | items/3 with attention_counts, :badge, :collapsible, /payments href | VERIFIED | `items/3` signature with `attention_counts \\ %{}`; all Billing items `collapsible: false`; specialist zones `collapsible: true`; Payments href uses `/payments` |
| `accrue_admin/lib/accrue_admin/components/sidebar.ex` | Collapsible group buttons + badges + SidebarCollapse hook | VERIFIED | `grouped_items/1` returns 3-tuples; collapsible groups render `<button>` with `aria-expanded`, `aria-controls`, `data-collapse-toggle`; badge renders when `group_meta.badge` is a positive integer; `phx-hook={if group_meta.collapsible, do: "SidebarCollapse"}` |
| `accrue_admin/assets/js/hooks/sidebar_collapse.js` | SidebarCollapse hook with localStorage + mount_path prefix | VERIFIED | 57-line hook with `mounted/0`, `destroyed/0`, `handleClick/1`, `setExpanded/1`, `storageKey/0`; key format `"ax-sidebar-" <> mountPath <> "-" <> group`; reads `data-mount-path` from `closest("[data-mount-path]")` |
| `accrue_admin/assets/js/app.js` | SidebarCollapse registered in hooks map | VERIFIED | Line 7 `import { SidebarCollapse } from "./hooks/sidebar_collapse"`, line 26 `hooks: { CommandPalette, SidebarCollapse }` |
| `accrue_admin/lib/accrue_admin/router.ex` | NavBadgeHook in @default_on_mount; /payments + /events/:id routes; /charges redirect routes | VERIFIED | Lines 9-11: `@default_on_mount [{AuthHook, :ensure_admin}, {NavBadgeHook, :default}]`; line 85 `/events/:id` EventLive; lines 62-63 `/charges` and `/charges/:id` RedirectController |
| `accrue_admin/lib/accrue_admin/controllers/redirect_controller.ex` | charges_index/2 + charges_show/2 | VERIFIED | Both actions present; `charges_show/2` applies `URI.encode(id)` for open-redirect prevention; mount_path-aware `String.replace_suffix` |
| `accrue_admin/assets/css/app.css` | ax-badge-warning, ax-badge-danger, ax-sidebar-group-chevron, ax-sidebar-group-toggle, ax-tab-more-menu | VERIFIED | All 5 classes present at lines 1204-1257+; token-sourced values |
| `accrue_admin/priv/static/accrue_admin.css` | Rebuilt bundle with new CSS classes | VERIFIED | File timestamp 2026-06-04; contains all 5 new CSS classes (1+1+3+4+1 occurrences respectively) |
| `accrue_admin/priv/static/accrue_admin.js` | Rebuilt bundle with SidebarCollapse | VERIFIED | Contains `SidebarCollapse` string in built bundle |
| `accrue_admin/lib/accrue_admin/live/event_live.ex` | EventLive at /events/:id | VERIFIED | Full LiveView: `mount/3` loads event by ID with 404-redirect; `render/1` renders type/actor/subject/Related card; `related_items/3` links source webhook and subject entity |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | Related card linking to /events/:id | VERIFIED | `related_items/4` maps `derived_events` to `%{href: ScopedPath.build(mount_path, "/events/#{event.id}", scope)}` |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | @primary_tabs + @more_tabs + more_tabs_open + More button | VERIFIED | `@primary_tabs ~w(subscriptions invoices charges)`, `@more_tabs ~w(payment_methods entitlements events metadata)`, `more_tabs_open` assign, `handle_event("toggle_more_tabs")`, `aria-haspopup="menu"`, `aria-expanded` |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | Always-visible By actor compliance chip | VERIFIED | `compliance_chips/2` returns `[%{id: :by_actor, label: "By actor", active: true, ...}]`; cobalt when active, slate when inactive; `activation_href` and `remove_href` URL-param synced |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | 3-clause handle_params + push_patch + work_queue_chips | VERIFIED | `@default_queue_status "open,uncollectible"`; view=all guard clause; default push_patch clause; passthrough clause; `FilterChipBar.filter_chip_bar items={work_queue_chips(...)}` |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | 3-clause handle_params + push_patch default past_due,canceling | VERIFIED | `@default_queue_status "past_due,canceling"`; same 3-clause pattern |
| `accrue_admin/lib/accrue_admin/live/charges_live.ex` | 3-clause handle_params + push_patch default failed + /payments path | VERIFIED | `@default_queue_status "failed"`; `table_path admin_path(admin, "/payments")`; `current_path admin_path(admin, "/payments")` |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | Related card: customer + invoice + events links | VERIFIED | `related_items/3` builds customer item (when present) + invoices filtered-link + events subject-link |
| `accrue_admin/lib/accrue_admin/live/coupon_live.ex` | Related card: promotion codes + events links | VERIFIED | `related_items/3` returns promotion-codes link + events subject-link for Coupon |
| `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` | Related card: coupon link + events link | VERIFIED | `related_items/3` builds coupon item (when coupon_id present) + events subject-link |
| `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` | Related card: events link | VERIFIED | `related_items/3` returns events subject-link for ConnectAccount |
| `accrue_admin/lib/accrue_admin/queries/invoices.ex` | Multi-status comma-separated filtering | VERIFIED | `filter_status/2`: splits on comma; single value uses equality; multi-value uses `where ... invoice.status in ^atoms`; `rescue ArgumentError -> query` |
| `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | Multi-status OR-dynamic filtering | VERIFIED | `filter_status/2` splits on comma; multi-value reduces `status_dynamic/1` fragments with `dynamic(^prev or ^d)` |
| `accrue_admin/lib/accrue_admin/queries/charges.ex` | Multi-status IN filtering | VERIFIED | `filter_status/2`: single → equality; multi → `where ... charge.status in ^values` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `router.ex @default_on_mount` | `AccrueAdmin.NavBadgeHook.on_mount/4` | live_session on_mount list | WIRED | Lines 9-11 confirmed |
| `app_shell.ex` | `Nav.items/3` | `nav_attention_counts` attr threaded | WIRED | Line 25: `Nav.items(assigns.mount_path, assigns.current_path, assigns.nav_attention_counts)` |
| `sidebar.ex grouped_items/1` | `nav.ex :collapsible + :badge fields` | `Map.get(first, :collapsible, false)` | WIRED | `grouped_items/1` reads `:collapsible`, `:badge` from first item in each group |
| `router.ex get /charges` | `RedirectController.charges_index/2` | `get/3` outside live_session | WIRED | Lines 62-63 confirmed |
| `app.js hooks map` | `SidebarCollapse hook` | import + hooks: {} registration | WIRED | Lines 7 and 26 confirmed |
| `sidebar.ex phx-hook` | `SidebarCollapse JS hook` | `phx-hook={if collapsible, do: "SidebarCollapse"}` | WIRED | Attribute present on collapsible group sections |
| `app_shell.ex data-mount-path` | `SidebarCollapse.storageKey()` | `this.el.closest("[data-mount-path]").dataset.mountPath` | WIRED | `ax-shell` div carries `data-mount-path={@mount_path}` at line 29 |
| `webhook_live.ex related_items/4` | `/events/:id` route | `ScopedPath.build(mount_path, "/events/#{event.id}", scope)` | WIRED | Line 332 confirmed |
| `event_live.ex related_items/3` | `/webhooks/:id` and entity paths | `caused_by_webhook_event_id` + `subject_href/3` | WIRED | Both webhook and entity link paths constructed correctly |
| `events_live.ex compliance_chips/2` | URL `?actor_type=` param | `activation_href = append_query(table_path, %{"actor_type" => "admin"})` | WIRED | URL-param synced via DataTable decode_filter |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| `attention_counts.ex compute/1` | `recovery` / `developer` | `Repo.aggregate(:count, :id)` on Subscription (past_due) + WebhookEvent (failed/dead) | Yes — live DB query | FLOWING |
| `nav_badge_hook.ex` | `nav_attention_counts` | `AttentionCounts.compute/1` → assigns | Yes | FLOWING |
| `invoices_live.ex` | status filter `open,uncollectible` | `Queries.Invoices.list/1` → `filter_status/2` splits comma → IN clause | Yes | FLOWING |
| `subscriptions_live.ex` | status filter `past_due,canceling` | `Queries.Subscriptions.list/1` → `filter_status/2` → dynamic OR | Yes | FLOWING |
| `event_live.ex @event` | event record | `Repo.get(Event, id)` — live DB lookup | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite passes | `mix test --seed 0` (in `accrue_admin/`) | 227 tests, 0 failures | PASS |
| Router redirect tests pass | `mix test test/accrue_admin/router_test.exs --seed 0` | 6 tests, 0 failures | PASS |
| Query multi-status tests pass | `mix test test/accrue_admin/queries/query_modules_test.exs --seed 0` | 26 tests, 0 failures | PASS |

### Probe Execution

Step 7c: No probe-*.sh files declared in plans or found under `scripts/*/tests/`. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|--------------|-------------|--------|---------|
| IA-01 | 175-02, 175-04 | Verb-labeled launchers + visible search from Home | SATISFIED | `copy.ex` verb titles; `dashboard_live.ex` visible search div |
| IA-02 | 175-02, 175-03 | Billing primary + Recovery/Developer/Catalog collapsible + badges + Connect standalone | SATISFIED | `nav.ex` items/3 with collapsible/badge fields; `sidebar.ex` grouped rendering; `attention_counts.ex` + `nav_badge_hook.ex` pipeline |
| IA-03 | 175-01, 175-04 | Work-queue pre-filtered lists + All chip | SATISFIED | `invoices_live.ex`, `subscriptions_live.ex`, `charges_live.ex` all implement 3-clause handle_params + push_patch default + FilterChipBar |
| IA-04 | 175-05, 175-07 | All 8 detail screens non-empty RelatedResources; Webhook→Event→entity thread | SATISFIED | All 8 screens verified: customer, subscription, invoice, charge, coupon, promotion_code, connect_account, webhook — all render RelatedResources; EventLive at /events/:id; bidirectional Webhook↔Event wiring |
| IA-05 | 175-06 | Customer-360 primary tabs + More overflow | SATISFIED | `customer_live.ex` @primary_tabs, @more_tabs, more_tabs_open, toggle_more_tabs, aria-haspopup="menu", "charges" → "Payments" label |
| IA-06 | 175-03 | /charges → /payments redirects; /events/:id added | SATISFIED | RedirectController with charges_index/2 + charges_show/2; router get routes outside live_session; test-verified 302 |
| IA-07 | 175-06 | Compliance actor-lens chip on events | SATISFIED | `events_live.ex` compliance_chips/2 always-active "By actor" chip; cobalt/slate tone toggle; URL-synced |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `charge_live.ex` | 35 | 404-fallback redirect goes to `/charges` not `/payments` | Info | Two-hop redirect only (404 → /charges → 302 → /payments); not a dead end; pre-dates Phase 175; no user-visible difference since RedirectController handles /charges |

No TBD/FIXME/XXX debt markers found in any files modified by this phase.
No stub patterns (placeholder text, empty returns, empty handlers) found.

---

### Human Verification Required

#### 1. Sidebar collapse/expand and localStorage persistence

**Test:** Open the admin UI, expand and collapse a specialist zone (e.g. Developer), refresh the page.
**Expected:** Collapsed state persists after refresh. Chevron rotates. Badge appears on Developer header when dead-letter webhooks exist in seed data. Billing group has no toggle at all.
**Why human:** SidebarCollapse JS hook interaction + CSS animation + localStorage side effects require a live browser.

#### 2. Attention-count badge appearance and tone

**Test:** With seed data containing past_due subscriptions and failed/dead webhooks, observe the sidebar Recovery and Developer group headers.
**Expected:** Recovery badge (warning-tone amber) shows count of past_due subs; Developer badge (danger-tone red) shows count of failed+dead webhooks; both absent when queues are empty.
**Why human:** Badge visual tone and conditional appearance require a live browser with DB-backed data.

#### 3. Home verb-launcher → work-queue persona path

**Test:** From Home, click "Clear the invoice queue" and "Recover at-risk revenue" launchers.
**Expected:** "Clear the invoice queue" lands on /invoices with cobalt-active work-queue chip pre-selected (open,uncollectible filter active); "Recover at-risk revenue" lands on /analytics/recovery. In both cases the path completes in ≤2 clicks.
**Why human:** Two-click persona path completion and chip visual state require browser navigation.

#### 4. Customer-360 More ▾ button toggle behavior

**Test:** Open a customer record, click "More ▾" button, verify tabs appear, click again to close, navigate to a More tab.
**Expected:** More menu shows Payment methods, Entitlements, Events, Metadata links. Second click closes the menu. Navigating to a More tab routes correctly and resets more_tabs_open to false (menu closes).
**Why human:** DOM show/hide toggle and routing behavior require live interaction.

#### 5. Webhook→Event→entity navigation thread

**Test:** Open a webhook that has derived events (use seed data with a replayed webhook). Follow the Related card links.
**Expected:** WebhookLive Related card shows event links pointing to /events/:id. EventLive loads the event, shows event type + actor + subject. EventLive Related card shows "Source webhook" link back to the webhook and an entity link (e.g. Customer or Subscription). The entity link routes to the correct detail screen.
**Why human:** Three-screen navigation chain with DB-backed derived_events query requires a browser and seed data.

---

### Gaps Summary

No gaps. All 5 ROADMAP success criteria and all 7 IA requirement IDs are satisfied by implemented, substantive, wired code with data flowing from live DB queries. The 227-test suite passes with 0 failures.

The only minor observation (charge_live.ex line 35 404-fallback to `/charges`) is pre-existing, produces no dead end (RedirectController intercepts), and has no user-visible impact. It does not constitute a gap.

---

_Verified: 2026-06-04T09:20:47Z_
_Verifier: Claude (gsd-verifier)_
