defmodule AccrueAdmin.Live.WebhooksLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Auth, Events}
  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Webhooks.DLQ

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    FilterChipBar,
    FlashGroup,
    PageHeader,
    StatStrip
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Webhooks

  @default_queue_status "failed,dead"

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
         "/webhooks",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/webhooks",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))
     |> assign(:flashes, [])
     |> assign(:pending_bulk_replay, nil)}
  end

  @impl true
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))}
  end

  def handle_params(params, _uri, socket) do
    summary = webhook_summary(socket.assigns.current_owner_scope)

    if map_size(params) == 0 or map_only_scope?(params) do
      default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)
      to = AccrueAdmin.DataTableNav.merge_query(socket.assigns.table_path, default)

      if connected?(socket) do
        {:noreply,
         socket
         |> assign(:summary, summary)
         |> push_patch(to: to)}
      else
        {:noreply,
         socket
         |> assign(:params, default)
         |> assign(:summary, summary)}
      end
    else
      {:noreply,
       socket
       |> assign(:params, params)
       |> assign(:summary, summary)}
    end
  end

  @impl true
  def handle_info({:data_table_bulk_action, "retry_selected", ids}, socket) do
    if ids == [] do
      {:noreply, push_flash(socket, :warning, Copy.webhooks_retry_no_selection_warning())}
    else
      {:noreply, assign(socket, :pending_bulk_replay, %{ids: ids, count: length(ids)})}
    end
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

  def handle_event("cancel_bulk_replay", _params, socket) do
    {:noreply, assign(socket, :pending_bulk_replay, nil)}
  end

  def handle_event("confirm_retry_selected", _params, socket) do
    %{ids: ids, count: count} = socket.assigns.pending_bulk_replay

    case scope_selected_ids(socket.assigns.current_owner_scope, ids) do
      [] ->
        {:noreply,
         socket
         |> assign(:pending_bulk_replay, nil)
         |> push_flash(:warning, Copy.Locked.replay_blocked())}

      scoped_ids ->
        case replay_scoped_rows(scoped_ids) do
          {:ok, result} ->
            socket =
              socket
              |> record_bulk_replay(scoped_ids, count, result)
              |> assign(:pending_bulk_replay, nil)
              |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))
              |> push_flash(:info, Copy.webhooks_retry_success(count))

            {:noreply, socket}

          {:error, _reason} ->
            {:noreply, push_flash(socket, :error, bulk_replay_error_copy(socket))}
        end
    end
  end

  defp replay_scoped_rows(ids) do
    Enum.reduce_while(ids, {:ok, %{requeued: 0}}, fn id, {:ok, acc} ->
      case DLQ.requeue(id) do
        {:ok, _row} -> {:cont, {:ok, %{requeued: acc.requeued + 1}}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  # Keep only the selected ids that resolve inside the active owner scope, mirroring
  # the per-row ownership check the filtered flow used.
  defp scope_selected_ids(nil, ids), do: ids

  defp scope_selected_ids(owner_scope, ids) do
    Enum.filter(ids, fn id ->
      match?({:ok, _}, Webhooks.detail(id, owner_scope))
    end)
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
            %{label: Copy.webhooks_index_heading()}
          ]}
          title={Copy.webhooks_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.webhooks_list_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label="Webhook summary">
              <:stat label="Received" value={Integer.to_string(@summary.received_count)} />
              <:stat
                label="Blocked"
                value={Integer.to_string(@summary.blocked_count)}
                tone="amber"
              />
              <:stat
                label="Replayed"
                value={Integer.to_string(@summary.replayed_count)}
                tone="cobalt"
              />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="webhooks"
              filter_fields={webhook_filter_fields(@current_owner_scope)}
              filter_params={filter_params(@params)}
              path={@table_path}
              clear_href={clear_all_href(@params, @table_path)}
              clear_visible={filter_active?(@params)}
            />
          </:filter_toolbar>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={@flashes} />

        <p class="ax-body ax-page-copy" data-role="webhooks-retry-helper">
          <%= Copy.webhooks_retry_selected_helper() %>
        </p>

        <section :if={@pending_bulk_replay} class="ax-card" data-role="bulk-replay-confirm">
          <p class="ax-body">
            <%= Copy.webhooks_retry_confirm_question(@pending_bulk_replay.count) %>
          </p>
          <div class="ax-page-header">
            <button
              type="button"
              phx-click="confirm_retry_selected"
              class="ax-button ax-button-primary"
              data-role="confirm-retry-selected"
            >
              <%= Copy.webhooks_retry_selected_label() %>
            </button>
            <button
              type="button"
              phx-click="cancel_bulk_replay"
              class="ax-button ax-button-ghost"
            >
              <%= Copy.webhooks_retry_cancel_label() %>
            </button>
          </div>
        </section>

        <.live_component
          module={DataTable}
          id="webhooks"
          query_module={Webhooks}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="webhooks"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={list_state_copy(:loading).heading}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          selectable={true}
          row_label={{"event", "events"}}
          bulk_action_label={Copy.webhooks_retry_selected_label()}
          bulk_action_event="retry_selected"
          columns={[
            %{label: "Webhook", render: &webhook_link(&1, @admin_mount_path, @current_owner_scope)},
            %{id: :type, label: "Type"},
            %{label: "Status", render: &status_summary/1},
            %{label: "Endpoint", render: &endpoint_summary/1},
            %{label: "Received", render: &received_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Status", render: &status_summary/1},
            %{id: :type, label: "Type"},
            %{label: "Endpoint", render: &endpoint_summary/1},
            %{label: "Received", render: &received_summary/1}
          ]}
          filter_fields={webhook_filter_fields(@current_owner_scope)}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
          table_caption={Copy.webhooks_index_table_caption()}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={work_queue_chips(@params, @table_path)}
              label="Webhook view"
              result_count={status.visible_count}
              result_label={Copy.webhooks_list_result_label_pair()}
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
    |> assign(:page_title, "Webhooks")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/webhooks"))
  end

  # Status filter options carry their live count in the label and disable zero-count
  # statuses (the active value is never disabled — handled in DataTable.filter_input/1).
  defp webhook_filter_fields(owner_scope) do
    [
      %{
        id: :status,
        label: "Status",
        type: :select,
        all_label: "All statuses",
        options: status_filter_options(owner_scope)
      },
      %{
        id: :type,
        label: "Type",
        type: :datalist,
        options: Webhooks.distinct_types(owner_scope)
      },
      %{
        id: :livemode,
        label: "Live mode",
        type: :segmented,
        options: [{"", "All"}, {"true", "Live"}, {"false", "Test"}]
      }
    ]
  end

  defp status_filter_options(owner_scope) do
    counts = Webhooks.status_counts(owner_scope)

    Enum.map(WebhookEvent.statuses(), fn status ->
      count = Map.get(counts, status, 0)

      %{
        value: Atom.to_string(status),
        label: "#{humanize(status)} (#{count})",
        disabled: count == 0
      }
    end)
  end

  defp webhook_summary(owner_scope) do
    %{
      received_count: Webhooks.count(owner_scope),
      blocked_count: Webhooks.count(owner_scope, %{status: [:failed, :dead]}),
      dead_count: Webhooks.count(owner_scope, %{status: :dead}),
      replayed_count: Webhooks.count(owner_scope, %{status: :replayed}),
      livemode_count: Webhooks.count(owner_scope, %{livemode: true})
    }
  end

  defp filter_params(params) do
    params
    |> Webhooks.decode_filter()
    |> Webhooks.encode_filter()
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
        label: Copy.webhooks_list_default_lens_label(),
        tone: :cobalt,
        active: queue_active,
        remove_href: if(queue_active, do: clear_href)
      },
      %{
        id: :view_all,
        label: Copy.webhooks_list_all_lens_label(),
        tone: :slate,
        active: queue_active or all_active,
        href: if(queue_active, do: clear_href)
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("status"), do: "Status"
  defp filter_chip_label("type"), do: "Type"
  defp filter_chip_label("livemode"), do: "Live mode"
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("status", value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map_join(", ", &humanize/1)
  end

  defp filter_chip_value("livemode", "true"), do: "Live"
  defp filter_chip_value("livemode", "false"), do: "Test"
  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "type" => nil,
      "status" => nil,
      "livemode" => nil,
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

  defp list_state_copy(state), do: Copy.resource_state_copy(:webhooks, state)

  defp first_run_empty?(params, summary),
    do:
      Map.get(params, "view") == "all" and summary.received_count == 0 and !filter_active?(params)

  defp phase197_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase197_state") == "loading-skeleton"
  end

  defp record_bulk_replay(socket, ids, count, result) do
    current_admin = socket.assigns.current_admin

    {:ok, _event} =
      Events.record(%{
        type: "admin.webhook.bulk_replay.completed",
        subject_type: "WebhookBatch",
        subject_id: "selected",
        actor_type: "admin",
        actor_id: Auth.actor_id(current_admin),
        data: %{
          "count" => count,
          "requeued" => result.requeued,
          "skipped" => Map.get(result, :skipped, 0),
          "ids" => ids
        }
      })

    :ok =
      Auth.log_audit(current_admin, %{
        type: "admin.webhook.bulk_replay.completed",
        count: count,
        source: :accrue_admin
      })

    socket
  end

  defp bulk_replay_error_copy(socket) do
    Copy.page_state_copy(:recoverable_error,
      resource: "webhook bulk replay",
      owner_scope: owner_scope_copy(socket.assigns.current_owner_scope),
      recovery: "retry from the filtered webhook queue"
    ).body
  end

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp webhook_link(row, mount_path, owner_scope) do
    label = row.processor_event_id || row.id
    safe_link(scoped_path(mount_path, "/webhooks/#{row.id}", owner_scope), label)
  end

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(<span class="ax-body"><a href="#{href}" class="ax-link">#{escaped}</a></span>)
    )
  end

  defp status_summary(row) do
    text = humanize(row.status) |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<span class="ax-body">#{text}</span>))
  end

  defp endpoint_summary(row) do
    text = "#{humanize(row.endpoint)} · #{mode_label(row.livemode)}"
    escaped = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<span class="ax-body">#{escaped}</span>))
  end

  defp received_summary(row) do
    text = format_datetime(row.received_at)
    escaped = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<span class="ax-body">#{escaped}</span>))
  end

  defp card_title(row), do: row.processor_event_id || row.id

  defp mode_label(true), do: "live"
  defp mode_label(false), do: "test"

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Unknown"

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

  defp map_only_scope?(params) do
    params != %{} and Map.keys(params) -- ["org"] == []
  end

  defp owner_scope_copy(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "organization #{slug}"

  defp owner_scope_copy(%{mode: :global}), do: "global owner scope"
  defp owner_scope_copy(_owner_scope), do: "the active organization scope"

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
