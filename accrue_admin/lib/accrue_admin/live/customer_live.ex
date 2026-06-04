defmodule AccrueAdmin.Live.CustomerLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.APIError
  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Invoice, PaymentMethod, Subscription}
  alias Accrue.Events
  alias Accrue.Repo
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Customers
  alias AccrueAdmin.ScopedPath

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    FlashGroup,
    JsonViewer,
    KpiCard,
    MoneyFormatter,
    RelatedResources,
    StatusBadge,
    TaxOwnershipCard,
    Timeline
  }

  alias AccrueAdmin.TaxOwnershipRow

  @tabs ~w(subscriptions invoices charges payment_methods entitlements events metadata)
  @primary_tabs ~w(subscriptions invoices charges)
  @more_tabs ~w(payment_methods entitlements events metadata)

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
         |> assign(:pending_payment_method_delete, nil)
         |> assign(:payment_methods, payment_methods(customer))
         |> assign(:tab, "subscriptions")
         |> assign(:more_tabs_open, false)
         |> assign(:more_tabs, @more_tabs)
         |> assign(:tab_counts, tab_counts(customer))
         |> assign(:tax_risk, tax_risk_summary(customer))}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tab =
      params
      |> Map.get("tab", "subscriptions")
      |> normalize_tab()

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:tab, tab)
     |> assign(:more_tabs_open, false)
     |> assign_entitlements_view(tab)}
  end

  @impl true
  def handle_event("toggle_more_tabs", _params, socket) do
    {:noreply, assign(socket, :more_tabs_open, !socket.assigns.more_tabs_open)}
  end

  def handle_event("close_more_tabs", _params, socket) do
    {:noreply, assign(socket, :more_tabs_open, false)}
  end

  @impl true
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
        "set_default_payment_method",
        %{"payment_method_id" => payment_method_id},
        socket
      ) do
    with {:ok, payment_method} <-
           fetch_customer_payment_method(socket.assigns.customer, payment_method_id),
         {:ok, _customer} <-
           Billing.set_default_payment_method(socket.assigns.customer, payment_method, []) do
      {:noreply,
       socket
       |> push_flash(:info, Copy.customer_payment_methods_set_default_success())
       |> refresh_customer_detail()}
    else
      {:error, reason} ->
        {:noreply, push_flash(socket, :error, payment_method_error_message(reason))}
    end
  end

  def handle_event(
        "prepare_delete_payment_method",
        %{"payment_method_id" => payment_method_id},
        socket
      ) do
    with {:ok, payment_method} <-
           fetch_customer_payment_method(socket.assigns.customer, payment_method_id) do
      {:noreply,
       assign(
         socket,
         :pending_payment_method_delete,
         build_pending_payment_method_delete(socket.assigns.customer, payment_method)
       )}
    else
      {:error, reason} ->
        {:noreply, push_flash(socket, :error, payment_method_error_message(reason))}
    end
  end

  def handle_event("cancel_delete_payment_method", _params, socket) do
    {:noreply, assign(socket, :pending_payment_method_delete, nil)}
  end

  def handle_event("confirm_delete_payment_method", _params, socket) do
    case socket.assigns.pending_payment_method_delete do
      %{blocked_reason: nil, payment_method: %PaymentMethod{} = payment_method} ->
        case Billing.delete_payment_method(payment_method, []) do
          {:ok, _payment_method} ->
            {:noreply,
             socket
             |> reconcile_deleted_payment_method(payment_method)
             |> push_flash(:info, Copy.customer_payment_methods_delete_success())
             |> assign(:pending_payment_method_delete, nil)
             |> refresh_customer_detail()}

          {:error, reason} ->
            {:noreply, push_flash(socket, :error, payment_method_error_message(reason))}
        end

      %{blocked_reason: blocked_reason} when not is_nil(blocked_reason) ->
        {:noreply, push_flash(socket, :warning, blocked_reason_copy(blocked_reason))}

      _ ->
        {:noreply, push_flash(socket, :warning, Copy.customer_payment_methods_delete_warning())}
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

        <section class="ax-kpi-grid" aria-label="Customer summary">
          <KpiCard.kpi_card label="Owner" value={@customer.owner_type}>
            <:meta><%= @customer.owner_id %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Subscriptions"
            value={Integer.to_string(@tab_counts.subscriptions)}
            delta={Integer.to_string(@tab_counts.payment_methods) <> " payment methods"}
            delta_tone="cobalt"
          >
            <:meta>Local subscription and payment method projections</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Payments"
            value={Integer.to_string(@tab_counts.charges)}
            delta={Integer.to_string(@tab_counts.invoices) <> " invoices"}
            delta_tone="slate"
          >
            <:meta>Payments and invoices tied to this customer</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Tax risk"
            value={@tax_risk.headline}
            delta={@tax_risk.detail}
            delta_tone={@tax_risk.tone}
          >
            <:meta>Derived from projected subscriptions and invoices only</:meta>
          </KpiCard.kpi_card>
        </section>

        <TaxOwnershipCard.tax_ownership_card row={TaxOwnershipRow.from_customer(@customer)} />

        <RelatedResources.related_resources items={related_items(@customer, @admin_mount_path, @current_owner_scope)} />

        <nav class="ax-tabs" aria-label="Customer sections">
          <a
            :for={tab <- primary_tab_list(@customer, @tab_counts, @admin_mount_path, @current_owner_scope)}
            href={tab.href}
            class={["ax-tab", @tab == tab.id && "ax-tab-active"]}
            aria-current={if(@tab == tab.id, do: "page", else: nil)}
          >
            <span><%= tab.label %></span>
            <span :if={tab.count} class="ax-tab-count"><%= tab.count %></span>
          </a>
          <div
            class="ax-tab-more-wrapper"
            phx-window-keydown="close_more_tabs"
            phx-key="Escape"
          >
            <button
              type="button"
              class={["ax-tab ax-tab-more-trigger", @tab in @more_tabs && "ax-tab-active"]}
              aria-haspopup="menu"
              aria-expanded={to_string(@more_tabs_open)}
              phx-click="toggle_more_tabs"
            >
              More <AccrueAdmin.Components.Icon.icon name={:chevron_down} size="sm" />
            </button>
            <ul :if={@more_tabs_open} class="ax-tab-more-menu" role="menu">
              <li
                :for={tab <- more_tab_list(@customer, @tab_counts, @admin_mount_path, @current_owner_scope)}
                role="none"
              >
                <a
                  href={tab.href}
                  class="ax-tab-more-item"
                  role="menuitem"
                  aria-current={if(@tab == tab.id, do: "page", else: nil)}
                >
                  <%= tab.label %>
                  <span :if={tab.count} class="ax-tab-count"><%= tab.count %></span>
                </a>
              </li>
            </ul>
          </div>
        </nav>

        <%= case @tab do %>
          <% "subscriptions" -> %>
            <Detail.detail_section title="Subscriptions">
              <div :for={subscription <- subscriptions(@customer)} class="ax-list-row">
                <a
                  href={scoped_mount_path(@admin_mount_path, "/subscriptions/" <> subscription.id, @current_owner_scope)}
                  class="ax-link"
                >
                  <%= subscription.processor_id %>
                </a>
                <span class="ax-body"><%= predicate_summary(subscription) %></span>
              </div>
              <p :if={subscriptions(@customer) == []} class="ax-body"><%= Copy.customer_detail_no_subscriptions() %></p>
            </Detail.detail_section>

          <% "invoices" -> %>
            <Detail.detail_section title="Invoices">
              <div :for={invoice <- invoices(@customer)} class="ax-list-row">
                <a
                  href={ScopedPath.build(@admin_mount_path, "/invoices/#{invoice.id}", @current_owner_scope)}
                  class="ax-link"
                >
                  <%= invoice.number || invoice.processor_id || invoice.id %>
                </a>
                <MoneyFormatter.money_formatter amount_minor={invoice.amount_remaining_minor || 0} currency={invoice.currency || "usd"} customer={@customer} />
              </div>
              <p :if={invoices(@customer) == []} class="ax-body"><%= Copy.customer_detail_no_invoices() %></p>
            </Detail.detail_section>

          <% "charges" -> %>
            <Detail.detail_section title="Payments">
              <div :for={charge <- charges(@customer)} class="ax-list-row">
                <span class="ax-body"><%= charge.processor_id || charge.id %> · <%= charge.status %></span>
                <MoneyFormatter.money_formatter amount_minor={charge.amount_cents || 0} currency={charge.currency || "usd"} customer={@customer} />
              </div>
              <p :if={charges(@customer) == []} class="ax-body">No charges projected yet.</p>
            </Detail.detail_section>

          <% "payment_methods" -> %>
            <Detail.detail_section title={Copy.customer_payment_methods_section_heading()}>
              <:actions>
                <button
                  type="button"
                  class="ax-button ax-button-primary"
                  phx-click="sync_payment_methods"
                  data-role="sync-payment-methods"
                >
                  <%= Copy.customer_payment_methods_sync_action() %>
                </button>
              </:actions>
              <p class="ax-body"><%= Copy.customer_payment_methods_section_body() %></p>
              <div :for={payment_method <- @payment_methods} class="ax-list-row">
                <div>
                  <p class="ax-body">
                    <%= payment_method.card_brand || payment_method.type || Copy.customer_payment_methods_row_fallback_label() %> <%= Copy.customer_payment_methods_card_last4_mask() %> <%= payment_method.card_last4 || "--" %>
                  </p>
                  <p class="ax-body">
                    <%= expiry(payment_method) %>
                    <span :if={default_payment_method?(@customer, payment_method)}>
                      · <%= Copy.customer_payment_methods_default_badge() %>
                    </span>
                    <span :if={active_subscription_payment_method?(@customer, payment_method)}>
                      · <%= Copy.customer_payment_methods_in_use_badge() %>
                    </span>
                  </p>
                </div>
                <div class="ax-page-header">
                  <button
                    :if={!default_payment_method?(@customer, payment_method)}
                    type="button"
                    class="ax-button ax-button-ghost"
                    phx-click="set_default_payment_method"
                    phx-value-payment_method_id={payment_method.id}
                    data-role="set-default-payment-method"
                    data-payment-method-id={payment_method.id}
                  >
                    <%= Copy.customer_payment_methods_set_default_action() %>
                  </button>
                  <button
                    type="button"
                    class="ax-button ax-button-ghost"
                    phx-click="prepare_delete_payment_method"
                    phx-value-payment_method_id={payment_method.id}
                    data-role="prepare-delete-payment-method"
                    data-payment-method-id={payment_method.id}
                  >
                    <%= Copy.customer_payment_methods_delete_action() %>
                  </button>
                </div>
              </div>
              <p :if={@payment_methods == []} class="ax-body"><%= Copy.customer_payment_methods_empty_copy() %></p>
              <p class="ax-body"><%= Copy.customer_payment_methods_replace_handoff() %></p>

              <section
                :if={@pending_payment_method_delete}
                class="ax-card"
                data-role="payment-method-delete-confirmation"
              >
                <p class="ax-label"><%= Copy.customer_payment_methods_delete_action() %></p>
                <p class="ax-body"><%= Copy.customer_payment_methods_delete_warning() %></p>
                <p class="ax-body">
                  <%= pending_delete_label(@pending_payment_method_delete.payment_method) %>
                </p>
                <p :if={@pending_payment_method_delete.blocked_reason} class="ax-body">
                  <%= blocked_reason_copy(@pending_payment_method_delete.blocked_reason) %>
                </p>
                <div class="ax-page-header">
                  <button
                    :if={is_nil(@pending_payment_method_delete.blocked_reason)}
                    type="button"
                    class="ax-button ax-button-primary"
                    phx-click="confirm_delete_payment_method"
                    data-role="confirm-delete-payment-method"
                  >
                    <%= Copy.customer_payment_methods_delete_action() %>
                  </button>
                  <button
                    type="button"
                    class="ax-button ax-button-ghost"
                    phx-click="cancel_delete_payment_method"
                  >
                    <%= Copy.customer_payment_methods_cancel_action() %>
                  </button>
                </div>
              </section>
            </Detail.detail_section>

          <% "entitlements" -> %>
            <%= case @entitlements_view do %>
              <% :error -> %>
                <section class="ax-card" data-role="entitlements-error">
                  <h3 class="ax-heading"><%= Copy.entitlements_section_title() %></h3>
                  <p class="ax-body"><%= Copy.entitlements_error_copy() %></p>
                </section>

              <% {:ok, resolved, unmapped} -> %>
                <% active_plans = resolved.active_plans |> MapSet.to_list() |> Enum.sort() %>
                <% features = resolved.features |> MapSet.to_list() |> Enum.sort() %>
                <% grace_plans = resolved.grace_plans |> MapSet.to_list() |> Enum.sort() %>
                <% grace_features = resolved.grace_features |> MapSet.to_list() |> Enum.sort() %>
                <% expired_grace_plans = resolved.expired_grace_plans |> MapSet.to_list() |> Enum.sort() %>
                <% any_grace? = grace_plans != [] or grace_features != [] or expired_grace_plans != [] %>
                <Detail.detail_section title={Copy.entitlements_section_title()}>
                  <div :if={active_plans != []} class="ax-stack-sm">
                    <p class="ax-label"><%= Copy.entitlements_active_plans_label() %></p>
                    <div :for={plan <- active_plans} class="ax-list-row">
                      <StatusBadge.status_badge status={plan} tone="moss" />
                    </div>
                  </div>

                  <div :if={features != []} class="ax-stack-sm">
                    <p class="ax-label"><%= Copy.entitlements_features_label() %></p>
                    <div :for={feature <- features} class="ax-list-row">
                      <StatusBadge.status_badge status={feature} tone="moss" />
                    </div>
                  </div>

                  <div :if={resolved.quantities != %{}} class="ax-stack-sm">
                    <p class="ax-label"><%= Copy.entitlements_quantities_label() %></p>
                    <div class="ax-kpi-grid">
                      <KpiCard.kpi_card
                        :for={{quota_key, count} <- Enum.sort_by(resolved.quantities, &elem(&1, 0))}
                        label={to_string(quota_key)}
                        value={Integer.to_string(count)}
                      />
                    </div>
                  </div>

                  <div :if={any_grace?} class="ax-stack-sm">
                    <p class="ax-label"><%= Copy.entitlements_grace_label() %></p>
                    <div :for={plan <- grace_plans} class="ax-list-row">
                      <StatusBadge.status_badge status={plan} tone="amber" />
                    </div>
                    <div :for={feature <- grace_features} class="ax-list-row">
                      <StatusBadge.status_badge status={feature} tone="amber" />
                    </div>
                    <div :for={plan <- expired_grace_plans} class="ax-list-row">
                      <StatusBadge.status_badge status={plan} tone="slate" />
                    </div>
                  </div>

                  <p :if={active_plans == [] and features == []} class="ax-body">
                    <%= Copy.entitlements_empty_title() %> · <%= Copy.entitlements_empty_copy() %>
                  </p>
                </Detail.detail_section>

                <Detail.detail_section title={Copy.entitlements_drift_section_title()}>
                  <div :for={price_id <- unmapped} class="ax-list-row">
                    <div>
                      <StatusBadge.status_badge
                        status={:unmapped}
                        label={Copy.entitlements_unmapped_badge()}
                        tone="amber"
                      />
                      <p class="ax-muted ax-body"><%= price_id %> · <%= Copy.entitlements_unmapped_hint() %></p>
                    </div>
                  </div>
                  <p :if={unmapped == []} class="ax-body"><%= Copy.entitlements_no_drift_copy() %></p>
                </Detail.detail_section>

                <JsonViewer.json_viewer
                  id="customer-entitlements"
                  label={Copy.entitlements_raw_map_label()}
                  payload={entitlements_display_map(resolved)}
                />
            <% end %>

          <% "events" -> %>
            <Detail.detail_section title="Events">
              <Timeline.timeline
                label="Customer events"
                empty_label="No customer-scoped events yet"
                items={timeline_items(@customer)}
              />
            </Detail.detail_section>

          <% "metadata" -> %>
            <JsonViewer.json_viewer id="customer-metadata" label="Customer metadata" payload={metadata_payload(@customer)} />
        <% end %>
      </section>
    </AppShell.app_shell>
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
        |> Repo.aggregate(:count, :id),
      payment_methods:
        PaymentMethod
        |> where([pm], pm.customer_id == ^customer.id)
        |> Repo.aggregate(:count, :id),
      events: length(Events.timeline_for("Customer", customer.id, limit: 25)),
      metadata: map_size(customer.metadata || %{})
    }
  end

  defp tabs(customer, mount_path, counts, owner_scope) do
    Enum.map(@tabs, fn tab ->
      %{
        id: tab,
        label: tab_display_label(tab),
        href:
          scoped_mount_path(mount_path, "/customers/#{customer.id}", owner_scope, %{
            "tab" => tab
          }),
        count: Map.get(counts, String.to_existing_atom(tab))
      }
    end)
  end

  defp primary_tab_list(customer, counts, mount_path, owner_scope) do
    Enum.map(@primary_tabs, fn tab ->
      %{
        id: tab,
        label: tab_display_label(tab),
        href:
          scoped_mount_path(mount_path, "/customers/#{customer.id}", owner_scope, %{
            "tab" => tab
          }),
        count: Map.get(counts, String.to_existing_atom(tab))
      }
    end)
  end

  defp more_tab_list(customer, counts, mount_path, owner_scope) do
    Enum.map(@more_tabs, fn tab ->
      %{
        id: tab,
        label: tab_display_label(tab),
        href:
          scoped_mount_path(mount_path, "/customers/#{customer.id}", owner_scope, %{
            "tab" => tab
          }),
        count: Map.get(counts, String.to_existing_atom(tab))
      }
    end)
  end

  # Display label for tab IDs — "charges" tab relabeled to "Payments" per IA-05
  defp tab_display_label("charges"), do: "Payments"
  defp tab_display_label(tab), do: humanize(tab)

  defp subscriptions(customer) do
    Subscription
    |> where([sub], sub.customer_id == ^customer.id)
    |> order_by([sub], desc: sub.inserted_at, desc: sub.id)
    |> Repo.all()
  end

  # WR-04: resolve the entitlements diagnostic ONCE into a socket assign in
  # handle_params (mirroring the :payment_methods assign in mount/3), not inside
  # the ~H template. This keeps render/1 pure (no DB round-trips per render),
  # lets CR-01's contained result be computed once and reused across unrelated
  # re-renders, and is the structural reason the failure can be contained. The
  # assign is only computed on the entitlements tab; other tabs carry `nil`
  # (never read by render, which only touches @entitlements_view inside the
  # "entitlements" case branch).
  defp assign_entitlements_view(socket, "entitlements") do
    assign(socket, :entitlements_view, entitlements_view(socket.assigns.customer))
  end

  defp assign_entitlements_view(socket, _tab) do
    assign(socket, :entitlements_view, nil)
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

  defp active_subscription_payment_method?(customer, payment_method) do
    customer
    |> subscriptions()
    |> Enum.filter(fn subscription ->
      subscription.processor == "braintree" and Subscription.active?(subscription)
    end)
    |> Enum.any?(fn subscription ->
      get_in(subscription.data || %{}, ["payment_method_token"]) == payment_method.processor_id
    end)
  end

  defp build_pending_payment_method_delete(customer, payment_method) do
    %{
      payment_method: payment_method,
      blocked_reason: payment_method_delete_blocked_reason(customer, payment_method)
    }
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

  defp blocked_reason_copy(_reason), do: Copy.customer_payment_methods_delete_warning()

  defp pending_delete_label(payment_method) do
    [
      payment_method.card_brand || payment_method.type ||
        Copy.customer_payment_methods_row_fallback_label(),
      Copy.customer_payment_methods_card_last4_mask(),
      payment_method.card_last4 || "--"
    ]
    |> Enum.join(" ")
  end

  defp refresh_customer_detail(socket) do
    customer_id = socket.assigns.customer.id

    case Customers.detail(customer_id, socket.assigns.current_owner_scope) do
      {:ok, customer} ->
        socket
        |> assign(:customer, customer)
        |> assign(:payment_methods, payment_methods(customer))
        |> assign(:tab_counts, tab_counts(customer))
        |> assign(:tax_risk, tax_risk_summary(customer))

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
      {:ok, _deleted_payment_method} = Repo.delete(persisted_payment_method)

      if socket.assigns.customer.default_payment_method_id == payment_method.id do
        # Best-effort update: the payment method is already deleted on Stripe,
        # so we don't let a changeset failure here crash the LiveView process.
        socket.assigns.customer
        |> Accrue.Billing.Customer.changeset(%{default_payment_method_id: nil})
        |> Repo.update()
        # intentionally ignoring {:error, _changeset} — best effort
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

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true

  defp timeline_items(customer) do
    customer
    |> then(&Events.timeline_for("Customer", &1.id, limit: 25))
    |> Enum.map(fn event ->
      %{
        title: event.type,
        at: format_datetime(event.inserted_at),
        body: event.subject_type <> " " <> event.subject_id,
        status: event.actor_type,
        tone: if(event.actor_type == "admin", do: :cobalt, else: :slate)
      }
    end)
  end

  defp metadata_payload(customer) do
    %{
      "metadata" => customer.metadata || %{},
      "data" => customer.data || %{},
      "default_payment_method_id" => customer.default_payment_method_id,
      "preferred_locale" => customer.preferred_locale,
      "preferred_timezone" => customer.preferred_timezone
    }
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

  defp normalize_tab("payments"), do: "charges"
  defp normalize_tab(tab) when tab in @tabs, do: tab
  defp normalize_tab(_tab), do: "subscriptions"

  defp humanize(value), do: value |> String.replace("_", " ") |> String.capitalize()

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
