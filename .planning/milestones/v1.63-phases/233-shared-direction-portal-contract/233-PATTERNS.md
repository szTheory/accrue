# Phase 233: Shared Direction & Portal Contract - Pattern Map

**Mapped:** 2026-10-07  
**Files analyzed:** 19 proposed/likely touched files or artifact groups (the upstream inputs define outcomes and source seams, but do not lock a complete output path list)  
**Analogs found:** 19 / 19

## Scope and naming note

Paths below are existing tracked analogs unless marked **PROPOSED**. Context/research do not specify final callback names, module path, new test filenames, inventory filename, or exact visual files to edit. Do not treat illustrative callback signatures in RESEARCH.md as current symbols. Existing compatibility names are `Accrue.Portal.CustomerSession.resolve/2`, `Accrue.Portal.AuthPlug`, `Accrue.Portal.AuthHook`, `AccruePortal.Authorize`, and the existing controller/LiveView modules cited below.

## File Classification

| New/Modified File or artifact | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_portal/lib/accrue_portal/customer_session.ex` | service | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/auth_plug.ex` | middleware | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/auth_hook.ex` | middleware | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/authorize.ex` | utility | CRUD | same file + `billing_read_model.ex` | exact |
| `accrue_portal/lib/accrue_portal/router.ex` | route | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` | controller | CRUD | same file | exact |
| `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` | controller | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` | component | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | component | request-response | same file | exact |
| `accrue_portal/priv/static/accrue_portal.js` | utility | event-driven | same file, `Hooks.BraintreeHostedFields` | exact |
| `accrue_portal/config/config.exs` (if adding optional adapter setting) | config | request-response | `accrue_portal/mix.exs` config/dependency conventions | role-match |
| `accrue_portal/test/support/fixtures.ex` and new adapter/authorization tests (**PROPOSED** test paths) | test | CRUD / request-response | `test/accrue_portal/live/payment_methods_wrong_tenant_test.exs` | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | service | CRUD | same file | exact |
| `examples/accrue_host/lib/accrue_host/accounts/scope.ex` | model | transform | same file | exact |
| `examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex` | controller | request-response | same file | exact |
| `accrue_admin/assets/css/theme.css`, `accrue/priv/static/brand.css`, `accrue_portal/priv/static/accrue_portal.css` | config / asset styles | transform | these three owned consumer files | exact |
| `DESIGN.md`, source/route inventory and provenance artifact (**PROPOSED locations**) | utility / docs | transform | Admin CSS census + Admin visual E2E artifacts; no exact matching Portal artifact established | role-match |
| `examples/accrue_host/e2e/verify01-org-switching.spec.js` and mixed/personal scenario (**PROPOSED**) | test | event-driven | same spec + `examples/accrue_host/e2e/support/fixture.js` | exact |
| `accrue/priv/static/brand.css` and Portal host brand bridge | config | transform | same file + Portal CSS | exact |

## Pattern Assignments

### Portal context resolution and shared HTTP/LiveView boundary

**Targets:** existing `customer_session.ex`, `auth_plug.ex`, `auth_hook.ex`, `authorize.ex`, `router.ex`; a context adapter module/config key would be **PROPOSED**, not a current symbol.

**Analog:** `accrue_portal/lib/accrue_portal/customer_session.ex` (tracked)

Existing resolver is personal-user based. It returns unauthenticated/unsupported-shape errors and has an explicit `create?` switch. The no-create branch queries the composite identity; retain the exact owner type, losslessly stringified owner ID, and configured processor predicate.

```elixir
def resolve(session, opts \\ []) when is_map(session) and is_list(opts) do
  create? = Keyword.get(opts, :create?, true)

  case Accrue.Auth.current_user(session) do
    nil ->
      {:error, :unauthenticated}

    %{__struct__: mod, id: id} = user ->
      resolve_customer(user, mod, id, create?)

    user ->
      {:error, {:unsupported_user_shape, user}}
  end
end
```

Source: `accrue_portal/lib/accrue_portal/customer_session.ex:11-24`.

```elixir
query =
  from(customer in Customer,
    where:
      customer.owner_type == ^billable_type and customer.owner_id == ^owner_id and
        customer.processor == ^Processor.name(),
    limit: 1
  )
```

Source: `accrue_portal/lib/accrue_portal/customer_session.ex:34-44`. `Customer` declares `owner_type`, `owner_id`, and `processor` separately at `accrue/lib/accrue/billing/customer.ex:47-53`.

**Transport pattern:** Plug and LiveView independently call the resolver today. Plug reads session via `get_session/1`, assigns actor/customer/session, and redirects on failure (`auth_plug.ex:21-55`). LiveView's `on_mount` re-resolves and assigns session plus presentation/asset metadata (`auth_hook.ex:9-42`). Router exposes four POST endpoints under the HTTP auth pipeline and seven LiveViews under a distinct LiveView session (`router.ex:48-110`). Put common context semantics at the shared boundary; do not rely on a host `on_mount` assign override because the default hook follows it and resolves again. Do not assume Plug.Conn exists in LiveView events.

Existing session forwarding copies only explicitly requested `session_keys` into LiveView session and adds a fixed `"accrue_portal"` metadata map (`router.ex:115-143`). Reuse the explicit-key/session pattern for a minimal selection reference only. Do not serialize membership/user structs or permission results as authority.

### Authorization, exact Customer identity, and mutations

**Targets:** `authorize.ex`, `billing_read_model.ex`, both Portal controllers, protected LiveView events, and tests.

**Analog:** `accrue_portal/lib/accrue_portal/authorize.ex` and `billing_read_model.ex` (tracked).

`Authorize.subscription/2` derives the `Customer` from the authenticated socket and delegates the target lookup to `BillingReadModel` (`authorize.ex:8-20`). Preserve this two-stage boundary: authorize host action/context, then retain existing Customer-scoped target lookup and provider capability checks.

The payment-method controller's current action shape is: obtain the request's assigned Customer, look up a server-owned method by ID within that Customer, then mutate and return truthful result messaging (`payment_method_controller.ex:32-52`, `54-73`). The three payment-method POSTs are `create`, `set_default`, and `delete`; checkout is the fourth (`router.ex:79-93`). The add-card POST has no existing resource ID, so a target/context pin must be carried explicitly and revalidated.

Checkout's existing positive ownership guard compares the stored checkout Customer ID to the assigned Customer before subscription (`checkout_controller.ex:10-37`). The LiveView has a separate mount comparison against `socket.assigns.current_customer.id` (`checkout_live.ex:19-55`); keep these aligned and bind the checkout's stored Customer/provider rather than retargeting to whichever context is currently selected.

For proposed authorization logic, the host resolves the human actor plus selection into billable and presentation data, then authorizes a named action against a server-loaded target. Those callback names/arity/envelope are **PROPOSED** from research examples, not existing APIs. Check reads before any call that may provision; distinguish allowed-but-unprovisioned from denied/unavailable; never fall back from explicit invalid selection. The no-adapter personal path remains the existing compatibility behavior.

### Local paths, display values, and recovery

**Analog:** `accrue_portal/lib/accrue_portal/auth_plug.ex` (tracked).

The Plug already rejects non-local configured login paths, specifically `//`-prefixed paths (`auth_plug.ex:71-81`), and only stores GET return paths (`:65-69`). Use the same narrow local-path discipline for optional host return/switch destinations. Display names are escaped presentation values and never an authorization key. Preserve the existing generic unavailable behavior in the host's `OrganizationScopeController` (`examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex:9-40`); don't expose whether another billable exists.

### Pinned forms and official payment SDK lifecycle

**Targets:** add-payment-method and checkout LiveViews, Portal JS, corresponding LiveView/POST tests.

**Analogs:** `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex:9-21,39-80`; `checkout_live.ex:19-55,65-120`; `accrue_portal/priv/static/accrue_portal.js:4-89` (tracked).

Add-payment-method obtains a Braintree client token from the currently assigned Customer and renders Hosted Fields plus a hidden nonce and CSRF field (`add_payment_method_live.ex:9-21,39-72`). Checkout pins the stored `LocalSession`, validates Customer equality on mount, and keeps promo/confirmation state in assigns (`checkout_live.ex:19-49`). A context change/revocation must clear that pending state and secure nonce/card acquisition; never auto-replay a denied mutation.

Keep card collection and tokenization at the official Braintree Hosted Fields boundary. The current hook avoids duplicate binding, tokenizes, reports failures, and tears down the provider instance in `destroyed` (`accrue_portal/priv/static/accrue_portal.js:4-17,60-88`). Extend cleanup through this owned hook; do not replace tokenization with custom card inputs. Successful browser callback or query parameters do not establish server payment success.

### Human audit attribution

**Analog:** `accrue/lib/accrue/actor.ex:47-68` and `accrue/lib/accrue/events.ex:158-191` (tracked).

`Actor.with_actor/2` scopes an actor and restores prior process state in `after`. `Events.normalize/1` prefers explicit actor context and otherwise reads `Actor.current/0`; absent actor is labeled `"system"`. Wrap authorized synchronous operations with the real human actor, not the company/billable ID. Do not assume process-dictionary state crosses a LiveView process boundary or async job. Verify the persisted event, since test Auth adapters' `log_audit/2` may be a no-op (`accrue_portal/test/support/fixtures.ex:17-38`).

### Canonical host examples and mixed/personal fixtures

**Analogs:** `examples/accrue_host/lib/accrue_host/accounts/scope.ex:19-45`, `billing.ex:18-43,86-130`, and `organization_scope_controller.ex:9-50` (tracked).

`Scope` keeps `user`, `active_organization`, `membership`, and impersonation origin as distinct values. `AccrueHost.Billing` is the host-owned facade and places authorization/policy before shared Billing operations. The selection controller looks up a live membership, stores active organization identifiers in session, and reports generic unavailability. Use these as an example of host-owned selection/policy, not as Portal requirements: no exported `:owner/:admin` roles or organization schema assumptions. A new host fixture/spec should cover plain personal default, organization/custom billable, and mixed actor with separately authorized accounts.

Existing browser switching spec reseeds fixtures and checks visible organization labels before/after selection (`examples/accrue_host/e2e/verify01-org-switching.spec.js:1-25`). Reuse `readFixture`, `reseedFixture`, `login`, and `waitForLiveView` from its support fixture; add assertions for the Portal billed identity and pinned-flow behavior in a new/proposed spec rather than claiming this Admin/account-switch test already covers Portal.

### Visual semantic roles and package-owned assets

**Analogs:**

- `accrue_admin/assets/css/theme.css:1-15,25-40,52-68,82-105` (tracked): Admin-scoped `html.accrue-admin` `--ax-*` tokens, typography, spacing, radius, motion.
- `accrue/priv/static/brand.css:1-15,23-54,56-99` (tracked): stable public `--accrue-*` tokens and host-brand bridge/theme behavior.
- `accrue_portal/priv/static/accrue_portal.css:1-12,24-65` (tracked): buildless Portal styles consuming public tokens, with package-owned `.portal-*` selectors.

Align semantic meaning and acceptance criteria while retaining distinct token namespaces, asset delivery, brand identity, shells, and audience density. The Portal CSS states it is committed hand-written CSS with no Tailwind/build step. Admin's asset build cannot prove Portal CSS was rebuilt/served. Treat new `DESIGN.md` and current source/route/state inventory paths as **PROPOSED artifacts**; cite source and asset provenance and keep saved screenshots explicitly historical. The Admin CSS census and visual specs are evidence-workflow analogs, not proof of a current served Portal render.

## Test and Fixture Patterns

**Portal ExUnit fixtures:** `accrue_portal/test/support/fixtures.ex:8-38,40-98` defines a test billable/auth adapter and builds current plus foreign Customer/resource bundles. `payment_methods_wrong_tenant_test.exs:9-41` sets the adapter with cleanup in `on_exit`, performs a foreign target POST, asserts 404, and verifies the foreign record remains. Copy the positive control as well as denial cases for new security checks; add assertions that denial did not provision or mutate and that actor attribution is the human.

**Current commands from checked-in configuration:**

- Portal quick focused command documented by research: `cd accrue_portal && mix test test/accrue_portal/auth_hook_test.exs test/accrue_portal/router_test.exs`.
- Portal full command documented by research: `cd accrue_portal && mix test --warnings-as-errors`.
- Portal `mix.exs` also defines `mix test.ci`, which runs format check, warnings-as-errors compile/test, and `mix hex.audit` (`accrue_portal/mix.exs:24-36`).
- Host Playwright package scripts include `cd examples/accrue_host && npm run e2e` and visual recipes in `examples/accrue_host/package.json:7-15`.
- Admin Playwright scripts include `cd accrue_admin && npm run e2e:visuals:png-only` and `npm run e2e:a11y` in `accrue_admin/package.json:5-18`; use only for Admin consumer evidence.

No tests, builds, app boot, or browser capture were run for this mapping.

## Shared Patterns

### Shared context boundary

**Apply to:** Portal HTTP AuthPlug, LiveView AuthHook, reconnect/events, navigation and all four POSTs.  
**Source:** `customer_session.ex:11-49`, `auth_plug.ex:21-55`, `auth_hook.ex:9-42`, `router.ex:77-110`.

Keep transport extraction separate from one shared resolver/authorizer. Reauthorize at the action edge against the same pinned billable/Customer/processor/target that the page named. Rendered permission is display-only.

### Resource and processor boundary

**Apply to:** Portal customer lookup and all billing reads/writes.  
**Source:** `customer_session.ex:34-49`, `authorize.ex:8-20`, `checkout_controller.ex:10-37`, `Customer` schema `customer.ex:47-53`.

Keep owner type + owner ID + configured processor together, then enforce Customer-scoped target ownership and provider capability.

### Recovery and navigation

**Apply to:** denied/unavailable context and host switch/return links.  
**Source:** `auth_plug.ex:57-81`, `organization_scope_controller.ex:23-40`.

Unauthenticated and authenticated-but-unavailable are distinct states; use generic copy for unavailable context, validate local targets, and avoid login/recovery loops.

### Visual ownership

**Apply to:** Admin and Portal semantic roles.  
**Source:** Admin `theme.css`, core `brand.css`, Portal `accrue_portal.css` above.

Share role intent; preserve `--ax-*` vs `--accrue-*` and source/asset ownership.

## No Analog Found

No close analogue exists for a shared Portal billable-context adapter spanning HTTP, LiveView reconnect/events, four POST endpoints, and per-form pinning. Implement the new adapter as a proposed contract layered into existing transport/resolution seams; do not copy an `on_mount`-only approach. No current Portal served-render evidence artifact was found as a same-role analog; use existing Admin census/Playwright evidence procedures and record fresh Portal source/asset provenance.

## Metadata

**Analog search scope:** `accrue_portal/lib`, `accrue_portal/test`, `accrue_portal/priv/static`, `accrue/lib/accrue/{billing,events}`, `accrue/priv/static`, `accrue_admin/assets/css`, `accrue_admin/e2e`, `examples/accrue_host/lib`, `examples/accrue_host/e2e`.  
**Tracked-source gate:** named source analogs were checked with `git ls-files -- <path>` and are tracked.  
**Pattern extraction date:** 2026-10-07
