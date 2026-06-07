defmodule AccrueHostWeb.SubscriptionLive do
  use AccrueHostWeb, :live_view

  import Ecto.Query
  import Phoenix.Controller, only: [get_csrf_token: 0]

  alias Accrue.APIError
  alias Accrue.Billing.Subscription
  alias AccrueHost.Accounts.{Organization, OrganizationMembership}
  alias AccrueHost.Billing
  alias AccrueHost.Billing.Plans
  alias AccrueHost.Repo

  @active_organization_label "Active workspace"
  @active_organization_helper "Plan changes and payment actions apply to this workspace only."
  @empty_state_heading "No workspace subscription yet"
  @empty_state_body "Choose a plan to start billing for this cohort workspace. Subscription and invoice records will appear here after checkout or webhook updates."
  @error_copy "We couldn't complete that billing action for the active workspace. Check access, billing setup, or payment state, then try again."
  @cancel_copy "Cancel now for this workspace only. Access can end immediately."
  @cancel_heading "Need to stop access?"
  @cancel_body "Use immediate cancellation when the workspace should stop billing and access right away."
  @cancel_cta "Cancel workspace subscription"
  @cancel_keep_cta "Keep subscription"
  @tax_location_repair_copy "Please update customer address or shipping before enabling automatic tax."
  @tax_location_success_copy "Tax location saved. Choose a plan again when you're ready."
  @member_denial_copy "Billing is managed by workspace admins. You can review the current billing state, but you can't change it."
  @no_active_organization_copy "Select an active workspace before managing billing."
  @start_subscription_copy "Choose plan"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Workspace billing")
     |> assign(:confirm_cancel, false)
     |> load_state()}
  end

  @impl true
  def handle_event("start_subscription", %{"plan" => plan_id} = params, socket) do
    case Billing.subscribe_active_organization(socket.assigns.current_scope, plan_id,
           automatic_tax: true,
           operation_id: operation_id(params, "subscribe")
         ) do
      {:ok, _subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Subscription started.")
         |> assign(:confirm_cancel, false)
         |> assign(:tax_location_error, nil)
         |> load_state()}

      {:error, %APIError{code: "customer_tax_location_invalid"}} ->
        {:noreply,
         socket
         |> assign(:tax_location_error, @tax_location_repair_copy)
         |> put_flash(:error, @tax_location_repair_copy)}

      {:error, :no_active_organization} ->
        {:noreply, put_flash(socket, :error, @no_active_organization_copy)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, @member_denial_copy)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, @error_copy)}
    end
  end

  def handle_event(
        "vault_acquisition_success",
        %{"payment_method_token" => vault_reference, "plan_id" => plan_id} = params,
        socket
      ) do
    case Billing.subscribe_with_vault_reference(
           socket.assigns.current_scope,
           plan_id,
           vault_reference,
           automatic_tax: true,
           operation_id: operation_id(params, "subscribe")
         ) do
      {:ok, _subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Subscription started.")
         |> assign(:confirm_cancel, false)
         |> assign(:tax_location_error, nil)
         |> load_state()}

      {:error, %APIError{code: "customer_tax_location_invalid"}} ->
        {:noreply,
         socket
         |> assign(:tax_location_error, @tax_location_repair_copy)
         |> put_flash(:error, @tax_location_repair_copy)}

      {:error, :no_active_organization} ->
        {:noreply, put_flash(socket, :error, @no_active_organization_copy)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, @member_denial_copy)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, @error_copy)}
    end
  end

  def handle_event("update_tax_location", %{"tax_location" => params}, socket) do
    case Billing.update_active_organization_tax_location(
           socket.assigns.current_scope,
           tax_location_attrs(params)
         ) do
      {:ok, _customer} ->
        {:noreply,
         socket
         |> put_flash(:info, @tax_location_success_copy)
         |> assign(:tax_location_error, nil)
         |> assign(:tax_location_form, tax_location_defaults(params))
         |> load_state()}

      {:error, %APIError{code: "customer_tax_location_invalid"}} ->
        {:noreply,
         socket
         |> assign(:tax_location_error, @tax_location_repair_copy)
         |> assign(:tax_location_form, tax_location_defaults(params))
         |> put_flash(:error, @tax_location_repair_copy)}

      {:error, :no_active_organization} ->
        {:noreply,
         socket
         |> assign(:tax_location_form, tax_location_defaults(params))
         |> put_flash(:error, @no_active_organization_copy)}

      {:error, :forbidden} ->
        {:noreply,
         socket
         |> assign(:tax_location_form, tax_location_defaults(params))
         |> put_flash(:error, @member_denial_copy)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:tax_location_form, tax_location_defaults(params))
         |> put_flash(:error, @error_copy)}
    end
  end

  def handle_event("request_cancel", _params, socket) do
    if billing_locked?(socket.assigns.access_state) do
      {:noreply, put_flash(socket, :error, access_message(socket.assigns.access_state))}
    else
      {:noreply, assign(socket, :confirm_cancel, true)}
    end
  end

  def handle_event("dismiss_cancel", _params, socket) do
    {:noreply, assign(socket, :confirm_cancel, false)}
  end

  def handle_event("confirm_cancel", params, socket) do
    case socket.assigns.subscription do
      %Subscription{} = subscription ->
        case Billing.cancel_active_organization(
               socket.assigns.current_scope,
               subscription,
               operation_id: operation_id(params, "cancel")
             ) do
          {:ok, _updated_subscription} ->
            {:noreply,
             socket
             |> put_flash(
               :info,
               "Subscription canceled now. Workspace access may end immediately."
             )
             |> assign(:confirm_cancel, false)
             |> load_state()}

          {:error, :no_active_organization} ->
            {:noreply, put_flash(socket, :error, @no_active_organization_copy)}

          {:error, :forbidden} ->
            {:noreply, put_flash(socket, :error, @member_denial_copy)}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, @error_copy)}
        end

      nil ->
        {:noreply, put_flash(socket, :error, @error_copy)}
    end
  end

  def handle_event("simulate_api_call", _params, socket) do
    # Meter events use value:; quantity: belongs to subscription/invoice line items.
    case Billing.report_usage_for_scope(socket.assigns.current_scope, "api_calls", value: 1) do
      {:ok, _event} ->
        {:noreply, put_flash(socket, :info, "Learner activity recorded for this period.")}

      {:error, :no_active_organization} ->
        {:noreply, put_flash(socket, :error, @no_active_organization_copy)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, @member_denial_copy)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, @error_copy)}
    end
  end

  def handle_event("create_checkout_session", _params, socket) do
    attrs = %{
      success_url: url(~p"/app/billing?checkout=success"),
      cancel_url: url(~p"/app/billing?checkout=cancel"),
      line_items: [%{price: Plans.ids().pro, quantity: 1}]
    }

    case Billing.create_checkout_session_for_scope(socket.assigns.current_scope, attrs) do
      {:ok, session} ->
        {:noreply, assign(socket, :checkout_url, session.url)}

      {:error, :no_active_organization} ->
        {:noreply, put_flash(socket, :error, @no_active_organization_copy)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, @member_denial_copy)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, @error_copy)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto flex max-w-5xl flex-col gap-6">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p class="text-sm font-semibold text-primary">
              {AccrueHost.DemoBrand.product_name()} billing
            </p>
            <h1 class="mt-2 text-3xl font-semibold">Workspace billing</h1>
            <p class="mt-2 max-w-3xl text-base leading-7 text-base-content/70">
              Review the active cohort workspace, subscription status, usage, and payment recovery path.
            </p>
          </div>
          <.link navigate={~p"/"} class="btn btn-ghost btn-sm self-start rounded-lg sm:self-auto">
            Back home
          </.link>
        </div>

        <section class="flex flex-col gap-4 rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
          <div>
            <p class="text-sm font-semibold text-base-content/60">{@active_organization_label}</p>
            <h2 class="mt-1 text-2xl font-semibold">{active_organization_name(@current_scope)}</h2>
            <p class="mt-1 text-base leading-7 text-base-content/65">
              {@active_organization_helper}
            </p>
          </div>

          <div
            :if={@switchable_organizations != []}
            class="flex flex-wrap items-center gap-2"
            data-testid="organization-switcher"
          >
            <p class="text-sm font-semibold text-base-content/60">Switch organization</p>
            <%= for org <- @switchable_organizations do %>
              <form action={~p"/app/organization-scope"} method="post" class="inline">
                <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                <input type="hidden" name="organization_slug" value={org.slug} />
                <button
                  type="submit"
                  class="btn btn-outline btn-sm rounded-lg"
                  data-organization-slug={org.slug}
                >
                  {org.name}
                </button>
              </form>
            <% end %>
          </div>

          <p :if={@access_message} class="text-sm font-semibold text-warning">
            {@access_message}
          </p>
        </section>

        <%= if @subscription do %>
          <section class="flex flex-col gap-4 rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
            <div>
              <h2 class="text-2xl font-semibold">Current subscription</h2>
              <p class="mt-1 text-base leading-7 text-base-content/65">
                This workspace is subscribed and can keep cohort access active.
              </p>
            </div>

            <dl class="grid gap-4 sm:grid-cols-3">
              <div>
                <dt class="text-sm font-semibold text-base-content/60">Plan</dt>
                <dd class="mt-1 text-base">{@subscription_plan_label}</dd>
              </div>
              <div>
                <dt class="text-sm font-semibold text-base-content/60">Status</dt>
                <dd class="mt-1 text-base">{humanize_status(@subscription.status)}</dd>
              </div>
              <div>
                <dt class="text-sm font-semibold text-base-content/60">Billing reference</dt>
                <dd class="mt-1 break-all text-base">{@customer.id}</dd>
              </div>
            </dl>

            <div :if={!Subscription.canceled?(@subscription)} class="border-t border-base-300 pt-4">
              <h3 class="text-xl font-semibold">{@cancel_heading}</h3>
              <p class="mt-1 text-base leading-7 text-base-content/65">{@cancel_body}</p>

              <%= if @confirm_cancel do %>
                <p class="mt-4 text-sm font-semibold text-warning">{@cancel_copy}</p>
                <div class="mt-4 flex flex-wrap gap-2">
                  <button
                    type="button"
                    phx-click="confirm_cancel"
                    phx-value-operation_id={@cancel_operation_id}
                    class="btn btn-error rounded-lg"
                    disabled={@billing_locked?}
                  >
                    Confirm cancellation
                  </button>
                  <button
                    type="button"
                    phx-click="dismiss_cancel"
                    class="btn btn-outline rounded-lg"
                    disabled={@billing_locked?}
                  >
                    {@cancel_keep_cta}
                  </button>
                </div>
              <% else %>
                <button
                  type="button"
                  phx-click="request_cancel"
                  class="btn btn-outline mt-4 w-full rounded-lg"
                  disabled={@billing_locked?}
                >
                  {@cancel_cta}
                </button>
              <% end %>
            </div>
          </section>

          <section
            class="flex flex-col gap-4 rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
            data-role="metered-usage-demo"
          >
            <div>
              <h2 class="text-2xl font-semibold">Usage this period</h2>
              <p class="mt-1 text-base leading-7 text-base-content/65">
                Record learner activity for usage-based capacity on larger cohort programs.
              </p>
            </div>
            <div class="flex flex-wrap gap-2">
              <button
                type="button"
                phx-click="simulate_api_call"
                class="btn btn-outline rounded-lg"
                disabled={@billing_locked? || !@subscription}
              >
                Record learner activity
              </button>
            </div>
          </section>
        <% else %>
          <section class="flex flex-col gap-4 rounded-lg border border-dashed border-base-300 bg-base-100 p-8 text-center shadow-sm">
            <h2 class="text-2xl font-semibold">{@empty_state_heading}</h2>
            <p class="text-base leading-7 text-base-content/70">{@empty_state_body}</p>
          </section>
        <% end %>

        <section
          class="flex flex-col gap-4 rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
          data-role="checkout-facade-demo"
        >
          <div>
            <h2 class="text-2xl font-semibold">Checkout handoff</h2>
            <p class="mt-1 text-base leading-7 text-base-content/65">
              Create a hosted checkout link for the Studio plan when a buyer needs to complete payment outside this screen.
            </p>
          </div>
          <div class="flex flex-wrap gap-2">
            <button
              type="button"
              phx-click="create_checkout_session"
              class="btn btn-outline rounded-lg"
              disabled={@billing_locked?}
            >
              Create checkout link
            </button>
          </div>
          <div :if={@checkout_url} class="space-y-1">
            <p class="text-sm font-semibold text-base-content/60">Checkout link</p>
            <a
              href={@checkout_url}
              target="_blank"
              class="break-all text-sm font-semibold text-primary hover:underline"
              data-testid="checkout-url"
            >
              {@checkout_url}
            </a>
          </div>
        </section>

        <section
          class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
          data-role="recovery-wiring-demo"
        >
          <h2 class="text-2xl font-semibold">Payment recovery</h2>
          <div class="mt-1 space-y-1 text-base leading-7 text-base-content/65">
            <p>
              CohortFlow keeps recovery checks active for expiring cards, missed usage events, and payment states that need follow-up.
            </p>
            <p>
              Operators can review the underlying billing events and recovery analytics in Accrue Admin.
            </p>
          </div>
        </section>

        <section class="flex flex-col gap-4 rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
          <div>
            <p class="text-sm font-semibold text-primary">Tax location</p>
            <h2 class="mt-1 text-2xl font-semibold">Repair automatic tax input</h2>
            <div class="mt-1 space-y-1 text-base leading-7 text-base-content/65">
              <p>Save the workspace billing address before starting a tax-enabled subscription.</p>
              <p>{@tax_location_repair_copy}</p>
            </div>
          </div>

          <div :if={@tax_location_error} class="flex flex-col gap-2">
            <h3 class="text-xl font-semibold" data-testid="e2e-tax-invalid-headline">
              Tax location needs attention
            </h3>
            <p class="text-base leading-7 text-base-content/65" data-testid="e2e-tax-invalid-body">
              Update the customer tax location before tax-enabled charges can proceed.
            </p>
            <p class="text-sm font-semibold text-warning">{@tax_location_error}</p>
          </div>

          <p :if={tax_location_status(@subscription)} class="text-base leading-7 text-base-content/65">
            {tax_location_status(@subscription)}
          </p>

          <.form
            for={%{}}
            as={:tax_location}
            id="tax-location-form"
            phx-submit="update_tax_location"
            class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4"
          >
            <input type="hidden" name="organization_id" value="ignored-client-org" />
            <label class="flex flex-col gap-1 text-sm font-semibold text-base-content/70">
              Street address
              <input
                type="text"
                name="tax_location[line1]"
                value={@tax_location_form.line1}
                class="input input-bordered w-full rounded-lg"
              />
            </label>

            <label class="flex flex-col gap-1 text-sm font-semibold text-base-content/70">
              City
              <input
                type="text"
                name="tax_location[city]"
                value={@tax_location_form.city}
                class="input input-bordered w-full rounded-lg"
              />
            </label>

            <label class="flex flex-col gap-1 text-sm font-semibold text-base-content/70">
              State
              <input
                type="text"
                name="tax_location[state]"
                value={@tax_location_form.state}
                class="input input-bordered w-full rounded-lg"
              />
            </label>

            <label class="flex flex-col gap-1 text-sm font-semibold text-base-content/70">
              Postal code
              <input
                type="text"
                name="tax_location[postal_code]"
                value={@tax_location_form.postal_code}
                class="input input-bordered w-full rounded-lg"
              />
            </label>

            <label class="flex flex-col gap-1 text-sm font-semibold text-base-content/70">
              Country
              <input
                type="text"
                name="tax_location[country]"
                value={@tax_location_form.country}
                class="input input-bordered w-full rounded-lg"
              />
            </label>

            <button
              type="submit"
              class="btn btn-outline self-end rounded-lg"
              disabled={@billing_locked?}
            >
              Save tax location
            </button>
          </.form>
        </section>

        <section class="grid gap-4 lg:grid-cols-3">
          <article
            :for={plan <- @plans}
            data-plan-id={plan.id}
            class="flex flex-col gap-4 rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
          >
            <div class="flex items-start justify-between gap-4">
              <div>
                <p class="text-sm font-semibold uppercase text-base-content/60">{plan.eyebrow}</p>
                <h2 class="mt-1 text-2xl font-semibold">{plan.label}</h2>
                <p class="mt-1 text-base leading-7 text-base-content/65">{plan.summary}</p>
              </div>
              <span class={[
                "shrink-0 rounded-md px-2 py-1 text-xs font-semibold",
                plan.id == active_plan_id(@subscription) &&
                  "bg-primary/15 text-primary",
                plan.id != active_plan_id(@subscription) &&
                  "bg-base-200 text-base-content/70"
              ]}>
                {plan_badge(plan.id, @subscription)}
              </span>
            </div>

            <p class="text-3xl font-bold">{plan_price(plan)}</p>

            <ul class="flex flex-1 flex-col gap-2 text-sm leading-6 text-base-content/75">
              <li :for={feature <- plan.features} class="flex items-start gap-2">
                <span
                  aria-hidden="true"
                  class="mt-0.5 grid size-5 shrink-0 place-items-center rounded-full bg-primary/15 text-xs font-bold text-primary"
                >
                  &check;
                </span>
                <span>{feature}</span>
              </li>
            </ul>

            <%= if !@billing_locked? && plan.id != active_plan_id(@subscription) && @braintree_client_token do %>
              <div
                id={"braintree-container-#{plan.id}"}
                phx-hook="BraintreeVaultAcquisition"
                phx-update="ignore"
                data-client-token={@braintree_client_token}
                data-plan-id={plan.id}
                data-operation-id={Map.fetch!(@plan_operation_ids, plan.id)}
                class="mt-auto"
              >
                <div id="braintree-dropin-container"></div>
                <button
                  id="braintree-submit-button"
                  type="button"
                  class="btn btn-primary w-full rounded-lg"
                >
                  Choose {plan.label}
                </button>
              </div>
            <% else %>
              <button
                type="button"
                phx-click="start_subscription"
                phx-value-plan={plan.id}
                phx-value-operation_id={Map.fetch!(@plan_operation_ids, plan.id)}
                class={[
                  "btn mt-auto w-full rounded-lg",
                  plan.id == active_plan_id(@subscription) && "btn-outline",
                  plan.id != active_plan_id(@subscription) && "btn-primary"
                ]}
                disabled={
                  @billing_locked? ||
                    (plan.id == active_plan_id(@subscription) &&
                       !Subscription.canceled?(@subscription))
                }
              >
                Choose {plan.label}
              </button>
            <% end %>
          </article>
        </section>
      </section>
    </Layouts.app>
    """
  end

  defp list_switchable_organizations(nil), do: []

  defp list_switchable_organizations(user_id) do
    from(o in Organization,
      join: m in OrganizationMembership,
      on: m.organization_id == o.id,
      where: m.user_id == ^user_id and is_nil(o.deleted_at),
      select: %{id: o.id, name: o.name, slug: o.slug},
      order_by: o.slug
    )
    |> Repo.all()
  end

  defp load_state(socket) do
    access_state = access_state(socket.assigns.current_scope)

    {customer, subscription} =
      case Billing.billing_state_for_scope(socket.assigns.current_scope) do
        {:ok, %{customer: customer, subscription: subscription}} -> {customer, subscription}
        {:error, :no_active_organization} -> {nil, nil}
      end

    user = socket.assigns.current_scope.user

    socket
    |> assign(:plans, Plans.all())
    |> assign_action_operation_ids()
    |> assign(:switchable_organizations, list_switchable_organizations(user && user.id))
    |> assign(:active_organization_label, @active_organization_label)
    |> assign(:active_organization_helper, @active_organization_helper)
    |> assign(:start_subscription_copy, @start_subscription_copy)
    |> assign(:empty_state_heading, @empty_state_heading)
    |> assign(:empty_state_body, @empty_state_body)
    |> assign(:cancel_heading, @cancel_heading)
    |> assign(:cancel_body, @cancel_body)
    |> assign(:cancel_cta, @cancel_cta)
    |> assign(:cancel_keep_cta, @cancel_keep_cta)
    |> assign(:cancel_copy, @cancel_copy)
    |> assign(:tax_location_repair_copy, @tax_location_repair_copy)
    |> assign(:access_state, access_state)
    |> assign(:access_message, access_message(access_state))
    |> assign(:billing_locked?, billing_locked?(access_state))
    |> assign_new(:braintree_client_token, fn -> nil end)
    |> assign_new(:tax_location_error, fn -> nil end)
    |> assign_new(:tax_location_form, fn -> empty_tax_location_form() end)
    |> assign_new(:checkout_url, fn -> nil end)
    |> assign(:customer, customer)
    |> assign(:subscription, subscription)
    |> assign(:subscription_plan_label, plan_label(subscription))
  end

  defp assign_action_operation_ids(socket) do
    plan_operation_ids =
      Plans.all()
      |> Map.new(fn plan -> {plan.id, "subscribe:#{plan.id}:#{Ecto.UUID.generate()}"} end)

    socket
    |> assign(:plan_operation_ids, plan_operation_ids)
    |> assign(:cancel_operation_id, "cancel:#{Ecto.UUID.generate()}")
  end

  defp operation_id(%{"operation_id" => operation_id}, _prefix)
       when is_binary(operation_id) and operation_id != "" do
    operation_id
  end

  defp operation_id(_params, prefix), do: "#{prefix}:#{Ecto.UUID.generate()}"

  defp access_state(%{active_organization: nil}), do: :no_active_organization
  defp access_state(%{membership: %{role: role}}) when role in [:owner, :admin], do: :admin
  defp access_state(%{active_organization: _organization}), do: :member

  defp access_message(:admin), do: nil
  defp access_message(:member), do: @member_denial_copy
  defp access_message(:no_active_organization), do: @no_active_organization_copy

  defp billing_locked?(:admin), do: false
  defp billing_locked?(_state), do: true

  defp active_organization_name(%{active_organization: %{name: name}}), do: name
  defp active_organization_name(_scope), do: "No active workspace selected"

  defp active_plan_id(nil), do: nil

  defp active_plan_id(subscription),
    do: plan_id_from_data(subscription) || plan_id_from_customer(subscription)

  defp plan_id_from_data(%Subscription{data: data}) when is_map(data) do
    data
    |> Map.get("items", Map.get(data, :items))
    |> extract_item_price_id()
  end

  defp plan_id_from_data(_subscription), do: nil

  defp extract_item_price_id(%{"data" => [item | _]}), do: extract_price_id(item)
  defp extract_item_price_id(%{data: [item | _]}), do: extract_price_id(item)
  defp extract_item_price_id(_items), do: nil

  defp extract_price_id(%{"price" => %{"id" => id}}), do: id
  defp extract_price_id(%{price: %{id: id}}), do: id
  defp extract_price_id(%{"price_id" => id}), do: id
  defp extract_price_id(%{price_id: id}), do: id
  defp extract_price_id(_item), do: nil

  defp plan_id_from_customer(_subscription), do: nil

  defp plan_label(nil), do: nil

  defp plan_label(subscription) do
    id = active_plan_id(subscription)

    Plans.all()
    |> Enum.find_value(id, fn plan ->
      if plan.id == id, do: plan.label
    end)
  end

  defp plan_price(%{unit_amount_minor: 0}), do: "Usage based"

  defp plan_price(%{unit_amount_minor: cents}) when is_integer(cents) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)

    amount =
      if remainder == 0 do
        "$#{dollars}"
      else
        "$#{dollars}.#{String.pad_leading(Integer.to_string(remainder), 2, "0")}"
      end

    amount <> "/mo"
  end

  defp plan_badge(_plan_id, nil), do: "Available"

  defp plan_badge(plan_id, subscription) do
    if plan_id == active_plan_id(subscription) and !Subscription.canceled?(subscription) do
      "Current plan"
    else
      "Available"
    end
  end

  defp humanize_status(nil), do: "Unknown"

  defp humanize_status(status),
    do: status |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp tax_location_status(%Subscription{} = subscription) do
    # Map.get keeps this LiveView compiling against older published `accrue`
    # (Hex smoke) where `Subscription` may not yet expose this field.
    case Map.get(subscription, :automatic_tax_disabled_reason) do
      reason when is_binary(reason) and reason != "" ->
        "Automatic tax is currently disabled: #{humanize_reason(reason)}."

      _ ->
        nil
    end
  end

  defp tax_location_status(_subscription), do: nil

  defp tax_location_attrs(params) when is_map(params) do
    %{
      address: %{
        line1: blank_to_nil(params["line1"]),
        city: blank_to_nil(params["city"]),
        state: blank_to_nil(params["state"]),
        postal_code: blank_to_nil(params["postal_code"]),
        country: blank_to_nil(params["country"])
      }
    }
  end

  defp tax_location_defaults(params) when is_map(params) do
    %{
      line1: params["line1"] || "",
      city: params["city"] || "",
      state: params["state"] || "",
      postal_code: params["postal_code"] || "",
      country: params["country"] || ""
    }
  end

  defp empty_tax_location_form do
    %{line1: "", city: "", state: "", postal_code: "", country: "US"}
  end

  defp humanize_reason(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
