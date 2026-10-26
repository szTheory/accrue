# Phase 236: Portal Billing Self-Service - Pattern Map

**Mapped:** 2026-10-08  
**Files analyzed:** 24 implementation, test, and CI targets  
**Analogs found:** 24 / 24

## File Classification

The phase refines these existing paths in place; there is no evidence for a new route, provider, schema, package, or account-selection file. Test targets are existing suites to extend, with the served-host spec and any new focused specs following the same conventions.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_portal/lib/accrue_portal/live/home_live.ex` | component (LiveView page) | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` | component (LiveView page) | CRUD | same file | exact |
| `accrue_portal/lib/accrue_portal/live/subscription_live.ex` | component (LiveView page) | CRUD | same file | exact |
| `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex` | component (LiveView page) | CRUD | same file | exact |
| `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` | component (LiveView page) | request-response / file-I/O (provider SDK) | same file | exact |
| `accrue_portal/lib/accrue_portal/live/invoices_live.ex` | component (LiveView page) | CRUD / request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | component (LiveView page) | request-response / event-driven | same file | exact |
| `accrue_portal/lib/accrue_portal/billing_read_model.ex` | model / service | CRUD | same file | exact |
| `accrue_portal/lib/accrue_portal/copy.ex` | utility | transform | same file | exact |
| `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` | controller | CRUD / request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` | controller | request-response | same file | exact |
| `accrue_portal/priv/static/accrue_portal.js` | utility (client hook) | event-driven / request-response | same file | exact |
| `accrue_portal/priv/static/accrue_portal.css` | config (presentation) | transform | same file | exact |
| `accrue_portal/lib/accrue_portal/layouts.ex` | component (shared layout) | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/router.ex` | route | request-response | same file | exact |
| `accrue_portal/test/accrue_portal/live/invoices_live_test.exs` | test | CRUD | same file | exact |
| `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs` | test | CRUD | same file | exact |
| `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` | test | CRUD | same file | exact |
| `accrue_portal/test/accrue_portal/live/payment_methods_live_test.exs` | test | CRUD | same file | exact |
| `accrue_portal/test/accrue_portal/live/add_payment_method_live_test.exs` | test | request-response | same file | exact |
| `accrue_portal/test/accrue_portal/context_live_test.exs` and `context_post_test.exs` | test | request-response | same files | exact |
| `accrue_portal/test/accrue_portal/checkout_context_test.exs` | test | request-response | same file | exact |
| `examples/accrue_host/e2e/phase102-portal-checkout.spec.js` | test | request-response / event-driven | same file | exact |
| `.github/workflows/ci.yml` | config (CI) | batch | same file | exact |

## Pattern Assignments

All named analog paths were verified as tracked with `git ls-files`; the Portal JS/CSS reside in `accrue_portal/priv/static/` (not `lib/accrue_portal/priv/static/`).

### Shared LiveView page pattern

**Analogs:** `home_live.ex` (lines 1-18, 21-35), `subscriptions_live.ex` (1-19, 22-49, 53-103), `subscription_live.ex` (1-36, 39-45, 106-144), `payment_methods_live.ex` (1-48, 51-110), `add_payment_method_live.ex` (1-51, 68-130), `invoices_live.ex` (1-26, 28-69), `checkout_live.ex` (25-105, 142-235, 318-440). All seven are the actual route owners declared in `router.ex` (102-144).

**Imports and mount:** pages use `Phoenix.LiveView`, aliases for billing/read model/copy/path modules, and receive current customer/context assigns from the shared auth hook. Example, `home_live.ex`:

```elixir
defmodule AccruePortal.Live.HomeLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal} = _session, socket) do
    data = BillingReadModel.dashboard(socket.assigns.current_customer)
    {:ok, socket |> assign(:page_title, Copy.home_page_title())
      |> assign(:portal, portal) |> assign(:base_path, portal["mount_path"])
      |> assign(:dashboard, data)}
  end
```

**Authorization and event outcomes:** `subscription_live.ex` is the strongest action analog. Confirmation handlers reauthorize the mounted exact subscription and set both an inline `role="status"` notice and flash after successful mutation (lines 115-141, 216-219). `subscriptions_live.ex` (22-49) demonstrates list action authorization, success refresh, not-found, denial, and mutation error branches. Reuse these patterns for D-02/D-03/D-07; a context pin is carried in links/forms as a locator, not treated as an authorization grant.

**Page copy and lifecycle:** `subscriptions_live.ex` (71-80) and `subscription_live.ex` (216-239) call `Copy.subscription_lifecycle_label/summary` rather than inventing lifecycle descriptions in templates. Rendered empty states currently branch on list equality (`invoices_live.ex` 36-57; `payment_methods_live.ex` 68-107); when reads gain tagged outcomes, branch on success-empty separately from unavailable.

### `accrue_portal/lib/accrue_portal/billing_read_model.ex` (model/service, CRUD)

**Analog:** same file, especially lines 18-35, 43-66. Customer scoping is in the query itself; detail lookups return `{:ok, record}` or `{:error, :not_found}`. Existing list reads use bare lists or force-match success, so use this seam to introduce explicit read outcomes without converting operational failure into `[]`.

```elixir
def subscription(%Customer{id: customer_id}, id) when is_binary(id) do
  case Repo.get_by(Subscription, id: id, customer_id: customer_id) do
    %Subscription{} = subscription -> {:ok, Repo.preload(subscription, :subscription_items)}
    nil -> {:error, :not_found}
  end
end

def invoices(%Customer{id: customer_id}) do
  from(invoice in Invoice,
    where: invoice.customer_id == ^customer_id,
    order_by: [desc: invoice.inserted_at], limit: 20
  ) |> Repo.all()
end
```

### `accrue_portal/lib/accrue_portal/copy.ex` (utility, transform)

**Analog:** same file, lifecycle and action-copy functions at lines 61-95, 97-182. Keep user-facing state language centralized and parameterized by actual subscription/provider state. Existing cancellation copy shows the provider-sensitive branching convention:

```elixir
def subscription_cancel_body(%Subscription{processor: "braintree"}) do
  "Cancel now can end access immediately. If you need end-of-term non-renewal instead, contact support."
end

def subscription_cancel_body(_subscription),
  do: "End at period end to turn off renewal now and keep access through the current billing period."
```

Expand unknown-state handling here; do not add unsupported promises about host access, invoice completeness, or document retention.

### Payment-method and checkout controllers

**Analogs:** `payment_method_controller.ex` lines 11-39, 41-97, 107-136; `checkout_controller.ex` lines 13-55, 57-97, 181-209, 229-250. For payment-method POSTs, retain owner-scoped target lookup, action-specific fresh authorization, actor attribution via `Accrue.Actor.with_actor`, and result-dependent flash/redirect. For checkout, keep exact pinned context resolution, target/session validation and authorization before claim/mutation. `checkout_controller.ex` distinguishes completed, card-declined, and uncertain outcomes; do not infer payment from query params.

```elixir
case authorize(conn, :payment_method_create, customer) do
  :ok ->
    case with_actor(conn, fn ->
           Billing.add_payment_method(customer, %{vault_acquisition: %{reference: nonce}})
         end) do
      {:ok, _} -> conn |> put_flash(:info, "Payment method saved.") |> redirect(to: payment_methods_path(conn))
      {:error, _} -> conn |> put_flash(:error, "Unable to save payment method.") |> redirect(to: payment_methods_path(conn))
    end
  :error -> blocked(conn)
end
```

### `accrue_portal/priv/static/accrue_portal.js`

**Analog:** tracked package-served JS, lines 4-119 and 121-180. `BraintreeHostedFields.mounted` waits for the SDK, requires the server client token, binds only once, initializes official iframe fields and disables submit until ready. `destroyed` clears nonce/state and tears down Hosted Fields (106-119). Tokenization clears stale nonce before call and again on failure; success writes only nonce to the hidden field (121-180). Preserve this hook lifecycle and use the browser lane to prove the served asset behavior.

### `accrue_portal/priv/static/accrue_portal.css` and `layouts.ex`

**Analogs:** CSS is tracked package static asset; shared tokens and focus states at CSS lines 1-126, 378-380; responsive breakpoints at 590-623. `layouts.ex` lines 31-115 renders `data-theme`, host-brand shell, and accessible theme controls (`aria-pressed`, labels). Retain public `--accrue-*` token usage and adapt existing selectors/breakpoints; validate rendered 320px behavior, focus, theme and reduced-motion behavior in the host browser.

### Tests: ExUnit and LiveViewTest

**Analogs:**

- `invoices_live_test.exs` lines 17-43 creates current and foreign customer invoice fixtures and verifies record/hosted URL isolation. Extend with not-found and injected read failure to prove empty differs from unavailable.
- `add_payment_method_live_test.exs` lines 13-31 configures deterministic auth and Braintree token fixtures with `on_exit` cleanup; lines 33-65 asserts authorized Hosted Fields markup and fail-closed token generation.
- `context_live_test.exs`, `context_post_test.exs`, and `checkout_context_test.exs` cover fresh authorization, pins, and POST target boundary. Follow their fixture setup/cleanup and assertions for stale/forged/denied targets.
- Per-page suites `subscriptions_live_test.exs`, `subscription_live_test.exs`, and `payment_methods_live_test.exs` are the direct action/copy assertion seams; use the existing `AccruePortal.ConnCase` and fixtures rather than live provider calls.

### `examples/accrue_host/e2e/phase102-portal-checkout.spec.js` (test, browser request-response)

**Analog:** same file lines 1-32 for shared Playwright helpers and accessibility scanning; 34-75 for deterministic reseed/login, navigation, role/text assertions, and Axe checks. Use `support/test.js` and `support/fixture.js`, seeded host fixtures, `waitForLiveView`, and test semantic roles/actual served assets. Keep browser checks on visible interaction, viewport, focus and package-served CSS/JS; move authorization/data permutations to deterministic ExUnit/controller suites.

### `.github/workflows/ci.yml` (config, batch)

**Analog:** tracked workflow. Portal package checks are already merge-blocking at lines 721-742 (`mix format --check-formatted`, warnings-as-errors compile/test, `mix hex.audit`). Served-host Playwright lane is at 1488-1613: Node 22, npm CI, host asset build, seeded E2E DB, Chromium install, sharded run and report/trace upload. Braintree checkout has an explicit browser lane at 1615-1645. Extend an existing lane/spec and preserve setup/fixture constraints; no new CI framework is indicated.

## Shared Patterns

### Fresh authorization and identity

**Source:** `accrue_portal/lib/accrue_portal/authorize.ex` lines 11-26 and 52-80; `context.ex` lines 3-11, 139-163; controller seams above. Resolve current context, scope lookup to `context.customer`, authorize named action against the exact record, and run mutation with the authenticated actor. Pins identify the displayed context only. Never fall back to another billable after selection or denial.

### Visible, observed outcomes

**Source:** `subscription_live.ex` lines 75-92, 120-141; `checkout_controller.ex` lines 73-97, 199-250. Success/error announcements follow returned outcomes. Provider uncertainty remains uncertain; failed reads remain distinct from successful empty reads.

### Host branding and safe destinations

**Source:** `router.ex` lines 170-186, `layouts.ex` lines 31-115, `checkout_controller.ex` lines 181-197, `context.ex` lines 213-219. Use host-supplied brand/theme/mount-path values, current tokenized Portal styling, `Context.valid_local_path?/1`, and established local fallback. Only allow explicitly host-approved external destinations through the existing policy.

### Secure fields

**Source:** `add_payment_method_live.ex` lines 14-29, 82-118; `accrue_portal/priv/static/accrue_portal.js` lines 4-180. Server authorizes before issuing client token; provider iframe handles card fields; only one-time nonce crosses to server; clear nonce and tear down fields on abandonment/failure.

## No Analog Found

None. All implementation and automated verification files have direct tracked analogs. The read-failure outcome itself is new behavior, but `BillingReadModel` and the existing page test suites are the appropriate extension seams.

## Metadata

**Analog search scope:** `accrue_portal/lib/accrue_portal/`, `accrue_portal/priv/static/`, `accrue_portal/test/accrue_portal/`, `examples/accrue_host/e2e/`, `.github/workflows/ci.yml`.  
**Files scanned:** 24 classified targets plus shared auth/layout/router and test harness references.  
**Pattern extraction date:** 2026-10-08.  
**Tracked-source gate:** All analog paths above were checked against `git ls-files`; no ignored runtime mirror paths are referenced.
