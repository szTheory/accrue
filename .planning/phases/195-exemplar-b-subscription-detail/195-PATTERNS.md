# Phase 195: Exemplar B - Subscription Detail - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 31
**Analogs found:** 31 / 31

Project context: `AGENTS.md` was absent; local `.codex/skills/` and `.agents/skills/` were absent. `CLAUDE.md` confirms `accrue_admin` owns LiveView runtime work and core `accrue` must stay LiveView-runtime-free.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | LiveView/controller | event-driven CRUD + request-response render | same file, action triplet and provider guards | exact |
| `accrue_admin/lib/accrue_admin/components/overlay.ex` | component | event-driven overlay/presentation | `detail_drawer.ex`, `step_up_auth_modal.ex`, LiveView `.portal` | role-match |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | component | request-response render | `Detail.summary_card/1`, `detail_section/1`, `detail_field_list/1` | exact |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | event-driven drawer | existing `DetailDrawer.detail_drawer/1` | exact |
| `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | component | event-driven auth modal | existing `StepUpAuthModal.step_up_auth_modal/1` | exact optional |
| `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` | component | event-driven menu | existing `DropdownMenu.dropdown_menu/1` + `dropdown.js` | role-match |
| `accrue_admin/lib/accrue_admin/components/related_resources.ex` | component | request-response navigation render | existing `RelatedResources.related_resources/1` | exact |
| `accrue_admin/lib/accrue_admin/layouts.ex` | layout/config | request-response shell render | existing `Layouts.root/1` | exact |
| `accrue_admin/lib/accrue_admin/components/app_shell.ex` | component/layout | request-response shell render | existing `AppShell.app_shell/1` | exact |
| `accrue_admin/assets/js/hooks/scroll_lock.js` | utility/hook | DOM side-effect event-driven | `focus_trap.js`, `focus_trap_test.mjs` | role-match |
| `accrue_admin/assets/js/hooks/focus_trap.js` | hook | DOM side-effect event-driven | same file | exact reused |
| `accrue_admin/assets/js/hooks/dropdown.js` | utility | DOM side-effect event-driven | same file | exact reused |
| `accrue_admin/assets/js/app.js` | JS config/bootstrap | event-driven hook registration | same file imports/hooks pattern | exact |
| `accrue_admin/assets/css/app.css` | CSS config | render transform | existing drawer/dropdown/detail CSS | exact |
| `accrue_admin/assets/css/theme.css` | token config | render transform | existing spacing/motion/z-index tokens | exact |
| `accrue_admin/priv/static/accrue_admin.css` | generated asset | batch/generated | `mix accrue_admin.assets.build` output | exact generated |
| `accrue_admin/priv/static/accrue_admin.js` | generated asset | batch/generated | `mix accrue_admin.assets.build` output | exact generated |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | copy utility | transform | existing subscription copy functions | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` | copy facade | transform | existing defdelegate facade | exact |
| `examples/accrue_host/e2e/generated/copy_strings.json` | generated fixture | batch/generated | `mix accrue_admin.export_copy_strings` output | exact generated |
| `storybook/components/overlay.story.exs` | Storybook story | request-response dev render | `storybook/components/button.story.exs` | role-match |
| `storybook/components/action_menu.story.exs` | Storybook story | request-response dev render | `storybook/components/button.story.exs` | role-match |
| `storybook/components/detail.story.exs` | Storybook story | request-response dev render | `storybook/components/button.story.exs` + `RegistryStory` | role-match |
| `storybook/components/subscription_detail.story.exs` | Storybook story | request-response dev render | `storybook/components/button.story.exs` | role-match |
| `accrue_admin/lib/accrue_admin/dev/component_registry.ex` | dev registry | request-response dev render | existing specimens entries | role-match |
| `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` | test | render assertions | same file old drawer/modal assertions | exact |
| `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | test | LiveView event-driven CRUD | same file old subscription tests | exact |
| `accrue_admin/test/js/scroll_lock_test.mjs` | test | JS event-driven DOM | `test/js/focus_trap_test.mjs` | role-match |
| `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` | test | Playwright page-flow | `admin-spec-overview-phase194.spec.js` + `phase191-page-flow-helpers.js` | role-match |
| `accrue_admin/package.json` | config | batch/test command | existing `e2e:phase191` / `e2e:phase194` scripts | exact |
| `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json` | test fixture | batch/page-flow matrix | existing additive page-flow cell rows | exact |

## Pattern Assignments

### `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (LiveView/controller, event-driven CRUD)

**Analog:** same file.

**Imports pattern** (lines 4-29):
```elixir
use Phoenix.LiveView

alias Accrue.{Actor, Auth, Billing, Clock, Config, Events, PlanResolver}
alias Accrue.Billing.Subscription
alias Accrue.Billing.UpcomingInvoice
alias Accrue.Dunning.Campaign
alias Accrue.Repo

alias AccrueAdmin.Components.{
  AppShell,
  Breadcrumbs,
  Detail,
  FlashGroup,
  JsonViewer,
  KpiCard,
  RelatedResources,
  StatusBadge,
  StepUpAuthModal,
  TaxOwnershipCard,
  Timeline
}

alias AccrueAdmin.Copy
alias AccrueAdmin.Queries.Subscriptions
alias AccrueAdmin.ScopedPath
alias AccrueAdmin.StepUp
alias AccrueAdmin.TaxOwnershipRow
```

**Scoped load + initial assigns** (lines 35-65):
```elixir
def mount(%{"id" => subscription_id}, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  case Subscriptions.detail(subscription_id, socket.assigns.current_owner_scope) do
    :not_found ->
      {:ok,
       socket
       |> put_flash(:error, Copy.Locked.owner_access_denied())
       |> redirect(
         to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/subscriptions")
       )}

    {:ok, subscription} ->
      mount_path = admin["mount_path"] || "/billing"
      scope = socket.assigns.current_owner_scope

      {:ok,
       socket
       |> assign_shell(admin)
       |> assign(:subscription, subscription)
       |> assign(:customer, subscription.customer)
       |> assign(:timeline_events, timeline_events(subscription.id))
       |> assign(:proration_options, proration_options())
       |> assign(:swap_plan_available, swap_plan_available?(subscription))
       |> assign(:related_items, related_items(subscription, mount_path, scope))
       |> assign(:pending_action, nil)}
  end
end
```

Copy this shape but move eager `:timeline_events` assignment behind first-expand for Activity/Raw JSON. Keep `Subscriptions.detail/2` scoping.

**Action event triplet + destructive StepUp** (lines 70-104):
```elixir
def handle_event("prepare_action", params, socket) do
  action = pending_action(params, socket)
  {:noreply, assign(socket, :pending_action, maybe_attach_preview(socket, action))}
end

def handle_event("cancel_pending_action", _params, socket) do
  {:noreply, assign(socket, :pending_action, nil)}
end

def handle_event("confirm_action", _params, socket) do
  pending_action = socket.assigns.pending_action

  case pending_action do
    nil ->
      {:noreply, push_flash(socket, :warning, Copy.subscription_select_action_warning())}

    %{type: type} = action when type in @destructive_actions ->
      case StepUp.require_fresh(
             socket,
             step_up_action(action, socket.assigns.subscription),
             &execute_pending_action(&1, action)
           ) do
        {:ok, socket} -> {:noreply, socket}
        {:challenge, socket} -> {:noreply, socket}
        {:error, _reason, socket} ->
          {:noreply, push_flash(socket, :error, subscription_action_error_copy(socket, action))}
      end

    action ->
      {:noreply, execute_pending_action(socket, action)}
  end
end
```

Do not replace this billing execution path. New primary buttons and action-menu items should push `prepare_action`; drawer submit should push `confirm_action`.

**Existing inline action forms to move into drawer** (lines 298-469):
```elixir
<form phx-submit="prepare_action" data-role="cancel-now-form">
  <input type="hidden" name="action_type" value="cancel_now" />
  <.source_event_select events={@timeline_events} />
  <button type="submit" class="ax-button ax-button-secondary">
    <%= Copy.subscription_action_cancel_now() %>
  </button>
</form>

<form :if={!braintree_processor?(@subscription)} phx-submit="prepare_action" data-role="cancel-at-period-end-form">
  <input type="hidden" name="action_type" value="cancel_at_period_end" />
  <.source_event_select events={@timeline_events} />
  <button type="submit" class="ax-button ax-button-secondary">
    <%= Copy.subscription_action_cancel_at_period_end() %>
  </button>
</form>

<form :if={@swap_plan_available} phx-submit="prepare_action" data-role="swap-plan-form">
  <input type="hidden" name="action_type" value="swap_plan" />
  <label class="ax-label" for="new-price-id">New price id</label>
  <input id="new-price-id" type="text" name="new_price_id" value={current_price_id(@subscription)} class="ax-input" />
  <label class="ax-label" for="proration">Proration</label>
  <select id="proration" name="proration" class="ax-select">
    <option :for={option <- @proration_options} value={option.value}><%= option.label %></option>
  </select>
  <.source_event_select events={@timeline_events} />
  <button type="submit" class="ax-button ax-button-secondary">
    <%= Copy.subscription_action_swap_plan() %>
  </button>
</form>
```

The forms are useful body content, but the page-level `ax-card` and confirm panel are obsolete. Render zero visible action-band forms on initial load.

**Confirm panel currently inline; move content into drawer footer/body** (lines 472-498):
```elixir
<section :if={@pending_action} class="ax-card" data-role="confirm-panel">
  <p class="ax-label">Confirm action</p>
  <p class="ax-body"><%= confirm_copy(@pending_action, @subscription, @customer) %></p>
  <section :if={match?(%UpcomingInvoice{}, @pending_action[:preview])} class="ax-stack-md" data-role="swap-plan-preview">
    <p class="ax-label"><%= AccrueAdmin.Copy.Subscription.subscription_action_preview_heading() %></p>
    <p class="ax-body"><%= preview_summary(@pending_action.preview) %></p>
  </section>
  <div class="ax-page-header">
    <button phx-click="confirm_action" class="ax-button ax-button-primary" data-role="confirm-action">
      Confirm <%= humanize(@pending_action.type) %>
    </button>
    <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost">Cancel</button>
  </div>
</section>
```

**Action parsing + execution allowlist** (lines 639-700, 701-902):
```elixir
defp pending_action(params, socket) do
  source_event = selected_source_event(params, socket.assigns.timeline_events)

  %{
    type: Map.fetch!(params, "action_type"),
    new_price_id: blank_to_nil(params["new_price_id"]),
    new_quantity: integer_param(params["new_quantity"]),
    item_id: blank_to_nil(params["item_id"]),
    pause_behavior: blank_to_nil(params["pause_behavior"]) || "void",
    proration: blank_to_nil(params["proration"]) || "create_prorations",
    source_event_id: source_event && source_event.id,
    source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
  }
end
```

Keep server-side allowlists in `execute_action/4`; menu visibility is not validation.

**Provider gates** (lines 1095-1118):
```elixir
defp swap_plan_available?(subscription) do
  if braintree_processor?(subscription) do
    PlanResolver.configured?()
  else
    true
  end
end

defp preview_supported?(subscription), do: not braintree_processor?(subscription)

defp quantity_change_available?(subscription) do
  quantity_item_changes_available?(subscription) and single_item_subscription?(subscription)
end

defp quantity_item_changes_available?(subscription), do: not braintree_processor?(subscription)

defp braintree_processor?(%{processor: processor}),
  do: normalize_processor(processor) == "braintree"
```

Use these exact gates to omit unavailable menu items, not to render disabled-looking controls.

**Related resources seam to extend** (lines 1191-1228):
```elixir
defp related_items(subscription, mount_path, scope) do
  customer_items =
    if subscription.customer do
      customer = subscription.customer
      label = customer.name || customer.email || customer.id

      [
        %{
          icon: :users,
          label: "Customer",
          value: label,
          href: ScopedPath.build(mount_path, "/customers/#{subscription.customer_id}", scope)
        }
      ]
    else
      []
    end

  customer_items ++
    [
      %{icon: :invoices, label: "Invoices", href: ScopedPath.build(mount_path, "/invoices", scope, %{"subscription_id" => subscription.id})},
      %{icon: :events, label: "Events", href: ScopedPath.build(mount_path, "/events", scope, %{"subject_type" => "Subscription", "subject_id" => subscription.id})}
    ]
end
```

Move unique duplicate-card links (`charges-for-customer`, events index) into this list and delete `data-role="subscription-related-billing"`.

---

### `accrue_admin/lib/accrue_admin/components/overlay.ex` (component, event-driven overlay)

**Analogs:** `detail_drawer.ex`, `step_up_auth_modal.ex`, and local LiveView `.portal`.

**Component attr/slot style** (`detail_drawer.ex` lines 6-20):
```elixir
use Phoenix.Component

attr(:id, :string, default: "detail-drawer")
attr(:open, :boolean, default: false)
attr(:title, :string, required: true)
attr(:subtitle, :string, default: nil)
attr(:eyebrow, :string, default: "Details")
attr(:close_label, :string, default: "Close")
attr(:close_href, :string, default: nil)
attr(:close_event, :string, default: nil)
attr(:class, :string, default: nil)
attr(:rest, :global, include: ~w(phx-click phx-target))
slot(:actions)
slot(:inner_block, required: true)
slot(:footer)
```

Use the same public API style for `overlay/1`: attrs before `def`, slots explicit, `:rest` for LiveView event attributes.

**Server-driven open/close and FocusTrap pattern** (`detail_drawer.ex` lines 31-45):
```elixir
<section
  :if={@open}
  id={@id}
  class={["ax-detail-drawer-shell", @class]}
  data-component-group="drawer-form"
  role="dialog"
  aria-modal="true"
  aria-labelledby={"#{@id}-title"}
  aria-describedby={@description_id}
  phx-hook="FocusTrap"
  data-focus-trap-close-event={@focus_trap_close_event}
  data-focus-trap-close-target={@focus_trap_close_target}
  data-focus-trap-fallback={@focus_trap_fallback}
  phx-mounted={Phoenix.LiveView.JS.show(..., time: 240)}
  phx-remove={Phoenix.LiveView.JS.hide(..., time: 140)}
>
```

Keep the LiveView `:if={@open}` model. Add portal, scroll-lock/inert behavior, and presentation-specific classes around this pattern.

**Backdrop + panel micro-stack** (`detail_drawer.ex` lines 48-82):
```elixir
<div
  class="ax-detail-drawer-backdrop"
  aria-hidden="true"
  phx-click={@focus_trap_close_event}
  phx-target={@focus_trap_close_target}
></div>
<aside class="ax-detail-drawer">
  <header class="ax-detail-drawer-header">...</header>
  <div class="ax-detail-drawer-body">
    <%= render_slot(@inner_block) %>
  </div>
  <footer :if={@footer != []} class="ax-detail-drawer-footer">
    <%= render_slot(@footer) %>
  </footer>
</aside>
```

Overlay should preserve the shell/backdrop/panel split, but genericize class names to `ax-overlay-*` with `data-presentation`.

**Modal analog** (`step_up_auth_modal.ex` lines 18-32):
```elixir
<section
  :if={@pending}
  id="accrue-admin-step-up-dialog"
  class="ax-step-up-modal-shell"
  data-component-group="modal-confirm"
  role="dialog"
  aria-modal="true"
  aria-labelledby="step-up-title"
  aria-describedby="step-up-description"
  phx-hook="FocusTrap"
  data-focus-trap-close-event="step_up_dismiss"
  data-focus-trap-fallback="#step-up-title"
  data-focus-trap-initial="#step-up-code"
  phx-mounted={Phoenix.LiveView.JS.push_focus() |> Phoenix.LiveView.JS.focus_first(to: "#accrue-admin-step-up-dialog")}
  phx-remove={Phoenix.LiveView.JS.pop_focus()}
>
```

If `StepUpAuthModal` migration is in scope, wrap its modal presentation through `<.overlay presentation={:modal}>`. If deferred, keep this as the temporary old shell only.

**Portal API confirmed locally** (`phoenix_component.ex` lines 3570-3594):
```elixir
attr.(:id, :string, required: true)
attr.(:target, :string, required: true, doc: "A CSS selector that identifies the target. The target must be unique.")
attr.(:class, :any, default: nil, doc: "The class to apply to the portal wrapper.")
attr.(:container, :string, default: "div", doc: "The HTML tag to use as the portal wrapper.")
slot.(:inner_block, required: true)

def portal(assigns) do
  ~H"""
  <template id={@id} data-phx-portal={@target}>
    <.dynamic_tag tag_name={@container} id={"_lv_portal_wrap_" <> @id} class={@class}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
  </template>
  """
end
```

Pinned `phoenix_live_view` is `1.1.31` (`mix.lock` line 66). Use `<.portal target="#ax-overlay-root">`.

---

### `accrue_admin/lib/accrue_admin/components/detail.ex` (component, request-response render)

**Analog:** same file.

**Component style** (lines 11-35):
```elixir
use Phoenix.Component

attr(:title, :string, required: true)
attr(:class, :any, default: nil)
slot(:actions)
slot(:inner_block, required: true)

def detail_section(assigns) do
  ~H"""
  <section class={["ax-detail-section", @class]}>
    <header class="ax-detail-section-head">
      <h3 class="ax-detail-section-title"><%= @title %></h3>
      <div :if={@actions != []} class="ax-detail-section-actions"><%= render_slot(@actions) %></div>
    </header>
    <%= render_slot(@inner_block) %>
  </section>
  """
end
```

**Read-only field list not to overload** (lines 44-55):
```elixir
attr(:fields, :list, required: true)
attr(:class, :any, default: nil)

def detail_field_list(assigns) do
  ~H"""
  <dl class={["ax-field-list", @class]}>
    <div :for={field <- @fields} class="ax-field">
      <dt class="ax-field-label"><%= field.label %></dt>
      <dd class="ax-field-value"><%= field.value %></dd>
    </div>
  </dl>
  """
end
```

Add `summary_list/1` as a new semantic `<dl>` with optional row action cell. Do not retrofit actions into `detail_field_list/1`.

**Summary wrapper to preserve** (lines 62-80):
```elixir
attr(:eyebrow, :string, default: nil)
attr(:title, :string, required: true)
slot(:status)
slot(:facts)
slot(:actions)

def summary_card(assigns) do
  ~H"""
  <header class="ax-card ax-summary-card" data-component-group="detail-header-metadata-actions">
    <div class="ax-summary-main">
      <p :if={@eyebrow} class="ax-eyebrow"><%= @eyebrow %></p>
      <div class="ax-summary-title-row">
        <h1 class="ax-summary-title"><%= @title %></h1>
        <%= render_slot(@status) %>
      </div>
      <div :if={@facts != []} class="ax-summary-facts"><%= render_slot(@facts) %></div>
    </div>
    <div :if={@actions != []} class="ax-summary-actions"><%= render_slot(@actions) %></div>
  </header>
  """
end
```

Render `summary_list/1` inside this wrapper.

---

### `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` (component, event-driven menu)

**Analog:** existing link-shaped dropdown plus `dropdown.js`.

**Current dropdown structure** (`dropdown_menu.ex` lines 8-38):
```elixir
attr(:label, :string, required: true)
attr(:items, :list, default: [])

def dropdown_menu(assigns) do
  ~H"""
  <details class="ax-dropdown" data-component-group="toolbar-search-filter-sort" data-phase191-focus="dropdown">
    <summary class="ax-button ax-button-secondary ax-dropdown-trigger" data-phase191-focus="dropdown-trigger">
      <span><%= @label %></span>
      <span aria-hidden="true">▾</span>
    </summary>

    <div class="ax-dropdown-panel" aria-label={@label} data-phase191-focus="dropdown-panel" data-floating-panel="dropdown">
      <a :for={item <- @items} href={item[:href] || "#"} class={["ax-dropdown-item", item[:danger] && "ax-dropdown-item-danger"]}>
        <span class="ax-dropdown-item-label"><%= item[:label] %></span>
        <span :if={item[:description]} class="ax-dropdown-item-description"><%= item[:description] %></span>
      </a>
    </div>
  </details>
  """
end
```

Add `action_menu/1` either here or in a new component module that follows this shape. Use `<button role="menuitem" phx-click>` instead of `<a>`.

**Dismissal grammar to reuse** (`dropdown.js` lines 1-35):
```javascript
function closeDropdown(details, { restoreFocus = false } = {}) {
  details.removeAttribute("open");

  if (restoreFocus) {
    focusSummary(details);
  }
}

export function initDropdowns() {
  document.addEventListener("click", (event) => {
    document.querySelectorAll("details.ax-dropdown[open]").forEach((details) => {
      if (!details.contains(event.target)) {
        closeDropdown(details, { restoreFocus: true });
      }
    });
  });

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    document.querySelectorAll("details.ax-dropdown[open]").forEach((details) => {
      closeDropdown(details, { restoreFocus: true });
    });
  });
}
```

Do not add scroll-lock, inert, or FocusTrap to the action menu.

---

### `accrue_admin/lib/accrue_admin/components/related_resources.ex` (component, request-response render)

**Analog:** same file.

**Current strip** (lines 25-46):
```elixir
attr(:title, :string, default: "Related billing")
attr(:items, :list, required: true)

def related_resources(assigns) do
  ~H"""
  <section :if={@items != []} class="ax-card ax-related" aria-label={@title}>
    <header class="ax-related-head">
      <h3 class="ax-related-title"><%= @title %></h3>
    </header>
    <ul class="ax-related-list">
      <li :for={item <- @items}>
        <a class="ax-related-item" href={item.href}>
          <span class="ax-related-icon"><Icon.icon name={item.icon} size="sm" /></span>
          <span class="ax-related-text">
            <span class="ax-related-label"><%= item.label %></span>
            <span :if={item[:value]} class="ax-related-value"><%= item.value %></span>
          </span>
          <Icon.icon name={:chevron_right} size="sm" class="ax-related-chevron" />
        </a>
      </li>
    </ul>
  </section>
  """
end
```

Add `data-ax-related-resources` to this canonical strip and ensure subscription renders exactly one of it.

---

### `accrue_admin/lib/accrue_admin/layouts.ex` and `app_shell.ex` (layout, request-response render)

**Analog:** existing root layout and app shell.

**Root placement** (`layouts.ex` lines 33-50):
```elixir
~H"""
<!DOCTYPE html>
<html lang="en" class="accrue-admin">
  <head>...</head>
  <body class="accrue-admin-shell">
    <%= @inner_content %>
    <style nonce={@csp_nonce}><%= Phoenix.HTML.raw(@runtime_theme_style) %></style>
    <script :if={@assets_js_path} defer src={@assets_js_path}></script>
  </body>
</html>
"""
```

Place `<div id="ax-overlay-root"></div>` as a body-level sibling of `@inner_content`, before scripts. It must not live inside `#accrue-admin-shell`.

**Inert target already exists** (`app_shell.ex` lines 50-57):
```elixir
<div
  id="accrue-admin-shell"
  class="ax-shell"
  data-mount-path={@mount_path}
  data-connection-state="connected"
  data-stale-disable-selector={@stale_disable_selector}
  phx-hook="ConnectionState"
>
```

Scroll-lock/inert JS should target this ID directly.

---

### `accrue_admin/assets/js/hooks/scroll_lock.js` and `focus_trap.js` (utility/hook, DOM event-driven)

**Analog:** `focus_trap.js`.

**Hook lifecycle shape** (`focus_trap.js` lines 31-68):
```javascript
export const FocusTrap = {
  mounted() {
    this.previouslyFocused = null;
    this.focusTrapActive = false;
    this.initialFocusTimer = null;
    this.handleFocusTrapKeydown = this.handleFocusTrapKeydown.bind(this);
    this.handleFocusTrapFocusin = this.handleFocusTrapFocusin.bind(this);

    if (this.isFocusTrapActive()) {
      this.activateFocusTrap();
    }
  },

  updated() {
    const active = this.isFocusTrapActive();

    if (active && !this.focusTrapActive) {
      this.activateFocusTrap();
    } else if (!active && this.focusTrapActive) {
      this.deactivateFocusTrap({ restoreFocus: true });
    }
  },

  destroyed() {
    this.deactivateFocusTrap({ restoreFocus: true });
  },
```

If `ScrollLock` is a LiveView hook, copy this lifecycle shape. If it is a plain module, still test module-level counters.

**Escape + focus restore pattern** (`focus_trap.js` lines 132-184):
```javascript
handleFocusTrapKeydown(event) {
  if (!this.focusTrapActive) return;

  if (event.key === "Escape") {
    event.preventDefault();
    event.stopPropagation?.();
    this.dispatchFocusTrapClose();
    return;
  }
  ...
},

dispatchFocusTrapClose() {
  const eventName = this.el.dataset?.focusTrapCloseEvent;
  if (!eventName) return;

  const target = this.el.dataset?.focusTrapCloseTarget;
  if (target && typeof this.pushEventTo === "function") {
    this.pushEventTo(target, eventName, {});
  } else if (typeof this.pushEvent === "function") {
    this.pushEvent(eventName, {});
  }
}
```

Overlay close events should use the same data-attribute contract so Escape and backdrop share server behavior.

**Hook registration** (`app.js` lines 1-10, 37-48):
```javascript
import { initDropdowns } from "./hooks/dropdown";
import { CommandPalette } from "./hooks/command_palette";
import { ConnectionState } from "./hooks/connection_state";
import { FocusTrap } from "./hooks/focus_trap";

ready(() => {
  initClipboardControls();
  initThemeControls();
  initShellNav();
  initDropdowns();
});

const liveSocket = new LiveSocket("/live", Socket, {
  params: csrfToken ? { _csrf_token: csrfToken } : {},
  hooks: { CommandPalette, ConnectionState, FocusTrap, Clipboard }
});
```

Register any `ScrollLock`/`Overlay` hook here and rebuild assets.

---

### CSS (`theme.css`, `app.css`) (config, render transform)

**Token constraints** (`theme.css` lines 25-33, 52-64, 128-135):
```css
--ax-space-xs: 0.25rem;
--ax-space-sm: 0.5rem;
--ax-space-md: 1rem;
--ax-space-lg: 1.5rem;
--ax-space-xl: 2rem;
--ax-space-2xl: 3rem;
--ax-space-3xl: 4rem;

--ax-dur-1: 120ms;
--ax-dur-2: 180ms;
--ax-dur-3: 240ms;
--ax-dur-exit: 140ms;
--ax-ease-out: cubic-bezier(0.2, 0, 0, 1);
--ax-ease-in: cubic-bezier(0.4, 0, 1, 1);

--ax-z-dropdown: 200;
--ax-z-popover: 300;
--ax-z-drawer: 400;
--ax-z-modal: 500;
--ax-z-toast: 600;
```

No new spacing, motion, or z tokens should be introduced for Phase 195.

**Existing drawer/modal layering** (`app.css` lines 1332-1375, 1405-1428):
```css
.ax-detail-drawer-shell {
  position: fixed;
  inset: 0;
  z-index: var(--ax-z-drawer);
  isolation: isolate;
}

.ax-detail-drawer-backdrop {
  position: absolute;
  inset: 0;
  z-index: 0;
}

.ax-detail-drawer {
  position: absolute;
  z-index: 1;
  display: grid;
  grid-template-rows: auto minmax(0, 1fr) auto;
  overflow: hidden;
}

.ax-step-up-modal-shell {
  position: fixed;
  inset: 0;
  z-index: var(--ax-z-modal);
  display: grid;
  place-items: center;
  isolation: isolate;
}
```

The new overlay CSS should keep one isolated shell with scrim `z-index:0` and panel `z-index:1`.

**Current drawer geometry to fix** (`app.css` lines 1738-1743):
```css
.ax-detail-drawer {
  inset: 0 0 0 auto;
  width: min(42rem, 100vw);
  min-height: 100vh;
  border-left: 1px solid var(--ax-border);
}
```

Update to the UI-SPEC: desktop right drawer `width: min(34rem, 92vw)`, mobile bottom sheet with translateY entry.

**Dropdown CSS to extend for action menu** (`app.css` lines 2458-2541):
```css
.ax-dropdown {
  position: relative;
  max-width: 100%;
  width: fit-content;
}

.ax-dropdown-panel {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  min-width: 15rem;
  max-width: min(22rem, calc(100vw - 2rem));
  max-height: min(24rem, calc(100vh - 6rem));
  overflow: auto;
  overscroll-behavior: contain;
  z-index: var(--ax-z-dropdown);
}

details.ax-dropdown .ax-dropdown-panel {
  opacity: 0;
  transform: translateY(calc(-1 * var(--ax-rise-sm)));
  pointer-events: none;
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),
    transform var(--ax-dur-2) var(--ax-ease-out);
}
```

Add `transform-origin: top right` for action menu; reuse danger item styles.

**Summary/detail CSS analog** (`app.css` lines 3555-3666):
```css
.ax-summary-card {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--ax-space-lg);
  flex-wrap: wrap;
}

.ax-summary-title {
  margin: 0;
  font-size: var(--ax-type-2xl);
  font-weight: 600;
  min-width: 0;
  overflow-wrap: anywhere;
}

.ax-field-list {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--ax-space-md);
  margin: 0;
}
```

Add `ax-summary-list`/row/action CSS near this section.

**Accessible hidden text + focus ring** (`app.css` lines 2932-2942, 3720-3738):
```css
.ax-visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.ax-button:focus-visible,
.ax-dropdown-item:focus-visible,
.ax-related-item:focus-visible,
[data-ax-force~="focus"] {
  border-color: var(--ax-focus-ring);
}
```

Use visually hidden context for row actions and menu items.

---

### Copy files and generated fixture (utility/fixture, transform + batch)

**Analogs:** `copy/subscription.ex`, `copy.ex`.

**Current action labels to relabel** (`copy/subscription.ex` lines 20-31):
```elixir
def subscription_action_cancel_now, do: "Cancel now"
def subscription_action_cancel_at_period_end, do: "Cancel at period end"
def subscription_action_resume, do: "Resume"
def subscription_action_swap_plan, do: "Swap plan"
def subscription_action_update_quantity, do: "Update quantity"
def subscription_action_add_item, do: "Add item"
def subscription_action_update_item_quantity, do: "Update item quantity"
def subscription_action_remove_item, do: "Remove item"
def subscription_action_pause_collection, do: "Pause collection"
def subscription_action_create_comp_replacement, do: "Create comp replacement"
def subscription_action_preview_heading, do: "Preview upcoming invoice"
def subscription_action_preview_total_label, do: "Preview total"
```

Change labels here for `Change plan`, `Cancel renewal`, `Cancel immediately`, and `Comp this subscription`. Add new summary/action-band copy here.

**Facade delegates** (`copy.ex` lines 20-39):
```elixir
defdelegate subscription_detail_eyebrow(), to: Subscription
defdelegate subscription_action_cancel_now(), to: Subscription
defdelegate subscription_action_cancel_at_period_end(), to: Subscription
defdelegate subscription_action_resume(), to: Subscription
defdelegate subscription_action_swap_plan(), to: Subscription
defdelegate subscription_action_pause_collection(), to: Subscription
defdelegate subscription_action_create_comp_replacement(), to: Subscription
defdelegate subscription_confirm_workflow_message(action_type, opts), to: Subscription
```

Add delegates only for new copy functions used outside `AccrueAdmin.Copy.Subscription`. Regenerate `examples/accrue_host/e2e/generated/copy_strings.json` after copy changes.

---

### Storybook files and component registry (Storybook story, request-response dev render)

**Analogs:** `storybook/components/button.story.exs`, `storybook/_support/registry_story.ex`, `component_registry.ex`.

**Story module shape** (`button.story.exs` lines 11-18):
```elixir
use PhoenixStorybook.Story, :component

def function, do: &AccrueAdmin.Components.Button.button/1

def variations do
  if Code.ensure_loaded?(AccrueAdmin.Storybook.RegistryStory) do
    AccrueAdmin.Storybook.RegistryStory.variations_for("button")
  else
    []
  end
end
```

Use this for registry-backed component stories. For overlay/action-menu states that need slots or custom markup, use the same `PhoenixStorybook.Story, :component` entry point and return explicit variations.

**Registry variation mapper** (`registry_story.ex` lines 21-40):
```elixir
@spec variations_for(String.t()) :: [Variation.t()]
def variations_for(family) when is_binary(family) do
  family
  |> AccrueAdmin.Dev.ComponentRegistry.variants_for()
  |> Enum.flat_map(fn entry ->
    specimens = entry[:specimens] || []

    specimens
    |> Enum.with_index()
    |> Enum.map(fn {specimen, idx} ->
      %Variation{
        id: String.to_atom(id_str),
        attributes: specimen[:props] || %{},
        slots: if(specimen[:content], do: [specimen[:content]], else: []),
        description: specimen[:label] || ""
      }
    end)
  end)
end
```

**Registry specimen shape** (`component_registry.ex` lines 300-365):
```elixir
%{
  family: "button",
  variant: "primary",
  ax_class: "ax-button ax-button-primary",
  tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"],
  applicable_states: ["default", "hover", "focus", "active", "pressed", "disabled", "loading", "overflow"],
  na_states: [
    %{state: "selected", reason: "button has no selection state — use aria-pressed for toggle buttons separately"}
  ],
  specimens: [
    %{label: "Default", props: %{variant: "primary", type: "button"}, content: "Save changes"},
    %{label: "Long label (overflow)", props: %{variant: "primary", type: "button"}, content: "Export all subscription events to CSV"}
  ]
}
```

If new stories use `RegistryStory`, add entries here. Otherwise keep standalone stories concrete.

---

### Tests: component, LiveView, JS, and Playwright

**Component test analog** (`overlay_components_test.exs` lines 11-58):
```elixir
describe "DetailDrawer focus and layer contract" do
  test "renders FocusTrap attributes with stable labels and fallback focus target" do
    html =
      render_component(fn assigns ->
        ~H"""
        <DetailDrawer.detail_drawer id="webhook-drawer" open title="Webhook event" phx-click="close_webhook_drawer" phx-target="#webhook-live">
          Drawer payload content
        </DetailDrawer.detail_drawer>
        """
      end)

    assert html =~ ~s(data-component-group="drawer-form")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(phx-hook="FocusTrap")
    assert html =~ ~s(data-focus-trap-close-event="close_webhook_drawer")
  end
end
```

Update this file to assert `.portal` template/source, `data-phx-portal="#ax-overlay-root"`, presentation attrs, and scroll-lock hook wiring. Portal docs warn LiveViewTest cannot query teleported children normally; assert rendered portal HTML and use Playwright for real DOM target.

**LiveView test analog** (`subscription_live_test.exs` lines 1-77):
```elixir
defmodule AccrueAdmin.SubscriptionLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Subscriptions
  alias AccrueAdmin.TestRepo

  import Ecto.Query

  defmodule AuthAdapter do
    @behaviour Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify admin action"}
    def verify_step_up(_user, %{"code" => "123456"}, action), do: :ok
  end
end
```

Keep this fixture/auth structure.

**Old assertions to replace** (`subscription_live_test.exs` lines 127-156, 305-354):
```elixir
assert has_element?(view, "[data-role='swap-plan-form']")
assert has_element?(view, "[data-role='quantity-update-form']")
...
html = render_submit(element(view, "[data-role='swap-plan-form']"), %{
  "action_type" => "swap_plan",
  "new_price_id" => "price_pro",
  "proration" => "create_prorations"
})
```

New tests should assert no initial action-band forms, primary/action-menu selectors, drawer-open after selecting an action, and provider-pruned menu items for Braintree.

**StepUp behavior test to preserve** (`subscription_live_test.exs` lines 158-197):
```elixir
html =
  render_submit(
    element(view, "[data-role='cancel-now-form']"),
    %{"action_type" => "cancel_now", "source_event_id" => Integer.to_string(source_event.id)}
  )

assert html =~ "Confirm action"

html = render_click(element(view, "[data-role='confirm-action']"))
assert html =~ "Step-up required"

html = render_submit(element(view, "form[phx-submit='step_up_submit']"), %{"code" => "123456"})
assert html =~ Copy.subscription_action_recorded_info()
```

Adapt trigger selectors, but keep destructive action requiring StepUp and audit linkage.

**JS hook test analog** (`focus_trap_test.mjs` lines 107-176):
```javascript
test("Tab and Shift+Tab wrap across active overlay focus targets", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const first = focusable("first", documentLike);
  const last = focusable("last", documentLike);
  const root = rootElement([first, last], { focusTrapCloseEvent: "close_overlay" });

  withDocument(documentLike, () => {
    trigger.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    ...
  });
});
```

Create `scroll_lock_test.mjs` with this fake DOM style. Cover lock ref count, saved scroll restore, scrollbar compensation, and `#accrue-admin-shell[inert]`.

**Playwright spec scaffold** (`admin-spec-overview-phase194.spec.js` lines 16-25, 31-45):
```javascript
const { test, expect } = require("@playwright/test");

const {
  PHASE191_VIEWPORTS,
  setPhase191Theme,
  assertFocusWithin,
  assertTopPointerTarget,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}
```

Create `admin-spec-detail-phase195.spec.js` by copying this scaffold and importing the Phase 191 helpers.

**Page-flow assertions to reuse** (`phase191-page-flow-helpers.js` lines 152-224):
```javascript
async function assertFocusWithin(page, target, label = "active overlay") { ... }

async function assertTopPointerTarget(locator, label = "primary control") {
  const result = await locator.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const top = document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2);
    return {
      visible,
      offscreen,
      receivesEvents: top === element || element.contains(top),
      topLabel: top ? `${top.tagName.toLowerCase()}${top.id ? `#${top.id}` : ""}` : "none",
    };
  });

  if (!result.visible || result.offscreen || !result.receivesEvents) {
    throw new Error(`Phase 191 pointer assertion failed: ${label} is not the top reachable target (${JSON.stringify(result)})`);
  }
}
```

Use these for drawer primary action and at least one focusable drawer control. Add a body-scroll-unchanged assertion in the new spec.

**Package script pattern** (`package.json` lines 5-11):
```json
"e2e": "env -u NO_COLOR playwright test",
"e2e:phase191": "env -u NO_COLOR playwright test e2e/admin-page-flow-phase191.spec.js --timeout=60000 --workers=1",
"e2e:phase194": "env -u NO_COLOR playwright test e2e/admin-spec-overview-phase194.spec.js --timeout=60000 --workers=1",
"e2e:a11y": "env -u NO_COLOR playwright test e2e/admin-a11y.spec.js",
"e2e:install": "playwright install chromium"
```

Add `e2e:phase195` with the same timeout/workers style.

**Page-flow fixture pattern** (`baseline-manifest.js` lines 83-98, 199-211):
```javascript
const PAGE_FLOWS = [
  ["subscriptions", "/billing/subscriptions", "Triage active, trialing, past-due, and canceled subscriptions."],
  [
    "subscription-detail",
    "/billing/subscriptions/:subscription_id",
    "Inspect subscription state, customer relationship, invoices, and actions.",
    { fixture: "dashboard", params: ["subscription_id"] },
  ],
];

function pageSurface([surface, route, persona_job, routeBuilder]) {
  return {
    surface,
    surface_type: "page-flow",
    persona_job,
    owner_phase: OWNER_PHASES.page,
    seed: "operator-flows+dashboard+edge-states",
    states: FLOW_STATES,
    projects: PROJECTS.map((project) => project.name),
    themes: THEMES,
    route,
    ...(routeBuilder ? { routeBuilder } : {}),
  };
}
```

The route already exists. Add focused Phase 195 cells/assertions without inventing a new route model.

## Shared Patterns

### LiveView Component Conventions
**Source:** `detail.ex`, `detail_drawer.ex`, `dropdown_menu.ex`
**Apply to:** `overlay.ex`, `summary_list/1`, `action_menu/1`, drawer/modal wrappers

Use `use Phoenix.Component`, `attr/slot` declarations, `~H` templates, and small private helpers. Keep components presentation-only; do not move billing calls into components.

### Auth And Destructive Actions
**Source:** `subscription_live.ex` lines 32, 79-104, 669-677
**Apply to:** `subscription_live.ex`, action menu, drawer confirm flow

`@destructive_actions ~w(cancel_now comp_subscription)` must continue to route through `StepUp.require_fresh/4`. Destructive menu items open the confirm/step-up path; they do not execute directly from menu click.

### Overlay Substrate
**Source:** `detail_drawer.ex`, `step_up_auth_modal.ex`, `focus_trap.js`, LiveView `.portal`
**Apply to:** `overlay.ex`, `detail_drawer.ex`, optional `step_up_auth_modal.ex`

Portal to `#ax-overlay-root`, isolate shell layering, reuse `FocusTrap`, wire backdrop and Escape to the same close event, and add ref-counted scroll lock plus `inert` on `#accrue-admin-shell` for modal/drawer presentations only.

### CSS Tokens And Bundle
**Source:** `theme.css`, `app.css`
**Apply to:** all visual changes

Use existing `--ax-space-*`, `--ax-dur-*`, `--ax-ease-*`, and `--ax-z-*` tokens. After CSS or JS source edits, run `mix accrue_admin.assets.build` so `priv/static/accrue_admin.css` and `.js` are updated.

### Copy And Fixture Coupling
**Source:** `copy/subscription.ex`, `copy.ex`
**Apply to:** action labels, summary row labels, error/empty copy

Copy goes through `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Subscription`. After copy changes, run `mix accrue_admin.export_copy_strings` and commit `examples/accrue_host/e2e/generated/copy_strings.json`. Research mentions `accrue_admin/e2e/generated/copy_strings.json`, but the existing fixture path found in this workspace is under `examples/accrue_host/e2e/generated/`.

### Testing
**Source:** `overlay_components_test.exs`, `subscription_live_test.exs`, `focus_trap_test.mjs`, Phase 191 helpers
**Apply to:** component tests, LiveView tests, JS hook tests, Playwright page-flow

Keep ExUnit render assertions for component HTML and LiveView event flow. Use Node `node --test` for hook modules. Use Playwright for real portal DOM, top pointer target, body-scroll lock, inert, focus trap, Escape/backdrop dismissal, and desktop/mobile drawer geometry.

## No Analog Found

None. New primitives have strong role-match analogs in the existing drawer/modal/dropdown/hook/story/test code.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin`, `accrue_admin/assets`, `accrue_admin/test`, `accrue_admin/e2e`, `storybook/`, local `phoenix_live_view` deps, page-flow baseline artifacts.

**Files scanned:** 70+ direct file paths via `rg --files` plus targeted `rg` matches.

**Important existing paths:** `AGENTS.md` absent; `.codex/skills/` absent; `.agents/skills/` absent; `CLAUDE.md` read.

**Pattern extraction date:** 2026-06-26
