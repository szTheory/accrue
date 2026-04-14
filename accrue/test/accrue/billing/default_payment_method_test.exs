defmodule Accrue.Billing.DefaultPaymentMethodTest do
  @moduledoc """
  Plan 06 Task 2: `set_default_payment_method/2` strict attachment check
  (BILL-25).
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, PaymentMethod}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_default_test",
        email: "default@example.com"
      })
      |> Repo.insert()

    {:ok, pm} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "pm_fake_default_owned",
        type: "card",
        fingerprint: "fp_default_owned",
        card_brand: "visa",
        card_last4: "4242"
      })
      |> Repo.insert()

    # Seed a Fake customer so set_default_payment_method in the Fake can
    # find the record by processor_id.
    {:ok, _} =
      Fake.create_customer(%{
        email: customer.email,
        name: nil,
        metadata: %{}
      })

    %{customer: customer, pm: pm}
  end

  test "set_default_payment_method with attached PM succeeds and updates customer row", %{
    customer: cus,
    pm: pm
  } do
    # Fake state has its own customer key; script the set_default response.
    Fake.scripted_response(:set_default_payment_method, {:ok, %{id: cus.processor_id}})

    assert {:ok, %Customer{} = updated} = Billing.set_default_payment_method(cus, pm)
    assert updated.default_payment_method_id == pm.id
  end

  test "set_default_payment_method with unattached PM raises NotAttached", %{customer: cus} do
    # Build a PM for a DIFFERENT customer
    {:ok, other_cus} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_other",
        email: "other@example.com"
      })
      |> Repo.insert()

    {:ok, foreign_pm} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: other_cus.id,
        processor: "fake",
        processor_id: "pm_fake_foreign",
        type: "card",
        fingerprint: "fp_foreign",
        card_brand: "visa",
        card_last4: "1111"
      })
      |> Repo.insert()

    assert_raise Accrue.Error.NotAttached, fn ->
      Billing.set_default_payment_method(cus, foreign_pm)
    end
  end

  test "charge/3 uses customer.default_payment_method after set_default", %{
    customer: cus,
    pm: pm
  } do
    Fake.scripted_response(:set_default_payment_method, {:ok, %{id: cus.processor_id}})
    {:ok, cus} = Billing.set_default_payment_method(cus, pm)

    assert {:ok, %Accrue.Billing.Charge{}} =
             Billing.charge(cus, Accrue.Money.new(1000, :usd))
  end
end
