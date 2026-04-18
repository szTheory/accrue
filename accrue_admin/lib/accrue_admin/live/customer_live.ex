defmodule AccrueAdmin.Live.CustomerLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Charge, Invoice, PaymentMethod, Subscription}
  alias Accrue.Events
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Customers

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    JsonViewer,
    KpiCard,
    MoneyFormatter,
    Tabs,
    TaxOwnershipCard,
    Timeline
  }

  alias AccrueAdmin.TaxOwnershipRow

  @tabs ~w(subscriptions invoices charges payment_methods events metadata)
  @owner_access_denied "You don't have access to billing for this organization."

  @impl true
  def mount(%{"id" => customer_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Customers.detail(customer_id, socket.assigns.current_owner_scope) do
      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, @owner_access_denied)
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
         |> assign(:params, %{})
         |> assign(:tab, "subscriptions")
         |> assign(:tab_counts, tab_counts(customer))}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tab =
      params
      |> Map.get("tab", "subscriptions")
      |> normalize_tab()

    {:noreply, socket |> assign(:params, params) |> assign(:tab, tab)}
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
        <header class="ax-page-header">
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
          <p class="ax-eyebrow">Customer detail</p>
          <h2 class="ax-display"><%= customer_label(@customer) %></h2>
          <p class="ax-body ax-page-copy">
            <%= @customer.processor_id %> · locale <%= @customer.preferred_locale || "--" %> · timezone <%= @customer.preferred_timezone || "--" %>
          </p>
        </header>

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
            label="Charges"
            value={Integer.to_string(@tab_counts.charges)}
            delta={Integer.to_string(@tab_counts.invoices) <> " invoices"}
            delta_tone="slate"
          >
            <:meta>Charges and invoices tied to this customer</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Tax risk"
            value={tax_risk_summary(@customer).headline}
            delta={tax_risk_summary(@customer).detail}
            delta_tone={tax_risk_summary(@customer).tone}
          >
            <:meta>Derived from projected subscriptions and invoices only</:meta>
          </KpiCard.kpi_card>
        </section>

        <TaxOwnershipCard.tax_ownership_card row={TaxOwnershipRow.from_customer(@customer)} />

        <Tabs.tabs tabs={tabs(@customer, @admin_mount_path, @tab_counts, @current_owner_scope)} active={@tab} />

        <%= case @tab do %>
          <% "subscriptions" -> %>
            <section class="ax-card">
              <h3 class="ax-heading">Subscriptions</h3>
              <div :for={subscription <- subscriptions(@customer)} class="ax-list-row">
                <a
                  href={scoped_mount_path(@admin_mount_path, "/subscriptions/" <> subscription.id, @current_owner_scope)}
                  class="ax-link"
                >
                  <%= subscription.processor_id %>
                </a>
                <span class="ax-body"><%= predicate_summary(subscription) %></span>
              </div>
              <p :if={subscriptions(@customer) == []} class="ax-body">No subscriptions for this customer.</p>
            </section>

          <% "invoices" -> %>
            <section class="ax-card">
              <h3 class="ax-heading">Invoices</h3>
              <div :for={invoice <- invoices(@customer)} class="ax-list-row">
                <span class="ax-body"><%= invoice.number || invoice.processor_id || invoice.id %></span>
                <MoneyFormatter.money_formatter amount_minor={invoice.amount_remaining_minor || 0} currency={invoice.currency || "usd"} customer={@customer} />
              </div>
              <p :if={invoices(@customer) == []} class="ax-body">No invoices projected yet.</p>
            </section>

          <% "charges" -> %>
            <section class="ax-card">
              <h3 class="ax-heading">Charges</h3>
              <div :for={charge <- charges(@customer)} class="ax-list-row">
                <span class="ax-body"><%= charge.processor_id || charge.id %> · <%= charge.status %></span>
                <MoneyFormatter.money_formatter amount_minor={charge.amount_cents || 0} currency={charge.currency || "usd"} customer={@customer} />
              </div>
              <p :if={charges(@customer) == []} class="ax-body">No charges projected yet.</p>
            </section>

          <% "payment_methods" -> %>
            <section class="ax-card">
              <h3 class="ax-heading">Payment methods</h3>
              <div :for={payment_method <- payment_methods(@customer)} class="ax-list-row">
                <span class="ax-body"><%= payment_method.card_brand || payment_method.type || "Payment method" %> ·•••• <%= payment_method.card_last4 || "--" %></span>
                <span class="ax-body"><%= expiry(payment_method) %></span>
              </div>
              <p :if={payment_methods(@customer) == []} class="ax-body">No payment methods on file.</p>
            </section>

          <% "events" -> %>
            <section class="ax-card">
              <h3 class="ax-heading">Events</h3>
              <Timeline.timeline
                label="Customer events"
                empty_label="No customer-scoped events yet"
                items={timeline_items(@customer)}
              />
            </section>

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
        label: humanize(tab),
        href:
          scoped_mount_path(mount_path, "/customers/#{customer.id}", owner_scope, %{
            "tab" => tab
          }),
        count: Map.get(counts, String.to_existing_atom(tab))
      }
    end)
  end

  defp subscriptions(customer) do
    Subscription
    |> where([sub], sub.customer_id == ^customer.id)
    |> order_by([sub], desc: sub.inserted_at, desc: sub.id)
    |> Repo.all()
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
    |> order_by([payment_method], desc: payment_method.inserted_at, desc: payment_method.id)
    |> Repo.all()
  end

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
