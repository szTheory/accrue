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

  test "renders coupon detail with linked promotion codes and payload", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}")

    assert html =~ "Annual discount"
    assert html =~ Copy.coupon_detail_section_codes_heading()
    assert html =~ "ANNUAL15"
    assert html =~ "/billing/promotion-codes/"
    assert html =~ "channel"
    assert html =~ "remote"
  end

  test "renders RelatedResources card with promotion codes and events links", %{
    conn: conn,
    coupon: coupon
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons/#{coupon.id}")

    # Related resources card must be present
    assert html =~ ~s(class="ax-card ax-related")
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
end
