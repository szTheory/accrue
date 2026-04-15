defmodule AccrueAdmin.CouponsLiveTest do
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
        name: "Spring 25",
        processor_id: "coupon_spring",
        percent_off: Decimal.new("25"),
        valid: true,
        times_redeemed: 4
      })

    _promotion_code =
      insert_promotion_code(coupon, %{
        code: "SPRING25",
        processor_id: "promo_spring",
        active: true
      })

    _other_coupon =
      insert_coupon(%{
        name: "Expired Deal",
        processor_id: "coupon_expired",
        valid: false
      })

    :ok
  end

  test "filters coupon rows and links to the dedicated promotion-code surface", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/coupons?q=Spring&valid=true")

    assert html =~ "Coupons backed by local discount projections"
    assert html =~ "Spring 25"
    assert html =~ "Promotion codes"
    assert html =~ "/billing/coupons/"
    assert html =~ "/billing/promotion-codes"
    refute html =~ "Expired Deal"
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
