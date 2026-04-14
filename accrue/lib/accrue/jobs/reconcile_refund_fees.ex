defmodule Accrue.Jobs.ReconcileRefundFees do
  @moduledoc """
  Daily backstop Oban worker for refund fees that weren't populated at
  create time (D3-46).

  ## Sweep window

  Selects `accrue_refunds` where `fees_settled_at IS NULL AND inserted_at
  < now() - 24h`. The 24h buffer gives Stripe's balance_transaction
  settlement time to populate before the reconciler tries to pull fees
  forward — earlier attempts would just re-fail with nil `fee_refunded`.

  ## Flow per row

    1. Refetch canonical via `Processor.retrieve_refund/2` with
       `expand: ["balance_transaction", "charge.balance_transaction"]`
    2. Extract `fee` / `fee_refunded` from `charge.balance_transaction`
    3. If both populated: update row with `stripe_fee_refunded_amount_minor`,
       `merchant_loss_amount_minor`, and `fees_settled_at = Clock.utc_now()`
    4. Emit `[:accrue, :billing, :refund, :fees_settled]` telemetry
    5. Record `refund.fees_settled` event

  Rows without populated fees are skipped silently — the next sweep
  will pick them up again.

  Schedule via Oban cron in the host app:

      config :my_app, Oban,
        plugins: [
          {Oban.Plugins.Cron,
           crontab: [
             {"@daily", Accrue.Jobs.ReconcileRefundFees}
           ]}
        ]
  """

  use Oban.Worker, queue: :accrue_reconcilers, max_attempts: 3

  import Ecto.Query

  alias Accrue.{Events, Processor, Repo}
  alias Accrue.Billing.Refund

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
      from r in Refund,
        where: is_nil(r.fees_settled_at) and r.inserted_at < ^cutoff

    query
    |> Repo.all()
    |> Enum.each(&reconcile/1)

    :ok
  end

  defp reconcile(%Refund{stripe_id: sid} = row) when is_binary(sid) do
    with {:ok, canonical} <-
           Processor.__impl__().retrieve_refund(sid,
             expand: ["balance_transaction", "charge.balance_transaction"]
           ),
         charge_bt <- extract_charge_balance_transaction(canonical),
         fee when is_integer(fee) <- Map.get(charge_bt, "fee") || Map.get(charge_bt, :fee),
         fr when is_integer(fr) <-
           Map.get(charge_bt, "fee_refunded") || Map.get(charge_bt, :fee_refunded) do
      attrs = %{
        stripe_fee_refunded_amount_minor: fr,
        # WR-03: clamp at 0 — fee_refunded can exceed fee in
        # fee-adjustment scenarios. BILL-26 requires non-negative.
        merchant_loss_amount_minor: max(0, fee - fr),
        fees_settled_at: Accrue.Clock.utc_now()
      }

      {:ok, updated} = row |> Refund.changeset(attrs) |> Repo.update()

      :telemetry.execute(
        [:accrue, :billing, :refund, :fees_settled],
        %{},
        %{refund_id: updated.id, source: :reconciler}
      )

      _ =
        Events.record(%{
          type: "refund.fees_settled",
          subject_type: "Refund",
          subject_id: updated.id,
          data: %{source: "reconciler"}
        })

      :ok
    else
      _ -> :skip
    end
  end

  defp reconcile(_), do: :skip

  defp extract_charge_balance_transaction(canonical) do
    case Map.get(canonical, "charge") || Map.get(canonical, :charge) do
      %{} = m -> Map.get(m, "balance_transaction") || Map.get(m, :balance_transaction) || %{}
      _ -> Map.get(canonical, "balance_transaction") || Map.get(canonical, :balance_transaction) || %{}
    end
  end
end
