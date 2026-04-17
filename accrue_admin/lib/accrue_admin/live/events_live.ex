defmodule AccrueAdmin.Live.EventsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Events.Event
  alias Accrue.Repo
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, KpiCard}
  alias AccrueAdmin.Queries.Events

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(:table_path, admin_path(admin, "/events"))
     |> assign(:summary, event_summary(socket.assigns.current_owner_scope))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:summary, event_summary(socket.assigns.current_owner_scope))}
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
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: @admin_mount_path},
              %{label: "Events"}
            ]}
          />
          <p class="ax-eyebrow"><%= activity_feed_eyebrow(@current_owner_scope) %></p>
          <h2 class="ax-display"><%= activity_feed_heading(@current_owner_scope) %></h2>
          <p class="ax-body ax-page-copy">
            <%= activity_feed_copy(@current_owner_scope) %>
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Event summary">
          <KpiCard.kpi_card label="Ledger rows" value={Integer.to_string(@summary.total_count)}>
            <:meta>Total append-only events recorded locally</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Webhook sourced"
            value={Integer.to_string(@summary.webhook_linked_count)}
            delta={Integer.to_string(@summary.admin_count) <> " admin"}
            delta_tone="cobalt"
          >
            <:meta>Rows linked back to a webhook cause chain</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Last 24h"
            value={Integer.to_string(@summary.last_day_count)}
            delta={Integer.to_string(@summary.unique_subject_types) <> " subject types"}
            delta_tone="moss"
          >
            <:meta>Recent cross-resource billing activity</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="events"
          query_module={Events}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          columns={[
            %{id: :type, label: "Event"},
            %{label: "Subject", render: &subject_summary/1},
            %{label: "Actor", render: &actor_summary/1},
            %{label: "Webhook source", render: &webhook_source_summary/1},
            %{label: "When", render: &when_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Subject", render: &subject_summary/1},
            %{label: "Actor", render: &actor_summary/1},
            %{label: "Webhook source", render: &webhook_source_summary/1},
            %{label: "When", render: &when_summary/1}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{id: :type, label: "Event type"},
            %{id: :actor_type, label: "Actor type"},
            %{id: :subject_type, label: "Subject type"},
            %{id: :source_webhook_event_id, label: "Source webhook id"}
          ]}
          empty_title="No event rows matched"
          empty_copy="Adjust the activity filters or wait for the next billing mutation."
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Events")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/events"))
  end

  defp event_summary(owner_scope) do
    day_ago = DateTime.add(DateTime.utc_now(), -86_400, :second)
    base_query = scoped_events_query(owner_scope)

    %{
      total_count: Repo.aggregate(base_query, :count, :id),
      webhook_linked_count:
        base_query
        |> where([event], not is_nil(event.caused_by_webhook_event_id))
        |> Repo.aggregate(:count, :id),
      admin_count:
        base_query
        |> where([event], event.actor_type == "admin")
        |> Repo.aggregate(:count, :id),
      last_day_count:
        base_query
        |> where([event], event.inserted_at >= ^day_ago)
        |> Repo.aggregate(:count, :id),
      unique_subject_types:
        base_query
        |> select([event], count(fragment("distinct ?", event.subject_type)))
        |> Repo.one()
    }
  end

  defp scoped_events_query(nil), do: Event
  defp scoped_events_query(%OwnerScope{mode: :global}), do: Event

  defp scoped_events_query(%OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      Event,
      [event],
      fragment(
        """
        EXISTS (
          SELECT 1
          FROM accrue_customers customers
          WHERE ? = 'Customer'
            AND customers.id::text = ?
            AND customers.owner_type = 'Organization'
            AND customers.owner_id = ?
        )
        OR EXISTS (
          SELECT 1
          FROM accrue_subscriptions subscriptions
          JOIN accrue_customers customers ON customers.id = subscriptions.customer_id
          WHERE ? = 'Subscription'
            AND subscriptions.id::text = ?
            AND customers.owner_type = 'Organization'
            AND customers.owner_id = ?
        )
        OR EXISTS (
          SELECT 1
          FROM accrue_invoices invoices
          JOIN accrue_customers customers ON customers.id = invoices.customer_id
          WHERE ? = 'Invoice'
            AND invoices.id::text = ?
            AND customers.owner_type = 'Organization'
            AND customers.owner_id = ?
        )
        """,
        event.subject_type,
        event.subject_id,
        ^organization_id,
        event.subject_type,
        event.subject_id,
        ^organization_id,
        event.subject_type,
        event.subject_id,
        ^organization_id
      )
    )
  end

  defp activity_feed_eyebrow(%OwnerScope{mode: :organization}), do: "Organization activity feed"
  defp activity_feed_eyebrow(_owner_scope), do: "Global activity feed"

  defp activity_feed_heading(%OwnerScope{mode: :organization}),
    do: "Billing activity for the active organization"

  defp activity_feed_heading(_owner_scope), do: "Append-only billing and admin activity"

  defp activity_feed_copy(%OwnerScope{mode: :organization}) do
    "This feed stays scoped to the active organization so linked webhook and admin activity can't reveal other billing owners."
  end

  defp activity_feed_copy(_owner_scope) do
    "This complements the scoped subject timelines with one operations-wide ledger view over `accrue_events`."
  end

  defp subject_summary(row), do: "#{row.subject_type} #{row.subject_id}"

  defp actor_summary(row) do
    case row.actor_id do
      nil -> humanize(row.actor_type)
      actor_id -> "#{humanize(row.actor_type)} #{actor_id}"
    end
  end

  defp webhook_source_summary(%{caused_by_webhook_event_id: nil}), do: "Direct"
  defp webhook_source_summary(%{caused_by_webhook_event_id: webhook_id}), do: webhook_id
  defp when_summary(row), do: format_datetime(row.inserted_at)
  defp card_title(row), do: row.type

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

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
