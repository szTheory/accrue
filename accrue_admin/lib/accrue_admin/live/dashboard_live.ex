defmodule AccrueAdmin.Live.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  alias AccrueAdmin.Components.{AppShell, FlashGroup, Icon, PageHeader, Timeline}
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
          breadcrumbs={[%{label: Copy.dashboard_breadcrumb_home()}]}
          title={Copy.home_intro_headline()}
        >
          <:description>
            <p class="ax-body">Review recent audit activity or open a scoped billing record.</p>
          </:description>
          <:actions>
            <a class="ax-button ax-button-primary ax-button-sm" href={ScopedPath.build(@admin_mount_path, "/customers", @current_owner_scope)}>
              Customers <Icon.icon name={:arrow_right} size="sm" />
            </a>
            <button
              type="button"
              class="ax-button ax-button-secondary ax-button-sm"
              data-command-palette-trigger="true"
              data-ax-command-palette-trigger="true"
            >
              <%= Copy.home_customer_search_cta() %>
              <Icon.icon name={:search} size="sm" />
            </button>
            <a class="ax-button ax-button-secondary ax-button-sm" href={ScopedPath.build(@admin_mount_path, "/subscriptions", @current_owner_scope)}>
              Subscriptions <Icon.icon name={:arrow_right} size="sm" />
            </a>
          </:actions>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={flash_messages(@flash)} />

        <section class="ax-home-section" aria-label="Recent audit activity">
          <header class="ax-section-head">
            <h2 class="ax-heading">Recent audit activity</h2>
            <a class="ax-link-quiet" href={ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope)}>Open event ledger</a>
          </header>
          <Timeline.timeline
            label="Recent audit activity"
            empty_label="No recent audit activity in this scope."
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
    |> assign(:current_path, admin["mount_path"] || "/billing")
  end

  defp recent_events(owner_scope, mount_path) do
    {events, _cursor} = Events.list(limit: 6, owner_scope: owner_scope)

    Enum.map(events, fn event ->
      %{
        title: event.type,
        at: format_datetime(event.inserted_at),
        body: event_subject_summary(event),
        status: event.actor_type,
        tone: if(event.actor_type == "admin", do: :cobalt, else: :slate),
        meta: "Audit event",
        href: ScopedPath.build(mount_path, "/events/#{event.id}", owner_scope),
        href_label: "Open event"
      }
    end)
  end

  defp event_subject_summary(%{subject_type: subject_type, subject_id: subject_id}) do
    subject = if subject_type, do: to_string(subject_type), else: "Record"
    if subject_id, do: "#{subject} · #{subject_id}", else: "#{subject} without linked record"
  end

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
  end

  defp format_datetime(nil), do: "Time unavailable"
  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%Y-%m-%d %H:%M UTC")

  defp format_datetime(%NaiveDateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M UTC")

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
