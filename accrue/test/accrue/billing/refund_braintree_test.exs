defmodule Accrue.Billing.RefundBraintreeTest do
  @moduledoc """
  Plan 099 Task 1: Hermetic coverage for canonical `refund/2` facade,
  additive `create_refund/2` compatibility, and Braintree adapter integration.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Customer, Refund}

  defmodule TransactionGatewayStub do
    def find(id, _opts) do
      if id == "ch_bt_unsettled" do
        {:ok, %{status: "authorized", id: id}}
      else
        {:ok, %{status: "settled", id: id}}
      end
    end

    def refund(id, amount, _opts \\ []) do
      if amount == "invalid" do
        {:error, %Elixir.Braintree.ErrorResponse{message: "Amount is invalid"}}
      else
        {:ok,
         %{
           id: "ref_bt_scripted_#{amount}",
           type: "credit",
           status: "submitted_for_settlement",
           amount: amount || "100.00",
           currency_iso_code: "USD",
           refunded_transaction_id: id
         }}
      end
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_transaction = Application.get_env(:accrue, :braintree_transaction_gateway)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_transaction_gateway, TransactionGatewayStub)

    on_exit(fn ->
      if previous_processor do
        Application.put_env(:accrue, :processor, previous_processor)
      else
        Application.delete_env(:accrue, :processor)
      end

      if previous_transaction do
        Application.put_env(:accrue, :braintree_transaction_gateway, previous_transaction)
      else
        Application.delete_env(:accrue, :braintree_transaction_gateway)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_bt_refund_test",
        email: "refund@example.com"
      })
      |> Repo.insert()

    {:ok, charge} =
      %Charge{}
      |> Charge.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "ch_bt_refund_src",
        amount_cents: 10_000,
        currency: "usd",
        status: "succeeded"
      })
      |> Repo.insert()

    %{customer: customer, charge: charge}
  end

  test "Billing.refund/2 returns uniform {:ok, refund} for a Braintree charge", %{charge: charge} do
    assert {:ok, %Refund{} = refund} = Billing.refund(charge, operation_id: "op_1")
    assert refund.charge_id == charge.id
    assert refund.amount_minor == 10_000
    assert refund.processor_id == "ref_bt_scripted_100.00"
  end

  test "create_refund/2 acts as an additive compatibility alias", %{charge: charge} do
    assert {:ok, %Refund{} = refund} = Billing.create_refund(charge, operation_id: "op_2")
    assert refund.charge_id == charge.id
    assert refund.amount_minor == 10_000
    assert refund.processor_id == "ref_bt_scripted_100.00"
  end

  test "repeated partial refunds create distinct refund rows tied to one parent charge", %{charge: charge} do
    assert {:ok, %Refund{} = r1} =
             Billing.refund(charge, amount: Accrue.Money.new(4000, :usd), operation_id: "op_3")

    assert r1.amount_minor == 4000
    assert r1.processor_id == "ref_bt_scripted_40.00"

    assert {:ok, %Refund{} = r2} =
             Billing.refund(charge, amount: Accrue.Money.new(2000, :usd), operation_id: "op_4")

    assert r2.amount_minor == 2000
    assert r2.processor_id == "ref_bt_scripted_20.00"

    # Because both use the stub, they might get the same processor_id right now in test,
    # but they are inserted as distinct rows. Let's just assert counts.
    count = Repo.aggregate(from(r in Refund, where: r.charge_id == ^charge.id), :count)
    assert count == 2
  end

  test "fails with explicit pre-settlement / invalid inputs APIError", %{charge: charge} do
    unsettled_charge = %{charge | processor_id: "ch_bt_unsettled"}

    assert {:error, %Accrue.APIError{code: "invalid_request_error", message: msg}} =
             Billing.refund(unsettled_charge)

    assert msg =~ "settling or settled"
  end
end
