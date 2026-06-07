defmodule Accrue.Telemetry.DiscountMappingInvalidTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Error.DiscountMappingInvalid

  @discount_mappings_table Accrue.Migration.qualified_table(:accrue_discount_mappings)

  setup do
    parent = self()
    handler_id = {__MODULE__, make_ref()}
    previous_processor = Application.get_env(:accrue, :processor)

    :telemetry.attach(
      handler_id,
      [:accrue, :ops, :discount_mapping_invalid],
      fn event, measurements, metadata, _ ->
        send(parent, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)

    on_exit(fn ->
      :telemetry.detach(handler_id)

      if previous_processor do
        Application.put_env(:accrue, :processor, previous_processor)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    :ok
  end

  test "drift emits one ops event with allowlisted metadata only" do
    customer = insert_braintree_customer!()
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, _} =
      Ecto.Adapters.SQL.query(
        Repo,
        """
        INSERT INTO #{@discount_mappings_table}
          (id, processor, code, discount_id, active, amount_off_minor, currency, metadata, data,
           lock_version, inserted_at, updated_at)
        VALUES
          ($1, 'braintree', 'DRIFTED', '', true, 500, 'USD', '{}'::jsonb, '{"gateway_response":"secret"}'::jsonb,
           1, $2, $2)
        """,
        [Ecto.UUID.generate() |> Ecto.UUID.dump!(), now]
      )

    assert {:error, %DiscountMappingInvalid{} = error} =
             Billing.subscribe(
               customer,
               "plan_premium",
               promotion_code: "DRIFTED",
               payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
             )

    assert_received {:telemetry, [:accrue, :ops, :discount_mapping_invalid], %{count: 1},
                     metadata}

    assert metadata.mapping_id == error.mapping_id
    assert metadata.code == "DRIFTED"
    assert metadata.discount_id == ""
    assert is_binary(metadata.operation_id)
    refute Map.has_key?(metadata, :processor_error)
    refute Map.has_key?(metadata, :gateway_response)
    refute Map.has_key?(metadata, :data)
  end

  defp insert_braintree_customer! do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_braintree_test_#{System.unique_integer([:positive])}",
        email: "bt-#{System.unique_integer([:positive])}@example.com"
      })
      |> Repo.insert()

    customer
  end
end
