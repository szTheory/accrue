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

  test "renders KPI cards and recent local activity", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing")

    assert html =~ Copy.dashboard_display_headline()
    assert html =~ Copy.dashboard_kpi_customers_label()
    assert html =~ Copy.dashboard_kpi_active_subscriptions_label()
    assert html =~ Copy.dashboard_kpi_open_invoice_balance_label()
    assert html =~ "$42.50"
    assert html =~ Copy.dashboard_kpi_webhook_backlog_label()
    assert html =~ "invoice.payment_failed"
    assert html =~ "customer.updated"

    assert html =~ ~s(href="/billing/customers")
    assert html =~ ~s(href="/billing/subscriptions")
    assert html =~ ~s(href="/billing/invoices")
    assert html =~ ~s(href="/billing/webhooks")
    assert html =~ ~s(href="/billing/events")
    assert html =~ Copy.dashboard_meter_reporting_failures_label()
    assert html =~ Copy.dashboard_meter_reporting_failures_aria_label()

    meter_idx = :binary.match(html, Copy.dashboard_meter_reporting_failures_label()) |> elem(0)
    meter_segment = String.slice(html, meter_idx, 900)
    assert meter_segment =~ ~s(ax-kpi-value">1</p>)

    assert html =~ Copy.dashboard_kpi_customers_aria_label()
    assert html =~ Copy.dashboard_kpi_subscriptions_aria_label()
    assert html =~ Copy.dashboard_kpi_invoices_aria_label()
    assert html =~ Copy.dashboard_kpi_webhooks_aria_label()
  end
end
