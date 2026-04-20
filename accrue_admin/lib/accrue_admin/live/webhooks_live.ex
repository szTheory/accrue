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
  def handle_event("prepare_bulk_replay", _params, socket) do
    filter = dlq_filter(socket.assigns.params)
    count = Webhooks.bulk_replay_count(socket.assigns.current_owner_scope, Map.new(filter))

    if count == 0 do
      {:noreply, push_flash(socket, :warning, Copy.webhooks_bulk_no_rows_warning())}
    else
      {:noreply, assign(socket, :pending_bulk_replay, %{count: count, filter: filter})}
    end
  end

  def handle_event("cancel_bulk_replay", _params, socket) do
    {:noreply, assign(socket, :pending_bulk_replay, nil)}
  end

  def handle_event("confirm_bulk_replay", _params, socket) do
    %{count: count, filter: filter} = socket.assigns.pending_bulk_replay

    case replay_scope(socket.assigns.current_owner_scope, filter) do
      [] ->
        {:noreply,
         socket
         |> assign(:pending_bulk_replay, nil)
         |> push_flash(:warning, Copy.Locked.replay_blocked())}

      ids ->
        case replay_scoped_rows(ids) do
          {:ok, result} ->
            socket =
              socket
              |> record_bulk_replay(filter, count, result)
              |> assign(:pending_bulk_replay, nil)
              |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))
              |> push_flash(:info, bulk_replay_success(socket.assigns.current_owner_scope))

            {:noreply, socket}

          {:error, reason} ->
            {:noreply, push_flash(socket, :error, inspect(reason))}
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

  defp replay_scope(nil, filter) do
    filter
    |> DLQ.list()
    |> Enum.map(& &1.id)
  end

  defp replay_scope(owner_scope, filter) do
    filter
    |> DLQ.list()
    |> Enum.map(& &1.id)
    |> Enum.filter(fn id ->
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
          <p class="ax-eyebrow">Webhook operations</p>
          <h2 class="ax-display">Replay, inspect, and trace webhook delivery</h2>
          <p class="ax-body ax-page-copy">
            Operators can filter inbound webhook rows, jump into forensic payload detail, and
            bulk requeue the current dead-letter slice without adding a second replay system.
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

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">DLQ bulk replay</p>
            <h3 class="ax-heading">Requeue the filtered dead-letter slice</h3>
            <p class="ax-body">
              Bulk replay respects the existing DLQ caps and records one admin audit event for the
              whole intent.
            </p>
          </header>

          <button
            type="button"
            phx-click="prepare_bulk_replay"
            class="ax-button ax-button-secondary"
            data-role="prepare-bulk-replay"
          >
            Replay filtered DLQ rows
          </button>

          <section :if={@pending_bulk_replay} class="ax-card" data-role="bulk-replay-confirm">
            <p class="ax-label">Confirm bulk replay</p>
            <p class="ax-body">
              <%= bulk_replay_confirmation(@pending_bulk_replay.count) %>
            </p>
            <div class="ax-page-header">
              <button
                type="button"
                phx-click="confirm_bulk_replay"
                class="ax-button ax-button-primary"
                data-role="confirm-bulk-replay"
              >
                Confirm bulk replay
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
        </section>

        <.live_component
          module={DataTable}
          id="webhooks"
          query_module={Webhooks}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Webhook", render: &webhook_link(&1, @admin_mount_path, @current_owner_scope)},
            %{id: :type, label: "Type"},
            %{label: "Status", render: &status_summary/1},
            %{label: "Endpoint", render: &endpoint_summary/1},
            %{label: "Received", render: &received_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{id: :type, label: "Type"},
            %{label: "Status", render: &status_summary/1},
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

  defp record_bulk_replay(socket, filter, count, result) do
    current_admin = socket.assigns.current_admin

    {:ok, _event} =
      Events.record(%{
        type: "admin.webhook.bulk_replay.completed",
        subject_type: "WebhookBatch",
        subject_id: "filtered",
        actor_type: "admin",
        actor_id: Auth.actor_id(current_admin),
        data: %{
          "count" => count,
          "requeued" => result.requeued,
          "skipped" => Map.get(result, :skipped, 0),
          "filter" =>
            Enum.into(filter, %{}, fn {key, value} ->
              {to_string(key), normalize_filter_value(value)}
            end)
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

  defp dlq_filter(params) do
    decoded = Webhooks.decode_filter(params)

    Enum.reduce(decoded, [], fn
      {:status, status}, acc when status in [:failed, :dead] -> [{:status, status} | acc]
      {:type, type}, acc -> [{:type, type} | acc]
      {:livemode, livemode}, acc -> [{:livemode, livemode} | acc]
      {_key, _value}, acc -> acc
    end)
    |> Enum.reverse()
  end

  defp normalize_filter_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_filter_value(value), do: value

  defp bulk_replay_confirmation(count), do: Copy.webhooks_bulk_replay_confirm_question(count)

  defp bulk_replay_success(%{mode: :organization}), do: Copy.Locked.bulk_replay_success_organization()
  defp bulk_replay_success(_owner_scope), do: Copy.Locked.bulk_replay_success_global()

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp webhook_link(row, mount_path, owner_scope) do
    label = row.processor_event_id || row.id
    safe_link(scoped_path(mount_path, "/webhooks/#{row.id}", owner_scope), label)
  end

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<span class="ax-body"><a href="#{href}" class="ax-link">#{escaped}</a></span>))
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

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
