# Building a Local Billing Portal for Braintree

`accrue_portal` is the batteries-included mounted portal package for
Braintree local checkout and self-serve billing flows. This guide is
the SSOT for that packaged path. For lifecycle meaning, action
vocabulary, and provider labels, use
[Lifecycle Semantics](lifecycle_semantics.md) as the canonical glossary.

For the default mounted path:

- mount `accrue_admin "/admin"` and `accrue_portal "/billing"` as sibling scopes
- set `:portal_mount_path` to `"/billing"`
- set `:portal_base_url` to an absolute host URL so returned checkout and
  billing-portal URLs stay absolute
- configure `:plan_resolver` if your local portal or admin UI will expose
  first-party `swap_plan/3` for Braintree subscriptions
- keep auth/session continuity across the browser pipeline and LiveView mounts
- load the Hosted Fields scripts and keep CSP aligned with that checkout surface

If any of those are incomplete, Braintree does not fall back to an upstream
hosted billing portal. The failure is local and typed: wrong `portal_mount_path`
or `portal_base_url` breaks URL generation, broken auth/session continuity
prevents customer resolution, missing Hosted Fields / CSP readiness breaks
checkout, and discount preview remains provisional until final submit.

Unlike Stripe, Braintree does not offer a pre-built, hosted customer billing
portal for self-serve subscription management. Accrue now closes that gap with
first-party local portal semantics while still exposing the core primitives for
hand-rolled flows.

## When to stay packaged vs go hand-rolled

The packaged `accrue_portal` mount is the default story. It is the shortest path
to a supported local checkout and billing portal because it already aligns the
router contract, local URL return shape, auth expectations, and Hosted Fields
checkout flow.

The hand-rolled path is the escape hatch. Use it when you want total UX control,
or when you need behaviors outside the packaged boundary such as emailed-link
checkout bootstraps. In that case, build your own `/checkout/start?token=...`
controller in the host app, resolve the token to a signed-in session, and then
redirect into the mounted portal or your custom UI. The core processor truth
does not change: Braintree checkout and billing portal URLs are still mounted
local URLs, not upstream hosted sessions.

## Local Promotion-Code Mappings

Stripe promotions are created upstream and projected locally. Braintree is
different: the customer-facing code is local to Accrue and resolves to a
Control Panel discount id at checkout submit time.

Use `Accrue.Billing.upsert_discount_mapping/2` to create or update that local
mapping:

```elixir
{:ok, _mapping} =
  Accrue.Billing.upsert_discount_mapping("SPRING25", %{
    discount_id: "bt_discount_25",
    amount_off_minor: 2_500,
    currency: "USD",
    active: true,
    max_redemptions: 100
  })
```

The mounted portal and any hand-rolled checkout should use the same core
resolver. Preview the code before payment submit, show the estimated savings
and total, then rely on `Accrue.Billing.subscribe/3` to revalidate the code
authoritatively on the final submit. The portal copy calls this out as
preview-before-submit so customers do not confuse a local preview with a final
processor confirmation.

That means discount preview is a setup-contract truth, not just UX copy:
successful preview proves only that the local mapping resolved. The
authoritative checkout result is the final mounted submit, which persists local
completion after the processor confirms the payment method and subscription
work.

### Drift and Operator Remediation

If a code is locally valid but points at a missing or invalid Braintree
discount id, Accrue returns `%Accrue.Error.DiscountMappingInvalid{}` and the
portal shows safe customer copy such as "This promotion is temporarily
unavailable." No subscription is created at the undiscounted amount.

Operator remediation is:

1. Inspect the local mapping row for the entered code.
2. Compare `discount_id` against the Braintree Control Panel discount.
3. Repair the mapping with `upsert_discount_mapping/2`.
4. Retry checkout after the mapping is valid again.

If you need alerting, subscribe to the `[:accrue, :ops, :discount_mapping_invalid]`
telemetry event that Plan 02 added for this drift condition.

## Why Accrue Remains Headless

We explicitly decided not to ship a drop-in local portal UI within Accrue for several reasons:

1. **CSS Framework Lock-in:** Any UI we provide would either look entirely out of place in your app or force you into a specific CSS framework (e.g., Tailwind, Bootstrap).
2. **Routing Complexities:** Injecting routes and managing authentication/authorization bounds within host applications creates unnecessary friction.
3. **Security Surface Expansion:** A built-in portal would increase the security surface area of the library. It's safer and more flexible for your application to govern how users access and mutate their billing state.
4. **Customization:** Subscription management UX is highly domain-specific. You might want to upsell features during a plan swap, request feedback on cancellation, or display custom usage metrics—all of which are difficult with rigid, pre-packaged UIs.

## Achieving Parity with Accrue Primitives

You can quickly assemble a cohesive self-serve local portal using Phoenix LiveView and Accrue's core billing functions. Below are snippets demonstrating how to implement the necessary features.

### 1. Listing and Swapping Plans

To allow a customer to view their active subscription and swap plans:

First, configure a host-owned resolver that can translate your app-facing
`price_id` into the Braintree plan metadata Accrue needs:

```elixir
config :accrue, :plan_resolver, MyApp.Billing.PlanResolver
```

The resolver should return `price_id`, `processor`, `processor_plan_id`,
`unit_amount_minor`, `currency`, and normalized `billing_cycle` metadata for
each swappable plan.

```elixir
defmodule MyAppWeb.BillingPortalLive do
  use MyAppWeb, :live_view
  
  alias Accrue.Billing

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    
    # Lazily fetch or create the customer record
    {:ok, customer} = Billing.customer(user)
    
    # Fetch active subscriptions
    subscriptions = Accrue.Billing.SubscriptionQueries.list_active_for(customer)
    
    {:ok, assign(socket, customer: customer, subscriptions: subscriptions)}
  end
  
  def handle_event("swap_plan", %{"subscription_id" => sub_id, "new_price_id" => price_id}, socket) do
    subscription = Accrue.Billing.get_subscription!(sub_id)
    
    case Billing.swap_plan(subscription, price_id, proration: :create_prorations) do
      {:ok, _updated_sub} ->
        {:noreply,
         socket
         |> put_flash(:info, "Plan updated successfully.")
         |> push_navigate(to: ~p"/billing")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to update plan.")}
    end
  end
end
```

### 2. Managing Payment Methods

Customers need to add, set default, and remove payment methods. For Braintree, you'll first acquire a nonce using Hosted Fields (Drop-in for Web is deprecated 2025-07-14 and unsupported 2026-07-14 — use Hosted Fields for new integrations), then send it to your LiveView.

```elixir
  # Adding a payment method using a vault acquisition reference (nonce)
  def handle_event("add_payment_method", %{"nonce" => nonce}, socket) do
    customer = socket.assigns.customer
    attrs = %{vault_acquisition: %{reference: nonce}}
    
    case Billing.add_payment_method(customer, attrs) do
      {:ok, payment_method} ->
        # Optionally set as default immediately
        Billing.set_default_payment_method!(customer, payment_method.id)
        
        {:noreply,
         socket
         |> put_flash(:info, "Payment method added.")
         |> assign(payment_methods: Billing.list_payment_methods!(customer))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not add payment method.")}
    end
  end

  # Deleting a payment method
  def handle_event("delete_payment_method", %{"id" => pm_id}, socket) do
    customer = socket.assigns.customer
    payment_method = Enum.find(Billing.list_payment_methods!(customer), &(&1.id == pm_id))
    
    case Billing.delete_payment_method(payment_method) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Payment method removed.")
         |> assign(payment_methods: Billing.list_payment_methods!(customer))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not remove payment method.")}
    end
  end
```

### 3. Canceling Subscriptions

Default self-serve posture should still match
[Lifecycle Semantics](lifecycle_semantics.md): `cancel_at_period_end/2` means
"turn off renewal now and keep access through the paid-through date." The
important Braintree-specific caveat is that this softer non-renewal behavior is
not a first-party processor capability in Accrue's generic facade. If your
product wants an end-of-term Braintree policy, keep that logic in a host-owned
seam above Accrue instead of implying generic parity.

The supported first-party Braintree cancellation path is immediate
`Accrue.Billing.cancel/2`:

```elixir
  def handle_event("cancel_subscription_now", %{"id" => sub_id}, socket) do
    subscription = Accrue.Billing.get_subscription!(sub_id)

    case Billing.cancel(subscription) do
      {:ok, _updated_sub} ->
        {:noreply,
         put_flash(socket, :info, "Subscription canceled now. Review entitlement effects before exposing this flow.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel the subscription now.")}
    end
  end
```

If you want a softer "cancel renewal" product experience for Braintree, model
that as a local host contract. Typical patterns are:

1. mark the subscription for end-of-term handling in your own app state
2. explain that renewal is turning off locally while service continues through
   the paid-through date
3. execute the final hard stop through `Accrue.Billing.cancel/2` when your
   host-owned policy says the term is over

That keeps the mounted portal honest: immediate cancellation is the supported
Accrue path, while end-of-term non-renewal remains a host-owned policy seam for
Braintree.

By connecting these primitives in your LiveViews, you retain absolute control over the UX, styling, and business rules, while relying on Accrue to maintain consistency with the underlying Braintree gateway.
