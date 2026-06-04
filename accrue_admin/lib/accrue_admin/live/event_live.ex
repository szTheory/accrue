defmodule AccrueAdmin.Live.EventLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Events.Event
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    RelatedResources
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(%{"id" => event_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case load_event(event_id, socket.assigns.current_owner_scope) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, AccrueAdmin.Copy.billing_event_not_found())
         |> redirect(
           to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/events")
         )}

      event ->
        mount_path = admin["mount_path"] || "/billing"
        owner_scope = socket.assigns.current_owner_scope

        {:ok,
         socket
         |> assign_shell(admin, event_id)
         |> assign(:event, event)
         |> assign(
           :related_items,
           related_items(event, mount_path, owner_scope)
         )}
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
        <Breadcrumbs.breadcrumbs
          items={[
            %{label: "Dashboard", href: @admin_mount_path},
            %{label: "Events", href: scoped_events_path(@admin_mount_path, @current_owner_scope)},
            %{label: @event.type}
          ]}
        />

        <Detail.summary_card eyebrow={Copy.event_detail_eyebrow()} title={@event.type}>
          <:facts>
            <dl class="ax-summary-facts-dl">
              <dt class="ax-label">Actor</dt>
              <dd class="ax-body"><%= @event.actor_type %> <%= @event.actor_id || "" %></dd>
              <dt class="ax-label">Subject</dt>
              <dd class="ax-body"><%= @event.subject_type %> <%= @event.subject_id %></dd>
              <dt class="ax-label">Recorded</dt>
              <dd class="ax-body"><%= format_datetime(@event.inserted_at) %></dd>
            </dl>
          </:facts>
        </Detail.summary_card>

        <Detail.detail_section title={Copy.event_detail_section_heading()}>
          <Detail.detail_field_list fields={[
            %{label: "Type", value: @event.type},
            %{label: "Actor type", value: @event.actor_type || "--"},
            %{label: "Actor ID", value: @event.actor_id || "--"},
            %{label: "Subject type", value: @event.subject_type || "--"},
            %{label: "Subject ID", value: @event.subject_id || "--"},
            %{label: "Recorded", value: format_datetime(@event.inserted_at)}
          ]} />
        </Detail.detail_section>

        <RelatedResources.related_resources items={@related_items} />
      </section>
    </AppShell.app_shell>
    """
  end

  # --- private ---

  defp load_event(event_id, _owner_scope) do
    case Integer.parse(event_id) do
      {id, ""} -> Repo.get(Event, id)
      _ -> nil
    end
  end

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
    |> assign(
      :current_path,
      (admin["mount_path"] || "/billing") <> "/events/#{event_id}"
    )
  end

  defp related_items(event, mount_path, scope) do
    webhook_items =
      if event.caused_by_webhook_event_id do
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

    Enum.take(webhook_items ++ entity_items, 3)
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

  defp subject_href(_event, _mount_path, _scope), do: nil

  defp subject_icon("Customer"), do: :users
  defp subject_icon("Subscription"), do: :subscriptions
  defp subject_icon("Invoice"), do: :invoices
  defp subject_icon("Charge"), do: :payments
  defp subject_icon("WebhookEvent"), do: :webhooks
  defp subject_icon(_), do: :events

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Unknown"

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
