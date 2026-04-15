defmodule AccrueAdmin.PromotionCodeLiveTest do
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
        name: "Referral coupon",
        processor_id: "coupon_referral"
      })

    promotion_code =
      insert_promotion_code(coupon, %{
        code: "REFER15",
        processor_id: "promo_referral",
        active: true,
        metadata: %{"campaign" => "referrals"},
        data: %{"processor" => "stripe"}
      })

    {:ok, promotion_code: promotion_code}
  end

  test "renders promotion code detail with a parent coupon link", %{
    conn: conn,
    promotion_code: promotion_code
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/promotion-codes/#{promotion_code.id}")

    assert html =~ "REFER15"
    assert html =~ "Navigate back to the discount definition"
    assert html =~ "Referral coupon"
    assert html =~ "/billing/coupons/"
    assert html =~ "campaign"
    assert html =~ "processor"
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
