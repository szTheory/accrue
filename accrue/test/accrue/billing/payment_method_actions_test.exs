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

  test "list_payment_methods/2 returns the local projection", %{customer: customer} do
    assert {:ok, []} = Billing.list_payment_methods(customer, [])
  end

  test "list_payment_methods!/2 returns the local projection", %{customer: customer} do
    assert [] = Billing.list_payment_methods!(customer, [])
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
