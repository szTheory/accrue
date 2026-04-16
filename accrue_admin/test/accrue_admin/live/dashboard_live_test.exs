defmodule AccrueAdmin.DashboardLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.Invoice
  alias Accrue.Events
  alias Accrue.Test.Factory
  alias Accrue.Webhook.WebhookEvent
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

    :ok
  end

  test "renders KPI cards and recent local activity", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing")

    assert html =~ "Local billing projections at a glance"
    assert html =~ "Customers"
    assert html =~ "Open invoice balance"
    assert html =~ "$42.50"
    assert html =~ "Webhook backlog"
    assert html =~ "invoice.payment_failed"
    assert html =~ "customer.updated"
  end
end
