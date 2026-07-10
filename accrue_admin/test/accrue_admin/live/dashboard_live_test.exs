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

    # Page chrome + attention rail heading
    assert html =~ Copy.home_intro_headline()
    assert html =~ "ax-display"
    assert html =~ Copy.dashboard_display_headline()

    # Zone 1 — attention rail surfaces the seeded exceptions (dead webhook + meter failure)
    assert html =~ Copy.home_attention_webhooks_label()
    assert html =~ "Debug failed webhook queue"
    assert html =~ Copy.home_attention_meter_label()
    assert html =~ Copy.home_attention_action_investigate()
    assert html =~ "Billing healthy? No"
    assert html =~ "Billing health: Critical issues require attention"

    assert html =~
             "Resolve priority 1 open invoices before webhook debugging and recovery review."

    assert html =~ "open invoices"
    assert html =~ ">1<"
    assert html =~ ">2<"
    assert html =~ "Debug dead-lettered webhooks"
    assert html =~ "Work open-invoice queue: $42.50 open"
    assert html =~ ~s(href="/billing/events?q=meter_event")
    assert html =~ ~s(href="/billing/invoices?status=open")
    assert html =~ "Audit: open event ledger"

    # Zone 2 — task launchers (the JTBD doors)
    assert html =~ Copy.home_launcher_customers_title()
    assert html =~ Copy.home_launcher_customers_meta()
    assert html =~ "ax-launcher-primary"
    assert html =~ "Open-invoice queue: $42.50 open"
    assert html =~ "$42.50 above $0.00 target"
    assert html =~ Copy.home_launcher_recovery_title()
    assert html =~ "Recovery status: At risk"
    assert html =~ "At-risk now:"
    assert html =~ "Open dunning funnel analytics"
    # Title relabeled in Phase 175-02 (IA-01 verb relabels); use Copy function directly.
    assert html =~ Copy.home_launcher_developer_title()
    assert html =~ "Debug webhook failures"

    # Zone 3 — demoted KPI strip
    assert html =~ Copy.dashboard_kpi_customers_label()
    assert html =~ Copy.dashboard_kpi_active_subscriptions_label()
    assert html =~ Copy.dashboard_kpi_open_invoice_balance_label()
    assert html =~ "$42.50"
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

    # IA-01 verb relabels (Plan 175-02)
    assert html =~ "Search customers globally"
    assert html =~ "Open global customer search"
    assert html =~ "Opens the Invoices queue workspace for current receivables"
    assert html =~ "Work open-invoice queue: $42.50 open"

    # IA-01 customer lookup entry point on Home (Plan 175-04)
    assert html =~ "Find one customer"
    assert html =~ "ax-home-customer-search-cta"
  end
end
