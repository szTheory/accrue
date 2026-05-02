defmodule Accrue.Billing.DiscountMappingActionsTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.DiscountMapping
  alias Accrue.Error.DiscountMappingInvalid
  alias Accrue.Processor.Fake

  describe "upsert_discount_mapping/2" do
    test "stores one canonical braintree code to discount mapping row" do
      assert {:ok, %DiscountMapping{} = mapping} =
               Billing.upsert_discount_mapping("SAVE10", %{
                 discount_id: "bt_discount_10",
                 amount_off_minor: 500,
                 currency: "USD",
                 max_redemptions: 10
               })

      assert mapping.processor == "braintree"
      assert mapping.code == "SAVE10"
      assert mapping.discount_id == "bt_discount_10"
      assert mapping.amount_off_minor == 500
      assert mapping.currency == "USD"
      assert mapping.max_redemptions == 10
    end
  end

  describe "get_discount_mapping/2 and resolve_discount_mapping/3" do
    test "stay local and do not route through processor coupon or promotion code writes" do
      Fake.stub(:coupon_create, fn _params, _opts ->
        send(self(), :coupon_create_called)
        {:ok, %{}}
      end)

      Fake.stub(:promotion_code_create, fn _params, _opts ->
        send(self(), :promotion_code_create_called)
        {:ok, %{}}
      end)

      assert {:ok, %DiscountMapping{} = mapping} =
               Billing.upsert_discount_mapping("SAVE20", %{
                 discount_id: "bt_discount_20",
                 amount_off_minor: 750,
                 currency: "USD"
               })

      mapping_id = mapping.id

      assert {:ok, %DiscountMapping{id: ^mapping_id}} =
               Billing.get_discount_mapping("SAVE20")

      assert {:ok, preview} = Billing.resolve_discount_mapping("SAVE20", 2_000)
      assert %DiscountMapping{id: ^mapping_id} = preview.mapping

      refute_received :coupon_create_called
      refute_received :promotion_code_create_called
    end

    test "returns a typed drift failure for invalid stored economics" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, _} =
        Ecto.Adapters.SQL.query(
          Repo,
          """
          INSERT INTO accrue_discount_mappings
            (id, processor, code, discount_id, active, amount_off_minor, currency, metadata, data,
             lock_version, inserted_at, updated_at)
          VALUES
            ($1, 'braintree', 'BROKEN', 'bt_discount_broken', true, -500, 'USD', '{}'::jsonb, '{}'::jsonb,
             1, $2, $2)
          """,
          [Ecto.UUID.generate() |> Ecto.UUID.dump!(), now]
        )

      assert {:error, %DiscountMappingInvalid{} = error} =
               Billing.resolve_discount_mapping("BROKEN", 2_000)

      assert error.code == "BROKEN"
      assert error.discount_id == "bt_discount_broken"
    end
  end
end
