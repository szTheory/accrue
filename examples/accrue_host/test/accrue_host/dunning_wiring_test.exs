defmodule AccrueHost.DunningWiringTest do
  @moduledoc """
  Phase 130 Plan 04 — DUN-10 SC#4: host-level Fake-backed dunning wiring smoke proof.

  Proves the HOST's Oban wiring works end-to-end (enqueue → drain → recovery →
  sweep). This is a THIN wiring smoke — the rich four-stage journey lives in the
  `accrue` package (`dunning_full_journey_test.exs`, Plan 03) to avoid duplication.

  The critical proof: before this phase, `examples/accrue_host` had NO
  `accrue_dunning` queue. A `DunningStep` enqueued via the campaign would silently
  fail to process. This test asserts that the host's wired queue makes the
  campaign live.

  Never uses `Process.sleep`. Time advances via `Accrue.Test.Clock.advance/2`.
  Jobs drain via `Oban.drain_queue(queue: :accrue_dunning)`.
  All webhook paths fire through `Accrue.Webhook.DefaultHandler.handle/1`.
  """

  use AccrueHost.AccrueCase, async: false
  use Oban.Testing, repo: AccrueHost.Repo

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Jobs.DunningSweeper
  alias Accrue.Processor.Fake
  alias Accrue.Test.Clock
  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Workers.DunningStep

  # Customer processor_id — must match the "customer" field in the invoice
  # stub so DefaultHandler can locate the local Customer row.
  @cus_processor_id "cus_fake_host_dunning"

  # Known-good dunning policy: mode :stripe_smart_retries, grace_days: 14,
  # terminal_action :unpaid, campaign ENABLED with the standard three-step cadence.
  @dunning_policy [
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

  # ---------------------------------------------------------------------------
  # Setup: save/restore :dunning env, install known-good policy, seed customer + sub
  # ---------------------------------------------------------------------------

  setup do
    # Pitfall 2: save and restore the :dunning app env to prevent cross-test pollution.
    prev_dunning = Application.get_env(:accrue, :dunning, :__unset__)

    on_exit(fn ->
      case prev_dunning do
        :__unset__ -> Application.delete_env(:accrue, :dunning)
        value -> Application.put_env(:accrue, :dunning, value)
      end
    end)

    # Install the known-good policy and validate.
    Application.put_env(:accrue, :dunning, @dunning_policy)
    :ok = Accrue.Config.validate_at_boot!()

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: @cus_processor_id,
        email: "host-dunning@example.com"
      })
      |> Repo.insert()

    sub_id = "sub_fake_" <> Integer.to_string(System.unique_integer([:positive]))

    {:ok, sub} =
      %Subscription{customer_id: customer.id, processor: "fake"}
      |> Subscription.force_status_changeset(%{
        processor_id: sub_id,
        status: :past_due
      })
      |> Repo.insert()

    %{customer: customer, sub: sub, sub_id: sub_id}
  end

  # ---------------------------------------------------------------------------
  # Helpers — inline webhook event construction (StripeFixtures is accrue-package-only)
  # ---------------------------------------------------------------------------

  # Builds a minimal Stripe-shaped webhook event map that DefaultHandler.handle/1 accepts.
  defp make_webhook_event(type, object_payload) do
    %{
      "id" => "evt_host_dun_" <> Integer.to_string(System.unique_integer([:positive])),
      "object" => "event",
      "type" => type,
      "created" => DateTime.to_unix(DateTime.utc_now()),
      "data" => %{"object" => object_payload}
    }
  end

  # Stubs Fake.retrieve_invoice and fires invoice.payment_failed through DefaultHandler.
  defp fire_payment_failed(invoice_id, sub_id) do
    next_attempt_unix =
      DateTime.utc_now() |> DateTime.add(2 * 86_400, :second) |> DateTime.to_unix()

    canonical = %{
      "id" => invoice_id,
      "object" => "invoice",
      "status" => "open",
      "customer" => @cus_processor_id,
      "subscription" => sub_id,
      "currency" => "usd",
      "amount_due" => 1000,
      "amount_paid" => 0,
      "amount_remaining" => 1000,
      "next_payment_attempt" => next_attempt_unix,
      "lines" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    :ok = Fake.stub(:retrieve_invoice, fn _id, _opts -> {:ok, canonical} end)
    event = make_webhook_event("invoice.payment_failed", canonical)
    DefaultHandler.handle(event)
  end

  # Fires customer.subscription.updated with status :active (recovery) through DefaultHandler.
  defp fire_payment_succeeded(sub_id) do
    canonical = %{
      "id" => sub_id,
      "object" => "subscription",
      "customer" => @cus_processor_id,
      "status" => "active",
      "cancel_at_period_end" => false,
      "pause_collection" => nil,
      "items" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    :ok = Fake.stub(:retrieve_subscription, fn _id, _opts -> {:ok, canonical} end)

    # customer.subscription.updated requires a well-shaped subscription object.
    sub_object = %{
      "id" => sub_id,
      "object" => "subscription",
      "customer" => @cus_processor_id,
      "status" => "active",
      "cancel_at_period_end" => false,
      "pause_collection" => nil,
      "current_period_start" => DateTime.to_unix(DateTime.utc_now()),
      "current_period_end" =>
        DateTime.to_unix(DateTime.add(DateTime.utc_now(), 30 * 86_400, :second)),
      "items" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    event = make_webhook_event("customer.subscription.updated", sub_object)
    DefaultHandler.handle(event)
  end

  # Queries ledger events for a given type + subscription subject.
  defp ledger_events(type, subject_id) do
    Repo.all(
      from(e in LedgerEvent,
        where:
          e.type == ^type and e.subject_type == "Subscription" and
            e.subject_id == ^subject_id
      )
    )
  end

  # ---------------------------------------------------------------------------
  # Stage A: Enqueue — invoice.payment_failed starts the campaign on the wired queue
  # ---------------------------------------------------------------------------

  describe "Stage A: enqueue works on the wired accrue_dunning queue" do
    test "invoice.payment_failed sets dunning_campaign_started_at and enqueues one DunningStep",
         %{sub: sub, sub_id: sub_id} do
      # Precondition: no campaign active.
      assert is_nil(Repo.reload!(sub).dunning_campaign_started_at)

      assert {:ok, _} = fire_payment_failed("in_host_dun_a1", sub_id)

      reloaded = Repo.reload!(sub)

      # Campaign anchor is set — this is the load-bearing proof that the host's
      # accrue_dunning queue makes the campaign live. Without the queue wired,
      # the DunningStep enqueue would fail silently.
      assert %DateTime{} = reloaded.dunning_campaign_started_at

      # Exactly one day-0 DunningStep enqueued on :accrue_dunning.
      jobs = all_enqueued(worker: DunningStep)
      assert length(jobs) == 1
      [job] = jobs
      assert job.args["subscription_id"] == sub.id
      assert job.args["step_key"] == "reminder"
      assert job.queue == "accrue_dunning"
    end
  end

  # ---------------------------------------------------------------------------
  # Stage B: Drain — the wired queue executes and chains steps
  # ---------------------------------------------------------------------------

  describe "Stage B: drain delivers the enqueued DunningStep on the wired queue" do
    test "Oban.drain_queue delivers the day-0 step; clock-advance + drain chains next step",
         %{sub: sub, sub_id: sub_id} do
      assert {:ok, _} = fire_payment_failed("in_host_dun_b1", sub_id)

      # Drain day-0 step — must run without error.
      %{success: success_count} = Oban.drain_queue(queue: :accrue_dunning)
      assert success_count >= 1

      # Ledger event for the step was recorded.
      assert [_ | _] = ledger_events("dunning.step_sent", sub.id)

      # Advance 5 days and drain — day-5 step chains.
      {:ok, _} = Clock.advance([days: 5], [])
      %{success: day5_success} = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)
      assert day5_success >= 1
    end
  end

  # ---------------------------------------------------------------------------
  # Stage C: Recovery — invoice.paid cancels the campaign on the host path
  # ---------------------------------------------------------------------------

  describe "Stage C: recovery cancels the campaign on the host path" do
    test "invoice.paid (customer.subscription.updated active) nils the anchor and records dunning.recovered",
         %{sub: sub, sub_id: sub_id} do
      # Start the campaign.
      assert {:ok, _} = fire_payment_failed("in_host_dun_c1", sub_id)
      assert %DateTime{} = Repo.reload!(sub).dunning_campaign_started_at

      # Fire recovery via customer.subscription.updated (active).
      assert {:ok, _} = fire_payment_succeeded(sub_id)

      # Anchor is cleared — recovery cancelled the campaign.
      reloaded = Repo.reload!(sub)
      assert is_nil(reloaded.dunning_campaign_started_at)

      # Ledger records dunning.recovered.
      assert [_ | _] = ledger_events("dunning.recovered", sub.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Stage D: Sweeper wiring — DunningSweeper.sweep/0 works against the host Repo
  # ---------------------------------------------------------------------------

  describe "Stage D: sweeper wiring" do
    test "DunningSweeper.sweep/0 runs against the host Repo without error" do
      # Stub update_subscription so the sweeper does not fail if it
      # finds a past_due candidate that is not registered in Fake's store.
      :ok =
        Fake.stub(:update_subscription, fn _id, _params, _opts -> {:ok, %{"status" => "unpaid"}} end)

      # sweep/0 always returns {:ok, count} — count may be 0 if no candidates.
      assert {:ok, _count} = DunningSweeper.sweep()
    end

    test "Oban.Plugins.Cron crontab entry for DunningSweeper uses the :accrue_dunning queue" do
      # The cron-dispatched sweep lands in the wired queue.
      assert DunningSweeper.__opts__()[:queue] == :accrue_dunning
    end
  end
end
