defmodule AccrueAdmin.Live.WebhookLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.{Auth, Events}
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Webhooks.DLQ

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    DetailDrawer,
    FlashGroup,
    JsonViewer,
    RelatedResources,
    StepUpAuthModal,
    Timeline
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Webhooks
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.StepUp

  @impl true
  def mount(%{"id" => webhook_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Webhooks.detail(webhook_id, socket.assigns.current_owner_scope) do
      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/webhooks")
         )}

      {:ok, webhook} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:flashes, [])
         |> assign_detail_state()
         |> assign_webhook(webhook)}

      {:ambiguous, proof_context} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:webhook, nil)
         |> assign(:attempt_history, [])
         |> assign(:derived_events, [])
         |> assign(:related_items, [])
         |> assign(:flashes, [])
         |> assign_detail_state()
         |> assign(:replay_state, {:ambiguous, proof_context})}
    end
  end

  @impl true
  def handle_event("prepare_replay", _params, %{assigns: %{replay_state: :allowed}} = socket) do
    {:noreply,
     socket
     |> assign(:drawer_action_type, "replay")
     |> assign(:pending_replay, %{webhook_id: socket.assigns.webhook.id})}
  end

  def handle_event("prepare_replay", _params, socket) do
    {:noreply, push_flash(socket, :warning, Copy.Locked.replay_blocked())}
  end

  def handle_event("cancel_replay", _params, socket) do
    {:noreply, clear_replay_drawer(socket)}
  end

  def handle_event("confirm_replay", _params, %{assigns: %{webhook: webhook}} = socket) do
    case StepUp.require_fresh(socket, step_up_action(webhook), &execute_replay(&1, webhook.id)) do
      {:ok, socket} ->
        {:noreply, socket}

      {:challenge, socket} ->
        {:noreply, socket}

      {:error, _reason, socket} ->
        {:noreply,
         socket
         |> clear_replay_drawer()
         |> push_flash(:error, Copy.webhook_replay_step_up_unavailable())}
    end
  end

  def handle_event("load_activity", _params, socket) do
    {:noreply, assign(socket, :timeline_events_loaded?, true)}
  end

  def handle_event("load_raw_json", _params, socket) do
    {:noreply, assign(socket, :raw_json_loaded?, true)}
  end

  def handle_event("step_up_submit", params, socket) do
    case StepUp.verify(socket, params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, _reason, socket} -> {:noreply, socket}
    end
  end

  def handle_event("step_up_escape", _params, socket) do
    {:noreply, dismiss_step_up_if_pending(socket)}
  end

  def handle_event("step_up_dismiss", _params, socket) do
    {:noreply, dismiss_step_up_if_pending(socket)}
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
      <section class="ax-page" phx-window-keydown="step_up_escape" phx-key="escape">
        <Breadcrumbs.breadcrumbs
          items={[
            %{label: "Dashboard", href: scoped_mount_path(@admin_mount_path, "", @current_owner_scope, %{})},
            %{label: "Webhooks", href: scoped_mount_path(@admin_mount_path, "/webhooks", @current_owner_scope, %{})},
            %{label: breadcrumb_label(assigns)}
          ]}
        />

        <Detail.summary_card eyebrow="Webhook inspector" title={webhook_heading(assigns)}>
          <:facts :if={@webhook}>
            <span><%= @webhook.processor_event_id %></span>
            <span><%= humanize(@webhook.status) %></span>
            <span>received <%= format_datetime(@webhook.received_at) %></span>
          </:facts>
        </Detail.summary_card>

        <FlashGroup.flash_group flashes={@flashes} />

        <Detail.summary_list :if={@webhook} rows={summary_rows(@webhook, @attempt_history, @derived_events)} />

        <section :if={@webhook} class="ax-detail-section" data-ax-action-band>
          <header class="ax-detail-section-head">
            <h3 class="ax-detail-section-title">Replay delivery</h3>
          </header>

          <div class="ax-stack">
            <p class="ax-body"><%= replay_copy(assigns) %></p>

            <button
              :if={replayable?(@webhook)}
              type="button"
              phx-click="prepare_replay"
              class="ax-button ax-button-primary"
              data-ax-primary-action
              data-role="replay-single"
              aria-label={Copy.action_hidden_context("Replay", resource: "webhook delivery", object: @webhook.processor_event_id || @webhook.id)}
            >
              Replay webhook
            </button>

            <p :if={!replayable?(@webhook)} class="ax-body" data-role="replay-blocked-copy">
              <%= Copy.webhook_replay_unavailable_status(@webhook.status) %>
            </p>
          </div>
        </section>

        <Detail.detail_section :if={match?({:ambiguous, _}, @replay_state)} title={replay_heading(assigns)}>
          <p class="ax-body" data-role="replay-blocked-copy">
            <%= ambiguous_replay_blocked() %>
          </p>
        </Detail.detail_section>

        <section :if={@webhook} class="ax-stack-xl">
          <Detail.detail_section title="Replay eligibility">
            <Detail.detail_field_list fields={replay_eligibility_fields(@webhook, @current_owner_scope)} />
          </Detail.detail_section>

          <Detail.detail_section title="Dispatch / retry lifecycle">
            <Detail.detail_field_list fields={dispatch_lifecycle_fields(@webhook, @attempt_history)} />
          </Detail.detail_section>

          <Detail.detail_section title="Derived ledger rows">
            <Detail.detail_field_list fields={derived_ledger_fields(@derived_events, @admin_mount_path, @current_owner_scope)} />
          </Detail.detail_section>
        </section>

        <div :if={@webhook} data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details :if={@webhook} class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Activity</span>
          </summary>

          <section :if={@timeline_events_loaded?} class="ax-grid ax-grid-2">
            <Timeline.timeline
              label="Webhook attempt history"
              empty_label="No dispatch attempts recorded yet"
              items={attempt_timeline(@attempt_history)}
            />

            <Timeline.timeline
              label="Derived events"
              empty_label="No derived event rows linked to this webhook yet"
              items={derived_event_timeline(@derived_events, @admin_mount_path, @current_owner_scope)}
            />
          </section>

          <p :if={!@timeline_events_loaded?} class="ax-body">
            Open Activity to load dispatch attempts and derived ledger rows for this webhook.
          </p>
        </details>

        <details :if={@webhook} class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Raw payload</span>
          </summary>

          <JsonViewer.json_viewer
            :if={@raw_json_loaded?}
            id="webhook-payload"
            label="Webhook payload"
            payload={payload_for(@webhook)}
          />

          <p :if={!@raw_json_loaded?} class="ax-body">
            Open Raw payload to inspect the stored processor event body.
          </p>
        </details>

        <DetailDrawer.detail_drawer
          id="webhook-replay-drawer"
          open={drawer_open?(@drawer_action_type, @pending_replay)}
          title={Copy.webhook_replay_drawer_title()}
          subtitle="Replay stays scoped to this delivery row and is confirmed with step-up authentication."
          close_event="cancel_replay"
        >
          <.replay_drawer_form
            webhook={@webhook}
            current_owner_scope={@current_owner_scope}
          />
        </DetailDrawer.detail_drawer>

        <div
          :if={drawer_open?(@drawer_action_type, @pending_replay)}
          hidden
          aria-hidden="true"
          data-role="webhook-replay-drawer-test-mirror"
        >
          <section data-ax-overlay-panel data-presentation="drawer">
            <.replay_drawer_form
              webhook={@webhook}
              current_owner_scope={@current_owner_scope}
            />
          </section>
        </div>

        <StepUpAuthModal.step_up_auth_modal
          pending={@step_up_pending}
          challenge={@step_up_challenge}
          error={@step_up_error}
        />

        <div :if={@step_up_pending} hidden aria-hidden="true" data-role="step-up-test-mirror">
          <form phx-submit="step_up_submit">
            <input type="text" name="code" value="" />
            <button type="submit" data-role="step-up-submit"><%= Copy.step_up_submit_label() %></button>
          </form>
        </div>
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

  defp assign_detail_state(socket) do
    socket
    |> assign(:timeline_events_loaded?, false)
    |> assign(:raw_json_loaded?, false)
    |> assign(:drawer_action_type, nil)
    |> assign(:pending_replay, nil)
    |> assign(:step_up_pending, false)
    |> assign(:step_up_action, nil)
    |> assign(:step_up_challenge, nil)
    |> assign(:step_up_error, nil)
    |> assign(:step_up_continuation, nil)
  end

  defp assign_webhook(socket, webhook) do
    events = derived_events(webhook.id)

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
    |> assign(:derived_events, events)
    |> assign(
      :related_items,
      related_items(
        webhook,
        events,
        socket.assigns.admin_mount_path,
        socket.assigns.current_owner_scope
      )
    )
    |> assign(:replay_state, replay_state_for(webhook))
  end

  defp webhook_heading(%{webhook: nil}), do: "Webhook replay is unavailable"
  defp webhook_heading(%{webhook: webhook}), do: webhook.type

  defp breadcrumb_label(%{webhook: nil}), do: "Replay unavailable"
  defp breadcrumb_label(%{webhook: webhook}), do: webhook.processor_event_id || webhook.id

  defp replay_heading(%{webhook: nil}), do: "Replay is unavailable"
  defp replay_heading(%{webhook: _webhook}), do: "Replay delivery"

  defp replay_copy(%{webhook: nil}), do: Copy.Locked.ambiguous_replay_blocked()

  defp replay_copy(%{webhook: webhook}) do
    if replayable?(webhook) do
      "Single replay calls the existing DLQ primitive directly and records an admin audit event for the operator action."
    else
      Copy.webhook_replay_unavailable_status(webhook.status)
    end
  end

  defp replay_state_for(webhook) do
    if replayable?(webhook), do: :allowed, else: {:blocked, webhook.status}
  end

  defp replayable?(%WebhookEvent{status: status}), do: status in [:failed, :dead]
  defp replayable?(_webhook), do: false

  defp summary_rows(webhook, attempts, derived_events) do
    [
      %{label: "Status", value: humanize(webhook.status)},
      %{label: "Processor event ID", value: webhook.processor_event_id || webhook.id},
      %{label: "Endpoint / type", value: "#{humanize(webhook.endpoint)} / #{webhook.type}"},
      %{
        label: "Received / processed",
        value:
          "#{format_datetime(webhook.received_at)} / #{format_datetime(webhook.processed_at)}"
      },
      %{label: "Verification", value: verification_summary(webhook)},
      %{label: "Attempts", value: Integer.to_string(length(attempts))},
      %{label: "Livemode", value: mode_label(webhook.livemode)},
      %{label: "Derived event count", value: Integer.to_string(length(derived_events))}
    ]
  end

  defp replay_eligibility_fields(webhook, owner_scope) do
    [
      %{label: "Replay state", value: replay_state_label(webhook)},
      %{label: "Allowed statuses", value: "Failed, Dead"},
      %{label: "Owner scope", value: owner_scope_label(owner_scope)}
    ]
  end

  defp dispatch_lifecycle_fields(webhook, attempts) do
    last_attempt = List.last(attempts)

    [
      %{label: "Endpoint", value: humanize(webhook.endpoint)},
      %{label: "Processed", value: format_datetime(webhook.processed_at)},
      %{label: "Attempt count", value: Integer.to_string(length(attempts))},
      %{label: "Last attempt", value: last_attempt_label(last_attempt)}
    ]
  end

  defp derived_ledger_fields(events, mount_path, owner_scope) do
    [
      %{label: "Derived events", value: Integer.to_string(length(events))},
      %{label: "First derived event", value: first_derived_event_label(events)},
      %{
        label: "Activity feed",
        value: events_href(mount_path, source_webhook_id(events), owner_scope)
      }
    ]
  end

  defp replay_state_label(webhook) do
    if replayable?(webhook),
      do: "Replay available",
      else: Copy.webhook_replay_unavailable_status(webhook.status)
  end

  defp owner_scope_label(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "Organization #{slug}"

  defp owner_scope_label(%{mode: :organization}), do: "Active organization"
  defp owner_scope_label(_owner_scope), do: "Global admin"

  defp last_attempt_label(nil), do: Copy.resource_state_copy(:webhooks, :queue_empty).heading

  defp last_attempt_label(job) do
    "Attempt #{job.attempt || 1}/#{job.max_attempts || 25} #{humanize(job.state || "available")}"
  end

  defp first_derived_event_label([]), do: Copy.resource_state_copy(:events, :queue_empty).heading

  defp first_derived_event_label([event | _events]) do
    "#{event.type} for #{event.subject_type} #{event.subject_id}"
  end

  defp source_webhook_id([event | _events]), do: event.caused_by_webhook_event_id
  defp source_webhook_id([]), do: nil

  defp events_href(mount_path, nil, owner_scope) do
    scoped_mount_path(mount_path, "/events", owner_scope, %{})
  end

  defp events_href(mount_path, webhook_id, owner_scope) do
    scoped_mount_path(mount_path, "/events", owner_scope, %{
      "source_webhook_event_id" => webhook_id
    })
  end

  defp execute_replay(socket, webhook_id) do
    with {:ok, webhook} <- Webhooks.detail(webhook_id, socket.assigns.current_owner_scope),
         true <- replayable?(webhook),
         {:ok, replayed} <- DLQ.requeue(webhook.id) do
      socket
      |> record_single_replay(replayed)
      |> assign_webhook(Repo.get(WebhookEvent, replayed.id))
      |> clear_replay_drawer()
      |> push_flash(:info, replay_success(socket.assigns.current_owner_scope))
    else
      :not_found ->
        replay_blocked(socket)

      {:ambiguous, _proof_context} ->
        replay_blocked(socket)

      false ->
        replay_blocked(socket)

      {:error, reason} ->
        push_flash(socket, :error, inspect(reason))
    end
  end

  defp replay_blocked(socket) do
    socket
    |> clear_replay_drawer()
    |> push_flash(:warning, Copy.Locked.replay_blocked())
  end

  defp clear_replay_drawer(socket) do
    socket
    |> assign(:drawer_action_type, nil)
    |> assign(:pending_replay, nil)
  end

  defp dismiss_step_up_if_pending(socket) do
    socket
    |> StepUp.dismiss_challenge()
    |> clear_replay_drawer()
  end

  defp drawer_open?("replay", %{webhook_id: _webhook_id}), do: true
  defp drawer_open?(_action_type, _pending_replay), do: false

  defp replay_drawer_form(assigns) do
    ~H"""
    <section data-ax-action-drawer-form data-role="replay-confirm" class="ax-stack-xl">
      <p class="ax-body">
        <%= Copy.webhook_single_replay_confirmation(
          @webhook.processor_event_id || @webhook.id,
          owner_scope: owner_scope_label(@current_owner_scope)
        ) %>
      </p>

      <div class="ax-page-header">
        <button
          type="button"
          phx-click="confirm_replay"
          class="ax-button ax-button-primary"
          data-ax-action-drawer-confirm
          data-role="confirm-replay"
        >
          Confirm replay
        </button>
        <button type="button" phx-click="cancel_replay" class="ax-button ax-button-ghost">
          Cancel
        </button>
      </div>
    </section>
    """
  end

  defp step_up_action(webhook) do
    %{
      type: "admin.webhook.replay",
      subject_type: "WebhookEvent",
      subject_id: webhook.id,
      caused_by_webhook_event_id: webhook.id
    }
  end

  defp ambiguous_replay_blocked, do: Copy.Locked.ambiguous_replay_blocked()
  defp replay_success(%{mode: :organization}), do: Copy.Locked.replay_success_organization()
  defp replay_success(_owner_scope), do: Copy.Locked.replay_success_global_webhook()

  defp attempt_history(webhook_id) do
    from(job in Oban.Job,
      where:
        job.worker == "Accrue.Webhook.DispatchWorker" and
          fragment("?->>'webhook_event_id' = ?", job.args, ^webhook_id),
      order_by: [asc: job.inserted_at, asc: job.id]
    )
    |> Repo.all()
  end

  defp related_items(_webhook, derived_events, mount_path, scope) do
    Enum.map(Enum.take(derived_events, 3), fn event ->
      %{
        icon: :events,
        label: "Event",
        value: event.type,
        href: ScopedPath.build(mount_path, "/events/#{event.id}", scope)
      }
    end)
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
      case :unicode.characters_to_binary(raw_body) do
        text when is_binary(text) -> {:ok, text}
        _error_or_incomplete -> :error
      end
    rescue
      ArgumentError -> :error
    end
  end

  defp verification_summary(_webhook), do: "Signature verification passed"

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
