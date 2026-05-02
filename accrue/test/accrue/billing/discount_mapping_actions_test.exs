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

    test "updates the existing row for the normalized code instead of inserting a duplicate" do
      assert {:ok, %DiscountMapping{} = first} =
               Billing.upsert_discount_mapping("save10", %{
                 discount_id: "bt_discount_10",
                 amount_off_minor: 500,
                 currency: "USD"
               })

      assert {:ok, %DiscountMapping{} = second} =
               Billing.upsert_discount_mapping(" SAVE10 ", %{
                 discount_id: "bt_discount_10b",
                 amount_off_minor: 650,
                 currency: "USD",
                 max_redemptions: 5
               })

      assert first.id == second.id
      assert second.code == "SAVE10"
      assert second.discount_id == "bt_discount_10b"
      assert second.amount_off_minor == 650
      assert second.max_redemptions == 5
      assert Repo.aggregate(DiscountMapping, :count) == 1
    end
  end

  describe "resolve_discount_mapping/3" do
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
      assert preview.amount_off_minor == 750
      assert preview.estimated_total_minor == 1_250

      refute_received :coupon_create_called
      refute_received :promotion_code_create_called
    end

    test "returns :not_found before any processor call for an unknown code" do
      Fake.stub(:coupon_create, fn _params, _opts ->
        send(self(), :coupon_create_called)
        {:ok, %{}}
      end)

      assert {:error, :not_found} = Billing.resolve_discount_mapping("missing", 2_000)
      refute_received :coupon_create_called
    end

    test "returns :inactive for inactive mappings" do
      assert {:ok, _mapping} =
               Billing.upsert_discount_mapping("OFF", %{
                 discount_id: "bt_discount_off",
                 amount_off_minor: 300,
                 currency: "USD",
                 active: false
               })

      assert {:error, :inactive} = Billing.resolve_discount_mapping("OFF", 2_000)
    end

    test "returns :expired for expired mappings" do
      past =
        Accrue.Clock.utc_now()
        |> DateTime.add(-86_400, :second)
        |> DateTime.truncate(:second)

      assert {:ok, _mapping} =
               Billing.upsert_discount_mapping("OLD", %{
                 discount_id: "bt_discount_old",
                 amount_off_minor: 300,
                 currency: "USD",
                 expires_at: past
               })

      assert {:error, :expired} = Billing.resolve_discount_mapping("OLD", 2_000)
    end

    test "returns :max_redemptions_reached before any processor call" do
      assert {:ok, _mapping} =
               Billing.upsert_discount_mapping("CAPPED", %{
                 discount_id: "bt_discount_capped",
                 amount_off_minor: 300,
                 currency: "USD",
                 max_redemptions: 2,
                 times_redeemed: 2
               })

      assert {:error, :max_redemptions_reached} =
               Billing.resolve_discount_mapping("CAPPED", 2_000)
    end

    test "caps savings at the checkout total and returns preview economics" do
      assert {:ok, %DiscountMapping{} = mapping} =
               Billing.upsert_discount_mapping("BIGSAVE", %{
                 discount_id: "bt_discount_big",
                 amount_off_minor: 5_000,
                 currency: "USD",
                 duration_in_billing_cycles: 3
               })

      assert {:ok, preview} = Billing.resolve_discount_mapping("BIGSAVE", 1_250)

      assert preview.mapping.id == mapping.id
      assert preview.mapping.duration_in_billing_cycles == 3
      assert preview.amount_off_minor == 1_250
      assert preview.estimated_total_minor == 0
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

  describe "record_discount_mapping_redemption/2" do
    test "increments times_redeemed for a successful mapping" do
      assert {:ok, %DiscountMapping{} = mapping} =
               Billing.upsert_discount_mapping("USEME", %{
                 discount_id: "bt_discount_useme",
                 amount_off_minor: 400,
                 currency: "USD",
                 max_redemptions: 3,
                 times_redeemed: 1
               })

      assert {:ok, %DiscountMapping{} = redeemed} =
               Accrue.Billing.DiscountMappingActions.record_discount_mapping_redemption(mapping)

      assert redeemed.times_redeemed == 2

      assert {:ok, %DiscountMapping{} = fetched} = Billing.get_discount_mapping("USEME")
      assert fetched.times_redeemed == 2
    end

    test "returns :max_redemptions_reached once the cap is exhausted" do
      assert {:ok, %DiscountMapping{} = mapping} =
               Billing.upsert_discount_mapping("LASTONE", %{
                 discount_id: "bt_discount_last",
                 amount_off_minor: 400,
                 currency: "USD",
                 max_redemptions: 1,
                 times_redeemed: 0
               })

      assert {:ok, %DiscountMapping{times_redeemed: 1}} =
               Accrue.Billing.DiscountMappingActions.record_discount_mapping_redemption(mapping)

      assert {:error, :max_redemptions_reached} =
               Accrue.Billing.DiscountMappingActions.record_discount_mapping_redemption(mapping)
    end
  end
end
