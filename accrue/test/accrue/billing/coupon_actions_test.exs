defmodule Accrue.Billing.CouponActionsTest do
  @moduledoc """
  Phase 4 Plan 05 (BILL-27/28) — coupon + promotion-code create flow
  plus `apply_promotion_code/2` validation branches.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Coupon, PromotionCode}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_promo"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "create_coupon/2" do
    test "creates a Coupon row via the Fake adapter and records an event" do
      assert {:ok, %Coupon{} = coupon} =
               Billing.create_coupon(%{
                 id: "accrue_comp_100_forever",
                 percent_off: 100,
                 duration: "forever"
               })

      assert coupon.processor_id == "accrue_comp_100_forever"
      assert coupon.duration == "forever"
      assert Decimal.equal?(coupon.percent_off, Decimal.new(100))
      assert coupon.processor == "fake"

      assert Repo.one!(
               from(e in Accrue.Events.Event,
                 where: e.type == "coupon.created" and e.subject_id == ^coupon.id
               )
             )
    end

    test "generates a deterministic id when none is supplied" do
      assert {:ok, %Coupon{processor_id: pid}} =
               Billing.create_coupon(%{percent_off: 25, duration: "once"})

      assert is_binary(pid)
      assert String.starts_with?(pid, "coupon_fake_")
    end
  end

  describe "create_promotion_code/2" do
    test "creates a PromotionCode row FK'd to an existing Coupon" do
      {:ok, coupon} =
        Billing.create_coupon(%{
          id: "accrue_save10",
          percent_off: 10,
          duration: "once"
        })

      assert {:ok, %PromotionCode{} = promo} =
               Billing.create_promotion_code(%{
                 coupon: coupon.processor_id,
                 code: "SAVE10"
               })

      assert promo.code == "SAVE10"
      assert promo.coupon_id == coupon.id
      assert promo.active == true

      assert Repo.one!(
               from(e in Accrue.Events.Event,
                 where: e.type == "promotion_code.created" and e.subject_id == ^promo.id
               )
             )
    end

    test "unique constraint on code rejects duplicate insertions" do
      {:ok, _coupon} =
        Billing.create_coupon(%{id: "accrue_dup", percent_off: 5, duration: "once"})

      assert {:ok, _} =
               Billing.create_promotion_code(%{coupon: "accrue_dup", code: "DUP"})

      # Seed a second promotion code row with the SAME code directly via
      # the schema changeset — bypasses the action's idempotency cache
      # (which would otherwise return the first result unchanged on
      # identical operation_id + subject).
      cs =
        PromotionCode.changeset(%PromotionCode{}, %{
          processor: "fake",
          processor_id: "promo_fake_handmade",
          code: "DUP"
        })

      assert {:error, %Ecto.Changeset{errors: errors}} = Repo.insert(cs)
      assert Keyword.has_key?(errors, :code)
    end
  end

  describe "apply_promotion_code/2" do
    setup %{customer: customer} do
      {:ok, coupon} =
        Billing.create_coupon(%{
          id: "accrue_apply_test",
          percent_off: 50,
          duration: "once"
        })

      {:ok, promo} =
        Billing.create_promotion_code(%{coupon: coupon.processor_id, code: "VIP"})

      {:ok, sub} =
        %Subscription{}
        |> Subscription.force_status_changeset(%{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "sub_fake_apply_01",
          status: :active
        })
        |> Repo.insert()

      # Seed the Fake so update_subscription resolves.
      Accrue.Processor.Fake.stub(:update_subscription, fn id, _params, _opts ->
        {:ok, %{id: id, object: "subscription", status: :active}}
      end)

      %{coupon: coupon, promo: promo, sub: sub}
    end

    test "happy path — attaches coupon and records coupon.applied event",
         %{sub: sub, coupon: coupon} do
      assert {:ok, %Subscription{}} = Billing.apply_promotion_code(sub, "VIP")

      assert event =
               Repo.one!(
                 from(e in Accrue.Events.Event,
                   where: e.type == "coupon.applied" and e.subject_id == ^sub.id
                 )
               )

      assert event.data["coupon_processor_id"] == coupon.processor_id ||
               event.data[:coupon_processor_id] == coupon.processor_id

      assert event.data["promotion_code"] == "VIP" ||
               event.data[:promotion_code] == "VIP"
    end

    test "unknown code returns :not_found", %{sub: sub} do
      assert {:error, :not_found} = Billing.apply_promotion_code(sub, "NOPE")
    end

    test "inactive promotion code returns :inactive", %{sub: sub, promo: promo} do
      {:ok, _} =
        promo
        |> PromotionCode.force_status_changeset(%{active: false})
        |> Repo.update()

      assert {:error, :inactive} = Billing.apply_promotion_code(sub, "VIP")
    end

    test "expired promotion code returns :expired", %{sub: sub, promo: promo} do
      past =
        Accrue.Clock.utc_now()
        |> DateTime.add(-86_400, :second)
        |> Map.put(:microsecond, {0, 6})

      {:ok, _} =
        promo
        |> PromotionCode.force_status_changeset(%{expires_at: past})
        |> Repo.update()

      assert {:error, :expired} = Billing.apply_promotion_code(sub, "VIP")
    end

    test "exhausted redemptions returns :max_redemptions_reached",
         %{sub: sub, promo: promo} do
      {:ok, _} =
        promo
        |> PromotionCode.force_status_changeset(%{max_redemptions: 3, times_redeemed: 3})
        |> Repo.update()

      assert {:error, :max_redemptions_reached} = Billing.apply_promotion_code(sub, "VIP")
    end
  end
end
