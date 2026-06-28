defmodule AccrueAdmin.CustomersLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, PaymentMethod}
  alias Accrue.Test.Factory
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

    %{customer: customer} =
      Factory.customer(%{owner_type: "Team", owner_id: "team_001", email: "captain@example.com"})

    %{customer: other_customer} =
      Factory.customer(%{owner_type: "User", owner_id: "user_002", email: "other@example.com"})

    payment_method =
      TestRepo.insert!(
        PaymentMethod.changeset(%PaymentMethod{}, %{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "pm_team_default",
          type: "card",
          card_brand: "visa",
          card_last4: "4242",
          exp_month: 12,
          exp_year: 2030
        })
      )

    customer
    |> Customer.changeset(%{
      default_payment_method_id: payment_method.id,
      name: "Captain Customer"
    })
    |> TestRepo.update!()

    other_customer
    |> Customer.changeset(%{name: "Other Customer"})
    |> TestRepo.update!()

    :ok
  end

  test "filters customer rows through the shared query layer", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(
               conn,
               "/billing/customers?q=Captain&owner_type=Team&has_default_payment_method=true"
             )

    # New find-and-open surface: plain heading + description, no projections jargon.
    assert html =~ Copy.customers_index_heading()
    assert html =~ Copy.customers_index_description()
    refute html =~ "Searchable customer projections"

    assert html =~ ~s(<caption)
    assert html =~ Copy.customers_index_table_caption()
    assert html =~ "Captain Customer"

    # Payment-method column relabelled and softened (no raw pm id leaked into the list).
    assert html =~ "Payment method"
    assert html =~ "On file"
    refute html =~ "pm_team_default"

    # Billing-signals column dropped from the list (always-Off, belongs on detail).
    refute html =~ "Billing signals"

    # Owner-types KPI dropped; the two clean KPIs remain.
    refute html =~ "Distinct host billable types"

    # owner_type filter renders from the derived distinct types. With <= 3 seeded
    # owner types it is a segmented toggle (radiogroup), not a free-text input or select.
    assert html =~ ~s(name="owner_type")
    assert html =~ ~s(class="ax-segmented")

    # Copyable ID chip rendered via the registered Clipboard hook.
    assert html =~ "ax-id-badge"
    assert html =~ ~s(phx-hook="Clipboard")

    refute html =~ "Other Customer"
    assert html =~ "/billing/customers/"
  end

  test "renders Copy-backed empty index when search excludes all customers", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers?q=___accrue_empty_fixture___")

    assert html =~ "No customers for this organization yet"
    assert html =~ Copy.customers_index_empty_copy()
  end

  test "renders Customers through PageHeader with the Phase 197 LIST chrome", %{conn: conn} do
    contract = ListContracts.fetch!(:customers)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live_list(conn, contract.route <> "?view=all")

    assert_page_header_contract(html, contract)
    assert html =~ contract.page_header.title
    assert html =~ "Look up a customer and inspect their billing state."
    assert_single_filter_form(html)
  end

  test "shows customer default and quick-lens chips with honest visible count copy", %{
    conn: conn
  } do
    contract = ListContracts.fetch!(:customers)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live_list(conn, contract.route)

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ contract.default_lens.label
    assert html =~ "Missing payment method"
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing"
    assert html =~ "customers"
    refute html =~ "total customers"
  end

  test "customer clear-all preserves organization scope and removes removable filters", %{
    conn: conn
  } do
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
             live_list(
               conn,
               "/billing/customers?org=allowed-org&q=Captain&has_default_payment_method=false"
             )

    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/customers?org=allowed-org")
    refute html =~ "has_default_payment_method=false&amp;q=Captain"
  end

  test "distinguishes customer populated, first-run-empty, filtered-empty, and loading states",
       %{conn: conn} do
    contract = ListContracts.fetch!(:customers)
    {loading_key, loading_value} = ListContracts.loading_fixture()

    populated_conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, populated_html} = live_list(populated_conn, contract.route <> "?view=all")
    assert_list_state(populated_html, contract, "populated")
    assert populated_html =~ "Captain Customer"

    empty_org = Ecto.UUID.generate()

    first_run_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: empty_org,
        active_organization_slug: "empty-customers",
        admin_organization_ids: [empty_org]
      )

    assert {:ok, _view, first_run_html} =
             live_list(first_run_conn, contract.route <> "?org=empty-customers&view=all")

    assert_list_state(first_run_html, contract, "first-run-empty")
    assert first_run_html =~ contract.states.first_run_empty
    refute first_run_html =~ ~s(data-ax-clear-all)

    filtered_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, filtered_html} =
             live_list(filtered_conn, contract.route <> "?q=___phase197_no_customer___")

    assert_list_state(filtered_html, contract, "filtered-empty")
    assert filtered_html =~ contract.states.filtered_empty
    assert filtered_html =~ ~s(data-ax-clear-all)

    loading_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, loading_html} =
             live_list(loading_conn, contract.route <> "?#{loading_key}=#{loading_value}")

    assert_list_state(loading_html, contract, "loading-skeleton")
    assert loading_html =~ ~s(aria-busy="true")
    assert loading_html =~ contract.states.loading
  end

  test "prioritizes customer identity and payment state before plumbing ids", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live_list(conn, "/billing/customers?view=all")

    assert_table_headings_in_order(html, ["Customer", "Payment method", "ID"])
    assert_before(html, "Captain Customer", "cus_fake_00001")
  end

  defp live_list(conn, path), do: live(conn, path, on_error: :warn)

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

  defp assert_before(html, left, right), do: assert_in_order(html, [left, right])

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
