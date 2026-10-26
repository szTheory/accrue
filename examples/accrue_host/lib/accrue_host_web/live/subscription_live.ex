defmodule AccrueHostWeb.SubscriptionLive do
  use AccrueHostWeb, :live_view

  import Ecto.Query
  import Phoenix.Controller, only: [get_csrf_token: 0]

  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Checkout
  alias Accrue.Checkout.LocalSession
  alias AccrueHost.Accounts.{Organization, OrganizationMembership}
  alias AccrueHost.Billing
  alias AccrueHost.Billing.Plans
  alias AccrueHost.Repo
  alias Accrue.Processor

  @active_organization_label "Active workspace"
  @active_organization_helper "Plan changes and payment actions apply to this workspace only."
  @empty_state_heading "No workspace subscription yet"
  @empty_state_body "Choose a plan to start billing for this team workspace. Subscription and invoice records will appear here after checkout or webhook updates."
  @error_copy "We couldn't complete that billing action for the active workspace. Check access, billing setup, or payment state, then try again."
  @cancel_copy "Cancel now for this workspace only. Access can end immediately."
  @cancel_heading "Need to stop access?"
  @cancel_body "Use immediate cancellation when the workspace should stop billing and access right away."
  @cancel_cta "Cancel workspace subscription"
  @cancel_keep_cta "Keep subscription"
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
  def handle_params(params = %{"plan" => plan_id, "selection" => selection_id}, _uri, socket)
      when is_binary(plan_id) and is_binary(selection_id) and
             not is_map_key(params, "checkout") do
    case Plans.get(plan_id) do
      nil ->
        {:noreply,
         socket
         |> assign(:selected_checkout_plan, nil)
         |> put_flash(:error, "That plan is unavailable. Choose a plan from pricing to continue.")}

      plan ->
        case Ecto.UUID.cast(selection_id) do
          {:ok, _uuid} ->
            socket = assign(socket, :checkout_selection_id, selection_id)
            create_selected_checkout(socket, plan, selection_id)

          :error ->
            {:noreply,
             socket
             |> assign(:selected_checkout_plan, nil)
             |> put_flash(
               :error,
               "That plan selection has expired. Choose a plan from pricing to continue."
             )}
        end
    end
  end

  def handle_params(%{"checkout" => "cancel"} = params, _uri, socket) do
    {:noreply,
     socket
     |> assign_return_offer(params)
     |> assign(
       :checkout_return_state,
       {:canceled, "Checkout was canceled. Return to billing to review the current status."}
     )}
  end

  def handle_params(%{"checkout" => "success"} = params, _uri, socket) do
    socket = assign_return_offer(socket, params)

    state_socket =
      if Processor.name() == "braintree" do
        braintree_checkout_return(socket, params)
      else
        case params["checkout_session_id"] do
          session_id when is_binary(session_id) and byte_size(session_id) <= 255 ->
            stripe_checkout_return(socket, params, session_id)

          _ ->
            assign_checkout_return(
              socket,
              :unavailable,
              "We couldn't verify this checkout return. Check billing status or contact support before trying again."
            )
        end
      end

    {:noreply, state_socket}
  end

  def handle_params(_params, _uri, socket),
    do: {:noreply, assign(socket, :selected_checkout_plan, nil)}

  @impl true
  def handle_event("start_subscription", %{"plan" => plan_id} = params, socket) do
    # An org already on a different, non-canceled plan should CHANGE plans
    # (swap the existing subscription) rather than create a second one; a
    # first-time or canceled workspace subscribes. Both report the same copy.
    result =
      case socket.assigns.subscription do
        %Subscription{} = subscription ->
          if not Subscription.canceled?(subscription) and
               active_plan_id(subscription) != plan_id do
            change_active_plan(socket, subscription, plan_id)
          else
            subscribe_active_org(socket, plan_id, params)
          end

        _ ->
          subscribe_active_org(socket, plan_id, params)
      end

    case result do
      {:ok, _subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Subscription started.")
         |> assign(:confirm_cancel, false)
         |> load_state()}

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
           operation_id: operation_id(params, "subscribe")
         ) do
      {:ok, _subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Subscription started.")
         |> assign(:confirm_cancel, false)
         |> load_state()}

      {:error, :no_active_organization} ->
        {:noreply, put_flash(socket, :error, @no_active_organization_copy)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, @member_denial_copy)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, @error_copy)}
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

  def handle_event("create_checkout_session", %{"plan" => plan_id}, socket) do
    case Plans.get(plan_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "That plan is unavailable.")}

      plan ->
        case socket.assigns[:checkout_selection_id] do
          selection_id when is_binary(selection_id) ->
            create_selected_checkout(socket, plan, selection_id)

          _ ->
            {:noreply,
             put_flash(socket, :error, "Choose a plan from pricing before starting checkout.")}
        end
    end
  end

  def handle_event("create_checkout_session", _params, socket) do
    {:noreply, put_flash(socket, :error, "Choose a plan from pricing before starting checkout.")}
  end

  defp create_selected_checkout(socket, plan, selection_id) do
    scope = socket.assigns.current_scope
    billable = scope.active_organization

    if billing_locked?(socket.assigns.access_state) or is_nil(billable) do
      {:noreply, put_flash(socket, :error, @member_denial_copy)}
    else
      attrs = %{
        mode: :subscription,
        ui_mode: :hosted,
        success_url: hosted_success_url(plan, selection_id),
        cancel_url: hosted_cancel_url(plan, selection_id),
        operation_id: "pricing:#{billable.id}:#{plan.id}:#{selection_id}",
        line_items: [
          %{
            "price" => plan.id,
            "quantity" => 1,
            "name" => plan.label,
            "amount" => amount_decimal(plan.unit_amount_minor),
            "amount_minor" => plan.unit_amount_minor,
            "currency" => plan.currency,
            "interval" => plan.billing_cycle.unit,
            "interval_count" => plan.billing_cycle.count
          }
        ],
        metadata: %{
          "plan_name" => plan.label,
          "amount_minor" => plan.unit_amount_minor,
          "currency" => plan.currency,
          "interval" => Atom.to_string(plan.billing_cycle.unit),
          "interval_count" => plan.billing_cycle.count,
          "billable_type" => "Organization",
          "billable_id" => to_string(billable.id),
          "billable_name" => billable.name,
          "processor" => to_string(Processor.name()),
          "plan_id" => plan.id,
          "selection_id" => selection_id
        }
      }

      case Billing.create_checkout_session_for_scope(scope, attrs) do
        {:ok, session} ->
          {:noreply,
           socket
           |> assign(:checkout_url, selected_checkout_url(session))
           |> assign(:selected_checkout_plan, plan)}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, @error_copy <> " (#{inspect(reason)})")}
      end
    end
  end

  defp hosted_success_url(plan, selection_id) do
    case Processor.name() do
      "braintree" ->
        url(~p"/app/billing") <>
          "?" <> URI.encode_query(%{checkout: "success", plan: plan.id, selection: selection_id})

      _ ->
        url(~p"/app/billing") <>
          "?checkout=success&plan=#{URI.encode(plan.id)}&selection=#{URI.encode(selection_id)}&checkout_session_id={CHECKOUT_SESSION_ID}"
    end
  end

  defp hosted_cancel_url(plan, selection_id) do
    url(~p"/app/billing") <>
      "?" <> URI.encode_query(%{checkout: "cancel", plan: plan.id, selection: selection_id})
  end

  defp assign_return_offer(socket, %{"plan" => plan_id, "selection" => selection_id}) do
    case {Plans.get(plan_id), Ecto.UUID.cast(selection_id)} do
      {%{} = plan, {:ok, _uuid}} -> assign(socket, :selected_checkout_plan, plan)
      _ -> assign(socket, :selected_checkout_plan, nil)
    end
  end

  defp assign_return_offer(socket, _params), do: assign(socket, :selected_checkout_plan, nil)

  defp valid_checkout_session_id?(id), do: Regex.match?(~r/\Acs_[A-Za-z0-9_]+\z/, id)

  defp stripe_checkout_return(socket, params, session_id) do
    scope = socket.assigns.current_scope
    organization = scope.active_organization

    if billing_locked?(socket.assigns.access_state) do
      assign_checkout_return(
        socket,
        :blocked,
        "Billing access is unavailable for this workspace. Ask a workspace admin to review the checkout status."
      )
    else
      if valid_checkout_session_id?(session_id) and not is_nil(organization) do
        expected_metadata = %{
          "billable_type" => "Organization",
          "billable_id" => to_string(organization.id),
          "processor" => to_string(Processor.name()),
          "plan_id" => params["plan"],
          "selection_id" => params["selection"]
        }

        state =
          case Checkout.reconcile(session_id, expected_metadata: expected_metadata) do
            {:ok, session} ->
              if value(session, :status) == "complete" and
                   value(session, :payment_status) == "paid" do
                {:complete,
                 "Payment confirmed by the provider. Your subscription is being updated."}
              else
                {:pending,
                 "The provider has not confirmed payment yet. Check billing status before trying again."}
              end

            {:error, _reason} ->
              {:unavailable,
               "We couldn't verify this checkout return. Check billing status or contact support before trying again."}
          end

        assign(socket, :checkout_return_state, state)
      else
        assign_checkout_return(
          socket,
          :unavailable,
          "We couldn't verify this checkout return. Check billing status or contact support before trying again."
        )
      end
    end
  end

  defp braintree_checkout_return(socket, %{"plan" => plan_id, "selection" => selection_id})
       when is_binary(plan_id) and is_binary(selection_id) and byte_size(selection_id) == 36 do
    scope = socket.assigns.current_scope

    case {Plans.get(plan_id), Ecto.UUID.cast(selection_id), scope.active_organization} do
      {%{} = plan, {:ok, _uuid}, %Organization{} = organization} ->
        operation_id = "pricing:#{organization.id}:#{plan.id}:#{selection_id}"

        case Billing.checkout_session_for_scope(scope, operation_id) do
          {:ok,
           %{
             customer: %Customer{} = customer,
             local_session: %LocalSession{} = local_session
           }} ->
            if braintree_session_matches?(
                 local_session,
                 customer,
                 organization,
                 plan,
                 selection_id
               ) do
              case local_session.status do
                "completed" ->
                  assign_checkout_return(
                    socket,
                    :complete,
                    "Checkout completed. Your workspace subscription is being updated."
                  )

                status when status in ["open", "processing", "uncertain"] ->
                  assign_checkout_return(
                    socket,
                    :pending,
                    "Checkout is still being verified. Check billing status before trying again."
                  )

                _ ->
                  checkout_return_unavailable(socket)
              end
            else
              checkout_return_unavailable(socket)
            end

          {:error, :forbidden} ->
            assign_checkout_return(
              socket,
              :blocked,
              "Billing access is unavailable for this workspace. Ask a workspace admin to review the checkout status."
            )

          _ ->
            checkout_return_unavailable(socket)
        end

      _ ->
        checkout_return_unavailable(socket)
    end
  end

  defp braintree_checkout_return(socket, _params), do: checkout_return_unavailable(socket)

  defp braintree_session_matches?(
         %LocalSession{} = session,
         %Customer{} = customer,
         organization,
         plan,
         selection_id
       ) do
    expected_metadata = %{
      "billable_type" => "Organization",
      "billable_id" => to_string(organization.id),
      "processor" => "braintree",
      "plan_id" => plan.id,
      "selection_id" => selection_id,
      "amount_minor" => plan.unit_amount_minor,
      "currency" => plan.currency,
      "interval" => Atom.to_string(plan.billing_cycle.unit),
      "interval_count" => plan.billing_cycle.count
    }

    metadata_matches? =
      is_map(session.metadata) and
        Enum.all?(expected_metadata, fn {key, expected} ->
          Map.get(session.metadata, key) == expected
        end)

    line_item_matches? =
      case session.line_items do
        [%{} = item] ->
          value(item, :price) == plan.id and value(item, :quantity) == 1 and
            value(item, :amount_minor) == plan.unit_amount_minor and
            value(item, :currency) == plan.currency and
            value(item, :interval) == Atom.to_string(plan.billing_cycle.unit) and
            value(item, :interval_count) == plan.billing_cycle.count

        _ ->
          false
      end

    session.processor == "braintree" and session.customer_id == customer.id and
      customer.processor == "braintree" and customer.owner_type == "Organization" and
      customer.owner_id == to_string(organization.id) and session.mode == "subscription" and
      session.ui_mode == "hosted" and
      session.operation_id == "pricing:#{organization.id}:#{plan.id}:#{selection_id}" and
      session.price_id == plan.id and metadata_matches? and line_item_matches?
  end

  defp checkout_return_unavailable(socket) do
    assign_checkout_return(
      socket,
      :unavailable,
      "We couldn't verify this checkout return. Check billing status or contact support before trying again."
    )
  end

  defp assign_checkout_return(socket, status, message),
    do: assign(socket, :checkout_return_state, {status, message})

  defp value(%{} = map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))
  defp value(_, _key), do: nil

  defp selected_checkout_url(%{id: id, url: url}) do
    case Ecto.UUID.cast(id) do
      {:ok, _uuid} ->
        case LocalSession.by_id(id) do
          %LocalSession{session_token: token} ->
            AccruePortal.Path.checkout("/shared-billing", token)

          _ ->
            url
        end

      :error ->
        url
    end
  end

  defp amount_decimal(amount_minor) when is_integer(amount_minor) do
    "#{div(amount_minor, 100)}.#{String.pad_leading(Integer.to_string(rem(amount_minor, 100)), 2, "0")}"
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
              Review the active team workspace, subscription status, usage, and payment recovery path.
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
          <section
            class="flex flex-col gap-4 rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm"
            data-testid="current-subscription"
          >
            <div>
              <h2 class="text-2xl font-semibold">Current subscription</h2>
              <p class="mt-1 text-base leading-7 text-base-content/65">
                This workspace is subscribed and can keep the team's access active.
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
              Continue with the exact plan selected on pricing when a buyer needs to complete payment outside this screen.
            </p>
          </div>
          <p
            :if={@checkout_return_state}
            role="status"
            aria-live="polite"
            data-testid="checkout-return-state"
            class="rounded-lg border border-base-300 p-4 text-base leading-7"
          >
            {elem(@checkout_return_state, 1)}
          </p>
          <div class="flex flex-wrap gap-2">
            <button
              :if={@selected_checkout_plan}
              type="button"
              phx-click="create_checkout_session"
              phx-value-plan={@selected_checkout_plan.id}
              class="btn btn-outline rounded-lg"
              disabled={@billing_locked?}
            >
              Continue with {@selected_checkout_plan.label}
            </button>
            <p :if={!@selected_checkout_plan} class="text-sm text-base-content/60">
              Choose a plan from pricing to start checkout.
            </p>
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
              Cadence keeps recovery checks active for expiring cards, missed usage events, and payment states that need follow-up.
            </p>
            <p>
              Operators can review the underlying billing events and recovery analytics in Accrue Admin.
            </p>
          </div>
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

  defp subscribe_active_org(socket, plan_id, params) do
    Billing.subscribe_active_organization(socket.assigns.current_scope, plan_id,
      operation_id: operation_id(params, "subscribe")
    )
  end

  defp change_active_plan(socket, subscription, plan_id) do
    if billing_locked?(socket.assigns.access_state) do
      {:error, :forbidden}
    else
      Billing.change_plan(subscription, plan_id, proration: :create_prorations)
    end
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
    |> assign(:access_state, access_state)
    |> assign(:access_message, access_message(access_state))
    |> assign(:billing_locked?, billing_locked?(access_state))
    |> assign_new(:braintree_client_token, fn -> nil end)
    |> assign_new(:checkout_url, fn -> nil end)
    |> assign_new(:selected_checkout_plan, fn -> nil end)
    |> assign_new(:checkout_selection_id, fn -> nil end)
    |> assign_new(:checkout_return_state, fn -> nil end)
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
end
