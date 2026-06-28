defmodule AccrueAdmin.Live.InvoicesLive do
  @moduledoc false

  import Ecto.Query

  use Phoenix.LiveView

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Repo
  alias AccrueAdmin.BillingPresentation

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    FilterChipBar,
    FlashGroup,
    PageHeader,
    StatStrip
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Invoices

  @default_queue_status "open,uncollectible"

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
         "/invoices",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/invoices",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, invoice_summary(socket.assigns.current_owner_scope))}
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
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  def handle_params(params, _uri, socket) do
    if map_size(params) == 0 or map_only_scope?(params) do
      default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)
      to = AccrueAdmin.DataTableNav.merge_query(socket.assigns.table_path, default)

      if connected?(socket) do
        {:noreply, push_patch(socket, to: to)}
      else
        {:noreply, assign(socket, :params, default)}
      end
    else
      {:noreply, assign(socket, :params, params)}
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
        <PageHeader.page_header
          breadcrumbs={[
            %{label: Copy.dashboard_breadcrumb_home(), href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
            %{label: Copy.invoices_index_breadcrumb_invoices()}
          ]}
          title={Copy.invoices_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.invoices_list_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label={Copy.invoices_kpi_section_aria_label()}>
              <:stat label={Copy.invoices_kpi_open_label()} value={Integer.to_string(@summary.open_count)} />
              <:stat label={Copy.invoices_kpi_paid_label()} value={Integer.to_string(@summary.paid_count)} />
              <:stat
                label={Copy.invoices_kpi_uncollectible_label()}
                value={Integer.to_string(@summary.uncollectible_count)}
                tone="amber"
              />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="invoices"
              filter_fields={invoice_filter_fields()}
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
          id="invoices"
          query_module={Invoices}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="invoices"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={Copy.invoices_list_loading_label()}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          columns={[
            %{label: Copy.invoices_column_invoice(), render: &invoice_identity_cell(&1, @admin_mount_path, @current_owner_scope)},
            %{label: Copy.invoices_column_status(), render: &status_summary/1},
            %{label: Copy.invoices_column_balance(), render: &balance_summary/1},
            %{id: :collection_method, label: Copy.invoices_column_collection()},
            %{label: Copy.invoices_column_billing_signals(), render: &billing_signals_cell/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: Copy.invoices_card_customer(), render: &customer_label/1},
            %{label: Copy.invoices_column_status(), render: &status_summary/1},
            %{label: Copy.invoices_column_balance(), render: &balance_summary/1},
            %{id: :collection_method, label: Copy.invoices_column_collection()},
            %{label: Copy.invoices_column_billing_signals(), render: &billing_signals_cell/1}
          ]}
          filter_fields={invoice_filter_fields()}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={work_queue_chips(@params, @table_path)}
              label="Invoice view"
              result_count={status.visible_count}
              result_label={Copy.invoices_list_result_label_pair()}
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
    |> assign(:page_title, Copy.invoices_page_title_index())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/invoices"))
  end

  defp invoice_summary(owner_scope) do
    invoices = scoped_invoices(owner_scope)

    %{
      total_count: Repo.aggregate(invoices, :count, :id),
      open_count: count_invoices(invoices, :open),
      paid_count: count_invoices(invoices, :paid),
      uncollectible_count: count_invoices(invoices, :uncollectible),
      void_count: count_invoices(invoices, :void)
    }
  end

  defp scoped_invoices(%{mode: :organization, organization_id: organization_id}) do
    Invoice
    |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
    |> where(
      [_invoice, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scoped_invoices(_owner_scope), do: Invoice

  defp count_invoices(query, status),
    do: query |> where([invoice], invoice.status == ^status) |> Repo.aggregate(:count, :id)

  defp billing_signals_cell(row) do
    ownership = BillingPresentation.ownership_label(row)
    tax = BillingPresentation.tax_health_label(BillingPresentation.tax_health(row))
    escaped_o = ownership |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    escaped_t = tax |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(<span class="ax-chip ax-label">#{escaped_o}</span> <span class="ax-chip ax-label">#{escaped_t}</span>)
    )
  end

  defp invoice_identity_cell(row, mount_path, owner_scope) do
    invoice_href = scoped_path(mount_path, "/invoices/#{row.id}", owner_scope)
    customer_href = scoped_path(mount_path, "/customers/#{row.customer_id}", owner_scope)
    invoice_label = row.number || row.processor_id || row.id

    Phoenix.HTML.raw(
      ~s(<span class="ax-stack-xs"><a href="#{invoice_href}" class="ax-link">#{escape(invoice_label)}</a><a href="#{customer_href}" class="ax-label ax-muted">#{escape(customer_label(row))}</a></span>)
    )
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id

  defp status_summary(row) do
    [row.status, row.finalized_at && "finalized", row.due_date && "due"]
    |> Enum.reject(&is_nil/1)
    |> Enum.map_join(" · ", &humanize/1)
  end

  defp balance_summary(row) do
    due = format_money(row.amount_due_minor, row.currency)
    paid = format_money(row.amount_paid_minor, row.currency)
    remaining = format_money(row.amount_remaining_minor, row.currency)
    Copy.invoices_balance_summary(due, paid, remaining)
  end

  defp card_title(row), do: row.number || row.processor_id || row.id

  defp format_money(amount_minor, currency) when is_integer(amount_minor) do
    Accrue.Invoices.Render.format_money(
      amount_minor,
      normalize_currency(currency),
      Accrue.Config.default_locale()
    )
  end

  defp format_money(_amount_minor, _currency), do: "--"

  defp normalize_currency(currency) when is_atom(currency), do: currency

  defp normalize_currency(currency) when is_binary(currency) do
    code = String.downcase(currency)

    try do
      String.to_existing_atom(code)
    rescue
      ArgumentError -> :usd
    end
  end

  defp normalize_currency(_currency), do: :usd

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp invoice_filter_fields do
    [
      %{id: :q, label: Copy.invoices_filter_search(), placeholder: Copy.invoices_filter_search()},
      {
        :status,
        [
          label: Copy.invoices_filter_status(),
          type: :select,
          all_label: "All statuses",
          options: [
            {"draft", Copy.invoices_filter_status_draft()},
            {"open", Copy.invoices_filter_status_open()},
            {"paid", Copy.invoices_filter_status_paid()},
            {"uncollectible", Copy.invoices_filter_status_uncollectible()},
            {"void", Copy.invoices_filter_status_void()}
          ]
        ]
      },
      %{
        id: :customer_id,
        label: Copy.invoices_filter_customer_id(),
        placeholder: Copy.invoices_filter_customer_id()
      },
      %{
        id: :collection_method,
        label: Copy.invoices_filter_collection(),
        type: :segmented,
        options: [
          {"", "All"},
          {"charge_automatically", Copy.invoices_filter_collection_automatic()},
          {"send_invoice", Copy.invoices_filter_collection_send_invoice()}
        ]
      }
    ]
    |> Enum.map(fn
      {id, opts} -> Map.new(opts) |> Map.put(:id, id)
      field -> field
    end)
  end

  defp filter_params(params) do
    params
    |> Invoices.decode_filter()
    |> Invoices.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp work_queue_chips(params, table_path) do
    queue_active = Map.get(params, "status") == @default_queue_status
    all_active = Map.get(params, "view") == "all"
    clear_href = clear_all_href(params, table_path)

    filter_chips =
      params
      |> filter_params()
      |> Enum.reject(fn {key, _value} -> key == "status" and queue_active end)
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
        id: :status_queue,
        label: Copy.invoices_list_default_lens_label(),
        tone: :cobalt,
        active: queue_active,
        remove_href: if(queue_active, do: clear_href)
      },
      %{
        id: :view_all,
        label: Copy.invoices_list_all_lens_label(),
        tone: :slate,
        active: queue_active or all_active,
        href: if(queue_active, do: clear_href)
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("q"), do: Copy.invoices_filter_search()
  defp filter_chip_label("status"), do: Copy.invoices_filter_status()
  defp filter_chip_label("customer_id"), do: Copy.invoices_filter_customer_id()
  defp filter_chip_label("collection_method"), do: Copy.invoices_filter_collection()
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("status", value), do: humanize(value)

  defp filter_chip_value("collection_method", "charge_automatically"),
    do: Copy.invoices_filter_collection_automatic()

  defp filter_chip_value("collection_method", "send_invoice"),
    do: Copy.invoices_filter_collection_send_invoice()

  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "q" => nil,
      "status" => nil,
      "customer_id" => nil,
      "collection_method" => nil,
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
      queue_active?(params) -> "queue"
      filter_active?(params) -> "filter"
      true -> nil
    end
  end

  defp build_default_params(%{mode: :organization, organization_slug: slug}, status)
       when is_binary(slug) do
    %{"status" => status, "org" => slug}
  end

  defp build_default_params(_scope, status), do: %{"status" => status}

  defp queue_active?(params),
    do: Map.get(params, "status") == @default_queue_status and Map.get(params, "view") != "all"

  defp empty_title(params, summary) do
    cond do
      first_run_empty?(params, summary) -> Copy.invoices_list_first_run_empty_title()
      queue_active?(params) -> Copy.invoices_list_queue_empty_title()
      filter_active?(params) -> Copy.invoices_list_filtered_empty_title()
      true -> Copy.invoices_list_first_run_empty_title()
    end
  end

  defp empty_copy(params, summary) do
    cond do
      first_run_empty?(params, summary) -> Copy.invoices_list_first_run_empty_body()
      queue_active?(params) -> Copy.invoices_list_queue_empty_body()
      filter_active?(params) -> Copy.invoices_list_filtered_empty_body()
      true -> Copy.invoices_list_first_run_empty_body()
    end
  end

  defp first_run_empty?(params, summary),
    do: Map.get(params, "view") == "all" and summary.total_count == 0 and !filter_active?(params)

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

  defp map_only_scope?(params) do
    params != %{} and Map.keys(params) -- ["org"] == []
  end

  defp escape(value), do: value |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
