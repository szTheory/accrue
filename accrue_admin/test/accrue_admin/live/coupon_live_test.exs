defmodule AccrueAdmin.CouponLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias AccrueAdmin.Copy
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
        name: "Annual discount",
        processor_id: "coupon_annual",
        amount_off_minor: 1_500,
        currency: "usd",
        max_redemptions: 100,
        metadata: %{"channel" => "sales"},
        data: %{"remote" => "coupon_annual"}
      })

    insert_promotion_code(coupon, %{
      code: "ANNUAL15",
      processor_id: "promo_annual",
      active: true,
      max_redemptions: 100,
      times_redeemed: 8
    })

    {:ok, coupon: coupon}
  end

  test "D-02 D-14 D-15 D-16 D-17 renders coupon summary-first read-only detail contract", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}")

    assert heading_count(html, "h1") == 1
    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1
    assert data_attr_count(html, "data-ax-action-band") == 0
    assert data_attr_count(html, "data-ax-action-overflow-menu") == 0

    assert html =~ "Annual discount"
    assert html =~ "Valid state"
    assert html =~ "Discount"
    assert html =~ "Duration"
    assert html =~ "Redeem by"
    assert html =~ "Max redemptions"
    assert html =~ "Current redemptions"
    assert html =~ "Promotion codes"
    assert html =~ Copy.coupon_detail_section_codes_heading()
    assert html =~ "ANNUAL15"
    assert html =~ "/billing/promotion-codes/"
    assert html =~ "Open this section to load"

    refute html =~ ~s(class="ax-kpi-grid")
    refute html =~ "channel"
    refute html =~ "remote"

    assert major_band_order(html) == [
             :summary_card,
             :summary_list,
             :drill_section,
             :related_resources,
             :lazy_activity,
             :lazy_json
           ]
  end

  test "renders RelatedResources card with promotion codes and events links", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}")

    # Related resources card must be present
    assert html =~ ~s(class="ax-card ax-related ax-related-resources")
    # Promotion codes link
    assert html =~ "/billing/promotion-codes"
    # Events filtered by Coupon subject
    assert html =~ "subject_type=Coupon"
    assert html =~ "subject_id=#{coupon.id}"
  end

  test "renders Detail.summary_card hero not a hand-rolled page header", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}")

    # Detail.summary_card renders ax-summary-card class
    assert html =~ "ax-summary-card"
    # Should NOT have a hand-rolled ax-page-header as the main coupon hero
    # (the summary_card replaces it; ax-page-header may still appear in KPI section)
    # Verify the eyebrow comes from the summary_card hero area
    assert html =~ Copy.coupon_detail_eyebrow()
  end

  test "renders projection section as Detail.detail_section with semantic dl field list", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}")

    # Detail.detail_section renders ax-detail-section class
    assert html =~ "ax-detail-section"
    # Detail.detail_field_list renders ax-field-list class (semantic dl)
    assert html =~ "ax-field-list"
    # Projection section heading should be present
    assert html =~ Copy.coupon_detail_section_projection_heading()
  end

  test "promotion codes section rendered in Detail.detail_section wrapper", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}")

    # The codes section heading must appear inside an ax-detail-section
    # Both ax-detail-section and the codes heading must be present
    assert html =~ "ax-detail-section"
    assert html =~ Copy.coupon_detail_section_codes_heading()
    # The promotion code link must still be present (content preserved)
    assert html =~ "ANNUAL15"
  end

  test "promotion code drilldown links preserve active organization scope", %{
    conn: conn,
    coupon: coupon
  } do
    promotion_code = TestRepo.get_by!(PromotionCode, coupon_id: coupon.id)

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}?org=allowed-org")

    assert html =~
             ~s(href="/billing/promotion-codes/#{promotion_code.id}?org=allowed-org")

    assert html =~ ~s(href="/billing?org=allowed-org")
    assert html =~ ~s(href="/billing/coupons?org=allowed-org")
  end

  test "lazy activity expands to quiet empty state when no coupon activity exists", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/coupons/#{coupon.id}")
    assert html =~ "Open this section to load activity."

    refute html =~
             "This record has no recorded activity yet. Core details remain available above."

    html = render_click(view, "load_activity", %{})

    assert html =~ "No activity yet"

    assert html =~
             "This record has no recorded activity yet. Core details remain available above."
  end

  test "raw coupon payload renders only after the lazy raw data event", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/coupons/#{coupon.id}")
    refute html =~ "remote"

    html = render_click(view, "load_raw_json", %{})

    assert html =~ Copy.coupon_json_payload_label()
    assert html =~ "remote"
    assert html =~ "coupon_annual"
  end

  test "redirects with flash when coupon id is not found", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    nonexistent_id = Ecto.UUID.generate()
    result = live(conn, "/billing/coupons/#{nonexistent_id}")

    # Should redirect (not render)
    assert {:error, {:redirect, redirect_info}} = result
    assert redirect_info.to =~ "/billing/coupons"
    # Flash must carry a not-found error message
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
