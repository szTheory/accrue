defmodule Accrue.Jobs.DunningSweeper do
  @moduledoc """
  Oban cron worker for the dunning grace-period overlay.

  Stripe Smart Retries owns the retry cadence. Accrue owns a thin
  grace-period overlay on top: once `past_due_since` is older than the
  configured `grace_days`, this worker asks the processor facade to
  move the subscription to the terminal action (`:unpaid` or
  `:canceled`) and stamps `dunning_sweep_attempted_at` on success.

  ## How status updates work

  This worker NEVER flips the local `subscription.status`. It only:

    * Calls `Accrue.Processor.update_subscription/3` to ask the
      processor facade to transition the row.
    * Stamps `dunning_sweep_attempted_at` AFTER a successful processor
      call so the same row is not retried on the next tick.
    * Records a `dunning.terminal_action_requested` audit event in
      `accrue_events`.

  The actual local status flip happens when Stripe echoes the change
  back via `customer.subscription.updated`, which the
  `Accrue.Webhook.DefaultHandler` picks up and projects.

  ## Host wiring

  Accrue does not start its own Oban instance. The host app must wire
  the cron themselves:

      config :my_app, Oban,
        queues: [accrue_dunning: 2],
        plugins: [
          {Oban.Plugins.Cron,
           crontab: [{"*/15 * * * *", Accrue.Jobs.DunningSweeper}]}
        ]

  ## Failure handling

  A processor error on any row logs a warning and returns `false`
  WITHOUT stamping `dunning_sweep_attempted_at`, so the next cron tick
  picks the same row up again. `max_attempts: 3` on the worker bounds
  per-tick retries.
  """

  use Oban.Worker, queue: :accrue_dunning, max_attempts: 3

  require Logger

  alias Accrue.{Config, Events, Processor, Repo}
  alias Accrue.Billing.{Dunning, Query, Subscription}

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Accrue.Oban.Middleware.put(job)
    sweep()
  end

  @doc """
  Runs one sweep tick. Returns `{:ok, count}` where `count` is the
  number of subscriptions successfully transitioned this tick.
  """
  @spec sweep() :: {:ok, non_neg_integer()}
  def sweep do
    policy = Config.dunning()

    case Keyword.get(policy, :mode) do
      :disabled ->
        {:ok, 0}

      _ ->
        grace_days = Keyword.fetch!(policy, :grace_days)

        candidates =
          grace_days
          |> Query.dunning_sweep_candidates()
          |> Repo.all()

        count =
          Enum.reduce(candidates, 0, fn %Subscription{} = sub, acc ->
            case Dunning.compute_terminal_action(sub, policy) do
              {:sweep, terminal} ->
                if sweep_one(sub, terminal), do: acc + 1, else: acc

              _ ->
                acc
            end
          end)

        {:ok, count}
    end
  end

  defp sweep_one(%Subscription{} = sub, terminal_action) do
    stripe_params = %{status: Atom.to_string(terminal_action)}

    case Processor.__impl__().update_subscription(sub.processor_id, stripe_params, []) do
      {:ok, _stripe_sub} ->
        # Stamp attempt AFTER successful processor call. Does NOT flip
        # local status — the webhook from Stripe does that.
        now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}

        {:ok, _updated} =
          sub
          |> Ecto.Changeset.change(%{dunning_sweep_attempted_at: now_usec})
          |> Repo.update()

        {:ok, _event} =
          Events.record(%{
            type: "dunning.terminal_action_requested",
            subject_type: "Subscription",
            subject_id: sub.id,
            data: %{
              terminal_action: Atom.to_string(terminal_action),
              mode: "accrue_sweeper"
            }
          })

        true

      {:error, err} ->
        Logger.warning(
          "DunningSweeper: processor error for sub #{sub.id} " <>
            "(processor_id=#{sub.processor_id}): #{inspect(err)}"
        )

        false
    end
  end
end
