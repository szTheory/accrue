defmodule Accrue.Billing.PaymentMethodListTest do
  @moduledoc """
  Phase 95 — `Accrue.Billing.list_payment_methods/2` now hard-fails as
  out-of-slice public surface instead of implying Stripe/Fake parity.
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

  test "list_payment_methods returns the unsupported-operation tuple", %{customer: cus} do
    {:ok, %{id: pm_id}} = Fake.create_payment_method(%{type: "card"}, [])

    assert {:ok, %PaymentMethod{}} = Billing.attach_payment_method(cus, pm_id)

    assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
             Billing.list_payment_methods(cus, [])

    assert error.message =~ "does not support payment-method listing"
  end
end
