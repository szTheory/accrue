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

  @active_organization_label "Active organization"
  @active_organization_helper "Billing actions apply to the active organization only."
  @empty_state_heading "No organization billing activity yet"
  @empty_state_body "Billing records appear after an organization starts a subscription or a webhook is processed. Start the organization subscription or review webhook activity for this organization."
  @error_copy "We couldn't complete that billing action for the active organization. Check organization access, billing setup, or webhook processing, then try again."
  @cancel_copy "Cancel organization subscription: Confirm cancellation before ending organization access."
  @tax_location_repair_copy "Please update customer address or shipping before enabling automatic tax."
  @tax_location_success_copy "Tax location saved. Start the subscription again when you're ready."
  @member_denial_copy "Billing is managed by organization admins. You can review the current billing state, but you can't change it."
  @no_active_organization_copy "Select an active organization before managing billing."
  @start_subscription_copy "Start organization subscription"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Billing")
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
             |> put_flash(:info, "Subscription canceled.")
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section style={page_style()}>
        <div style={shell_style()}>
          <div style={header_style()}>
            <div>
              <p style={eyebrow_style()}>Account billing</p>
              <h1 style={heading_style()}>Choose a plan</h1>
              <p style={body_style()}>
                Billing for the signed-in host follows the active organization only.
              </p>
            </div>
            <.link navigate={~p"/"} style={link_style()}>Back home</.link>
          </div>

          <section style={card_style()}>
            <div style={section_header_style()}>
              <div>
                <p style={label_style()}>{@active_organization_label}</p>
                <h2 style={section_heading_style()}>{active_organization_name(@current_scope)}</h2>
                <p style={muted_body_style()}>{@active_organization_helper}</p>
              </div>
            </div>

            <div
              :if={@switchable_organizations != []}
              style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;"
              data-testid="organization-switcher"
            >
              <p style={label_style()}>Switch organization</p>
              <%= for org <- @switchable_organizations do %>
                <form action={~p"/app/organization-scope"} method="post" style="display:inline;">
                  <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                  <input type="hidden" name="organization_slug" value={org.slug} />
                  <button
                    type="submit"
                    style={secondary_button_style()}
                    data-organization-slug={org.slug}
                  >
                    {org.name}
                  </button>
                </form>
              <% end %>
            </div>

            <p :if={@access_message} style={warning_copy_style()}>
              {@access_message}
            </p>
          </section>

          <%= if @subscription do %>
            <section style={card_style()}>
              <div style={section_header_style()}>
                <div>
                  <h2 style={section_heading_style()}>Current subscription</h2>
                  <p style={muted_body_style()}>
                    Organization billing state is resolved through <code style={code_style()}>AccrueHost.Billing</code>.
                  </p>
                </div>
              </div>

              <dl style={details_grid_style()}>
                <div>
                  <dt style={label_style()}>Plan</dt>
                  <dd style={value_style()}>{@subscription_plan_label}</dd>
                </div>
                <div>
                  <dt style={label_style()}>Status</dt>
                  <dd style={value_style()}>{humanize_status(@subscription.status)}</dd>
                </div>
                <div>
                  <dt style={label_style()}>Customer</dt>
                  <dd style={value_style()}>{@customer.id}</dd>
                </div>
              </dl>

              <div :if={!Subscription.canceled?(@subscription)} style={danger_zone_style()}>
                <%= if @confirm_cancel do %>
                  <p style={warning_copy_style()}>{@cancel_copy}</p>
                  <div style={action_row_style()}>
                    <button
                      type="button"
                      phx-click="confirm_cancel"
                      phx-value-operation_id={@cancel_operation_id}
                      style={destructive_button_style()}
                      disabled={@billing_locked?}
                    >
                      Confirm cancellation
                    </button>
                    <button
                      type="button"
                      phx-click="dismiss_cancel"
                      style={secondary_button_style()}
                      disabled={@billing_locked?}
                    >
                      Keep subscription
                    </button>
                  </div>
                <% else %>
                  <button
                    type="button"
                    phx-click="request_cancel"
                    style={secondary_button_style()}
                    disabled={@billing_locked?}
                  >
                    Cancel organization subscription
                  </button>
                <% end %>
              </div>
            </section>
          <% else %>
            <section style={empty_state_style()}>
              <h2 style={section_heading_style()}>{@empty_state_heading}</h2>
              <p style={body_style()}>{@empty_state_body}</p>
            </section>
          <% end %>

          <section style={card_style()}>
            <div style={section_header_style()}>
              <div>
                <p style={eyebrow_style()}>Tax location</p>
                <h2 style={section_heading_style()}>Repair automatic tax input</h2>
                <p style={muted_body_style()}>
                  Save the customer billing address before starting a tax-enabled organization subscription.
                </p>
                <p style={muted_body_style()}>
                  {@tax_location_repair_copy}
                </p>
              </div>
            </div>

            <div :if={@tax_location_error} style="display:flex;flex-direction:column;gap:8px;">
              <h3 style={section_heading_style()} data-testid="e2e-tax-invalid-headline">
                Tax location needs attention
              </h3>
              <p style={muted_body_style()} data-testid="e2e-tax-invalid-body">
                Update the customer tax location before tax-enabled charges can proceed.
              </p>
              <p style={warning_copy_style()}>{@tax_location_error}</p>
            </div>

            <p :if={tax_location_status(@subscription)} style={muted_body_style()}>
              {tax_location_status(@subscription)}
            </p>

            <.form
              for={%{}}
              as={:tax_location}
              id="tax-location-form"
              phx-submit="update_tax_location"
              style={tax_location_form_style()}
            >
              <input type="hidden" name="organization_id" value="ignored-client-org" />
              <label style={field_label_style()}>
                Street address
                <input
                  type="text"
                  name="tax_location[line1]"
                  value={@tax_location_form.line1}
                  style={input_style()}
                />
              </label>

              <label style={field_label_style()}>
                City
                <input
                  type="text"
                  name="tax_location[city]"
                  value={@tax_location_form.city}
                  style={input_style()}
                />
              </label>

              <label style={field_label_style()}>
                State
                <input
                  type="text"
                  name="tax_location[state]"
                  value={@tax_location_form.state}
                  style={input_style()}
                />
              </label>

              <label style={field_label_style()}>
                Postal code
                <input
                  type="text"
                  name="tax_location[postal_code]"
                  value={@tax_location_form.postal_code}
                  style={input_style()}
                />
              </label>

              <label style={field_label_style()}>
                Country
                <input
                  type="text"
                  name="tax_location[country]"
                  value={@tax_location_form.country}
                  style={input_style()}
                />
              </label>

              <button type="submit" style={secondary_button_style()} disabled={@billing_locked?}>
                Save tax location
              </button>
            </.form>
          </section>

          <section style={plans_grid_style()}>
            <article :for={plan <- @plans} data-plan-id={plan.id} style={card_style()}>
              <div style={plan_header_style()}>
                <div>
                  <h2 style={section_heading_style()}>{plan.label}</h2>
                  <p style={muted_body_style()}>{plan.id}</p>
                </div>
                <span style={pill_style(plan.id == active_plan_id(@subscription))}>
                  {plan_badge(plan.id, @subscription)}
                </span>
              </div>

              <button
                type="button"
                phx-click="start_subscription"
                phx-value-plan={plan.id}
                phx-value-operation_id={Map.fetch!(@plan_operation_ids, plan.id)}
                style={primary_button_style(plan.id == active_plan_id(@subscription))}
                disabled={
                  @billing_locked? ||
                    (plan.id == active_plan_id(@subscription) &&
                       !Subscription.canceled?(@subscription))
                }
              >
                {@start_subscription_copy}
              </button>
            </article>
          </section>
        </div>
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
    |> assign(:cancel_copy, @cancel_copy)
    |> assign(:tax_location_repair_copy, @tax_location_repair_copy)
    |> assign(:access_state, access_state)
    |> assign(:access_message, access_message(access_state))
    |> assign(:billing_locked?, billing_locked?(access_state))
    |> assign_new(:tax_location_error, fn -> nil end)
    |> assign_new(:tax_location_form, fn -> empty_tax_location_form() end)
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
  defp active_organization_name(_scope), do: "No active organization selected"

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
      if plan.id == id, do: "#{plan.label} (#{plan.id})"
    end)
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

  defp tax_location_status(%Subscription{automatic_tax_disabled_reason: reason})
       when is_binary(reason) and reason != "" do
    "Automatic tax is currently disabled: #{humanize_reason(reason)}."
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

  defp page_style do
    "background:#FAFBFC;font-family:system-ui,-apple-system,BlinkMacSystemFont,\"Segoe UI\",sans-serif;padding:32px 0;"
  end

  defp shell_style do
    "margin:0 auto;max-width:880px;display:flex;flex-direction:column;gap:24px;"
  end

  defp header_style do
    "display:flex;justify-content:space-between;align-items:flex-start;gap:16px;"
  end

  defp eyebrow_style do
    "margin:0 0 8px;color:#2644C5;font-size:14px;font-weight:600;line-height:1.4;"
  end

  defp heading_style do
    "margin:0 0 8px;color:#111418;font-size:28px;font-weight:600;line-height:1.2;"
  end

  defp body_style do
    "margin:0;color:#24303B;font-size:16px;font-weight:400;line-height:1.5;"
  end

  defp muted_body_style do
    "margin:0;color:#5F6B76;font-size:16px;font-weight:400;line-height:1.5;"
  end

  defp card_style do
    "background:#FFFFFF;border:1px solid #E9EEF2;border-radius:8px;padding:24px;display:flex;flex-direction:column;gap:16px;"
  end

  defp empty_state_style do
    "background:#FFFFFF;border:1px dashed #E9EEF2;border-radius:8px;padding:48px 24px;display:flex;flex-direction:column;gap:16px;"
  end

  defp section_header_style do
    "display:flex;justify-content:space-between;align-items:flex-start;gap:16px;"
  end

  defp section_heading_style do
    "margin:0;color:#111418;font-size:20px;font-weight:600;line-height:1.2;"
  end

  defp details_grid_style do
    "display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;margin:0;"
  end

  defp tax_location_form_style do
    "display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;align-items:end;"
  end

  defp label_style do
    "margin:0 0 4px;color:#5F6B76;font-size:14px;font-weight:600;line-height:1.4;"
  end

  defp field_label_style do
    "display:flex;flex-direction:column;gap:6px;margin:0;color:#24303B;font-size:14px;font-weight:600;line-height:1.4;"
  end

  defp value_style do
    "margin:0;color:#111418;font-size:16px;font-weight:400;line-height:1.5;"
  end

  defp plans_grid_style do
    "display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;"
  end

  defp plan_header_style do
    "display:flex;justify-content:space-between;align-items:flex-start;gap:16px;"
  end

  defp link_style do
    "color:#2644C5;font-size:14px;font-weight:600;line-height:1.4;text-decoration:none;padding:8px 0;"
  end

  defp input_style do
    "border:1px solid #D3DCE4;border-radius:8px;padding:10px 12px;color:#111418;font-size:16px;line-height:1.4;background:#FFFFFF;"
  end

  defp code_style do
    "font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:14px;"
  end

  defp pill_style(true) do
    "background:#EEF2FF;color:#2644C5;border-radius:8px;padding:4px 8px;font-size:14px;font-weight:600;line-height:1.4;"
  end

  defp pill_style(false) do
    "background:#F3F5F7;color:#24303B;border-radius:8px;padding:4px 8px;font-size:14px;font-weight:600;line-height:1.4;"
  end

  defp action_row_style do
    "display:flex;flex-wrap:wrap;gap:8px;"
  end

  defp danger_zone_style do
    "display:flex;flex-direction:column;gap:16px;padding-top:8px;border-top:1px solid #E9EEF2;"
  end

  defp warning_copy_style do
    "margin:0;color:#111418;font-size:14px;font-weight:600;line-height:1.4;"
  end

  defp primary_button_style(true) do
    primary_button_style(false) <> "opacity:0.6;cursor:not-allowed;"
  end

  defp primary_button_style(false) do
    "background:#2644C5;color:#FFFFFF;border:none;border-radius:8px;padding:12px 16px;font-size:16px;font-weight:600;line-height:1.5;cursor:pointer;"
  end

  defp secondary_button_style do
    "background:#FFFFFF;color:#24303B;border:1px solid #E9EEF2;border-radius:8px;padding:12px 16px;font-size:16px;font-weight:600;line-height:1.5;cursor:pointer;"
  end

  defp destructive_button_style do
    "background:#111418;color:#FFFFFF;border:none;border-radius:8px;padding:12px 16px;font-size:16px;font-weight:600;line-height:1.5;cursor:pointer;"
  end
end
