defmodule Accrue.Billing.PaymentMethodListTest do
  @moduledoc """
  Phase 98 keeps `list_payment_methods/2` as a local-row-first read model.
  """
  # Async false: global `Accrue.Processor.Fake` + `ConnectCase`'s full
  # `Fake.reset/0` can interleave with `BillingCase`'s `reset_preserve_connect/0`
  # and wipe in-flight payment method state across test modules.
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  setup do
    {:ok, %{id: processor_id}} =
      Fake.create_customer(
        %{email: "list-pm@example.com", name: nil, metadata: %{}},
        []
      )

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: processor_id,
        email: "list-pm@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "list_payment_methods returns local payment-method rows without provider fetches", %{customer: cus} do
    {:ok, %{id: pm_id}} = Fake.create_payment_method(%{type: "card"}, [])

    assert {:ok, %PaymentMethod{} = attached} = Billing.attach_payment_method(cus, pm_id)
    assert {:ok, listed} = Billing.list_payment_methods(cus, [])
    assert Enum.map(listed, & &1.id) == [attached.id]
  end
end
