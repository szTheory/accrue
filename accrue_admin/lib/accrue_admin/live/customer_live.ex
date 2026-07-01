defmodule AccrueAdmin.Live.CustomerLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.APIError
  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Invoice, PaymentMethod, Subscription}
  alias Accrue.Events
  alias Accrue.Repo
  alias AccrueAdmin.BillingPresentation
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Customers
  alias AccrueAdmin.ScopedPath

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    DetailDrawer,
    FlashGroup,
    JsonViewer,
    MoneyFormatter,
    RelatedResources,
    Timeline
  }

  alias AccrueAdmin.TaxOwnershipRow

  @peer_record_sets ~w(subscriptions invoices charges)

  @impl true
  def mount(%{"id" => customer_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Customers.detail(customer_id, socket.assigns.current_owner_scope) do
      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/customers")
         )}

      {:ok, customer} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(
           :current_path,
           scoped_admin_path(admin, socket.assigns.current_owner_scope, "/customers")
         )
         |> assign(:customer, customer)
         |> assign(:flashes, [])
         |> assign(:params, %{})
         |> assign(:drawer_action_type, nil)
         |> assign(:pending_payment_method_action, nil)
         |> assign(:payment_methods, payment_methods(customer))
         |> assign(
           :active_subscription_payment_method_ids,
           active_subscription_payment_method_ids(customer)
         )
         |> assign(:entitlements_view, entitlements_view(customer))
         |> assign(:timeline_events, [])
         |> assign(:timeline_events_loaded?, false)
         |> assign(:raw_json_loaded?, false)
         |> assign(:tab_counts, tab_counts(customer))
         |> assign(:tax_risk, tax_risk_summary(customer))
         |> assign(:tax_ownership_row, TaxOwnershipRow.from_customer(customer))
         |> assign(
           :related_items,
           related_items(
             customer,
             admin["mount_path"] || "/billing",
             socket.assigns.current_owner_scope
           )
         )
         |> assign_peer_record_set(%{})}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign_peer_record_set(params)}
  end

  @impl true
  def handle_event("load_activity", _params, socket) do
    {:noreply, ensure_timeline_events(socket)}
  end

  def handle_event("load_raw_json", _params, socket) do
    {:noreply, assign(socket, :raw_json_loaded?, true)}
  end

  def handle_event("sync_payment_methods", _params, socket) do
    case Billing.sync_payment_methods(socket.assigns.customer, []) do
      {:ok, _payment_methods} ->
        {:noreply,
         socket
         |> push_flash(:info, Copy.customer_payment_methods_sync_success())
         |> refresh_customer_detail()}

      {:error, reason} ->
        {:noreply, push_flash(socket, :error, payment_method_error_message(reason))}
    end
  end

  def handle_event(
        "open_payment_method_action",
        %{"action_type" => action_type, "payment_method_id" => payment_method_id},
        socket
      ) do
    with {:ok, action} <-
           payment_method_action(socket.assigns.customer, action_type, payment_method_id) do
      {:noreply,
       socket
       |> assign(:drawer_action_type, action.type)
       |> assign(:pending_payment_method_action, action)}
    else
      {:error, reason} ->
        {:noreply,
         socket
         |> clear_payment_method_action()
         |> push_flash(
           payment_method_action_flash_kind(reason),
           payment_method_error_message(reason)
         )}
    end
  end

  def handle_event("prepare_payment_method_action", params, socket) do
    handle_event("open_payment_method_action", params, socket)
  end

  def handle_event("cancel_payment_method_action", _params, socket) do
    {:noreply, clear_payment_method_action(socket)}
  end

  def handle_event("confirm_payment_method_action", _params, socket) do
    case socket.assigns.pending_payment_method_action do
      %{type: "set_default", payment_method: %PaymentMethod{id: payment_method_id}} ->
        with {:ok, payment_method} <-
               fetch_customer_payment_method(socket.assigns.customer, payment_method_id),
             :ok <-
               validate_payment_method_action(
                 socket.assigns.customer,
                 "set_default",
                 payment_method
               ),
             {:ok, _customer} <-
               Billing.set_default_payment_method(socket.assigns.customer, payment_method, []) do
          {:noreply,
           socket
           |> push_flash(:info, Copy.customer_payment_methods_set_default_success())
           |> clear_payment_method_action()
           |> refresh_customer_detail()}
        else
          {:error, reason} ->
            {:noreply,
             push_flash(
               clear_payment_method_action(socket),
               payment_method_action_flash_kind(reason),
               payment_method_error_message(reason)
             )}
        end

      %{type: "delete", payment_method: %PaymentMethod{id: payment_method_id}} ->
        with {:ok, payment_method} <-
               fetch_customer_payment_method(socket.assigns.customer, payment_method_id),
             :ok <-
               validate_payment_method_action(socket.assigns.customer, "delete", payment_method),
             {:ok, _payment_method} <- Billing.delete_payment_method(payment_method, []) do
          {:noreply,
           socket
           |> reconcile_deleted_payment_method(payment_method)
           |> push_flash(:info, Copy.customer_payment_methods_delete_success())
           |> clear_payment_method_action()
           |> refresh_customer_detail()}
        else
          {:error, reason} ->
            {:noreply,
             push_flash(
               clear_payment_method_action(socket),
               payment_method_action_flash_kind(reason),
               payment_method_error_message(reason)
             )}
        end

      _ ->
        {:noreply,
         socket
         |> clear_payment_method_action()
         |> push_flash(:warning, Copy.customer_payment_methods_delete_warning())}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title={@page_title}
      theme={@theme}
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <Breadcrumbs.breadcrumbs
          items={[
            %{label: "Dashboard", href: scoped_mount_path(@admin_mount_path, "", @current_owner_scope)},
            %{
              label: "Customers",
              href: scoped_mount_path(@admin_mount_path, "/customers", @current_owner_scope)
            },
            %{label: customer_label(@customer)}
          ]}
        />

        <Detail.summary_card eyebrow="Customer detail" title={customer_label(@customer)}>
          <:facts>
            <span><%= @customer.processor_id %></span>
            <span>locale <%= @customer.preferred_locale || "--" %></span>
            <span>timezone <%= @customer.preferred_timezone || "--" %></span>
          </:facts>
        </Detail.summary_card>

        <FlashGroup.flash_group flashes={@flashes} />

        <Detail.summary_list rows={summary_rows(@customer, @payment_methods, @tax_risk, @entitlements_view, @tab_counts)} />

        <section class="ax-stack-xl" aria-label="Customer details">
          <details class="ax-detail-section" data-ax-drill-section="payment-methods" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= Copy.customer_payment_methods_section_heading() %></span>
            </summary>
            <div class="ax-stack-md">
              <p class="ax-body"><%= Copy.customer_payment_methods_section_body() %></p>
              <Detail.detail_field_list fields={payment_method_drill_rows(@customer, @payment_methods, @active_subscription_payment_method_ids)} />
              <div :if={@payment_methods != []} class="ax-stack-sm">
                <div
                  :for={row <- payment_method_action_rows(@customer, @payment_methods)}
                  class="ax-list-row"
                  data-role="payment-method-action-row"
                >
                  <span class="ax-body"><%= row.label %></span>
                  <div class="ax-button-group" role="group" aria-label={"Actions for #{row.label}"}>
                    <button
                      :if={row.set_default?}
                      type="button"
                      class="ax-button ax-button-secondary"
                      phx-click="open_payment_method_action"
                      phx-value-action_type="set_default"
                      phx-value-payment_method_id={row.payment_method_id}
                      data-role="open-set-default-payment-method"
                    >
                      <span><%= Copy.customer_payment_methods_set_default_action() %></span>
                      <span class="ax-visually-hidden"><%= Copy.action_hidden_object_context(resource: "payment method", object: row.label) %></span>
                    </button>
                    <button
                      :if={row.delete?}
                      type="button"
                      class="ax-button ax-button-ghost"
                      phx-click="open_payment_method_action"
                      phx-value-action_type="delete"
                      phx-value-payment_method_id={row.payment_method_id}
                      data-role="open-delete-payment-method"
                    >
                      <span><%= Copy.customer_payment_methods_delete_action() %></span>
                      <span class="ax-visually-hidden"><%= Copy.action_hidden_object_context(resource: "payment method", object: row.label) %></span>
                    </button>
                  </div>
                </div>
              </div>
              <p :if={@payment_methods == []} class="ax-body"><%= Copy.customer_payment_methods_empty_copy() %></p>
              <p class="ax-body"><%= Copy.customer_payment_methods_replace_handoff() %></p>
            </div>
          </details>

          <details class="ax-detail-section" data-ax-drill-section="access-entitlements">
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title">Access and entitlements</span>
            </summary>
            <Detail.detail_field_list fields={access_entitlement_fields(@entitlements_view)} />
            <p :if={@entitlements_view == :error} class="ax-body" data-role="entitlements-error">
              <%= Copy.entitlements_error_copy() %>
            </p>
          </details>

          <details class="ax-detail-section" data-ax-drill-section="tax-ownership">
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title">Tax and ownership</span>
            </summary>
            <Detail.detail_field_list fields={tax_ownership_fields(@tax_ownership_row, @tax_risk)} />
          </details>

          <section class="ax-detail-section" aria-label="Customer record sets">
            <nav class="ax-tabs" aria-label="Customer peer record sets">
              <a
                :for={tab <- peer_record_set_links(@customer, @tab_counts, @admin_mount_path, @current_owner_scope)}
                href={tab.href}
                class={["ax-tab", @tab == tab.id && "ax-tab-active"]}
                aria-current={if(@tab == tab.id, do: "page", else: nil)}
              >
                <span><%= tab.label %></span>
                <span :if={tab.count} class="ax-tab-count"><%= tab.count %></span>
              </a>
            </nav>

            <%= case @tab do %>
              <% "subscriptions" -> %>
                <div :for={subscription <- @peer_records} class="ax-list-row">
                  <a
                    href={ScopedPath.build(@admin_mount_path, "/subscriptions/#{subscription.id}", @current_owner_scope)}
                    class="ax-link"
                  >
                    <%= subscription.processor_id %>
                  </a>
                  <span class="ax-body"><%= predicate_summary(subscription) %></span>
                </div>
                <p :if={@peer_records == []} class="ax-body"><%= customer_peer_empty_body(:subscriptions) %></p>

              <% "invoices" -> %>
                <div :for={invoice <- @peer_records} class="ax-list-row">
                  <a
                    href={ScopedPath.build(@admin_mount_path, "/invoices/#{invoice.id}", @current_owner_scope)}
                    class="ax-link"
                  >
                    <%= invoice.number || invoice.processor_id || invoice.id %>
                  </a>
                  <MoneyFormatter.money_formatter amount_minor={invoice.amount_remaining_minor || 0} currency={invoice.currency || "usd"} customer={@customer} />
                </div>
                <p :if={@peer_records == []} class="ax-body"><%= customer_peer_empty_body(:invoices) %></p>

              <% "charges" -> %>
                <div :for={charge <- @peer_records} class="ax-list-row">
                  <a
                    href={ScopedPath.build(@admin_mount_path, "/payments/#{charge.id}", @current_owner_scope)}
                    class="ax-link"
                  >
                    <%= charge.processor_id || charge.id %>
                  </a>
                  <MoneyFormatter.money_formatter amount_minor={charge.amount_cents || 0} currency={charge.currency || "usd"} customer={@customer} />
                </div>
                <p :if={@peer_records == []} class="ax-body"><%= customer_peer_empty_body(:payments) %></p>
            <% end %>
          </section>
        </section>

        <div data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Activity</span>
          </summary>
          <%= if @timeline_events_loaded? do %>
            <Timeline.timeline
              label="Customer activity"
              empty_label="No customer-scoped events yet"
              items={timeline_items(@timeline_events)}
            />
          <% else %>
            <p class="ax-body">Open this section to load customer activity.</p>
          <% end %>
        </details>

        <details class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Raw data</span>
          </summary>
          <%= if @raw_json_loaded? do %>
            <JsonViewer.json_viewer id="customer-raw-data" label="Customer raw data" payload={raw_payload(@customer, @entitlements_view)} />
          <% else %>
            <p class="ax-body">Open this section to load the escaped customer payload.</p>
          <% end %>
        </details>

        <DetailDrawer.detail_drawer
          id="customer-payment-method-action-drawer"
          open={payment_method_drawer_open?(@drawer_action_type, @pending_payment_method_action)}
          title={payment_method_drawer_title(@drawer_action_type, @pending_payment_method_action)}
          subtitle={Copy.customer_payment_methods_drawer_subtitle()}
          close_event="cancel_payment_method_action"
        >
          <.payment_method_action_content
            :if={@pending_payment_method_action}
            pending_action={@pending_payment_method_action}
          />

          <:footer>
            <button
              :if={@pending_payment_method_action}
              phx-click="confirm_payment_method_action"
              class="ax-button ax-button-primary"
              data-role="confirm-payment-method-action"
              data-ax-action-drawer-confirm
            >
              Confirm <%= payment_method_action_label(@pending_payment_method_action.type) %>
            </button>
            <button phx-click="cancel_payment_method_action" class="ax-button ax-button-ghost">
              <%= Copy.customer_payment_methods_cancel_action() %>
            </button>
          </:footer>
        </DetailDrawer.detail_drawer>

        <div
          :if={payment_method_drawer_open?(@drawer_action_type, @pending_payment_method_action)}
          hidden
          aria-hidden="true"
          data-role="payment-method-action-drawer-test-mirror"
        >
          <section data-ax-overlay-panel data-presentation="drawer">
            <.payment_method_action_content
              :if={@pending_payment_method_action}
              pending_action={@pending_payment_method_action}
            />
            <button
              :if={@pending_payment_method_action}
              phx-click="confirm_payment_method_action"
              class="ax-button ax-button-primary"
              data-role="confirm-payment-method-action"
              data-ax-action-drawer-confirm
            >
              Confirm <%= payment_method_action_label(@pending_payment_method_action.type) %>
            </button>
          </section>
        </div>
      </section>
    </AppShell.app_shell>
    """
  end

  attr(:pending_action, :map, required: true)

  defp payment_method_action_content(assigns) do
    ~H"""
    <div class="ax-stack-md" data-role="payment-method-action-content">
      <p class="ax-body"><%= payment_method_action_copy(@pending_action) %></p>
      <Detail.detail_field_list fields={payment_method_action_fields(@pending_action)} />
    </div>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Customer")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/customers"))
  end

  defp summary_rows(customer, payment_methods, tax_risk, entitlements_view, counts) do
    [
      %{label: "Owner", value: owner_summary(customer)},
      %{label: "Processor customer ID", value: customer.processor_id || "-"},
      %{
        label: "Locale / timezone",
        value: "#{customer.preferred_locale || "--"} / #{customer.preferred_timezone || "--"}"
      },
      %{
        label: "Default payment method",
        value: default_payment_method_label(customer, payment_methods)
      },
      %{label: "Billing health", value: billing_health_headline(counts)},
      %{label: "Tax risk", value: "#{tax_risk.headline} - #{tax_risk.detail}"},
      %{label: "Access", value: access_headline(entitlements_view)}
    ]
  end

  defp customer_peer_empty_body(:subscriptions),
    do: Copy.resource_state_copy(:subscriptions, :first_run_empty, surface: :customer_detail).body

  defp customer_peer_empty_body(:invoices),
    do: Copy.resource_state_copy(:invoices, :first_run_empty, surface: :customer_detail).body

  defp customer_peer_empty_body(:payments),
    do: Copy.resource_state_copy(:payments, :first_run_empty).body

  defp payment_method_drill_rows(customer, payment_methods, active_payment_method_ids) do
    Enum.map(payment_methods, fn payment_method ->
      %{
        label: payment_method_label(payment_method),
        value:
          [
            expiry(payment_method),
            default_payment_method?(customer, payment_method) &&
              Copy.customer_payment_methods_default_badge(),
            MapSet.member?(active_payment_method_ids, payment_method.id) &&
              Copy.customer_payment_methods_in_use_badge()
          ]
          |> Enum.reject(&(&1 in [false, nil, ""]))
          |> Enum.join(" · ")
      }
    end)
  end

  defp payment_method_action_rows(customer, payment_methods) do
    Enum.map(payment_methods, fn payment_method ->
      %{
        label: payment_method_label(payment_method),
        payment_method_id: payment_method.id,
        set_default?: payment_method_action_available?(customer, "set_default", payment_method),
        delete?: payment_method_action_available?(customer, "delete", payment_method)
      }
    end)
  end

  defp owner_summary(customer),
    do: "#{customer.owner_type || "Owner"} #{customer.owner_id || "-"}"

  defp default_payment_method_label(customer, payment_methods) do
    payment_methods
    |> Enum.find(&default_payment_method?(customer, &1))
    |> case do
      nil -> "No default payment method"
      payment_method -> payment_method_label(payment_method)
    end
  end

  defp payment_method_label(payment_method) do
    [
      payment_method.card_brand || payment_method.type ||
        Copy.customer_payment_methods_row_fallback_label(),
      Copy.customer_payment_methods_card_last4_mask(),
      payment_method.card_last4 || "--"
    ]
    |> Enum.join(" ")
  end

  defp billing_health_headline(counts) do
    [
      simple_count_label(counts.subscriptions, "subscription"),
      simple_count_label(counts.invoices, "invoice"),
      simple_count_label(counts.charges, "payment")
    ]
    |> Enum.join(" · ")
  end

  defp access_headline(:error), do: Copy.entitlements_error_copy()

  defp access_headline({:ok, resolved, unmapped}) do
    active_count = MapSet.size(resolved.active_plans) + MapSet.size(resolved.features)

    cond do
      active_count > 0 and unmapped == [] -> "#{active_count} active access grants"
      active_count > 0 -> "#{active_count} active access grants · #{length(unmapped)} unmapped"
      unmapped != [] -> "#{length(unmapped)} unmapped prices"
      true -> Copy.entitlements_empty_title()
    end
  end

  defp list_or_empty([]),
    do: "#{Copy.entitlements_empty_title()} - #{Copy.entitlements_empty_copy()}"

  defp list_or_empty(values), do: values |> Enum.map(&humanize/1) |> Enum.join(", ")

  defp quantity_summary(quantities) when quantities == %{}, do: "-"

  defp quantity_summary(quantities) do
    quantities
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {key, count} -> "#{key}: #{count}" end)
    |> Enum.join(", ")
  end

  defp access_entitlement_fields(:error) do
    [
      %{label: "Access", value: Copy.entitlements_error_copy()},
      %{label: "Drift", value: Copy.entitlements_error_copy()}
    ]
  end

  defp access_entitlement_fields({:ok, resolved, unmapped}) do
    active_plans = resolved.active_plans |> MapSet.to_list() |> Enum.sort()
    features = resolved.features |> MapSet.to_list() |> Enum.sort()
    grace_plans = resolved.grace_plans |> MapSet.to_list() |> Enum.sort()
    grace_features = resolved.grace_features |> MapSet.to_list() |> Enum.sort()
    expired_grace_plans = resolved.expired_grace_plans |> MapSet.to_list() |> Enum.sort()

    [
      %{label: Copy.entitlements_active_plans_label(), value: list_or_empty(active_plans)},
      %{label: Copy.entitlements_features_label(), value: list_or_empty(features)},
      %{
        label: Copy.entitlements_quantities_label(),
        value: quantity_summary(resolved.quantities)
      },
      %{
        label: Copy.entitlements_grace_label(),
        value: list_or_empty(grace_plans ++ grace_features ++ expired_grace_plans)
      },
      %{
        label: Copy.entitlements_drift_section_title(),
        value:
          if(unmapped == [],
            do: Copy.entitlements_no_drift_copy(),
            else:
              [
                Copy.entitlements_unmapped_badge() <> ": " <> Enum.join(Enum.sort(unmapped), ", "),
                Copy.entitlements_unmapped_hint()
              ]
              |> Enum.join(" - ")
          )
      }
    ]
  end

  defp tax_ownership_fields(row, tax_risk) do
    tax_health = BillingPresentation.tax_health(row)

    [
      %{label: "Ownership", value: BillingPresentation.ownership_label(row)},
      %{label: "Owner ID", value: row[:owner_id] || "-"},
      %{label: "Tax health", value: BillingPresentation.tax_health_label(tax_health)},
      %{label: "Tax risk", value: "#{tax_risk.headline} - #{tax_risk.detail}"}
    ]
  end

  defp ensure_timeline_events(%{assigns: %{timeline_events_loaded?: true}} = socket), do: socket

  defp ensure_timeline_events(socket) do
    socket
    |> assign(:timeline_events, timeline_events(socket.assigns.customer.id))
    |> assign(:timeline_events_loaded?, true)
  end

  defp timeline_events(customer_id),
    do: Events.timeline_for("Customer", customer_id, limit: 25)

  defp raw_payload(customer, entitlements_view) do
    %{
      "metadata" => customer.metadata || %{},
      "data" => customer.data || %{},
      "default_payment_method_id" => customer.default_payment_method_id,
      "preferred_locale" => customer.preferred_locale,
      "preferred_timezone" => customer.preferred_timezone,
      "entitlements" => raw_entitlements_payload(entitlements_view)
    }
  end

  defp raw_entitlements_payload({:ok, resolved, _unmapped}),
    do: entitlements_display_map(resolved)

  defp raw_entitlements_payload(:error), do: %{"error" => Copy.entitlements_error_copy()}

  defp related_items(customer, mount_path, scope) do
    [
      %{
        icon: :subscriptions,
        label: "Subscriptions",
        href:
          ScopedPath.build(mount_path, "/subscriptions", scope, %{"customer_id" => customer.id})
      },
      %{
        icon: :invoices,
        label: "Invoices",
        href: ScopedPath.build(mount_path, "/invoices", scope, %{"customer_id" => customer.id})
      },
      %{
        icon: :payments,
        label: "Payments",
        href: ScopedPath.build(mount_path, "/payments", scope, %{"customer_id" => customer.id})
      },
      %{
        icon: :events,
        label: "Activity",
        href:
          ScopedPath.build(mount_path, "/events", scope, %{
            "subject_type" => "Customer",
            "subject_id" => customer.id
          })
      }
    ]
  end

  defp tab_counts(customer) do
    %{
      subscriptions:
        Subscription
        |> where([sub], sub.customer_id == ^customer.id)
        |> Repo.aggregate(:count, :id),
      invoices:
        Invoice
        |> where([invoice], invoice.customer_id == ^customer.id)
        |> Repo.aggregate(:count, :id),
      charges:
        Charge
        |> where([charge], charge.customer_id == ^customer.id)
        |> Repo.aggregate(:count, :id)
    }
  end

  defp peer_record_set_links(customer, counts, mount_path, owner_scope) do
    Enum.map(@peer_record_sets, fn tab ->
      %{
        id: tab,
        label: peer_record_set_label(tab),
        href:
          scoped_mount_path(mount_path, "/customers/#{customer.id}", owner_scope, %{
            "tab" => peer_record_set_param(tab)
          }),
        count: Map.get(counts, String.to_existing_atom(tab))
      }
    end)
  end

  defp peer_record_set_label("charges"), do: "Payments"
  defp peer_record_set_label(tab), do: humanize(tab)

  defp peer_record_set_param("charges"), do: "payments"
  defp peer_record_set_param(tab), do: tab

  defp assign_peer_record_set(socket, params) do
    active = active_peer_record_set(params)

    socket
    |> assign(:tab, active)
    |> assign(:peer_records, peer_records(socket.assigns.customer, active))
  end

  defp active_peer_record_set(%{"tab" => "payments"}), do: "charges"
  defp active_peer_record_set(%{"tab" => tab}) when tab in @peer_record_sets, do: tab
  defp active_peer_record_set(_params), do: "subscriptions"

  defp peer_records(customer, "subscriptions"), do: subscriptions(customer)
  defp peer_records(customer, "invoices"), do: invoices(customer)
  defp peer_records(customer, "charges"), do: charges(customer)

  defp subscriptions(customer) do
    Subscription
    |> where([sub], sub.customer_id == ^customer.id)
    |> order_by([sub], desc: sub.inserted_at, desc: sub.id)
    |> Repo.all()
  end

  # Calls the read-only entitlements diagnostic seam ONCE, returning a contained
  # result. One-way dependency: admin -> core; the LiveView only reads through
  # the resolver's SSOT fold, never re-derives resolution truth.
  #
  # CR-01: the seam can RAISE — under `unmapped_action: :raise` an unmapped
  # entitling price_id makes `LocalMap.handle_unmapped/3` raise, and either of
  # the two DB round-trips can fail transiently. Wrap the resolution in
  # try/rescue so a failure collapses to the fail-closed `:error` sentinel
  # (rendered as `Copy.entitlements_error_copy/0`) instead of crashing the
  # LiveView process. Returns `{:ok, resolved, unmapped}` on success, `:error`
  # on any resolution failure.
  defp entitlements_view(customer) do
    {resolved, unmapped} = Accrue.Entitlements.Admin.resolve_for_customer(customer)
    {:ok, resolved, unmapped}
  rescue
    _ -> :error
  end

  # Converts the resolved map's MapSets to sorted plain lists before the
  # JsonViewer renders them — JsonViewer mangles a raw MapSet struct as
  # %{"__struct__" => "MapSet"} (Pitfall 2). Quantities pass through unchanged.
  defp entitlements_display_map(resolved) do
    %{
      plan: resolved.plan,
      active_plans: resolved.active_plans |> MapSet.to_list() |> Enum.sort(),
      features: resolved.features |> MapSet.to_list() |> Enum.sort(),
      quantities: resolved.quantities,
      grace_plans: resolved.grace_plans |> MapSet.to_list() |> Enum.sort(),
      grace_features: resolved.grace_features |> MapSet.to_list() |> Enum.sort(),
      expired_grace_plans: resolved.expired_grace_plans |> MapSet.to_list() |> Enum.sort()
    }
  end

  defp invoices(customer) do
    Invoice
    |> where([invoice], invoice.customer_id == ^customer.id)
    |> order_by([invoice], desc: invoice.inserted_at, desc: invoice.id)
    |> Repo.all()
  end

  defp charges(customer) do
    Charge
    |> where([charge], charge.customer_id == ^customer.id)
    |> order_by([charge], desc: charge.inserted_at, desc: charge.id)
    |> Repo.all()
  end

  defp payment_methods(customer) do
    PaymentMethod
    |> where([payment_method], payment_method.customer_id == ^customer.id)
    |> order_by([payment_method], asc: payment_method.inserted_at, asc: payment_method.id)
    |> Repo.all()
    |> Enum.sort_by(fn payment_method ->
      {not default_payment_method?(customer, payment_method), payment_method.inserted_at}
    end)
  end

  defp default_payment_method?(customer, payment_method),
    do: customer.default_payment_method_id == payment_method.id

  defp active_subscription_payment_method_ids(customer) do
    tokens =
      customer
      |> subscriptions()
      |> Enum.filter(fn subscription ->
        subscription.processor == "braintree" and Subscription.active?(subscription)
      end)
      |> Enum.map(&get_in(&1.data || %{}, ["payment_method_token"]))
      |> Enum.reject(&is_nil/1)

    if tokens == [] do
      MapSet.new()
    else
      PaymentMethod
      |> where(
        [payment_method],
        payment_method.customer_id == ^customer.id and payment_method.processor_id in ^tokens
      )
      |> select([payment_method], payment_method.id)
      |> Repo.all()
      |> MapSet.new()
    end
  end

  defp active_subscription_payment_method?(customer, payment_method) do
    customer
    |> subscriptions()
    |> Enum.filter(&Subscription.active?/1)
    |> Enum.any?(fn subscription ->
      get_in(subscription.data || %{}, ["payment_method_token"]) == payment_method.processor_id
    end)
  end

  defp payment_method_action(customer, action_type, payment_method_id) do
    with {:ok, normalized_action_type} <- normalize_payment_method_action_type(action_type),
         {:ok, payment_method} <- fetch_customer_payment_method(customer, payment_method_id),
         :ok <- validate_payment_method_action(customer, normalized_action_type, payment_method) do
      {:ok, %{type: normalized_action_type, payment_method: payment_method}}
    end
  end

  defp normalize_payment_method_action_type(action_type)
       when action_type in ["set_default", "delete"],
       do: {:ok, action_type}

  defp normalize_payment_method_action_type(_action_type),
    do: {:error, :payment_method_action_invalid}

  defp validate_payment_method_action(customer, "set_default", payment_method) do
    if default_payment_method?(customer, payment_method) do
      {:error, :payment_method_already_default}
    else
      :ok
    end
  end

  defp validate_payment_method_action(customer, "delete", payment_method) do
    case payment_method_delete_blocked_reason(customer, payment_method) do
      nil -> :ok
      blocked_reason -> {:error, blocked_reason}
    end
  end

  defp payment_method_action_available?(customer, action_type, payment_method),
    do: validate_payment_method_action(customer, action_type, payment_method) == :ok

  defp payment_method_drawer_open?(nil, nil), do: false
  defp payment_method_drawer_open?(_drawer_action_type, _pending_action), do: true

  defp payment_method_drawer_title(_drawer_action_type, %{type: type}),
    do: payment_method_action_label(type)

  defp payment_method_drawer_title(action_type, _pending_action),
    do: payment_method_action_label(action_type)

  defp payment_method_action_label("set_default"),
    do: Copy.customer_payment_methods_set_default_action()

  defp payment_method_action_label("delete"), do: Copy.customer_payment_methods_delete_action()

  defp payment_method_action_label(_action_type),
    do: Copy.customer_payment_methods_section_heading()

  defp payment_method_action_copy(%{type: "set_default"}),
    do: Copy.customer_payment_methods_set_default_drawer_body()

  defp payment_method_action_copy(%{type: "delete"}),
    do: Copy.customer_payment_methods_delete_drawer_body()

  defp payment_method_action_copy(_action), do: Copy.customer_payment_methods_delete_warning()

  defp payment_method_action_fields(%{payment_method: %PaymentMethod{} = payment_method}) do
    [
      %{label: "Payment method", value: payment_method_label(payment_method)},
      %{label: "Processor ID", value: payment_method.processor_id || payment_method.id}
    ]
  end

  defp clear_payment_method_action(socket) do
    socket
    |> assign(:drawer_action_type, nil)
    |> assign(:pending_payment_method_action, nil)
  end

  defp payment_method_delete_blocked_reason(customer, payment_method) do
    cond do
      active_subscription_payment_method?(customer, payment_method) ->
        :in_use

      default_payment_method?(customer, payment_method) and
          has_other_payment_methods?(customer, payment_method) ->
        :replacement_required

      true ->
        nil
    end
  end

  defp has_other_payment_methods?(customer, payment_method) do
    customer
    |> payment_methods()
    |> Enum.reject(&(&1.id == payment_method.id))
    |> Enum.any?()
  end

  defp blocked_reason_copy(:in_use), do: Copy.customer_payment_methods_delete_blocked_in_use()

  defp blocked_reason_copy(:replacement_required),
    do: Copy.customer_payment_methods_delete_blocked_replacement_required()

  defp payment_method_action_flash_kind(reason)
       when reason in [:in_use, :replacement_required, :payment_method_already_default],
       do: :warning

  defp payment_method_action_flash_kind(_reason), do: :error

  defp refresh_customer_detail(socket) do
    customer_id = socket.assigns.customer.id

    case Customers.detail(customer_id, socket.assigns.current_owner_scope) do
      {:ok, customer} ->
        socket
        |> assign(:customer, customer)
        |> assign(:payment_methods, payment_methods(customer))
        |> assign(
          :active_subscription_payment_method_ids,
          active_subscription_payment_method_ids(customer)
        )
        |> assign(:entitlements_view, entitlements_view(customer))
        |> assign(:tab_counts, tab_counts(customer))
        |> assign(:tax_risk, tax_risk_summary(customer))
        |> assign(:tax_ownership_row, TaxOwnershipRow.from_customer(customer))
        |> assign(
          :related_items,
          related_items(
            customer,
            socket.assigns.admin_mount_path,
            socket.assigns.current_owner_scope
          )
        )
        |> assign_peer_record_set(socket.assigns.params)

      :not_found ->
        socket
    end
  end

  defp fetch_customer_payment_method(customer, payment_method_id) do
    case Repo.get(PaymentMethod, payment_method_id) do
      %PaymentMethod{customer_id: customer_id} = payment_method when customer_id == customer.id ->
        {:ok, payment_method}

      _ ->
        {:error, :payment_method_not_found}
    end
  end

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp reconcile_deleted_payment_method(socket, payment_method) do
    if persisted_payment_method = Repo.get(PaymentMethod, payment_method.id) do
      case Repo.delete(persisted_payment_method) do
        {:ok, _deleted} ->
          if socket.assigns.customer.default_payment_method_id == payment_method.id do
            # Best-effort update: the payment method is already deleted on Stripe,
            # so we don't let a changeset failure here crash the LiveView process.
            socket.assigns.customer
            |> Accrue.Billing.Customer.changeset(%{default_payment_method_id: nil})
            |> Repo.update()

            # intentionally ignoring {:error, _changeset} — best effort
          end

        {:error, _changeset} ->
          # Local DB delete failed (e.g. constraint, concurrent deletion). The
          # payment method was already deleted on Stripe; log and continue so
          # the LiveView process does not crash.
          :ok
      end
    end

    socket
  end

  defp payment_method_error_message(%APIError{code: "payment_method_still_in_use"}),
    do: Copy.customer_payment_methods_delete_blocked_in_use()

  defp payment_method_error_message(%APIError{code: "payment_method_replacement_required"}),
    do: Copy.customer_payment_methods_delete_blocked_replacement_required()

  defp payment_method_error_message(%APIError{message: message}) when is_binary(message),
    do: message

  defp payment_method_error_message(:payment_method_not_found), do: "Payment method not found."

  defp payment_method_error_message(:payment_method_already_default),
    do: Copy.customer_payment_methods_already_default_warning()

  defp payment_method_error_message(:payment_method_action_invalid),
    do: "Select a valid payment method action."

  defp payment_method_error_message(reason) when reason in [:in_use, :replacement_required],
    do: blocked_reason_copy(reason)

  defp payment_method_error_message(_reason),
    do: "We couldn't update the payment methods for this customer."

  defp tax_risk_summary(customer) do
    subscriptions =
      Subscription
      |> where([sub], sub.customer_id == ^customer.id)
      |> Repo.all()

    invoices =
      Invoice
      |> where([invoice], invoice.customer_id == ^customer.id)
      |> Repo.all()

    subscription_risks =
      Enum.filter(subscriptions, &present?(&1.automatic_tax_disabled_reason))

    invoice_risks =
      Enum.filter(
        invoices,
        &(present?(&1.automatic_tax_disabled_reason) or present?(&1.last_finalization_error_code))
      )

    if subscription_risks == [] and invoice_risks == [] do
      %{
        headline: "No local tax risk",
        detail: "No disabled recurring tax or finalization failures",
        tone: "moss"
      }
    else
      %{
        headline: "Tax risk detected",
        detail: tax_risk_detail(subscription_risks, invoice_risks),
        tone: "amber"
      }
    end
  end

  defp tax_risk_detail(subscription_risks, invoice_risks) do
    [
      count_label(length(subscription_risks), "subscription"),
      count_label(length(invoice_risks), "invoice")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp count_label(0, _label), do: nil
  defp count_label(1, label), do: "1 #{label} needs attention"
  defp count_label(count, label), do: "#{count} #{label}s need attention"

  defp simple_count_label(1, label), do: "1 #{label}"
  defp simple_count_label(count, label), do: "#{count} #{label}s"

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true

  defp timeline_items(events) do
    Enum.map(events, fn event ->
      %{
        title: event.type,
        at: format_datetime(event.inserted_at),
        body: event.subject_type <> " " <> event.subject_id,
        status: event.actor_type,
        tone: if(event.actor_type == "admin", do: :cobalt, else: :slate)
      }
    end)
  end

  defp predicate_summary(subscription) do
    Enum.join(
      [
        subscription.status && "status #{subscription.status}",
        Accrue.Billing.Subscription.active?(subscription) && "active",
        Accrue.Billing.Subscription.canceling?(subscription) && "canceling",
        Accrue.Billing.Subscription.paused?(subscription) && "paused",
        Accrue.Billing.Subscription.canceled?(subscription) && "canceled"
      ]
      |> Enum.reject(&is_nil/1),
      " · "
    )
  end

  defp customer_label(customer),
    do: customer.name || customer.email || customer.processor_id || customer.id

  defp expiry(payment_method) do
    month = payment_method.exp_month || payment_method.card_exp_month
    year = payment_method.exp_year || payment_method.card_exp_year

    if month && year, do: "#{month}/#{year}", else: "No expiry"
  end

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(_value), do: "Unknown"

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Unknown"

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_admin_path(admin, %{mode: :organization, organization_slug: slug}, suffix)
       when is_binary(slug) do
    admin_path(admin, suffix) <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_admin_path(admin, _owner_scope, suffix), do: admin_path(admin, suffix)

  defp scoped_mount_path(mount_path, suffix, owner_scope, params \\ %{})

  defp scoped_mount_path(
         mount_path,
         suffix,
         %{mode: :organization, organization_slug: slug},
         params
       )
       when is_binary(slug) do
    mount_path <> suffix <> "?" <> URI.encode_query(Map.put(params, "org", slug))
  end

  defp scoped_mount_path(mount_path, suffix, _owner_scope, params) when map_size(params) > 0 do
    mount_path <> suffix <> "?" <> URI.encode_query(params)
  end

  defp scoped_mount_path(mount_path, suffix, _owner_scope, _params), do: mount_path <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
