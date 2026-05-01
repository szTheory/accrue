# Building a Local Billing Portal for Braintree

Unlike Stripe, Braintree does not offer a pre-built, hosted customer billing portal for self-serve subscription management. Consequently, when Accrue is configured to use the Braintree processor, calling `Accrue.Billing.create_billing_portal_session/2` will safely intercept the request and return an `{:error, %Accrue.APIError{code: :unsupported_by_gateway}}` response.

Instead of shipping an opinionated, built-in UI for this missing functionality, Accrue remains a headless backend facade. This guide explains why this architectural decision was made and demonstrates how to build a robust local portal yourself using Accrue's primitives.

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
    
    case Billing.swap_plan(subscription, price_id, []) do
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

Offer immediate cancellations using Accrue's cancel functions:

```elixir
  def handle_event("cancel_subscription", %{"id" => sub_id}, socket) do
    subscription = Accrue.Billing.get_subscription!(sub_id)
    
    # Braintree supports immediate cancellation
    case Billing.cancel(subscription) do
      {:ok, _canceled_sub} ->
        {:noreply, put_flash(socket, :info, "Subscription canceled.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel subscription.")}
    end
  end
```

By connecting these primitives in your LiveViews, you retain absolute control over the UX, styling, and business rules, while relying on Accrue to maintain consistency with the underlying Braintree gateway.
