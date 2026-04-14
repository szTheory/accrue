defmodule Accrue.Jobs.ReconcileRefundFeesTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Refund
  alias Accrue.Jobs.ReconcileRefundFees

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_recon_refund",
        email: "recon-refund@example.com"
      })
      |> Repo.insert()

    {:ok, charge} =
      %Charge{customer_id: customer.id, processor: "fake"}
      |> Charge.changeset(%{
        processor_id: "ch_recon_refund_1",
        amount_cents: 10_000,
        currency: "usd",
        status: "succeeded"
      })
      |> Repo.insert()

    %{customer: customer, charge: charge}
  end

  test "sweeps unsettled refunds older than 24h and settles fees", %{charge: charge} do
    # Seed Fake with a charge that has nested balance_transaction with fee + fee_refunded
    {:ok, _stripe_ch} =
      Fake.create_charge(%{amount: 10_000, currency: "usd", customer: "cus_recon_refund"}, [])

    {:ok, stripe_refund} = Fake.create_refund(%{charge: "ch_recon_refund_1", amount: 10_000}, [])

    # Patch the Fake's retrieve_refund to return fee + fee_refunded via scripted_response
    :ok =
      Fake.scripted_response(
        :retrieve_refund,
        {:ok,
         %{
           id: stripe_refund.id,
           object: "refund",
           status: :succeeded,
           amount: 10_000,
           currency: "usd",
           charge: %{
             id: "ch_recon_refund_1",
             balance_transaction: %{fee: 320, fee_refunded: 250}
           }
         }}
      )

    past = DateTime.add(Accrue.Clock.utc_now(), -2 * 86_400, :second)

    {:ok, refund} =
      %Refund{charge_id: charge.id}
      |> Refund.changeset(%{
        stripe_id: stripe_refund.id,
        amount_minor: 10_000,
        currency: "usd",
        status: :succeeded
      })
      |> Repo.insert()

    # Backdate inserted_at so the 24h cutoff includes this row.
    import Ecto.Query
    Repo.one(from r in Refund, where: r.id == ^refund.id)

    Accrue.TestRepo.update_all(
      from(r in Refund, where: r.id == ^refund.id),
      set: [inserted_at: past]
    )

    :ok = ReconcileRefundFees.sweep()

    reloaded = Repo.one!(from r in Refund, where: r.id == ^refund.id)
    assert reloaded.stripe_fee_refunded_amount_minor == 250
    assert reloaded.merchant_loss_amount_minor == 70
    assert reloaded.fees_settled_at
  end

  test "does NOT sweep rows younger than 24h", %{charge: charge} do
    {:ok, refund} =
      %Refund{charge_id: charge.id}
      |> Refund.changeset(%{
        stripe_id: "re_fresh_nosweep",
        amount_minor: 5_000,
        currency: "usd",
        status: :succeeded
      })
      |> Repo.insert()

    :ok = ReconcileRefundFees.sweep()

    import Ecto.Query
    reloaded = Repo.one!(from r in Refund, where: r.id == ^refund.id)
    refute reloaded.fees_settled_at
  end
end
