defmodule Accrue.Billing.RefundTest do
  @moduledoc """
  Plan 06 Task 3: `create_refund/2` with sync best-effort fee math
  (BILL-26, D3-45..47). Uniform `{:ok, %Refund{}}` return; fee columns
  populated when `charge.balance_transaction.fee_refunded` is present;
  `fees_settled?/1` predicate reflects the settlement timestamp.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Customer, Refund}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_refund_test",
        email: "refund@example.com"
      })
      |> Repo.insert()

    {:ok, charge} =
      %Charge{}
      |> Charge.changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "ch_fake_refund_src",
        amount_cents: 10_000,
        currency: "usd",
        status: "succeeded",
        stripe_fee_amount_minor: 320,
        stripe_fee_currency: "usd"
      })
      |> Repo.insert()

    %{customer: customer, charge: charge}
  end

  defp scripted_refund(charge_id, bt) do
    %{
      id: "re_fake_scripted",
      object: "refund",
      amount: 10_000,
      currency: "usd",
      status: "succeeded",
      charge: %{
        id: charge_id,
        object: "charge",
        balance_transaction: bt
      }
    }
  end

  test "create_refund populates merchant_loss_amount when fee_refunded is present", %{
    charge: charge
  } do
    Fake.scripted_response(
      :create_refund,
      {:ok,
       scripted_refund(charge.processor_id, %{
         id: "txn_fake",
         fee: 320,
         fee_refunded: 310,
         net: -9680
       })}
    )

    assert {:ok, %Refund{} = refund} = Billing.create_refund(charge)
    assert refund.charge_id == charge.id
    assert refund.amount_minor == 10_000
    assert refund.stripe_fee_refunded_amount_minor == 310
    assert refund.merchant_loss_amount_minor == 10
    assert %DateTime{} = refund.fees_settled_at
    assert Refund.fees_settled?(refund)
  end

  test "create_refund with nil fee_refunded leaves fees unsettled", %{charge: charge} do
    Fake.scripted_response(
      :create_refund,
      {:ok,
       scripted_refund(charge.processor_id, %{
         id: "txn_fake",
         fee: 320,
         fee_refunded: nil
       })}
    )

    assert {:ok, %Refund{} = refund} = Billing.create_refund(charge)
    assert refund.stripe_fee_refunded_amount_minor == nil
    assert refund.merchant_loss_amount_minor == nil
    assert refund.fees_settled_at == nil
    refute Refund.fees_settled?(refund)
  end

  test "create_refund partial amount via :amount option", %{charge: charge} do
    Fake.scripted_response(
      :create_refund,
      {:ok,
       %{
         id: "re_fake_partial",
         object: "refund",
         amount: 5000,
         currency: "usd",
         status: "succeeded",
         charge: %{id: charge.processor_id}
       }}
    )

    assert {:ok, %Refund{} = refund} =
             Billing.create_refund(charge, amount: Accrue.Money.new(5000, :usd))

    assert refund.amount_minor == 5000
  end

  test "create_refund emits refund.created event", %{charge: charge} do
    Fake.scripted_response(
      :create_refund,
      {:ok,
       %{
         id: "re_fake_evt",
         object: "refund",
         amount: 10_000,
         currency: "usd",
         status: "succeeded",
         charge: %{id: charge.processor_id}
       }}
    )

    {:ok, refund} = Billing.create_refund(charge)

    count =
      Repo.aggregate(
        from(e in "accrue_events",
          where: e.subject_id == ^refund.id and e.type == "refund.created"
        ),
        :count
      )

    assert count >= 1
  end

  test "create_refund returns uniform {:ok, refund} — no tagged variant", %{charge: charge} do
    Fake.scripted_response(
      :create_refund,
      {:ok,
       %{
         id: "re_fake_shape",
         object: "refund",
         amount: 10_000,
         currency: "usd",
         status: "succeeded",
         charge: %{id: charge.processor_id}
       }}
    )

    result = Billing.create_refund(charge)
    assert match?({:ok, %Refund{}}, result)
    refute match?({:ok, :pending_fees, _}, result)
    refute match?({:ok, :requires_action, _}, result)
  end
end
