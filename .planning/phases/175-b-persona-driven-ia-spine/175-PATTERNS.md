# Phase 175: B — Persona-Driven IA Spine — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 14 new/modified files
**Analogs found:** 13 / 14 (one file — `redirect_controller.ex` — has no direct controller analog; uses `AccrueAdmin.Assets` Plug pattern + Phoenix.Controller docs)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/accrue_admin/attention_counts.ex` | service (context fn) | CRUD / batch-query | `dashboard_live.ex` lines 234–270 (`dashboard_stats/0`) | role-match — same query shapes, extracted to module |
| `lib/accrue_admin/auth_hook.ex` → add `NavBadgeHook` sibling | middleware/hook | request-response | `auth_hook.ex` lines 1–34 | exact — identical `on_mount/4` contract |
| `lib/accrue_admin/nav.ex` | utility (data transform) | transform | `nav.ex` lines 1–90 (current file) | exact — extend in place |
| `lib/accrue_admin/components/sidebar.ex` | component | request-response | `sidebar.ex` lines 1–67 (current file) | exact — extend in place |
| `lib/accrue_admin/components/app_shell.ex` | component | request-response | `app_shell.ex` lines 1–72 (current file) | exact — pass `nav_attention_counts` through |
| `lib/accrue_admin/router.ex` | config/route | request-response | `router.ex` lines 45–96 (current file) | exact — extend macro body |
| `lib/accrue_admin/controllers/redirect_controller.ex` | controller | request-response | `assets.ex` (Plug behaviour), Phoenix.Controller docs | partial — only Plug/conn pattern available in codebase |
| `lib/accrue_admin/live/event_live.ex` | LiveView (detail) | CRUD / request-response | `webhook_live.ex` mount+assign pattern; `events_live.ex` `subject_href/3` | role-match — same detail LiveView shape |
| `lib/accrue_admin/live/customer_live.ex` | LiveView (detail) | CRUD / request-response | `customer_live.ex` lines 34–79, 460–520 (current file) | exact — extend in place |
| `lib/accrue_admin/live/invoices_live.ex` | LiveView (list) | CRUD | `invoices_live.ex` lines 16–30 (current file); `events_live.ex` handle_params | exact — extend `handle_params` |
| `lib/accrue_admin/live/subscriptions_live.ex` | LiveView (list) | CRUD | `invoices_live.ex` — same structure | role-match |
| `lib/accrue_admin/live/charges_live.ex` | LiveView (list) | CRUD | `invoices_live.ex` — same structure | role-match |
| `lib/accrue_admin/live/events_live.ex` | LiveView (list) | CRUD | `events_live.ex` lines 1–30, 243–258 (current file) | exact — extend in place |
| `lib/accrue_admin/live/webhook_live.ex` | LiveView (detail) | CRUD | `webhook_live.ex` lines 310–316 (`derived_events/1`) | exact — extend in place |
| `lib/accrue_admin/live/dashboard_live.ex` | LiveView (home) | CRUD | `dashboard_live.ex` lines 91–100, 698–712 in copy.ex | exact — extend in place |
| `lib/accrue_admin/copy.ex` | utility (copy strings) | transform | `copy.ex` lines 698–712 | exact — 4 one-line string replacements |
| `assets/js/hooks/sidebar_collapse.js` | JS hook | event-driven | `command_palette.js` lines 1–94; `accrue_shell_nav.js` lines 1–29 | role-match — same hook lifecycle + localStorage pattern |
| `assets/js/app.js` | config | event-driven | `app.js` lines 1–29 (current file) | exact — add SidebarCollapse to hooks map |
| `assets/css/app.css` | CSS | transform | (token system — no analog needed; compose from `--ax-*` tokens per UI-SPEC §Token Gaps) | n/a |

---

## Pattern Assignments

### `lib/accrue_admin/attention_counts.ex` (new module — service, batch-query)

**Analog:** `lib/accrue_admin/live/dashboard_live.ex` lines 234–270

The executor extracts the two badge-relevant counts from `dashboard_stats/0` into a dedicated module so `DashboardLive` and every `on_mount` hook share a single source of truth.

**Module + query shape to replicate** (dashboard_live.ex lines 234–270):
```elixir
# dashboard_stats/0 — the full function; attention_counts.ex extracts the two
# badge-relevant keys: past_due_subscription_count and blocked_webhook_count.
import Ecto.Query
alias Accrue.Billing.{Query, Subscription}
alias Accrue.Repo
alias Accrue.Webhook.WebhookEvent

defp dashboard_stats do
  %{
    past_due_subscription_count:
      Subscription |> Query.past_due() |> Repo.aggregate(:count, :id),
    blocked_webhook_count:
      WebhookEvent
      |> where([event], event.status in [:failed, :dead])
      |> Repo.aggregate(:count, :id),
    # ... other fields stay in dashboard_live
  }
end
```

**New module shape** (executor writes this):
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

**After creating `AttentionCounts`, update `dashboard_live.ex`** to call `AttentionCounts.compute/1` for those two fields instead of inlining them in `dashboard_stats/0`, so both code paths stay in sync.

---

### `lib/accrue_admin/auth_hook.ex` → `AccrueAdmin.NavBadgeHook` (new sibling module, middleware)

**Analog:** `lib/accrue_admin/auth_hook.ex` lines 1–34 — exact `on_mount/4` contract

**Pattern to replicate** (auth_hook.ex lines 1–34):
```elixir
defmodule AccrueAdmin.AuthHook do
  @moduledoc false

  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  alias AccrueAdmin.OwnerScope

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_admin, params, session, socket) do
    case OwnerScope.resolve(session, params) do
      {:ok, owner_scope} ->
        {:cont,
         socket
         |> assign(:accrue_admin_session, session)
         |> assign(:current_admin, user)
         # ...
        }

      {:error, _reason} ->
        {:halt, redirect(socket, to: "/")}
    end
  end
end
```

**New hook shape** (executor writes this, can be a separate file or the same `auth_hook.ex` as a new public function):
```elixir
defmodule AccrueAdmin.NavBadgeHook do
  @moduledoc false
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:default, _params, _session, socket) do
    counts = AccrueAdmin.AttentionCounts.compute(socket.assigns[:current_owner_scope])
    {:cont, assign(socket, :nav_attention_counts, counts)}
  end
end
```

**Registration in `router.ex`** — the hook is appended to the `on_mount` list in `validate_opts!/2` (router.ex line 184):
```elixir
# router.ex line 184 — current:
on_mount: List.wrap(extra_hooks) ++ @default_on_mount
# @default_on_mount = [{AccrueAdmin.AuthHook, :ensure_admin}]

# After change — add NavBadgeHook after AuthHook so counts run post-auth:
@default_on_mount [
  {AccrueAdmin.AuthHook, :ensure_admin},
  {AccrueAdmin.NavBadgeHook, :default}
]
```

---

### `lib/accrue_admin/nav.ex` (modified — extend in place)

**Analog:** itself — `nav.ex` lines 1–90 (full file read above)

**Current shape** (lines 1–90):
```elixir
defmodule AccrueAdmin.Nav do
  def items(mount_path, current_path) do          # ← 2 args today
    org = org_slug(current_path)
    [
      %{label: "Home", href: nav_href(mount_path, "", org), icon: :home, group: nil},
      %{label: "Customers", ..., group: "Billing"},
      %{label: "Subscriptions", ..., group: "Billing"},
      %{label: "Invoices", ..., group: "Billing"},
      %{label: "Payments", href: nav_href(mount_path, "/charges", org), ..., group: "Billing"}, # ← /charges today
      %{label: "Recovery", ..., group: "Recovery"},
      %{label: "Webhooks", ..., group: "Developer"},
      %{label: "Event log", ..., group: "Developer"},
      %{label: "Coupons", ..., group: "Catalog"},
      %{label: "Promotion codes", ..., group: "Catalog"},
      %{label: "Connect", ..., group: "Connect"}
    ]
  end
end
```

**What to change:**
1. Add a third argument `attention_counts \\ %{}` to `items/3`.
2. Update `"Payments"` href from `/charges` to `/payments` (line 32).
3. Add `:badge` and `:collapsible` fields to every item map:
   - Billing items: `badge: nil, collapsible: false`
   - Recovery, Developer, Catalog items: `collapsible: true, badge: <count or nil>`
   - Connect, Home: `badge: nil, collapsible: false`

**Pattern for new fields:**
```elixir
def items(mount_path, current_path, attention_counts \\ %{}) do
  org = org_slug(current_path)
  recovery_badge = Map.get(attention_counts, :recovery, 0)
  developer_badge = Map.get(attention_counts, :developer, 0)

  [
    %{label: "Home", href: nav_href(mount_path, "", org), icon: :home,
      group: nil, collapsible: false, badge: nil},
    %{label: "Payments", href: nav_href(mount_path, "/payments", org),  # /payments not /charges
      icon: :payments, group: "Billing", collapsible: false, badge: nil},
    %{label: "Recovery", href: nav_href(mount_path, "/analytics/recovery", org),
      icon: :recovery, group: "Recovery", collapsible: true,
      badge: if(recovery_badge > 0, do: recovery_badge, else: nil)},
    %{label: "Webhooks", href: nav_href(mount_path, "/webhooks", org),
      icon: :webhooks, group: "Developer", collapsible: true,
      badge: if(developer_badge > 0, do: developer_badge, else: nil)},
    # ... Catalog items: collapsible: true, badge: nil
    # ... Connect: collapsible: false, badge: nil
  ]
end
```

---

### `lib/accrue_admin/components/app_shell.ex` (modified — thread attention_counts)

**Analog:** `app_shell.ex` lines 1–72 (full file read above)

**Current shape** (line 21 — the key line):
```elixir
assigns = assign(assigns, :nav_items, Nav.items(assigns.mount_path, assigns.current_path))
```

**What to change** — add `nav_attention_counts` attr and thread it to `Nav.items/3`:
```elixir
attr(:nav_attention_counts, :map, default: %{})

# In def app_shell(assigns):
assigns = assign(assigns, :nav_items,
  Nav.items(assigns.mount_path, assigns.current_path, assigns.nav_attention_counts))
```

All callers (`DashboardLive`, list LiveViews, detail LiveViews) pass `nav_attention_counts={@nav_attention_counts}` as a new attr, which comes from the `NavBadgeHook` assign on the socket. Since `attr` has `default: %{}`, existing callers without the attr still compile.

---

### `lib/accrue_admin/components/sidebar.ex` (modified — collapse + badges)

**Analog:** `sidebar.ex` lines 1–67 (full file read above)

**Current shape** (lines 31–47):
```elixir
# Current grouped_items/1 returns {group, items} 2-tuples:
defp grouped_items(items) do
  items
  |> Enum.chunk_by(&Map.get(&1, :group))
  |> Enum.map(fn [first | _] = group_items -> {Map.get(first, :group), group_items} end)
end

# Rendered as:
<section :for={{group, items} <- grouped_items(@items)} class="ax-sidebar-nav-group">
  <p :if={group} class="ax-sidebar-group-label"><%= group %></p>
  <a :for={item <- items} href={item.href} class={nav_class(item, @current_path)}>
    <Icon.icon name={item.icon} size="sm" class="ax-sidebar-link-icon" />
    <span class="ax-sidebar-link-label"><%= item.label %></span>
  </a>
</section>
```

**What to change:**
1. `grouped_items/1` returns `{group, items, group_meta}` 3-tuples where `group_meta = %{collapsible: bool, badge: integer|nil, tone: atom}`. Derive `collapsible` and `badge` from the first item (all items in a group share these fields, since they come from `nav.ex`).
2. Replace the `<p :if={group}>` group label with conditional: static `<p>` for non-collapsible groups, `<button>` with `phx-hook="SidebarCollapse"` for collapsible ones.
3. Wrap the link list in a `<div id=... hidden={...}>` controlled by `aria-expanded`.

**New `grouped_items/1` shape:**
```elixir
defp grouped_items(items) do
  items
  |> Enum.chunk_by(&Map.get(&1, :group))
  |> Enum.map(fn [first | _] = group_items ->
    group = Map.get(first, :group)
    meta = %{
      collapsible: Map.get(first, :collapsible, false),
      badge: Map.get(first, :badge),
      tone: badge_tone(group)
    }
    {group, group_items, meta}
  end)
end

defp badge_tone("Recovery"), do: :warning
defp badge_tone("Developer"), do: :danger
defp badge_tone(_), do: :neutral
```

**New HEEx render shape for collapsible groups** (mirrors RESEARCH.md §2 example):
```heex
<section
  :if={group}
  class="ax-sidebar-nav-group"
  id={"sidebar-group-#{slugify(group)}"}
  phx-hook={if group_meta.collapsible, do: "SidebarCollapse", else: nil}
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
    <span
      :if={group_meta.badge}
      class={badge_class(group_meta.tone)}
      aria-label={badge_aria_label(group, group_meta.badge)}
    >
      <%= group_meta.badge %>
    </span>
    <Icon.icon name={:chevron_right} size="sm" class="ax-sidebar-group-chevron" />
  </button>
  <p :if={not group_meta.collapsible} class="ax-sidebar-group-label"><%= group %></p>

  <div
    id={"sidebar-group-links-#{slugify(group)}"}
    hidden={not group_initially_expanded?(group_meta)}
  >
    <a :for={item <- items} href={item.href} class={nav_class(item, @current_path)}>
      <Icon.icon name={item.icon} size="sm" class="ax-sidebar-link-icon" />
      <span class="ax-sidebar-link-label"><%= item.label %></span>
    </a>
  </div>
</section>
```

**Helper functions to add:**
```elixir
defp group_initially_expanded?(%{collapsible: false}), do: true
defp group_initially_expanded?(%{badge: n}) when is_integer(n) and n > 0, do: true
defp group_initially_expanded?(_meta), do: false

defp badge_class(:warning), do: "ax-badge ax-badge-warning"
defp badge_class(:danger), do: "ax-badge ax-badge-danger"
defp badge_class(_), do: "ax-badge"

defp badge_aria_label("Recovery", n), do: "#{n} at-risk subscriptions"
defp badge_aria_label("Developer", n), do: "#{n} webhooks need attention"
defp badge_aria_label(group, n), do: "#{n} items in #{group}"

defp slugify(str), do: str |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "-")
```

---

### `lib/accrue_admin/router.ex` (modified — add redirect routes + /payments + /events/:id)

**Analog:** `router.ex` lines 45–96 (full file read above)

**Current structure** (condensed):
```elixir
scope mount_path, as: :accrue_admin do
  get("/assets/brand-...", AccrueAdmin.Assets, :brand)
  # ... other asset routes ...

  pipe_through(:accrue_admin_browser)

  live_session :accrue_admin,
    root_layout: ..., on_mount: on_mount, session: ... do
    live("/", ...)
    live("/charges", AccrueAdmin.Live.ChargesLive, :index)   # ← remove
    live("/charges/:id", AccrueAdmin.Live.ChargeLive, :show) # ← remove
    live("/events", AccrueAdmin.Live.EventsLive, :index)
    # ... no /events/:id ...
  end
end
```

**What to change** — add BEFORE `live_session` (inside scope, after `pipe_through`):
```elixir
# Redirect /charges → /payments (IA-06 — must be OUTSIDE live_session)
get("/charges", AccrueAdmin.RedirectController, :charges_index)
get("/charges/:id", AccrueAdmin.RedirectController, :charges_show)
```

And INSIDE `live_session`, replace removed routes + add new:
```elixir
# Replace /charges:
live("/payments", AccrueAdmin.Live.ChargesLive, :index)
live("/payments/:id", AccrueAdmin.Live.ChargeLive, :show)
# Add /events/:id (was missing):
live("/events/:id", AccrueAdmin.Live.EventLive, :show)
```

**Critical constraint from router.ex lines 55–60:** `pipe_through(:accrue_admin_browser)` must appear BEFORE the `get/3` redirect routes — it already applies to the whole scope, so the redirect controller gets the browser pipeline (session, CSRF, brand).

---

### `lib/accrue_admin/controllers/redirect_controller.ex` (new — controller, request-response)

**Analog:** `assets.ex` (Plug behaviour) — closest existing controller-like module. No full Phoenix.Controller exists in the codebase yet. Use Phoenix.Controller pattern directly.

**`assets.ex` Plug pattern** (lines 43–50) — shows `import Plug.Conn` + `conn` manipulation:
```elixir
def call(conn, kind) do
  conn
  |> put_resp_header("cache-control", ...)
  |> send_resp(200, body)
end
```

**Session mount_path access** — `BrandPlug` does NOT set `accrue_admin_mount_path` on conn assigns. The mount path is only available in the LiveView session (injected by `Router.__session__/3`). For the redirect controller, use the simpler approach: derive it from `conn.request_path` (strip the `/charges` suffix) or read from `Application.get_env`. The cleanest approach given router macro binding:

```elixir
defmodule AccrueAdmin.RedirectController do
  use Phoenix.Controller

  def charges_index(conn, _params) do
    qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
    # mount_path is the scope prefix — derive from request_path by stripping /charges
    mount_path = conn.request_path |> String.replace_suffix("/charges", "")
    redirect(conn, to: mount_path <> "/payments" <> qs)
  end

  def charges_show(conn, %{"id" => id}) do
    qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
    mount_path = conn.request_path |> String.replace_suffix("/charges/#{id}", "")
    redirect(conn, to: mount_path <> "/payments/" <> URI.encode(id) <> qs)
  end
end
```

**Footgun note:** `URI.encode/1` on the `:id` path segment prevents path traversal from user-controlled input (RESEARCH.md §Security). The mount_path derivation from `request_path` is safe because the router only routes `/charges` and `/charges/:id` to this controller — no other prefix hits these actions.

---

### `lib/accrue_admin/live/event_live.ex` (new — LiveView detail, CRUD)

**Analog:** `webhook_live.ex` — same detail LiveView mount/assign pattern (lines 28–60). `events_live.ex` — `subject_href/3` logic (lines 243–258).

**Mount pattern to replicate** (webhook_live.ex lines 28–60):
```elixir
def mount(%{"id" => webhook_id}, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  case Webhooks.detail(webhook_id, socket.assigns.current_owner_scope) do
    :not_found ->
      {:ok,
       socket
       |> put_flash(:error, Copy.Locked.owner_access_denied())
       |> redirect(to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/webhooks"))}

    {:ok, webhook} ->
      {:ok,
       socket
       |> assign_shell(admin)
       |> assign_webhook(webhook)
       |> assign(:flashes, [])}
  end
end
```

**subject_href pattern to copy** (events_live.ex lines 243–258):
```elixir
defp subject_href(%{subject_type: "Customer", subject_id: id}, mount_path, scope),
  do: ScopedPath.build(mount_path, "/customers/#{id}", scope)

defp subject_href(%{subject_type: "Subscription", subject_id: id}, mount_path, scope),
  do: ScopedPath.build(mount_path, "/subscriptions/#{id}", scope)

defp subject_href(%{subject_type: "Invoice", subject_id: id}, mount_path, scope),
  do: ScopedPath.build(mount_path, "/invoices/#{id}", scope)

defp subject_href(%{subject_type: "Charge", subject_id: id}, mount_path, scope),
  do: ScopedPath.build(mount_path, "/charges/#{id}", scope)   # update to /payments/:id

defp subject_href(%{subject_type: "WebhookEvent", subject_id: id}, mount_path, scope),
  do: ScopedPath.build(mount_path, "/webhooks/#{id}", scope)

defp subject_href(_row, _mount_path, _scope), do: nil
```

**assign_shell pattern** — copy verbatim from any list LiveView (e.g., events_live.ex lines 128–139):
```elixir
defp assign_shell(socket, admin) do
  socket
  |> assign(:page_title, "Event")
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, admin_path(admin, "/events"))
end
```

**RelatedResources usage pattern** (charge_live.ex line 288 + 556–588):
```elixir
# In render:
<RelatedResources.related_resources
  items={related_items(@event, @admin_mount_path, @current_owner_scope)}
/>

# related_items/3 for EventLive:
defp related_items(event, mount_path, scope) do
  # 1. Source webhook (if caused_by_webhook_event_id present):
  webhook_items =
    if event.caused_by_webhook_event_id do
      [%{icon: :webhooks, label: "Source webhook",
         value: event.caused_by_webhook_event_id,
         href: ScopedPath.build(mount_path, "/webhooks/#{event.caused_by_webhook_event_id}", scope)}]
    else
      []
    end

  # 2. Affected entity (subject):
  entity_items =
    case subject_href(event, mount_path, scope) do
      nil -> []
      href -> [%{icon: subject_icon(event.subject_type), label: event.subject_type,
                  value: event.subject_id, href: href}]
    end

  webhook_items ++ entity_items
end
```

---

### `lib/accrue_admin/live/customer_live.ex` (modified — tab tiering + More ▾)

**Analog:** `customer_live.ex` lines 34, 62–79, 460–520 (current file — extend in place)

**Current `@tabs` constant** (line 34):
```elixir
@tabs ~w(subscriptions invoices charges payment_methods entitlements events metadata)
```

**What to change:**
1. Add `@primary_tabs ~w(subscriptions invoices charges)` and `@more_tabs ~w(payment_methods entitlements events metadata)`.
2. Add `more_tabs_open: false` in mount assigns.
3. Add `handle_event("toggle_more_tabs", ...)` and `handle_event("close_more_tabs", ...)`.
4. In `handle_params/3` (lines 68–79), reset `more_tabs_open: false` on tab navigation.
5. Replace `Tabs.tabs/1` call in render with inline tab strip + "More ▾" button.

**handle_params shape** (lines 68–79):
```elixir
@impl true
def handle_params(params, _uri, socket) do
  tab = params |> Map.get("tab", "subscriptions") |> normalize_tab()
  {:noreply,
   socket
   |> assign(:params, params)
   |> assign(:tab, tab)
   |> assign(:more_tabs_open, false)   # ← add this
   |> assign_entitlements_view(tab)}
end
```

**related_items/3** (lines 470–498) — update `/charges` href to `/payments`:
```elixir
# line 486: change /charges to /payments
%{icon: :payments, label: "Charges",
  href: ScopedPath.build(mount_path, "/payments", scope, %{"customer_id" => customer.id})}
```

**Tab tiering HEEx sketch** (replaces `<Tabs.tabs ...>`):
```heex
<nav class="ax-tabs" aria-label="Customer sections">
  <a :for={tab <- primary_tab_list(@customer, @tab_counts, @admin_mount_path, @current_owner_scope)}
     href={tab.href}
     class={["ax-tab", @tab == tab.id && "ax-tab-active"]}
     aria-current={if(@tab == tab.id, do: "page", else: nil)}>
    <span><%= tab.label %></span>
    <span :if={tab.count} class="ax-tab-count"><%= tab.count %></span>
  </a>
  <div class="ax-tab-more-wrapper">
    <button type="button"
      class={["ax-tab ax-tab-more-trigger", @tab in @more_tabs && "ax-tab-active"]}
      aria-haspopup="menu"
      aria-expanded={to_string(@more_tabs_open)}
      phx-click="toggle_more_tabs">
      More <Icon.icon name={:chevron_down} size="sm" />
    </button>
    <ul :if={@more_tabs_open} class="ax-tab-more-menu" role="menu">
      <li :for={tab <- more_tab_list(@customer, @tab_counts, @admin_mount_path, @current_owner_scope)} role="none">
        <a href={tab.href} class="ax-tab-more-item" role="menuitem"
           aria-current={if(@tab == tab.id, do: "page", else: nil)}>
          <%= tab.label %>
          <span :if={tab.count} class="ax-tab-count"><%= tab.count %></span>
        </a>
      </li>
    </ul>
  </div>
</nav>
```

---

### `lib/accrue_admin/live/invoices_live.ex` (modified — work-queue default)

**Analog:** `invoices_live.ex` lines 16–30 (current `mount` + `handle_params` — extend in place)

**Current handle_params** (line 28–30):
```elixir
@impl true
def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end
```

**Pattern to replace with** (RESEARCH.md §4 example + `?view=all` sentinel):
```elixir
@default_queue_status "open,uncollectible"

@impl true
def handle_params(%{"view" => "all"} = params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end

def handle_params(params, _uri, socket) when map_size(params) == 0 do
  default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)
  {:noreply, push_patch(socket, to: socket.assigns.table_path <> "?" <> URI.encode_query(default))}
end

def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end

defp build_default_params(%{mode: :organization, organization_slug: slug}, status)
     when is_binary(slug) do
  %{"status" => status, "org" => slug}
end
defp build_default_params(_scope, status), do: %{"status" => status}
```

**FilterChipBar integration** — add above `<.live_component module={DataTable}`:
```heex
<AccrueAdmin.Components.FilterChipBar.filter_chip_bar
  items={work_queue_chips(@params, @table_path)}
  label="Work queue"
/>
```

```elixir
defp work_queue_chips(params, table_path) do
  queue_active = Map.get(params, "status") == @default_queue_status
  all_active = Map.get(params, "view") == "all"
  [
    %{id: :status_queue, label: "Queue", value: "open · uncollectible",
      tone: :cobalt, active: queue_active,
      remove_href: table_path <> "?view=all"},
    %{id: :view_all, label: "All", tone: :slate,
      active: all_active,
      remove_href: table_path}
  ]
end
```

**Apply the same pattern** to `subscriptions_live.ex` (`@default_queue_status "past_due,canceling"`) and `charges_live.ex` (`@default_queue_status "failed"`). Customers list keeps no queue default (CONTEXT.md: "customers → all").

---

### `lib/accrue_admin/live/events_live.ex` (modified — compliance actor-lens chip)

**Analog:** `events_live.ex` lines 85–119 (filter_fields + render — extend in place)

**Current filter_fields** (line 113–119):
```elixir
filter_fields={[
  %{id: :q, label: ...},
  %{id: :type, label: ...},
  %{id: :actor_type, label: ...},   # ← already exists
  %{id: :subject_type, label: ...},
  %{id: :source_webhook_event_id, label: ...}
]}
```

**Add above the DataTable** — a `FilterChipBar` with the "By actor" quick-lens:
```heex
<AccrueAdmin.Components.FilterChipBar.filter_chip_bar
  items={compliance_chips(@params, @table_path)}
  label="Quick filters"
/>
```

```elixir
defp compliance_chips(params, table_path) do
  actor_active = Map.get(params, "actor_type") not in [nil, ""]
  [%{
    id: :by_actor,
    label: "By actor",
    tone: if(actor_active, do: :cobalt, else: :slate),
    active: true,                          # always render (saved lens)
    value: if(actor_active, do: params["actor_type"], else: nil),
    remove_href: if(actor_active, do: table_path, else: nil)
    # Note: when inactive, chip has no remove_href so no Clear link renders.
    # A separate activation link must be provided (extend filter_chip_bar or
    # render a plain styled link alongside the bar for the inactive lens).
  }]
end
```

**Footgun on chip API:** `filter_chip_bar` chips only render `Clear` when `remove_href` is set (line 49 of filter_chip_bar.ex). When the lens is inactive (no actor_type param), the chip has no `remove_href` and no activation `href` either — it just renders as a label. The planner must either: (a) extend `filter_chip_bar` to support an `href` attr for inactive chips that creates a "lens" link, or (b) render the inactive chip as a separate element outside `filter_chip_bar`. The RESEARCH.md notes this tension at §10.

---

### `lib/accrue_admin/live/webhook_live.ex` (modified — Related card + event links)

**Analog:** `webhook_live.ex` lines 310–316 (`derived_events/1`); `charge_live.ex` lines 556–588 (`related_items` pattern)

**Current `derived_events/1`** (lines 310–316):
```elixir
defp derived_events(webhook_id) do
  from(event in Event,
    where: event.caused_by_webhook_event_id == ^webhook_id,
    order_by: [asc: event.inserted_at, asc: event.id]
  )
  |> Repo.all()
end
```

**What to add** — a `related_items/3` function and the `RelatedResources` render call:
```elixir
# Add to imports:
alias AccrueAdmin.Components.RelatedResources
alias AccrueAdmin.ScopedPath

# New function:
defp related_items(webhook, derived_events, mount_path, scope) do
  Enum.map(Enum.take(derived_events, 3), fn event ->
    %{
      icon: :events,
      label: "Event",
      value: event.type,
      href: ScopedPath.build(mount_path, "/events/#{event.id}", scope)
    }
  end)
end

# In render, alongside the existing Timeline section:
<RelatedResources.related_resources
  items={related_items(@webhook, @derived_events, @admin_mount_path, @current_owner_scope)}
/>
```

---

### `lib/accrue_admin/live/dashboard_live.ex` (modified — verb relabels + visible search)

**Analog:** `dashboard_live.ex` lines 38–100 (render); `copy.ex` lines 698–712

**Verb relabels** — 4 one-line string changes in `copy.ex`:
```elixir
# copy.ex line 698:  "Find a customer"         → "Look up a customer"
# copy.ex line 703:  "Work open invoices"       → "Clear the invoice queue"
# copy.ex line 707:  "Recover failed payments"  → "Recover at-risk revenue"
# copy.ex line 711:  "Debug webhooks & events"  → "Investigate an incident"
```

**Global search quick-links** — also update in `global_search.ex` (inline strings, not through Copy module per RESEARCH.md §9). Grep for the old strings there.

**Visible search field on Home** — add above or below the launchers section (anti-churn: do NOT touch attention rail, KPIs, or recent activity):
```heex
<%!-- Home visible search field — IA-01, persona-job: Support entry discoverability --%>
<div class="ax-home-search">
  <button
    type="button"
    class="ax-input ax-input-search"
    role="search"
    aria-label="Search"
    phx-click="open"
    phx-target="#global-search"
  >
    <Icon.icon name={:search} size="md" class="ax-input-icon" />
    <span class="ax-input-placeholder">Search customers, invoices… ⌘K</span>
  </button>
</div>
```

**Why a button, not an input:** This avoids LiveComponent event-targeting complexity (RESEARCH.md §8 footgun). The `phx-click="open" phx-target="#global-search"` pattern is already used in `topbar.ex` for the search trigger.

---

### `lib/accrue_admin/copy.ex` (modified — 4 string replacements)

**Analog:** `copy.ex` lines 698–712 (current — direct 1:1 string replacements)

```elixir
# Line 698: def home_launcher_customers_title, do: "Find a customer"
# → "Look up a customer"

# Line 703: def home_launcher_invoices_title, do: "Work open invoices"
# → "Clear the invoice queue"

# Line 707: def home_launcher_recovery_title, do: "Recover failed payments"
# → "Recover at-risk revenue"

# Line 711: def home_launcher_developer_title, do: "Debug webhooks & events"
# → "Investigate an incident"
```

No template changes needed — render calls `Copy.home_launcher_*_title()` which is already wired.

---

### `assets/js/hooks/sidebar_collapse.js` (new — JS hook, event-driven)

**Analog:** `command_palette.js` lines 1–94 (hook lifecycle: `mounted()`, `destroyed()`, `pushEventTo`); `accrue_shell_nav.js` lines 1–29 (document-level click + `localStorage` pattern without LiveView round-trips)

**CommandPalette lifecycle pattern** (command_palette.js lines 1–29):
```javascript
export const CommandPalette = {
  mounted() {
    this.handleGlobalKeydown = this.handleGlobalKeydown.bind(this);
    window.addEventListener("keydown", this.handleGlobalKeydown);
    this.el.addEventListener("keydown", this.handleInputKeydown);
    this.setupItems();
  },
  updated() { ... },
  destroyed() {
    window.removeEventListener("keydown", this.handleGlobalKeydown);
    this.el.removeEventListener("keydown", this.handleInputKeydown);
  },
  // ... event handlers
};
```

**accrue_shell_nav.js document-click pattern** (lines 6–18):
```javascript
function onDocumentClick(event) {
  const toggle = event.target.closest("[data-sidebar-toggle='true']");
  if (toggle) {
    event.preventDefault();
    document.documentElement.classList.toggle("ax-shell-nav-open");
  }
}
```

**New hook shape** — combines lifecycle from CommandPalette + localStorage from RESEARCH.md §2:
```javascript
export const SidebarCollapse = {
  mounted() {
    // Read localStorage to override server-rendered aria-expanded
    const key = this.storageKey();
    const stored = localStorage.getItem(key);
    if (stored !== null) {
      this.setExpanded(stored === "true");
    }

    this.handleClick = this.handleClick.bind(this);
    this.el.addEventListener("click", this.handleClick);
  },

  destroyed() {
    this.el.removeEventListener("click", this.handleClick);
  },

  handleClick(e) {
    if (e.target.closest("[data-collapse-toggle]")) {
      e.preventDefault();
      const expanded = this.el.getAttribute("aria-expanded") === "true";
      this.setExpanded(!expanded);
      localStorage.setItem(this.storageKey(), String(!expanded));
    }
  },

  setExpanded(expanded) {
    this.el.setAttribute("aria-expanded", String(expanded));
    const list = document.getElementById(this.el.dataset.controls);
    if (list) list.hidden = !expanded;
  },

  storageKey() {
    // Prefix with mount_path to avoid collision across mounts (RESEARCH.md §3 footgun)
    const mountPath = this.el.closest("[data-mount-path]")?.dataset.mountPath || "/billing";
    return "ax-sidebar-" + mountPath + "-" + this.el.dataset.group;
  }
};
```

---

### `assets/js/app.js` (modified — register SidebarCollapse hook)

**Analog:** `app.js` lines 6 + 25 (current)

**Current hook registration** (lines 6 + 22–26):
```javascript
import { CommandPalette } from "./hooks/command_palette";
// ...
const liveSocket = new LiveSocket("/live", Socket, {
  params: csrfToken ? { _csrf_token: csrfToken } : {},
  hooks: { CommandPalette }
});
```

**What to change:**
```javascript
import { CommandPalette } from "./hooks/command_palette";
import { SidebarCollapse } from "./hooks/sidebar_collapse";
// ...
const liveSocket = new LiveSocket("/live", Socket, {
  params: csrfToken ? { _csrf_token: csrfToken } : {},
  hooks: { CommandPalette, SidebarCollapse }
});
```

---

## Shared Patterns

### assign_shell/2 (all LiveViews)
**Source:** any list LiveView — `invoices_live.ex` lines 133–143, `events_live.ex` lines 128–139
**Apply to:** `event_live.ex` (new file — copy verbatim, update `:page_title` and `:current_path`)
```elixir
defp assign_shell(socket, admin) do
  socket
  |> assign(:page_title, "...")
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, admin_path(admin, "/events"))
end
```

### ScopedPath.build/3,4
**Source:** `accrue_admin/lib/accrue_admin/scoped_path.ex` (full file)
**Apply to:** `event_live.ex`, `redirect_controller.ex`, every `related_items/3` function
```elixir
# Signature:
ScopedPath.build(mount_path, "/suffix", owner_scope)
ScopedPath.build(mount_path, "/suffix", owner_scope, %{"key" => "value"})
# Handles org= param injection automatically; never do string concat for scoped paths
```

### RelatedResources component API
**Source:** `related_resources.ex` lines 25–48 (full component — unchanged)
```elixir
attr(:title, :string, default: "Related billing")
attr(:items, :list, required: true)
# Each item: %{icon: atom, label: string, href: string, value: string (optional)}
# Renders nothing when items == []
```

### FilterChipBar chip API
**Source:** `filter_chip_bar.ex` lines 8–60 (full component)
```elixir
# Chip map keys: id, label, value, tone (:moss|:cobalt|:amber|:slate|:ink), active (bool), remove_href
# Chip renders only when active: true (default)
# "Clear" link renders only when remove_href is set
# Tones cobalt = active/selected; slate = neutral/escape-hatch
```

### AppShell render contract
**Source:** `app_shell.ex` lines 11–49 (full component)
```elixir
# Required attrs: brand, current_path, mount_path, page_title
# Optional: theme (default "system"), active_organization_name (default nil)
# NEW: nav_attention_counts (add with default: %{})
# GlobalSearch LiveComponent is mounted inside — do NOT add a second instance
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/accrue_admin/controllers/redirect_controller.ex` | controller | request-response | No Phoenix.Controller exists in accrue_admin yet; only Plug behaviours (`assets.ex`). Pattern must be derived from Phoenix.Controller + Plug.Conn (`import Plug.Conn; use Phoenix.Controller`). |
| `assets/css/app.css` (new classes) | CSS | n/a | New `ax-badge-warning`, `ax-badge-danger`, `ax-sidebar-group-chevron`, `ax-tab-more-menu`, `ax-sidebar-group-toggle` classes have no existing analog. Compose from `--ax-*` tokens per UI-SPEC §Token Gaps; reference `.ax-badge`, `.ax-related-chevron`, `.ax-tab` as the closest structural analogs. |

---

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/`, `accrue_admin/assets/js/`
**Files read:** 18
**Pattern extraction date:** 2026-06-04
