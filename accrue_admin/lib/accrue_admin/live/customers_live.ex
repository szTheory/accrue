defmodule AccrueAdmin.Live.CustomersLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.Customer
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    FilterChipBar,
    FlashGroup,
    IdBadge,
    PageHeader,
    StatStrip
  }

  alias AccrueAdmin.Copy
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
     |> assign(:summary, customer_summary(socket.assigns.current_owner_scope))
     |> assign_owner_type_filter(
       Customers.distinct_owner_types(socket.assigns.current_owner_scope)
     )}
  end

  # owner_type cardinality is data-driven: with <= 3 distinct owner types a segmented
  # toggle reads best (prepend an "All" segment); beyond that fall back to a select.
  defp assign_owner_type_filter(socket, owner_type_options) do
    owner_type_type = if length(owner_type_options) <= 3, do: :segmented, else: :select

    owner_type_options =
      if owner_type_type == :segmented do
        [{"", "All"} | owner_type_options]
      else
        owner_type_options
      end

    socket
    |> assign(:owner_type_options, owner_type_options)
    |> assign(:owner_type_type, owner_type_type)
  end

  @impl true
  def handle_event("data_table_filter", params, socket) do
    {:noreply,
     AccrueAdmin.DataTableNav.patch_with_filters(
       socket,
       socket.assigns.table_path,
       Map.drop(params, ["_target", "_csrf_token"])
     )}
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
    active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <PageHeader.page_header
          breadcrumbs={[
            %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
            %{label: Copy.customers_index_heading()}
          ]}
          title={Copy.customers_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.customers_list_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label="Customer summary">
              <:stat label="Customers" value={Integer.to_string(@summary.customer_count)} />
              <:stat
                label="With payment method"
                value={Integer.to_string(@summary.with_default_payment_method_count)}
              />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="customers"
              filter_fields={customer_filter_fields(@owner_type_type, @owner_type_options)}
              filter_params={filter_params(@params)}
              path={@table_path}
              clear_href={clear_all_href(@params, @table_path)}
              clear_visible={filter_active?(@params)}
            />
          </:filter_toolbar>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={flash_messages(@flash)} />

        <.live_component
          module={DataTable}
          id="customers"
          query_module={Customers}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="customers"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={list_state_copy(:loading).heading}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          columns={[
            %{label: "Customer", render: &customer_link(&1, @admin_mount_path, @current_owner_scope)},
            %{label: "Payment method", render: &default_payment_method_label/1},
            %{label: "ID", render: &id_badge_cell(&1, "table")}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Payment method", render: &default_payment_method_label/1},
            %{label: "ID", render: &id_badge_cell(&1, "card")}
          ]}
          filter_fields={customer_filter_fields(@owner_type_type, @owner_type_options)}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
          table_caption={Copy.customers_index_table_caption()}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={customer_lens_chips(@params, @table_path)}
              label="Customer view"
              result_count={status.visible_count}
              result_label={Copy.customers_list_result_label_pair()}
              clear_all_href={active_clear_all_href(@params, @table_path)}
              clear_all_label={Copy.data_table_clear_filters_label()}
            />
          </:list_status>
        </.live_component>
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
        |> Repo.aggregate(:count, :id)
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

  # Customer cell: primary name/identifier as a link, with email stacked beneath it
  # so the column reads as a find-and-open target (name + contact at a glance).
  defp customer_link(row, mount_path, owner_scope) do
    label = row.name || row.email || row.processor_id || row.id
    href = scoped_path(mount_path, "/customers/#{row.id}", owner_scope)
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    email_line =
      if row.email && row.email != label do
        escaped_email = row.email |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
        ~s(<span class="ax-body ax-text-muted ax-type-code-xs">#{escaped_email}</span>)
      else
        ""
      end

    Phoenix.HTML.raw(
      ~s(<span class="ax-stack-xs"><a href="#{href}" class="ax-link">#{escaped}</a>#{email_line}</span>)
    )
  end

  # Click-to-copy processor (or local) id chip, rendered via the shared IdBadge
  # component. A unique DOM id per row gives each chip its own Clipboard hook
  # instance, so copy keeps working on infinite-scroll-appended/filter-re-rendered rows.
  defp id_badge_cell(row, surface) do
    id_value = row.processor_id || to_string(row.id)

    assigns = %{
      __changed__: %{},
      dom_id: "ax-id-badge-#{surface}-#{row.id}",
      id_value: id_value
    }

    ~H"""
    <IdBadge.id_badge id={@dom_id} id_value={@id_value} />
    """
  end

  defp default_payment_method_label(%{default_payment_method_id: nil}), do: "Missing"
  defp default_payment_method_label(%{default_payment_method_id: _id}), do: "On file"

  defp card_title(row), do: row.name || row.email || row.processor_id || row.id

  defp customer_filter_fields(owner_type_type, owner_type_options) do
    [
      %{id: :q, label: "Search", placeholder: "Search customers"},
      %{
        id: :owner_type,
        label: "Owner type",
        type: owner_type_type,
        all_label: "All owner types",
        options: owner_type_options
      },
      %{
        id: :has_default_payment_method,
        label: "Payment method",
        type: :segmented,
        options: [{"", "All"}, {"true", "On file"}, {"false", "Missing"}]
      }
    ]
  end

  defp filter_params(params) do
    params
    |> Customers.decode_filter()
    |> Customers.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp customer_lens_chips(params, table_path) do
    missing_payment_active? = Map.get(params, "has_default_payment_method") == "false"
    clear_href = clear_all_href(params, table_path)

    filter_chips =
      params
      |> filter_params()
      |> Enum.reject(fn {key, value} ->
        key == "has_default_payment_method" and value == "false"
      end)
      |> Enum.map(fn {key, value} ->
        %{
          id: String.to_atom(key),
          label: filter_chip_label(key),
          value: filter_chip_value(key, value),
          tone: :slate,
          active: true,
          remove_href: AccrueAdmin.DataTableNav.merge_query(table_path, %{key => nil})
        }
      end)

    [
      %{
        id: :all_customers,
        label: Copy.customers_list_all_lens_label(),
        tone: if(missing_payment_active?, do: :slate, else: :cobalt),
        active: true,
        href: if(missing_payment_active?, do: clear_href, else: nil)
      },
      %{
        id: :missing_payment_method,
        label: Copy.customers_list_missing_payment_method_label(),
        tone: :amber,
        active: true,
        href:
          if missing_payment_active? do
            nil
          else
            AccrueAdmin.DataTableNav.merge_query(table_path, %{
              "has_default_payment_method" => "false",
              "cursor" => nil,
              "phase197_state" => nil
            })
          end,
        remove_href:
          if missing_payment_active? do
            AccrueAdmin.DataTableNav.merge_query(table_path, %{
              "has_default_payment_method" => nil,
              "cursor" => nil,
              "phase197_state" => nil
            })
          end
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("q"), do: "Search"
  defp filter_chip_label("owner_type"), do: "Owner type"
  defp filter_chip_label("has_default_payment_method"), do: "Payment method"
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("has_default_payment_method", "true"), do: "On file"
  defp filter_chip_value("has_default_payment_method", "false"), do: "Missing"
  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => nil,
      "q" => nil,
      "owner_type" => nil,
      "has_default_payment_method" => nil,
      "cursor" => nil,
      "phase197_state" => nil
    })
  end

  defp filter_active?(params), do: filter_params(params) != %{}

  defp active_clear_all_href(params, table_path) do
    if filter_active?(params), do: clear_all_href(params, table_path)
  end

  defp list_state(params) do
    if phase197_loading_fixture?(params), do: "loading-skeleton", else: nil
  end

  defp empty_reason(params, summary) do
    cond do
      phase197_loading_fixture?(params) -> nil
      first_run_empty?(params, summary) -> "first-run"
      filter_active?(params) -> "filter"
      true -> nil
    end
  end

  defp empty_title(params, summary) do
    params
    |> empty_state(summary)
    |> list_state_copy()
    |> Map.fetch!(:heading)
  end

  defp empty_copy(params, summary) do
    params
    |> empty_state(summary)
    |> list_state_copy()
    |> Map.fetch!(:body)
  end

  defp empty_state(params, summary) do
    if first_run_empty?(params, summary), do: :first_run_empty, else: :filtered_empty
  end

  defp list_state_copy(state), do: Copy.resource_state_copy(:customers, state)

  defp first_run_empty?(params, summary),
    do: summary.customer_count == 0 and !filter_active?(params)

  defp phase197_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase197_state") == "loading-skeleton"
  end

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

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
