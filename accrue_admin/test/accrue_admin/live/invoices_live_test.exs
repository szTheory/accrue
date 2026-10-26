defmodule AccrueAdmin.InvoicesLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Invoice, Subscription}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.ListContracts
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Invoices, as: InvoicesQuery
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

  test "filters invoice rows and renders stored identity, status, amount, and detail links",
       %{conn: conn, invoice: invoice} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/invoices?status=open")

    assert html =~ Copy.invoices_index_headline()
    assert html =~ "INV-0002"
    assert html =~ "/billing/invoices/#{invoice.id}"
    assert html =~ "Open"
    assert html =~ "Automatic"
    refute html =~ "Charge Automatically"
    assert html =~ "$75.00"
    assert html =~ "Automatic tax off"
    refute html =~ "ax-text-12"
  end

  test "keeps invoice number, customer, and exact copyable processor ID on separate lines", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")
    document = Floki.parse_document!(html)
    row = Floki.find(document, ".ax-data-table-grid [data-row-id='#{invoice.id}']") |> hd()

    assert [primary] = Floki.find(row, ".ax-data-table-identity-primary a")
    assert Floki.text(primary) == "INV-0002"
    assert Floki.text(row) =~ "Invoice Customer"

    assert length(
             Floki.find(row, "[data-clipboard-text='in_0002'][aria-label='Copy invoice ID']")
           ) == 1

    card = Floki.find(document, ".ax-data-table-card[data-row-id='#{invoice.id}']") |> hd()

    assert length(
             Floki.find(card, "[data-clipboard-text='in_0002'][aria-label='Copy invoice ID']")
           ) == 1
  end

  test "default invoice queue exposes checked status controls for its returned rows", %{
    conn: conn
  } do
    customer = insert_customer(%{name: "Uncollectible Customer"})
    subscription = insert_subscription(customer)

    uncollectible =
      insert_invoice(customer, subscription, %{
        number: "INV-UNCOLLECTIBLE",
        status: :uncollectible
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/invoices")

    document = Floki.parse_document!(html)
    status_controls = Floki.find(document, "input[name='status[]'][type='checkbox']")

    assert Enum.any?(
             status_controls,
             &(Floki.attribute(&1, "value") == ["open"] and Floki.attribute(&1, "checked") == [""])
           )

    assert Enum.any?(
             status_controls,
             &(Floki.attribute(&1, "value") == ["uncollectible"] and
                 Floki.attribute(&1, "checked") == [""])
           )

    assert html =~ "INV-0002"
    assert html =~ "INV-UNCOLLECTIBLE"
    refute html =~ "INV-0001"
    assert uncollectible
  end

  test "mounted status changes preserve owner and search scope while rows follow the selection",
       %{
         conn: conn
       } do
    organization_id = Ecto.UUID.generate()
    foreign_organization_id = Ecto.UUID.generate()
    owner_customer = insert_customer(%{owner_type: "Organization", owner_id: organization_id})
    owner_subscription = insert_subscription(owner_customer)

    insert_invoice(owner_customer, owner_subscription, %{
      number: "INV-SCOPED-OPEN-OWNER",
      status: :open
    })

    owner_paid =
      insert_invoice(owner_customer, owner_subscription, %{
        number: "INV-SCOPED-PAID-OWNER",
        status: :paid
      })

    foreign_customer =
      insert_customer(%{owner_type: "Organization", owner_id: foreign_organization_id})

    foreign_subscription = insert_subscription(foreign_customer)

    insert_invoice(foreign_customer, foreign_subscription, %{
      number: "INV-SCOPED-PAID-FOREIGN",
      status: :paid
    })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: organization_id,
        active_organization_slug: "invoice-owner",
        admin_organization_ids: [organization_id]
      )

    assert {:ok, view, html} =
             live(
               conn,
               "/billing/invoices?org=invoice-owner&view=all&status=open,uncollectible&q=INV-SCOPED"
             )

    assert html =~ "INV-SCOPED-OPEN-OWNER"
    refute html =~ "INV-SCOPED-PAID-FOREIGN"

    html =
      view
      |> element("[data-role='filter-form']")
      |> render_change(%{"status" => ["paid", ""], "q" => "INV-SCOPED", "view" => "all"})

    assert_patch(view, "/billing/invoices?org=invoice-owner&q=INV-SCOPED&status=paid&view=all")
    assert html =~ "INV-SCOPED-PAID-OWNER"

    visible_row_ids =
      html
      |> Floki.parse_document!()
      |> Floki.find("tbody > tr[data-row-id]")
      |> Enum.map(&Floki.attribute(&1, "data-row-id"))
      |> List.flatten()

    assert visible_row_ids == [owner_paid.id]
    assert owner_paid
  end

  test "direct multi-status URLs normalize to supported status order and select matching rows", %{
    conn: conn
  } do
    customer = insert_customer(%{name: "Direct Status Customer"})
    subscription = insert_subscription(customer)

    paid =
      insert_invoice(customer, subscription, %{number: "INV-DIRECT-PAID", status: :paid})

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, _html} =
             live(conn, "/billing/invoices?view=all&status=paid,open")

    assert InvoicesQuery.normalize_status_selection("paid,open") == "open,paid"
    html = render(view)
    document = Floki.parse_document!(html)
    status_controls = Floki.find(document, "input[name='status[]'][type='checkbox']")

    assert Enum.any?(
             status_controls,
             &(Floki.attribute(&1, "value") == ["open"] and Floki.attribute(&1, "checked") == [""])
           )

    assert Enum.any?(
             status_controls,
             &(Floki.attribute(&1, "value") == ["paid"] and Floki.attribute(&1, "checked") == [""])
           )

    assert html =~ "INV-0002"
    assert html =~ "INV-DIRECT-PAID"
    refute html =~ "INV-0001"
    assert paid
  end

  test "organization invoice list excludes invoices owned by another organization", %{conn: conn} do
    organization_id = Ecto.UUID.generate()
    foreign_organization_id = Ecto.UUID.generate()
    owner_customer = insert_customer(%{owner_type: "Organization", owner_id: organization_id})
    owner_subscription = insert_subscription(owner_customer)

    owner_invoice =
      insert_invoice(owner_customer, owner_subscription, %{
        number: "INV-SCOPED-OWNER",
        processor_id: "in_scoped_owner",
        status: :open
      })

    foreign_customer =
      insert_customer(%{owner_type: "Organization", owner_id: foreign_organization_id})

    foreign_subscription = insert_subscription(foreign_customer)

    insert_invoice(foreign_customer, foreign_subscription, %{
      number: "INV-SCOPED-FOREIGN",
      processor_id: "in_scoped_foreign",
      status: :open
    })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: organization_id,
        active_organization_slug: "invoice-owner",
        admin_organization_ids: [organization_id]
      )

    assert {:ok, _view, html} = live(conn, "/billing/invoices?org=invoice-owner&view=all")

    assert html =~ "INV-SCOPED-OWNER"
    assert html =~ "/billing/invoices/#{owner_invoice.id}"
    refute html =~ "INV-SCOPED-FOREIGN"
  end

  test "invoice fixtures preserve raw date, amount, currency, identity, and owner observations" do
    reference = ~U[2026-10-08 12:00:00.000000Z]
    organization_id = Ecto.UUID.generate()
    foreign_organization_id = Ecto.UUID.generate()
    empty_organization_id = Ecto.UUID.generate()

    empty_owner_scope = organization_scope(empty_organization_id)
    assert {[], nil} = InvoicesQuery.list(owner_scope: empty_owner_scope)

    single_organization_id = Ecto.UUID.generate()

    single_customer =
      insert_customer(%{owner_type: "Organization", owner_id: single_organization_id})

    single_subscription = insert_subscription(single_customer)

    single_invoice =
      insert_invoice(single_customer, single_subscription, %{
        number: "INV-FIXTURE-SINGLE",
        status: :paid
      })

    {single_rows, nil} =
      InvoicesQuery.list(owner_scope: organization_scope(single_organization_id))

    assert [%{id: single_id, status: :paid}] = single_rows
    assert single_id == single_invoice.id

    customer = insert_customer(%{owner_type: "Organization", owner_id: organization_id})
    subscription = insert_subscription(customer)
    fixtures = invoice_fixture_set(customer, subscription, reference)

    foreign_customer =
      insert_customer(%{owner_type: "Organization", owner_id: foreign_organization_id})

    foreign_invoice =
      foreign_customer
      |> then(&insert_subscription/1)
      |> then(
        &insert_invoice(foreign_customer, &1, %{number: "INV-FIXTURE-FOREIGN", status: :paid})
      )

    assert fixtures.dates.before.due_date == DateTime.add(reference, -1, :second)
    assert fixtures.dates.equal.due_date == reference
    assert fixtures.dates.after.due_date == DateTime.add(reference, 1, :second)
    assert is_nil(fixtures.dates.missing.due_date)

    assert fixtures.money.zero.amount_due_minor == 0
    assert fixtures.money.zero.currency == "usd"
    assert fixtures.money.zero_decimal.amount_due_minor == 1_234
    assert fixtures.money.zero_decimal.currency == "jpy"
    assert fixtures.money.three_decimal.amount_due_minor == 1_234
    assert fixtures.money.three_decimal.currency == "kwd"
    assert fixtures.money.unsupported_currency.currency == "zzz"
    assert fixtures.money.missing_currency.currency == nil

    all_owner_fixtures = Map.merge(fixtures.dates, fixtures.money) |> Map.values()
    assert length(all_owner_fixtures) == 10
    assert Enum.all?(all_owner_fixtures, &(&1.status == :open))
    assert Enum.all?(all_owner_fixtures, &(&1.inserted_at == reference))
    assert Enum.all?(all_owner_fixtures, &(&1.customer_id == customer.id))
    assert length(Enum.uniq_by(all_owner_fixtures, & &1.id)) == 10

    {scoped_rows, nil} = InvoicesQuery.list(owner_scope: organization_scope(organization_id))
    scoped_ids = MapSet.new(Enum.map(scoped_rows, & &1.id))
    assert MapSet.equal?(scoped_ids, MapSet.new(Enum.map(all_owner_fixtures, & &1.id)))
    refute MapSet.member?(scoped_ids, foreign_invoice.id)
    assert Enum.all?(scoped_rows, &(&1.owner_id == organization_id))
  end

  test "overdue is a separate collection signal for open invoices strictly past due", %{
    conn: conn
  } do
    now = Accrue.Clock.utc_now()
    customer = insert_customer(%{name: "Boundary Customer"})
    subscription = insert_subscription(customer)

    overdue =
      insert_invoice(customer, subscription, %{
        number: "INV-OVERDUE-OPEN",
        status: :open,
        due_date: DateTime.add(now, -1, :second)
      })

    due_now =
      insert_invoice(customer, subscription, %{
        number: "INV-DUE-NOW",
        status: :open,
        due_date: now
      })

    future =
      insert_invoice(customer, subscription, %{
        number: "INV-DUE-FUTURE",
        status: :open,
        due_date: DateTime.add(now, 1, :second)
      })

    unknown =
      insert_invoice(customer, subscription, %{
        number: "INV-DUE-UNKNOWN",
        status: :open,
        due_date: nil
      })

    paid =
      insert_invoice(customer, subscription, %{
        number: "INV-PAID-PAST-DUE",
        status: :paid,
        due_date: DateTime.add(now, -1, :second)
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")

    doc = Floki.parse_document!(html)
    overdue_row = Floki.find(doc, "[data-row-id='#{overdue.id}']") |> hd()
    due_now_row = Floki.find(doc, "[data-row-id='#{due_now.id}']") |> hd()
    future_row = Floki.find(doc, "[data-row-id='#{future.id}']") |> hd()
    unknown_row = Floki.find(doc, "[data-row-id='#{unknown.id}']") |> hd()
    paid_row = Floki.find(doc, "[data-row-id='#{paid.id}']") |> hd()

    assert Floki.text(overdue_row) =~ "Overdue"
    refute Floki.text(due_now_row) =~ "Overdue"
    refute Floki.text(future_row) =~ "Overdue"
    refute Floki.text(unknown_row) =~ "Overdue"
    refute Floki.text(paid_row) =~ "Overdue"
    assert Floki.text(paid_row) =~ "Paid"
    assert Floki.text(overdue_row) =~ "Open"
    refute Floki.text(html) =~ "False"

    overdue_card = Floki.find(doc, ".ax-data-table-card[data-row-id='#{overdue.id}']") |> hd()
    unknown_card = Floki.find(doc, ".ax-data-table-card[data-row-id='#{unknown.id}']") |> hd()

    assert Floki.text(overdue_card) =~
             Calendar.strftime(overdue.due_date, "%b %d, %Y")

    assert Floki.text(unknown_card) =~ "Due date unavailable"
    assert Floki.text(overdue_card) =~ "Overdue"
    assert Floki.find(overdue_card, "a[aria-label^='View invoice']") != []
  end

  test "invoice list formats supported precision and keeps unknown money unavailable", %{
    conn: conn
  } do
    customer = insert_customer(%{name: "Money Boundary"})
    subscription = insert_subscription(customer)

    fixtures =
      [
        zero: {0, "usd"},
        zero_decimal: {1_234, "jpy"},
        three_decimal: {1_234, "kwd"},
        unsupported: {1_234, "zzz"},
        missing_currency: {50, nil},
        missing_amount: {nil, "usd"}
      ]
      |> Map.new(fn {key, {amount, currency}} ->
        invoice =
          insert_invoice(customer, subscription, %{
            number: "INV-LIST-MONEY-#{key}",
            status: :open,
            amount_due_minor: amount,
            amount_remaining_minor: amount,
            total_minor: amount,
            currency: currency
          })

        {key, invoice}
      end)

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")
    doc = Floki.parse_document!(html)

    row_text = fn invoice ->
      doc |> Floki.find("[data-row-id='#{invoice.id}']") |> hd() |> Floki.text()
    end

    assert row_text.(fixtures.zero) =~ "$0.00"

    assert row_text.(fixtures.zero_decimal) =~ "¥" or row_text.(fixtures.zero_decimal) =~ "￥" or
             row_text.(fixtures.zero_decimal) =~ "JPY",
           inspect(row_text.(fixtures.zero_decimal))

    assert row_text.(fixtures.zero_decimal) =~ "1,234"
    assert row_text.(fixtures.three_decimal) =~ "1.234"
    assert row_text.(fixtures.unsupported) =~ "--"
    assert row_text.(fixtures.missing_currency) =~ "--"
    assert row_text.(fixtures.missing_amount) =~ "--"
  end

  test "renders Copy-backed filtered empty list when search excludes all invoices", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/invoices?q=___accrue_empty_fixture___")

    assert html =~ Copy.invoices_list_filtered_empty_title()
    assert html =~ Copy.invoices_list_filtered_empty_body()
  end

  test "bare navigation push_patches to default queue status", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/invoices?status=open,uncollectible")

    # The selected queue view is separate from applied-filter chips.
    assert html =~ ~s(data-ax-view-nav)
    assert html =~ ~s(aria-current="page")

    assert Floki.find(
             Floki.parse_document!(html),
             "[data-ax-filter-chips] [data-filter='status_queue']"
           ) == []

    assert html =~ "?view=all"
  end

  test "view=all sentinel shows All chip active without redirect", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    # ?view=all must not redirect — the sentinel prevents a push_patch loop
    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")

    # All is selected in the view navigation, not represented as a chip.
    assert html =~ ~s(data-ax-view-nav)

    assert length(
             Floki.find(Floki.parse_document!(html), "[data-ax-view-nav] a[aria-current='page']")
           ) == 1

    assert Floki.find(
             Floki.parse_document!(html),
             "[data-ax-filter-chips] [data-filter='view_all']"
           ) == []
  end

  test "renders Invoices through PageHeader with exactly one h1", %{conn: conn} do
    contract = ListContracts.fetch!(:invoices)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route <> "?view=all")

    assert_page_header_contract(html, contract)
    assert html =~ contract.page_header.title
    assert html =~ "Review outstanding balances and invoice history."
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

    document = Floki.parse_document!(html)

    assert length(Floki.find(document, "[data-ax-page-filter-toolbar] [data-ax-filter-chips]")) ==
             1

    assert length(Floki.find(document, "[data-role='list-status'] [data-ax-page-filter-toolbar]")) ==
             1

    assert length(Floki.find(document, "[data-ax-result-count]")) == 1
    assert Floki.find(document, "[data-role='row-count']") == []
    assert Floki.find(document, "[data-ax-clear-all]") == []
    assert Floki.find(document, "[data-role='clear-filters']") == []
  end

  test "invoice filters, lens, active constraints, count, and clear share one hierarchy", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all&status=open&q=INV-0002")

    document = Floki.parse_document!(html)

    assert length(Floki.find(document, "[data-ax-page-filter-toolbar] [data-ax-filter-chips]")) ==
             1

    assert length(Floki.find(document, "[data-ax-page-filter-toolbar] [data-filter='status']")) ==
             1

    assert length(Floki.find(document, "[data-ax-page-filter-toolbar] [data-filter='q']")) == 1

    assert length(Floki.find(document, "[data-ax-page-filter-toolbar] [data-ax-result-count]")) ==
             1

    assert length(Floki.find(document, "[data-ax-page-filter-toolbar] [data-ax-clear-all]")) == 1

    assert length(Floki.find(document, "[data-role='clear-filters']")) == 1

    assert length(Floki.find(document, "[data-ax-result-count]")) == 1
    assert Floki.find(document, "[data-role='row-count']") == []
  end

  test "invoice view is separate from labeled constraints and remove links retain scope and query",
       %{conn: conn} do
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: Ecto.UUID.generate(),
        active_organization_slug: "allowed-org",
        admin_organization_ids: []
      )

    assert {:ok, _view, html} =
             live(
               conn,
               "/billing/invoices?org=allowed-org&view=all&status=open&q=Atelier+Caf%C3%A9"
             )

    document = Floki.parse_document!(html)

    assert Floki.text(Floki.find(document, "fieldset[data-filter-group='status'] legend")) ==
             "Status"

    assert length(Floki.find(document, "label[for='invoices-filter-q']")) == 1
    assert length(Floki.find(document, "details.ax-data-table-filter-disclosure")) == 1
    assert length(Floki.find(document, "[data-ax-view-nav] a[aria-current='page']")) == 1
    refute Floki.find(document, "[data-ax-filter-chips] [data-filter='view_all']") != []
    assert Floki.text(Floki.find(document, "[data-ax-filter-chips]")) =~ "Atelier Café"

    remove_links = Floki.find(document, "[data-ax-filter-chips] a[aria-label^='Remove']")
    assert Enum.any?(remove_links, &(Floki.attribute(&1, "href") |> hd() =~ "org=allowed-org"))
    assert Enum.any?(remove_links, &(Floki.attribute(&1, "href") |> hd() =~ "view=all"))

    assert Enum.any?(
             remove_links,
             &(Floki.attribute(&1, "href") |> hd() =~ "q=Atelier+Caf%C3%A9")
           )

    assert length(Floki.find(document, "[data-ax-page-filter-toolbar] [data-ax-clear-all]")) == 1
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

    clear_href =
      html
      |> Floki.parse_document!()
      |> Floki.find("[data-ax-clear-all]")
      |> Floki.attribute("href")
      |> hd()

    assert clear_href == "/billing/invoices?org=allowed-org"
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

  test "prioritizes invoice identity, state, money, due date, collection, and ownership columns",
       %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/invoices?view=all")

    assert_table_headings_in_order(html, [
      "Invoice",
      "Status",
      "Balance",
      "Collection",
      "Ownership and tax"
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

  defp invoice_fixture_set(customer, subscription, reference) do
    dates =
      [
        before: DateTime.add(reference, -1, :second),
        equal: reference,
        after: DateTime.add(reference, 1, :second),
        missing: nil
      ]
      |> Map.new(fn {label, due_date} ->
        invoice =
          insert_invoice(customer, subscription, %{
            number: "INV-FIXTURE-DATE-#{label}",
            status: :open,
            due_date: due_date
          })
          |> pin_invoice_inserted_at(reference)

        {label, invoice}
      end)

    money =
      [
        zero: {0, "usd"},
        zero_decimal: {1_234, "jpy"},
        two_decimal: {1_234, "usd"},
        three_decimal: {1_234, "kwd"},
        unsupported_currency: {1_234, "zzz"},
        missing_currency: {50, nil}
      ]
      |> Map.new(fn {label, {amount_minor, currency}} ->
        invoice =
          insert_invoice(customer, subscription, %{
            number: "INV-FIXTURE-MONEY-#{label}",
            status: :open,
            amount_due_minor: amount_minor,
            amount_remaining_minor: amount_minor,
            total_minor: amount_minor,
            currency: currency
          })
          |> pin_invoice_inserted_at(reference)

        {label, invoice}
      end)

    %{dates: dates, money: money}
  end

  defp pin_invoice_inserted_at(invoice, timestamp) do
    invoice
    |> Ecto.Changeset.change(inserted_at: timestamp)
    |> TestRepo.update!()
  end

  defp organization_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1"},
      organization_id: organization_id,
      platform_admin?: true,
      admin_org_ids: []
    }
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
