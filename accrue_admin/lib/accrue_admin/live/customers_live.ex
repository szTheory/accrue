defmodule AccrueAdmin.Live.CustomersLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.Customer
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, FlashGroup, KpiCard}
  alias AccrueAdmin.Queries.Customers

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(
       :current_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/customers",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/customers",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, customer_summary(socket.assigns.current_owner_scope))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
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
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
              %{label: "Customers"}
            ]}
          />
          <p class="ax-eyebrow">Customers</p>
          <h2 class="ax-display">Searchable customer projections</h2>
          <p class="ax-body ax-page-copy">
            Customer rows come from the shared admin query layer and stay backed by local billing
            projections only.
          </p>
        </header>

        <FlashGroup.flash_group flashes={flash_messages(@flash)} />

        <section class="ax-kpi-grid" aria-label="Customer summary">
          <KpiCard.kpi_card label="Customers" value={Integer.to_string(@summary.customer_count)}>
            <:meta>All local customer records</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="With payment method"
            value={Integer.to_string(@summary.with_default_payment_method_count)}
          >
            <:meta>Default payment method present</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Owner types" value={Integer.to_string(@summary.owner_type_count)}>
            <:meta>Distinct host billable types</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="customers"
          query_module={Customers}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Customer", render: &customer_link(&1, @admin_mount_path, @current_owner_scope)},
            %{id: :owner_type, label: "Owner type"},
            %{id: :owner_id, label: "Owner id"},
            %{id: :processor_id, label: "Processor id"},
            %{label: "Default PM", render: &default_payment_method_label/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{id: :owner_type, label: "Owner type"},
            %{id: :owner_id, label: "Owner id"},
            %{label: "Default PM", render: &default_payment_method_label/1}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{id: :owner_type, label: "Owner type"},
            %{
              id: :has_default_payment_method,
              label: "Default PM",
              type: :select,
              options: [{"true", "On file"}, {"false", "Missing"}]
            }
          ]}
          empty_title="No customers matched"
          empty_copy="Adjust the customer filters or wait for the next local billing sync."
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Customers")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/customers"))
  end

  defp customer_summary(owner_scope) do
    customers = scoped_customers(owner_scope)

    %{
      customer_count: Repo.aggregate(customers, :count, :id),
      with_default_payment_method_count:
        customers
        |> where([customer], not is_nil(customer.default_payment_method_id))
        |> Repo.aggregate(:count, :id),
      owner_type_count:
        customers
        |> select([customer], count(fragment("distinct ?", customer.owner_type)))
        |> Repo.one()
    }
  end

  defp scoped_customers(%{mode: :organization, organization_id: organization_id}) do
    Customer
    |> where(
      [customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scoped_customers(_owner_scope), do: Customer

  defp customer_link(row, mount_path, owner_scope) do
    label =
      row.name || row.email || row.processor_id || row.id

    href = scoped_path(mount_path, "/customers/#{row.id}", owner_scope)
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp default_payment_method_label(%{default_payment_method_id: nil}), do: "Missing"
  defp default_payment_method_label(%{default_payment_method_id: id}), do: "On file (#{id})"

  defp card_title(row), do: row.name || row.email || row.processor_id || row.id

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
