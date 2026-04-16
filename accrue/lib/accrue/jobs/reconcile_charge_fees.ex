defmodule Accrue.Jobs.ReconcileChargeFees do
  @moduledoc """
  Daily backstop Oban worker for charge fees that weren't populated at
  create time (D3-46).

  Mirrors `Accrue.Jobs.ReconcileRefundFees` but sweeps `accrue_charges`
  where `fees_settled_at IS NULL AND inserted_at < now() - 24h`.
  Refetches canonical via `Processor.retrieve_charge/2` with
  `expand: ["balance_transaction"]`, and when `balance_transaction.fee`
  is populated updates the row's `stripe_fee_amount_minor` and
  `fees_settled_at`.
  """

  use Oban.Worker, queue: :accrue_reconcilers, max_attempts: 3

  import Ecto.Query

  alias Accrue.{Events, Processor, Repo}
  alias Accrue.Billing.Charge

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Accrue.Oban.Middleware.put(job)
    sweep()
  end

  def perform(_other), do: sweep()

  @doc false
  def sweep do
    cutoff = DateTime.add(Accrue.Clock.utc_now(), -86_400, :second)

    query =
      from(c in Charge,
        where: is_nil(c.fees_settled_at) and c.inserted_at < ^cutoff
      )

    query
    |> Repo.all()
    |> Enum.each(&reconcile/1)

    :ok
  end

  defp reconcile(%Charge{processor_id: sid} = row) when is_binary(sid) do
    with {:ok, canonical} <-
           Processor.__impl__().retrieve_charge(sid, expand: ["balance_transaction"]),
         bt <-
           Map.get(canonical, "balance_transaction") || Map.get(canonical, :balance_transaction) ||
             %{},
         fee when is_integer(fee) <- Map.get(bt, "fee") || Map.get(bt, :fee) do
      currency = Map.get(bt, "currency") || Map.get(bt, :currency) || "usd"

      attrs = %{
        stripe_fee_amount_minor: fee,
        stripe_fee_currency: currency,
        fees_settled_at: Accrue.Clock.utc_now()
      }

      {:ok, updated} = row |> Charge.changeset(attrs) |> Repo.update()

      :telemetry.execute(
        [:accrue, :billing, :charge, :fees_settled],
        %{},
        %{charge_id: updated.id, source: :reconciler}
      )

      _ =
        Events.record(%{
          type: "charge.fees_settled",
          subject_type: "Charge",
          subject_id: updated.id,
          data: %{source: "reconciler"}
        })

      :ok
    else
      _ -> :skip
    end
  end

  defp reconcile(_), do: :skip
end
