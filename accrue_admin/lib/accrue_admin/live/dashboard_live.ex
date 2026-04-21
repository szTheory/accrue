defmodule AccrueAdmin.Live.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice, Query, Subscription}
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, KpiCard, Timeline}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    stats = dashboard_stats()

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:stats, stats)
     |> assign(:recent_events, recent_events())
     |> assign(:webhook_health, webhook_health())}
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
          <Breadcrumbs.breadcrumbs items={[%{label: Copy.dashboard_breadcrumb_home()}]} />
          <p class="ax-eyebrow"><%= Copy.dashboard_chrome_eyebrow() %></p>
          <h2 class="ax-display"><%= Copy.dashboard_display_headline() %></h2>
          <p class="ax-body ax-page-copy">
            <%= Copy.dashboard_page_copy_primary() %>
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label={Copy.dashboard_kpi_section_aria_label()}>
          <KpiCard.kpi_card
            label={Copy.dashboard_kpi_customers_label()}
            value={Integer.to_string(@stats.customer_count)}
            href={ScopedPath.build(@admin_mount_path, "/customers", @current_owner_scope)}
            aria_label={Copy.dashboard_kpi_customers_aria_label()}
          >
            <:meta><%= Copy.dashboard_kpi_customers_meta() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={Copy.dashboard_kpi_active_subscriptions_label()}
            value={Integer.to_string(@stats.active_subscription_count)}
            delta={
              Integer.to_string(@stats.canceling_subscription_count) <>
                Copy.dashboard_kpi_active_subscriptions_canceling_suffix()
            }
            delta_tone="amber"
            href={ScopedPath.build(@admin_mount_path, "/subscriptions", @current_owner_scope)}
            aria_label={Copy.dashboard_kpi_subscriptions_aria_label()}
          >
            <:meta><%= Copy.dashboard_kpi_active_subscriptions_meta() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={Copy.dashboard_kpi_open_invoice_balance_label()}
            value={format_minor(@stats.open_invoice_balance_minor, "usd")}
            delta={
              Integer.to_string(@stats.open_invoice_count) <>
                Copy.dashboard_kpi_open_invoice_delta_suffix()
            }
            delta_tone="cobalt"
            href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope)}
            aria_label={Copy.dashboard_kpi_invoices_aria_label()}
          >
            <:meta><%= Copy.dashboard_kpi_open_invoice_balance_meta() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={Copy.dashboard_kpi_webhook_backlog_label()}
            value={Integer.to_string(@stats.blocked_webhook_count)}
            delta={
              Integer.to_string(@stats.events_last_day_count) <>
                Copy.dashboard_kpi_webhook_events_suffix()
            }
            delta_tone={if(@stats.blocked_webhook_count > 0, do: "amber", else: "moss")}
            href={ScopedPath.build(@admin_mount_path, "/webhooks", @current_owner_scope)}
            aria_label={Copy.dashboard_kpi_webhooks_aria_label()}
          >
            <:meta><%= Copy.dashboard_kpi_webhook_backlog_meta() %></:meta>
          </KpiCard.kpi_card>
        </section>

        <section class="ax-grid ax-grid-2" aria-label={Copy.dashboard_activity_section_aria_label()}>
          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow"><%= Copy.dashboard_activity_event_ledger_eyebrow() %></p>
              <h3 class="ax-heading"><%= Copy.dashboard_activity_recent_local_heading() %></h3>
            </header>

            <Timeline.timeline
              label={Copy.dashboard_timeline_events_label()}
              empty_label={Copy.dashboard_timeline_events_empty()}
              items={@recent_events}
            />
          </article>

          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow"><%= Copy.dashboard_activity_webhook_health_eyebrow() %></p>
              <h3 class="ax-heading"><%= Copy.dashboard_activity_projection_pipeline_heading() %></h3>
            </header>

            <Timeline.timeline
              label={Copy.dashboard_timeline_webhooks_label()}
              empty_label={Copy.dashboard_timeline_webhooks_empty()}
              items={@webhook_health}
            />
          </article>
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

  defp dashboard_stats do
    open_invoice_statuses = [:draft, :open]

    %{
      customer_count: Repo.aggregate(Customer, :count, :id),
      active_subscription_count: Subscription |> Query.active() |> Repo.aggregate(:count, :id),
      canceling_subscription_count:
        Subscription |> Query.canceling() |> Repo.aggregate(:count, :id),
      open_invoice_count:
        Invoice
        |> where([invoice], invoice.status in ^open_invoice_statuses)
        |> Repo.aggregate(:count, :id),
      open_invoice_balance_minor:
        Invoice
        |> where([invoice], invoice.status in ^open_invoice_statuses)
        |> select([invoice], coalesce(sum(invoice.amount_remaining_minor), 0))
        |> Repo.one()
        |> Kernel.||(0),
      blocked_webhook_count:
        WebhookEvent
        |> where([event], event.status in [:failed, :dead])
        |> Repo.aggregate(:count, :id),
      events_last_day_count:
        Event
        |> where(
          [event],
          event.inserted_at >= ^DateTime.add(DateTime.utc_now(), -86_400, :second)
        )
        |> Repo.aggregate(:count, :id)
    }
  end

  defp recent_events do
    Event
    |> order_by([event], desc: event.inserted_at, desc: event.id)
    |> limit(6)
    |> Repo.all()
    |> Enum.map(fn event ->
      %{
        title: event.type,
        at: format_datetime(event.inserted_at),
        body: "#{event.subject_type} #{event.subject_id}",
        status: event.actor_type,
        tone: if(event.actor_type == "admin", do: :cobalt, else: :slate),
        meta: event.actor_id && "actor #{event.actor_id}"
      }
    end)
  end

  defp webhook_health do
    WebhookEvent
    |> order_by([event], desc: event.inserted_at, desc: event.id)
    |> limit(6)
    |> Repo.all()
    |> Enum.map(fn event ->
      %{
        title: event.type,
        at: format_datetime(event.received_at || event.inserted_at),
        body: "#{event.processor} #{event.processor_event_id}",
        status: event.status,
        tone: webhook_tone(event.status),
        meta: endpoint_label(event.endpoint)
      }
    end)
  end

  defp webhook_tone(status) when status in [:succeeded, :processing], do: :moss
  defp webhook_tone(status) when status in [:received, :replayed], do: :cobalt
  defp webhook_tone(status) when status in [:failed, :dead], do: :amber
  defp webhook_tone(_status), do: :slate

  defp endpoint_label(nil), do: nil
  defp endpoint_label(endpoint), do: "endpoint #{endpoint}"

  defp format_minor(amount_minor, _currency) when is_integer(amount_minor) do
    dollars = amount_minor / 100
    "$" <> :erlang.float_to_binary(dollars, decimals: 2)
  end

  defp format_minor(%Decimal{} = amount_minor, currency) do
    amount_minor
    |> Decimal.to_integer()
    |> format_minor(currency)
  end

  defp format_minor(_amount_minor, _currency), do: "$0.00"

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Unknown"

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
