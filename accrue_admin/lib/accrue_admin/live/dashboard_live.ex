defmodule AccrueAdmin.Live.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  alias AccrueAdmin.Components.{AppShell, FlashGroup, PageHeader, Timeline}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Events
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    socket = assign_shell(socket, admin)
    scope = socket.assigns[:current_owner_scope]
    events = recent_events(scope, socket.assigns.admin_mount_path)

    {:ok, assign(socket, recent_events: events)}
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
      <section class="ax-page ax-home">
        <PageHeader.page_header
          breadcrumb_group="Billing"
          breadcrumbs={[%{label: Copy.home_intro_headline()}]}
          title={Copy.home_intro_headline()}
        >
          <:description>
            <p class="ax-body">See what changed in customer billing, and open an event for details.</p>
          </:description>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={flash_messages(@flash)} />

        <section class="ax-home-section" aria-label="Recent billing activity">
          <header class="ax-section-head">
            <a class="ax-link-quiet" href={ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope)}>View events</a>
          </header>
          <Timeline.timeline
            label="Recent billing activity"
            empty_label="No recent billing activity in this scope."
            items={@recent_events}
          />
        </section>
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, Copy.dashboard_breadcrumb_home())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(
      :current_path,
      ScopedPath.build(
        admin["mount_path"] || "/billing",
        "",
        socket.assigns[:current_owner_scope]
      )
    )
  end

  defp recent_events(owner_scope, mount_path) do
    {events, _cursor} = Events.list(limit: 6, owner_scope: owner_scope)

    Enum.map(events, fn event ->
      %{
        title: Copy.billing_event_label(event.type),
        event_type: event.type,
        id: event.id,
        at: event.inserted_at,
        subject_type: event.subject_type,
        subject_id: event.subject_id,
        actor: event.actor_type,
        actor_id: event.actor_id,
        tone: AccrueAdmin.EventPresentation.for(event.type).tone,
        href: ScopedPath.build(mount_path, "/events/#{event.id}", owner_scope),
        href_label: "Open event"
      }
    end)
  end

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
  end

  defp default_brand do
    %{
      "name" => "Accrue",
      "logo_url" => nil,
      "primary_color" => "#254ee8",
      "secondary_color" => "#667085",
      "accent_color" => "#12b76a"
    }
  end
end
