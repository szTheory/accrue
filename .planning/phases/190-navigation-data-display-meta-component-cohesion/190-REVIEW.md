---
phase: 190-navigation-data-display-meta-component-cohesion
reviewed: 2026-06-18T16:53:57Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - accrue_admin/assets/css/app.css
  - accrue_admin/e2e/admin-group-contracts.spec.js
  - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
  - accrue_admin/lib/accrue_admin/components/data_table.ex
  - accrue_admin/lib/accrue_admin/components/detail.ex
  - accrue_admin/lib/accrue_admin/components/detail_drawer.ex
  - accrue_admin/lib/accrue_admin/components/dropdown_menu.ex
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/components/kpi_card.ex
  - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
  - accrue_admin/lib/accrue_admin/components/tabs.ex
  - accrue_admin/lib/accrue_admin/components/window_selector.ex
  - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
  - accrue_admin/lib/accrue_admin/dev/component_registry.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
  - accrue_admin/test/accrue_admin/components/data_table_test.exs
  - accrue_admin/test/accrue_admin/components/display_components_test.exs
  - accrue_admin/test/accrue_admin/components/global_search_test.exs
  - accrue_admin/test/accrue_admin/components/navigation_components_test.exs
  - accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs
  - accrue_admin/test/accrue_admin/dev/component_registry_test.exs
findings:
  critical: 2
  warning: 6
  info: 0
  total: 8
status: issues_found
---

# Phase 190: Code Review Report

**Reviewed:** 2026-06-18T16:53:57Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Reviewed the Phase 190 component, dev-kitchen, CSS, Playwright, and focused test changes. The highest-risk issues are in global search: the closed command palette still exposes a modal dialog to assistive technology, and the result rows are styled as clickable controls without native or JS click behavior. Additional warnings cover missing modal input labelling, query-param loss in the window selector, a wrong canonical group locator, DataTable copy/accessibility gaps, and a representative browser probe that can pass without proving the KPI group locator on the live recovery route.

Phase 190 validation remains pending baseline evidence because `admin-baseline.spec.js` hung, as recorded in `190-VALIDATION.md`.

## Critical Issues

### CR-01: [BLOCKER] Closed Global Search Remains An `aria-modal` Dialog

**File:** `accrue_admin/lib/accrue_admin/components/global_search.ex:130`

**Issue:** `AppShell` renders `GlobalSearch` on every admin page, and `GlobalSearch.render/1` always emits the dialog markup with `role="dialog"` and `aria-modal="true"` even when `@is_open` is false. The closed state is CSS-only (`data-open="false"`, opacity/pointer-events), so assistive technology can still encounter a modal dialog that is visually closed. That is an accessibility behavior regression across the admin shell.

**Fix:**
```elixir
<div id={@id} class="ax-command-palette-wrapper" data-open={to_string(@is_open)} ...>
  <%= if @is_open do %>
    <div class="ax-command-palette-backdrop" phx-click="close" phx-target={@myself}></div>
    <div
      class="ax-command-palette"
      phx-hook="CommandPalette"
      id="command-palette-container"
      data-target={@myself}
      role="dialog"
      aria-modal="true"
      aria-label="Global search"
    >
      ...
    </div>
  <% end %>
</div>
```
Add a component test that renders `is_open: false` and refutes `role="dialog"` / `aria-modal="true"` in the closed HTML.

### CR-02: [BLOCKER] Command Palette Results Are Not Mouse-Activatable Controls

**File:** `accrue_admin/lib/accrue_admin/components/global_search.ex:175`

**Issue:** Search shortcuts and results are rendered as `<li class="ax-command-palette-item" data-path=...>` elements. CSS gives them a pointer cursor, but the reviewed markup is not a link/button, is not tabbable, and has no native activation. The related hook only opens the palette on document clicks and activates the selected item on Enter, so pointer users can click visible results and nothing happens.

**Fix:**
```elixir
<li class="ax-command-palette-list-item">
  <.link patch={path(@mount_path, "/customers")} class="ax-command-palette-item">
    <Icon.icon name={:users} size="sm" />
    <span>Look up a customer</span>
  </.link>
</li>
```
Alternatively keep `data-path`, but add a click handler in the hook that delegates clicks from `[data-path], [data-action]` to the same activation path used by Enter. Cover both click and keyboard activation in Playwright.

## Warnings

### WR-01: [WARNING] Step-Up Challenge Input Has No Programmatic Label Or Error Association

**File:** `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex:40`

**Issue:** The modal challenge input is rendered with only a placeholder (`Password`, `Verification code`, or `Assertion payload`). There is no `<label>`, `aria-label`, or `aria-labelledby`, and errors are displayed in a paragraph that is not connected to the input. Screen-reader users can land in an unlabeled destructive-action challenge and may not hear the validation error.

**Fix:** Give the input a stable id, add a visually hidden label, and wire error state into `aria-invalid`/`aria-describedby`.

```elixir
<label :if={input_name(@challenge)} class="ax-visually-hidden" for="step-up-code">
  <%= input_placeholder(@challenge) %>
</label>
<input
  :if={input_name(@challenge)}
  id="step-up-code"
  type={input_type(@challenge)}
  name={input_name(@challenge)}
  aria-invalid={if @error, do: "true"}
  aria-describedby={if @error, do: "step-up-error", else: "step-up-description"}
  placeholder={input_placeholder(@challenge)}
/>
<p :if={@error} id="step-up-error" class="ax-body" data-role="step-up-error"><%= @error %></p>
```

### WR-02: [WARNING] Window Selector Drops Existing Query Parameters

**File:** `accrue_admin/lib/accrue_admin/components/window_selector.ex:43`

**Issue:** `window_href/2` parses `base_path` and replaces the whole query with `%{"window" => value}`. If a caller passes an existing query string, changing the window silently drops unrelated filters or owner-scope parameters. The module docs say existing query params are handled safely, but the implementation only avoids a double `?`.

**Fix:**
```elixir
defp window_href(base_path, value) do
  uri = URI.parse(base_path)

  query =
    uri.query
    |> case do
      nil -> %{}
      existing -> URI.decode_query(existing)
    end
    |> Map.put("window", value)
    |> URI.encode_query()

  uri
  |> Map.put(:query, query)
  |> URI.to_string()
end
```
Add a test for `"/billing/analytics/recovery?owner=platform&window=30d"` preserving `owner=platform` while replacing `window`.

### WR-03: [WARNING] Canonical Group Contract Publishes A Nonexistent ID Locator

**File:** `accrue_admin/lib/accrue_admin/dev/component_registry.ex:969`

**Issue:** `group_locators/1` publishes `"##{slug}"`, but the rendered proof roots use ids like `grp190-#{slug}`. Tests assert the bad locator is present in the contract, so downstream consumers that trust `contract.locators` will try `#table-empty-loading-error-pagination` even though the page renders `#grp190-table-empty-loading-error-pagination`.

**Fix:**
```elixir
defp group_locators(slug) do
  [
    ~s([data-component-group="#{slug}"]),
    "#grp190-#{slug}",
    "/billing/dev/components?group=#{slug}"
  ]
end
```
Update `component_group_registry_test.exs` to expect the rendered proof-root id, not `##{slug}`.

### WR-04: [WARNING] DataTable Controls Miss Phase 190 Copy And Accessibility Contracts

**File:** `accrue_admin/lib/accrue_admin/components/data_table.ex:137`

**Issue:** The filter toolbar reset link still renders visible text `Clear` instead of the Phase 190 contract label `Clear filters`. The bulk selection button renders only `Select visible` / `Clear visible` with no contextual accessible name, despite the UI spec requiring bulk controls to expose names like `Select visible invoices` or `Clear visible customers` when context is not otherwise programmatic.

**Fix:**
```elixir
attr(:resource_plural, :string, default: "rows")

<a href={@path} class="ax-button ax-button-ghost">
  <%= Copy.data_table_clear_filters_label() %>
</a>

<button
  type="button"
  phx-click="toggle-all"
  phx-target={@myself}
  aria-label={
    if all_visible_selected?(assigns),
      do: "Clear visible #{@resource_plural}",
      else: "Select visible #{@resource_plural}"
  }
  ...
>
  <%= if all_visible_selected?(assigns), do: "Clear visible", else: "Select visible" %>
</button>
```
Add focused assertions for the toolbar clear label and the bulk selection accessible name.

### WR-05: [WARNING] Representative KPI Browser Probe Can Pass Without The KPI Group Locator

**File:** `accrue_admin/e2e/admin-group-contracts.spec.js:41`

**Issue:** The `recovery-kpi` representative route is declared as the recovery/KPI sample, but it maps `group: "table-empty-loading-error-pagination"` and `assertRepresentativeRoute/2` only checks generic `.ax-kpi-card` / `.ax-funnel-chart` selectors plus the table and tabs group locators. A live recovery page can omit `data-component-group="kpi-chart-table"` entirely and this browser probe still passes.

**Fix:** Make the representative route assert the actual KPI group contract and update the live recovery surface to opt in where the KPI/chart/table group starts.

```javascript
{ category: "recovery-kpi", group: "kpi-chart-table", path: "/billing/analytics/recovery" }

if (route.category === "recovery-kpi") {
  await expect(groupLocator(page, "kpi-chart-table").first()).toBeVisible();
  await expect(page.locator(".ax-funnel-chart").first()).toBeVisible();
  await expect(groupLocator(page, "table-empty-loading-error-pagination").first()).toBeVisible();
  return;
}
```

### WR-06: [WARNING] DataTable Tests Do Not Exercise The New Bulk/Reset Contracts

**File:** `accrue_admin/test/accrue_admin/components/data_table_test.exs:315`

**Issue:** The current DataTable component tests cover row-level `aria-label` values, but they do not assert the bulk control accessible name or the toolbar reset text. That allowed WR-04 to ship: row selection labels are covered, while the Phase 190 bulk-selection and `Clear filters` contracts remain unguarded.

**Fix:** Extend the existing DataTable test to assert both controls.

```elixir
assert html =~ "Clear filters"
assert html =~ ~s(aria-label="Select visible fixture rows")

html = render_click(element(view, "[data-role='toggle-all']"))
assert html =~ ~s(aria-label="Clear visible fixture rows")
```

---

_Reviewed: 2026-06-18T16:53:57Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
