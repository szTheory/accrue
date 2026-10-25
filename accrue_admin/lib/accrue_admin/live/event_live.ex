defmodule AccrueAdmin.Live.EventLive do
  @moduledoc false

  use Phoenix.LiveView

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    Icon,
    IdBadge,
    JsonViewer,
    RelatedResources,
    Timestamp
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.{Charges, Customers, Invoices, Subscriptions, Webhooks}
  alias AccrueAdmin.Queries.Events
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(%{"id" => event_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case read_event(event_id, socket.assigns.current_owner_scope) do
      :unavailable ->
        {:ok,
         socket
         |> assign_shell(admin, event_id)
         |> assign(:event, nil)
         |> assign(:related_items, [])
         |> assign(:read_unavailable?, true)}

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, AccrueAdmin.Copy.Locked.owner_access_denied())
         |> redirect(to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/events"))}

      {:ok, event} ->
        mount_path = admin["mount_path"] || "/billing"
        owner_scope = socket.assigns.current_owner_scope

        {:ok,
         socket
         |> assign_shell(admin, event_id)
         |> assign(:event, event)
         |> assign(
           :related_items,
           related_items(event, mount_path, owner_scope)
         )
         |> assign(:read_unavailable?, false)}
    end
  end

  @impl true
  def handle_event("retry_read", _params, socket) do
    case read_event(socket.assigns.event_id, socket.assigns.current_owner_scope) do
      {:ok, event} ->
        {:noreply,
         socket
         |> assign(:event, event)
         |> assign(
           :related_items,
           related_items(
             event,
             socket.assigns.admin_mount_path,
             socket.assigns.current_owner_scope
           )
         )
         |> assign(:read_unavailable?, false)}

      :unavailable ->
        {:noreply,
         socket
         |> assign(:event, nil)
         |> assign(:related_items, [])
         |> assign(:read_unavailable?, true)}

      :not_found ->
        admin = %{"mount_path" => socket.assigns.admin_mount_path}

        {:noreply,
         socket
         |> put_flash(:error, AccrueAdmin.Copy.Locked.owner_access_denied())
         |> redirect(to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/events"))}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    destination =
      ScopedPath.return_destination(
        socket.assigns.admin_mount_path,
        params["return"],
        socket.assigns.current_owner_scope,
        nil,
        "/events"
      )

    {:noreply, assign(socket, :return_destination, destination)}
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
      <section class="ax-page ax-event-page">
        <div :if={@read_unavailable?} class="ax-card ax-data-table-unavailable" data-role="event-unavailable" role="alert">
          <p class="ax-heading">Event record unavailable</p>
          <p class="ax-body">This event could not be loaded. Its identity and related evidence are unknown until the read succeeds.</p>
          <button type="button" phx-click="retry_read" class="ax-button ax-button-secondary" data-role="retry-event-read">Retry read</button>
        </div>

        <Breadcrumbs.breadcrumbs
          group="Audit"
          :if={@event}
          items={[
            %{label: "Events", href: @return_destination.path},
            %{label: Copy.billing_event_label(@event.type)}
          ]}
        />

        <header :if={@event} class="ax-event-header">
          <h1 class="ax-display"><%= Copy.billing_event_label(@event.type) %></h1>
        </header>
        <Detail.summary_list :if={@event} rows={summary_rows(@event, @admin_mount_path)} class="ax-event-facts" />

        <div :if={@event} data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
          <section :if={@related_items == []} class="ax-card ax-related" aria-label={Copy.event_detail_related_resources_title()}>
            <header class="ax-related-head">
              <h3 class="ax-related-title"><%= Copy.event_detail_related_resources_title() %></h3>
            </header>
            <p class="ax-body"><%= event_related_resources_empty_body() %></p>
          </section>
        </div>

        <details
          :if={raw_payload_available?(@event)}
          id="event-raw-payload"
          open
          class="ax-detail-section"
          data-ax-event-payload
          phx-hook="PreserveDisclosure"
        >
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= Copy.event_detail_json_payload_label() %></span>
            <Icon.icon name={:chevron_down} size="sm" class="ax-event-payload-chevron" />
          </summary>
          <JsonViewer.json_viewer
            id="event-payload"
            label={Copy.event_detail_json_payload_label()}
            payload={raw_payload(@event)}
            show_heading={false}
          />
        </details>
      </section>
    </AppShell.app_shell>
    """
  end

  # --- private ---

  defp read_event(event_id, owner_scope) do
    try do
      if Application.get_env(:accrue_admin, :env) == :test and
           Application.get_env(:accrue_admin, :phase238_read_failure_fixture) == :event_detail do
        raise DBConnection.ConnectionError, message: "fixture database unavailable"
      end

      Events.detail(event_id, owner_scope)
    rescue
      _error in DBConnection.ConnectionError -> :unavailable
    end
  end

  defp summary_rows(event, _mount_path) do
    rows = [
      %{label: "Event type", value: event.type},
      %{label: "Event ID", value: copy_id(event.id, "event-id-#{event.id}", "event")},
      %{label: "Recorded by", value: actor_summary(event)},
      %{
        label: "#{event.subject_type || "Record"} ID",
        value:
          copy_id(event.subject_id, "event-subject-#{event.id}", event.subject_type || "record")
      },
      %{label: "Source webhook", value: source_webhook_summary(event)},
      %{
        label: "Recorded time",
        value: timestamp_value(event.inserted_at, "event-recorded-summary-#{event.id}")
      }
    ]

    case livemode_summary(event) do
      nil -> rows
      value -> rows ++ [%{label: "Livemode", value: value}]
    end
  end

  defp event_related_resources_empty_body, do: Copy.event_detail_related_resources_empty()

  defp raw_payload(%{data: data} = event) do
    %{
      "data" => data || %{},
      "schema_version" => event.schema_version,
      "trace_id" => event.trace_id,
      "idempotency_key" => event.idempotency_key
    }
  end

  defp raw_payload_available?(%{data: data}) when is_map(data), do: map_size(data) > 0
  defp raw_payload_available?(_event), do: false

  defp assign_shell(socket, admin, event_id) do
    socket
    |> assign(:page_title, "Event")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:event_id, event_id)
    |> assign(:return_destination, %{
      path:
        scoped_events_path(admin["mount_path"] || "/billing", socket.assigns.current_owner_scope),
      label: "Back to events"
    })
    |> assign(
      :current_path,
      (admin["mount_path"] || "/billing") <> "/events/#{event_id}"
    )
  end

  defp related_items(event, mount_path, scope) do
    webhook_items =
      if authorized_detail?(Webhooks, event.caused_by_webhook_event_id, scope) do
        [
          %{
            icon: :webhooks,
            label: "Source webhook",
            value: event.caused_by_webhook_event_id,
            href:
              ScopedPath.build(
                mount_path,
                "/webhooks/#{event.caused_by_webhook_event_id}",
                scope
              )
          }
        ]
      else
        []
      end

    entity_items =
      case subject_href(event, mount_path, scope) do
        nil ->
          []

        href ->
          [
            %{
              icon: subject_icon(event.subject_type),
              label: event.subject_type,
              value: event.subject_id,
              href: href
            }
          ]
      end

    actor_items =
      case actor_href(event, mount_path, scope) do
        nil ->
          []

        href ->
          [
            %{
              icon: actor_icon(event.actor_type),
              label: "Actor",
              value: event.actor_id,
              href: href
            }
          ]
      end

    Enum.take(webhook_items ++ actor_items ++ entity_items, 3)
  end

  defp actor_href(%{actor_type: "webhook", caused_by_webhook_event_id: id}, mount_path, scope)
       when is_binary(id) do
    if authorized_detail?(Webhooks, id, scope),
      do: ScopedPath.build(mount_path, "/webhooks/#{id}", scope)
  end

  defp actor_href(_event, _mount_path, _scope), do: nil

  defp subject_href(%{subject_type: "Customer", subject_id: id}, mount_path, scope),
    do: authorized_href(Customers, id, mount_path, "/customers/#{id}", scope)

  defp subject_href(%{subject_type: "Subscription", subject_id: id}, mount_path, scope),
    do: authorized_href(Subscriptions, id, mount_path, "/subscriptions/#{id}", scope)

  defp subject_href(%{subject_type: "Invoice", subject_id: id}, mount_path, scope),
    do: authorized_href(Invoices, id, mount_path, "/invoices/#{id}", scope)

  defp subject_href(%{subject_type: "Charge", subject_id: id}, mount_path, scope),
    do: authorized_href(Charges, id, mount_path, "/payments/#{id}", scope)

  defp subject_href(%{subject_type: "WebhookEvent", subject_id: id}, mount_path, scope),
    do: authorized_href(Webhooks, id, mount_path, "/webhooks/#{id}", scope)

  defp subject_href(_event, _mount_path, _scope), do: nil

  defp authorized_href(module, id, mount_path, suffix, scope) do
    if authorized_detail?(module, id, scope), do: ScopedPath.build(mount_path, suffix, scope)
  end

  defp authorized_detail?(module, id, scope) when is_binary(id) do
    case apply(module, :detail, [id, scope]) do
      {:ok, %{id: ^id}} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp authorized_detail?(_module, _id, _scope), do: false

  defp subject_icon("Customer"), do: :users
  defp subject_icon("Subscription"), do: :subscriptions
  defp subject_icon("Invoice"), do: :invoices
  defp subject_icon("Charge"), do: :payments
  defp subject_icon("WebhookEvent"), do: :webhooks
  defp subject_icon(_), do: :events

  defp actor_icon("webhook"), do: :webhooks
  defp actor_icon(_actor_type), do: :users

  defp actor_summary(%{actor_type: nil, actor_id: nil}), do: "--"
  defp actor_summary(%{actor_type: "system", actor_id: nil}), do: "App"
  defp actor_summary(%{actor_type: type, actor_id: nil}), do: type || "--"

  defp actor_summary(%{actor_type: type, actor_id: id, id: event_id}) do
    assigns = %{type: type || "Actor", value: to_string(id), id: "event-actor-#{event_id}"}

    ~H"""
    <span class="ax-timeline-subject">
      <span><%= @type %></span>
      <IdBadge.id_badge id={@id} id_value={@value} label={"Copy actor ID " <> @value} copy_label="actor ID" variant="plain" />
    </span>
    """
  end

  defp source_webhook_summary(%{caused_by_webhook_event_id: nil}),
    do: Copy.BillingEvent.event_detail_no_linked_webhook()

  defp source_webhook_summary(%{caused_by_webhook_event_id: id, id: event_id}),
    do: copy_id(id, "event-webhook-#{event_id}", "webhook")

  defp livemode_summary(%{data: %{"payload" => %{"livemode" => value}}}),
    do: livemode_label(value)

  defp livemode_summary(%{data: %{"livemode" => value}}), do: livemode_label(value)
  defp livemode_summary(_event), do: nil

  defp livemode_label(true), do: "Live"
  defp livemode_label(false), do: "Test"
  defp livemode_label(_value), do: nil

  defp copy_id(nil, _id, _kind), do: "Unavailable"

  defp copy_id(value, id, kind) do
    assigns = %{
      value: to_string(value),
      id: id,
      label: "Copy #{kind} ID #{value}",
      copy_label: String.downcase(kind) <> " ID"
    }

    ~H"""
    <IdBadge.id_badge id={@id} id_value={@value} label={@label} copy_label={@copy_label} variant="plain" />
    """
  end

  defp timestamp_value(%DateTime{} = value, id) do
    assigns = %{value: value, id: id}

    ~H"""
    <Timestamp.timestamp value={@value} id={@id} />
    """
  end

  defp timestamp_value(_value, _id), do: "Time unavailable"

  defp scoped_events_path(mount_path, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> "/events?org=" <> slug
  end

  defp scoped_events_path(mount_path, _owner_scope), do: mount_path <> "/events"

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
