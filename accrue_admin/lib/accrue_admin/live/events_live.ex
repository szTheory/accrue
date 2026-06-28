defmodule AccrueAdmin.Live.EventsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Events.Event
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    FilterChipBar,
    PageHeader,
    StatStrip
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Events
  alias AccrueAdmin.ScopedPath

  @customers_table Accrue.Migration.qualified_table(:accrue_customers)
  @subscriptions_table Accrue.Migration.qualified_table(:accrue_subscriptions)
  @invoices_table Accrue.Migration.qualified_table(:accrue_invoices)
  @organization_scope_sql """
  EXISTS (
    SELECT 1
    FROM #{@customers_table} customers
    WHERE ? = 'Customer'
      AND customers.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  OR EXISTS (
    SELECT 1
    FROM #{@subscriptions_table} subscriptions
    JOIN #{@customers_table} customers ON customers.id = subscriptions.customer_id
    WHERE ? = 'Subscription'
      AND subscriptions.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  OR EXISTS (
    SELECT 1
    FROM #{@invoices_table} invoices
    JOIN #{@customers_table} customers ON customers.id = invoices.customer_id
    WHERE ? = 'Invoice'
      AND invoices.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  """

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(
       :current_path,
       ScopedPath.build(
         admin["mount_path"] || "/billing",
         "/events",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       ScopedPath.build(
         admin["mount_path"] || "/billing",
         "/events",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, event_summary(socket.assigns.current_owner_scope))}
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
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:summary, event_summary(socket.assigns.current_owner_scope))}
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
            %{label: Copy.dashboard_breadcrumb_home(), href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)},
            %{label: Copy.billing_events_breadcrumb_events()}
          ]}
          title={Copy.events_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.events_list_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label={Copy.billing_events_kpi_section_aria_label()}>
              <:stat
                label={Copy.billing_events_kpi_label_ledger_rows()}
                value={Integer.to_string(@summary.total_count)}
              />
              <:stat
                label={Copy.billing_events_kpi_label_webhook_sourced()}
                value={Integer.to_string(@summary.webhook_linked_count)}
                tone="cobalt"
              />
              <:stat
                label={Copy.billing_events_kpi_label_last_24h()}
                value={Integer.to_string(@summary.last_day_count)}
                tone="moss"
              />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="events"
              filter_fields={event_filter_fields()}
              filter_params={filter_params(@params)}
              path={@table_path}
              clear_href={clear_all_href(@params, @table_path)}
              clear_visible={filter_active?(@params)}
            />
          </:filter_toolbar>
        </PageHeader.page_header>

        <.live_component
          module={DataTable}
          id="events"
          query_module={Events}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="events"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={Copy.events_list_loading_label()}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          row_label={Copy.events_list_result_label_pair()}
          filter_submit_label={Copy.billing_events_apply_filters()}
          columns={[
            %{id: :type, label: Copy.billing_events_table_column_event()},
            %{
              label: Copy.billing_events_table_column_subject(),
              render: fn row -> subject_cell(row, @admin_mount_path, @current_owner_scope) end
            },
            %{label: Copy.billing_events_table_column_actor(), render: &actor_summary/1},
            %{label: Copy.billing_events_table_column_webhook_source(), render: &webhook_source_summary/1},
            %{label: Copy.billing_events_table_column_when(), render: &when_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{
              label: Copy.billing_events_table_column_subject(),
              render: fn row -> subject_cell(row, @admin_mount_path, @current_owner_scope) end
            },
            %{label: Copy.billing_events_table_column_actor(), render: &actor_summary/1},
            %{label: Copy.billing_events_table_column_webhook_source(), render: &webhook_source_summary/1},
            %{label: Copy.billing_events_table_column_when(), render: &when_summary/1}
          ]}
          filter_fields={event_filter_fields()}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={event_lens_chips(@params, @table_path)}
              label="Event view"
              result_count={status.visible_count}
              result_label={Copy.events_list_result_label_pair()}
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
    |> assign(:page_title, Copy.billing_events_page_title())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/events"))
  end

  defp event_summary(owner_scope) do
    day_ago = DateTime.add(DateTime.utc_now(), -86_400, :second)
    base_query = scoped_events_query(owner_scope)

    %{
      total_count: Repo.aggregate(base_query, :count, :id),
      webhook_linked_count:
        base_query
        |> where([event], not is_nil(event.caused_by_webhook_event_id))
        |> Repo.aggregate(:count, :id),
      admin_count:
        base_query
        |> where([event], event.actor_type == "admin")
        |> Repo.aggregate(:count, :id),
      last_day_count:
        base_query
        |> where([event], event.inserted_at >= ^day_ago)
        |> Repo.aggregate(:count, :id),
      unique_subject_types:
        base_query
        |> select([event], count(fragment("distinct ?", event.subject_type)))
        |> Repo.one()
    }
  end

  defp scoped_events_query(nil), do: Event
  defp scoped_events_query(%OwnerScope{mode: :global}), do: Event

  defp scoped_events_query(%OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      Event,
      [event],
      fragment(
        @organization_scope_sql,
        event.subject_type,
        event.subject_id,
        ^organization_id,
        event.subject_type,
        event.subject_id,
        ^organization_id,
        event.subject_type,
        event.subject_id,
        ^organization_id
      )
    )
  end

  defp event_filter_fields do
    [
      %{id: :q, label: Copy.billing_events_filter_label_search()},
      %{id: :type, label: Copy.billing_events_filter_label_event_type()},
      %{id: :actor_type, label: Copy.billing_events_filter_label_actor_type()},
      %{id: :subject_type, label: Copy.billing_events_filter_label_subject_type()},
      %{
        id: :source_webhook_event_id,
        label: Copy.billing_events_filter_label_source_webhook_id()
      }
    ]
  end

  defp filter_params(params) do
    params
    |> Events.decode_filter()
    |> Events.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp event_lens_chips(params, table_path) do
    admin_active? = Map.get(params, "actor_type") == "admin"
    clear_href = clear_all_href(params, table_path)

    filter_chips =
      params
      |> filter_params()
      |> Enum.reject(fn {key, value} -> key == "actor_type" and value == "admin" end)
      |> Enum.map(fn {key, value} ->
        %{
          id: String.to_atom(key),
          label: filter_chip_label(key),
          value: filter_chip_value(key, value),
          tone: :slate,
          active: true,
          remove_href:
            AccrueAdmin.DataTableNav.merge_query(table_path, %{
              key => nil,
              "cursor" => nil,
              "phase197_state" => nil
            })
        }
      end)

    [
      %{
        id: :all_ledger,
        label: Copy.events_list_all_lens_label(),
        tone: if(filter_active?(params), do: :slate, else: :cobalt),
        active: true,
        href: if(filter_active?(params), do: clear_href)
      },
      %{
        id: :admin_changes,
        label: Copy.events_list_admin_changes_label(),
        tone: if(admin_active?, do: :cobalt, else: :slate),
        active: true,
        href:
          if admin_active? do
            nil
          else
            AccrueAdmin.DataTableNav.merge_query(table_path, %{
              "actor_type" => "admin",
              "cursor" => nil,
              "phase197_state" => nil
            })
          end,
        remove_href:
          if admin_active? do
            AccrueAdmin.DataTableNav.merge_query(table_path, %{
              "actor_type" => nil,
              "cursor" => nil,
              "phase197_state" => nil
            })
          end
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("q"), do: "Search"
  defp filter_chip_label("type"), do: Copy.billing_events_filter_label_event_type()
  defp filter_chip_label("actor_type"), do: Copy.billing_events_filter_label_actor_type()
  defp filter_chip_label("subject_type"), do: Copy.billing_events_filter_label_subject_type()

  defp filter_chip_label("source_webhook_event_id"),
    do: Copy.billing_events_filter_label_source_webhook_id()

  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "q" => nil,
      "type" => nil,
      "actor_type" => nil,
      "subject_type" => nil,
      "source_webhook_event_id" => nil,
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
    if first_run_empty?(params, summary) do
      Copy.events_list_first_run_empty_title()
    else
      Copy.events_list_filtered_empty_title()
    end
  end

  defp empty_copy(params, summary) do
    if first_run_empty?(params, summary) do
      Copy.events_list_first_run_empty_body()
    else
      Copy.events_list_filtered_empty_body()
    end
  end

  defp first_run_empty?(params, summary),
    do: summary.total_count == 0 and !filter_active?(params)

  defp phase197_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase197_state") == "loading-skeleton"
  end

  defp subject_cell(row, mount_path, owner_scope) do
    label = "#{row.subject_type} #{row.subject_id}"

    case subject_href(row, mount_path, owner_scope) do
      nil ->
        label

      href ->
        escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
        Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
    end
  end

  defp subject_href(%{subject_type: "Customer", subject_id: id}, mount_path, scope),
    do: ScopedPath.build(mount_path, "/customers/#{id}", scope)

  defp subject_href(%{subject_type: "Subscription", subject_id: id}, mount_path, scope),
    do: ScopedPath.build(mount_path, "/subscriptions/#{id}", scope)

  defp subject_href(%{subject_type: "Invoice", subject_id: id}, mount_path, scope),
    do: ScopedPath.build(mount_path, "/invoices/#{id}", scope)

  defp subject_href(%{subject_type: "Charge", subject_id: id}, mount_path, scope),
    do: ScopedPath.build(mount_path, "/payments/#{id}", scope)

  defp subject_href(%{subject_type: "WebhookEvent", subject_id: id}, mount_path, scope),
    do: ScopedPath.build(mount_path, "/webhooks/#{id}", scope)

  defp subject_href(_row, _mount_path, _scope), do: nil

  defp actor_summary(row) do
    case row.actor_id do
      nil -> humanize(row.actor_type)
      actor_id -> "#{humanize(row.actor_type)} #{actor_id}"
    end
  end

  defp webhook_source_summary(%{caused_by_webhook_event_id: nil}),
    do: Copy.billing_events_webhook_source_direct()

  defp webhook_source_summary(%{caused_by_webhook_event_id: webhook_id}), do: webhook_id

  defp when_summary(row), do: format_datetime(row.inserted_at)
  defp card_title(row), do: row.type

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: Copy.billing_events_when_unknown()

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
