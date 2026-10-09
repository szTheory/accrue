# Phase 235: Customer Plan Selection & Checkout - Pattern Map

**Mapped:** 2026-10-08  
**Files analyzed:** 12 likely changed files, based on CONTEXT.md canonical refs and RESEARCH.md recommended structure/validation gaps  
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | component/controller (LiveView) | request-response | same file, `start_subscription` handler (lines 36-71) | exact |
| `examples/accrue_host/lib/accrue_host/billing/plans.ex` | service/config | transform | same file, `all/0` and `get/1` (lines 12-65) | exact |
| `examples/accrue_host/lib/accrue_host/billing/plan_resolver.ex` | service | request-response | same file, `resolve_price/1` (lines 10-27) | exact |
| `accrue/lib/accrue/checkout/local_session.ex` | model/service | CRUD | same file, schema/create/read/update (lines 20-115) | exact |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | component/controller (LiveView) | request-response | same file, mount, promo events, authorization (lines 23-80, 182-245, 448-506) | exact |
| `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` | controller | request-response | same file, `complete/2` (lines 12-75) | exact |
| `accrue_portal/priv/static/accrue_portal.js` | utility/browser hook | event-driven | same file, `BraintreeHostedFields` (lines 4-173) | exact |
| `accrue_portal/priv/static/accrue_portal.css` | config/style | transform | same file, hosted field and responsive styles (lines 456-551) | exact |
| `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` | test | request-response | same file (setup and rendered checkout tests) | exact |
| `accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs` | test | request-response | same file (promotion event tests) | exact |
| `accrue_portal/test/accrue_portal/checkout_context_test.exs` | test | request-response | same file (host adapter and authorization fixtures) | exact |
| `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js` | test | event-driven | same file (browser SDK probe and visible checkout assertions) | exact |

All named analogs were verified as git-tracked using `git ls-files`. These are probable modifications, not a committed task file list; keep discovery/selection host-owned, and do not add a generic catalog endpoint.

## Pattern Assignments

### Host selection and plan metadata

**Files:** `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`, `billing/plans.ex`, `billing/plan_resolver.ex`  
**Analogs:** [subscription_live.ex] lines 36-71 and 148-167; [plans.ex] lines 6-27, 63-65; [plan_resolver.ex] lines 10-25.

The existing host LiveView handles an event, delegates to the host Billing boundary, and maps tagged errors to user-facing state. Plan facts come from `Plans` maps (`label`, `unit_amount_minor`, `currency`, `billing_cycle`), while `PlanResolver.resolve_price/1` returns `{:ok, facts}` or `{:error, :unknown_price_id}`. Preserve that host-owned lookup and pass facts for the exact selected `price_id` into the existing checkout-session creation path. Do not display the raw ID as the name or treat Fake-backed browser evidence as processor parity.

```elixir
def all do
  [
    %{
      key: :basic,
      id: @ids.basic,
      label: @labels.basic,
      unit_amount_minor: @amounts.basic,
      currency: "USD",
      billing_cycle: %{unit: :month, count: 1}
    }
  ]
end

def resolve_price(price_id) when is_binary(price_id) do
  case Plans.get(price_id) do
    nil -> {:error, :unknown_price_id}
    plan -> {:ok, %{price_id: plan.id, processor: processor_name(),
      processor_plan_id: plan.id, unit_amount_minor: plan.unit_amount_minor,
      currency: plan.currency, billing_cycle: plan.billing_cycle}}
  end
end
```

### Persisted checkout session

**File:** `accrue/lib/accrue/checkout/local_session.ex`  
**Analog:** same file, lines 20-63 and 65-115.

Use the current Ecto schema and changeset shape. `metadata` and `data` are persisted maps; `create_or_reuse/2` scopes reuse by customer and operation ID, while `by_token/1` reloads server-side state. Add selected display terms to the existing session attrs, preserving existing required fields and constraints.

```elixir
field(:price_id, :string)
field(:line_items, {:array, :map}, default: [])
field(:metadata, :map, default: %{})
field(:data, :map, default: %{})

def by_token(token) when is_binary(token) do
  Repo.get_by(__MODULE__, session_token: token)
end
```

### Mounted checkout render, validation, and action

**File:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`  
**Analog:** same file, mount lines 23-80; promo event lines 182-245; reload/authorize helpers lines 448-506.

Imports/aliases use explicit `alias` groups for core Billing, session, Portal context, and Portal helpers. Mount loads by session token, resolves the pinned context, checks target identity and authorization, then assigns render state. Event actions use `authorized_checkout/3`, which reloads the session and re-resolves/authorizes before mutation. Keep promotion validation and checkout completion tied to the same exact session; fail closed when trusted price terms are incomplete or inconsistent.

```elixir
checkout = LocalSession.by_token(token)

with %LocalSession{} = checkout <- checkout,
     {:ok, _pin, context} <- resolve_checkout_context(socket, pin, false),
     true <- checkout_action_target?(context, checkout),
     true <- checkout_ready?(checkout),
     :ok <- Context.authorize_action(context, socket.assigns[:current_context_adapter],
       action, checkout) do
  {:ok, checkout, context}
else
  _ -> {:error, :unavailable}
end
```

### POST completion and safe returns

**File:** `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex`  
**Analog:** same file, lines 12-75 and 123-150.

The POST handler requires token, context pin, and nonce, then resolves the pin, reloads the session, verifies target/readiness, and freshly authorizes `:checkout_complete`. The provider call is wrapped with actor context and operation ID. `success_destination/2` accepts validated local paths or HTTPS URLs without userinfo and falls back to the Portal home. Keep output status tied to authoritative results; the existing catch-all `deny/2` copy currently implies no payment was submitted, so it is not a suitable pattern for ambiguous provider outcomes.

```elixir
with {:ok, context} <- resolve_pinned_context(conn, pin),
     %LocalSession{} = checkout <- LocalSession.by_token(token),
     true <- checkout_target?(context, checkout),
     true <- checkout_ready?(checkout),
     :ok <- Context.authorize_action(context, conn.assigns[:current_context_adapter],
       :checkout_complete, checkout) do
  subscribe(conn, context, checkout, nonce)
else
  _ -> deny(conn, token)
end
```

### Hosted Fields browser hook

**File:** `accrue_portal/priv/static/accrue_portal.js`  
**Analog:** same file, lines 4-173.

The hook initializes the official SDK in `mounted`, prevents duplicate work, tokenizes on form submit, sends only the nonce through native POST or `pushEvent`, and tears down fields and nonce state in `destroyed`. Follow the existing submit state machine. On failure, clear nonce, restore the button, and surface accessible status; uncertain server outcomes must not automatically trigger a second submit.

```javascript
this.hostedFields.tokenize(function (tokenizeErr, payload) {
  if (tokenizeErr) {
    this.tokenizing = false;
    setSubmitting(submitButton, false);
    if (nonceInput) nonceInput.value = "";
    this.pushEvent("checkout_failed", {
      message: tokenizeErr.message || "Unable to tokenize card."
    });
    return;
  }
  nonceInput.value = payload.nonce;
  this.submissionSent = true;
  this.el.submit();
}.bind(this));
```

### Checkout test coverage

**Files:** `checkout_live_test.exs`, `checkout_live_discount_test.exs`, `checkout_context_test.exs`  
**Analogs:** the respective current modules.

Use `AccruePortal.ConnCase`, database fixtures, Braintree Mox/client token stub, and a subscription gateway stub for deterministic server behavior. Checkout tests already test LiveView-rendered markup and session state. Discount tests own promo mapping/event behavior. Context tests define a host adapter with grant/revoke state and assert authorization at the boundary. Add assertions at the owning seam for valid/missing offer terms, stale/expired/completed sessions, provider result classification, retry reset, and both POST and LiveView transport parity.

### Browser checkout proof

**File:** `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`  
**Analog:** same file, lines 5-49 (SDK shim + visible checkout) and 51-75 (host authorization denial).

Use `support/test.js` fixtures and `support/fixture.js` login/LiveView readiness helpers. Its injected Braintree shim currently proves initialization only. Extend the shim with deterministic `tokenize`, click the actual visible submit, and assert actual request/event and resulting visible/server outcome; label it mocked SDK path evidence. Retain a separate denied-context case proving no Hosted Fields or form appears.

### CSS and delivered assets

**File:** `accrue_portal/priv/static/accrue_portal.css`  
**Analog:** same file, lines 456-504 and 529-551; served asset integration in `accrue_portal/lib/accrue_portal/assets.ex` lines 8-27.

Use existing `.portal-hosted-*`, `.portal-inline-error`, and `.portal-checkout-actions` roles with `--accrue-*` tokens; preserve the single-column narrow layout. The Assets module reads these package-owned static files at compile time, so browser evidence must exercise the Portal-served bundle.

## Shared Patterns

### Trust and authorization

**Sources:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex` lines 448-506; `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` lines 12-43.  
**Apply to:** every checkout completion, validation, and return-sensitive action.

The pin locates context; it does not grant authorization. Reload persisted `LocalSession`, match Customer, owner/billable, configured processor, selected offer, open state, and expiry, then call `Context.authorize_action` for the requested action immediately before mutation.

### Payment result evidence

**Sources:** checkout controller lines 45-75; LiveView lines 124-141; context decisions D-04 through D-07.  
**Apply to:** POST, LiveView, and provider return states.

Only a confirmed server/provider result can show completion. Keep invalid input, stale promo, expiry, cancellation, rejection, and uncertainty distinct. Never replay an uncertain payment or reuse a single-use nonce; offer retry only after authoritative state allows a fresh action.

### Host-selected offer

**Sources:** `examples/accrue_host/lib/accrue_host/billing/plans.ex` lines 12-65 and `accrue/lib/accrue/checkout/local_session.ex` lines 20-36.  
**Apply to:** host selection/session creation and Portal offer rendering.

Use trusted host catalog facts persisted with the selected session. Missing/ambiguous material price terms must stay unavailable and disable payment; a valid zero-price plan must remain distinguishable from missing metadata.

## No Analog Found

None for the candidate files above. Exact checkout analogs exist. The precise plan selection → unauthenticated sign-in → safe return session creation seam still needs planner inspection; if it is in another host module, use the existing `SubscriptionLive.start_subscription` error/delegation pattern and preserve the selected plan through the actual current sign-in path.

## Metadata

**Analog search scope:** Portal checkout LiveView/controller/session/assets/tests; host billing plan definitions and subscription LiveView; Braintree browser spec.  
**Files scanned:** 12 target analogs plus Portal asset-serving integration.  
**Pattern extraction date:** 2026-10-08
