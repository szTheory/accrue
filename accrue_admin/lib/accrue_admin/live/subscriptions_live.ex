defmodule AccrueAdmin.Live.SubscriptionsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Query, Subscription}
  alias Accrue.Repo
  alias AccrueAdmin.Components.BillingContext

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    FilterChipBar,
    FlashGroup,
    IdBadge,
    PageHeader,
    StatStrip,
    Timestamp
  }

  alias AccrueAdmin.Components.StatusBadge
  alias AccrueAdmin.Copy
  alias AccrueAdmin.DataTableNav
  alias AccrueAdmin.Queries.Subscriptions
  alias AccrueAdmin.ScopedPath

  @default_queue_status "past_due,canceling"

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
         "/subscriptions",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/subscriptions",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, subscription_summary(socket.assigns.current_owner_scope))}
  end

  @impl true
  def handle_event("data_table_filter", params, socket) do
    params =
      params
      |> Map.drop(["_target", "_csrf_token"])
      |> Map.update("status", nil, &Subscriptions.normalize_status_selection/1)

    params = if is_nil(params["status"]), do: Map.put(params, "view", "all"), else: params

    {:noreply,
     AccrueAdmin.DataTableNav.patch_with_filters(
       socket,
       socket.assigns.table_path,
       params
     )}
  end

  @impl true
  def handle_params(%{"cursor" => cursor} = params, _uri, socket) do
    if Subscriptions.cursor_valid?(cursor, params, socket.assigns.current_owner_scope) do
      {:noreply, assign(socket, :params, params)}
    else
      to =
        socket.assigns.table_path
        |> DataTableNav.merge_query(Map.drop(params, ["cursor", "org"]))

      {:noreply,
       socket
       |> put_flash(
         :info,
         "That saved page position expired. Showing the first page with the same filters."
       )
       |> push_patch(to: to)}
    end
  end

  @impl true
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    assign_canonical_params(socket, params)
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
      assign_canonical_params(socket, params)
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
        <.subscriptions_collection
          admin_mount_path={@admin_mount_path}
          current_owner_scope={@current_owner_scope}
          table_path={@table_path}
          params={@params}
          summary={@summary}
          flash={@flash}
          query_module={Subscriptions}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  attr(:admin_mount_path, :string, default: "/billing")
  attr(:current_owner_scope, :map, required: true)
  attr(:table_path, :string, required: true)
  attr(:params, :map, default: %{})
  attr(:summary, :map, required: true)
  attr(:flash, :map, default: %{})
  attr(:query_module, :atom, default: nil)
  attr(:limit, :integer, default: nil)

  def subscriptions_collection(assigns) do
    assigns = assign(assigns, :query_module, assigns[:query_module] || Subscriptions)

    ~H"""
    <PageHeader.page_header
      breadcrumb_group="Billing"
      breadcrumbs={[
        %{label: Copy.subscriptions_index_breadcrumb()}
      ]}
      title={Copy.subscriptions_index_breadcrumb()}
    >
      <:description>
        <p class="ax-body"><%= Copy.subscriptions_route_line() %></p>
      </:description>
      <:stat_strip>
        <StatStrip.stat_strip label={Copy.subscriptions_kpi_section_aria_label()}>
          <:stat label="Subscriptions" value={to_string(@summary.total_count)} />
          <:stat label="Past due" value={to_string(@summary.past_due_count)} tone={if @summary.past_due_count > 0, do: "amber"} />
          <:stat label="Ending" value={to_string(@summary.canceling_count)} />
        </StatStrip.stat_strip>
      </:stat_strip>
      <:filter_toolbar>
        <DataTable.filter_toolbar
          id="subscriptions"
          filter_fields={subscription_filter_fields()}
          filter_params={filter_params(@params)}
          path={@table_path}
          clear_href={@table_path}
          clear_visible={reset_visible?(@params, @summary)}
        />
      </:filter_toolbar>
    </PageHeader.page_header>

    <FlashGroup.flash_group flashes={flash_messages(@flash)} />

    <.live_component
      module={DataTable}
      row_label={Copy.subscriptions_list_result_label_pair()}
      id="subscriptions"
      query_module={@query_module}
      current_owner_scope={@current_owner_scope}
      path={@table_path}
      params={@params}
      list_id="subscriptions"
      list_state={list_state(@params, @summary)}
      empty_reason={empty_reason(@params, @summary)}
      loading_fixture={phase196_loading_fixture?(@params)}
      loading_label={list_state_copy(:loading).heading}
      render_filter_toolbar={false}
      clear_href={@table_path}
      limit={@limit}
      columns={[
        %{width: 34,
          label: "Subscription",
          render: &identity_cell(&1, @admin_mount_path, @current_owner_scope, @params, :table)
        },
        %{width: 14, label: "Status", render: &state_cell/1},
        %{width: 18, label: "Plan", render: &plan_amount_cell/1},
        %{width: 18, label: "Renews / ends", render: fn row -> time_cell(row, :table) end},
        %{width: 16,
          label: Copy.billing_owner_tax_label(),
          render: &billing_signals_cell(&1, @admin_mount_path, @current_owner_scope)
        }
      ]}
      card_title={&identity_cell(&1, @admin_mount_path, @current_owner_scope, @params, :card)}
      card_fields={[
        %{label: "Status", render: &state_cell/1},
        %{label: "Plan", render: &plan_amount_cell/1},
        %{label: "Renews / ends", render: fn row -> time_cell(row, :card) end},
        %{
          label: Copy.billing_owner_tax_label(),
          render: &billing_signals_cell(&1, @admin_mount_path, @current_owner_scope)
        }
      ]}
      filter_fields={subscription_filter_fields()}
      empty_action_href={if empty_reason(@params, @summary) == "queue", do: clear_all_href(@params, @table_path), else: @table_path}
      empty_action_label={if empty_reason(@params, @summary) == "queue", do: "View all " <> elem(Copy.subscriptions_list_result_label_pair(), 1), else: "Reset filters"}
      empty_title={empty_title(@params, @summary)}
      empty_copy={empty_copy(@params, @summary)}
      filtered_empty_title={empty_title(@params, @summary)}
      filtered_empty_copy={empty_copy(@params, @summary)}
    >
      <:list_status :let={status}>
        <DataTable.view_nav label="Subscription view" items={[
          %{label: "Past due or ending", current: queue_active?(@params), href: view_href(@params, @table_path, default_queue_status())},
          %{label: "All subscriptions", current: is_nil(@params["status"]), href: view_href(@params, @table_path, nil)}
        ]} />
        <FilterChipBar.filter_chip_bar
          items={work_queue_chips(@params, @table_path, @summary)}
          label="Work queue" compact={true}
          result_count={status.visible_count}
          result_label={Copy.subscriptions_list_result_label_pair()}
          clear_all_label={Copy.data_table_clear_filters_label()}
        />
      </:list_status>
    </.live_component>
    """
  end

  defp default_queue_status, do: @default_queue_status

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, Copy.subscriptions_index_breadcrumb())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/subscriptions"))
  end

  defp subscription_summary(owner_scope) do
    subscriptions = scoped_subscriptions(owner_scope)

    %{
      active_count: subscriptions |> Query.active() |> Repo.aggregate(:count, :id),
      canceling_count: subscriptions |> Query.canceling() |> Repo.aggregate(:count, :id),
      paused_count: subscriptions |> Query.paused() |> Repo.aggregate(:count, :id),
      past_due_count: subscriptions |> Query.past_due() |> Repo.aggregate(:count, :id),
      total_count: subscriptions |> Repo.aggregate(:count, :id)
    }
  end

  defp scoped_subscriptions(%{mode: :organization, organization_id: organization_id}) do
    Subscription
    |> join(:inner, [subscription], customer in assoc(subscription, :customer))
    |> where(
      [_subscription, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scoped_subscriptions(_owner_scope), do: Subscription

  defp billing_signals_cell(row, _mount_path, _owner_scope) do
    assigns = %{row: row}

    ~H"""
    <BillingContext.billing_context row={@row} />
    """
  end

  # Primary link resolves to the subscription's own detail page (D-01's literal href
  # mandate) with customer-first TEXT for scannability; secondary link cross-navigates to
  # the customer (mirrors invoices_live.ex's bidirectional identity-cell pattern).
  defp identity_cell(row, mount_path, owner_scope, params, surface) do
    list_path =
      mount_path
      |> scoped_path("/subscriptions", owner_scope)
      |> DataTableNav.merge_query(params)

    return_to = ScopedPath.return_path(mount_path, list_path, owner_scope)

    subscription_href =
      ScopedPath.build(mount_path, "/subscriptions/#{row.id}", owner_scope, %{
        "return_to" => return_to
      })

    customer_href =
      ScopedPath.build(mount_path, "/customers/#{row.customer_id}", owner_scope, %{
        "return_to" => return_to
      })

    subscription_id = row.processor_id || row.id

    assigns = %{
      customer_href: customer_href,
      customer_label: customer_label(row),
      subscription_href: subscription_href,
      badge_id: "ax-id-badge-subscription-#{surface}-#{row.id}",
      subscription_id: subscription_id
    }

    ~H"""
    <DataTable.identity_cell label={@customer_label}>
      <:primary><.link href={@subscription_href} class="ax-link"><%= @customer_label %></.link></:primary>
      <:secondary>
        <IdBadge.id_badge id={@badge_id} id_value={to_string(@subscription_id)} label="Copy subscription ID" copy_label="subscription ID" variant="plain" />
        <.link href={@customer_href} class="ax-label ax-muted" aria-label={"Customer details for #{@customer_label}"}>Customer details</.link>
      </:secondary>
    </DataTable.identity_cell>
    """
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id

  defp state_cell(row) do
    {status, label} = lifecycle_status(row)

    assigns = %{
      status: status,
      label: label,
      tone: status_tone(status),
      canceling: row.cancel_at_period_end and not Subscription.canceled?(row)
    }

    ~H"""
    <span class="ax-data-table-value">
      <StatusBadge.status_badge status={@status} label={@label} tone={@tone} />
      <span :if={@canceling} class="ax-data-table-value-detail">Cancellation scheduled</span>
    </span>
    """
  end

  defp lifecycle_status(row) do
    cond do
      row.status == :incomplete_expired -> {:neutral, "Incomplete expired"}
      Subscription.canceled?(row) -> {:neutral, "Canceled"}
      row.status == :unpaid -> {:warning, "Unpaid"}
      Subscription.past_due?(row) -> {:warning, "Past due"}
      row.status == :incomplete -> {:warning, "Incomplete"}
      Subscription.trialing?(row) -> {:trialing, "Trialing"}
      row.status == :paused -> {:neutral, "Paused"}
      Subscription.active?(row) -> {:active, "Active"}
      true -> {row.status, humanize(row.status)}
    end
  end

  defp status_tone(status) when status in [:active, :success, :ok], do: "moss"
  defp status_tone(status) when status in [:trialing, :info], do: "cobalt"
  defp status_tone(status) when status in [:warning, :past_due, :unpaid], do: "amber"
  defp status_tone(status) when status in [:neutral, :canceled, :paused], do: "slate"
  defp status_tone(_status), do: "ink"

  defp plan_amount_cell(%{plan_price_id: price_id} = row) when is_binary(price_id) do
    quantity = integerish(row[:plan_quantity]) || 1
    item_count = integerish(row[:plan_item_count]) || 1

    plan_context =
      [
        price_id,
        quantity > 1 && "qty #{quantity}",
        item_count > 1 && "#{item_count} items"
      ]
      |> Enum.reject(&(&1 in [false, nil, ""]))
      |> Enum.join(" · ")

    evidence_cell(plan_context, "Amount unavailable")
  end

  defp plan_amount_cell(%{cancel_at_period_end: true}),
    do: evidence_cell("Renewal ending", "Price unavailable")

  defp plan_amount_cell(_row),
    do: evidence_cell("Plan unavailable", "Amount unavailable")

  defp evidence_cell(context, detail) do
    assigns = %{value: context, detail: detail}

    ~H"""
    <DataTable.value_cell value={@value} detail={@detail} />
    """
  end

  defp time_cell(%{ended_at: %DateTime{} = ended_at} = row, surface),
    do: timestamp_cell("Ended", ended_at, row.id, surface)

  defp time_cell(%{ended_at: ended_at}, _surface) when not is_nil(ended_at),
    do: "Ended #{to_string(ended_at)}"

  defp time_cell(
         %{cancel_at_period_end: true, current_period_end: %DateTime{} = ends_at} = row,
         surface
       ),
       do: timestamp_cell("Ends", ends_at, row.id, surface)

  defp time_cell(%{cancel_at_period_end: true}, _surface),
    do: "Cancellation scheduled · end date not shown"

  defp time_cell(%{current_period_end: %DateTime{} = renews_at} = row, surface),
    do: timestamp_cell("Renews", renews_at, row.id, surface)

  defp time_cell(%{trial_end: %DateTime{} = trial_end} = row, surface),
    do: timestamp_cell("Trial ends", trial_end, row.id, surface)

  defp time_cell(_row, _surface), do: "Renewal date not shown"

  defp timestamp_cell(label, value, row_id, surface) do
    assigns = %{label: label, value: value, id: "subscription-#{surface}-time-#{row_id}"}

    ~H"""
    <span><%= @label %> <Timestamp.timestamp value={@value} id={@id} format={:date} /></span>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end

  defp integerish(%Decimal{} = value), do: Decimal.to_integer(value)
  defp integerish(value) when is_integer(value), do: value
  defp integerish(_value), do: nil

  defp subscription_filter_fields do
    [
      %{
        id: :q,
        label: "Search subscriptions",
        placeholder: "Customer name, email, or ID"
      },
      {
        :status,
        [
          label: "Status",
          type: :checkbox_group,
          options: [
            {"active", "Active"},
            {"trialing", "Trialing"},
            {"canceling", "Canceling"},
            {"paused", "Paused"},
            {"past_due", "Past due"},
            {"canceled", "Canceled"}
          ]
        ]
      },
      %{
        id: :customer_id,
        label: "Customer ID",
        placeholder: "Customer ID",
        secondary: true
      }
    ]
    |> Enum.map(fn
      {id, opts} -> Map.new(opts) |> Map.put(:id, id)
      field -> field
    end)
  end

  defp filter_params(params) do
    params
    |> Subscriptions.decode_filter()
    |> Subscriptions.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp assign_canonical_params(socket, params) do
    canonical =
      case Map.get(params, "status") do
        nil ->
          params

        status ->
          case Subscriptions.normalize_status_selection(status) do
            nil -> Map.delete(params, "status")
            normalized -> Map.put(params, "status", normalized)
          end
      end

    if connected?(socket) and canonical != params do
      {:noreply,
       Phoenix.LiveView.push_patch(socket,
         to: AccrueAdmin.DataTableNav.merge_query(socket.assigns.table_path, canonical)
       )}
    else
      {:noreply, assign(socket, :params, canonical)}
    end
  end

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
  end

  defp work_queue_chips(params, table_path, _summary) do
    queue_active = Map.get(params, "status") == @default_queue_status

    filters =
      params
      |> filter_params()
      |> Enum.reject(fn {key, _} -> key == "status" and queue_active end)
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

    filters
  end

  defp filter_chip_label("q"), do: "Search"
  defp filter_chip_label("status"), do: "Status"
  defp filter_chip_label("customer_id"), do: "Customer"
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("status", value),
    do: value |> String.split(",") |> Enum.map_join(", ", &humanize/1)

  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "q" => nil,
      "status" => nil,
      "customer_id" => nil,
      "cursor" => nil,
      "phase196_state" => nil
    })
  end

  defp reset_visible?(params, summary) do
    filter_params(params) != %{"status" => @default_queue_status} and
      (filter_active?(params) or (params["view"] == "all" and summary.total_count > 0))
  end

  defp filter_active?(params), do: filter_params(params) != %{}

  defp view_href(params, path, status) do
    params =
      params
      |> Map.drop(["cursor", "phase196_state"])
      |> Map.put("status", status)
      |> Map.put("view", if(is_nil(status), do: "all"))

    AccrueAdmin.DataTableNav.merge_query(path, params)
  end

  defp list_state(params, _summary) do
    if phase196_loading_fixture?(params), do: "loading-skeleton", else: nil
  end

  defp empty_reason(params, summary) do
    cond do
      phase196_loading_fixture?(params) -> nil
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

  # Queue-context-aware empty states (IA-03 contract).
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

  defp list_state_copy(state), do: Copy.resource_state_copy(:subscriptions, state)

  defp first_run_empty?(params, summary),
    do: Map.get(params, "view") == "all" and summary.total_count == 0 and !filter_active?(params)

  defp phase196_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase196_state") == "loading-skeleton"
  end

  defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

  defp map_only_scope?(params) do
    params != %{} and Map.keys(params) -- ["org"] == []
  end

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(_value), do: "Unknown"

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
