defmodule Accrue.Dunning.DunningFullJourneyTest do
  @moduledoc """
  Phase 130 Plan 03 — DUN-10 SC#3: deterministic Fake-lane full-journey proof.

  Proves the ENTIRE dunning journey — campaign start → step progression →
  cancel-on-recovery → exhaustion — driven THROUGH the real
  `Accrue.Webhook.DefaultHandler` entry point (D-10: "a fully green suite can
  hide a feature dead on the production path").

  Every webhook-triggered stage fires through `DefaultHandler.handle/1`.
  Internal helpers (`maybe_start_dunning_campaign/2`, `enqueue_step/4`) are
  NEVER called directly. Time is advanced only via `Accrue.Test.Clock.advance/2`
  and jobs are dispatched only via `Oban.drain_queue/1` — never `Process.sleep`,
  never a network call.

  This test is UNTAGGED (no @tag :slow, :live_stripe, :compile_matrix) so it
  runs in the default merge-blocking suite (D-11).

  Also asserts the Capabilities dunning.* labels equal the doc literals (D-09
  code-side mirror of the bash drift gate).
  """
  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.Subscription
  alias Accrue.Events.Event, as: LedgerEvent
  alias Accrue.Jobs.DunningSweeper
  alias Accrue.Processor.Capabilities
  alias Accrue.Test.Clock
  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Workers.DunningStep

  # Customer processor_id shared across the journey helpers (must match the
  # `"customer"` field in stub_invoice_fetch so DefaultHandler can locate the
  # local Customer row via Customer.processor_id).
  @cus_processor_id "cus_fake_journey"

  # Default dunning policy for the journey: mode :stripe_smart_retries,
  # grace_days: 14, terminal_action :unpaid, campaign ENABLED with the
  # standard three-step cadence [0, 5, 12].
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
  # Setup: save/restore :dunning env, install known-good campaign policy,
  # seed a Customer + past_due Subscription.
  # ---------------------------------------------------------------------------

  setup do
    # Pitfall 2: save and restore the :dunning app env so config pollution
    # from another test module cannot short-circuit dunning_campaign_enabled?().
    prev_dunning = Application.get_env(:accrue, :dunning, :__unset__)

    on_exit(fn ->
      case prev_dunning do
        :__unset__ -> Application.delete_env(:accrue, :dunning)
        value -> Application.put_env(:accrue, :dunning, value)
      end
    end)

    # Install a known-good policy and validate so Config.dunning/0 returns it.
    Application.put_env(:accrue, :dunning, @dunning_policy)
    :ok = Accrue.Config.validate_at_boot!()

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: @cus_processor_id,
        email: "dun-journey@example.com"
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
  # Helpers (copied/adapted from dunning_campaign_start_test.exs precedent)
  # ---------------------------------------------------------------------------

  # Stubs Fake.retrieve_invoice and returns the canonical invoice map.
  defp stub_invoice_fetch(invoice_id, subscription_id, next_payment_attempt) do
    canonical = %{
      "id" => invoice_id,
      "object" => "invoice",
      "status" => "open",
      "customer" => @cus_processor_id,
      "subscription" => subscription_id,
      "currency" => "usd",
      "amount_due" => 1000,
      "amount_paid" => 0,
      "amount_remaining" => 1000,
      "next_payment_attempt" => next_payment_attempt,
      "lines" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    :ok = Fake.stub(:retrieve_invoice, fn _id, _opts -> {:ok, canonical} end)
    canonical
  end

  # Fires invoice.payment_failed through the REAL DefaultHandler entry point.
  defp fire_payment_failed(invoice_id, sub_id) do
    next_attempt_unix =
      DateTime.utc_now() |> DateTime.add(2 * 86_400, :second) |> DateTime.to_unix()

    canonical = stub_invoice_fetch(invoice_id, sub_id, next_attempt_unix)
    event = StripeFixtures.webhook_event("invoice.payment_failed", canonical)
    DefaultHandler.handle(event)
  end

  # Fires invoice.payment_failed with no next_payment_attempt (Stripe has
  # stopped retrying) through the REAL DefaultHandler entry point.
  defp fire_payment_failed_final(invoice_id, sub_id) do
    canonical = stub_invoice_fetch(invoice_id, sub_id, nil)
    event = StripeFixtures.webhook_event("invoice.payment_failed", canonical)
    DefaultHandler.handle(event)
  end

  # Fires customer.subscription.updated with status :active (recovery) through
  # the REAL DefaultHandler entry point. The dunning.recovered ledger event +
  # telemetry are emitted by maybe_finalize_dunning_campaign/2 inside
  # reduce_subscription.
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

    event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "active"})
      )

    DefaultHandler.handle(event)
  end

  # Fires customer.subscription.updated with status :unpaid (sweeper terminal)
  # through the REAL DefaultHandler entry point. The dunning.exhausted ledger
  # event + telemetry are emitted by maybe_emit_dunning_exhaustion/2 inside
  # reduce_subscription.
  defp fire_subscription_exhausted(sub_id) do
    canonical = %{
      "id" => sub_id,
      "object" => "subscription",
      "customer" => @cus_processor_id,
      "status" => "unpaid",
      "cancel_at_period_end" => false,
      "pause_collection" => nil,
      "items" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    :ok = Fake.stub(:retrieve_subscription, fn _id, _opts -> {:ok, canonical} end)

    event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "unpaid"})
      )

    DefaultHandler.handle(event)
  end

  # Attaches a test telemetry handler that sends a message to the calling process.
  # Handler names are made unique per invocation to prevent duplicate-attach errors
  # on CI retries or when the process crashes before on_exit cleanup runs.
  defp attach_telemetry(name, event) do
    unique_name = "#{name}-#{System.unique_integer([:positive])}"
    test_pid = self()

    :ok =
      :telemetry.attach(
        unique_name,
        event,
        fn evt, meas, meta, _ -> send(test_pid, {:telemetry, evt, meas, meta}) end,
        nil
      )

    ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(unique_name) end)
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
  # D-09 label-mirror test: Capabilities dunning.* labels == doc literals
  # ---------------------------------------------------------------------------

  describe "Capabilities dunning.* label mirror (D-09 code-side)" do
    test "provider_support_label/2 values equal the documented literals" do
      # dunning.campaign is a CONVERGENCE row — local-identical across all three
      assert Capabilities.provider_support_label(:fake, [:dunning, :campaign]) ==
               "local-identical"

      assert Capabilities.provider_support_label(:stripe, [:dunning, :campaign]) ==
               "local-identical"

      assert Capabilities.provider_support_label(:braintree, [:dunning, :campaign]) ==
               "local-identical"

      # dunning.smart_retry_alignment is a DIVERGENCE row
      assert Capabilities.provider_support_label(:stripe, [:dunning, :smart_retry_alignment]) ==
               "native (Smart Retries)"

      assert Capabilities.provider_support_label(:braintree, [:dunning, :smart_retry_alignment]) ==
               "unsupported (clock-driven only)"

      assert Capabilities.provider_support_label(:fake, [:dunning, :smart_retry_alignment]) ==
               "testing/local-only"

      # Public (group-level) labels via support_label/1
      assert Capabilities.support_label([:dunning, :campaign]) == "all first-party"

      assert Capabilities.support_label([:dunning, :smart_retry_alignment]) ==
               "provider-divergent (see dunning guide)"
    end
  end

  # ---------------------------------------------------------------------------
  # Stage 1 + 2: Happy-path progression (start → step 0 → step 5 → step 12)
  # ---------------------------------------------------------------------------

  describe "full journey — start + step progression (Stages 1 + 2)" do
    test "invoice.payment_failed starts campaign; clock-advance + drain delivers each step",
         %{sub: sub, sub_id: sub_id} do
      # ---- Stage 1: campaign start ----
      # Attach telemetry for campaign_started + step_sent before firing.
      attach_telemetry("journey-campaign-started", [:accrue, :ops, :dunning_campaign_started])
      attach_telemetry("journey-step-sent-day0", [:accrue, :ops, :dunning_step_sent])

      assert is_nil(Repo.reload!(sub).dunning_campaign_started_at)

      assert {:ok, _} = fire_payment_failed("in_journey_1", sub_id)

      reloaded = Repo.reload!(sub)
      assert %DateTime{} = reloaded.dunning_campaign_started_at,
             "dunning_campaign_started_at must be set after invoice.payment_failed"

      # Exactly one DunningStep enqueued (day-0 :reminder).
      jobs = all_enqueued(worker: DunningStep)
      assert length(jobs) == 1
      [day0_job] = jobs
      assert day0_job.args["step_key"] == "reminder"
      assert day0_job.args["subscription_id"] == sub.id

      # Ledger: dunning.campaign_started recorded.
      assert [event] = ledger_events("dunning.campaign_started", sub.id)
      assert event.data["step_count"] == 3

      # Telemetry: dunning_campaign_started fired.
      assert_received {:telemetry, [:accrue, :ops, :dunning_campaign_started], %{count: 1},
                       %{subscription_id: sub_id_from_meta, step_count: 3}}

      assert sub_id_from_meta == sub.id

      # ---- Stage 2a: drain day-0 (no clock advance needed — it's immediately available) ----
      assert %{success: 1} = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)

      # day-0 :reminder step delivered → dunning.step_sent ledger event + telemetry.
      assert [_step0_event] = ledger_events("dunning.step_sent", sub.id)

      assert_received {:telemetry, [:accrue, :ops, :dunning_step_sent], %{count: 1},
                       %{step_key: "reminder"}}

      # After day-0 drain, a day-5 step is chained (scheduled in the future).
      # The anchor must still be set (campaign remains active).
      assert Repo.reload!(sub).dunning_campaign_started_at ==
               reloaded.dunning_campaign_started_at

      # ---- Stage 2b: advance to day 5 + drain :action_required ----
      # Re-attach step_sent telemetry for day-5 step.
      attach_telemetry("journey-step-sent-day5", [:accrue, :ops, :dunning_step_sent])

      # ABSOLUTE from anchor: advance 5 days total (day-0 already at t=0).
      assert {:ok, _} = Clock.advance([days: 5], [])

      # with_scheduled: true promotes the chained future job to available.
      assert %{success: 1} = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)

      step_sent_events = ledger_events("dunning.step_sent", sub.id)
      assert length(step_sent_events) == 2, "Expected 2 step_sent events after day-5 step"

      assert_received {:telemetry, [:accrue, :ops, :dunning_step_sent], %{count: 1},
                       %{step_key: "action_required"}}

      # ---- Stage 2c: advance to day 12 + drain :final_notice ----
      attach_telemetry("journey-step-sent-day12", [:accrue, :ops, :dunning_step_sent])

      # Advance another 7 days to reach total of 12 days from anchor.
      assert {:ok, _} = Clock.advance([days: 7], [])

      assert %{success: 1} = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)

      step_sent_events = ledger_events("dunning.step_sent", sub.id)
      assert length(step_sent_events) == 3, "Expected 3 step_sent events after day-12 step"

      assert_received {:telemetry, [:accrue, :ops, :dunning_step_sent], %{count: 1},
                       %{step_key: "final_notice"}}

      # After final step, no more steps are chained — campaign is still active
      # (anchor set) but there are no more scheduled DunningStep jobs.
      remaining_jobs = all_enqueued(worker: DunningStep)
      assert remaining_jobs == [] or length(remaining_jobs) == 0,
             "No further DunningStep jobs should be enqueued after the final step"
    end
  end

  # ---------------------------------------------------------------------------
  # Stage 3: Cancel-on-recovery
  # ---------------------------------------------------------------------------

  describe "cancel-on-recovery (Stage 3)" do
    test "invoice.paid (via subscription.updated) mid-journey nils anchor, cancels steps, emits recovered",
         %{sub: sub, sub_id: sub_id} do
      # Start the campaign (Stage 1).
      assert {:ok, _} = fire_payment_failed("in_journey_recovery_1", sub_id)

      reloaded = Repo.reload!(sub)
      assert %DateTime{} = reloaded.dunning_campaign_started_at

      # Confirm one DunningStep enqueued.
      assert length(all_enqueued(worker: DunningStep)) == 1

      # Attach telemetry BEFORE firing recovery.
      attach_telemetry("journey-recovered", [:accrue, :ops, :dunning_recovered])

      # Stage 3: recovery — fires customer.subscription.updated with status: active.
      # DefaultHandler.reduce_subscription → maybe_finalize_dunning_campaign →
      # clears anchor in-transaction + stashes post-commit cancel instruction.
      assert {:ok, _updated} = fire_payment_succeeded(sub_id)

      # Anchor is cleared.
      reloaded_after = Repo.reload!(sub)
      assert is_nil(reloaded_after.dunning_campaign_started_at),
             "dunning_campaign_started_at must be nil after recovery"

      # No further DunningStep jobs enqueued (the post-commit cancel ran).
      remaining_jobs = all_enqueued(worker: DunningStep)
      assert remaining_jobs == [],
             "All enqueued DunningStep jobs must be cancelled on recovery"

      # Ledger: dunning.recovered recorded.
      assert [_] = ledger_events("dunning.recovered", sub.id)

      # Telemetry: dunning_recovered fired.
      assert_received {:telemetry, [:accrue, :ops, :dunning_recovered], %{count: 1},
                       %{subscription_id: sub_id_from_meta}}

      assert sub_id_from_meta == sub.id

      # Safety: advancing the clock + draining after recovery delivers NO further steps
      # (the anchor is nil so campaign_active? returns false on any in-flight step).
      assert {:ok, _} = Clock.advance([days: 5], [])
      drain_result = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)
      # Either empty (no jobs at all) or all cancelled (cancel guards fire).
      assert drain_result.failure == 0,
             "No failures should occur after recovery drain"

      # No new step_sent events.
      assert ledger_events("dunning.step_sent", sub.id) == []
    end
  end

  # ---------------------------------------------------------------------------
  # Stage 4: Exhaustion via DunningSweeper
  # ---------------------------------------------------------------------------

  describe "exhaustion via DunningSweeper (Stage 4)" do
    test "sweeper sweep/0 drives terminal transition; Stripe echo emits dunning.exhausted",
         %{sub: sub, sub_id: sub_id} do
      # Start the campaign and run all three steps (Stages 1 + 2).
      assert {:ok, _} = fire_payment_failed("in_journey_exhaust_1", sub_id)
      assert %{success: 1} = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)
      assert {:ok, _} = Clock.advance([days: 5], [])
      assert %{success: 1} = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)
      assert {:ok, _} = Clock.advance([days: 7], [])
      assert %{success: 1} = Oban.drain_queue(queue: :accrue_dunning, with_scheduled: true)

      # All three steps delivered, no recovery. Now the campaign has exhausted
      # its cadence. The anchor is still set (no recovery webhook arrived).
      assert %DateTime{} = Repo.reload!(sub).dunning_campaign_started_at

      # Set past_due_since to a time well beyond grace_days (14 days) so the
      # sweeper's grace_elapsed? check passes and it picks this row as a
      # candidate. We place it 30 days in the past (from the Fake clock, which
      # is now at anchor + 12 days; 30 - 12 = 18 days still > 14 grace days).
      # Use Accrue.Clock.utc_now() (Fake clock) for determinism.
      # Reload first — fire_payment_failed bumped past_due_since and lock_version.
      sub_reloaded = Repo.reload!(sub)

      past_due_since =
        Accrue.Clock.utc_now()
        |> DateTime.add(-30 * 86_400, :second)
        |> Map.put(:microsecond, {0, 6})

      {:ok, _} =
        sub_reloaded
        |> Subscription.force_status_changeset(%{past_due_since: past_due_since})
        |> Repo.update()

      # Stage 4a: sweeper calls Processor.update_subscription (Fake) to flip
      # the remote subscription to :unpaid. Local status is NOT flipped by the
      # sweeper — only by the webhook that follows.
      # Stub update_subscription so the Fake succeeds (our sub is not in the
      # Fake's in-memory subscription store — it was seeded directly into the DB).
      :ok =
        Fake.stub(:update_subscription, fn _id, _params, _opts -> {:ok, %{status: "unpaid"}} end)

      assert {:ok, sweep_count} = DunningSweeper.sweep()

      assert sweep_count >= 1,
             "DunningSweeper.sweep/0 must find and sweep at least one candidate"

      # The sweeper stamped dunning_sweep_attempted_at (used to tag the source
      # as :accrue_sweeper in the exhaustion telemetry).
      swept_sub = Repo.reload!(sub)
      assert %DateTime{} = swept_sub.dunning_sweep_attempted_at

      # Local status is still :past_due — Stripe's webhook is canonical for flips.
      assert swept_sub.status == :past_due

      # Attach telemetry before firing the Stripe echo.
      attach_telemetry("journey-exhausted", [:accrue, :ops, :dunning_exhausted])

      # Stage 4b: Stripe echoes the terminal transition via
      # customer.subscription.updated with status: :unpaid. This fires
      # maybe_emit_dunning_exhaustion + maybe_finalize_dunning_campaign inside
      # reduce_subscription.
      assert {:ok, %Subscription{status: :unpaid}} = fire_subscription_exhausted(sub_id)

      # Ledger: dunning.exhausted recorded.
      assert [exhausted_event] = ledger_events("dunning.exhausted", sub.id)
      assert exhausted_event.data["to_status"] == "unpaid"

      # Telemetry: dunning_exhausted fired.
      assert_received {:telemetry, [:accrue, :ops, :dunning_exhausted], %{count: 1},
                       %{subscription_id: sub_id_from_meta, to_status: :unpaid}}

      assert sub_id_from_meta == sub.id

      # Anchor cleared on the terminal transition (maybe_finalize_dunning_campaign
      # covers both recovery AND terminal edges).
      final_sub = Repo.reload!(sub)
      assert is_nil(final_sub.dunning_campaign_started_at),
             "anchor must be cleared on terminal transition"
    end

    test "no dunning.recovered event is emitted on exhaustion (only dunning.exhausted)",
         %{sub: sub, sub_id: sub_id} do
      # Set past_due_since so the sweeper picks this row.
      past_due_since =
        Accrue.Clock.utc_now()
        |> DateTime.add(-20 * 86_400, :second)
        |> Map.put(:microsecond, {0, 6})

      {:ok, _} =
        sub
        |> Subscription.force_status_changeset(%{past_due_since: past_due_since})
        |> Repo.update()

      # Stub update_subscription so the Fake succeeds (our sub is not in the
      # Fake's in-memory subscription store).
      :ok =
        Fake.stub(:update_subscription, fn _id, _params, _opts -> {:ok, %{status: "unpaid"}} end)

      # Run the sweeper.
      assert {:ok, _} = DunningSweeper.sweep()

      # Fire the terminal webhook echo.
      assert {:ok, _} = fire_subscription_exhausted(sub_id)

      # MUST have dunning.exhausted.
      assert [_] = ledger_events("dunning.exhausted", sub.id)

      # MUST NOT have dunning.recovered (terminal edge, not recovery edge).
      assert [] = ledger_events("dunning.recovered", sub.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Safety: no Process.sleep, no direct internal-helper calls
  # (verified by grep in CI; these tests confirm correct patterns)
  # ---------------------------------------------------------------------------

  describe "test integrity checks (D-10 compliance)" do
    test "fire_payment_failed goes through DefaultHandler (not an internal helper)", %{
      sub_id: sub_id
    } do
      # This test merely confirms DefaultHandler.handle/1 is the entry point
      # by verifying its side effects (subscription row updated, job enqueued).
      assert {:ok, _} = fire_payment_failed("in_integrity_check", sub_id)

      # Only DefaultHandler.handle produces this combination — if an internal
      # helper were called, the subscription's past_due_since would NOT be set
      # (maybe_bump_attempt is inside the invoice reducer path).
      reloaded = Repo.reload!(Repo.get_by!(Subscription, processor_id: sub_id))
      # past_due_since set by maybe_bump_attempt (inside DefaultHandler.reduce_invoice).
      assert %DateTime{} = reloaded.past_due_since
    end

    test "fire_payment_failed_final does not crash on nil next_payment_attempt", %{
      sub_id: sub_id
    } do
      # First fire starts the campaign.
      assert {:ok, _} = fire_payment_failed("in_final_ok1", sub_id)
      # Second fire with nil next_payment_attempt (Stripe stopped retrying).
      assert {:ok, _} = fire_payment_failed_final("in_final_ok2", sub_id)
      # Anchor unchanged (count==0 no-op on second fire).
      assert %DateTime{} =
               Repo.reload!(Repo.get_by!(Subscription, processor_id: sub_id)).dunning_campaign_started_at
    end
  end
end
