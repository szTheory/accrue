defmodule Accrue.Workers.DunningStepTest do
  @moduledoc """
  Phase 128 Plan 05 — `Accrue.Workers.DunningStep` (DUN-02, DUN-05; D-10, D-11, D-16).

  Proves the durable, cancel-guarded, Oban-unique step worker:

    * Cancel-guard FIRST — a sub that is no longer past_due OR has a nil
      campaign anchor returns `{:cancel, :recovered}` and delivers NOTHING
      (D-11 backstop for cancel-on-recovery races / out-of-order webhooks).
    * Happy path — an active campaign delivers the step's email exactly once
      (via `Accrue.Mailer.deliver/2`, captured by `Accrue.Mailer.Test`) then
      enqueues the NEXT step with the SAME `campaign_started_at` ISO8601 anchor
      (single campaign identity threaded through the chain — D-10).
    * Terminal — when the resolver returns `:done` (journey exhausted), the
      worker enqueues NOTHING (the final step is the last email).
    * Duplicate enqueue — re-enqueuing the same
      `[subscription_id, step_key, campaign_started_at]` returns
      `{:ok, %Oban.Job{conflict?: true}}` — a step can NEVER be enqueued twice
      across retries / redeliveries / duplicate webhooks (D-16 unique).
    * `campaign_started_at` round-trips as an ISO8601 STRING (Oban args are
      JSON; parsed via `DateTime.from_iso8601/1`, never atomized).

  Uses the env-default `Accrue.Mailer.Test` capture adapter, which sends
  `{:accrue_email_delivered, type, assigns}` to the calling pid — so "delivered
  once" is provable without standing up the Mailglass/Swoosh lanes.
  """
  use Accrue.BillingCase, async: false

  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Workers.DunningStep

  @anchor ~U[2026-05-01 00:00:00.000000Z]

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_dunning_step",
        email: "dunning-step@example.test"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  # Seeds a subscription row directly (no Fake processor round-trip needed —
  # the step worker never calls the processor; it reloads local state for the
  # cancel-guard and delivers an email).
  defp seed_sub(customer, attrs) do
    row_attrs =
      attrs
      |> Map.put_new(:status, :past_due)
      |> Map.put_new(:processor_id, "sub_" <> Ecto.UUID.generate())

    {:ok, sub} =
      %Subscription{customer_id: customer.id, processor: "fake"}
      |> Subscription.force_status_changeset(row_attrs)
      |> Repo.insert()

    sub
  end

  defp args(sub, step_key, campaign_started_at, customer) do
    %{
      "subscription_id" => sub.id,
      "step_key" => Atom.to_string(step_key),
      "campaign_started_at" => DateTime.to_iso8601(campaign_started_at),
      "customer_id" => customer.id,
      "invoice_id" => "in_step_test"
    }
  end

  defp attach_telemetry(name, event) do
    test_pid = self()

    :ok =
      :telemetry.attach(
        name,
        event,
        fn evt, meas, meta, _ -> send(test_pid, {:telemetry, evt, meas, meta}) end,
        nil
      )

    ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(name) end)
  end

  defp ledger_events(type, subject_id) do
    Repo.all(
      from(e in LedgerEvent,
        where:
          e.type == ^type and e.subject_type == "Subscription" and
            e.subject_id == ^subject_id
      )
    )
  end

  describe "cancel-guard FIRST (D-11)" do
    test "a recovered (not past_due) sub returns {:cancel, :recovered} and delivers nothing",
         %{customer: cus} do
      sub = seed_sub(cus, %{status: :active, dunning_campaign_started_at: @anchor})

      assert {:cancel, :recovered} =
               perform_job(DunningStep, args(sub, :reminder, @anchor, cus))

      refute_received {:accrue_email_delivered, _type, _assigns}
      assert [] = all_enqueued(worker: DunningStep)
    end

    test "a nil campaign anchor returns {:cancel, :recovered} and delivers nothing",
         %{customer: cus} do
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: nil})

      assert {:cancel, :recovered} =
               perform_job(DunningStep, args(sub, :reminder, @anchor, cus))

      refute_received {:accrue_email_delivered, _type, _assigns}
      assert [] = all_enqueued(worker: DunningStep)
    end

    # CR-02: an `:unpaid` sub has reached the dunning-TERMINAL state. Even with
    # a still-set anchor (e.g. a terminal transition that raced an in-flight
    # step), the cancel-guard must treat it as NOT live and deliver nothing —
    # the guard now mirrors `dunning_sweepable?/1` (`:past_due` only) rather
    # than `past_due?/1` (which also matches `:unpaid`).
    test "a terminal :unpaid sub with a live anchor returns {:cancel, :recovered}",
         %{customer: cus} do
      sub = seed_sub(cus, %{status: :unpaid, dunning_campaign_started_at: @anchor})

      assert {:cancel, :recovered} =
               perform_job(DunningStep, args(sub, :final_notice, @anchor, cus))

      refute_received {:accrue_email_delivered, _type, _assigns}
      assert [] = all_enqueued(worker: DunningStep)
    end
  end

  describe "happy-path chain (D-10)" do
    test "delivers the step email exactly once and enqueues the next step with the same anchor",
         %{customer: cus} do
      # Anchor = now: at elapsed 0, the resolver's first pending step is day-0
      # :reminder, so after delivering it the worker enqueues the next step
      # (:action_required at day 5) with schedule_in 5 days, same anchor.
      now = Accrue.Clock.utc_now()
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: now})

      assert {:ok, _} = perform_job(DunningStep, args(sub, :reminder, now, cus))

      # Delivered the reminder step's email exactly once.
      assert_received {:accrue_email_delivered, :invoice_payment_failed, delivered_assigns}
      assert delivered_assigns[:step_key] == "reminder"
      refute_received {:accrue_email_delivered, _t, _a}

      # Enqueued exactly one next step, threading the SAME anchor verbatim.
      assert [%Oban.Job{} = next] = all_enqueued(worker: DunningStep)
      assert next.args["campaign_started_at"] == DateTime.to_iso8601(now)
      # The next step is the day-5 :action_required step.
      assert next.args["step_key"] == "action_required"
    end

    test "delivers the action_required step and chains the final_notice step",
         %{customer: cus} do
      now = Accrue.Clock.utc_now()
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: now})

      assert {:ok, _} = perform_job(DunningStep, args(sub, :action_required, now, cus))

      assert_received {:accrue_email_delivered, :dunning_action_required, _assigns}

      assert [%Oban.Job{} = next] = all_enqueued(worker: DunningStep)
      assert next.args["step_key"] == "final_notice"
      assert next.args["campaign_started_at"] == DateTime.to_iso8601(now)
    end
  end

  describe "terminal step (journey exhausted)" do
    test "the final step delivers but enqueues nothing", %{customer: cus} do
      now = Accrue.Clock.utc_now()
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: now})

      assert {:ok, _} = perform_job(DunningStep, args(sub, :final_notice, now, cus))

      assert_received {:accrue_email_delivered, :dunning_final_notice, _assigns}
      # No further step — the journey is exhausted after final_notice.
      assert [] = all_enqueued(worker: DunningStep)
    end
  end

  describe "WR-02: step no longer in live cadence ends the journey (no wall-clock re-resolve)" do
    test "a delivered step whose key was removed from the live config enqueues nothing",
         %{customer: cus} do
      # Host edits the cadence mid-flight so it no longer contains the step
      # being delivered. Previously the chain fell back to the wall clock and
      # could re-resolve to a DIFFERENT step (a double-send vector); now it
      # treats "step no longer configured" as journey-exhausted.
      prior = Application.get_env(:accrue, :dunning, :__unset__)

      Application.put_env(:accrue, :dunning,
        mode: :stripe_smart_retries,
        grace_days: 14,
        terminal_action: :unpaid,
        campaign: [
          enabled: true,
          steps: [
            [after_days: 0, key: :reminder, template: Accrue.Emails.InvoicePaymentFailed]
          ]
        ]
      )

      on_exit(fn ->
        case prior do
          :__unset__ -> Application.delete_env(:accrue, :dunning)
          value -> Application.put_env(:accrue, :dunning, value)
        end
      end)

      now = Accrue.Clock.utc_now()
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: now})

      # `final_notice` is no longer in the live cadence (only `reminder` is).
      assert {:ok, _} = perform_job(DunningStep, args(sub, :final_notice, now, cus))

      # The step email still delivered (email_type/1 maps the key), but the
      # chain enqueues NOTHING — no wall-clock re-resolve to a different step.
      assert_received {:accrue_email_delivered, :dunning_final_notice, _assigns}
      assert [] = all_enqueued(worker: DunningStep)
    end
  end

  describe "duplicate enqueue is impossible (D-16 unique)" do
    test "re-enqueuing the same [subscription_id, step_key, campaign_started_at] conflicts",
         %{customer: cus} do
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: @anchor})

      assert {:ok, %Oban.Job{conflict?: false}} =
               DunningStep.enqueue_step(sub.id, :action_required, @anchor, %{
                 customer_id: cus.id,
                 invoice_id: "in_dup"
               })

      assert {:ok, %Oban.Job{conflict?: true}} =
               DunningStep.enqueue_step(sub.id, :action_required, @anchor, %{
                 customer_id: cus.id,
                 invoice_id: "in_dup"
               })

      assert [_only_one] =
               all_enqueued(worker: DunningStep)
               |> Enum.filter(&(&1.args["step_key"] == "action_required"))
    end
  end

  # --- DUN-08 observability: dunning.step_sent -----------------------

  describe "dunning.step_sent observability (DUN-08)" do
    test "a delivered step records a ledger event AND fires telemetry",
         %{customer: cus} do
      now = Accrue.Clock.utc_now()
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: now})

      attach_telemetry("test-dun-step-sent", [:accrue, :ops, :dunning_step_sent])

      assert {:ok, _} = perform_job(DunningStep, args(sub, :reminder, now, cus))

      # The step email delivered (existing behaviour).
      assert_received {:accrue_email_delivered, :invoice_payment_failed, _assigns}

      # Ledger: data carries step_key + step_index (no PII).
      assert [ledger] = ledger_events("dunning.step_sent", sub.id)
      assert ledger.data["step_key"] == "reminder"
      assert ledger.data["step_index"] == 0

      # Telemetry: %{count: 1}; metadata IDs + bounded values only.
      assert_received {:telemetry, [:accrue, :ops, :dunning_step_sent], %{count: 1}, meta}
      assert meta.subscription_id == sub.id
      assert meta.step_key == "reminder"
      assert meta.step_index == 0
    end

    test "a later step records the correct step_index", %{customer: cus} do
      now = Accrue.Clock.utc_now()
      sub = seed_sub(cus, %{status: :past_due, dunning_campaign_started_at: now})

      attach_telemetry("test-dun-step-sent-2", [:accrue, :ops, :dunning_step_sent])

      assert {:ok, _} = perform_job(DunningStep, args(sub, :action_required, now, cus))

      assert [ledger] = ledger_events("dunning.step_sent", sub.id)
      assert ledger.data["step_key"] == "action_required"
      assert ledger.data["step_index"] == 1

      assert_received {:telemetry, [:accrue, :ops, :dunning_step_sent], %{count: 1}, meta}
      assert meta.step_index == 1
    end
  end
end
