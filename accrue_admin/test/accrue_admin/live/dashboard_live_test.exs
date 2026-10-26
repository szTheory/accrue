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

    {:ok, event} =
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

    {:ok, %{event: event}}
  end

  test "renders factual recent activity without unsupported health or aggregate claims", %{
    conn: conn,
    event: event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing")

    # Home presents observable activity and scope-matched destinations only.
    assert html =~ "ax-display"
    assert html =~ "Recent activity"

    assert html
           |> Floki.parse_document!()
           |> Floki.find(".ax-breadcrumbs-group")
           |> Floki.text()
           |> String.trim() == "Billing"

    assert html =~ "data-event-family=\"customer\""
    refute html =~ "Recorded automatically"
    assert html =~ "ax-id-badge-plain"
    assert html =~ "Customer updated"
    refute html =~ "data-ax-command-palette-trigger"
    refute html =~ Copy.home_customer_search_cta()
    refute html =~ "Audit event"
    assert html =~ "Copy Customer ID"
    assert html =~ ~s(class="ax-timeline-subject-label">ID</span>)
    assert html =~ "data-clipboard-text"
    refute html =~ ">Open event<"
    assert html =~ "ax-timeline-title-link"
    assert html =~ "View events"

    refute html =~ "data-ax-health-verdict"
    refute html =~ "Healthy"
    refute html =~ "above $0.00 target"
    refute html =~ "Failed webhooks"
    refute html =~ "At-risk subscriptions"
    assert html =~ ~s(href="/billing/customers")
    assert html =~ ~s(href="/billing/events")
    assert html =~ ~s(href="/billing/events/#{event.id}")
  end

  test "organization Home shows its event and same-scope destinations only", %{conn: conn} do
    org_id = Ecto.UUID.generate()
    allowed = customer_for_org(org_id)
    foreign = customer_for_org(Ecto.UUID.generate())

    {:ok, allowed_event} =
      Events.record(%{
        type: "home.allowed_scope_event",
        subject_type: "Customer",
        subject_id: allowed.id,
        actor_type: "admin",
        actor_id: "admin_1"
      })

    {:ok, _} =
      Events.record(%{
        type: "home.foreign_scope_event",
        subject_type: "Customer",
        subject_id: foreign.id,
        actor_type: "admin",
        actor_id: "admin_1"
      })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: org_id,
        active_organization_slug: "home-org",
        admin_organization_ids: [org_id]
      )

    assert {:ok, _view, html} = live(conn, "/billing?org=home-org")
    assert html =~ "Billing event"
    refute html =~ "home.foreign_scope_event"
    assert html =~ ~s(href="/billing/events/#{allowed_event.id}?org=home-org")
    assert html =~ ~s(href="/billing/customers?org=home-org")
    assert html =~ ~s(href="/billing/events?org=home-org")

    assert html =~
             ~r/href="\/billing\?org=home-org"[^>]*class="ax-sidebar-link ax-sidebar-link-active"/
  end

  test "organization Home keeps the activity empty state distinct from scoped destinations", %{
    conn: conn
  } do
    org_id = Ecto.UUID.generate()

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: org_id,
        active_organization_slug: "empty-home-org",
        admin_organization_ids: [org_id]
      )

    assert {:ok, _view, html} = live(conn, "/billing?org=empty-home-org")

    assert html =~ "No recent billing activity in this scope."
    assert html =~ ~s(href="/billing/events?org=empty-home-org")
    refute html =~ "Open event"
    refute html =~ "Customer updated"
  end

  test "organization Home keeps multiple activity rows attached to their scoped event records", %{
    conn: conn
  } do
    org_id = Ecto.UUID.generate()
    first_customer = customer_for_org(org_id)

    {:ok, first_event} =
      Events.record(%{
        type: "customer.updated",
        subject_type: "Customer",
        subject_id: first_customer.id,
        actor_type: "admin",
        actor_id: "admin_1"
      })

    {:ok, second_event} =
      Events.record(%{
        type: "customer.local_updated",
        subject_type: "Customer",
        subject_id: first_customer.id,
        actor_type: "admin",
        actor_id: "admin_1"
      })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: org_id,
        active_organization_slug: "many-home-org",
        admin_organization_ids: [org_id]
      )

    assert {:ok, _view, html} = live(conn, "/billing?org=many-home-org")

    rows = html |> Floki.parse_fragment!() |> Floki.find(".ax-timeline-item")
    assert length(rows) == 2

    assert Enum.any?(rows, fn row ->
             text = Floki.text(row)
             href = row |> Floki.find("a.ax-timeline-title-link") |> Floki.attribute("href")

             text =~ "Customer updated" and text =~ first_customer.id and
               href == ["/billing/events/#{first_event.id}?org=many-home-org"]
           end)

    assert Enum.any?(rows, fn row ->
             text = Floki.text(row)
             href = row |> Floki.find("a.ax-timeline-title-link") |> Floki.attribute("href")

             text =~ "Customer record updated locally" and text =~ first_customer.id and
               href == ["/billing/events/#{second_event.id}?org=many-home-org"]
           end)
  end

  test "Billing destinations are peers under a non-linked navigation group", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    for path <- [
          "/billing",
          "/billing/customers",
          "/billing/subscriptions",
          "/billing/invoices",
          "/billing/payments"
        ] do
      assert {:ok, _view, html} = live(conn, path)
      document = Floki.parse_fragment!(html)
      crumbs = Floki.find(document, "nav[aria-label='Breadcrumb']")

      assert crumbs |> Floki.find(".ax-breadcrumbs-group") |> Floki.text() |> String.trim() ==
               "Billing"

      assert Floki.find(crumbs, "a") == []
      refute Floki.text(crumbs) =~ "Dashboard"
      assert length(Floki.find(crumbs, "[aria-current='page']")) == 1
    end
  end

  defp customer_for_org(org_id) do
    %{customer: customer} =
      Factory.customer(%{
        owner_type: "Organization",
        owner_id: org_id,
        email: "#{org_id}@example.com"
      })

    customer
  end
end
