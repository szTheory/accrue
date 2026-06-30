defmodule AccrueAdmin.Live.DashboardLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice, MeterEvent, Query, Subscription}
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.AttentionCounts
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, Icon, KpiCard, Timeline}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    stats = dashboard_stats()
    socket = assign_shell(socket, admin)

    {:ok,
     socket
     |> assign(:stats, stats)
     |> assign(
       :attention,
       attention_items(
         stats,
         socket.assigns.admin_mount_path,
         socket.assigns[:current_owner_scope]
       )
     )
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
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page ax-home">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs items={[%{label: Copy.dashboard_breadcrumb_home()}]} />
          <h1 class="ax-display"><%= Copy.home_intro_headline() %></h1>
          <p class="ax-body ax-page-copy"><%= Copy.home_intro_copy() %></p>
        </header>

        <%!-- Zone 1 — Attention rail: exceptions first, only non-zero rows --%>
        <section class="ax-home-section" aria-label="Billing exceptions" data-ax-zone="attention-rail">
          <header class="ax-section-head">
            <h3 class="ax-heading"><%= Copy.dashboard_display_headline() %></h3>
            <a
              :if={@attention != []}
              class="ax-link-quiet"
              href={ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope)}
            >
              <%= Copy.home_attention_all_signals() %>
              <Icon.icon name={:arrow_right} size="sm" />
            </a>
          </header>

          <div :if={@attention != []} class="ax-card ax-attention">
            <a :for={row <- @attention} href={row.href} class="ax-attention-row">
              <span class={["ax-attention-dot", "ax-attention-dot-#{row.tone}"]} aria-hidden="true"></span>
              <span class="ax-attention-text">
                <strong><%= row.metric %></strong> <%= row.label %>
              </span>
              <span :if={row.pill} class={["ax-attention-pill", "ax-attention-pill-#{row.tone}"]}>
                <%= row.pill %>
              </span>
              <span class="ax-attention-action">
                <%= row.action %> <Icon.icon name={:arrow_right} size="sm" />
              </span>
            </a>
          </div>

          <div :if={@attention == []} class="ax-card ax-empty ax-attention-rail--empty">
            <Icon.icon name={:check_circle} size="lg" class="ax-empty-icon" />
            <p class="ax-empty-title"><%= Copy.home_attention_empty_title() %></p>
            <p class="ax-body ax-empty-copy"><%= Copy.home_attention_empty_copy() %></p>
          </div>
        </section>

        <%!-- Zone 2 — Task launchers: one door per JTBD --%>
        <section class="ax-home-section" aria-label="Tasks" data-ax-zone="task-launcher">
          <header class="ax-section-head">
            <h3 class="ax-heading"><%= Copy.home_tasks_heading() %></h3>
          </header>

          <%!-- Visible search field (IA-01): Support entry point visible without hotkey knowledge --%>
          <div class="ax-home-search">
            <button
              type="button"
              class="ax-input-search"
              role="search"
              aria-label="Search"
              data-command-palette-trigger="true"
              data-ax-command-palette-trigger="true"
            >
              <AccrueAdmin.Components.Icon.icon name={:search} size="md" class="ax-input-icon" />
              <span class="ax-input-placeholder">Search customers, invoices… ⌘K</span>
            </button>
          </div>

          <div class="ax-launchers">
            <a class="ax-launcher" href={ScopedPath.build(@admin_mount_path, "/customers", @current_owner_scope)}>
              <span class="ax-launcher-icon"><Icon.icon name={:search} size="lg" /></span>
              <span class="ax-launcher-title"><%= Copy.home_launcher_customers_title() %></span>
              <span class="ax-launcher-copy"><%= Copy.home_launcher_customers_copy() %></span>
            </a>

            <a class="ax-launcher" href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"status" => "open"})}>
              <span class="ax-launcher-icon"><Icon.icon name={:invoices} size="lg" /></span>
              <span class="ax-launcher-title"><%= Copy.home_launcher_invoices_title() %></span>
              <span class="ax-launcher-copy"><%= Copy.home_launcher_invoices_copy() %></span>
              <span :if={@stats.open_invoice_count > 0} class="ax-launcher-meta">
                <%= count(@stats.open_invoice_count, "open invoice") %>
              </span>
            </a>

            <a class="ax-launcher" href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}>
              <span class="ax-launcher-icon"><Icon.icon name={:recovery} size="lg" /></span>
              <span class="ax-launcher-title"><%= Copy.home_launcher_recovery_title() %></span>
              <span class="ax-launcher-copy"><%= Copy.home_launcher_recovery_copy() %></span>
              <span :if={@stats.past_due_subscription_count > 0} class="ax-launcher-meta ax-launcher-meta-warn">
                <%= count(@stats.past_due_subscription_count, "at-risk subscription") %>
              </span>
            </a>

            <a class="ax-launcher" href={ScopedPath.build(@admin_mount_path, "/webhooks", @current_owner_scope)}>
              <span class="ax-launcher-icon"><Icon.icon name={:webhooks} size="lg" /></span>
              <span class="ax-launcher-title"><%= Copy.home_launcher_developer_title() %></span>
              <span class="ax-launcher-copy"><%= Copy.home_launcher_developer_copy() %></span>
              <span :if={@stats.blocked_webhook_count > 0} class="ax-launcher-meta ax-launcher-meta-warn">
                <%= count(@stats.blocked_webhook_count, "dead-letter") %>
              </span>
            </a>
          </div>
        </section>

        <%!-- Zone 3 — At a glance: demoted KPIs --%>
        <section class="ax-home-section" aria-label={Copy.dashboard_kpi_section_aria_label()} data-ax-zone="kpi-cluster">
          <header class="ax-section-head">
            <h3 class="ax-heading"><%= Copy.home_kpi_heading() %></h3>
          </header>

          <div class="ax-kpi-grid ax-kpi-grid-4">
            <KpiCard.kpi_card
              label={Copy.dashboard_kpi_customers_label()}
              value={Integer.to_string(@stats.customer_count)}
              href={ScopedPath.build(@admin_mount_path, "/customers", @current_owner_scope)}
              aria_label={Copy.dashboard_kpi_customers_aria_label()}
            />
            <KpiCard.kpi_card
              label={Copy.dashboard_kpi_active_subscriptions_label()}
              value={Integer.to_string(@stats.active_subscription_count)}
              delta={
                Integer.to_string(@stats.canceling_subscription_count) <>
                  Copy.dashboard_kpi_active_subscriptions_canceling_suffix()
              }
              delta_tone="amber"
              href={ScopedPath.build(@admin_mount_path, "/subscriptions", @current_owner_scope, %{"status" => "canceling"})}
              aria_label={Copy.dashboard_kpi_subscriptions_aria_label()}
            />
            <KpiCard.kpi_card
              label={Copy.dashboard_kpi_open_invoice_balance_label()}
              value={format_minor(@stats.open_invoice_balance_minor, "usd")}
              delta={
                Integer.to_string(@stats.open_invoice_count) <>
                  Copy.dashboard_kpi_open_invoice_delta_suffix()
              }
              delta_tone="cobalt"
              href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"status" => "open"})}
              aria_label={Copy.dashboard_kpi_invoices_aria_label()}
            />
            <KpiCard.kpi_card
              label={Copy.dashboard_kpi_webhook_backlog_label()}
              value={Integer.to_string(@stats.blocked_webhook_count)}
              delta={
                Integer.to_string(@stats.events_last_day_count) <>
                  Copy.dashboard_kpi_webhook_events_suffix()
              }
              delta_tone={if(@stats.blocked_webhook_count > 0, do: "amber", else: "moss")}
              href={ScopedPath.build(@admin_mount_path, "/webhooks", @current_owner_scope, %{"status" => "dead"})}
              aria_label={Copy.dashboard_kpi_webhooks_aria_label()}
            />
          </div>
        </section>

        <%!-- Zone 4 — Recent activity --%>
        <section class="ax-grid ax-grid-2" aria-label={Copy.dashboard_activity_section_aria_label()} data-ax-zone="recent-activity">
          <article class="ax-card">
            <header class="ax-section-head">
              <h3 class="ax-heading"><%= Copy.dashboard_activity_recent_local_heading() %></h3>
              <a class="ax-link-quiet" href={ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope)}>
                <%= Copy.home_activity_events_link() %>
                <Icon.icon name={:arrow_right} size="sm" />
              </a>
            </header>

            <Timeline.timeline
              label={Copy.dashboard_timeline_events_label()}
              empty_label={Copy.dashboard_timeline_events_empty()}
              items={@recent_events}
            />
          </article>

          <article class="ax-card">
            <header class="ax-section-head">
              <h3 class="ax-heading"><%= Copy.dashboard_activity_projection_pipeline_heading() %></h3>
              <a class="ax-link-quiet" href={ScopedPath.build(@admin_mount_path, "/webhooks", @current_owner_scope)}>
                <%= Copy.home_activity_webhooks_link() %>
                <Icon.icon name={:arrow_right} size="sm" />
              </a>
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
      past_due_subscription_count: AttentionCounts.compute(nil).recovery,
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
      blocked_webhook_count: AttentionCounts.compute(nil).developer,
      failed_meter_event_count:
        MeterEvent
        |> where([m], m.stripe_status == "failed")
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

  # Attention rail rows — only exceptions that exist, highest-signal first.
  defp attention_items(stats, mount_path, scope) do
    [
      stats.blocked_webhook_count > 0 &&
        %{
          tone: "danger",
          metric: count(stats.blocked_webhook_count, "webhook"),
          label: Copy.home_attention_webhooks_label(),
          pill: "needs review",
          action: Copy.home_attention_action_review(),
          href: ScopedPath.build(mount_path, "/webhooks", scope, %{"status" => "dead"})
        },
      stats.past_due_subscription_count > 0 &&
        %{
          tone: "warning",
          metric: count(stats.past_due_subscription_count, "subscription"),
          label: Copy.home_attention_past_due_label(),
          pill: "at risk",
          action: Copy.home_attention_action_recover(),
          href: ScopedPath.build(mount_path, "/analytics/recovery", scope)
        },
      stats.failed_meter_event_count > 0 &&
        %{
          tone: "info",
          metric: count(stats.failed_meter_event_count, "meter event"),
          label: Copy.home_attention_meter_label(),
          pill: nil,
          action: Copy.home_attention_action_investigate(),
          href: ScopedPath.build(mount_path, "/events", scope, %{"q" => "meter_event"})
        }
    ]
    |> Enum.filter(& &1)
  end

  defp count(1, noun), do: "1 #{noun}"
  defp count(n, noun), do: "#{n} #{noun}s"

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
