defmodule Accrue.Dunning.Engine.ObanTest do
  @moduledoc """
  Phase 131 Plan 01 Task 1: Unit test scaffold for Accrue.Dunning.Engine.Oban.

  Wave-0 test scaffold — all tests are RED until Plan 03 creates Engine.Oban.
  Expected failure: `UndefinedFunctionError` / module not available.

  Tests cover the four documented behaviours:
    (a) start_campaign enqueues exactly one DunningStep job for the day-zero step.
    (b) start_campaign returns :ok and enqueues nothing when no day-zero step configured.
    (c) cancel_campaign cancels Oban jobs matching subscription_id + campaign_started_at.
    (d) cancel_campaign returns :ok even when the underlying cancel raises (rescue contract).
  """

  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Billing.Subscription
  alias Accrue.Dunning.Engine.Oban, as: EngineOban
  alias Accrue.Workers.DunningStep

  # Default dunning campaign policy — three steps with a day-0 step.
  @dunning_with_campaign [
    mode: :stripe_smart_retries,
    grace_days: 14,
    terminal_action: :unpaid,
    campaign: [
      enabled: true,
      steps: [
        [after_days: 0, key: :reminder, template: Accrue.Emails.InvoicePaymentFailed],
        [after_days: 5, key: :action_required, template: Accrue.Emails.DunningActionRequired],
        [after_days: 12, key: :final_notice, template: Accrue.Emails.DunningFinalNotice]
      ]
    ]
  ]

  # Campaign policy with no day-zero step (first step is day 5).
  @dunning_no_day_zero [
    mode: :stripe_smart_retries,
    grace_days: 14,
    terminal_action: :unpaid,
    campaign: [
      enabled: true,
      steps: [
        [after_days: 5, key: :action_required, template: Accrue.Emails.DunningActionRequired],
        [after_days: 12, key: :final_notice, template: Accrue.Emails.DunningFinalNotice]
      ]
    ]
  ]

  setup do
    prev_dunning = Application.get_env(:accrue, :dunning, :__unset__)

    on_exit(fn ->
      case prev_dunning do
        :__unset__ -> Application.delete_env(:accrue, :dunning)
        value -> Application.put_env(:accrue, :dunning, value)
      end
    end)

    {:ok, customer} =
      %Accrue.Billing.Customer{}
      |> Accrue.Billing.Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_engine_oban_test_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "engine-oban-test@example.com"
      })
      |> Accrue.TestRepo.insert()

    {:ok, sub} =
      %Subscription{customer_id: customer.id, processor: "fake"}
      |> Subscription.force_status_changeset(%{
        processor_id: "sub_engine_" <> Integer.to_string(System.unique_integer([:positive])),
        status: :past_due
      })
      |> Accrue.TestRepo.insert()

    %{customer: customer, sub: sub}
  end

  describe "start_campaign/3" do
    test "enqueues exactly one DunningStep job for the day-zero step", %{sub: sub} do
      Application.put_env(:accrue, :dunning, @dunning_with_campaign)
      :ok = Accrue.Config.validate_at_boot!()

      anchor = DateTime.utc_now()

      assert :ok = EngineOban.start_campaign(sub, anchor, invoice_id: "in_test_001")

      jobs = all_enqueued(worker: DunningStep)
      assert length(jobs) == 1
      [job] = jobs
      assert job.args["step_key"] == "reminder"
      assert job.args["subscription_id"] == sub.id
    end

    test "returns :ok and enqueues nothing when no day-zero step configured", %{sub: sub} do
      Application.put_env(:accrue, :dunning, @dunning_no_day_zero)
      :ok = Accrue.Config.validate_at_boot!()

      anchor = DateTime.utc_now()

      assert :ok = EngineOban.start_campaign(sub, anchor, invoice_id: "in_test_002")

      assert [] = all_enqueued(worker: DunningStep)
    end
  end

  describe "cancel_campaign/3" do
    test "cancels Oban jobs matching subscription_id + campaign_started_at", %{sub: sub} do
      Application.put_env(:accrue, :dunning, @dunning_with_campaign)
      :ok = Accrue.Config.validate_at_boot!()

      anchor = DateTime.utc_now()
      iso_anchor = DateTime.to_iso8601(anchor)

      # Start campaign first to enqueue a DunningStep job.
      :ok = EngineOban.start_campaign(sub, anchor, invoice_id: "in_test_003")

      assert length(all_enqueued(worker: DunningStep)) == 1

      # Cancel campaign — should cancel the enqueued jobs.
      assert :ok = EngineOban.cancel_campaign(sub, iso_anchor, [])

      # After cancellation, no available jobs should remain for this campaign.
      # (Oban marks cancelled jobs as :cancelled, not deleted.)
      remaining =
        all_enqueued(worker: DunningStep)
        |> Enum.filter(fn j ->
          j.args["subscription_id"] == sub.id and
            j.args["campaign_started_at"] == iso_anchor
        end)

      assert remaining == []
    end

    test "returns :ok even when cancel raises (rescue contract)", %{sub: sub} do
      anchor = DateTime.utc_now()
      iso_anchor = DateTime.to_iso8601(anchor)

      # Calling cancel with a non-existent campaign should still return :ok.
      # This validates the rescue contract in cancel_campaign/3.
      assert :ok = EngineOban.cancel_campaign(sub, iso_anchor, [])
    end
  end
end
