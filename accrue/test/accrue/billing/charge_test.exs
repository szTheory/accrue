defmodule Accrue.Billing.ChargeTest do
  @moduledoc """
  Plan 06 Task 1: `Accrue.Billing.charge/3` — dual-API with SCA tagged
  return, `:payment_method` / default resolution, balance_transaction fee
  projection, and deterministic idempotency via operation_id.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Customer, PaymentMethod}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_charge_test",
        email: "charge-test@example.com"
      })
      |> Repo.insert()

    {:ok, pm} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "pm_fake_00001",
        type: "card",
        fingerprint: "fp_charge_default",
        card_brand: "visa",
        card_last4: "4242"
      })
      |> Repo.insert()

    %{customer: customer, pm: pm}
  end

  test "charge/3 with explicit :payment_method succeeds and returns {:ok, %Charge{}}", %{
    customer: cus
  } do
    assert {:ok, %Charge{} = charge} =
             Billing.charge(cus, Accrue.Money.new(1000, :usd), payment_method: "pm_fake_00001")

    assert charge.customer_id == cus.id
    assert charge.amount_cents == 1000
    assert charge.currency == "usd"
    assert charge.processor == "fake"
    assert is_binary(charge.processor_id)
  end

  test "charge/3 with customer default_payment_method_id set succeeds", %{
    customer: cus,
    pm: pm
  } do
    {:ok, cus} =
      cus
      |> Customer.changeset(%{default_payment_method_id: pm.id})
      |> Repo.update()

    assert {:ok, %Charge{} = charge} = Billing.charge(cus, Accrue.Money.new(500, :usd))
    assert charge.amount_cents == 500
  end

  test "charge/3 with no PM and no default returns error tuple", %{customer: cus} do
    assert {:error, %Accrue.Error.NoDefaultPaymentMethod{customer_id: id}} =
             Billing.charge(cus, Accrue.Money.new(1000, :usd))

    assert id == cus.id
  end

  test "charge!/3 with no PM and no default raises", %{customer: cus} do
    assert_raise Accrue.Error.NoDefaultPaymentMethod, fn ->
      Billing.charge!(cus, Accrue.Money.new(1000, :usd))
    end
  end

  test "charge/3 with scripted 3DS response returns {:ok, :requires_action, pi}", %{
    customer: cus
  } do
    pi = %{
      id: "pi_fake_requires_action",
      object: "payment_intent",
      status: "requires_action",
      client_secret: "pi_fake_requires_action_secret",
      next_action: %{type: "use_stripe_sdk"},
      amount: 2000,
      currency: "usd"
    }

    Fake.scripted_response(:create_charge, {:ok, pi})

    assert {:ok, :requires_action, returned_pi} =
             Billing.charge(cus, Accrue.Money.new(2000, :usd), payment_method: "pm_fake_00001")

    assert (returned_pi[:status] || returned_pi["status"]) == "requires_action"
  end

  test "charge/3 populates stripe_fee_amount_minor from balance_transaction.fee", %{
    customer: cus
  } do
    assert {:ok, %Charge{} = charge} =
             Billing.charge(cus, Accrue.Money.new(10_000, :usd),
               payment_method: "pm_fake_00001"
             )

    # Fake.build_charge returns fee: 30
    assert charge.stripe_fee_amount_minor == 30
    assert charge.stripe_fee_currency == "usd"
    assert %DateTime{} = charge.fees_settled_at
  end

  test "charge/3 with deterministic operation_id uses same idempotency key on retry", %{
    customer: cus
  } do
    op_id = "test-op-" <> Ecto.UUID.generate()

    assert {:ok, %Charge{} = c1} =
             Billing.charge(cus, Accrue.Money.new(1000, :usd),
               payment_method: "pm_fake_00001",
               operation_id: op_id
             )

    assert {:ok, %Charge{} = c2} =
             Billing.charge(cus, Accrue.Money.new(1000, :usd),
               payment_method: "pm_fake_00001",
               operation_id: op_id
             )

    # Idempotency subject_uuid is deterministic on operation_id: same id.
    assert c1.id == c2.id
  end

  test "charge/3 emits charge.succeeded event row", %{customer: cus} do
    {:ok, %Charge{id: charge_id}} =
      Billing.charge(cus, Accrue.Money.new(1000, :usd), payment_method: "pm_fake_00001")

    count =
      Repo.aggregate(
        from(e in "accrue_events",
          where: e.subject_id == ^charge_id and e.type == "charge.succeeded"
        ),
        :count
      )

    assert count >= 1
  end
end
