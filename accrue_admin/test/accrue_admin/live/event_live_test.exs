defmodule AccrueAdmin.EventLiveTest do
  @moduledoc false

  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Charge, Customer, Invoice}
  alias Accrue.Events
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
        caused_by_webhook_event_id: webhook.id,
        data: %{"payload" => %{"livemode" => false, "failure_code" => "card_declined"}}
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

  test "D-02 D-14 D-15 D-16 D-17 renders event summary-first read-only detail contract",
       %{
         conn: conn,
         event: event,
         webhook: webhook,
         invoice: invoice
       } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    assert heading_count(html, "h1") == 1
    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1
    assert data_attr_count(html, "data-ax-action-band") == 0
    assert data_attr_count(html, "data-ax-action-overflow-menu") == 0

    assert html =~ "Type"
    assert html =~ "Actor"
    assert html =~ "Subject"
    assert html =~ "Source webhook"
    assert html =~ "Recorded time"
    assert html =~ "Livemode"
    assert html =~ "/billing/webhooks/#{webhook.id}"
    assert html =~ "/billing/invoices/#{invoice.id}"
    assert html =~ "Open this section to load"

    refute html =~ ~s(class="ax-kpi-grid")
    refute html =~ "failure_code"
    refute html =~ "card_declined"

    assert major_band_order(html) == [
             :summary_card,
             :summary_list,
             :drill_section,
             :related_resources,
             :lazy_activity,
             :lazy_json
           ]
  end

  test "keeps activity collapsed until the operator opens the marker", %{
    conn: conn,
    event: event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/events/#{event.id}")

    assert html =~ "Open this section to load activity."
    refute html =~ "This record has no recorded activity yet."

    html = render_click(view, "load_activity", %{})

    assert html =~ "This record has no recorded activity yet."
    assert html =~ "Core details remain available above."
  end

  test "keeps raw event payload collapsed until the operator opens the marker", %{
    conn: conn,
    event: event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/events/#{event.id}")

    assert html =~ "Event payload"
    refute html =~ "failure_code"
    refute html =~ "card_declined"

    html = render_click(view, "load_raw_json", %{})

    assert html =~ "failure_code"
    assert html =~ "card_declined"
  end

  test "omits the lazy raw marker when the event has no payload", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, event} =
      Events.record(%{
        type: "system.note",
        subject_type: "Unknown",
        subject_id: "no_payload",
        actor_type: "system"
      })

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 0
  end

  test "D-15 event detail keeps one related-resources wrapper with quiet empty state when no links exist",
       %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, event} =
      Events.record(%{
        type: "system.note",
        subject_type: "Unknown",
        subject_id: "detached",
        actor_type: "system",
        data: %{"note" => "no related resources"}
      })

    assert {:ok, _view, html} = live(conn, "/billing/events/#{event.id}")

    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert html =~ "No related resources"
  end

  test "EventLive Related card links to source webhook when caused_by_webhook_event_id present",
       %{
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

  test "out-of-scope event route redirects with denial flash before rendering detail", %{
    conn: conn
  } do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_invoice = insert_invoice(allowed_customer, %{processor_id: "in_event_allowed"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "in_event_denied"})
    allowed_charge = insert_charge(allowed_customer, %{processor_id: "ch_event_allowed"})
    denied_charge = insert_charge(denied_customer, %{processor_id: "ch_event_denied"})

    {:ok, allowed_event} =
      Events.record(%{
        type: "invoice.payment_failed.allowed_org",
        subject_type: "Invoice",
        subject_id: allowed_invoice.id,
        actor_type: "system"
      })

    {:ok, denied_event} =
      Events.record(%{
        type: "invoice.payment_failed.denied_org",
        subject_type: "Invoice",
        subject_id: denied_invoice.id,
        actor_type: "system"
      })

    {:ok, allowed_charge_event} =
      Events.record(%{
        type: "charge.succeeded.allowed_org",
        subject_type: "Charge",
        subject_id: allowed_charge.id,
        actor_type: "system"
      })

    {:ok, denied_charge_event} =
      Events.record(%{
        type: "charge.succeeded.denied_org",
        subject_type: "Charge",
        subject_id: denied_charge.id,
        actor_type: "system"
      })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, allowed_html} =
             live(conn, "/billing/events/#{allowed_event.id}?org=allowed-org")

    assert allowed_html =~ "invoice.payment_failed.allowed_org"

    assert {:ok, _view, allowed_charge_html} =
             live(conn, "/billing/events/#{allowed_charge_event.id}?org=allowed-org")

    assert allowed_charge_html =~ "charge.succeeded.allowed_org"

    assert {:error, {:redirect, %{to: "/billing/events?org=allowed-org", flash: flash_token}}} =
             redirect =
             live(conn, "/billing/events/#{denied_event.id}?org=allowed-org")

    assert %{"error" => denied} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert denied == AccrueAdmin.Copy.Locked.owner_access_denied()
    assert redirect

    assert {:error,
            {:redirect, %{to: "/billing/events?org=allowed-org", flash: charge_flash_token}}} =
             charge_redirect =
             live(conn, "/billing/events/#{denied_charge_event.id}?org=allowed-org")

    assert %{"error" => charge_denied} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, charge_flash_token)

    assert charge_denied == AccrueAdmin.Copy.Locked.owner_access_denied()
    assert charge_redirect
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

  defp insert_charge(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      processor_id: "ch_" <> Integer.to_string(System.unique_integer([:positive])),
      amount_cents: 1_000,
      currency: "usd",
      status: "succeeded",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Charge{}
    |> Charge.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp data_attr_count(html, attr) do
    attr
    |> Regex.escape()
    |> then(&Regex.compile!("\\b" <> &1 <> "(?:\\s|=|>)"))
    |> Regex.scan(html)
    |> length()
  end

  defp heading_count(html, tag) do
    tag
    |> Regex.escape()
    |> then(&Regex.compile!("<" <> &1 <> "\\b"))
    |> Regex.scan(html)
    |> length()
  end

  defp major_band_order(html) do
    [
      summary_card: ~s(class="ax-card ax-summary-card"),
      summary_list: "data-ax-summary-list",
      drill_section: ~s(class="ax-detail-section"),
      related_resources: "data-ax-related-resources",
      lazy_activity: "data-ax-lazy-activity",
      lazy_json: "data-ax-lazy-json",
      kpi_grid: ~s(class="ax-kpi-grid")
    ]
    |> Enum.flat_map(fn {band, marker} ->
      case :binary.match(html, marker) do
        :nomatch -> []
        {position, _length} -> [{position, band}]
      end
    end)
    |> Enum.sort()
    |> Enum.map(fn {_position, band} -> band end)
  end
end
