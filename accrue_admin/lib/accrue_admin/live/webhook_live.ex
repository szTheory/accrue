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
    Detail,
    DetailDrawer,
    FlashGroup,
    JsonViewer,
    PageHeader,
    RelatedResources,
    StepUpAuthModal,
    Timeline,
    Timestamp
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Webhooks
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.StepUp

  @impl true
  def mount(%{"id" => webhook_id} = params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    return_destination =
      ScopedPath.return_destination(
        admin["mount_path"] || "/billing",
        Map.get(params, "return_to"),
        socket.assigns.current_owner_scope,
        nil,
        "/webhooks"
      )

    case fetch_webhook(webhook_id, socket.assigns.current_owner_scope) do
      :unavailable ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:return_destination, return_destination)
         |> assign(:requested_webhook_id, webhook_id)
         |> assign(:webhook, nil)
         |> assign(:attempt_history, [])
         |> assign(:derived_events, [])
         |> assign(:related_items, [])
         |> assign(:flashes, [])
         |> assign_detail_state()
         |> assign(:detail_unavailable?, true)
         |> assign(:replay_state, :unavailable)}

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/webhooks")
         )}

      {:ok, webhook, attempts, events} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:return_destination, return_destination)
         |> assign(:requested_webhook_id, webhook_id)
         |> assign(:flashes, [])
         |> assign_detail_state()
         |> assign_webhook(webhook, attempts, events)
         |> assign(:detail_unavailable?, false)}

      {:ambiguous, proof_context} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:return_destination, return_destination)
         |> assign(:requested_webhook_id, webhook_id)
         |> assign(:webhook, nil)
         |> assign(:attempt_history, [])
         |> assign(:derived_events, [])
         |> assign(:related_items, [])
         |> assign(:flashes, [])
         |> assign_detail_state()
         |> assign(:replay_state, {:ambiguous, proof_context})
         |> assign(:detail_unavailable?, false)}
    end
  end

  def handle_event("retry_read", _params, socket) do
    case fetch_webhook(socket.assigns.requested_webhook_id, socket.assigns.current_owner_scope) do
      {:ok, webhook, attempts, events} ->
        {:noreply,
         socket
         |> assign(:flashes, Enum.reject(socket.assigns.flashes, &(&1.kind == :warning)))
         |> assign(:detail_unavailable?, false)
         |> assign_webhook(webhook, attempts, events)}

      :unavailable ->
        {:noreply,
         socket
         |> clear_webhook_evidence()
         |> assign(:detail_unavailable?, true)
         |> assign(:replay_state, :unavailable)}

      :not_found ->
        {:noreply,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to:
             scoped_admin_path(
               %{"mount_path" => socket.assigns.admin_mount_path},
               socket.assigns.current_owner_scope,
               "/webhooks"
             )
         )}

      {:ambiguous, proof_context} ->
        {:noreply,
         socket
         |> clear_webhook_evidence()
         |> assign(:detail_unavailable?, false)
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
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page" phx-window-keydown="step_up_escape" phx-key="escape">
        <PageHeader.page_header
          breadcrumbs={webhook_breadcrumbs(assigns)}
          title={webhook_heading(assigns)}
          component_group="webhook-detail-header"
          data-role="webhook-page-header"
        >
          <:description :if={@webhook}>
            <span><%= @webhook.type %></span>
            <span aria-hidden="true"> · </span>
            <span data-role="webhook-observed-status"><%= humanize(@webhook.status) %></span>
          </:description>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={@flashes} />

        <div :if={@detail_unavailable?} class="ax-card ax-data-table-unavailable" data-role="webhook-unavailable" role="alert">
          <p class="ax-heading">Webhook history unavailable</p>
          <p class="ax-body">This delivery and its local attempt history could not be loaded. Its current status and ownership are unknown.</p>
          <button type="button" phx-click="retry_read" class="ax-button ax-button-secondary" data-role="retry-webhook-read">Retry read</button>
        </div>

        <section :if={@webhook} class="ax-detail-section" data-ax-action-band>
          <header class="ax-detail-section-head">
            <h2 class="ax-detail-section-title">Replay webhook</h2>
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
            >
              Replay webhook
            </button>
          </div>
        </section>

        <Detail.detail_section :if={match?({:ambiguous, _}, @replay_state)} title="Replay unavailable">
          <p class="ax-body" data-role="replay-blocked-copy">
            <%= ambiguous_replay_blocked() %>
          </p>
        </Detail.detail_section>

        <Detail.summary_list
          :if={@webhook}
          rows={
            summary_rows(
              @webhook,
              @attempt_history,
              @derived_events,
              @admin_mount_path,
              @current_owner_scope
            )
          }
        />

        <div :if={@webhook} data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details :if={@webhook} id={"webhook-activity-#{@webhook.id}"} class="ax-detail-section" data-ax-lazy-activity phx-hook="PreserveDisclosure" phx-click="load_activity">
          <summary class="ax-detail-section-head ax-disclosure-summary" aria-controls="webhook-activity-content">
            <span class="ax-detail-section-title">Activity</span>
          </summary>

          <section id="webhook-activity-content">
            <p
              :if={@timeline_events_loaded? and @attempt_history == [] and @derived_events == []}
              class="ax-body"
              data-role="webhook-activity-empty"
            >
              No dispatch attempts or derived billing events are recorded for this webhook yet.
            </p>

            <div
              :if={@timeline_events_loaded? and (@attempt_history != [] or @derived_events != [])}
              class="ax-grid ax-grid-2"
            >
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
            </div>
          </section>

          <p :if={!@timeline_events_loaded?} class="ax-body">
            Open Activity to load dispatch attempts and derived ledger rows for this webhook.
          </p>
        </details>

        <details :if={@webhook} id="webhook-raw-payload" class="ax-detail-section" data-ax-lazy-json phx-hook="PreserveDisclosure" phx-click="load_raw_json">
          <summary class="ax-detail-section-head ax-disclosure-summary" aria-controls="webhook-payload-content">
            <span class="ax-detail-section-title">Raw payload</span>
          </summary>

          <section id="webhook-payload-content">
            <JsonViewer.json_viewer
              :if={@raw_json_loaded?}
              id="webhook-payload"
              label="Webhook payload"
              payload={payload_for(@webhook)}
            />

            <p :if={!@raw_json_loaded?} class="ax-body">
              Open Raw payload to inspect the stored processor event body.
            </p>
          </section>
        </details>

        <DetailDrawer.detail_drawer
          id="webhook-replay-drawer"
          open={drawer_open?(@drawer_action_type, @pending_replay)}
          title={Copy.webhook_replay_drawer_title()}
          subtitle="Replay stays scoped to this delivery row and is confirmed with step-up authentication."
          close_event="cancel_replay"
          close_label="Cancel replay"
          show_close_button={false}
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
    |> assign(:detail_unavailable?, false)
  end

  defp assign_webhook(socket, webhook, attempts, events) do
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
    |> assign(:attempt_history, attempts)
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

  defp clear_webhook_evidence(socket) do
    socket
    |> assign(:webhook, nil)
    |> assign(:attempt_history, [])
    |> assign(:derived_events, [])
    |> assign(:related_items, [])
  end

  defp refresh_webhook_after_replay(socket, webhook_id) do
    case fetch_webhook(webhook_id, socket.assigns.current_owner_scope) do
      {:ok, webhook, attempts, events} ->
        socket
        |> assign(:detail_unavailable?, false)
        |> assign_webhook(webhook, attempts, events)

      _unavailable_or_inaccessible ->
        socket
        |> clear_webhook_evidence()
        |> assign(:detail_unavailable?, true)
        |> assign(:replay_state, :unavailable)
    end
  end

  defp fetch_webhook(webhook_id, owner_scope) do
    try do
      if Application.get_env(:accrue_admin, :env) == :test and
           Application.get_env(:accrue_admin, :phase238_read_failure_fixture) == :webhook_detail do
        raise DBConnection.ConnectionError, message: "fixture database unavailable"
      end

      case read_webhook_detail(webhook_id, owner_scope) do
        {:ok, webhook} ->
          {:ok, webhook, attempt_history(webhook.id), derived_events(webhook.id)}

        result ->
          result
      end
    rescue
      _error in DBConnection.ConnectionError -> :unavailable
    end
  end

  defp read_webhook_detail(webhook_id, owner_scope) do
    if Mix.env() == :test do
      case Application.get_env(:accrue_admin, :webhook_detail_fun) do
        fun when is_function(fun, 2) -> fun.(webhook_id, owner_scope)
        _configured_fun -> Webhooks.detail(webhook_id, owner_scope)
      end
    else
      Webhooks.detail(webhook_id, owner_scope)
    end
  rescue
    _error in DBConnection.ConnectionError -> :unavailable
  end

  defp webhook_heading(%{webhook: nil}), do: "Webhook unavailable"
  defp webhook_heading(%{webhook: webhook}), do: webhook.processor_event_id || webhook.id

  defp webhook_breadcrumbs(assigns) do
    [
      %{label: "Webhooks", href: assigns.return_destination.path},
      %{label: "Webhook"}
    ]
  end

  defp replay_copy(%{webhook: nil, replay_state: :unavailable}),
    do: "Replay is unavailable while delivery history cannot be loaded. Retry the read first."

  defp replay_copy(%{webhook: nil}), do: Copy.Locked.ambiguous_replay_blocked()

  defp replay_copy(%{webhook: webhook}) do
    if replayable?(webhook) do
      "Queues another delivery attempt. Queue acceptance does not confirm processing."
    else
      Copy.webhook_replay_unavailable_status(webhook.status)
    end
  end

  defp replay_state_for(webhook) do
    if replayable?(webhook), do: :allowed, else: {:blocked, webhook.status}
  end

  defp replayable?(%WebhookEvent{status: status}), do: status in [:failed, :dead]
  defp replayable?(_webhook), do: false

  defp summary_rows(webhook, attempts, derived_events, mount_path, owner_scope) do
    [
      %{label: "Endpoint", value: humanize(webhook.endpoint)},
      %{
        label: "Received / processed",
        value: timestamp_pair(webhook.received_at, webhook.processed_at, webhook.id)
      },
      %{label: "Verification", value: verification_summary(webhook)},
      %{label: "Attempts", value: Integer.to_string(length(attempts))},
      %{
        label: "Event feed",
        value: events_href(mount_path, webhook.id, derived_events, owner_scope)
      },
      %{label: "Livemode", value: mode_label(webhook.livemode)},
      %{label: "Failure", value: failure_summary(attempts)},
      %{label: "Derived event count", value: Integer.to_string(length(derived_events))}
    ]
    |> Enum.reject(&is_nil(&1.value))
  end

  defp failure_summary(attempts) do
    case List.last(attempts) do
      %{errors: [_ | _] = errors} ->
        case List.last(errors) do
          %{"error" => message} when is_binary(message) and message != "" -> message
          %{error: message} when is_binary(message) and message != "" -> message
          _error -> "A dispatch attempt failed; inspect Activity for its recorded error."
        end

      _ ->
        nil
    end
  end

  defp owner_scope_label(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "Organization #{slug}"

  defp owner_scope_label(%{mode: :organization}), do: "Active organization"
  defp owner_scope_label(_owner_scope), do: "Global admin"

  defp events_href(mount_path, webhook_id, derived_events, owner_scope) do
    source_id =
      case derived_events do
        [event | _events] -> event.caused_by_webhook_event_id || webhook_id
        [] -> webhook_id
      end

    assigns = %{
      href:
        scoped_mount_path(mount_path, "/events", owner_scope, %{
          "source_webhook_event_id" => source_id
        })
    }

    ~H"""
    <a href={@href}>Open related events</a>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end

  defp execute_replay(socket, webhook_id) do
    owner_scope = socket.assigns.current_owner_scope

    with {:ok, webhook} <- read_webhook_detail(webhook_id, owner_scope),
         true <- replayable?(webhook),
         {:ok, replayed} <- requeue_delivery(webhook.id, owner_scope) do
      socket
      |> record_single_replay(replayed)
      |> refresh_webhook_after_replay(replayed.id)
      |> clear_replay_drawer()
      |> push_replay_outcome(owner_scope)
    else
      :not_found ->
        replay_blocked(socket)

      {:ambiguous, _proof_context} ->
        replay_blocked(socket)

      false ->
        replay_blocked(socket)

      {:error, :out_of_scope} ->
        replay_blocked(socket)

      :unavailable ->
        socket
        |> clear_replay_drawer()
        |> push_flash(
          :warning,
          "Replay was not queued because current delivery ownership could not be verified."
        )

      {:error, reason} ->
        _ = reason

        socket
        |> clear_replay_drawer()
        |> push_flash(
          :error,
          "Replay could not be queued. Confirm the delivery is still eligible and try again."
        )
    end
  end

  defp requeue_delivery(id, owner_scope) do
    authorize_fun = &Webhooks.owner_scope_allows_replay?(&1, owner_scope)

    if Mix.env() == :test do
      case Application.get_env(:accrue_admin, :webhook_requeue_fun) do
        fun when is_function(fun, 2) -> fun.(id, authorize_fun)
        _configured_fun -> DLQ.requeue(id, authorize_fun)
      end
    else
      DLQ.requeue(id, authorize_fun)
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
          Cancel replay
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

  defp push_replay_outcome(%{assigns: %{detail_unavailable?: true}} = socket, _owner_scope) do
    push_flash(
      socket,
      :warning,
      "Replay request accepted. Current processing status is unknown because delivery history could not be loaded. Retry read to check current status."
    )
  end

  defp push_replay_outcome(socket, owner_scope) do
    push_flash(
      socket,
      :info,
      "Replay request accepted. Processing has not been confirmed. #{replay_success(owner_scope)}"
    )
  end

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
        id: "webhook-attempt-#{job.id}",
        title: "Attempt #{job.attempt || 1}/#{job.max_attempts || 25}",
        at: job.inserted_at,
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
    if Enum.any?([job.attempted_at, job.completed_at, job.discarded_at], &match?(%DateTime{}, &1)) do
      assigns = %{job: job}

      ~H"""
      <span :if={match?(%DateTime{}, @job.attempted_at)}>attempted <Timestamp.timestamp value={@job.attempted_at} id={"webhook-attempted-#{@job.id}"} /></span>
      <span :if={match?(%DateTime{}, @job.completed_at)}> · completed <Timestamp.timestamp value={@job.completed_at} id={"webhook-completed-#{@job.id}"} /></span>
      <span :if={match?(%DateTime{}, @job.discarded_at)}> · discarded <Timestamp.timestamp value={@job.discarded_at} id={"webhook-discarded-#{@job.id}"} /></span>
      """
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()
      |> Phoenix.HTML.raw()
    end
  end

  defp derived_event_timeline(events, mount_path, owner_scope) do
    Enum.map(events, fn event ->
      %{
        id: "webhook-derived-event-#{event.id}",
        title: Copy.billing_event_label(event.type),
        at: event.inserted_at,
        body: "#{event.subject_type} #{event.subject_id}",
        tone: if(event.actor_type == "admin", do: :cobalt, else: :slate),
        details_label: "Inspect event evidence",
        details: event_evidence(event),
        meta: "Actor: #{event.actor_type || "Unavailable"} · event ##{event.id}",
        href: ScopedPath.build(mount_path, "/events/#{event.id}", owner_scope),
        href_label: "Open event"
      }
    end)
  end

  defp event_evidence(event) do
    [
      "Stored event key: #{event.type || "Unavailable"}",
      "Event ID: #{event.id || "Unavailable"}",
      "Actor ID: #{event.actor_id || "Unavailable"}",
      "Subject: #{event.subject_type || "Unavailable"} #{event.subject_id || "Unavailable"}",
      "Webhook delivery ID: #{event.caused_by_webhook_event_id || "Unavailable"}",
      "Recorded: #{exact_datetime(event.inserted_at)}"
    ]
    |> Enum.join("\n")
  end

  defp exact_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp exact_datetime(_value), do: "Unavailable"

  defp timestamp_pair(received_at, processed_at, webhook_id) do
    assigns = %{
      received_at: received_at,
      processed_at: processed_at,
      webhook_id: webhook_id
    }

    ~H"""
    <span>Received <Timestamp.timestamp value={@received_at} id={"webhook-summary-received-#{@webhook_id}"} /></span>
    <span> · Processed <Timestamp.timestamp value={@processed_at} id={"webhook-summary-processed-#{@webhook_id}"} /></span>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
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
