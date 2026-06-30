defmodule AccrueAdmin.Live.ChargesLive do
  @moduledoc false

  import Ecto.Query

  use Phoenix.LiveView

  alias Accrue.Billing.{Charge, Customer, Refund}
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
  alias AccrueAdmin.Queries.Charges

  @default_queue_status "failed"

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
         "/payments",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/payments",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, charge_summary(socket.assigns.current_owner_scope))}
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
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <PageHeader.page_header
          breadcrumbs={[
            %{label: Copy.dashboard_breadcrumb_home(), href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
            %{label: Copy.charges_index_heading()}
          ]}
          title={Copy.payments_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.payments_list_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label="Payment summary">
              <:stat label="Succeeded" value={Integer.to_string(@summary.succeeded_count)} />
              <:stat
                label="Fees settled"
                value={Integer.to_string(@summary.fees_settled_count)}
                tone="cobalt"
              />
              <:stat label="Refunded" value={Integer.to_string(@summary.refunded_count)} />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="payments"
              filter_fields={payment_filter_fields()}
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
          id="payments"
          query_module={Charges}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="payments"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={list_state_copy(:loading).heading}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          columns={[
            %{label: "Payment", render: &payment_identity_cell(&1, @admin_mount_path, @current_owner_scope)},
            %{label: "Status", render: &status_summary/1},
            %{label: "Amount", render: &amount_summary/1},
            %{label: "Fees", render: &fee_summary/1},
            %{label: "Billing signals", render: &billing_signals_cell/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Customer", render: &customer_label/1},
            %{label: "Status", render: &status_summary/1},
            %{label: "Amount", render: &amount_summary/1},
            %{label: "Fees", render: &fee_summary/1},
            %{label: "Billing signals", render: &billing_signals_cell/1}
          ]}
          filter_fields={payment_filter_fields()}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={work_queue_chips(@params, @table_path)}
              label="Payment view"
              result_count={status.visible_count}
              result_label={Copy.payments_list_result_label_pair()}
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
    |> assign(:page_title, Copy.charges_index_heading())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/payments"))
  end

  defp charge_summary(owner_scope) do
    charges = scoped_charges(owner_scope)

    %{
      total_count: Repo.aggregate(charges, :count, :id),
      succeeded_count: count_charges(charges, "succeeded"),
      fees_settled_count: count_fees_settled(charges),
      refunded_count: refunded_charge_count(owner_scope)
    }
  end

  defp scoped_charges(%{mode: :organization, organization_id: organization_id}) do
    Charge
    |> join(:inner, [charge], customer in Customer, on: customer.id == charge.customer_id)
    |> where(
      [_charge, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scoped_charges(_owner_scope), do: Charge

  defp count_charges(query, status),
    do: query |> where([charge, ...], charge.status == ^status) |> Repo.aggregate(:count, :id)

  defp count_fees_settled(query),
    do:
      query
      |> where([charge, ...], not is_nil(charge.fees_settled_at))
      |> Repo.aggregate(:count, :id)

  defp refunded_charge_count(owner_scope) do
    Refund
    |> join(:inner, [refund], charge in Charge, on: charge.id == refund.charge_id)
    |> join(:inner, [_refund, charge], customer in Customer,
      on: customer.id == charge.customer_id
    )
    |> scope_refunds(owner_scope)
    |> select([_refund, charge, _customer], charge.id)
    |> distinct(true)
    |> Repo.all()
    |> length()
  end

  defp scope_refunds(query, %{mode: :organization, organization_id: organization_id}) do
    where(
      query,
      [_refund, _charge, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scope_refunds(query, _owner_scope), do: query

  defp billing_signals_cell(row) do
    ownership = BillingPresentation.ownership_label(row)
    tax = BillingPresentation.tax_health_label(BillingPresentation.tax_health(row))
    escaped_o = ownership |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    escaped_t = tax |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(<span class="ax-chip ax-label">#{escaped_o}</span> <span class="ax-chip ax-label">#{escaped_t}</span>)
    )
  end

  defp payment_identity_cell(row, mount_path, owner_scope) do
    payment_href = scoped_path(mount_path, "/payments/#{row.id}", owner_scope)
    customer_href = scoped_path(mount_path, "/customers/#{row.customer_id}", owner_scope)
    payment_label = row.processor_id || row.id

    Phoenix.HTML.raw(
      ~s(<span class="ax-stack-xs"><a href="#{payment_href}" class="ax-link">#{escape(payment_label)}</a><a href="#{customer_href}" class="ax-label ax-muted">#{escape(customer_label(row))}</a></span>)
    )
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id
  defp status_summary(row), do: humanize(row.status)
  defp card_title(row), do: row.processor_id || row.id

  defp amount_summary(row) do
    format_money(row.amount_cents, row.currency)
  end

  defp fee_summary(row) do
    stripe_fee =
      case row.stripe_fee_amount_minor do
        amount when is_integer(amount) ->
          format_money(amount, row.stripe_fee_currency || row.currency)

        _ ->
          "pending"
      end

    settled = if row.fees_settled_at, do: "settled", else: "unsettled"
    "#{stripe_fee} stripe fee · #{settled}"
  end

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

  defp payment_filter_fields do
    [
      %{id: :q, label: "Search", placeholder: "Search payments"},
      {
        :status,
        [
          label: "Status",
          type: :select,
          all_label: "All statuses",
          options: [
            {"succeeded", "Succeeded"},
            {"failed", "Failed"},
            {"pending", "Pending"},
            {"refunded", "Refunded"}
          ]
        ]
      },
      %{id: :customer_id, label: "Customer id", placeholder: "Customer id"},
      %{
        id: :fees_settled,
        label: "Fees settled",
        type: :segmented,
        options: [{"", "All"}, {"true", "Settled"}, {"false", "Pending"}]
      }
    ]
    |> Enum.map(fn
      {id, opts} -> Map.new(opts) |> Map.put(:id, id)
      field -> field
    end)
  end

  defp filter_params(params) do
    params
    |> Charges.decode_filter()
    |> Charges.encode_filter()
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
        label: Copy.payments_list_default_lens_label(),
        tone: :cobalt,
        active: queue_active,
        remove_href: if(queue_active, do: clear_href)
      },
      %{
        id: :view_all,
        label: Copy.payments_list_all_lens_label(),
        tone: :slate,
        active: queue_active or all_active,
        href: if(queue_active, do: clear_href)
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("q"), do: "Search"
  defp filter_chip_label("status"), do: "Status"
  defp filter_chip_label("customer_id"), do: "Customer id"
  defp filter_chip_label("fees_settled"), do: "Fees settled"
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("status", value), do: humanize(value)
  defp filter_chip_value("fees_settled", "true"), do: "Settled"
  defp filter_chip_value("fees_settled", "false"), do: "Pending"
  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "q" => nil,
      "status" => nil,
      "customer_id" => nil,
      "fees_settled" => nil,
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

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp queue_active?(params),
    do: Map.get(params, "status") == @default_queue_status and Map.get(params, "view") != "all"

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
    cond do
      first_run_empty?(params, summary) -> :first_run_empty
      queue_active?(params) -> :queue_empty
      filter_active?(params) -> :filtered_empty
      true -> :first_run_empty
    end
  end

  defp list_state_copy(state), do: Copy.resource_state_copy(:payments, state)

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
