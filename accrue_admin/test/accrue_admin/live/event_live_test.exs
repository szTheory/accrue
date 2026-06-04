defmodule AccrueAdmin.EventLiveTest do
  @moduledoc false

  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events
  alias Accrue.Billing.{Customer, Invoice}
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

    customer = insert_customer(%{processor_id: "cus_event_test"})
    invoice = insert_invoice(customer, %{processor_id: "in_event_test"})

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_for_event_live",
        type: "invoice.payment_failed",
        status: :dead,
        received_at: ~U[2026-04-15 10:00:00Z],
        raw_body:
          Jason.encode!(%{
            "id" => "evt_for_event_live",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"customer" => "cus_event_test"}}
          }),
        data: %{"redacted" => true}
      })

    {:ok, event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Invoice",
        subject_id: to_string(invoice.id),
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, event: event, webhook: webhook, invoice: invoice}
  end

  test "GET /events/:id renders EventLive detail with event type and actor", %{
    conn: conn,
    event: event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    assert html =~ "invoice.payment_failed"
    assert html =~ "webhook"
  end

  test "EventLive Related card links to source webhook when caused_by_webhook_event_id present", %{
    conn: conn,
    event: event,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    # Related card should contain a link to the source webhook
    assert html =~ "/billing/webhooks/#{webhook.id}"
    assert html =~ "Source webhook"
  end

  test "EventLive Related card links to affected entity via subject_href", %{
    conn: conn,
    event: event,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    # Related card should contain a link to the affected invoice
    assert html =~ "/billing/invoices/#{invoice.id}"
  end

  test "GET /events/:id with unknown ID redirects to /events with flash", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    unknown_id = 9_999_999

    # The initial HTTP GET does not include query string params in conn.params
    # (Phoenix LiveView static render uses path params only). So the redirect
    # goes to the base /billing/events path without an org qualifier.
    result = live(conn, "/billing/events/#{unknown_id}")
    assert {:error, {:redirect, redirect_info}} = result
    assert redirect_info.to =~ "/billing/events"
    # Flash must carry a not-found error message (dim ④ = 2 requirement)
    flash =
      case redirect_info[:flash] do
        flash when is_map(flash) ->
          flash

        token when is_binary(token) ->
          Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, token)

        _ ->
          %{}
      end

    assert flash["error"] != nil
  end

  test "renders semantic dl/dt/dd facts inside summary_card", %{conn: conn, event: event} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    # Summary card facts slot must use dl/dt/dd — not bare <span>Actor: ...
    assert html =~ ~s(class="ax-label")
    assert html =~ ~s(class="ax-body")
    # The dl wrapper must be present inside the facts slot
    assert html =~ "<dl"
  end

  test "renders a detail_section body with event type, actor, subject, recorded fields", %{
    conn: conn,
    event: event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    # Detail.detail_section renders ax-detail-section class
    assert html =~ "ax-detail-section"
    # Field list should be rendered with ax-field-list
    assert html =~ "ax-field-list"
    # Known field labels and values from the event fixture
    assert html =~ "Type"
    assert html =~ "Actor type"
    assert html =~ "Subject type"
    assert html =~ "Recorded"
  end

  # --- helpers ---

  defp insert_webhook(attrs) do
    defaults = %{
      processor: "stripe",
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "invoice.payment_failed",
      livemode: false,
      endpoint: :default,
      status: :received,
      raw_body: Jason.encode!(%{"id" => "evt_seed", "object" => "event"}),
      received_at: DateTime.utc_now(),
      data: %{}
    }

    Map.merge(defaults, attrs)
    |> WebhookEvent.ingest_changeset()
    |> TestRepo.insert!()
    |> then(fn webhook ->
      webhook
      |> Ecto.Changeset.change(%{
        status: Map.get(attrs, :status, :received),
        processed_at: Map.get(attrs, :processed_at)
      })
      |> TestRepo.update!()
    end)
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      preferred_locale: "en",
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_invoice(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      currency: "usd",
      status: :open,
      collection_method: "charge_automatically",
      metadata: %{},
      data: %{},
      lock_version: 1,
      processor_id: "in_" <> Integer.to_string(System.unique_integer([:positive]))
    }

    %Invoice{}
    |> Invoice.force_status_changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end
end
