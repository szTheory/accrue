defmodule Accrue.Jobs.MeteredRenewalReconciler do
  @moduledoc """
  Narrow scheduled backstop for stale Braintree renewal windows.

  Scans active Braintree subscriptions whose `current_period_end` is past a
  grace window and which still have no local metered-renewal anchor for that
  closed period. Each stale row is repaired by reusing
  `Accrue.Billing.MeteredRenewalActions.open_braintree_renewal_window/4`
  instead of inventing a scheduler-only billing path.
  """

  use Oban.Worker, queue: :accrue_meters, max_attempts: 3

  import Ecto.Query

  alias Accrue.Billing.{MeteredRenewal, MeteredRenewalActions, Subscription}
  alias Accrue.Clock
  alias Accrue.Repo
  alias Accrue.Telemetry.Ops

  @limit 1_000
  @grace_seconds 60
  @active_statuses [:active, :trialing, :past_due, :unpaid]

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    _ = Accrue.Oban.Middleware.put(job)
    {:ok, _count} = reconcile()
    :ok
  end

  @spec reconcile() :: {:ok, non_neg_integer()}
  def reconcile do
    cutoff = DateTime.add(Clock.utc_now(), -@grace_seconds, :second)

    repaired_count =
      cutoff
      |> stale_subscriptions()
      |> Enum.reduce(0, fn subscription, count ->
        case MeteredRenewalActions.open_braintree_renewal_window(
               subscription.processor_id,
               nil,
               nil,
               "scheduled_reconciler"
             ) do
          {:ok, %MeteredRenewal{} = renewal} ->
            Ops.emit(:metered_renewal_stale_repaired, %{count: 1}, %{
              source: :reconciler,
              processor: renewal.processor,
              subscription_id: renewal.subscription_id,
              metered_renewal_id: renewal.id
            })

            count + 1

          {:ok, :ignored} ->
            count

          {:error, _reason} ->
            count
        end
      end)

    {:ok, repaired_count}
  end

  defp stale_subscriptions(cutoff) do
    from(subscription in Subscription,
      left_join: renewal in MeteredRenewal,
      on:
        renewal.subscription_id == subscription.id and
          renewal.period_start == subscription.current_period_start and
          renewal.period_end == subscription.current_period_end,
      where:
        subscription.processor == "braintree" and
          subscription.status in ^@active_statuses and
          not is_nil(subscription.current_period_end) and
          subscription.current_period_end < ^cutoff and
          is_nil(renewal.id),
      order_by: [asc: subscription.current_period_end],
      limit: @limit
    )
    |> Repo.all()
  end
end
