defmodule AccrueAdmin.EventsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Events
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.Copy
  alias AccrueAdmin.ListContracts
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

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_feed",
        type: "invoice.payment_failed",
        status: :dead
      })

    in_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    out_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    in_scope_invoice = insert_invoice(in_scope_customer, %{processor_id: "in_scope_invoice"})
    out_scope_invoice = insert_invoice(out_scope_customer, %{processor_id: "out_scope_invoice"})

    {:ok, _} =
      Events.record(%{
        type: "invoice.payment_failed.in_scope",
        subject_type: "Invoice",
        subject_id: in_scope_invoice.id,
        actor_type: "admin",
        actor_id: "admin_1",
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, _} =
      Events.record(%{
        type: "invoice.payment_failed.out_of_scope",
        subject_type: "Invoice",
        subject_id: out_scope_invoice.id,
        actor_type: "admin",
        actor_id: "admin_1",
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, _} =
      Events.record(%{
        type: "admin.webhook.replay.completed",
        subject_type: "WebhookEvent",
        subject_id: webhook.id,
        actor_type: "admin",
        actor_id: "admin_1",
        caused_by_webhook_event_id: webhook.id
      })

    {:ok,
     webhook_id: webhook.id,
     in_scope_invoice: in_scope_invoice,
     out_scope_invoice: out_scope_invoice}
  end

  test "renders Events through PageHeader with exactly one h1", %{conn: conn} do
    contract = ListContracts.fetch!(:events)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route)

    assert_page_header_contract(html, contract)
    assert html =~ contract.page_header.title
    assert html =~ Copy.billing_events_copy_global()
    assert_single_filter_form(html)
  end

  test "bare events route represents the All ledger lens", %{conn: conn} do
    contract = ListContracts.fetch!(:events)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route)

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ contract.default_lens.label
    assert html =~ "Admin changes"
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing"
    assert html =~ "events"
  end

  test "events Admin changes lens maps to actor_type=admin", %{conn: conn} do
    contract = ListContracts.fetch!(:events)
    admin_changes = List.first(contract.quick_lenses)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route <> "?actor_type=admin")

    assert html =~ admin_changes.label
    assert html =~ ~s(actor_type=admin)
    assert html =~ "ax-filter-chip-cobalt"
    refute html =~ ">By actor<"
  end

  test "events clear-all drops filters and preserves organization scope", %{conn: conn} do
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
               "/billing/events?org=allowed-org&actor_type=admin&type=invoice.payment_failed.in_scope&q=invoice&phase197_state=loading-skeleton"
             )

    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/events?org=allowed-org&amp;view=all")
    refute html =~ "actor_type=admin"
    refute html =~ "type=invoice.payment_failed"
    refute html =~ "phase197_state=loading-skeleton"
  end

  test "distinguishes event populated, first-run-empty, filtered-empty, and loading states",
       %{conn: conn} do
    contract = ListContracts.fetch!(:events)
    {loading_key, loading_value} = ListContracts.loading_fixture()

    populated_conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, populated_html} = live(populated_conn, contract.route)
    assert_list_state(populated_html, contract, "populated")
    assert populated_html =~ "invoice.payment_failed.in_scope"

    empty_org = Ecto.UUID.generate()

    first_run_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: empty_org,
        active_organization_slug: "empty-events",
        admin_organization_ids: [empty_org]
      )

    assert {:ok, _view, first_run_html} =
             live(first_run_conn, contract.route <> "?org=empty-events&view=all")

    assert_list_state(first_run_html, contract, "first-run-empty")
    assert first_run_html =~ contract.states.first_run_empty
    refute first_run_html =~ ~s(data-ax-clear-all)

    filtered_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, filtered_html} =
             live(filtered_conn, contract.route <> "?q=___phase197_no_event___")

    assert_list_state(filtered_html, contract, "filtered-empty")
    assert filtered_html =~ contract.states.filtered_empty
    assert filtered_html =~ ~s(data-ax-clear-all)

    loading_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, loading_html} =
             live(loading_conn, contract.route <> "?#{loading_key}=#{loading_value}")

    assert_list_state(loading_html, contract, "loading-skeleton")
    assert loading_html =~ ~s(aria-busy="true")
    assert loading_html =~ contract.states.loading
  end

  # --- Plan 175-06: Compliance actor-lens chip tests ---

  test "events list always renders a 'By actor' chip element", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/events")
    assert html =~ "By actor"
  end

  test "By actor chip is slate (inactive) when actor_type param is absent", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/events")
    # chip rendered with slate tone and an activation href
    assert html =~ "ax-filter-chip-slate"
    assert html =~ "actor_type"
  end

  test "By actor chip is cobalt (active) when actor_type=admin in params", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/events?actor_type=admin")
    assert html =~ "ax-filter-chip-cobalt"
    # should have Clear remove_href
    assert html =~ "Clear"
  end

  # --- end Plan 175-06 tests ---

  # --- Quick 260621-idn: >25-event pagination regression (integer-PK cursor) ---

  test "renders 'Load more' and appends rows for >25 events without crashing", %{conn: conn} do
    # Seed 30 globally-visible events so the feed overflows the 25-row page
    # limit. Pre-fix, mounting raised FunctionClauseError in Cursor.encode/2
    # because the event primary key is an integer, not a UUID.
    for n <- 1..30 do
      {:ok, _} =
        Events.record(%{
          type: "subscription.created.page#{n}",
          subject_type: "Subscription",
          subject_id: "sub_page_#{n}",
          actor_type: "admin",
          actor_id: "admin_1"
        })
    end

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/events")
    assert html =~ "Load more"

    first_page_rows = page_row_count(html)

    next_html =
      view
      |> element("#events [data-role=\"load-more\"]")
      |> render_click()

    assert page_row_count(next_html) > first_page_rows
  end

  defp page_row_count(html) do
    # Every rendered row (table `<tr>` and responsive card `<article>`) carries a
    # `data-row-id` attribute, regardless of whether the table is selectable, so
    # counting these is a stable proxy for "how many rows are on the page".
    html
    |> String.split("data-row-id=")
    |> length()
    |> Kernel.-(1)
  end

  # --- end Quick 260621-idn tests ---

  test "renders the active-organization event feed without out-of-scope rows", %{
    conn: conn,
    webhook_id: webhook_id,
    in_scope_invoice: in_scope_invoice,
    out_scope_invoice: out_scope_invoice
  } do
    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, html} =
             live(
               conn,
               "/billing/events?org=allowed-org&source_webhook_event_id=#{webhook_id}&actor_type=admin"
             )

    assert html =~ Copy.billing_events_copy_organization()
    assert html =~ "invoice.payment_failed.in_scope"
    assert html =~ in_scope_invoice.id
    refute html =~ "invoice.payment_failed.out_of_scope"
    refute html =~ out_scope_invoice.id
    assert html =~ webhook_id
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
      |> Ecto.Changeset.change(%{status: Map.get(attrs, :status, :received)})
      |> TestRepo.update!()
    end)
  end
end
