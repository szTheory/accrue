defmodule Accrue.Billing.PaymentMethodListTest do
  @moduledoc """
  Phase 56 — `Accrue.Billing.list_payment_methods/2` happy path on Fake (BIL-01).
  """
  use Accrue.BillingCase, async: true

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

  test "list_payment_methods returns attached processor PM in data", %{customer: cus} do
    {:ok, %{id: pm_id}} = Fake.create_payment_method(%{type: "card"}, [])

    assert {:ok, %PaymentMethod{}} = Billing.attach_payment_method(cus, pm_id)

    assert {:ok, %{data: list}} = Billing.list_payment_methods(cus, [])
    assert is_list(list)
    assert length(list) >= 1
    assert Enum.any?(list, &(&1[:id] == pm_id))
  end
end
