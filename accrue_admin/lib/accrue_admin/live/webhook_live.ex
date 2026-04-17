defmodule AccrueAdmin.Live.WebhookLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.{Auth, Events}
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Webhooks.DLQ
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, FlashGroup, JsonViewer, KpiCard, Timeline}
  alias AccrueAdmin.Queries.Webhooks

  @owner_access_denied "You don't have access to billing for this organization."
  @ambiguous_replay_blocked "Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved."
  @replay_success "Replay requested for the active organization."
  @global_replay_success "Webhook replay requested."
  @replay_blocked "Replay is blocked because this webhook isn't linked to a billable row in the active organization."

  @impl true
  def mount(%{"id" => webhook_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Webhooks.detail(webhook_id, socket.assigns.current_owner_scope) do
      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, @owner_access_denied)
         |> redirect(
           to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/webhooks")
         )}

      {:ok, webhook} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign_webhook(webhook)
         |> assign(:flashes, [])
         |> assign(:pending_replay, false)
         |> assign(:replay_state, :allowed)}

      {:ambiguous, proof_context} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:webhook, nil)
         |> assign(:attempt_history, [])
         |> assign(:derived_events, [])
         |> assign(:flashes, [])
         |> assign(:pending_replay, false)
         |> assign(:replay_state, {:ambiguous, proof_context})}
    end
  end

  @impl true
  def handle_event("prepare_replay", _params, %{assigns: %{replay_state: :allowed}} = socket) do
    {:noreply, assign(socket, :pending_replay, true)}
  end

  def handle_event("prepare_replay", _params, socket) do
    {:noreply, push_flash(socket, :warning, @replay_blocked)}
  end

  def handle_event("cancel_replay", _params, socket) do
    {:noreply, assign(socket, :pending_replay, false)}
  end

  def handle_event("confirm_replay", _params, %{assigns: %{webhook: webhook}} = socket) do
    with {:ok, ^webhook} <- Webhooks.detail(webhook.id, socket.assigns.current_owner_scope),
         {:ok, replayed} <- DLQ.requeue(webhook.id) do
      socket =
        socket
        |> record_single_replay(replayed)
        |> assign_webhook(Repo.get(WebhookEvent, replayed.id))
        |> assign(:pending_replay, false)
        |> push_flash(:info, replay_success(socket.assigns.current_owner_scope))

      {:noreply, socket}
    else
      :not_found ->
        {:noreply,
         socket
         |> assign(:pending_replay, false)
         |> push_flash(:warning, @replay_blocked)}

      {:ambiguous, _proof_context} ->
        {:noreply,
         socket
         |> assign(:pending_replay, false)
         |> push_flash(:warning, @replay_blocked)}

      {:error, reason} ->
        {:noreply, push_flash(socket, :error, inspect(reason))}
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
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: scoped_mount_path(@admin_mount_path, "", @current_owner_scope, %{})},
              %{label: "Webhooks", href: scoped_mount_path(@admin_mount_path, "/webhooks", @current_owner_scope, %{})},
              %{label: breadcrumb_label(assigns)}
            ]}
          />
          <p class="ax-eyebrow">Webhook inspector</p>
          <h2 class="ax-display"><%= webhook_heading(assigns) %></h2>
          <p :if={@webhook} class="ax-body ax-page-copy">
            <%= @webhook.processor_event_id %> · <%= humanize(@webhook.status) %> · received
            <%= format_datetime(@webhook.received_at) %>
          </p>
        </header>

        <FlashGroup.flash_group flashes={@flashes} />

        <section :if={@webhook} class="ax-kpi-grid" aria-label="Webhook summary">
          <KpiCard.kpi_card label="Verification" value={verification_summary(@webhook)}>
            <:meta>Signature verification passed before the row was persisted</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Attempts" value={Integer.to_string(length(@attempt_history))}>
            <:meta>Existing Oban job history for this webhook row</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Derived events"
            value={Integer.to_string(length(@derived_events))}
            delta={mode_label(@webhook.livemode)}
            delta_tone="cobalt"
          >
            <:meta>Append-only ledger rows linked by webhook causality</:meta>
          </KpiCard.kpi_card>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Replay</p>
            <h3 class="ax-heading"><%= replay_heading(assigns) %></h3>
            <p class="ax-body"><%= replay_copy(assigns) %></p>
          </header>

          <button
            :if={@webhook}
            type="button"
            phx-click="prepare_replay"
            class="ax-button ax-button-secondary"
            data-role="replay-single"
            disabled={@webhook.status not in [:failed, :dead]}
          >
            Replay webhook
          </button>

          <p :if={match?({:ambiguous, _}, @replay_state)} class="ax-body" data-role="replay-blocked-copy">
            <%= ambiguous_replay_blocked() %>
          </p>

          <section :if={@pending_replay} class="ax-page" data-role="replay-confirm">
            <p class="ax-label"><%= single_replay_confirmation() %></p>
            <div class="ax-page-header">
              <button
                type="button"
                phx-click="confirm_replay"
                class="ax-button ax-button-primary"
                data-role="confirm-replay"
              >
                Confirm replay
              </button>
              <button
                type="button"
                phx-click="cancel_replay"
                class="ax-button ax-button-ghost"
              >
                Cancel
              </button>
            </div>
          </section>
        </section>

        <section :if={@webhook} class="ax-grid ax-grid-2">
          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow">Attempt history</p>
              <h3 class="ax-heading">Dispatch and retry lifecycle</h3>
            </header>

            <Timeline.timeline
              label="Webhook attempt history"
              empty_label="No dispatch attempts recorded yet"
              items={attempt_timeline(@attempt_history)}
            />
          </article>

          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow">Derived events</p>
              <h3 class="ax-heading">Ledger rows caused by this webhook</h3>
            </header>

            <Timeline.timeline
              label="Derived events"
              empty_label="No derived event rows linked to this webhook yet"
              items={derived_event_timeline(@derived_events, @admin_mount_path, @current_owner_scope)}
            />
          </article>
        </section>

        <section :if={@webhook} class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Forensic payload</p>
            <h3 class="ax-heading">Stored raw payload and metadata</h3>
          </header>

          <div class="ax-page">
            <p class="ax-body">Endpoint: <%= humanize(@webhook.endpoint) %></p>
            <p class="ax-body">Processed: <%= format_datetime(@webhook.processed_at) %></p>
            <p class="ax-body">
              Activity feed:
              <a
                class="ax-link"
                href={
                  scoped_mount_path(@admin_mount_path, "/events", @current_owner_scope, %{
                    "source_webhook_event_id" => @webhook.id
                  })
                }
              >
                View linked activity
              </a>
            </p>
          </div>
        </section>

        <JsonViewer.json_viewer
          :if={@webhook}
          id="webhook-payload"
          label="Webhook payload"
          payload={payload_for(@webhook)}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Webhook")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(
      :current_path,
      scoped_admin_path(admin, socket.assigns.current_owner_scope, "/webhooks")
    )
  end

  defp assign_webhook(socket, webhook) do
    socket
    |> assign(:webhook, webhook)
    |> assign(
      :current_path,
      scoped_mount_path(
        socket.assigns.admin_mount_path,
        "/webhooks",
        socket.assigns.current_owner_scope,
        %{}
      )
    )
    |> assign(:attempt_history, attempt_history(webhook.id))
    |> assign(:derived_events, derived_events(webhook.id))
    |> assign(:replay_state, :allowed)
  end

  defp webhook_heading(%{webhook: nil}), do: "Webhook replay is unavailable"
  defp webhook_heading(%{webhook: webhook}), do: webhook.type

  defp breadcrumb_label(%{webhook: nil}), do: "Replay unavailable"
  defp breadcrumb_label(%{webhook: webhook}), do: webhook.processor_event_id || webhook.id

  defp replay_heading(%{webhook: nil}), do: "Replay is unavailable"
  defp replay_heading(%{webhook: _webhook}), do: "Requeue this webhook row"

  defp replay_copy(%{webhook: nil}), do: @ambiguous_replay_blocked

  defp replay_copy(%{webhook: _webhook}) do
    "Single replay calls the existing DLQ primitive directly and records an admin audit event for the operator action."
  end

  defp ambiguous_replay_blocked, do: @ambiguous_replay_blocked
  defp single_replay_confirmation, do: "Replay webhook for the active organization?"
  defp replay_success(%{mode: :organization}), do: @replay_success
  defp replay_success(_owner_scope), do: @global_replay_success

  defp attempt_history(webhook_id) do
    from(job in Oban.Job,
      where:
        job.worker == "Accrue.Webhook.DispatchWorker" and
          fragment("?->>'webhook_event_id' = ?", job.args, ^webhook_id),
      order_by: [asc: job.inserted_at, asc: job.id]
    )
    |> Repo.all()
  end

  defp derived_events(webhook_id) do
    from(event in Event,
      where: event.caused_by_webhook_event_id == ^webhook_id,
      order_by: [asc: event.inserted_at, asc: event.id]
    )
    |> Repo.all()
  end

  defp record_single_replay(socket, webhook) do
    current_admin = socket.assigns.current_admin

    {:ok, _event} =
      Events.record(%{
        type: "admin.webhook.replay.completed",
        subject_type: "WebhookEvent",
        subject_id: webhook.id,
        actor_type: "admin",
        actor_id: Auth.actor_id(current_admin),
        caused_by_webhook_event_id: webhook.id,
        data: %{
          "processor_event_id" => webhook.processor_event_id,
          "status" => Atom.to_string(webhook.status)
        }
      })

    :ok =
      Auth.log_audit(current_admin, %{
        type: "admin.webhook.replay.completed",
        webhook_event_id: webhook.id,
        source: :accrue_admin
      })

    socket
  end

  defp attempt_timeline(jobs) do
    Enum.map(jobs, fn job ->
      %{
        title: "Attempt #{job.attempt || 1}/#{job.max_attempts || 25}",
        at: format_datetime(job.inserted_at),
        body: humanize(job.state || "available"),
        status: job.state || "available",
        tone: attempt_tone(job.state),
        details: attempt_details(job),
        meta: attempt_meta(job)
      }
    end)
  end

  defp attempt_details(job) do
    case List.last(job.errors || []) do
      nil -> nil
      error -> Jason.encode!(error, pretty: true)
    end
  end

  defp attempt_meta(job) do
    [
      job.attempted_at && "attempted #{format_datetime(job.attempted_at)}",
      job.completed_at && "completed #{format_datetime(job.completed_at)}",
      job.discarded_at && "discarded #{format_datetime(job.discarded_at)}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp derived_event_timeline(events, mount_path, owner_scope) do
    Enum.map(events, fn event ->
      %{
        title: event.type,
        at: format_datetime(event.inserted_at),
        body: "#{event.subject_type} #{event.subject_id}",
        status: event.actor_type,
        tone: if(event.actor_type == "admin", do: :cobalt, else: :slate),
        meta:
          "event ##{event.id} · #{events_path(mount_path, event.caused_by_webhook_event_id, owner_scope)}"
      }
    end)
  end

  defp events_path(mount_path, webhook_id, owner_scope) do
    "linked in " <>
      scoped_mount_path(mount_path, "/events", owner_scope, %{
        "source_webhook_event_id" => webhook_id
      })
  end

  defp scoped_mount_path(
         mount_path,
         suffix,
         %{mode: :organization, organization_slug: slug},
         params
       )
       when is_binary(slug) do
    mount_path <> suffix <> "?" <> URI.encode_query(Map.put(params, "org", slug))
  end

  defp scoped_mount_path(mount_path, suffix, _owner_scope, params) when map_size(params) > 0 do
    mount_path <> suffix <> "?" <> URI.encode_query(params)
  end

  defp scoped_mount_path(mount_path, suffix, _owner_scope, _params), do: mount_path <> suffix

  defp payload_for(%WebhookEvent{raw_body: raw_body, data: data}) do
    decode_raw_body(raw_body) || data || %{}
  end

  defp decode_raw_body(raw_body) when is_binary(raw_body) do
    with {:ok, text} <- safe_utf8(raw_body),
         {:ok, payload} <- Jason.decode(text) do
      payload
    else
      _ -> nil
    end
  end

  defp decode_raw_body(_raw_body), do: nil

  defp safe_utf8(raw_body) do
    try do
      {:ok, :unicode.characters_to_binary(raw_body)}
    rescue
      ArgumentError -> :error
    end
  end

  defp verification_summary(_webhook), do: "Verified"

  defp attempt_tone(state) when state in ["completed"], do: :moss
  defp attempt_tone(state) when state in ["executing", "available", "scheduled"], do: :cobalt
  defp attempt_tone(state) when state in ["retryable", "discarded", "cancelled"], do: :amber
  defp attempt_tone(_state), do: :slate

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp mode_label(true), do: "live mode"
  defp mode_label(false), do: "test mode"

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

  defp scoped_admin_path(admin, %_{organization_slug: nil}, suffix), do: admin_path(admin, suffix)

  defp scoped_admin_path(admin, %{organization_slug: slug}, suffix) when is_binary(slug) do
    admin_path(admin, suffix) <> "?org=" <> slug
  end

  defp scoped_admin_path(admin, _owner_scope, suffix), do: admin_path(admin, suffix)

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
