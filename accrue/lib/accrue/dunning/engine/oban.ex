defmodule Accrue.Dunning.Engine.Oban do
  @moduledoc """
  Built-in dunning engine backed by Oban (DUN-03, D-02).

  This is the always-on default engine. No additional configuration is
  required — it wraps the existing Oban-backed `Accrue.Workers.DunningStep`
  worker. It is the value `Accrue.Config.dunning_engine/0` returns when no
  explicit engine is configured.

  ## Responsibilities

  - `start_campaign/3` — enqueues the day-0 `DunningStep` job for the
    configured `after_days: 0` step (or no-ops when none is configured).
  - `cancel_campaign/3` — bulk-cancels all `DunningStep` jobs keyed on
    `subscription_id` + `campaign_started_at`. Always returns `:ok` even on
    failure (the anchor-clear is already committed; the per-step cancel-guard
    backstops any step that races this cancel — D-12 contract).

  ## Isolation

  This module only references always-on dependencies (`Oban`,
  `Accrue.Workers.DunningStep`, `Accrue.Config`) and compiles and loads
  unconditionally, whether or not the optional `:chimeway` dependency is
  present. No Chimeway references appear here.
  """

  @behaviour Accrue.Dunning.Engine

  import Ecto.Query, only: [from: 2]

  require Logger

  alias Accrue.Billing.Subscription
  alias Accrue.Workers.DunningStep

  @impl Accrue.Dunning.Engine
  @doc """
  Enqueues the day-0 `DunningStep` job for the configured `after_days: 0`
  step, threading the campaign anchor and `invoice_id` from `opts`.

  Returns `:ok` immediately when no day-0 step is configured (the first
  cadence step has `after_days > 0`). The `DunningStep` `unique` contract
  (D-16) backstops the atomic campaign-start elector against duplicate
  enqueues.

  Note: `emit_campaign_started/1` (telemetry + ledger) is NOT called here —
  it is Accrue's responsibility and is called in `default_handler.ex` BEFORE
  this dispatch (RESEARCH Pitfall 3).
  """
  def start_campaign(%Subscription{} = sub, %DateTime{} = anchor, opts) do
    case day_zero_step_key() do
      nil ->
        :ok

      step_key ->
        case DunningStep.enqueue_step(sub.id, step_key, anchor, %{
               customer_id: sub.customer_id,
               invoice_id: Keyword.get(opts, :invoice_id)
             }) do
          {:ok, _job} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @impl Accrue.Dunning.Engine
  @doc """
  Bulk-cancels all `Accrue.Workers.DunningStep` Oban jobs matching
  `sub.id` + `iso_anchor`.

  Always returns `:ok` — a cancel failure is logged as a warning but never
  propagated (D-12). The anchor-clear is already committed at the time this
  is called; the per-step cancel-guard backstops any job that races this
  bulk cancel.
  """
  def cancel_campaign(%Subscription{} = sub, iso_anchor, _opts) when is_binary(iso_anchor) do
    from(j in Oban.Job,
      where: j.worker == "Accrue.Workers.DunningStep",
      where: fragment("? ->> 'subscription_id' = ?", j.args, ^sub.id),
      where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor)
    )
    |> Oban.cancel_all_jobs()

    :ok
  rescue
    e ->
      # The anchor-clear already committed; the per-step cancel-guard
      # (D-11) backstops any step we failed to cancel. Log the failure
      # without undoing the committed recovery (no new telemetry/ledger —
      # that family is Phase 129).
      Logger.warning("dunning cancel-on-recovery bulk cancel failed: #{inspect(e)}")
      :ok
  end

  # The day-0 step is the configured step at `after_days: 0`.
  # Mirrors the private helper formerly in default_handler.ex; only calls
  # `Accrue.Config.dunning_campaign_steps()` (always-on).
  defp day_zero_step_key do
    Enum.find_value(Accrue.Config.dunning_campaign_steps(), fn step ->
      if Keyword.get(step, :after_days) == 0, do: Keyword.get(step, :key)
    end)
  end
end
