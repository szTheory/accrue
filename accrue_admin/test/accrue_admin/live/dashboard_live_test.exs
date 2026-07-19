defmodule AccrueAdmin.DashboardLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.APIError
  alias Accrue.Billing.{Invoice, MeterEvent}
  alias Accrue.Events
  alias Accrue.Test.Factory
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.Copy
  alias AccrueAdmin.TestRepo

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    %{customer: customer} = Factory.customer(%{email: "dashboard@example.com"})
    %{subscription: subscription} = Factory.active_subscription(%{owner_id: "dashboard-owner"})

    TestRepo.insert!(
      Invoice.changeset(%Invoice{}, %{
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor: "fake",
        processor_id: "in_dashboard",
        status: :open,
        currency: "usd",
        amount_remaining_minor: 4_250
      })
    )

    TestRepo.insert!(
      WebhookEvent.ingest_changeset(%{
        processor: "stripe",
        processor_event_id: "evt_dashboard_dead",
        type: "invoice.payment_failed",
        data: %{"id" => "evt_dashboard_dead"},
        received_at: ~U[2026-04-15 18:00:00Z]
      })
      |> Ecto.Changeset.put_change(:status, :dead)
    )

    {:ok, _event} =
      Events.record(%{
        type: "customer.updated",
        subject_type: "Customer",
        subject_id: customer.id,
        actor_type: "admin",
        actor_id: "admin_1"
      })

    me =
      %{
        customer_id: customer.id,
        stripe_customer_id: customer.processor_id,
        event_name: "api_requests",
        value: 1,
        identifier: "dashboard_live_test_meter_#{Ecto.UUID.generate()}",
        occurred_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      }
      |> MeterEvent.pending_changeset()
      |> TestRepo.insert!()

    me
    |> MeterEvent.failed_changeset(%APIError{message: "x", code: "test", http_status: 400})
    |> TestRepo.update!()

    :ok
  end

  test "renders attention rail, task launchers, demoted KPIs, and activity", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing")

    # Page chrome — PageHeader emits the single top-level h1 (ax-display) + one verdict
    assert html =~ "ax-display"
    assert html =~ "data-ax-health-verdict"
    # Seed has one open invoice → verdict is :action_required (single StatusBadge verdict)
    assert html =~ Copy.dashboard_health_verdict_action_required()

    # Zone 1 — attention rail: heading + seeded exceptions (open invoice P1, dead webhook P2,
    # failed meter P4), rebuilt from StatusBadge / .ax-chip / .ax-link-quiet primitives
    assert html =~ Copy.home_attention_priority_heading()
    assert html =~ "Work invoice queue"
    assert html =~ Copy.home_attention_webhooks_label()
    assert html =~ "Debug failed webhook queue"
    assert html =~ Copy.home_attention_meter_label()
    assert html =~ Copy.home_attention_action_investigate()
    assert html =~ ~s(href="/billing/events?q=meter_event")
    assert html =~ ~s(href="/billing/invoices?status=open")

    # Header actions — single customer-lookup control + audit-ledger link
    assert html =~ "data-ax-command-palette-trigger"
    assert html =~ Copy.home_customer_search_cta()
    assert html =~ "Audit ledger"

    # Header StatStrip — 4-stat exposure-first strip
    assert html =~ "Open invoices"
    assert html =~ "Exposure"
    assert html =~ "At-risk subscriptions"
    assert html =~ "Failed webhooks"

    # Zone 2 — task launchers (three JTBD doors; customer tile folded into the header)
    assert html =~ "data-ax-launcher-primary"
    assert html =~ Copy.home_launcher_invoices_title()
    assert html =~ Copy.home_launcher_recovery_title()
    assert html =~ "Open dunning analytics"
    assert html =~ Copy.home_launcher_developer_title()
    assert html =~ "Debug webhook failures"

    # Zone 3 — demoted KPI strip
    assert html =~ Copy.dashboard_kpi_customers_label()
    assert html =~ Copy.dashboard_kpi_active_subscriptions_label()
    assert html =~ Copy.dashboard_kpi_open_invoice_balance_label()
    assert html =~ Copy.dashboard_kpi_webhook_backlog_label()
    assert html =~ Copy.dashboard_kpi_customers_aria_label()
    assert html =~ Copy.dashboard_kpi_subscriptions_aria_label()
    assert html =~ Copy.dashboard_kpi_invoices_aria_label()
    assert html =~ Copy.dashboard_kpi_webhooks_aria_label()

    # Zone 4 — recent activity timelines
    assert html =~ Copy.dashboard_activity_event_ledger_eyebrow()
    assert html =~ Copy.dashboard_activity_webhook_health_eyebrow()
    assert html =~ "invoice.payment_failed"
    assert html =~ "customer.updated"
    assert html =~ "Open event"
    assert html =~ "Debug delivery trace"
    assert html =~ "Debug failed webhook queue"
    assert html =~ "Open full event ledger"
    assert html =~ "Load more audit events"
    assert html =~ "Filter admin actors"
    assert html =~ "Filter system actors"
    assert html =~ "Admin user Admin 1"
    assert html =~ "Latest event ledger summary"
    assert html =~ "Action"
    assert html =~ "Audit event"

    # Regrouped sidebar nav still threads to every section (exact, query-free hrefs)
    assert html =~ ~s(href="/billing/customers")
    assert html =~ ~s(href="/billing/subscriptions")
    assert html =~ ~s(href="/billing/invoices")
    assert html =~ ~s(href="/billing/webhooks")
    assert html =~ ~s(href="/billing/events")
  end

  test "header verdict is 'Action required' when open invoices are zero but another signal fires (WR-01)",
       %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    # Drive open_invoice_count to 0 while the setup's dead webhook (blocked_webhook_count > 0)
    # and failed meter event remain. The header verdict must key off ALL attention signals,
    # so it must render "Action required" — never a green "Healthy" while the attention rail
    # lists priority exceptions on the same page (the IA-01 answer-first contract).
    TestRepo.delete_all(Invoice)

    assert {:ok, _view, html} = live(conn, "/billing")

    assert html =~ "data-ax-health-verdict"
    assert html =~ Copy.dashboard_health_verdict_action_required()
    refute html =~ Copy.dashboard_health_verdict_healthy()

    # The exception the verdict must not contradict is still surfaced in the rail.
    assert html =~ Copy.home_attention_webhooks_label()
  end
end
