defmodule AccrueAdmin.PromotionCodesLiveTest do
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

    assert html =~ "Promotion codes as a dedicated admin surface"
    assert html =~ "BUNDLE10"
    assert html =~ "Bundle coupon"
    assert html =~ "/billing/promotion-codes/"
    assert html =~ "/billing/coupons/"
    refute html =~ "BUNDLEOLD"
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
