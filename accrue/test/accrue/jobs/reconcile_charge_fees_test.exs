defmodule Accrue.Jobs.ReconcileChargeFeesTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Jobs.ReconcileChargeFees

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_recon_charge",
        email: "recon-charge@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "sweeps unsettled charges older than 24h", %{customer: customer} do
    :ok =
      Fake.scripted_response(
        :retrieve_charge,
        {:ok,
         %{
           id: "ch_recon_old",
           object: "charge",
           status: :succeeded,
           balance_transaction: %{fee: 320, currency: "usd"}
         }}
      )

    {:ok, charge} =
      %Charge{customer_id: customer.id, processor: "fake"}
      |> Charge.changeset(%{
        processor_id: "ch_recon_old",
        amount_cents: 10_000,
        currency: "usd",
        status: "succeeded"
      })
      |> Repo.insert()

    past = DateTime.add(Accrue.Clock.utc_now(), -2 * 86_400, :second)

    import Ecto.Query

    Accrue.TestRepo.update_all(
      from(c in Charge, where: c.id == ^charge.id),
      set: [inserted_at: past]
    )

    :ok = ReconcileChargeFees.sweep()

    reloaded = Repo.one!(from c in Charge, where: c.id == ^charge.id)
    assert reloaded.stripe_fee_amount_minor == 320
    assert reloaded.fees_settled_at
  end

  test "does NOT sweep rows younger than 24h", %{customer: customer} do
    {:ok, charge} =
      %Charge{customer_id: customer.id, processor: "fake"}
      |> Charge.changeset(%{
        processor_id: "ch_recon_fresh",
        amount_cents: 10_000,
        currency: "usd",
        status: "succeeded"
      })
      |> Repo.insert()

    :ok = ReconcileChargeFees.sweep()

    import Ecto.Query
    reloaded = Repo.one!(from c in Charge, where: c.id == ^charge.id)
    refute reloaded.fees_settled_at
  end
end
