defmodule AccrueAdmin.CouponLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Coupon, PromotionCode}
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
    assert html =~ "Codes linked to this coupon"
    assert html =~ "ANNUAL15"
    assert html =~ "/billing/promotion-codes/"
    assert html =~ "channel"
    assert html =~ "remote"
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
