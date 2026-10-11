defmodule AccrueAdmin.WebhookLiveTest do
  use AccrueAdmin.LiveCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Webhooks.DLQ
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Events, as: EventQueries
  alias AccrueAdmin.Queries.Webhooks
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

    @impl Accrue.Auth
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify webhook replay"}

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, action) do
      case Application.get_env(:accrue_admin, :expected_step_up_subject_id) do
        nil -> :ok
        expected when action.subject_id == expected -> :ok
        _expected -> {:error, :wrong_subject_id}
      end
    end

    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior)
      Application.delete_env(:accrue_admin, :expected_step_up_subject_id)
      Application.delete_env(:accrue_admin, :webhook_detail_fun)
    end)

    customer = insert_customer(%{processor_id: "cus_123"})
    invoice = insert_invoice(customer, %{processor_id: "in_123"})

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_detail",
        type: "invoice.payment_failed",
        status: :dead,
        received_at: ~U[2026-04-15 10:00:00Z],
        raw_body:
          Jason.encode!(%{
            "id" => "evt_detail",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"customer" => "cus_123", "attempt_count" => 3}}
          }),
        data: %{"redacted" => true}
      })

    {:ok, _event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Invoice",
        subject_id: invoice.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    insert_attempt_job(webhook.id)

    {:ok, webhook: webhook}
  end

  test "D-12 D-13 D-14 D-15 D-16 D-17 renders replayable webhook detail contract", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, webhook.id)

    assert {:ok, view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    assert heading_count(html, "h1") == 1
    assert has_element?(view, "[data-role='webhook-page-header']")
    assert has_element?(view, "h1", webhook.processor_event_id)
    assert has_element?(view, "[aria-label='Breadcrumb'] a", "Webhooks")
    assert has_element?(view, "[aria-label='Breadcrumb'] [aria-current='page']", "Webhook")
    refute html =~ "Webhook inspector"
    refute html =~ "Processor event ID"
    refute html =~ "Replay eligibility"
    refute html =~ "Dispatch / retry lifecycle"
    refute html =~ "Derived ledger rows"
    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-action-band") == 1
    assert data_attr_count(html, "data-ax-primary-action") == 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1
    assert length(Regex.scan(~r/phx-hook="PreserveDisclosure"/, html)) == 2

    assert length(
             Floki.find(Floki.parse_document!(html), "details > summary.ax-disclosure-summary")
           ) == 2

    for label <- [
          "Endpoint",
          "Received / processed",
          "Verification",
          "Attempts",
          "Livemode",
          "Failure",
          "Derived event count"
        ] do
      assert html =~ label
    end

    assert html =~ "processor timeout"
    refute html =~ "data-role=\"webhook-payload\""

    assert has_element?(view, "[data-ax-primary-action]", "Replay webhook")

    assert html =~
             "Queues another delivery attempt. Queue acceptance does not confirm processing."

    refute has_element?(view, "[data-role='replay-confirm']")

    html = render_click(element(view, "[data-ax-primary-action]", "Replay webhook"))

    assert has_element?(view, "[data-ax-action-drawer-form][data-role='replay-confirm']")
    assert html =~ "Confirm replay"
    assert html =~ "Cancel replay"
    assert length(Regex.scan(~r/Cancel replay/, html)) == 2

    active_drawer =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("#webhook-replay-drawer-portal")
      |> hd()

    assert length(Floki.find(active_drawer, "button.ax-button-ghost")) == 1

    html = render_click(element(view, "[data-ax-action-drawer-confirm]", "Confirm replay"))
    assert html =~ Copy.step_up_title()
  end

  test "D-13 non-replayable webhook rows omit replay-looking controls and show state copy", %{
    conn: conn
  } do
    webhook =
      insert_webhook(%{
        processor_event_id: "evt_received_no_replay",
        status: :received,
        type: "invoice.payment_succeeded"
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    refute has_element?(view, "[data-role='replay-single']")
    refute html =~ ~r/<button[^>]+data-role="replay-single"[^>]+disabled/
    assert html =~ "Replay is unavailable while this webhook is Received."
  end

  test "renders forensic payload, verification summary, attempt history, and derived events", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    # UX-03: one page shell; summary rows replace the old KPI band.
    assert Regex.scan(~r/class="ax-page"/, html) |> length() == 1
    assert html =~ "data-ax-summary-list"
    refute html =~ "ax-kpi-grid"

    assert html =~ "Signature verification passed"
    assert html =~ "invoice.payment_failed"
    assert length(Floki.find(Floki.parse_document!(html), "[data-time-display]")) >= 1

    activity_html = render_click(element(view, "[data-ax-lazy-activity]"))
    assert activity_html =~ "Webhook attempt history"
    assert activity_html =~ "data-time-display"
    assert length(Floki.find(Floki.parse_document!(activity_html), "[data-time-display]")) >= 2
    assert activity_html =~ "Attempt 3/25"
    assert activity_html =~ "/billing/events?source_webhook_event_id=#{webhook.id}"

    html = render_click(element(view, "[data-ax-lazy-json]"))
    assert html =~ "cus_123"
  end

  test "related activity shares event meaning and discloses exact evidence and destination", %{
    conn: conn,
    webhook: webhook
  } do
    customer = insert_customer(%{processor_id: "cus_related_event"})

    {:ok, event} =
      Events.record(%{
        type: "customer.updated",
        subject_type: "Customer",
        subject_id: customer.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/webhooks/#{webhook.id}")
    assert html =~ "Dead"

    html = render_click(element(view, "[data-ax-lazy-activity]"))

    event_item =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("[aria-label='Derived events'] .ax-timeline-item")
      |> Enum.find(&(Floki.text(&1) =~ "event ##{event.id}"))

    assert html =~ "Webhook attempt history"
    assert html =~ "Derived events"
    assert Floki.text(event_item) =~ "Customer updated"
    assert Floki.text(event_item) =~ "Inspect event evidence"
    assert Floki.text(event_item) =~ "Stored event key: customer.updated"
    assert Floki.text(event_item) =~ "Event ID: #{event.id}"
    assert Floki.text(event_item) =~ "Webhook delivery ID: #{webhook.id}"
    assert Floki.text(event_item) =~ "Recorded: #{DateTime.to_iso8601(event.inserted_at)}"

    event_link =
      Floki.find(event_item, "a.ax-timeline-link")

    assert Floki.text(event_link) |> String.trim() == "Open event"
    assert Floki.attribute(event_link, "href") == ["/billing/events/#{event.id}"]
    assert html =~ "Attempt 3/25"
    assert html =~ "Dead"
  end

  test "empty webhook activity has one truthful empty state", %{
    conn: conn
  } do
    webhook =
      insert_webhook(%{
        processor_event_id: "evt_empty_activity",
        type: "invoice.payment_failed",
        status: :dead
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    assert html =~
             "Open Activity to load dispatch attempts and derived ledger rows for this webhook."

    html = render_click(element(view, "[data-ax-lazy-activity]"))

    assert html =~
             "No dispatch attempts or derived billing events are recorded for this webhook yet."

    refute html =~ "No dispatch attempts recorded yet"
    refute html =~ "No derived event rows linked to this webhook yet"
    refute html =~ "Inspect event evidence"
  end

  test "multiple derived activity rows retain each label, evidence, and event destination", %{
    conn: conn,
    webhook: webhook
  } do
    customer = insert_customer(%{processor_id: "cus_many_related_events"})

    {:ok, first_event} =
      Events.record(%{
        type: "customer.updated",
        subject_type: "Customer",
        subject_id: customer.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, second_event} =
      Events.record(%{
        type: "customer.local_updated",
        subject_type: "Customer",
        subject_id: customer.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")
    html = render_click(element(view, "[data-ax-lazy-activity]"))

    rows =
      html
      |> Floki.parse_fragment!()
      |> Floki.find("[aria-label='Derived events'] .ax-timeline-item")

    assert length(rows) == 3

    for {event, label} <- [
          {first_event, "Customer updated"},
          {second_event, "Customer record updated locally"}
        ] do
      row = Enum.find(rows, &(Floki.text(&1) =~ "event ##{event.id}"))
      assert row
      assert Floki.text(row) =~ label
      assert Floki.text(row) =~ "Stored event key: #{event.type}"

      assert Floki.attribute(Floki.find(row, "a.ax-timeline-link"), "href") ==
               ["/billing/events/#{event.id}"]
    end
  end

  test "WebhookLive Related card renders event links pointing to /events/:id", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    # Related card is rendered (ax-related section)
    assert html =~ "ax-related"
    # Contains a link to the derived event at /events/:id
    # The event was created in setup with caused_by_webhook_event_id = webhook.id
    assert html =~ "/billing/events/"
  end

  test "in-scope replay uses the exact confirmation and success copy", %{conn: conn} do
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    invoice = insert_invoice(customer, %{processor_id: "in_scope_detail"})

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_scope_confirm",
        status: :dead,
        data: %{"object" => %{"id" => invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_scope_confirm",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => invoice.processor_id}}
          })
      })

    {:ok, _event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Invoice",
        subject_id: invoice.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}?org=allowed-org")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, webhook.id)

    html = render_click(element(view, "[data-ax-primary-action]", "Replay webhook"))

    assert html =~
             "This will requeue the webhook delivery and record an admin audit event. Confirm replay."

    html = render_click(element(view, "[data-ax-action-drawer-confirm]", "Confirm replay"))
    assert html =~ Copy.step_up_title()

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})
    assert html =~ "Replay requested for the active organization."
  end

  test "single replay rechecks current status after fresh step-up", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, webhook.id)

    assert {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")
    render_click(element(view, "[data-role='replay-single']"))
    render_click(element(view, "[data-role='confirm-replay']"))
    assert render(view) =~ Copy.step_up_title()

    webhook
    |> Ecto.Changeset.change(status: :received)
    |> TestRepo.update!()

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "Replay is blocked because this webhook isn&#39;t linked to a billable row"
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :received

    refute TestRepo.exists?(
             from(event in Event,
               where:
                 event.type == "admin.webhook.replay.completed" and
                   event.subject_id == ^webhook.id
             )
           )
  end

  test "single replay dismissal and step-up denial leave delivery, jobs, and audit unchanged", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")
    jobs_before = dispatch_jobs(webhook.id)

    render_click(element(view, "[data-role='replay-single']"))
    render_click(element(view, "button", "Cancel"))
    refute has_element?(view, "[data-role='replay-confirm']")
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead
    assert dispatch_jobs(webhook.id) == jobs_before
    refute replay_events_exist?(webhook.id)

    render_click(element(view, "[data-role='replay-single']"))
    render_click(element(view, "[data-role='confirm-replay']"))
    render_submit(view, "step_up_submit", %{"code" => "wrong"})
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead
    assert dispatch_jobs(webhook.id) == jobs_before
    refute replay_events_exist?(webhook.id)
  end

  test "accepted replay remains queued when the follow-up detail read is unavailable", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, webhook.id)
    base_detail = &Webhooks.detail/2

    # The disconnected and connected mounts plus pre-dispatch reads succeed; only the
    # post-acceptance evidence refresh fails.
    calls = :counters.new(1, [:atomics])

    Application.put_env(:accrue_admin, :webhook_detail_fun, fn id, scope ->
      :counters.add(calls, 1, 1)

      case :counters.get(calls, 1) do
        4 -> :unavailable
        _ -> base_detail.(id, scope)
      end
    end)

    assert {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")
    render_click(element(view, "[data-role='replay-single']"))
    render_click(element(view, "[data-role='confirm-replay']"))
    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~
             "Replay request accepted. Current processing status is unknown because delivery history could not be loaded. Retry read to check current status."

    assert html =~
             "Current processing status is unknown because delivery history could not be loaded"

    assert html =~ "Retry read"
    assert html =~ "Webhook history unavailable"
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :received
    assert dispatch_jobs(webhook.id) |> Enum.count(&(&1.state == "available")) == 1

    assert replay_event_types(webhook.id) == [
             "admin.webhook.replay.completed",
             "webhook.replay_requested"
           ]

    html = render_click(element(view, "[data-role='retry-webhook-read']"))

    refute html =~ "Current processing status is unknown"
    refute html =~ ~s(data-role="webhook-unavailable")
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :received
    assert dispatch_jobs(webhook.id) |> Enum.count(&(&1.state == "available")) == 1

    assert replay_event_types(webhook.id) == [
             "admin.webhook.replay.completed",
             "webhook.replay_requested"
           ]
  end

  test "webhook detail preserves only validated family return context and scopes direct fallback",
       %{
         conn: conn
       } do
    customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    invoice = insert_invoice(customer, %{processor_id: "in_return_context"})

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_return_context",
        data: %{"object" => %{"id" => invoice.processor_id}}
      })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    return_to = "/billing/webhooks?status=dead&type=invoice.payment_failed&org=wrong-org"

    assert {:ok, _view, html} =
             live(
               conn,
               "/billing/webhooks/#{webhook.id}?org=allowed-org&return_to=#{URI.encode_www_form(return_to)}"
             )

    assert html =~ "status=dead"
    assert html =~ "type=invoice.payment_failed"
    assert html =~ "org=allowed-org"
    refute html =~ "wrong-org"

    assert {:ok, _view, direct_html} =
             live(conn, "/billing/webhooks/#{webhook.id}?org=allowed-org")

    assert direct_html =~ "href=\"/billing/webhooks?org=allowed-org\""
  end

  test "single replay revalidates organization ownership inside the claim transaction", %{
    conn: conn
  } do
    customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    invoice = insert_invoice(customer, %{processor_id: "in_reassigned_single"})

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_reassigned_single",
        status: :dead,
        data: %{"object" => %{"id" => invoice.processor_id}}
      })

    {:ok, _event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Invoice",
        subject_id: invoice.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    prior_requeue_fun = Application.get_env(:accrue_admin, :webhook_requeue_fun)

    on_exit(fn ->
      if prior_requeue_fun do
        Application.put_env(:accrue_admin, :webhook_requeue_fun, prior_requeue_fun)
      else
        Application.delete_env(:accrue_admin, :webhook_requeue_fun)
      end
    end)

    Application.put_env(:accrue_admin, :webhook_requeue_fun, fn id, authorize_fun ->
      customer
      |> Ecto.Changeset.change(owner_id: "org_foreign")
      |> TestRepo.update!()

      DLQ.requeue(id, authorize_fun)
    end)

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}?org=allowed-org")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, webhook.id)

    _ = render_click(element(view, "[data-ax-primary-action]", "Replay webhook"))
    _ = render_click(element(view, "[data-ax-action-drawer-confirm]", "Confirm replay"))
    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "Replay is blocked because this webhook isn&#39;t linked to a billable row"
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead

    refute TestRepo.exists?(
             from(event in Event,
               where: event.type == "webhook.replay_requested" and event.subject_id == ^webhook.id
             )
           )

    refute TestRepo.exists?(
             from(event in Event,
               where:
                 event.type == "admin.webhook.replay.completed" and
                   event.subject_id == ^webhook.id
             )
           )
  end

  test "detail read failure is unavailable rather than not-found and retry restores evidence", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")

    on_exit(fn -> Application.delete_env(:accrue_admin, :phase238_read_failure_fixture) end)
    Application.put_env(:accrue_admin, :phase238_read_failure_fixture, :webhook_detail)
    html = render_click(view, "retry_read", %{})

    assert html =~ ~s(data-role="webhook-unavailable")
    assert html =~ "Webhook history unavailable"
    assert html =~ "Retry read"
    refute html =~ webhook.processor_event_id
    refute html =~ "fixture database unavailable"

    Application.delete_env(:accrue_admin, :phase238_read_failure_fixture)
    html = render_click(view, "retry_read", %{})

    assert html =~ webhook.processor_event_id
    refute html =~ ~s(data-role="webhook-unavailable")
  end

  test "forensic payload section uses Detail.detail_section not hand-rolled ax-card", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    # Detail.detail_section renders ax-detail-section class
    assert html =~ "ax-detail-section"
    assert html =~ "data-ax-lazy-json"
    assert html =~ "Raw payload"
    # Endpoint and processed fields should appear via detail_field_list
    assert html =~ "Endpoint"
    assert html =~ "Processed"

    html = render_click(element(view, "[data-ax-lazy-json]"))
    assert html =~ "webhook-payload"
    assert html =~ "evt_detail"

    document = Floki.parse_document!(html)
    tabs = Floki.find(document, "#webhook-payload [role=tab]")
    assert Enum.map(tabs, &(Floki.text(&1) |> String.trim())) == ["Tree", "Raw"]

    tree_tab = Floki.find(document, "#webhook-payload-tree-tab") |> hd()
    assert Floki.attribute(tree_tab, "aria-selected") == ["true"]

    raw_panel = Floki.find(document, "#webhook-payload-raw-panel") |> hd()
    assert Floki.attribute(raw_panel, "hidden") == [""]

    copy_button = Floki.find(document, "#webhook-payload-copy") |> hd()
    assert Floki.attribute(copy_button, "role") == []

    assert Floki.attribute(copy_button, "data-clipboard-text") == [
             Jason.encode!(Jason.decode!(webhook.raw_body), pretty: true)
           ]
  end

  test "keeps activity feed path and lazy Activity marker in DETAIL layout", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    assert html =~ "data-ax-lazy-activity"

    html = render_click(element(view, "[data-ax-lazy-activity]"))
    assert html =~ "Webhook attempt history"
    assert html =~ "Derived events"
    assert html =~ "/billing/events?source_webhook_event_id=#{webhook.id}"
  end

  test "webhook loader distinguishes in-scope, out-of-scope, and ambiguous ownership" do
    in_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    out_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    in_scope_invoice = insert_invoice(in_scope_customer, %{processor_id: "in_scope_invoice"})
    out_scope_invoice = insert_invoice(out_scope_customer, %{processor_id: "out_scope_invoice"})

    in_scope_webhook =
      insert_webhook(%{
        processor_event_id: "evt_in_scope",
        data: %{"object" => %{"id" => in_scope_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_in_scope",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => in_scope_invoice.processor_id}}
          })
      })

    out_scope_webhook =
      insert_webhook(%{
        processor_event_id: "evt_out_scope",
        data: %{"object" => %{"id" => out_scope_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_out_scope",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => out_scope_invoice.processor_id}}
          })
      })

    ambiguous_webhook =
      insert_webhook(%{
        processor_event_id: "evt_ambiguous",
        data: %{"object" => %{"id" => "in_unknown"}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_ambiguous",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => "in_unknown"}}
          })
      })

    in_scope_webhook_id = in_scope_webhook.id

    owner_scope = organization_owner_scope("org_allowed")

    assert {:ok, %{id: ^in_scope_webhook_id}} = Webhooks.detail(in_scope_webhook.id, owner_scope)
    assert :not_found = Webhooks.detail(out_scope_webhook.id, owner_scope)

    assert {:ambiguous, proof_context} = Webhooks.detail(ambiguous_webhook.id, owner_scope)
    assert proof_context.webhook_id == ambiguous_webhook.id
  end

  test "organization event feed includes only webhook replay records proven in scope", %{
    conn: conn
  } do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_invoice = insert_invoice(allowed_customer, %{processor_id: "in_replay_allowed"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "in_replay_denied"})

    allowed_webhook =
      insert_webhook(%{
        processor_event_id: "evt_replay_allowed",
        data: %{"object" => %{"id" => allowed_invoice.processor_id}}
      })

    denied_webhook =
      insert_webhook(%{
        processor_event_id: "evt_replay_denied",
        data: %{"object" => %{"id" => denied_invoice.processor_id}}
      })

    {:ok, allowed_single} =
      Events.record(%{
        type: "admin.webhook.replay.completed",
        subject_type: "WebhookEvent",
        subject_id: allowed_webhook.id,
        caused_by_webhook_event_id: allowed_webhook.id
      })

    {:ok, denied_single} =
      Events.record(%{
        type: "admin.webhook.replay.completed",
        subject_type: "WebhookEvent",
        subject_id: denied_webhook.id,
        caused_by_webhook_event_id: denied_webhook.id
      })

    {:ok, allowed_batch} =
      Events.record(%{
        type: "admin.webhook.bulk_replay.completed",
        subject_type: "WebhookBatch",
        subject_id: "selected",
        data: %{"ids" => [allowed_webhook.id]}
      })

    {:ok, mixed_batch} =
      Events.record(%{
        type: "admin.webhook.bulk_replay.completed",
        subject_type: "WebhookBatch",
        subject_id: "selected",
        data: %{"ids" => [allowed_webhook.id, denied_webhook.id]}
      })

    scope = organization_owner_scope("org_allowed")

    {single_rows, _cursor} =
      EventQueries.list(owner_scope: scope, filter: %{subject_type: "WebhookEvent"})

    assert Enum.any?(single_rows, &(&1.id == allowed_single.id))
    refute Enum.any?(single_rows, &(&1.id == denied_single.id))
    assert {:ok, %{id: id}} = EventQueries.detail(allowed_single.id, scope)
    assert id == allowed_single.id
    assert :not_found = EventQueries.detail(denied_single.id, scope)

    {batch_rows, _cursor} =
      EventQueries.list(owner_scope: scope, filter: %{subject_type: "WebhookBatch"})

    assert Enum.any?(batch_rows, &(&1.id == allowed_batch.id))
    refute Enum.any?(batch_rows, &(&1.id == mixed_batch.id))

    owner_conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, webhook_html} =
             live(owner_conn, "/billing/webhooks/#{allowed_webhook.id}?org=allowed-org")

    event_path = "/billing/events/#{allowed_single.id}?org=allowed-org"
    assert webhook_html =~ event_path

    event_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(),
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, event_html} = live(event_conn, event_path)
    assert event_html =~ "admin.webhook.replay.completed"
  end

  test "out-of-scope webhook route redirects with denial flash before rendering detail", %{
    conn: conn
  } do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    allowed_invoice = insert_invoice(allowed_customer, %{processor_id: "in_scope_redirect"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "out_scope_redirect"})

    allowed_webhook =
      insert_webhook(%{
        processor_event_id: "evt_scope_redirect",
        data: %{"object" => %{"id" => allowed_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_scope_redirect",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => allowed_invoice.processor_id}}
          })
      })

    denied_webhook =
      insert_webhook(%{
        processor_event_id: "evt_denied_redirect",
        data: %{"object" => %{"id" => denied_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_denied_redirect",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => denied_invoice.processor_id}}
          })
      })

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, allowed_html} =
             live(conn, "/billing/webhooks/#{allowed_webhook.id}?org=allowed-org")

    assert allowed_html =~ allowed_webhook.processor_event_id

    assert {:error, {:redirect, %{to: "/billing/webhooks?org=allowed-org", flash: flash_token}}} =
             redirect =
             live(conn, "/billing/webhooks/#{denied_webhook.id}?org=allowed-org")

    assert %{"error" => flash_error} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert flash_error == AccrueAdmin.Copy.Locked.owner_access_denied()

    assert redirect
  end

  test "ambiguous ownership renders blocked copy and no replay action", %{conn: conn} do
    ambiguous_webhook =
      insert_webhook(%{
        processor_event_id: "evt_ambiguous_route",
        status: :dead,
        data: %{"object" => %{"id" => "in_unknown"}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_ambiguous_route",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => "in_unknown"}}
          })
      })

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, html} =
             live(conn, "/billing/webhooks/#{ambiguous_webhook.id}?org=allowed-org")

    assert html =~
             "Ownership couldn&#39;t be verified for this webhook. Replay is unavailable until the linked billing owner is resolved."

    refute html =~ "evt_ambiguous_route"
    refute html =~ "Replay webhook for the active organization?"
    refute html =~ "data-role=\"replay-single\""

    refute TestRepo.exists?(
             from(event in Event,
               where:
                 event.type == "admin.webhook.replay.completed" and
                   event.subject_id == ^ambiguous_webhook.id
             )
           )
  end

  test "safe_utf8/1 returns :error for invalid-UTF-8 raw_body and does not crash Jason.decode",
       %{conn: conn} do
    # <<0xFF, 0xFE>> is valid Erlang binary but illegal UTF-8 — :unicode.characters_to_binary/1
    # returns {:error, "", rest} rather than raising; the fixed guard must catch it.
    invalid_utf8_body = <<0xFF, 0xFE, 0x41, 0x42>>

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_invalid_utf8",
        type: "invoice.payment_failed",
        status: :received,
        raw_body: invalid_utf8_body,
        data: %{"id" => "evt_invalid_utf8", "type" => "invoice.payment_failed"}
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    # The page must render without crashing; it falls back to the :data field
    assert {:ok, _view, html} = live(conn, "/billing/webhooks/#{webhook.id}")
    assert html =~ "invoice.payment_failed"
  end

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

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end

  defp insert_attempt_job(webhook_id) do
    TestRepo.insert!(%Oban.Job{
      state: "discarded",
      queue: "accrue_webhooks",
      worker: "Accrue.Webhook.DispatchWorker",
      args: %{"webhook_event_id" => webhook_id},
      errors: [%{"attempt" => 3, "error" => "processor timeout"}],
      attempt: 3,
      max_attempts: 25,
      inserted_at: ~U[2026-04-15 10:01:00.000000Z],
      attempted_at: ~U[2026-04-15 10:02:00.000000Z],
      discarded_at: ~U[2026-04-15 10:03:00.000000Z]
    })
  end

  defp dispatch_jobs(webhook_id) do
    TestRepo.all(
      from(job in Oban.Job,
        where:
          job.worker == "Accrue.Webhook.DispatchWorker" and
            fragment("?->>'webhook_event_id' = ?", job.args, ^webhook_id),
        order_by: [asc: job.inserted_at, asc: job.id]
      )
    )
  end

  defp replay_events_exist?(webhook_id) do
    TestRepo.exists?(
      from(event in Event,
        where:
          event.subject_id == ^webhook_id and
            event.type in ["webhook.replay_requested", "admin.webhook.replay.completed"]
      )
    )
  end

  defp replay_event_types(webhook_id) do
    TestRepo.all(
      from(event in Event,
        where:
          event.subject_id == ^webhook_id and
            event.type in ["webhook.replay_requested", "admin.webhook.replay.completed"],
        order_by: [asc: event.type],
        select: event.type
      )
    )
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
end
