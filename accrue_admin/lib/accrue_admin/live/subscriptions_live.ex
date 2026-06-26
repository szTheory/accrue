defmodule AccrueAdmin.Live.SubscriptionsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Query, Subscription}
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
  alias AccrueAdmin.Queries.Subscriptions

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
            %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
            %{label: "Subscriptions"}
          ]}
          title={Copy.subscriptions_index_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.subscriptions_index_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label="Subscription summary">
              <:stat label="Active" value={Integer.to_string(@summary.active_count)} />
              <:stat
                label="Canceling"
                value={Integer.to_string(@summary.canceling_count)}
                tone="amber"
              />
              <:stat label="Paused" value={Integer.to_string(@summary.paused_count)} tone="amber" />
              <:stat label="Past due" value={Integer.to_string(@summary.past_due_count)} />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="subscriptions"
              filter_fields={subscription_filter_fields()}
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
          id="subscriptions"
          query_module={Subscriptions}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          columns={[
            %{
              label: "Subscription",
              render: &subscription_link(&1, @admin_mount_path, @current_owner_scope)
            },
            %{label: "Customer", render: &customer_link(&1, @admin_mount_path, @current_owner_scope)},
            %{label: "Billing signals", render: &billing_signals_cell/1},
            %{label: "Lifecycle", render: &lifecycle_summary/1},
            %{id: :current_period_end, label: "Current period end"}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Customer", render: &customer_label/1},
            %{label: "Billing signals", render: &billing_signals_cell/1},
            %{label: "Lifecycle", render: &lifecycle_summary/1},
            %{id: :current_period_end, label: "Current period end"}
          ]}
          filter_fields={subscription_filter_fields()}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={work_queue_chips(@params, @table_path)}
              label="Work queue"
              result_count={status.visible_count}
              result_label={{"subscription", "subscriptions"}}
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
    |> assign(:page_title, "Subscriptions")
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

  defp billing_signals_cell(row) do
    ownership = BillingPresentation.ownership_label(row)
    tax = BillingPresentation.tax_health_label(BillingPresentation.tax_health(row))
    escaped_o = ownership |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    escaped_t = tax |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(<span class="ax-chip ax-label">#{escaped_o}</span> <span class="ax-chip ax-label">#{escaped_t}</span>)
    )
  end

  defp subscription_link(row, mount_path, owner_scope),
    do:
      safe_link(
        scoped_path(mount_path, "/subscriptions/#{row.id}", owner_scope),
        row.processor_id || row.id
      )

  defp customer_link(row, mount_path, owner_scope),
    do:
      safe_link(
        scoped_path(mount_path, "/customers/#{row.customer_id}", owner_scope),
        customer_label(row)
      )

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id

  defp lifecycle_summary(row) do
    row
    |> lifecycle_flags()
    |> Enum.join(" · ")
  end

  defp lifecycle_flags(row) do
    [
      row.status && to_string(row.status),
      row.cancel_at_period_end && "cancel at period end",
      row.ended_at && "ended"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == false))
  end

  defp card_title(row), do: row.processor_id || row.id

  defp subscription_filter_fields do
    [
      %{id: :q, label: "Search", placeholder: "Search subscriptions"},
      %{
        id: :status,
        label: "Status",
        type: :select,
        all_label: "All statuses",
        options: [
          {"active", "Active"},
          {"trialing", "Trialing"},
          {"canceling", "Canceling"},
          {"paused", "Paused"},
          {"past_due", "Past due"},
          {"canceled", "Canceled"}
        ]
      },
      %{id: :customer_id, label: "Customer id", placeholder: "Customer id"}
    ]
  end

  defp filter_params(params) do
    params
    |> Subscriptions.decode_filter()
    |> Subscriptions.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
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
        label: "At risk",
        tone: :cobalt,
        active: queue_active,
        remove_href: if(queue_active, do: clear_href, else: nil)
      },
      %{
        id: :view_all,
        label: "All",
        tone: :slate,
        active: queue_active or all_active,
        href: if(queue_active, do: clear_href, else: nil)
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("q"), do: "Search"
  defp filter_chip_label("status"), do: "Status"
  defp filter_chip_label("customer_id"), do: "Customer"
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("status", value), do: humanize(value)
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

  defp filter_active?(params), do: filter_params(params) != %{}

  defp active_clear_all_href(params, table_path) do
    if filter_active?(params), do: clear_all_href(params, table_path)
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
    cond do
      first_run_empty?(params, summary) -> Copy.subscriptions_list_first_run_empty_title()
      queue_active?(params) -> Copy.subscriptions_list_queue_empty_title()
      filter_active?(params) -> Copy.subscriptions_list_filtered_empty_title()
      true -> Copy.subscriptions_list_first_run_empty_title()
    end
  end

  defp empty_copy(params, summary) do
    cond do
      first_run_empty?(params, summary) -> Copy.subscriptions_list_first_run_empty_body()
      queue_active?(params) -> Copy.subscriptions_list_queue_empty_body()
      filter_active?(params) -> Copy.subscriptions_list_filtered_empty_body()
      true -> Copy.subscriptions_list_first_run_empty_body()
    end
  end

  defp first_run_empty?(params, summary),
    do: Map.get(params, "view") == "all" and summary.total_count == 0 and !filter_active?(params)

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
