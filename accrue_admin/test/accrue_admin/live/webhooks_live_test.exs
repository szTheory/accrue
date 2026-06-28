defmodule AccrueAdmin.WebhooksLiveTest do
  use AccrueAdmin.LiveCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.Copy
  alias AccrueAdmin.ListContracts
  alias AccrueAdmin.OwnerScope
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
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    insert_webhook(%{
      processor_event_id: "evt_dead",
      type: "invoice.payment_failed",
      status: :dead,
      livemode: true,
      received_at: ~U[2026-04-15 10:00:00Z]
    })

    insert_webhook(%{
      processor_event_id: "evt_ok",
      type: "invoice.paid",
      status: :succeeded,
      livemode: false,
      received_at: ~U[2026-04-15 09:00:00Z]
    })

    :ok
  end

  test "renders Webhooks through PageHeader with exactly one h1", %{conn: conn} do
    contract = ListContracts.fetch!(:webhooks)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route <> "?view=all")

    assert_page_header_contract(html, contract)
    assert html =~ contract.page_header.title
    assert html =~ Copy.webhooks_list_subtitle()
    assert_single_filter_form(html)
  end

  test "bare webhooks route represents the Needs replay queue", %{conn: conn} do
    contract = ListContracts.fetch!(:webhooks)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route)

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ contract.default_lens.label
    assert html =~ "All deliveries"
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing"
    assert html =~ "webhook deliveries"
  end

  test "webhook clear-all drops filters and preserves organization scope", %{conn: conn} do
    org_id = Ecto.UUID.generate()

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: org_id,
        active_organization_slug: "allowed-org",
        admin_organization_ids: [org_id]
      )

    assert {:ok, _view, html} =
             live(
               conn,
               "/billing/webhooks?org=allowed-org&status=failed,dead&type=invoice.payment_failed&livemode=true&phase197_state=loading-skeleton"
             )

    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/webhooks?org=allowed-org&amp;view=all")
    refute html =~ "status=failed"
    refute html =~ "type=invoice.payment_failed"
    refute html =~ "phase197_state=loading-skeleton"
  end

  test "distinguishes webhook populated, first-run-empty, filtered-empty, queue-empty, and loading states",
       %{conn: conn} do
    contract = ListContracts.fetch!(:webhooks)
    {loading_key, loading_value} = ListContracts.loading_fixture()

    populated_conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, populated_html} = live(populated_conn, contract.route <> "?view=all")
    assert_list_state(populated_html, contract, "populated")
    assert populated_html =~ "evt_dead"

    empty_org = Ecto.UUID.generate()

    first_run_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: empty_org,
        active_organization_slug: "empty-webhooks",
        admin_organization_ids: [empty_org]
      )

    assert {:ok, _view, first_run_html} =
             live(first_run_conn, contract.route <> "?org=empty-webhooks&view=all")

    assert_list_state(first_run_html, contract, "first-run-empty")
    assert first_run_html =~ contract.states.first_run_empty
    refute first_run_html =~ ~s(data-ax-clear-all)

    filtered_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, filtered_html} =
             live(filtered_conn, contract.route <> "?view=all&type=does-not-exist-zzz")

    assert_list_state(filtered_html, contract, "filtered-empty")
    assert filtered_html =~ contract.states.filtered_empty
    assert filtered_html =~ ~s(data-ax-clear-all)

    queue_org = Ecto.UUID.generate()
    queue_customer = insert_customer(%{owner_type: "Organization", owner_id: queue_org})
    queue_invoice = insert_invoice(queue_customer, %{processor_id: "in_queue_webhook"})

    insert_webhook(%{
      processor_event_id: "evt_queue_succeeded",
      status: :succeeded,
      type: "invoice.paid",
      data: %{"object" => %{"id" => queue_invoice.processor_id}},
      raw_body:
        Jason.encode!(%{
          "id" => "evt_queue_succeeded",
          "type" => "invoice.paid",
          "data" => %{"object" => %{"id" => queue_invoice.processor_id}}
        })
    })

    queue_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: queue_org,
        active_organization_slug: "queue-webhooks",
        admin_organization_ids: [queue_org]
      )

    assert {:ok, _view, queue_html} =
             live(queue_conn, contract.route <> "?org=queue-webhooks&status=failed,dead")

    assert_list_state(queue_html, contract, "filtered-empty")
    assert queue_html =~ ~s(data-ax-empty-reason="queue")
    assert queue_html =~ contract.states.queue_empty
    refute queue_html =~ contract.states.first_run_empty

    loading_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, loading_html} =
             live(loading_conn, contract.route <> "?#{loading_key}=#{loading_value}")

    assert_list_state(loading_html, contract, "loading-skeleton")
    assert loading_html =~ ~s(aria-busy="true")
    assert loading_html =~ contract.states.loading
  end

  test "preserves selection-driven replay controls inside the webhooks list", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/webhooks?status=dead")

    assert html =~ ~s(data-role="toggle-all")
    assert html =~ Copy.webhooks_retry_selected_label()
  end

  test "filters webhook rows and runs a selection-driven retry with plain-language confirm", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} =
      live(conn, "/billing/webhooks?status=dead&type=invoice.payment_failed&livemode=true")

    assert html =~ Copy.webhooks_list_heading()
    assert html =~ Copy.webhooks_list_subtitle()
    assert html =~ ~s(<caption)
    assert html =~ Copy.webhooks_index_table_caption()
    # UX-03: table cells use ax-body like money index DataTable rhythm
    assert html =~ "ax-body"
    refute html =~ "ax-text-12"
    assert html =~ "evt_dead"
    refute html =~ "evt_ok"

    # Plain-language helper line, no jargon, and the old card/jargon is gone.
    assert html =~ "Events that failed every automatic retry land here"
    refute html =~ "DLQ bulk replay"
    refute html =~ "dead-letter slice"
    refute html =~ "Replay filtered DLQ rows"

    # Select the visible dead-lettered row, then click the primary Retry selected.
    html = render_click(element(view, "[data-role='toggle-all']"))
    assert html =~ ~s(data-role="bulk-action")
    assert html =~ Copy.webhooks_retry_selected_label()

    render_click(element(view, "[data-role='bulk-action']"))
    # bulk-action notifies the parent via send/2 -> handle_info; render/1 picks it up.
    html = render(view)

    assert html =~ "Retry 1 webhook event?"
    assert html =~ "failed every automatic retry"

    html = render_click(element(view, "[data-role='confirm-retry-selected']"))
    assert html =~ "Retrying 1 event"
  end

  test "filtered-to-zero shows the filtered-empty copy, not the truly-empty hero", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    # The org genuinely HAS deliveries (evt_dead + evt_ok from setup); this filter
    # matches no type, so zero rows are the result of filtering — not an empty org.
    {:ok, _view, html} = live(conn, "/billing/webhooks?type=does-not-exist-zzz")

    assert html =~ "No webhook deliveries match these filters"
    refute html =~ "No webhook deliveries for this organization yet"
  end

  test "selection-driven retry records an audit event of the selected ids and count", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    dead = TestRepo.one!(from(e in WebhookEvent, where: e.processor_event_id == "evt_dead"))

    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")

    render_click(
      element(
        view,
        ~s([data-role="card-list"] [data-role="toggle-row"][data-row-id="#{dead.id}"])
      )
    )

    render_click(element(view, "[data-role='bulk-action']"))
    render_click(element(view, "[data-role='confirm-retry-selected']"))

    event =
      TestRepo.one!(
        from(e in Event,
          where: e.type == "admin.webhook.bulk_replay.completed",
          order_by: [desc: e.inserted_at],
          limit: 1
        )
      )

    assert event.subject_type == "WebhookBatch"
    assert event.subject_id == "selected"
    assert event.data["count"] == 1
    assert event.data["ids"] == [dead.id]
  end

  test "scoped bulk replay counts ignore rows outside the active organization" do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    allowed_invoice = insert_invoice(allowed_customer, %{processor_id: "in_scope_bulk"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "out_scope_bulk"})

    insert_webhook(%{
      processor_event_id: "evt_scope_bulk",
      status: :dead,
      type: "invoice.payment_failed",
      data: %{"object" => %{"id" => allowed_invoice.processor_id}},
      raw_body:
        Jason.encode!(%{
          "id" => "evt_scope_bulk",
          "type" => "invoice.payment_failed",
          "data" => %{"object" => %{"id" => allowed_invoice.processor_id}}
        })
    })

    insert_webhook(%{
      processor_event_id: "evt_out_scope_bulk",
      status: :dead,
      type: "invoice.payment_failed",
      data: %{"object" => %{"id" => denied_invoice.processor_id}},
      raw_body:
        Jason.encode!(%{
          "id" => "evt_out_scope_bulk",
          "type" => "invoice.payment_failed",
          "data" => %{"object" => %{"id" => denied_invoice.processor_id}}
        })
    })

    owner_scope = organization_owner_scope("org_allowed")

    assert Webhooks.bulk_replay_count(owner_scope, %{
             status: :dead,
             type: "invoice.payment_failed"
           }) ==
             1
  end

  test "blocked bulk replay does not emit replay-success audit events", %{conn: conn} do
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "out_scope_bulk_blocked"})

    denied_webhook =
      insert_webhook(%{
        processor_event_id: "evt_out_scope_only",
        status: :dead,
        type: "invoice.payment_failed",
        data: %{"object" => %{"id" => denied_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_out_scope_only",
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

    {:ok, _view, html} =
      live(conn, "/billing/webhooks?status=dead&type=invoice.payment_failed&org=allowed-org")

    # The out-of-scope dead row is filtered out of the org-scoped list entirely, so
    # it is never selectable and never retried — no replay event is emitted for it.
    refute html =~ denied_webhook.id

    refute TestRepo.exists?(
             from(event in Event,
               where:
                 event.type == "admin.webhook.replay.completed" and
                   event.subject_id == ^denied_webhook.id
             )
           )
  end

  defp assert_page_header_contract(html, contract) do
    assert html =~ ~s(data-ax-page-header)
    assert html =~ ~s(data-ax-page-title)
    assert html =~ ~s(data-component-group="page-header-actions-breadcrumbs")
    assert html =~ ~s(data-ax-page-filter-toolbar)
    assert_one_h1(html)
    assert html =~ ~s(data-ax-list="#{contract.list_id}")
  end

  defp assert_single_filter_form(html) do
    assert html
           |> Floki.parse_document!()
           |> Floki.find(~s([data-role="filter-form"]))
           |> length() == 1
  end

  defp assert_list_state(html, contract, state) do
    assert html =~ ~s(data-ax-list="#{contract.list_id}")
    assert html =~ ~s(data-ax-state="#{state}")
  end

  defp assert_one_h1(html) do
    assert html |> Floki.parse_document!() |> Floki.find("h1") |> length() == 1
  end

  defp insert_webhook(attrs) do
    defaults = %{
      processor: "stripe",
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "invoice.payment_failed",
      livemode: false,
      endpoint: :default,
      status: :received,
      raw_body:
        Jason.encode!(%{
          "id" => "evt_seed",
          "object" => "event",
          "type" => "invoice.payment_failed"
        }),
      received_at: DateTime.utc_now(),
      data: %{"id" => "evt_seed", "object" => "event", "type" => "invoice.payment_failed"}
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
end
