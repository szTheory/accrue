defmodule AccrueAdmin.InvoicesLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Invoice, Subscription}
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

    customer = insert_customer(%{name: "Invoice Customer", email: "invoice-list@example.com"})
    subscription = insert_subscription(customer)

    _draft =
      insert_invoice(customer, subscription, %{
        number: "INV-0001",
        processor_id: "in_0001",
        status: :draft
      })

    invoice =
      insert_invoice(customer, subscription, %{
        number: "INV-0002",
        processor_id: "in_0002",
        status: :open,
        amount_due_minor: 7_500,
        amount_remaining_minor: 7_500,
        amount_paid_minor: 0,
        total_minor: 7_500
      })

    {:ok, invoice: invoice}
  end

  test "filters invoice rows and renders detail links", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/invoices?status=open")

    assert html =~ Copy.invoices_index_headline()
    assert html =~ "INV-0002"
    assert html =~ "/billing/invoices/"
    assert html =~ "ax-chip ax-label"
    refute html =~ "ax-text-12"
  end

  test "renders Copy-backed empty index when search excludes all invoices", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/invoices?q=___accrue_empty_fixture___")

    assert html =~ Copy.invoices_index_empty_title()
    assert html =~ Copy.invoices_index_empty_copy()
  end

  test "bare navigation push_patches to default queue status", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/invoices?status=open,uncollectible")

    # FilterChipBar renders queue chip (cobalt) and All chip (slate)
    assert html =~ "ax-filter-chip-cobalt"
    assert html =~ "ax-filter-chip-slate"
    assert html =~ "?view=all"
  end

  test "view=all sentinel shows All chip active without redirect", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    # ?view=all must not redirect — the sentinel prevents a push_patch loop
    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")

    # All chip is active (slate) — not the queue chip (cobalt)
    assert html =~ "ax-filter-chip-slate"
    refute html =~ "ax-filter-chip-cobalt"
  end

  test "renders Invoices through PageHeader with exactly one h1", %{conn: conn} do
    contract = ListContracts.fetch!(:invoices)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route <> "?view=all")

    assert_page_header_contract(html, contract)
    assert html =~ contract.page_header.title
    assert html =~ "Work invoices that need collection."
    assert_single_filter_form(html)
  end

  test "bare invoices route represents the Needs collection queue", %{conn: conn} do
    contract = ListContracts.fetch!(:invoices)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route)

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ contract.default_lens.label
    assert html =~ "All invoices"
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing"
    assert html =~ "invoices"
    refute html =~ "total invoices"
  end

  test "invoice clear-all drops filters and preserves organization scope", %{conn: conn} do
    org_id = Ecto.UUID.generate()
    customer_filter_id = Ecto.UUID.generate()

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
               "/billing/invoices?org=allowed-org&status=open,uncollectible&q=INV&collection_method=send_invoice&customer_id=#{customer_filter_id}&phase197_state=loading-skeleton"
             )

    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/invoices?org=allowed-org&amp;view=all")
    refute html =~ "status=open"
    refute html =~ "collection_method=send_invoice"
    refute html =~ "phase197_state=loading-skeleton"
  end

  test "distinguishes invoice populated, first-run-empty, filtered-empty, queue-empty, and loading states",
       %{conn: conn} do
    contract = ListContracts.fetch!(:invoices)
    {loading_key, loading_value} = ListContracts.loading_fixture()

    populated_conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, populated_html} = live(populated_conn, contract.route <> "?view=all")
    assert_list_state(populated_html, contract, "populated")
    assert populated_html =~ "INV-0002"

    empty_org = Ecto.UUID.generate()

    first_run_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: empty_org,
        active_organization_slug: "empty-invoices",
        admin_organization_ids: [empty_org]
      )

    assert {:ok, _view, first_run_html} =
             live(first_run_conn, contract.route <> "?org=empty-invoices&view=all")

    assert_list_state(first_run_html, contract, "first-run-empty")
    assert first_run_html =~ contract.states.first_run_empty
    refute first_run_html =~ ~s(data-ax-clear-all)

    filtered_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, filtered_html} =
             live(filtered_conn, contract.route <> "?view=all&q=___phase197_no_invoice___")

    assert_list_state(filtered_html, contract, "filtered-empty")
    assert filtered_html =~ contract.states.filtered_empty
    assert filtered_html =~ ~s(data-ax-clear-all)

    queue_org = Ecto.UUID.generate()
    queue_customer = insert_customer(%{owner_type: "Organization", owner_id: queue_org})
    queue_subscription = insert_subscription(queue_customer)
    insert_invoice(queue_customer, queue_subscription, %{number: "INV-PAID", status: :paid})

    queue_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: queue_org,
        active_organization_slug: "queue-invoices",
        admin_organization_ids: [queue_org]
      )

    assert {:ok, _view, queue_html} =
             live(
               queue_conn,
               contract.route <> "?org=queue-invoices&status=open,uncollectible"
             )

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

  test "prioritizes invoice identity, state, money, time, and signals columns", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")

    assert_table_headings_in_order(html, [
      "Invoice",
      "Status",
      "Balance",
      "Collection",
      "Billing signals"
    ])
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Subscription{}
    |> Subscription.changeset(defaults)
    |> TestRepo.insert!()
  end

  defp insert_invoice(customer, subscription, attrs) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      processor: "stripe",
      currency: "usd",
      collection_method: "charge_automatically",
      amount_due_minor: 1_000,
      amount_paid_minor: 0,
      amount_remaining_minor: 1_000,
      total_minor: 1_000,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Invoice{}
    |> Invoice.force_status_changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
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

  defp assert_table_headings_in_order(html, labels) do
    text =
      html
      |> Floki.parse_document!()
      |> Floki.find("th")
      |> Enum.map_join(" ", &Floki.text/1)

    assert_in_order(text, labels)
  end

  defp assert_in_order(text, labels) do
    positions =
      Enum.map(labels, fn label ->
        {label, :binary.match(text, label)}
      end)

    missing =
      for {label, :nomatch} <- positions do
        label
      end

    assert missing == []

    positions
    |> Enum.map(fn {label, {position, _length}} -> {label, position} end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [{left_label, left_position}, {right_label, right_position}] ->
      assert left_position < right_position,
             "expected #{inspect(left_label)} to render before #{inspect(right_label)}"
    end)
  end
end
