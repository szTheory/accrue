# Phase 234: Admin Customers & Subscriptions - Pattern Map

**Mapped:** 2026-10-07  
**Files analyzed:** 22 likely changed/new files, based on CONTEXT, RESEARCH, VALIDATION  
**Analogs found:** 22 / 22

All named analogs below were verified with `git ls-files`; paths refer to tracked source, not generated or ignored mirrors. The context/research/validation records identify existing Admin Home/search, customer and subscription list/detail/action surfaces, scoped queries, shared presentation components, tests, and one new adopter-host browser spec.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | controller (LiveView) | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | role-match |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | component (LiveComponent) | request-response | same file; `global_search_test.exs` | exact |
| `accrue_admin/lib/accrue_admin/live/customers_live.ex` | controller (LiveView) | CRUD/read | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | controller (LiveView) | CRUD/read | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | controller (LiveView) | CRUD/read | same file; `customers_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | controller (LiveView) | request-response/action | same file; `step_up.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/customers.ex` | service/query | CRUD/read | `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | service/query | CRUD/read | same file; `customers.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/invoices.ex` | service/query | CRUD/read | `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | role-match |
| `accrue_admin/lib/accrue_admin/owner_scope.ex` | utility/security boundary | request-response | same module and `queries/subscriptions.ex` | exact |
| `accrue_admin/lib/accrue_admin/scoped_path.ex` | utility | transform/navigation | same module | exact |
| `accrue_admin/lib/accrue_admin/step_up.ex` | service | event-driven continuation | same module | exact |
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | component | request-response | `customers_live.ex` / `subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | component | transform/presentation | same component and `subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/tabs.ex` | component | request-response/navigation | `customer_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` | component | request-response | `subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/components/money_formatter.ex` | utility | transform | `AccrueAdmin.BillingPresentation` callers | role-match |
| `accrue_admin/assets/css/app.css` | config/style | transform/presentation | same stylesheet and `theme.css` | exact |
| `accrue_admin/assets/css/theme.css` | config/style | transform/presentation | same stylesheet | exact |
| `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | test | request-response | same test; `step_up_test.exs` | exact |
| `accrue_admin/test/accrue_admin/components/global_search_test.exs` | test | request-response | same test | exact |
| `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` (new) | test | request-response/browser | `examples/accrue_host/e2e/verify01-admin-denial.spec.js` | exact |

Tests and other existing focused suites should be extended in place where RESEARCH/VALIDATION says “existing tests”; the only specifically new test file is the host-lane spec above. Keep the Admin package lane (`accrue_admin/e2e`, configured by `accrue_admin/playwright.config.js`) distinct from the adopter-host lane (`examples/accrue_host/e2e`, configured by `examples/accrue_host/playwright.config.js`). The prescribed new browser command runs from `examples/accrue_host`, while ExUnit and Admin asset builds run from `accrue_admin`.

## Pattern Assignments

### Customer/subscription LiveViews

**Targets:** `customers_live.ex`, `customer_live.ex`, `subscriptions_live.ex`, `subscription_live.ex`, and `dashboard_live.ex`.  
**Analogs:** corresponding existing LiveViews, with `subscription_live.ex` as the action/step-up analog and `subscriptions_live.ex` as the list/navigation analog.

`subscriptions_live.ex:1-62` establishes the imports/aliases, route-derived mount path, scope-aware list setup, URL-backed `handle_params/3`, and filter patch pattern:

```elixir
alias AccrueAdmin.Queries.Subscriptions

@default_queue_status "past_due,canceling"

@impl true
def mount(_params, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})
  {:ok, socket |> assign_shell(admin) |> assign(:params, %{}) ...}
end

def handle_event("data_table_filter", params, socket) do
  {:noreply,
   AccrueAdmin.DataTableNav.patch_with_filters(
     socket, socket.assigns.table_path, Map.drop(params, ["_target", "_csrf_token"])
   )}
end
```

`subscription_live.ex:44-82` is the detail security pattern: read through `Subscriptions.detail(id, socket.assigns.current_owner_scope)` and redirect with generic denial copy when not found. `subscription_live.ex:85-163` shows event payload validation, availability re-check, pending review, and destructive-action delegation to `StepUp.require_fresh/4`. `step_up.ex:27-83` stores and invokes the continuation only after verification; phase research identifies that current continuation captures stale action/socket state, so use this seam but add the specified fresh scoped revalidation before dispatch.

`subscription_live.ex:1603-1635` is the closest mutation/result seam: the existing Admin context wraps core `Billing` calls and distinguishes success tuple forms. It currently mints operation identity during dispatch, uses an unscoped refresh helper, and handles all errors generically; phase decisions explicitly require correcting these behaviors. Do not copy those limitations. Core operation/idempotency examples are in tracked `accrue/lib/accrue/billing/subscription_actions.ex` (cancel/resume/pause semantics) and item operations in the corresponding core billing module; use core predicates and the processor matrix as the eligibility authority.

### Scoped query and navigation

**Targets:** `queries/customers.ex`, `queries/subscriptions.ex`, `queries/invoices.ex`, `owner_scope.ex`, `scoped_path.ex`.

`queries/subscriptions.ex:88-102` supplies the scoped detail pattern:

```elixir
Subscription
|> join(:inner, [subscription], customer in Customer,
  on: customer.id == subscription.customer_id
)
|> scope_query(owner_scope)
|> where([subscription, _customer], subscription.id == ^id)
|> select([subscription, _customer], subscription)
|> Repo.one()
|> case do
  nil -> :not_found
  subscription -> {:ok, Repo.preload(subscription, [:customer, :subscription_items])}
end
```

Follow this owner-scope-first query shape for detail, aggregate, and post-action reads. `scoped_path.ex:7-27` is the canonical alternate-mount and org-scope URL builder; pass only allowlisted route-local params and derive org from the current authorized `OwnerScope`, never from return context. `queries/behaviour.ex` and `queries/cursor.ex` own normalization and opaque cursor decode/encode; retain cursor pagination rather than adding offset scans. Search analog `global_search.ex:72-90,147-173` invokes exactly the existing three bounded query groups (`limit: 5`); preserve that supported query contract and represent group failures separately from empty results.

### Components, money, and CSS

**Targets:** DataTable, Detail, Tabs, DetailDrawer, MoneyFormatter, `app.css`, `theme.css`.

Use the existing components from `customers_live.ex` / `subscriptions_live.ex` for desktop tables and narrow labeled-card presentation; use `customer_live.ex` for URL-backed tab selection and `subscription_live.ex` for drawer composition. Existing component APIs should be reused rather than introducing a new modal or table primitive. Money display should route through the established money formatter / `BillingPresentation` implementation so currency minor-unit behavior stays centralized.

`app.css:1-5` imports `theme.css`; `theme.css:1-35` owns `html.accrue-admin` typography, spacing, radius, icon, shadow and motion roles. Phase 233 `DESIGN.md` is the inherited semantic contract: Admin owns `--ax-*`, keep operator density, readable status labels, visible focus and 320px reflow. Change Admin selectors/tokens in these tracked files only; don't copy Portal `--accrue-*` CSS into Admin.

### Tests and browser lane

`accrue_admin/test/accrue_admin/live/subscription_live_test.exs:1-75` is the deterministic mounted test pattern: `AccrueAdmin.LiveCase, async: false`, host auth adapter, factory fixtures, and repo-preloaded records. Existing cases cover step-up, forged events, owner denial and action rendering; extend the nearest relevant case and preserve positive controls. `global_search_test.exs:1-35` shows isolated LiveComponent tests using `render_component/2` and Phoenix LiveView test helpers. The validation map also names `customers_live_test.exs`, `subscriptions_live_test.exs`, `customer_live_test.exs`, `step_up_test.exs`, and `scoped_path_test.exs` for their respective behavior.

For the new browser spec, `examples/accrue_host/e2e/verify01-admin-denial.spec.js:1-24` provides the host fixture imports and `test`/`expect` idiom. It is intentionally skipped because the configured host browser server currently returns 500 for that deep link; preserve its failure direction and diagnose before restoring it. Host browser helpers are under `examples/accrue_host/e2e/support/`. Do not use `accrue_admin/e2e` for the new adopter-host flow.

## Shared Patterns

### Scope and authorization

**Sources:** `accrue_admin/lib/accrue_admin/owner_scope.ex`, `queries/customers.ex`, `queries/subscriptions.ex`, `scoped_path.ex`.  
**Apply to:** every customer/subscription detail, search group, aggregate, related link, action revalidation and result refresh. Current scope is security input; route params and UI assigns do not grant access. Use generic denial copy and do not render foreign identifiers or tokens.

### Action and step-up

**Sources:** `subscription_live.ex:85-163`, `step_up.ex:27-83`, core `accrue/lib/accrue/billing/subscription.ex` and `subscription_actions.ex`.  
**Apply to:** every supported mutation entry point. Re-evaluate host authorization, scope, target/item membership, lifecycle predicate, provider capability and consequence immediately before dispatch, including after a step-up delay. Reuse the operation ID for one staged submission; suppress duplicate dispatch; on reconnect discard uncertain pending intent. Preserve ambiguous outcomes as “Outcome not confirmed.”

### Navigation and UI semantics

**Sources:** `DataTableNav`, `ScopedPath`, `DataTable`, `DetailDrawer`, `Tabs`, Phase 233 `DESIGN.md`.  
**Apply to:** list/detail/search return journeys and overlays. Keep list filters and tabs URL-backed, validate bounded local return state, preserve current owner scope and mount, and use native link/button semantics with existing focus behavior. Keep `--ax-*` roles, readable state labels and the established desktop/narrow table path.

## No Analog Found

None. The new host spec has an exact test-lane analog. The requested changed behavior is new, but the surrounding LiveView/query/component/browser structures already exist and are the intended patterns.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/{live,components,queries}`, `accrue_admin/test/accrue_admin`, `accrue_admin/assets/css`, `accrue/lib/accrue/billing`, `examples/accrue_host/e2e`, and Phase 233 design records.  
**Files scanned:** 22 named/likely targets plus focused analogs.  
**Pattern extraction date:** 2026-10-07
