defmodule Accrue.Billing.PromotionCodeTest do
  @moduledoc """
  Phase 4 Plan 05 (BILL-27) — PromotionCode schema + projection unit
  tests. Integration with `Accrue.Billing.CouponActions` is exercised
  in `coupon_actions_test.exs`; this file pins the schema-level
  contract (required fields, unique constraints, projection shape).
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{PromotionCode, PromotionCodeProjection}

  describe "changeset/2" do
    test "requires processor, processor_id, code" do
      cs = PromotionCode.changeset(%PromotionCode{}, %{})
      refute cs.valid?

      assert %{processor_id: _, code: _} = errors_on(cs)
    end

    test "valid with minimum required fields" do
      cs =
        PromotionCode.changeset(%PromotionCode{}, %{
          processor: "fake",
          processor_id: "promo_fake_x",
          code: "HELLO"
        })

      assert cs.valid?
    end

    test "rejects duplicate processor_id via DB unique constraint" do
      {:ok, _} =
        %PromotionCode{}
        |> PromotionCode.changeset(%{
          processor: "fake",
          processor_id: "promo_fake_dup_pid",
          code: "CODE1"
        })
        |> Repo.insert()

      {:error, %Ecto.Changeset{errors: errors}} =
        %PromotionCode{}
        |> PromotionCode.changeset(%{
          processor: "fake",
          processor_id: "promo_fake_dup_pid",
          code: "CODE2"
        })
        |> Repo.insert()

      assert Keyword.has_key?(errors, :processor_id)
    end

    test "rejects duplicate code via DB unique constraint" do
      {:ok, _} =
        %PromotionCode{}
        |> PromotionCode.changeset(%{
          processor: "fake",
          processor_id: "promo_fake_a",
          code: "SAMECODE"
        })
        |> Repo.insert()

      {:error, %Ecto.Changeset{errors: errors}} =
        %PromotionCode{}
        |> PromotionCode.changeset(%{
          processor: "fake",
          processor_id: "promo_fake_b",
          code: "SAMECODE"
        })
        |> Repo.insert()

      assert Keyword.has_key?(errors, :code)
    end
  end

  describe "force_status_changeset/2" do
    test "skips required-field validation (webhook-path)" do
      cs =
        PromotionCode.force_status_changeset(%PromotionCode{}, %{active: false})

      assert cs.valid?
    end
  end

  describe "projection.decompose/1" do
    test "extracts processor_id, code, active, max_redemptions, coupon ref" do
      stripe_promo =
        StripeFixtures.promotion_code_created(%{"code" => "VIP", "max_redemptions" => 100})

      assert {:ok, attrs, coupon_processor_id} =
               PromotionCodeProjection.decompose(stripe_promo)

      assert attrs.processor_id == stripe_promo["id"]
      assert attrs.code == "VIP"
      assert attrs.active == true
      assert attrs.max_redemptions == 100
      assert is_binary(coupon_processor_id)
      assert is_map(attrs.data)
    end

    test "handles nil / missing expires_at gracefully" do
      {:ok, attrs, _} =
        StripeFixtures.promotion_code_created(%{"expires_at" => nil})
        |> PromotionCodeProjection.decompose()

      assert attrs.expires_at == nil
    end

    test "converts unix expires_at to DateTime" do
      unix = DateTime.to_unix(DateTime.utc_now())

      {:ok, attrs, _} =
        StripeFixtures.promotion_code_created(%{"expires_at" => unix})
        |> PromotionCodeProjection.decompose()

      assert %DateTime{} = attrs.expires_at
    end
  end

  defp errors_on(cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _whole, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
