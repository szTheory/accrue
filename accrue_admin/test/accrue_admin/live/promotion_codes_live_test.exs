defmodule AccrueAdmin.PromotionCodesLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Coupon, PromotionCode}
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

    coupon =
      insert_coupon(%{
        name: "Bundle coupon",
        processor_id: "coupon_bundle"
      })

    _active =
      insert_promotion_code(coupon, %{
        code: "BUNDLE10",
        processor_id: "promo_bundle",
        active: true,
        times_redeemed: 3
      })

    _inactive =
      insert_promotion_code(coupon, %{
        code: "BUNDLEOLD",
        processor_id: "promo_bundle_old",
        active: false
      })

    :ok
  end

  test "filters promotion codes independently from coupons", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/promotion-codes?q=BUNDLE&active=true")

    assert html =~ Copy.promotion_codes_index_headline()
    assert html =~ "BUNDLE10"
    assert html =~ "Bundle coupon"
    assert html =~ "/billing/promotion-codes/"
    assert html =~ "/billing/coupons/"
    refute html =~ "BUNDLEOLD"
  end

  test "renders Promotion codes through PageHeader with the Phase 197 LIST chrome", %{
    conn: conn
  } do
    contract = ListContracts.fetch!(:promotion_codes)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route <> "?view=all")

    assert_page_header_contract(html, contract)
    assert html =~ contract.page_header.title
    assert html =~ "Review customer-facing codes tied to coupons."
    assert_single_filter_form(html)
  end

  test "bare promotion codes route represents the Active codes default lens", %{conn: conn} do
    contract = ListContracts.fetch!(:promotion_codes)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, contract.route)

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ contract.default_lens.label
    assert html =~ "All promotion codes"
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing"
    assert html =~ "promotion codes"
    assert html =~ ~s(data-ax-clear-all)
  end

  test "promotion-code clear-all routes to All while preserving organization scope", %{conn: conn} do
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
             live(conn, "/billing/promotion-codes?org=allowed-org&active=true&q=BUNDLE")

    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/promotion-codes?org=allowed-org&amp;view=all")
    refute html =~ "active=true"
    refute html =~ "q=BUNDLE"
  end

  test "distinguishes promotion-code populated, first-run-empty, filtered-empty, queue-empty, and loading states",
       %{conn: conn} do
    contract = ListContracts.fetch!(:promotion_codes)
    {loading_key, loading_value} = ListContracts.loading_fixture()

    populated_conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, populated_html} = live(populated_conn, contract.route <> "?view=all")
    assert_list_state(populated_html, contract, "populated")
    assert populated_html =~ "BUNDLE10"

    TestRepo.delete_all(PromotionCode)
    TestRepo.delete_all(Coupon)

    first_run_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, first_run_html} =
             live(first_run_conn, contract.route <> "?view=all")

    assert_list_state(first_run_html, contract, "first-run-empty")
    assert first_run_html =~ contract.states.first_run_empty
    refute first_run_html =~ ~s(data-ax-clear-all)

    coupon =
      insert_coupon(%{
        name: "Inactive coupon",
        processor_id: "coupon_inactive_only"
      })

    insert_promotion_code(coupon, %{
      code: "INACTIVEONLY",
      processor_id: "promo_inactive_only",
      active: false
    })

    queue_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, queue_html} = live(queue_conn, contract.route <> "?active=true")

    assert_list_state(queue_html, contract, "filtered-empty")
    assert queue_html =~ ~s(data-ax-empty-reason="queue")
    assert queue_html =~ contract.states.queue_empty

    filtered_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, filtered_html} =
             live(filtered_conn, contract.route <> "?view=all&q=___phase197_no_code___")

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

  test "prioritizes promotion-code identity, state, value, time, and signals before raw ids", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/promotion-codes?view=all")

    assert_table_headings_in_order(html, [
      "Promotion code",
      "Status",
      "Coupon",
      "Expires",
      "Redemptions"
    ])

    assert_before(html, "BUNDLE10", "promo_bundle")
  end

  defp insert_coupon(attrs) do
    defaults = %{
      processor: "stripe",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Coupon{}
    |> Coupon.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_promotion_code(coupon, attrs) do
    defaults = %{
      processor: "stripe",
      coupon_id: coupon.id,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %PromotionCode{}
    |> PromotionCode.changeset(Map.merge(defaults, attrs))
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
