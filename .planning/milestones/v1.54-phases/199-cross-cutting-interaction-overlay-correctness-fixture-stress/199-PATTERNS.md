# Phase 199: Cross-cutting interaction/overlay correctness + fixture stress - Pattern Map

**Mapped:** 2026-06-29  
**Files analyzed:** 63 target files and file families  
**Analogs found:** 61 / 63  
**Scope:** `accrue_admin` operator UI only

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` | test | request-response + event-driven | `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`, `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` | exact |
| `accrue_admin/package.json` | config | batch | existing `e2e:phase191`...`e2e:phase198` scripts | exact |
| `accrue_admin/e2e/phase191-page-flow-helpers.js` | utility | transform/assertion | same file helper exports | exact |
| `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` | test | request-response + event-driven | same file target matrix | exact |
| `accrue_admin/e2e/admin-spec-list-phase197.spec.js` | test | request-response + CRUD | same file list target matrix | exact |
| `accrue_admin/e2e/reduced-motion.spec.js` | test | transform | same file token-duration checks | exact |
| `accrue_admin/e2e/spike-overlay-portal.spec.js` | test | event-driven + transform | same file portal/stacking proof | role-match |
| `accrue_admin/lib/accrue_admin/components/overlay.ex` | component | event-driven | same file canonical substrate | exact |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | event-driven | same file wrapper around `Overlay` | exact |
| `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` | component | event-driven | same file wrapper around `Overlay` | exact |
| `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` | component | event-driven | same file native disclosure menu | exact |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | component | event-driven + request-response | same file command palette | exact |
| `accrue_admin/lib/accrue_admin/components/theme_picker.ex` | component | event-driven + local persistence | same file segmented radiogroup | exact |
| `accrue_admin/lib/accrue_admin/layouts.ex` | component/config | request-response | same file `#ax-overlay-root` and anti-FOUC script | exact |
| `accrue_admin/assets/js/hooks/overlay.js` | hook | event-driven | same file `FocusTrap` + `ScrollLock` composition | exact |
| `accrue_admin/assets/js/hooks/focus_trap.js` | hook | event-driven | same file keyboard/focus loop | exact |
| `accrue_admin/assets/js/hooks/scroll_lock.js` | utility | event-driven | same file ref-counted lock | exact |
| `accrue_admin/assets/js/hooks/dropdown.js` | hook | event-driven | same file outside-click/Escape close | exact |
| `accrue_admin/assets/js/hooks/command_palette.js` | hook | event-driven | same file keyboard/palette loop | exact |
| `accrue_admin/assets/js/hooks/accrue_theme.js` | hook | event-driven + local persistence | same file production theme key | exact |
| `accrue_admin/assets/css/app.css` | config | transform | existing overlay, drawer, dropdown, palette CSS blocks | exact |
| `accrue_admin/assets/css/theme.css` | config | transform | existing motion/theme token blocks | exact |
| `accrue_admin/priv/static/accrue_admin.css` | generated asset | batch | `mix accrue_admin.assets.build` output from source CSS | role-match |
| `accrue_admin/priv/static/accrue_admin.js` | generated asset | batch | `mix accrue_admin.assets.build` output from source JS | role-match |
| `accrue_admin/lib/accrue_admin/live/customers_live.ex` | component/page | CRUD + request-response | same file list-state + copy pattern | exact |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | component/page | CRUD + request-response | `customers_live.ex`, `admin-spec-list-phase197.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/charges_live.ex` | component/page | CRUD + request-response | `customers_live.ex`, `admin-spec-list-phase197.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | component/page | CRUD + event-driven | `admin-spec-list-phase197.spec.js`, `DataTable` | exact |
| `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex` | component/page | CRUD + request-response | `customers_live.ex`, `admin-spec-list-phase197.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | component/page | CRUD + request-response | `customers_live.ex`, `admin-spec-list-phase197.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/coupons_live.ex` | component/page | CRUD + request-response | `admin-spec-list-phase197.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex` | component/page | CRUD + request-response | `admin-spec-list-phase197.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | component/page | batch + request-response | `admin-spec-list-phase197.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | component/page | CRUD + event-driven | `invoice_live.ex`, `connect_account_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | component/page | CRUD + event-driven | same file drawer/step-up flow | exact |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | component/page | CRUD + event-driven | `invoice_live.ex`, `admin-spec-detail-phase198.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | component/page | event-driven | `invoice_live.ex`, `connect_account_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` | component/page | CRUD + event-driven | same file platform-fee drawer/step-up | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | component/page | CRUD + event-driven | `invoice_live.ex`, `admin-spec-detail-phase195.spec.js` | exact |
| `accrue_admin/lib/accrue_admin/live/coupon_live.ex` | component/page | request-response | `admin-spec-detail-phase198.spec.js` | role-match |
| `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` | component/page | request-response | `admin-spec-detail-phase198.spec.js` | role-match |
| `accrue_admin/lib/accrue_admin/live/event_live.ex` | component/page | batch + request-response | `admin-spec-detail-phase198.spec.js` | role-match |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | component/page | request-response | `admin-spec-detail-phase198.spec.js` analytics targets | role-match |
| `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex` | component/page | request-response | `admin-spec-detail-phase198.spec.js` analytics targets | role-match |
| `accrue_admin/test/js/scroll_lock_test.mjs` | test | event-driven | same file fake-browser ref-count tests | exact |
| `accrue_admin/test/js/focus_trap_test.mjs` | test | event-driven | same file fake-document keyboard tests | exact |
| `accrue_admin/test/js/dropdown_test.mjs` | test | event-driven | same file fake-document dropdown tests | exact |
| `accrue_admin/test/js/command_palette_test.mjs` | test | event-driven | same file hook method tests | exact |
| `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` | test | request-response + transform | same file component/CSS contracts | exact |
| `accrue_admin/test/accrue_admin/components/global_search_test.exs` | test | request-response | same file command-palette markup tests | exact |
| `accrue_admin/test/accrue_admin/components/theme_picker_test.exs` | test | request-response | same file radiogroup tests | exact |
| `accrue_admin/test/accrue_admin/theme_test.exs` | test | request-response + local persistence | same file cookie/session/anti-FOUC tests | exact |
| `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs` | test | batch + CRUD | same file deterministic seed contract | exact |
| `accrue_admin/test/accrue_admin/copy_test.exs` | test | transform | same file CPY state/copy checks | exact |
| `accrue_admin/test/accrue_admin/live/*_live_test.exs` | test | request-response + event-driven | corresponding existing LiveView tests and `overlay_components_test.exs` | role-match |
| `accrue_admin/test/support/e2e_fixtures.ex` | utility | batch + CRUD | same file deterministic seed helpers | exact |
| `accrue_admin/test/support/e2e_plug.ex` | route/middleware | request-response | same file seed endpoints | exact |
| `accrue_admin/test/support/list_contracts.ex` | utility | transform | same file list-state contract rows | exact |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | component | CRUD + request-response | same file state/empty/filter contract | exact |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | component | request-response | same file summary-list hidden context | exact |
| `accrue_admin/lib/accrue_admin/components/empty_state.ex` | component | request-response | same file non-interactive empty hero | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` | utility | transform | same file delegator and shared copy helpers | exact |
| `accrue_admin/lib/accrue_admin/copy/*.ex` | utility | transform | `copy/invoice.ex`, `copy/connect.ex` | exact |
| `examples/accrue_host/e2e/generated/copy_strings.json` | generated fixture | batch | `mix accrue_admin.export_copy_strings --out ...` | role-match |

## Pattern Assignments

### `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` (test, request-response + event-driven)

**Analog:** `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`

**Imports/helper pattern** (lines 10-19):
```javascript
const { test, expect } = require("@playwright/test");

const {
  setPhase191Theme,
  assertFocusWithin,
  assertTopPointerTarget,
  assertNoHorizontalClip,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });
```

**Explicit target matrix pattern** (lines 21-58, 73-101):
```javascript
const DETAIL_TARGETS = Object.freeze([
  {
    name: "Customer",
    route: ({ dashboard }) => `/billing/customers/${dashboard.customer_id}`,
    customerPeerNav: true,
  },
  {
    name: "Invoice",
    route: ({ edgeStates }) => `/billing/invoices/${edgeStates.jpy_invoice_id}`,
  },
]);

const DRAWER_FLOW_TARGETS = Object.freeze([
  {
    name: "Invoice",
    route: ({ edgeStates }) => `/billing/invoices/${edgeStates.jpy_invoice_id}`,
    trigger: /void invoice|mark uncollectible/i,
    confirm: /confirm|void|mark uncollectible|continue/i,
    preferMenu: true,
  },
]);
```

**Seed/login pattern** (lines 103-134):
```javascript
async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seedScenario(request, scenario) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}

async function seedPhase198(request) {
  const phase191 = await seedScenario(request, "phase191-matrix");
  const operatorFlows = await seedScenario(request, "operator-flows");
  const dashboard = await seedScenario(request, "dashboard");
  const edgeStates = await seedScenario(request, "edge-states");

  return { operatorFlows, dashboard, edgeStates, phase191 };
}
```

**Drawer flow assertion pattern** (lines 277-319):
```javascript
async function assertDrawerFlow(page, flow) {
  await expect(page.locator("[data-ax-action-band] form:visible"), `${flow.name}: no initial forms`).toHaveCount(0);

  await clickActionTrigger(page, flow);

  let drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
  await expect(drawer, `${flow.name}: drawer opens after intent`).toBeVisible();

  let confirm = drawer.getByRole("button", { name: flow.confirm }).first();
  await expect(confirm, `${flow.name}: drawer confirm action`).toBeVisible();
  await drawer.locator(".ax-detail-drawer-body").evaluate((body) => {
    body.scrollTop = body.scrollHeight;
  });
  confirm = page.locator("#ax-overlay-root [data-presentation='drawer']").getByRole("button", { name: flow.confirm }).first();
  await confirm.scrollIntoViewIfNeeded();
  const clickMode = await confirmPointerClickMode(confirm, flow);
  if (clickMode === "dom") {
    await confirm.focus();
  }
  await assertFocusWithin(page, drawer, `${flow.name}: drawer`);

  if (clickMode === "dom") {
    await confirm.evaluate((element) => element.click());
  } else {
    await confirm.click();
  }
}
```

**Additional analog for close/scroll/geometry:** `accrue_admin/e2e/admin-spec-detail-phase195.spec.js`

**Open drawer and inert shell pattern** (lines 64-82):
```javascript
async function openSafeActionDrawer(page) {
  const actionMenu = page.locator("[data-ax-action-overflow-menu]").first();
  await expect(actionMenu).toBeVisible();
  await actionMenu.click();

  const safeItem = page
    .getByRole("menuitem", {
      name: /update quantity|add item|update item quantity|remove item|pause collection|resume/i,
    })
    .first();
  await expect(safeItem).toBeVisible();
  await safeItem.click();

  const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
  await expect(drawer).toBeVisible();
  await expect(page.locator("#accrue-admin-shell")).toHaveAttribute("inert", "");

  return drawer;
}
```

**Geometry and hit-testing pattern** (lines 84-129):
```javascript
async function assertDrawerGeometry(page, drawer) {
  const geometry = await drawer.locator("[data-ax-overlay-panel]").first().evaluate((panel) => {
    const rect = panel.getBoundingClientRect();
    const viewport = { width: window.innerWidth, height: window.innerHeight };
    return { left: rect.left, right: rect.right, top: rect.top, bottom: rect.bottom, width: rect.width, height: rect.height, viewport };
  });

  if (geometry.viewport.width < 768) {
    expect(geometry.bottom, "mobile drawer should present as a bottom sheet").toBeCloseTo(geometry.viewport.height, 0);
    expect(geometry.width, "mobile drawer should span most of the viewport").toBeGreaterThan(geometry.viewport.width * 0.9);
  } else {
    expect(geometry.right, "desktop drawer should be right docked").toBeCloseTo(geometry.viewport.width, 0);
    expect(geometry.left, "desktop drawer should not cover the full page width").toBeGreaterThan(0);
  }
}

async function assertDrawerInteractive(page, drawer) {
  const primary = drawer
    .getByRole("button", { name: /confirm|save|update|change|continue|submit/i })
    .first();
  const field = drawer.locator("input, select, textarea, button").first();

  await expect(primary).toBeVisible();
  await expect(field).toBeVisible();
  await field.focus();

  await assertTopPointerTarget(primary, "Phase 195 drawer primary action");
  await assertTopPointerTarget(field, "Phase 195 drawer focusable control");
  await assertFocusWithin(page, drawer, "Phase 195 action drawer");
}
```

**Close parity/ghost overlay pattern** (lines 174-206):
```javascript
test("Subscription action drawer portals, locks background scroll, traps focus, and closes by Escape", async ({
  page,
  request,
}) => {
  await openSubscriptionDetail(page, request);

  const drawer = await openSafeActionDrawer(page);
  await assertDrawerGeometry(page, drawer);
  await assertDrawerInteractive(page, drawer);
  await assertBodyScrollStable(page, "Escape close flow");

  await page.keyboard.press("Escape");
  await expect(drawer).toBeHidden();
  await expect(page.locator("#accrue-admin-shell")).not.toHaveAttribute("inert", "");
});

test("Subscription action drawer closes by backdrop click without leaving a ghost overlay", async ({
  page,
  request,
}) => {
  await openSubscriptionDetail(page, request);

  const drawer = await openSafeActionDrawer(page);
  const backdrop = page.locator("#ax-overlay-root [data-ax-overlay-backdrop]").first();
  await expect(backdrop).toBeVisible();
  await backdrop.click({ position: { x: 8, y: 8 } });

  await expect(drawer).toBeHidden();
  await expect(page.locator("#ax-overlay-root [data-presentation='drawer']")).toHaveCount(0);
  await expect(page.locator("#accrue-admin-shell")).not.toHaveAttribute("inert", "");
});
```

**Apply to:** New Phase 199 cross-page spec. Keep target arrays explicit; avoid a generic page DSL. Add `e2e:phase199` as a one-spec, one-worker script.

---

### `accrue_admin/e2e/phase191-page-flow-helpers.js` (utility, transform/assertion)

**Analog:** same file.

**Theme helper caveat** (lines 119-131):
```javascript
async function setPhase191Theme(page, theme) {
  if (!["light", "dark"].includes(theme)) {
    throw new Error(`Unsupported Phase 191 theme: ${theme}`);
  }

  await page.evaluate((value) => {
    document.documentElement.setAttribute("data-theme", value);
    document.documentElement.dataset.theme = value;
    window.localStorage?.setItem("accrue_admin_theme", value);
  }, theme);

  if (typeof page.waitForTimeout === "function") await page.waitForTimeout(50);
}
```

**Planner note:** This helper is suitable for visual matrix checks only. Production persistence tests must use `accrue_theme` via `layouts.ex`/`accrue_theme.js`.

**Focus and body-focus assertions** (lines 133-175):
```javascript
async function assertNoBodyFocus(page, label = "active element") {
  const active = await page.evaluate(() => {
    const element = document.activeElement;
    return {
      isBody: element === document.body,
      tagName: element?.tagName || "none",
      id: element?.id || "",
      role: element?.getAttribute?.("role") || "",
      text: (element?.textContent || "").trim().replace(/\s+/g, " ").slice(0, 80),
    };
  });

  if (active.isBody) {
    throw new Error(`Phase 191 focus assertion failed: ${label} resolved to document.body`);
  }

  return active;
}

async function assertFocusWithin(page, target, label = "active overlay") {
  const evaluate =
    typeof target === "string"
      ? (callback) => page.locator(target).first().evaluate(callback)
      : (callback) => target.evaluate(callback);

  const result = await evaluate((element) => {
    const active = document.activeElement;
    return {
      containsActive: Boolean(active && element.contains(active)),
      activeLabel: active
        ? `${active.tagName.toLowerCase()}${active.id ? `#${active.id}` : ""}`
        : "none",
    };
  });

  if (!result.containsActive) {
    throw new Error(
      `Phase 191 focus assertion failed: ${label} does not contain active element ${result.activeLabel}`
    );
  }

  return result;
}
```

**Hit-testing and scroll/clipping assertions** (lines 177-298):
```javascript
async function assertTopPointerTarget(locator, label = "primary control") {
  const result = await locator.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const style = window.getComputedStyle(element);
    const visible =
      style.display !== "none" &&
      style.visibility !== "hidden" &&
      rect.width > 0 &&
      rect.height > 0;
    const offscreen =
      rect.left < 0 ||
      rect.top < 0 ||
      rect.right > window.innerWidth ||
      rect.bottom > window.innerHeight;

    if (!visible || offscreen) {
      return { visible, offscreen, receivesEvents: false, rect: { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom }, topLabel: "not-tested" };
    }

    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    const top = document.elementFromPoint(x, y);

    return {
      visible,
      offscreen,
      receivesEvents: top === element || element.contains(top),
      rect: { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom },
      topLabel: top ? `${top.tagName.toLowerCase()}${top.id ? `#${top.id}` : ""}` : "none",
    };
  });

  if (!result.visible || result.offscreen || !result.receivesEvents) {
    throw new Error(
      `Phase 191 pointer assertion failed: ${label} is not the top reachable target (${JSON.stringify(result)})`
    );
  }

  return result;
}
```

**Apply to:** all Phase 199 Playwright specs. Extend exports only for repeated assertions such as production theme persistence or near-edge floating geometry.

---

### `accrue_admin/package.json` (config, batch)

**Analog:** same file.

**Script pattern** (lines 4-14):
```json
"scripts": {
  "e2e": "env -u NO_COLOR playwright test",
  "e2e:phase191": "env -u NO_COLOR playwright test e2e/admin-page-flow-phase191.spec.js --timeout=60000 --workers=1",
  "e2e:phase194": "env -u NO_COLOR playwright test e2e/admin-spec-overview-phase194.spec.js --timeout=60000 --workers=1",
  "e2e:phase195": "env -u NO_COLOR playwright test e2e/admin-spec-detail-phase195.spec.js --timeout=60000 --workers=1",
  "e2e:phase196": "env -u NO_COLOR playwright test e2e/admin-spec-list-phase196.spec.js --timeout=60000 --workers=1",
  "e2e:phase197": "env -u NO_COLOR playwright test e2e/admin-spec-list-phase197.spec.js --timeout=60000 --workers=1",
  "e2e:phase198": "env -u NO_COLOR playwright test e2e/admin-spec-detail-phase198.spec.js --timeout=60000 --workers=1",
  "e2e:a11y": "env -u NO_COLOR playwright test e2e/admin-a11y.spec.js"
}
```

**Apply to:** add `"e2e:phase199": "env -u NO_COLOR playwright test e2e/admin-interaction-overlay-phase199.spec.js --timeout=60000 --workers=1"`.

---

### Overlay components: `overlay.ex`, `detail_drawer.ex`, `step_up_auth_modal.ex`

**Analogs:** same files.

**Overlay imports/attrs pattern** (`overlay.ex` lines 1-24):
```elixir
defmodule AccrueAdmin.Components.Overlay do
  @moduledoc """
  Canonical overlay substrate for admin modals, drawers, and popovers.

  The component owns the shared portal, focus, close, and presentation markup.
  Domain-specific actions stay in the calling LiveView or wrapper component.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:presentation, :atom, default: :modal)
  attr(:title, :string, required: true)
  attr(:close_event, :string, default: nil)
  attr(:close_target, :string, default: nil)
  attr(:initial_focus, :string, default: nil)
  attr(:rest, :global, include: ~w(phx-click phx-target))
```

**Portal/focus/scroll markup pattern** (`overlay.ex` lines 53-89):
```elixir
~H"""
<.portal :if={@open} id={@portal_id} target="#ax-overlay-root">
  <section
    id={@id}
    class={@shell_class}
    data-ax-overlay-shell
    data-component-group={@component_group}
    data-presentation={@presentation_name}
    data-scroll-lock={@scroll_lock}
    phx-hook="Overlay"
    data-focus-trap-close-event={@focus_trap_close_event}
    data-focus-trap-close-target={@focus_trap_close_target}
    data-focus-trap-fallback={@focus_trap_fallback}
    data-focus-trap-initial={@initial_focus}
    phx-mounted={mounted_transition(@presentation)}
    phx-remove={remove_transition(@presentation)}
  >
    <div
      :if={@show_backdrop}
      class={@backdrop_class}
      data-ax-overlay-backdrop
      aria-hidden="true"
      phx-click={@focus_trap_close_event}
      phx-target={@focus_trap_close_target}
    >
    </div>

    <.dynamic_tag
      tag_name={@panel_tag}
      class={@panel_class}
      data-ax-overlay-panel
      data-presentation={@presentation_name}
      role={@role}
      aria-modal={@aria_modal}
      aria-labelledby={@resolved_title_id}
      aria-describedby={@resolved_description_id}
    >
"""
```

**Presentation contract pattern** (`overlay.ex` lines 134-149):
```elixir
defp normalize_presentation(presentation) when presentation in [:modal, :drawer, :popover],
  do: presentation

defp normalize_presentation(_presentation), do: :modal

defp role_for(:popover), do: "menu"
defp role_for(_presentation), do: "dialog"

defp aria_modal_for(:popover), do: nil
defp aria_modal_for(_presentation), do: "true"

defp scroll_lock?(:popover), do: nil
defp scroll_lock?(_presentation), do: true

defp backdrop?(:popover), do: false
defp backdrop?(_presentation), do: true
```

**Drawer wrapper pattern** (`detail_drawer.ex` lines 6-19, 31-55):
```elixir
use Phoenix.Component

alias AccrueAdmin.Components.Overlay

attr(:id, :string, default: "detail-drawer")
attr(:open, :boolean, default: false)
attr(:title, :string, required: true)
attr(:subtitle, :string, default: nil)
attr(:close_label, :string, default: "Close")
attr(:close_event, :string, default: nil)
attr(:rest, :global, include: ~w(phx-click phx-target))

<Overlay.overlay
  id={@id}
  open={@open}
  presentation={:drawer}
  title={@title}
  subtitle={@subtitle}
  close_label={drawer_close_label(@close_href, @close_label)}
  close_event={@focus_trap_close_event}
  close_target={@focus_trap_close_target}
  component_group="drawer-form"
  class={@class}
>
  <:actions>
    <%= render_slot(@actions) %>
    <a :if={@close_href} href={@close_href} class="ax-button ax-button-ghost">
      <%= @close_label %>
    </a>
  </:actions>

  <%= render_slot(@inner_block) %>

  <:footer :if={@footer != []}>
    <%= render_slot(@footer) %>
  </:footer>
</Overlay.overlay>
```

**Step-up wrapper pattern** (`step_up_auth_modal.ex` lines 10-12, 26-65):
```elixir
alias AccrueAdmin.Components.Overlay
alias AccrueAdmin.Copy

<Overlay.overlay
  id="accrue-admin-step-up-dialog"
  open={@pending}
  presentation={:modal}
  title={Copy.step_up_title()}
  title_id="step-up-title"
  subtitle={@challenge_message}
  description_id="step-up-description"
  close_label=""
  close_event="step_up_dismiss"
  initial_focus="#step-up-code"
  component_group="modal-confirm"
>
  <p :if={@error} id="step-up-error" class="ax-body" data-role="step-up-error"><%= @error %></p>

  <form phx-submit="step_up_submit" class="ax-step-up-modal-form">
    <label :if={input_name(@challenge) != nil} class="ax-visually-hidden" for="step-up-code">
      <%= input_placeholder(@challenge) %>
    </label>
    <input
      :if={input_name(@challenge) != nil}
      id="step-up-code"
      type={input_type(@challenge)}
      name={input_name(@challenge)}
      value=""
      placeholder={input_placeholder(@challenge)}
      aria-invalid={if @error, do: "true", else: "false"}
      aria-describedby={step_up_input_describedby(@error)}
      data-focus-trap-initial
    />

    <div class="ax-step-up-modal-actions">
      <button type="button" phx-click="step_up_dismiss" class="ax-button ax-button-ghost" data-role="step-up-cancel">
        <%= Copy.step_up_cancel_label() %>
      </button>

      <button type="submit" class="ax-button ax-button-primary" data-role="step-up-submit"><%= Copy.step_up_submit_label() %></button>
    </div>
  </form>
</Overlay.overlay>
```

**Apply to:** any modal/drawer-like surface. Do not add hand-rolled fixed shells outside `Overlay` or a named wrapper.

---

### Overlay JS hooks: `overlay.js`, `focus_trap.js`, `scroll_lock.js`

**Analogs:** same files.

**Hook composition pattern** (`overlay.js` lines 1-4, 20-57):
```javascript
import { FocusTrap } from "./focus_trap";
import { ScrollLock } from "./scroll_lock";

const SCROLL_LOCK_PRESENTATIONS = new Set(["modal", "drawer"]);

export const Overlay = {
  ...FocusTrap,

  mounted() {
    this.overlayScrollLocked = false;
    FocusTrap.mounted.call(this);
    this.syncOverlayScrollLock();
  },

  updated() {
    FocusTrap.updated.call(this);
    this.syncOverlayScrollLock();
  },

  destroyed() {
    this.releaseOverlayScrollLock();
    FocusTrap.destroyed.call(this);
  },

  syncOverlayScrollLock() {
    const shouldLock = scrollLockEnabled(this.el);

    if (shouldLock && !this.overlayScrollLocked) {
      ScrollLock.lock();
      this.overlayScrollLocked = true;
    } else if (!shouldLock && this.overlayScrollLocked) {
      ScrollLock.unlock();
      this.overlayScrollLocked = false;
    }
  },

  releaseOverlayScrollLock() {
    if (!this.overlayScrollLocked) return;

    ScrollLock.unlock();
    this.overlayScrollLocked = false;
  }
};
```

**Focus trap lifecycle/escape pattern** (`focus_trap.js` lines 31-68, 132-184):
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

  activateFocusTrap() {
    this.previouslyFocused = document.activeElement;
    this.focusTrapActive = true;
    document.addEventListener("keydown", this.handleFocusTrapKeydown);
    document.addEventListener("focusin", this.handleFocusTrapFocusin);
    this.scheduleInitialFocus();
  },

  handleFocusTrapKeydown(event) {
    if (!this.focusTrapActive) return;

    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation?.();
      this.dispatchFocusTrapClose();
      return;
    }
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
};
```

**Scroll lock ref-count pattern** (`scroll_lock.js` lines 125-162):
```javascript
export const ScrollLock = {
  lock() {
    lockCount += 1;
    if (lockCount > 1) return lockCount;

    const doc = browserDocument();
    const win = browserWindow();

    if (!doc?.documentElement || !doc?.body) return lockCount;

    previousState = captureState(doc, win);
    applyLock(previousState, win);

    return lockCount;
  },

  unlock() {
    if (lockCount === 0) return 0;

    lockCount -= 1;
    if (lockCount > 0) return lockCount;

    const state = previousState;
    previousState = null;

    if (state) {
      restoreLock(state, browserWindow());
    }

    return lockCount;
  }
};

export function resetScrollLockForTests() {
  lockCount = 0;
  savedScrollY = 0;
  previousState = null;
}
```

**Apply to:** overlay/focus/scroll fixes and JS unit tests. Preserve ref-counting and cleanup order: release scroll lock before `FocusTrap.destroyed`.

---

### Floating surfaces: `dropdown_menu.ex`, `dropdown.js`, `global_search.ex`, `command_palette.js`

**Analogs:** same files.

**Native non-modal action menu pattern** (`dropdown_menu.ex` lines 51-115):
```elixir
def action_menu(assigns) do
  ~H"""
  <details
    id={@id}
    class="ax-dropdown ax-action-menu"
    data-component-group="detail-action-menu"
    data-ax-action-overflow-menu
    data-phase191-focus="dropdown"
  >
    <summary
      class="ax-button ax-button-secondary ax-dropdown-trigger ax-action-menu-trigger"
      aria-haspopup="menu"
      data-phase191-focus="dropdown-trigger"
    >
      <span><%= @label %></span>
      <span aria-hidden="true">▾</span>
    </summary>

    <div
      class="ax-dropdown-panel ax-action-menu-panel"
      role="menu"
      aria-label={@label}
      data-phase191-focus="dropdown-panel"
      data-floating-panel="dropdown"
    >
      <button
        :for={item <- group_items(group)}
        type="button"
        role="menuitem"
        class={[
          "ax-dropdown-item",
          "ax-action-menu-item",
          item_danger?(item) && "ax-dropdown-item-danger"
        ]}
        phx-click={item_event(item)}
        phx-target={item_target(item)}
        phx-value-action_type={item_value(item)}
        data-phase191-focus="dropdown-item"
      >
        <span class="ax-dropdown-item-label">
          <span><%= item_label(item) %></span>
          <span :if={item_hidden_context(item)} class="ax-visually-hidden"><%= " " <> item_hidden_context(item) %></span>
        </span>
      </button>
    </div>
  </details>
  """
end
```

**Hidden context lookup pattern** (`dropdown_menu.ex` lines 128-130):
```elixir
defp item_hidden_context(item) do
  get_value(item, :hidden_context) || get_value(item, :action_context) ||
    get_value(item, :context)
end
```

**Dropdown dismissal pattern** (`dropdown.js` lines 16-35):
```javascript
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

**Command palette markup pattern** (`global_search.ex` lines 127-151):
```elixir
def render(assigns) do
  ~H"""
  <div
    id={@id}
    class="ax-command-palette-wrapper"
    data-open={to_string(@is_open)}
    data-component-group="toolbar-search-filter-sort"
  >
    <div id={"#{@id}-controller"} phx-hook="CommandPalette" data-target={@myself}>
      <%= if @is_open do %>
        <div
          class="ax-command-palette-backdrop"
          phx-click="close"
          phx-target={@myself}
        >
        </div>

        <div
          class="ax-command-palette"
          id="command-palette-container"
          role="dialog"
          aria-modal="true"
          aria-label="Global search"
        >
  """
end
```

**Command palette keyboard/restore pattern** (`command_palette.js` lines 48-57, 93-108):
```javascript
handleGlobalKeydown(e) {
  if ((e.metaKey || e.ctrlKey) && e.key === "k") {
    e.preventDefault();
    this.pushEventTo(this.el.dataset.target, "toggle", {});
  }

  if (e.key === "Escape" && this.isOpen()) {
    e.preventDefault();
    this.pushEventTo(this.el.dataset.target, "close", {});
  }
},

restoreFocus() {
  const preferred = this.previousFocus && this.previousFocus.isConnected
    ? this.previousFocus
    : document.querySelector("[data-command-palette-trigger], #main-content, main");

  if (preferred && typeof preferred.focus === "function") {
    const needsTemporaryTabIndex =
      preferred.tabIndex < 0 && !preferred.hasAttribute("tabindex");

    if (needsTemporaryTabIndex) {
      preferred.setAttribute("tabindex", "-1");
    }

    setTimeout(() => preferred.focus({ preventScroll: true }), 0);
  }
}
```

**Apply to:** dropdown/action-menu bounds, command palette close/focus tests, and any near-edge floating correction. Keep dropdowns non-modal; command palette must either route through `Overlay` or explicitly meet the same focus/dismissal/background-isolation contract.

---

### Theme persistence: `theme_picker.ex`, `layouts.ex`, `accrue_theme.js`, `theme_test.exs`

**Analogs:** same files plus `accrue_admin/e2e/phase7-uat.spec.js`.

**Theme picker radiogroup pattern** (`theme_picker.ex` lines 35-51):
```elixir
<div class={["ax-theme-picker", @class]} role="radiogroup" aria-label="Color theme">
  <button
    :for={{value, label, icon} <- @options}
    type="button"
    role="radio"
    aria-checked={to_string(@theme == value)}
    aria-label={label}
    title={label}
    tabindex={if @theme == value, do: "0", else: "-1"}
    data-theme-target={value}
    class={["ax-theme-picker-option", @theme == value && "ax-theme-picker-option-active"]}
  >
    <Icon.icon name={icon} size="sm" />
    <span class="ax-theme-picker-label"><%= label %></span>
  </button>
</div>
```

**Anti-FOUC production key pattern** (`layouts.ex` lines 56-69):
```elixir
@spec anti_fouc_script() :: String.t()
def anti_fouc_script do
  """
  (() => {
    const key = "accrue_theme";
    const allowed = new Set(["light", "dark", "system"]);
    const fromCookie = document.cookie.split("; ").find((chunk) => chunk.startsWith(`${key}=`));
    const cookieValue = fromCookie ? decodeURIComponent(fromCookie.split("=").slice(1).join("=")) : null;
    const storedValue = window.localStorage.getItem(key);
    const theme = allowed.has(cookieValue) ? cookieValue : allowed.has(storedValue) ? storedValue : "system";
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem(key, theme);
  })();
  """
end
```

**Production persistence hook pattern** (`accrue_theme.js` lines 1-13, 73-78):
```javascript
export const THEME_COOKIE = "accrue_theme";
export const ALLOWED_THEMES = new Set(["light", "dark", "system"]);

export function sanitizeTheme(theme) {
  return ALLOWED_THEMES.has(theme) ? theme : "system";
}

export function setThemePreference(theme) {
  const value = sanitizeTheme(theme);
  document.documentElement.dataset.theme = value;
  window.localStorage.setItem(THEME_COOKIE, value);
  document.cookie = `${THEME_COOKIE}=${encodeURIComponent(value)}; path=/; max-age=31536000; samesite=lax`;
  return value;
}

export function initThemeControls() {
  document.addEventListener("click", onThemeTargetClick, true);
  document.addEventListener("keydown", onThemeTargetKeydown, true);
  const initial = document.documentElement.dataset.theme;
  if (initial) syncThemeButtonActiveState(sanitizeTheme(initial));
}
```

**Existing browser persistence analog** (`phase7-uat.spec.js` lines 47-63):
```javascript
if (isMobile) {
  await page.evaluate(() => {
    window.localStorage.setItem("accrue_theme", "dark");
    document.cookie = "accrue_theme=dark; path=/; max-age=31536000; samesite=lax";
  });
} else {
  await page.getByRole("radio", { name: "Dark" }).click();
  await expect
    .poll(() => page.evaluate(() => window.localStorage.getItem("accrue_theme")))
    .toBe("dark");
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
}

await page.reload();
await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
```

**Server-side theme test pattern** (`theme_test.exs` lines 27-46, 98-130):
```elixir
test "brand plug sanitizes theme cookie and resolves runtime brand values" do
  conn =
    build_conn()
    |> Plug.Conn.put_req_header("cookie", "accrue_theme=neon")
    |> AccrueAdmin.BrandPlug.call([])

  assert conn.assigns.accrue_admin_theme == "system"
end

test "root layout keeps anti-fouc ordering ahead of stylesheet loading" do
  html =
    render_component(&AccrueAdmin.Layouts.root/1, %{
      page_title: "Billing",
      theme: "system",
      csp_nonce: "nonce-123",
      brand_css_path: "/billing/assets/brand.css",
      assets_css_path: "/billing/assets/app.css",
      assets_js_path: "/billing/assets/app.js",
      inner_content: Phoenix.HTML.raw("<main>Shell</main>")
    })

  anti_fouc_index = find_index(html, "document.documentElement.dataset.theme")
  brand_css_index = find_index(html, ~s(href="/billing/assets/brand.css"))
  app_css_index = find_index(html, ~s(href="/billing/assets/app.css"))
  runtime_style_index = find_index(html, "--ax-accent: #5D79F6;")
  js_index = find_index(html, ~s(src="/billing/assets/app.js"))

  assert anti_fouc_index < brand_css_index
  assert brand_css_index < app_css_index
  assert app_css_index < runtime_style_index
  assert runtime_style_index < js_index
end
```

**Apply to:** production-key cookie/localStorage precedence, reload persistence, and system dark/light emulation tests. Do not use `setPhase191Theme` as proof of production persistence.

---

### CSS: `app.css`, `theme.css`, generated bundles

**Analogs:** existing source CSS blocks.

**Overlay shell/layer pattern** (`app.css` lines 1375-1414):
```css
.ax-overlay-shell {
  position: fixed;
  inset: 0;
  /* ax-z-micro-stack: shell creates an isolated stacking context for backdrop/panel internals */
  isolation: isolate;
}

.ax-overlay-shell[data-presentation="drawer"],
.ax-detail-drawer-shell {
  z-index: var(--ax-z-drawer);
}

.ax-overlay-shell[data-presentation="modal"],
.ax-step-up-modal-shell {
  z-index: var(--ax-z-modal);
}

.ax-overlay-backdrop,
.ax-detail-drawer-backdrop,
.ax-step-up-modal-backdrop {
  position: absolute;
  inset: 0;
  z-index: 0; /* ax-z-micro-stack: backdrop at 0 inside isolated drawer shell */
}

.ax-overlay-panel {
  position: relative;
  isolation: isolate;
  z-index: 1; /* ax-z-micro-stack: panel at 1 inside isolated overlay shell */
  overscroll-behavior: contain;
}
```

**Drawer geometry pattern** (`app.css` lines 1417-1444, 1584-1595, 1827-1838):
```css
.ax-detail-drawer {
  position: absolute;
  inset: auto 0 0 0;
  display: grid;
  grid-template-rows: auto minmax(0, 1fr) auto;
  width: 100%;
  max-height: min(42rem, calc(100dvh - var(--ax-space-lg)));
  overflow: hidden;
  background: var(--ax-base);
  border-radius: var(--ax-radius-lg) var(--ax-radius-lg) 0 0;
}

.ax-detail-drawer-body {
  display: grid;
  gap: var(--ax-space-lg);
  min-height: 0;
  overflow: auto;
  overscroll-behavior: contain;
}

@media (max-width: 767.98px) {
  .ax-drawer-enter-from {
    transform: translateY(100%);
  }
}

@media (min-width: 768px) {
  .ax-detail-drawer {
    inset: 0 0 0 auto;
    width: min(34rem, 92vw);
    min-height: 100vh;
    max-height: 100vh;
    border-left: 1px solid var(--ax-border);
    border-radius: 0;
  }

  .ax-drawer-enter-from {
    transform: translateX(100%);
  }
}
```

**Dropdown bounds/motion pattern** (`app.css` lines 2715-2825):
```css
.ax-dropdown-panel {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  min-width: 15rem;
  max-width: min(22rem, calc(100vw - 2rem));
  max-height: min(24rem, calc(100vh - 6rem));
  overflow: auto;
  overscroll-behavior: contain;
  padding: var(--ax-space-sm);
  border: 1px solid var(--ax-border);
  border-radius: var(--ax-radius-md);
  background: var(--ax-elevated);
  box-shadow: var(--ax-shadow-sm);
  z-index: var(--ax-z-dropdown);
}

.ax-action-menu-panel {
  transform-origin: top right;
}

details.ax-dropdown .ax-dropdown-panel {
  opacity: 0;
  transform: translateY(calc(-1 * var(--ax-rise-sm)));
  pointer-events: none;
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),
    transform var(--ax-dur-2) var(--ax-ease-out);
}

details[open].ax-dropdown .ax-dropdown-panel {
  opacity: 1;
  transform: translateY(0px);
  pointer-events: auto;
}
```

**Command palette fixed-layer pattern** (`app.css` lines 2955-3021):
```css
.ax-command-palette-wrapper {
  position: fixed;
  inset: 0;
  z-index: var(--ax-z-modal);
  display: grid;
  place-items: start center;
  padding: 10vh var(--ax-space-md) var(--ax-space-md);
  pointer-events: none;
}

.ax-command-palette-wrapper[data-open="true"] {
  pointer-events: auto;
}

.ax-command-palette-wrapper[data-open="true"] .ax-command-palette {
  opacity: 1;
  transform: scale(1);
  pointer-events: auto;
  transition:
    opacity var(--ax-dur-2) var(--ax-ease-out),
    transform var(--ax-dur-2) var(--ax-ease-emphasis);
}
```

**Motion token pattern** (`theme.css` lines 52-68, 412-438):
```css
html.accrue-admin {
  --ax-dur-instant: 0ms;
  --ax-dur-1: 120ms;
  --ax-dur-2: 180ms;
  --ax-dur-3: 240ms;
  --ax-dur-exit: 140ms;
  --ax-ease-out: cubic-bezier(0.2, 0, 0, 1);
  --ax-ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ax-ease-emphasis: cubic-bezier(0.2, 0.9, 0.3, 1.2);
  --ax-rise-sm: 4px;
  --ax-rise-md: 8px;
  --ax-motion-fast: var(--ax-dur-1) var(--ax-ease-out);
  --ax-motion-standard: var(--ax-dur-2) var(--ax-ease-out);
  --ax-theme-transition: var(--ax-motion-standard);
}

@media (prefers-reduced-motion: reduce) {
  html.accrue-admin {
    --ax-rise-sm: 0px;
    --ax-rise-md: 0px;
    --ax-press-scale: 1;
    --ax-ease-emphasis: var(--ax-ease-out);
    --ax-dur-1: 0ms;
    --ax-dur-3: 0ms;
    --ax-dur-exit: 0ms;
    --ax-dur-2: 1ms;
    --ax-motion-fast: 0ms linear;
    --ax-motion-standard: 0ms linear;
    --ax-theme-transition: 0ms linear;
  }
}
```

**Apply to:** overlay geometry, floating bounds/origin, transformed ancestor audit, reduced-motion expansion. After source CSS/JS edits, rebuild committed assets with `cd accrue_admin && mix accrue_admin.assets.build`.

---

### Detail LiveViews: invoice, charge, subscription, webhook, connect account, customer

**Analogs:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `connect_account_live.ex`, `customer_live.ex`.

**Imports and owner-scope mount pattern** (`invoice_live.ex` lines 4-29, 34-61):
```elixir
use Phoenix.LiveView

alias Accrue.{Actor, Auth, Billing, Events}
alias Accrue.Billing.Invoice

alias AccrueAdmin.Components.{
  AppShell,
  Breadcrumbs,
  Detail,
  DetailDrawer,
  DropdownMenu,
  FlashGroup,
  Input,
  JsonViewer,
  MoneyFormatter,
  RelatedResources,
  Select,
  StatusBadge,
  StepUpAuthModal,
  Timeline
}

alias AccrueAdmin.Copy
alias AccrueAdmin.Queries.Invoices
alias AccrueAdmin.ScopedPath
alias AccrueAdmin.{BillingPresentation, StepUp, TaxOwnershipRow}

def mount(%{"id" => invoice_id}, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  case Invoices.detail(invoice_id, socket.assigns.current_owner_scope) do
    :not_found ->
      {:ok,
       socket
       |> put_flash(:error, Copy.Locked.owner_access_denied())
       |> redirect(to: ScopedPath.build(admin["mount_path"] || "/billing", "/invoices", socket.assigns.current_owner_scope))}

    {:ok, invoice} ->
      {:ok,
       socket
       |> assign_shell(admin)
       |> assign_invoice(invoice)
       |> assign(:flashes, [])
       |> assign(:pending_action, nil)
       |> assign(:drawer_action_type, nil)}
  end
end
```

**Drawer open/prepare/cancel pattern** (`invoice_live.ex` lines 65-99):
```elixir
def handle_event("open_action_drawer", %{"action_type" => action_type}, socket)
    when is_binary(action_type) do
  socket = ensure_timeline_events(socket)

  if action_available?(socket.assigns.invoice, action_type) do
    {:noreply,
     socket
     |> assign(:drawer_action_type, action_type)
     |> assign(:pending_action, nil)}
  else
    {:noreply, reject_unavailable_invoice_action(socket)}
  end
end

def handle_event("prepare_action", params, socket) do
  socket = ensure_timeline_events(socket)

  with action_type when is_binary(action_type) <- socket.assigns.drawer_action_type,
       true <- action_available?(socket.assigns.invoice, action_type) do
    action = pending_action(action_type, params, socket.assigns.timeline_events)

    {:noreply, assign(socket, :pending_action, action)}
  else
    _unavailable -> {:noreply, reject_unavailable_invoice_action(socket)}
  end
end

def handle_event("cancel_pending_action", _params, socket) do
  {:noreply,
   socket
   |> assign(:pending_action, nil)
   |> assign(:drawer_action_type, nil)}
end
```

**Step-up execution/dismissal pattern** (`invoice_live.ex` lines 110-149):
```elixir
def handle_event("confirm_action", _params, socket) do
  case socket.assigns.pending_action do
    nil ->
      {:noreply, push_flash(socket, :warning, Copy.invoice_select_action_warning())}

    %{type: type} = action when type in @destructive_actions ->
      case StepUp.require_fresh(
             socket,
             step_up_action(action, socket.assigns.invoice),
             &execute_action(&1, action)
           ) do
        {:ok, socket} -> {:noreply, socket}
        {:challenge, socket} -> {:noreply, socket}
        {:error, _reason, socket} -> {:noreply, push_flash(socket, :error, invoice_action_error_copy(socket, action))}
      end

    action ->
      {:noreply, execute_action(socket, action)}
  end
end

def handle_event("step_up_submit", params, socket) do
  case StepUp.verify(socket, params) do
    {:ok, socket} -> {:noreply, socket}
    {:error, _reason, socket} -> {:noreply, socket}
  end
end

def handle_event("step_up_dismiss", _params, socket) do
  {:noreply, dismiss_step_up_if_pending(socket)}
end
```

**Drawer/render/test mirror pattern** (`invoice_live.ex` lines 432-511):
```elixir
<DetailDrawer.detail_drawer
  id="invoice-action-drawer"
  open={drawer_open?(@drawer_action_type, @pending_action)}
  title={drawer_title(@drawer_action_type, @pending_action)}
  subtitle={drawer_subtitle(@drawer_action_type, @pending_action)}
  close_event="cancel_pending_action"
>
  <%= if @pending_action do %>
    <.pending_action_content pending_action={@pending_action} invoice={@invoice} />
  <% else %>
    <.invoice_action_form
      action_type={@drawer_action_type}
      invoice={@invoice}
      customer={@customer}
      events={@timeline_events}
    />
  <% end %>

  <:footer>
    <button
      :if={@pending_action}
      phx-click="confirm_action"
      class="ax-button ax-button-primary"
      data-role="confirm-action"
      data-ax-action-drawer-confirm
    >
      <%= Copy.invoice_confirm_action_verb() %> <%= invoice_action_label(@pending_action.type) %>
    </button>
    <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost"><%= Copy.invoice_confirm_cancel() %></button>
  </:footer>
</DetailDrawer.detail_drawer>

<div
  :if={drawer_open?(@drawer_action_type, @pending_action)}
  hidden
  aria-hidden="true"
  data-role="invoice-action-drawer-test-mirror"
>
  <section data-ax-overlay-panel data-presentation="drawer">
    ...
  </section>
</div>

<StepUpAuthModal.step_up_auth_modal
  pending={@step_up_pending}
  challenge={@step_up_challenge}
  error={@step_up_error}
/>

<div :if={@step_up_pending} hidden aria-hidden="true" data-role="step-up-test-mirror">
  <p><%= Copy.step_up_title() %></p>
  <form phx-submit="step_up_submit">
    <input type="text" name="code" value="" />
    <button type="submit" data-role="step-up-submit"><%= Copy.step_up_submit_label() %></button>
  </form>
</div>
```

**Summary/action context pattern** (`invoice_live.ex` lines 751-762, 817-876):
```elixir
%{
  label: "Customer",
  value: customer_label(customer),
  action_label: "View",
  action_context: "customer for invoice #{invoice_label}",
  action_href: ScopedPath.build(mount_path, "/customers/#{customer.id}", scope)
}

defp invoice_action_menu_groups(invoice) do
  primary_values = Enum.map(primary_actions(invoice), & &1.value)
  invoice_label = invoice_label(invoice)

  [
    %{label: "Collection", items: ["finalize", "pay", "add_line_item"] |> Enum.reject(&(&1 in primary_values)) |> Enum.filter(&action_available?(invoice, &1)) |> Enum.map(&invoice_action_item(invoice, &1))},
    %{label: "Danger zone", items: ["void", "mark_uncollectible"] |> Enum.filter(&action_available?(invoice, &1)) |> Enum.map(&invoice_action_item(invoice, &1, danger?: true))}
  ]
  |> Enum.map(fn group ->
    update_in(group.items, fn items ->
      Enum.map(items, &Map.put_new(&1, :hidden_context, "for invoice #{invoice_label}"))
    end)
  end)
  |> Enum.reject(&(Map.get(&1, :items) == []))
end

defp invoice_action_item(invoice, action_type, opts \\ []) do
  %{
    label: invoice_action_label(action_type),
    event: "open_action_drawer",
    value: action_type,
    danger?: Keyword.get(opts, :danger?, false),
    primary?: Keyword.get(opts, :primary?, false),
    hidden_context: "#{invoice_action_label(action_type)} for invoice #{invoice_label(invoice)}"
  }
end
```

**Connect account variant** (`connect_account_live.ex` lines 74-99, 242-279, 471-476):
```elixir
def handle_event("save_override", %{"override" => params}, socket) do
  socket = apply_override_preview(socket, params)

  case socket.assigns.override_preview do
    %{error: nil, override_payload: override_payload} ->
      socket = assign(socket, :pending_override, override_payload)

      case StepUp.require_fresh(
             socket,
             step_up_action(socket.assigns.account),
             &execute_override_save(&1, override_payload)
           ) do
        {:ok, socket} -> {:noreply, socket}
        {:challenge, socket} -> {:noreply, socket}
        {:error, _reason, socket} ->
          {:noreply,
           socket
           |> assign(:pending_override, nil)
           |> assign(:flashes, [
             %{kind: :error, message: AccrueAdmin.Copy.connect_account_step_up_unavailable()}
           ])}
      end
  end
end

<DetailDrawer.detail_drawer
  id="connect-platform-fee-drawer"
  open={drawer_open?(@drawer_action_type)}
  title={override_drawer_title(@account)}
  subtitle={AccrueAdmin.Copy.connect_account_drawer_subtitle()}
  close_event="cancel_override_drawer"
>
  <.override_drawer_form preview={@override_preview} default_fee_config={@default_fee_config} />
</DetailDrawer.detail_drawer>

%{
  label: AccrueAdmin.Copy.connect_account_summary_label_override(),
  value: override_state_label(account),
  action_label: "Change",
  action_context: "platform fee override for account #{account_label}",
  action_event: "open_override_drawer",
  action_value: "platform_fee_override"
}
```

**Apply to:** all drawer/step-up detail pages. Hidden test mirrors may stay only when hidden and `aria-hidden="true"`; do not create a second visible interactive path.

---

### List LiveViews and list components

**Analogs:** `customers_live.ex`, `DataTable`, `admin-spec-list-phase197.spec.js`.

**List LiveView render/copy pattern** (`customers_live.ex` lines 98-174):
```elixir
<PageHeader.page_header
  breadcrumbs={[
    %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
    %{label: Copy.customers_index_heading()}
  ]}
  title={Copy.customers_list_heading()}
>
  <:description>
    <p class="ax-body"><%= Copy.customers_list_subtitle() %></p>
  </:description>

  <:filter_toolbar>
    <DataTable.filter_toolbar
      id="customers"
      filter_fields={customer_filter_fields(@owner_type_type, @owner_type_options)}
      filter_params={filter_params(@params)}
      path={@table_path}
      clear_href={clear_all_href(@params, @table_path)}
      clear_visible={filter_active?(@params)}
    />
  </:filter_toolbar>
</PageHeader.page_header>

<.live_component
  module={DataTable}
  id="customers"
  query_module={Customers}
  current_owner_scope={@current_owner_scope}
  path={@table_path}
  params={@params}
  list_id="customers"
  list_state={list_state(@params)}
  empty_reason={empty_reason(@params, @summary)}
  loading_fixture={phase197_loading_fixture?(@params)}
  loading_label={Copy.customers_list_loading_label()}
  empty_title={empty_title(@params, @summary)}
  empty_copy={empty_copy(@params, @summary)}
  filtered_empty_title={empty_title(@params, @summary)}
  filtered_empty_copy={empty_copy(@params, @summary)}
  table_caption={Copy.customers_index_table_caption()}
>
```

**Empty-state routing pattern** (`customers_live.ex` lines 365-391):
```elixir
defp list_state(params) do
  if phase197_loading_fixture?(params), do: "loading-skeleton", else: nil
end

defp empty_reason(params, summary) do
  cond do
    phase197_loading_fixture?(params) -> nil
    first_run_empty?(params, summary) -> "first-run"
    filter_active?(params) -> "filter"
    true -> nil
  end
end

defp empty_title(params, summary) do
  if first_run_empty?(params, summary) do
    Copy.customers_list_first_run_empty_title()
  else
    Copy.customers_list_filtered_empty_title()
  end
end

defp empty_copy(params, summary) do
  if first_run_empty?(params, summary) do
    Copy.customers_list_first_run_empty_body()
  else
    Copy.customers_list_filtered_empty_body()
  end
end
```

**DataTable state derivation pattern** (`data_table.ex` lines 97-165):
```elixir
defp resolve_list_state(socket) do
  list_state = normalize_marker(socket.assigns[:list_state]) || derive_list_state(socket)

  empty_reason =
    normalize_marker(socket.assigns[:empty_reason]) ||
      derive_empty_reason(list_state, socket)

  assign(socket, list_state: list_state, empty_reason: empty_reason)
end

defp derive_list_state(socket) do
  cond do
    socket.assigns[:loading_fixture] == true -> "loading-skeleton"
    !Enum.empty?(socket.assigns[:rows] || []) -> "populated"
    any_filter_active?(socket.assigns[:filter_params] || %{}) -> "filtered-empty"
    true -> "first-run-empty"
  end
end

defp resolve_empty_state(socket) do
  filtered? =
    socket.assigns[:list_state] == "filtered-empty" or
      any_filter_active?(socket.assigns[:filter_params] || %{})

  resolved_empty_title =
    if filtered? and socket.assigns.filtered_empty_title,
      do: socket.assigns.filtered_empty_title,
      else: socket.assigns.empty_title

  resolved_empty_copy =
    if filtered? and socket.assigns.filtered_empty_copy,
      do: socket.assigns.filtered_empty_copy,
      else: socket.assigns.empty_copy

  assign(socket,
    resolved_empty_title: resolved_empty_title,
    resolved_empty_copy: resolved_empty_copy
  )
end
```

**Clear filters and disabled select pattern** (`data_table.ex` lines 329-341, 525-560):
```elixir
<div :if={@render_empty_state} class="ax-card ax-empty ax-data-table-empty" data-role="empty-state">
  <Icon.icon name={:inbox} size="lg" class="ax-empty-icon ax-empty-icon-muted" />
  <p class="ax-empty-title"><%= @resolved_empty_title %></p>
  <p class="ax-body ax-empty-copy"><%= @resolved_empty_copy %></p>
  <.link
    :if={any_filter_active?(@filter_params)}
    patch={@clear_href}
    class="ax-button ax-button-secondary"
    data-role="clear-filters"
    data-phase191-focus="clear-filters"
  >
    <%= Copy.data_table_clear_filters_label() %>
  </.link>
</div>

<.link
  :if={@clear_visible}
  patch={@clear_href}
  class="ax-button ax-button-ghost ax-data-table-filter-clear"
  data-role="clear-filters"
  data-phase191-focus="clear-filters"
>
  <%= Copy.data_table_clear_filters_label() %>
</.link>

<option
  :for={option <- @options}
  value={option_value(option)}
  selected={option_selected?(@value, option)}
  disabled={option_disabled?(option) and not option_selected?(@value, option)}
>
```

**List browser target pattern** (`admin-spec-list-phase197.spec.js` lines 18-116, 233-291):
```javascript
const LIST_CONTRACTS = Object.freeze([
  {
    name: "Customers",
    route: "/billing/customers",
    listId: "customers",
    resourceLabel: "customers",
    activeChip: "All customers",
    quickChip: "Missing payment method",
    defaultParams: {},
    clearAllOnDefault: false,
    loadingText: "Loading customers.",
  },
  {
    name: "Webhooks",
    route: "/billing/webhooks",
    listId: "webhooks",
    resourceLabel: "webhook deliveries",
    activeChip: "Needs replay",
    allChip: "All deliveries",
    defaultParams: { status: "failed,dead" },
    clearAllOnDefault: true,
    loadingText: "Loading webhook deliveries.",
  },
]);

for (const contract of LIST_CONTRACTS) {
  test(`${contract.name} desktop smoke renders PageHeader, LIST chrome, chips, and count`, async ({
    page,
    request,
  }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    await page.setViewportSize({ width: 1280, height: 900 });
    await reset(request);
    await seedListBaseline(request);
    for (const theme of ["light", "dark"]) {
      await login(page, contract.route);
      await assertDefaultParams(page, contract, `${contract.name} default`);
      await setPhase191Theme(page, theme);
      await assertPageHeaderContract(page, `${contract.name} ${theme}`);
      const state = await assertListChrome(page, contract, `${contract.name} ${theme}`);
    }
  });
}
```

**Apply to:** customers, invoices, payments, webhooks, connect accounts, subscriptions, coupons, promotion codes, events list pages.

---

### Detail/empty components: `detail.ex`, `empty_state.ex`

**Analogs:** same files.

**Summary-list hidden context pattern** (`detail.ex` lines 73-98):
```elixir
def summary_list(assigns) do
  ~H"""
  <dl class={["ax-summary-list", @class]} data-ax-summary-list>
    <div :for={row <- @rows} class="ax-summary-list-row">
      <dt class="ax-summary-list-key"><%= row_value(row, :label) %></dt>
      <dd class="ax-summary-list-value"><%= row_value(row, :value) %></dd>
      <dd :if={row_action?(row)} class="ax-summary-list-actions">
        <a
          :if={row_action_href(row)}
          href={row_action_href(row)}
          class="ax-summary-list-action"
        >
          <span><%= row_action_label(row) %></span>
          <span :if={row_action_context(row)} class="ax-visually-hidden"><%= " " <> row_action_context(row) %></span>
        </a>
        <button
          :if={!row_action_href(row) and row_action_event(row)}
          type="button"
          class="ax-summary-list-action"
          phx-click={row_action_event(row)}
          phx-target={row_action_target(row)}
          phx-value-action_type={row_action_value(row)}
        >
          <span><%= row_action_label(row) %></span>
          <span :if={row_action_context(row)} class="ax-visually-hidden"><%= " " <> row_action_context(row) %></span>
        </button>
      </dd>
    </div>
  </dl>
  """
end
```

**Non-interactive empty-state contract** (`empty_state.ex` lines 1-12, 26-36):
```elixir
@moduledoc """
Non-interactive empty-state hero container for mounted admin pages.

Displays a centered icon, title, and body copy. An optional
`actions` slot renders a CTA (e.g. a `<.button>` component) inside
the hero -- the wrapper itself carries NO interactive affordances
(`tabindex`, `role="button"`, `phx-click`, `:hover` cursor change).
"""

def empty_state(assigns) do
  ~H"""
  <div class={["ax-empty", @class]}>
    <Icon.icon name={@icon} size="lg" class="ax-empty-icon ax-empty-icon-muted" />
    <p class="ax-type-title ax-empty-title"><%= @title %></p>
    <p class="ax-type-body-sm ax-muted ax-empty-copy"><%= @body %></p>
    <div :if={@actions != []} class="ax-empty-actions">
      <%= render_slot(@actions) %>
    </div>
  </div>
  """
end
```

**Apply to:** CPY-01 action labels, false affordance removal, and empty/healthy hero checks.

---

### JS unit tests

**Analogs:** `scroll_lock_test.mjs`, `focus_trap_test.mjs`, `dropdown_test.mjs`, `command_palette_test.mjs`.

**Fake browser test pattern** (`scroll_lock_test.mjs` lines 1-5, 79-109, 111-129):
```javascript
import assert from "node:assert/strict";
import { afterEach, beforeEach, test } from "node:test";

import { ScrollLock, resetScrollLockForTests } from "../../assets/js/hooks/scroll_lock.js";

function withBrowserGlobals(browser, callback) {
  const priorDocument = globalThis.document;
  const priorWindow = globalThis.window;

  globalThis.document = browser.documentLike;
  globalThis.window = browser.windowLike;

  try {
    callback(browser);
  } finally {
    if (priorDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = priorDocument;
    }

    if (priorWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = priorWindow;
    }
  }
}

beforeEach(() => {
  resetScrollLockForTests();
});

afterEach(() => {
  resetScrollLockForTests();
});

test("lock is ref-counted and restores only after the final unlock", () => {
  const browser = fakeBrowser({ scrollY: 240 });

  withBrowserGlobals(browser, ({ documentLike, shell }) => {
    ScrollLock.lock();
    ScrollLock.lock();

    assert.equal(documentLike.documentElement.style.position, "fixed");
    assert.equal(shell.hasAttribute("inert"), true);

    ScrollLock.unlock();
    assert.equal(documentLike.documentElement.style.position, "fixed");
    assert.equal(shell.hasAttribute("inert"), true);

    ScrollLock.unlock();
    assert.equal(documentLike.documentElement.style.position, "");
    assert.equal(shell.hasAttribute("inert"), false);
  });
});
```

**Focus trap event pattern** (`focus_trap_test.mjs` lines 142-176):
```javascript
test("Escape invokes only the configured close event", () => {
  const documentLike = fakeDocument();
  const cancel = focusable("cancel", documentLike);
  const submit = focusable("submit", documentLike);
  submit.click = () => {
    throw new Error("Escape must not click submit controls");
  };

  const root = rootElement([cancel, submit], {
    focusTrapCloseEvent: "close_step_up"
  });
  const pushed = [];

  withDocument(documentLike, () => {
    cancel.focus();

    const hook = {
      ...FocusTrap,
      el: root,
      pushEvent(eventName, payload) {
        pushed.push([eventName, payload]);
      }
    };

    hook.mounted();

    const escape = keyEvent("Escape");
    documentLike.dispatch("keydown", escape);

    assert.equal(escape.defaultPrevented, true);
    assert.deepEqual(pushed, [["close_step_up", {}]]);

    hook.destroyed();
  });
});
```

**Dropdown idempotent close pattern** (`dropdown_test.mjs` lines 69-124):
```javascript
test("Escape closes an open dropdown and restores focus to the summary trigger", () => {
  const dropdown = detailsElement();
  const documentLike = fakeDocument([dropdown]);

  withDocument(documentLike, () => {
    initDropdowns();
    documentLike.dispatch("keydown", { key: "Escape" });
  });

  assert.equal(dropdown.open, false);
  assert.equal(dropdown.removeCalls, 1);
  assert.deepEqual(dropdown.summary.focusCalls, [{ preventScroll: true }]);
});

test("repeated close attempts are safe after the dropdown is already closed", () => {
  const dropdown = detailsElement();
  const documentLike = fakeDocument([dropdown]);

  withDocument(documentLike, () => {
    initDropdowns();
    documentLike.dispatch("keydown", { key: "Escape" });
    documentLike.dispatch("keydown", { key: "Escape" });
    documentLike.dispatch("click", { target: {} });
  });

  assert.equal(dropdown.open, false);
  assert.equal(dropdown.removeCalls, 1);
  assert.deepEqual(dropdown.summary.focusCalls, [{ preventScroll: true }]);
});
```

**Apply to:** nested scroll-lock, rapid open/close, Escape/backdrop parity, dropdown and command-palette focus restoration.

---

### Component/contract tests

**Analogs:** `overlay_components_test.exs`, `global_search_test.exs`, `theme_picker_test.exs`.

**Overlay component contract pattern** (`overlay_components_test.exs` lines 15-49, 82-110):
```elixir
describe "Overlay portal and focus contract" do
  test "renders drawer presentation through the body-level overlay root" do
    html =
      render_component(fn assigns ->
        assigns = assigns

        ~H"""
        <Overlay.overlay
          id="subscription-action-drawer"
          open
          presentation={:drawer}
          title="Change plan"
          subtitle="Subscription sub_123"
          close_label="Close action drawer"
          close_event="close_subscription_drawer"
          close_target="#subscription-live"
        >
          <button type="button" data-focus-trap-initial>Save change</button>
        </Overlay.overlay>
        """
      end)

    assert html =~ ~s(data-phx-portal="#ax-overlay-root")
    assert html =~ ~s(data-ax-overlay-shell)
    assert html =~ ~s(data-ax-overlay-panel)
    assert html =~ ~s(data-ax-overlay-backdrop)
    assert html =~ ~s(data-presentation="drawer")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(phx-hook="Overlay")
    assert html =~ ~s(data-focus-trap-close-event="close_subscription_drawer")
    assert html =~ ~s(data-focus-trap-close-target="#subscription-live")
    assert html =~ ~s(data-focus-trap-fallback="#subscription-action-drawer-title")
    assert html =~ ~s(data-scroll-lock)
  end

  test "renders popover presentation without modal semantics" do
    html = render_component(...)

    assert html =~ ~s(data-phx-portal="#ax-overlay-root")
    assert html =~ ~s(data-presentation="popover")
    assert html =~ ~s(role="menu")
    refute html =~ ~s(aria-modal="true")
    refute html =~ ~s(data-scroll-lock)
    refute html =~ ~s(data-ax-overlay-backdrop)
  end
end
```

**CSS source guard pattern** (`overlay_components_test.exs` lines 297-332):
```elixir
describe "Overlay CSS layer and geometry contract" do
  test "defines canonical shell, backdrop, and panel local ordering" do
    app_css = File.read!(app_css_path())

    assert app_css =~
             ~r/\.ax-overlay-shell\s*\{[^}]*position: fixed;[^}]*inset: 0;[^}]*isolation: isolate;/s

    assert app_css =~
             ~r/\.ax-overlay-backdrop,\s*\.ax-detail-drawer-backdrop,\s*\.ax-step-up-modal-backdrop\s*\{[^}]*z-index: 0;/s

    assert app_css =~
             ~r/\.ax-overlay-panel\s*\{[^}]*z-index: 1;[^}]*overscroll-behavior: contain;/s
  end

  test "keeps drawer right-docked on desktop and bottom-sheeted below md" do
    app_css = File.read!(app_css_path())

    assert app_css =~
             ~r/@media \(min-width: 768px\).*?\.ax-detail-drawer\s*\{.*?inset: 0 0 0 auto;.*?width: min\(34rem, 92vw\);.*?border-left: 1px solid var\(--ax-border\);.*?border-radius: 0;.*?\}.*?\.ax-drawer-enter-from\s*\{.*?transform: translateX\(100%\);/s

    assert app_css =~
             ~r/@media \(max-width: 767\.98px\).*?\.ax-detail-drawer\s*\{.*?inset: auto 0 0 0;.*?width: 100%;.*?max-height: min\(42rem, calc\(100dvh - var\(--ax-space-lg\)\)\);.*?border-radius: var\(--ax-radius-lg\) var\(--ax-radius-lg\) 0 0;.*?\}.*?\.ax-drawer-enter-from\s*\{.*?transform: translateY\(100%\);/s
  end
end
```

**Command palette markup tests** (`global_search_test.exs` lines 52-90):
```elixir
describe "command palette group contract" do
  test "renders modal-layer dialog markup with active-result styling proof" do
    html =
      render_component(GlobalSearch, %{
        id: "global-search",
        mount_path: "/billing",
        query: "",
        results: %{customers: [], invoices: [], subscriptions: []},
        is_open: true,
        loading: false
      })

    css = File.read!("assets/css/app.css")

    assert html =~ ~s(data-component-group="toolbar-search-filter-sort")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(aria-label="Global search")
    assert css =~ ".ax-command-palette-wrapper"
    assert css =~ "z-index: var(--ax-z-modal)"
    assert css =~ ".ax-command-palette-item.ax-active"
  end

  test "does not expose modal dialog semantics while closed" do
    html = render_component(GlobalSearch, %{is_open: false, ...})

    assert html =~ ~s(data-component-group="toolbar-search-filter-sort")
    refute html =~ ~s(role="dialog")
    refute html =~ ~s(aria-modal="true")
  end
end
```

**Theme picker test pattern** (`theme_picker_test.exs` lines 10-50):
```elixir
test "renders a radiogroup with the three theme segments" do
  html = render("system")

  assert html =~ ~s(role="radiogroup")
  assert html =~ ~s(aria-label="Color theme")

  for value <- ~w(light dark system) do
    assert html =~ ~s(data-theme-target="#{value}")
  end
end

test "marks only the active theme as checked, with roving tabindex" do
  html = render("dark")

  assert html |> String.split(~s(aria-checked="true")) |> length() == 2
  assert html |> String.split(~s(aria-checked="false")) |> length() == 3
  assert html |> String.split(~s(tabindex="0")) |> length() == 2
  assert html |> String.split(~s(tabindex="-1")) |> length() == 3
end
```

**Apply to:** ExUnit/component coverage for overlay markup, dropdown non-modal status, command-palette status, theme picker, and CSS invariants.

---

### Fixtures: `e2e_fixtures.ex`, `e2e_plug.ex`, `e2e_fixtures_test.exs`

**Analogs:** same files.

**Seed endpoint pattern** (`e2e_plug.ex` lines 36-84):
```elixir
post "/reset" do
  Fixtures.reset!()
  json(conn, 200, %{ok: true})
end

post "/seed/operator-flows" do
  json(conn, 200, Fixtures.seed_operator_flows!())
end

post "/seed/edge-states" do
  json(conn, 200, Fixtures.seed_edge_states!())
end

post "/__e2e__/seed/edge-states" do
  json(conn, 200, Fixtures.seed_edge_states!())
end

post "/seed/phase191-matrix" do
  json(conn, 200, Fixtures.seed_phase191_matrix!())
end

post "/__e2e__/seed/phase191-matrix" do
  json(conn, 200, Fixtures.seed_phase191_matrix!())
end
```

**Fixture reset pattern** (`e2e_fixtures.ex` lines 12-40):
```elixir
@public_tables ~w(
  oban_jobs
)

@accrue_tables ~w(
  accrue_events
  accrue_refunds
  accrue_charges
  accrue_invoice_items
  accrue_invoices
  accrue_subscription_items
  accrue_subscriptions
  accrue_payment_methods
  accrue_promotion_codes
  accrue_coupons
  accrue_connect_accounts
  accrue_webhook_events
  accrue_customers
)

def reset! do
  tables =
    @public_tables ++
      Enum.map(@accrue_tables, &Accrue.Migration.qualified_table/1)

  TestRepo.query!("TRUNCATE TABLE #{Enum.join(tables, ", ")} RESTART IDENTITY CASCADE", [])
  :ok = Accrue.Processor.Fake.reset()
  :ok = Accrue.Actor.put_operation_id("e2e-" <> Ecto.UUID.generate())
  :ok
end
```

**Edge-state seed pattern** (`e2e_fixtures.ex` lines 144-224):
```elixir
def seed_edge_states! do
  owner_id = Ecto.UUID.generate()

  customer =
    insert_customer(%{
      owner_id: owner_id,
      name: "E2E Dunning Customer",
      email: "dunning-e2e@example.com"
    })

  at_risk_sub =
    %Subscription{}
    |> Subscription.force_status_changeset(%{
      customer_id: customer.id,
      processor: "fake",
      processor_id: "sub_e2e_dunning_at_risk",
      status: :past_due,
      past_due_since: DateTime.add(DateTime.utc_now(), -5 * 86_400, :second),
      dunning_campaign_started_at: DateTime.add(DateTime.utc_now(), -5 * 86_400, :second),
      cancel_at_period_end: false,
      lock_version: 1,
      metadata: %{},
      data: %{}
    })
    |> TestRepo.insert!()

  jpy_invoice =
    insert_invoice(customer, at_risk_sub, %{
      processor_id: "in_e2e_jpy",
      currency: "jpy",
      total_minor: 55_000,
      amount_due_minor: 55_000,
      amount_remaining_minor: 55_000,
      status: :open,
      number: "E2E-JPY-001"
    })

  long_name_customer =
    insert_customer(%{
      name: String.duplicate("A", 100) <> " LongNameCo",
      email: "long-name-e2e@example.com"
    })

  %{
    at_risk_sub_id: at_risk_sub.id,
    jpy_invoice_id: jpy_invoice.id,
    long_name_customer_id: long_name_customer.id
  }
end
```

**Deterministic matrix pattern** (`e2e_fixtures.ex` lines 247-468):
```elixir
def seed_phase191_matrix! do
  reset!()

  owner_id = "19100000-0000-4000-8000-00000000f001"
  now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
  five_days_ago = DateTime.add(now, -5 * 86_400, :second)

  customer =
    insert_customer(%{
      id: "19100000-0000-4000-8000-000000000001",
      owner_id: owner_id,
      name: "E2E Phase 191 Boundary Customer",
      email: "phase191-customer@example.com",
      processor_id: "cus_e2e_phase191_customer",
      preferred_locale: nil,
      preferred_timezone: nil,
      metadata: %{"phase191_fixture" => "non_ascii", "phase191_boundary" => "primary-route"},
      data: %{"phase191_high_count" => 100_000, "optional_profile_fields" => nil}
    })

  webhook =
    insert_webhook(%{
      id: "19100000-0000-4000-8000-000000000008",
      processor_event_id: "evt_e2e_phase191_dead",
      type: "invoice.payment_failed",
      status: :dead,
      raw_body: ~s({"id":"evt_e2e_phase191_dead","type":"invoice.payment_failed","phase191":true})
    })

  %{
    namespace: "e2e_phase191",
    customer_id: customer.id,
    single_webhook_id: webhook.id,
    boundary_counts: %{
      zero_rows: zero_rows,
      one_row: one_row,
      more_than_one_page: more_than_one_page,
      high_count: 100_000
    }
  }
end
```

**Fixture tests pattern** (`e2e_fixtures_test.exs` lines 184-229, 289-318):
```elixir
@tag :phase191
test "seed_phase191_matrix!/0 returns deterministic route IDs for every Phase 191 manifest detail placeholder" do
  result = Fixtures.seed_phase191_matrix!()

  for key <- @phase191_route_keys ++ @phase191_plan_keys do
    assert Map.has_key?(result, key), "Expected Phase 191 fixture result to include #{key}"
    refute is_nil(result[key]), "Expected Phase 191 fixture result #{key} to be non-nil"
  end

  assert result.namespace == "e2e_phase191"
  assert result.phase191_customer_id == result.customer_id
  assert TestRepo.get!(Customer, result.customer_id).processor_id == "cus_e2e_phase191_customer"
  assert TestRepo.get!(WebhookEvent, result.single_webhook_id).processor_event_id ==
           "evt_e2e_phase191_dead"
end

@tag :phase191
test "seed_phase191_matrix!/0 resets before seeding so route IDs and counts are deterministic" do
  first = Fixtures.seed_phase191_matrix!()
  first_counts = phase191_fixture_counts()

  second = Fixtures.seed_phase191_matrix!()
  second_counts = phase191_fixture_counts()

  assert Map.take(first, @phase191_route_keys) == Map.take(second, @phase191_route_keys)
  assert first.boundary_counts == second.boundary_counts
  assert first_counts == second_counts
end
```

**Apply to:** add only missing Phase 199 edge data. Prefer extending existing seeded routes over synthetic-only component states.

---

### Copy modules and copy tests

**Analogs:** `copy.ex`, `copy/invoice.ex`, `copy/connect.ex`, `copy_test.exs`.

**Delegator/import pattern** (`copy.ex` lines 1-18, 77-99):
```elixir
defmodule AccrueAdmin.Copy do
  @moduledoc """
  Tier A host-contract copy for admin surfaces (Phase 27).

  Strings here are the single source of truth for operator-facing empty states
  and related chrome described in `.planning/phases/27-microcopy-and-operator-strings/27-CONTEXT.md`.
  """

  alias AccrueAdmin.Copy.BillingEvent
  alias AccrueAdmin.Copy.Connect
  alias AccrueAdmin.Copy.Coupon
  alias AccrueAdmin.Copy.CustomerPaymentMethods
  alias AccrueAdmin.Copy.Dunning
  alias AccrueAdmin.Copy.Entitlements
  alias AccrueAdmin.Copy.Invoice
  alias AccrueAdmin.Copy.Locked
  alias AccrueAdmin.Copy.PromotionCode
  alias AccrueAdmin.Copy.Subscription

  defdelegate invoices_index_empty_title(), to: Invoice
  defdelegate invoices_index_empty_copy(), to: Invoice
  defdelegate invoices_page_title_index(), to: Invoice
  defdelegate invoices_list_heading(), to: Invoice
  defdelegate invoices_list_subtitle(), to: Invoice
  defdelegate invoices_list_first_run_empty_title(), to: Invoice
  defdelegate invoices_list_first_run_empty_body(), to: Invoice
  defdelegate invoices_list_queue_empty_title(), to: Invoice
  defdelegate invoices_list_queue_empty_body(), to: Invoice
  defdelegate invoices_list_filtered_empty_title(), to: Invoice
  defdelegate invoices_list_filtered_empty_body(), to: Invoice
end
```

**Domain module copy pattern** (`copy/invoice.ex` lines 30-55, 177-198):
```elixir
def invoices_list_heading, do: "Clear open receivables"

def invoices_list_subtitle, do: "Work invoices that need collection."

def invoices_list_first_run_empty_title, do: "No invoices yet."

def invoices_list_first_run_empty_body,
  do: "Invoices appear when subscriptions activate or renew."

def invoices_list_queue_empty_title, do: "No invoices need collection."

def invoices_list_queue_empty_body,
  do: "View all invoices to review the ledger."

def invoices_list_filtered_empty_title, do: "No invoices match these filters."

def invoices_list_filtered_empty_body,
  do: "Clear filters or adjust the search to see invoices."

def invoice_confirm_workflow_message(
      action_label,
      invoice_label,
      billing_effect,
      audit_consequence,
      source_suffix
    ) do
  "#{action_label}: This will #{billing_effect} for #{invoice_label} and #{audit_consequence}.#{source_suffix} Continue?"
end

def invoice_confirm_source_event_suffix(source_event_id),
  do: " Source event ##{source_event_id} will be linked."
```

**Connect domain copy pattern** (`copy/connect.ex` lines 18-44, 230-269):
```elixir
def connect_accounts_list_heading, do: "Finish account readiness"

def connect_accounts_list_subtitle,
  do: "Find connected accounts that need onboarding or capability work."

def connect_accounts_list_first_run_empty_title, do: "No connected accounts yet."

def connect_accounts_list_queue_empty_title, do: "No accounts need attention."

def connect_accounts_list_filtered_empty_title, do: "No connected accounts match these filters."

def connect_accounts_list_result_label_pair, do: {"connected account", "connected accounts"}

def connect_account_drawer_title(_account_label), do: "Save a per-account fee policy"

def connect_account_drawer_subtitle,
  do: "Preview the effective fee and verify identity before saving the account override."

def connect_account_step_up_unavailable,
  do:
    "Platform fee override could not start step-up verification. Confirm admin auth configuration before retrying."
```

**Copy tests pattern** (`copy_test.exs` lines 16-74, 174-325):
```elixir
@vague_standalone ~r/\A(?:failed|forbidden|invalid|not found|could not load|something went wrong|oops)\.?\z/i

test "PAGE-02 and CPY-01 page state helpers distinguish state classes" do
  states = %{
    true_empty:
      Copy.page_state_copy(:true_empty,
        resource: "billing records",
        owner_scope: "organization org_phase191"
      ),
    filtered_empty:
      Copy.page_state_copy(:filtered_empty,
        resource: "invoice records",
        owner_scope: "organization org_phase191"
      ),
    permission_denied:
      Copy.page_state_copy(:permission_denied,
        object: "invoice in_phase191",
        owner_scope: "organization org_phase191"
      )
  }

  assert states.true_empty.heading == "No billing records yet"
  assert states.filtered_empty.heading == "No records match these filters"
  assert states.permission_denied.heading == "Access restricted"

  headings = states |> Map.values() |> Enum.map(& &1.heading)
  bodies = states |> Map.values() |> Enum.map(& &1.body)

  assert Enum.uniq(headings) == headings
  assert Enum.uniq(bodies) == bodies

  refute_vague_copy!(states)
end

test "Phase 197 list copy helpers expose JTBD headings and state-specific copy" do
  pages = [
    %{
      heading: Copy.invoices_list_heading(),
      subtitle: Copy.invoices_list_subtitle(),
      expected_heading: "Clear open receivables",
      expected_subtitle: "Work invoices that need collection.",
      states: [
        Copy.invoices_list_first_run_empty_title(),
        Copy.invoices_list_queue_empty_title(),
        Copy.invoices_list_filtered_empty_title(),
        Copy.invoices_list_loading_label()
      ],
      labels: [
        Copy.invoices_list_default_lens_label(),
        Copy.invoices_list_all_lens_label()
      ],
      result_label: Copy.invoices_list_result_label_pair()
    }
  ]

  for page <- pages do
    assert page.heading == page.expected_heading
    assert page.subtitle == page.expected_subtitle
    assert Enum.uniq(page.states) == page.states
    assert Enum.all?(page.states, &(&1 != ""))
    assert Enum.all?(page.labels, &(&1 != ""))
    assert {singular, plural} = page.result_label
    assert singular != plural

    refute_vague_copy!([page.heading, page.subtitle | page.states ++ page.labels])
  end
end
```

**Apply to:** all touched page-level copy. If generated copy fixtures depend on changed strings, run:

```bash
cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json
```

## Shared Patterns

### Authentication, Owner Scope, and Step-up

**Source:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex` lines 34-61, 110-149; `connect_account_live.ex` lines 74-99.

**Apply to:** detail LiveViews and destructive/consequential drawer flows.

Pattern:
- Pull admin session from `session["accrue_admin"]`.
- Load data through query modules using `socket.assigns.current_owner_scope`.
- On not-found, flash copy from `AccrueAdmin.Copy` and redirect through `ScopedPath`.
- Consequential/destructive actions call `AccrueAdmin.StepUp.require_fresh/3`.
- `step_up_submit` delegates to `StepUp.verify/2`.
- Escape and backdrop/dismiss both settle through the same pending-step-up dismissal path.

### Overlay Substrate

**Source:** `overlay.ex` lines 53-89; `overlay.js` lines 20-57; `scroll_lock.js` lines 125-162.

**Apply to:** all modal/drawer surfaces.

Pattern:
- Portal open overlays to `#ax-overlay-root`.
- Mark shells with `data-ax-overlay-shell`, `data-presentation`, `phx-hook="Overlay"`.
- Use `data-scroll-lock` only for modal/drawer, not popover.
- Backdrop `phx-click` and FocusTrap Escape use the same `close_event`/target metadata.
- Keep `ScrollLock` ref-counted and restore `#accrue-admin-shell` inert only after the final unlock.

### Floating Surfaces

**Source:** `dropdown_menu.ex` lines 51-115; `dropdown.js` lines 16-35; `global_search.ex` lines 127-151.

**Apply to:** dropdown action menus, command palette, theme picker, and any popover-like surface.

Pattern:
- Dropdown/action menus remain native `details` disclosure surfaces with `role="menu"`/`role="menuitem"`.
- Do not add `aria-modal`, scroll lock, or overlay shell to dropdowns.
- Outside click and Escape close dropdowns and restore focus to `<summary>`.
- Command palette is overlay-like and must be tested for equivalent focus/dismissal/layering behavior if it remains outside `Overlay.overlay/1`.

### Error Handling and Copy

**Source:** `copy_test.exs` lines 16-74; `copy/invoice.ex` lines 177-198; `copy/connect.ex` lines 267-269.

**Apply to:** page-state copy, action confirmations, error/permission/not-found copy.

Pattern:
- Copy functions name the resource, state, and next useful action.
- Consequential confirmations name object, billing effect, and audit consequence.
- Avoid vague standalone strings matched by `@vague_standalone`.
- Route changed page-level strings through `AccrueAdmin.Copy` or domain modules.

### Fixture Stress

**Source:** `e2e_fixtures.ex` lines 247-468; `e2e_plug.ex` lines 36-84; `e2e_fixtures_test.exs` lines 184-318.

**Apply to:** FIX-01/FIX-02 multi-step flows and edge-state browser tests.

Pattern:
- Seed through `/__e2e__/seed/*`.
- Return deterministic IDs needed by route builders.
- Reset before matrix seeds when deterministic route IDs/counts matter.
- Assert persisted DB state in ExUnit and rendered route behavior in Playwright.

### Motion and Geometry

**Source:** `app.css` lines 1375-1444, 1584-1595, 1827-1838, 2715-2825, 2955-3021; `theme.css` lines 52-68, 412-438; `reduced-motion.spec.js` lines 63-267.

**Apply to:** drawer geometry, dropdown/palette motion, reduced-motion checks, focus-ring immediacy.

Pattern:
- Drawer desktop: right docked, `translateX(100%)` entry.
- Drawer mobile: bottom sheet, `translateY(100%)` entry.
- Dropdowns: trigger-adjacent, max viewport width/height, `transform-origin: top right`.
- Reduced motion collapses travel tokens and durations through theme tokens, not one-off CSS overrides.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Optional new anchored floating helper, if planner creates one | utility/hook | event-driven + transform | No shared positioning helper exists. Prefer extending dropdown/command-palette local code first; create only after near-edge tests show repeated drift. |
| Full production theme precedence Playwright helper, if planner extracts one | utility/test | local persistence | Partial analog exists in `phase7-uat.spec.js`; no reusable helper currently covers cookie > localStorage > system/default plus media emulation. |

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/components`, `accrue_admin/lib/accrue_admin/live`, `accrue_admin/assets/js/hooks`, `accrue_admin/assets/css`, `accrue_admin/e2e`, `accrue_admin/test/js`, `accrue_admin/test/accrue_admin`, `accrue_admin/test/support`, `accrue_admin/package.json`  
**Files scanned:** 150+ admin source/test files via `rg --files` and targeted `rg` searches  
**Pattern extraction date:** 2026-06-29  
**Project instructions checked:** `CLAUDE.md` present and read; `AGENTS.md`, `.claude/CLAUDE.md`, `.claude/skills`, `.agents/skills`, and `.codex/skills` absent in workspace.

