defmodule Accrue.Jobs.DetectExpiringCards do
  @moduledoc """
  Scheduled Oban worker for expiring-card detection (D3-71..78, BILL-24).

  Scans `accrue_payment_methods` with non-nil `exp_month` / `exp_year`,
  computes days-until-expiry (end of expiry month), and emits a
  `card.expiring_soon` event + telemetry for each PM whose remaining
  days matches one of the configured thresholds.

  Thresholds come from `Accrue.Config.get!(:expiring_card_thresholds)`
  (default `[30, 7, 1]`).

  ## Dedup via accrue_events

  To prevent re-emission on subsequent sweeps, the worker queries
  `accrue_events` for any `card.expiring_soon` event with matching
  `(subject_id, data.threshold)` within the last 365 days. The 1-year
  window covers the typical card lifecycle without leaving a stale
  dedup entry forever.

  No new column is added to `accrue_payment_methods` for dedup — the
  event ledger IS the dedup source of truth (D3-14, EVT-04).
  """

  use Oban.Worker, queue: :accrue_scheduled, max_attempts: 3

  import Ecto.Query

  alias Accrue.{Clock, Config, Events, Repo}
  alias Accrue.Billing.{Customer, PaymentMethod}

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Accrue.Oban.Middleware.put(job)
    scan()
  end

  def perform(_other), do: scan()

  @doc false
  def scan do
    thresholds = Config.get!(:expiring_card_thresholds)
    now = Clock.utc_now()

    query =
      from p in PaymentMethod,
        where: not is_nil(p.exp_month) and not is_nil(p.exp_year)

    pms = Repo.all(query)

    for pm <- pms, threshold <- thresholds do
      maybe_emit(pm, threshold, now)
    end

    :ok
  end

  defp maybe_emit(%PaymentMethod{} = pm, threshold, now) do
    expiry_dt = end_of_month(pm.exp_year, pm.exp_month)
    days_until = DateTime.diff(expiry_dt, now, :second) |> div(86_400)

    if days_until == threshold and not already_warned?(pm.id, threshold) do
      is_default_pm =
        Repo.one(
          from c in Customer,
            where: c.default_payment_method_id == ^pm.id,
            select: count(c.id)
        ) > 0

      _ =
        Events.record(%{
          type: "card.expiring_soon",
          subject_type: "PaymentMethod",
          subject_id: pm.id,
          data: %{
            threshold: threshold,
            days_until_expiry: days_until,
            is_default_pm: is_default_pm
          }
        })

      :telemetry.execute(
        [:accrue, :billing, :payment_method, :expiring_soon],
        %{days_until: days_until},
        %{payment_method_id: pm.id, threshold: threshold, is_default_pm: is_default_pm}
      )
    end
  end

  defp already_warned?(pm_id, threshold) do
    one_year_ago = DateTime.add(Clock.utc_now(), -365 * 86_400, :second)

    query =
      from e in "accrue_events",
        where:
          e.subject_id == ^pm_id and
            e.type == "card.expiring_soon" and
            fragment("(?->>'threshold')::int = ?", e.data, ^threshold) and
            e.inserted_at > ^one_year_ago,
        select: count()

    Repo.one(query) > 0
  end

  defp end_of_month(year, month) do
    days = :calendar.last_day_of_the_month(year, month)
    {:ok, dt} = DateTime.new(Date.new!(year, month, days), Time.new!(23, 59, 59))
    dt
  end
end
