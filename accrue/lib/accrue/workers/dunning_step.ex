defmodule Accrue.Workers.DunningStep do
  @moduledoc """
  Durable, cancel-guarded, Oban-unique dunning-campaign step worker
  (DUN-02, DUN-05; D-10, D-11, D-16).

  This is the self-propelling scheduling engine for the built-in dunning
  campaign. The webhook reducer (Plan 06) enqueues the day-0 step; from
  there each `perform/1` delivers one step's email, asks the pure
  `Accrue.Dunning.Campaign` resolver what comes next, and enqueues the
  following step — threading the SAME `campaign_started_at` anchor so the
  entire chain shares one campaign identity.

  ## Cancel-guard FIRST (D-11)

  Every `perform/1` reloads the live subscription row BEFORE delivering
  anything. If the sub is no longer past_due, or its campaign anchor is
  `nil`, the step returns `{:cancel, :recovered}` and delivers NOTHING.
  This is the backstop for any job that races the Plan-06 proactive
  `Oban.cancel_all_jobs` (cancel-on-recovery) or arrives after an
  out-of-order recovery webhook — a recovered customer is never emailed.

  ## Once-per-step uniqueness (D-16)

  Each step is keyed `[:subscription_id, :step_key, :campaign_started_at]`
  with `period: :infinity` and `:completed` included in the unique
  `states`. A duplicate enqueue returns `{:ok, %Oban.Job{conflict?: true}}`
  — a step can NEVER be enqueued twice across retries, redeliveries, or
  duplicate webhooks. `period: :infinity` (not the finite window the
  metered precedent uses) is required because Stripe Smart Retries span
  weeks; a completed prior step must still block a week-2 redelivery.

  ## Oban-safe scalar args (D-10)

  Oban persists job `args` as JSONB, so `campaign_started_at` is carried as
  an ISO8601 STRING (never a `%DateTime{}` struct) and parsed back with
  `DateTime.from_iso8601/1`. The string is NEVER atomized (no
  string-to-atom conversion of any kind) — that would be an atom-table
  exhaustion vector on DB-sourced input. All wall-clock reads use
  `Accrue.Clock.utc_now/0` for Fake-lane determinism (Phase 130).

  ## Scope fence

  Phase 128 is the engine + correctness only. This worker emits NO ledger
  events and NO telemetry (DUN-08, Phase 129) and does NOT introduce the
  `Accrue.Dunning.Engine` behaviour (DUN-03, Phase 131) — step resolution
  is a direct call to the pure resolver, keeping the future engine seam
  clean.

  ## Host wiring

  Accrue does not start its own Oban instance. The host wires the queue
  (shared with the sweeper):

      config :my_app, Oban, queues: [accrue_dunning: 2]
  """

  use Oban.Worker, queue: :accrue_dunning, max_attempts: 3

  alias Accrue.Billing.Subscription
  alias Accrue.Dunning.Campaign
  alias Accrue.{Config, Mailer, Repo}

  @doc """
  Delivers one dunning step and chains the next.

  1. Cancel-guard FIRST: reload the row; `{:cancel, :recovered}` (deliver
     nothing) when not past_due OR the campaign anchor is `nil`.
  2. Deliver the current step's email exactly once (outside any
     transaction).
  3. Resolve the next step via the pure resolver and enqueue it with the
     SAME anchor; enqueue nothing when the journey is exhausted.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = job) do
    Accrue.Oban.Middleware.put(job)

    %{
      "subscription_id" => subscription_id,
      "step_key" => step_key_str,
      "campaign_started_at" => anchor_iso
    } = args

    {:ok, anchor, _offset} = DateTime.from_iso8601(anchor_iso)

    case Repo.get(Subscription, subscription_id) do
      %Subscription{} = sub ->
        if campaign_active?(sub) do
          deliver_step(sub, step_key_str, anchor, args)
          chain_next(subscription_id, step_key_str, anchor, args)
          {:ok, :delivered}
        else
          # D-11 cancel-guard backstop: recovered (or anchor cleared) —
          # deliver nothing, non-retryable.
          {:cancel, :recovered}
        end

      nil ->
        # Subscription gone (deleted) — nothing to dun.
        {:cancel, :recovered}
    end
  end

  @doc """
  Enqueues a dunning step for delivery, threading the campaign anchor.

  Used by both this worker's internal chaining and the Plan-06 webhook
  reducer that seeds the day-0 step. The D-16 `unique` keyword keys the job
  on `[:subscription_id, :step_key, :campaign_started_at]` so the SAME step
  can never be enqueued twice (returns `{:ok, %Oban.Job{conflict?: true}}`
  on a duplicate).

  `campaign_started_at` is coerced to an ISO8601 string so the args stay
  Oban-JSON-safe. `extra` carries scalar reference IDs only (`:customer_id`,
  `:invoice_id`) — no structs, no PII.
  """
  @spec enqueue_step(binary(), atom(), DateTime.t(), map()) ::
          {:ok, Oban.Job.t()} | {:error, term()}
  def enqueue_step(subscription_id, step_key, %DateTime{} = campaign_started_at, extra \\ %{})
      when is_binary(subscription_id) and is_atom(step_key) and is_map(extra) do
    %{
      "subscription_id" => subscription_id,
      "step_key" => Atom.to_string(step_key),
      "campaign_started_at" => maybe_iso8601(campaign_started_at),
      "customer_id" => Map.get(extra, :customer_id) || Map.get(extra, "customer_id"),
      "invoice_id" => Map.get(extra, :invoice_id) || Map.get(extra, "invoice_id")
    }
    |> new(unique: unique_opts())
    |> Oban.insert()
  end

  # D-16 unique keyword. `period: :infinity` + `:completed` in states
  # because Stripe Smart Retries span weeks; the keys shape clones the
  # metered precedent verbatim but with the infinite window (NOT the finite
  # 60-second window the metered precedent uses).
  defp unique_opts do
    [
      fields: [:worker, :args],
      keys: [:subscription_id, :step_key, :campaign_started_at],
      period: :infinity,
      states: [:available, :scheduled, :executing, :retryable, :completed]
    ]
  end

  # Live-state cancel-guard (CR-02): a campaign is active iff the sub is
  # STRICTLY `:past_due` AND has a non-nil campaign anchor. `:unpaid` is the
  # dunning-terminal state — a sub that has reached it (via the Accrue sweeper
  # or Stripe-native termination) must NOT be dunned further, so we mirror
  # `Subscription.dunning_sweepable?/1` (`:past_due` only) rather than
  # `past_due?/1` (which ALSO matches `:unpaid`). This is the backstop the
  # design leans on: any in-flight step that races a terminal transition
  # self-cancels here instead of emailing a terminated customer.
  defp campaign_active?(%Subscription{} = sub) do
    Subscription.dunning_sweepable?(sub) and Subscription.dunning_campaign_active?(sub)
  end

  # Deliver the current step's email exactly once. Kept OUTSIDE any
  # transaction (never call the email adapter inside Repo.transact). The
  # email TYPE atom is derived from the step key; assigns carry scalar
  # reference IDs only (D-17).
  defp deliver_step(%Subscription{} = sub, step_key_str, anchor, args) do
    assigns = %{
      subscription_id: sub.id,
      step_key: step_key_str,
      campaign_started_at: maybe_iso8601(anchor),
      customer_id: Map.get(args, "customer_id"),
      invoice_id: Map.get(args, "invoice_id")
    }

    Mailer.deliver(email_type(step_key_str), assigns)
  end

  # Resolve the next step from the pure resolver and enqueue it with the
  # SAME anchor; enqueue nothing when the journey is exhausted.
  #
  # The resolver returns the first step whose absolute boundary is `>=`
  # elapsed. To ADVANCE past the step just delivered (rather than re-resolve
  # to it — the `>=` boundary keeps an at-boundary step pending, which is the
  # day-0 immediate-send semantics, but would otherwise re-enqueue the
  # current step), we ask the resolver for `now` positioned ONE SECOND past
  # the current step's boundary. That makes the just-delivered step strictly
  # behind `elapsed` (skipped) and yields the next step in the journey, with
  # `schedule_in` correctly measured from the campaign anchor. This keeps
  # step-resolution a direct call to the pure resolver (no behaviour) and is
  # deterministic under the Fake clock (Phase 130) since it derives `now`
  # from the anchor + the configured offset, not from wall-clock drift.
  defp chain_next(subscription_id, step_key_str, anchor, args) do
    steps = Config.dunning_campaign_steps()
    advanced_now = advance_past_current(steps, step_key_str, anchor)

    case Campaign.next_step(steps, anchor, advanced_now) do
      {:next, step, schedule_in} ->
        next_key = Keyword.fetch!(step, :key)
        extra = %{customer_id: Map.get(args, "customer_id"), invoice_id: Map.get(args, "invoice_id")}
        enqueue_step(subscription_id, next_key, anchor, extra, schedule_in)

      :done ->
        :ok
    end
  end

  # `now` positioned one second past the current step's absolute boundary, so
  # the resolver advances to the NEXT step. Falls back to the live clock when
  # the current step is unknown (defensive; the configured list is the SSOT).
  defp advance_past_current(steps, step_key_str, anchor) do
    case find_after_days(steps, step_key_str) do
      nil -> %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
      after_days -> DateTime.add(anchor, after_days * 86_400 + 1, :second)
    end
  end

  defp find_after_days(steps, step_key_str) do
    Enum.find_value(steps, fn step ->
      if Atom.to_string(Keyword.fetch!(step, :key)) == step_key_str do
        Keyword.fetch!(step, :after_days)
      end
    end)
  end

  # Chained enqueue with a delay (the resolver's non-negative schedule_in).
  defp enqueue_step(subscription_id, step_key, %DateTime{} = anchor, extra, schedule_in) do
    %{
      "subscription_id" => subscription_id,
      "step_key" => Atom.to_string(step_key),
      "campaign_started_at" => maybe_iso8601(anchor),
      "customer_id" => Map.get(extra, :customer_id),
      "invoice_id" => Map.get(extra, :invoice_id)
    }
    |> new(schedule_in: schedule_in, unique: unique_opts())
    |> Oban.insert()
  end

  # Map the campaign step key (config-level identity) to the mailer email
  # TYPE atom that resolves the template in `Accrue.Workers.Mailer`. Step-1
  # reuses the existing `:invoice_payment_failed` email.
  defp email_type("reminder"), do: :invoice_payment_failed
  defp email_type("action_required"), do: :dunning_action_required
  defp email_type("final_notice"), do: :dunning_final_notice

  # ISO8601 scalar coercion for Oban args (only_scalars!-safe).
  defp maybe_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp maybe_iso8601(_), do: nil
end
