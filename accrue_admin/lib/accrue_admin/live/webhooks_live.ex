defmodule AccrueAdmin.Live.WebhooksLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Auth, Events}
  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Webhooks.DLQ
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, FlashGroup, KpiCard}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Webhooks

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
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))}
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
    active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
              %{label: "Webhooks"}
            ]}
          />
          <h1 class="ax-display">Replay, inspect, and trace webhook delivery</h1>
          <p class="ax-body ax-page-copy">
            Filter inbound webhook events, open any event for full payload detail, and select
            the ones that need a re-run.
          </p>
        </header>

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-kpi-grid" aria-label="Webhook summary">
          <KpiCard.kpi_card label="Received" value={Integer.to_string(@summary.received_count)}>
            <:meta>Total persisted webhook rows</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Blocked"
            value={Integer.to_string(@summary.blocked_count)}
            delta={Integer.to_string(@summary.dead_count) <> " dead-lettered"}
            delta_tone="amber"
          >
            <:meta>Rows waiting on operator replay or investigation</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Replayed"
            value={Integer.to_string(@summary.replayed_count)}
            delta={Integer.to_string(@summary.livemode_count) <> " live mode"}
            delta_tone="cobalt"
          >
            <:meta>Replay cycles recorded through the shared DLQ primitives</:meta>
          </KpiCard.kpi_card>
        </section>

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
              Cancel
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
          filter_fields={[
            %{
              id: :status,
              label: "Status",
              type: :select,
              options:
                Enum.map(WebhookEvent.statuses(), fn status ->
                  {Atom.to_string(status), humanize(status)}
                end)
            },
            %{id: :type, label: "Type"},
            %{
              id: :livemode,
              label: "Live mode",
              type: :select,
              options: [{"true", "Live"}, {"false", "Test"}]
            }
          ]}
          empty_title={Copy.webhooks_index_empty_title()}
          empty_copy={Copy.webhooks_index_empty_copy()}
          table_caption={Copy.webhooks_index_table_caption()}
        />
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

  defp webhook_summary(owner_scope) do
    %{
      received_count: Webhooks.count(owner_scope),
      blocked_count: Webhooks.count(owner_scope, %{status: [:failed, :dead]}),
      dead_count: Webhooks.count(owner_scope, %{status: :dead}),
      replayed_count: Webhooks.count(owner_scope, %{status: :replayed}),
      livemode_count: Webhooks.count(owner_scope, %{livemode: true})
    }
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

  defp owner_scope_copy(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "organization #{slug}"

  defp owner_scope_copy(%{mode: :global}), do: "global owner scope"
  defp owner_scope_copy(_owner_scope), do: "the active organization scope"

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
