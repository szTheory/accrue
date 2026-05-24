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

  alias Accrue.Billing.{Customer, Subscription}
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
end
