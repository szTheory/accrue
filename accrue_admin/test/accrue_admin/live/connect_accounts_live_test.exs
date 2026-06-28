defmodule AccrueAdmin.ConnectAccountsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Connect.Account
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

    _match =
      insert_account(%{
        stripe_account_id: "acct_match",
        owner_type: "Team",
        owner_id: "team_123",
        type: "express",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
        data: %{"platform_fee_override" => %{"percent" => "1.5"}}
      })

    _other =
      insert_account(%{
        stripe_account_id: "acct_other",
        owner_type: "User",
        owner_id: "user_456",
        type: "standard",
        charges_enabled: false,
        payouts_enabled: false,
        details_submitted: false
      })

    :ok
  end

  test "renders Connect accounts through PageHeader with exactly one h1", %{conn: conn} do
    contract = ListContracts.fetch!(:connect)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route <> "?view=all")

    assert_page_header_contract(html, contract)
    assert html =~ contract.page_header.title
    assert html =~ Copy.connect_accounts_page_copy_primary()
    assert_single_filter_form(html)
  end

  test "bare connect route represents the Needs attention queue", %{conn: conn} do
    contract = ListContracts.fetch!(:connect)

    insert_account(%{
      stripe_account_id: "acct_one_signal",
      charges_enabled: true,
      payouts_enabled: true,
      details_submitted: false
    })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route)

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ contract.default_lens.label
    assert html =~ "All accounts"
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing"
    assert html =~ "connected accounts"
    assert html =~ "acct_other"
    assert html =~ "acct_one_signal"
    refute html =~ "acct_match"
  end

  test "connect all-accounts lens keeps healthy accounts visible", %{conn: conn} do
    contract = ListContracts.fetch!(:connect)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route <> "?view=all")

    assert html =~ "All accounts"
    assert html =~ "acct_match"
    assert html =~ "acct_other"
  end

  test "connect clear-all drops filters and preserves organization scope", %{conn: conn} do
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
               "/billing/connect?org=allowed-org&type=express&charges_enabled=false&payouts_enabled=false&details_submitted=false&deauthorized=false&needs_attention=true&phase197_state=loading-skeleton"
             )

    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/connect?org=allowed-org&amp;view=all")
    refute html =~ "type=express"
    refute html =~ "needs_attention=true"
    refute html =~ "phase197_state=loading-skeleton"
  end

  test "distinguishes connect populated, first-run-empty, filtered-empty, queue-empty, and loading states",
       %{conn: conn} do
    contract = ListContracts.fetch!(:connect)
    {loading_key, loading_value} = ListContracts.loading_fixture()

    populated_conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, populated_html} = live(populated_conn, contract.route)
    assert_list_state(populated_html, contract, "populated")
    assert populated_html =~ "acct_other"

    TestRepo.delete_all(Account)

    first_run_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, first_run_html} = live(first_run_conn, contract.route <> "?view=all")
    assert_list_state(first_run_html, contract, "first-run-empty")
    assert first_run_html =~ contract.states.first_run_empty
    refute first_run_html =~ ~s(data-ax-clear-all)

    insert_account(%{stripe_account_id: "acct_filter_seed"})

    filtered_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, filtered_html} =
             live(filtered_conn, contract.route <> "?view=all&q=___phase197_no_account___")

    assert_list_state(filtered_html, contract, "filtered-empty")
    assert filtered_html =~ contract.states.filtered_empty
    assert filtered_html =~ ~s(data-ax-clear-all)

    TestRepo.delete_all(Account)

    insert_account(%{
      stripe_account_id: "acct_ready",
      charges_enabled: true,
      payouts_enabled: true,
      details_submitted: true
    })

    queue_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, queue_html} = live(queue_conn, contract.route)
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

  test "filters connect account rows and shows override state", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/connect?type=express&charges_enabled=true&q=acct_match")

    assert html =~ Copy.connect_accounts_headline()
    assert html =~ Copy.connect_accounts_page_copy_primary()
    assert html =~ "acct_match"
    assert html =~ "Override saved"
    assert html =~ "/billing/connect/"
    refute html =~ "acct_other"
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

  defp insert_account(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      type: "standard",
      country: "US",
      email: "owner@example.com",
      data: %{},
      capabilities: %{},
      requirements: %{},
      lock_version: 1
    }

    %Account{}
    |> Account.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end
end
