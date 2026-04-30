defmodule Accrue.Billing.PaymentMethodActionsTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  setup do
    previous = Application.get_env(:accrue, :processor)
    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_pm_guard",
        email: "pm-guard@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "list_payment_methods/2 returns the unsupported-operation tuple", %{customer: customer} do
    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
             Billing.list_payment_methods(customer, [])

    assert error.message =~ "does not support payment-method listing"
  end

  test "list_payment_methods!/2 raises the same unsupported-operation error", %{customer: customer} do
    assert_raise Accrue.APIError, ~r/does not support payment-method listing/, fn ->
      Billing.list_payment_methods!(customer, [])
    end
  end

  test "canonical payment-method CRUD verbs are exported from Accrue.Billing" do
    exports = Accrue.Billing.module_info(:exports)

    assert {:add_payment_method, 3} in exports
    assert {:add_payment_method!, 3} in exports
    assert {:update_payment_method, 3} in exports
    assert {:update_payment_method!, 3} in exports
    assert {:delete_payment_method, 2} in exports
    assert {:delete_payment_method!, 2} in exports
    assert {:sync_payment_methods, 2} in exports
    assert {:sync_payment_methods!, 2} in exports
  end
end
