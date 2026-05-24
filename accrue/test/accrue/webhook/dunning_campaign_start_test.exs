defmodule Accrue.Webhook.DunningCampaignStartTest do
  @moduledoc """
  Phase 128 Plan 06 — campaign start on the REAL webhook path
  (DUN-02; D-09 atomic first-transition elector + D-15 REPLACE gate).

  Drives `invoice.payment_failed` fixtures through the REAL
  `Accrue.Webhook.DefaultHandler` entry point (Pitfall 1 — the production
  path, NOT `maybe_bump_past_due_since/2` directly) and asserts:

    1. A FIRST `invoice.payment_failed` for a previously nil-anchor past_due
       subscription sets `dunning_campaign_started_at` and enqueues exactly
       one day-0 `Accrue.Workers.DunningStep` (the `after_days: 0`
       `:reminder` step) via the atomic
       `update_all WHERE is_nil(dunning_campaign_started_at)` (count==1
       winner) (D-09).

    2. A SECOND `invoice.payment_failed` in the same past-due window finds
       the anchor already set (count==0 no-op) and enqueues NO additional
       day-0 step (the `past_due_since` bump still happens) (D-09).

    3. D-15 REPLACE: with the campaign ENABLED, NO standalone
       `:invoice_payment_failed` mailer dispatch happens (campaign step-1
       owns day-0 — exactly one day-0 email path). With the campaign
       DISABLED, the standalone `:invoice_payment_failed` DOES dispatch
       (deduped by Plan 04) and NO `DunningStep` is enqueued (D-15).

  Scope fence: no ledger/telemetry (Phase 129).
  """
  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Billing.Subscription
  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Workers.DunningStep

  setup do
    prev_dunning = Application.get_env(:accrue, :dunning, :__unset__)

    on_exit(fn ->
      case prev_dunning do
        :__unset__ -> Application.delete_env(:accrue, :dunning)
        value -> Application.put_env(:accrue, :dunning, value)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_dun_start",
        email: "dun-start@example.com"
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

  # --- Helpers -------------------------------------------------------

  defp stub_invoice_fetch(invoice_id, subscription_id, next_payment_attempt) do
    canonical = %{
      "id" => invoice_id,
      "object" => "invoice",
      "status" => "open",
      "customer" => "cus_fake_dun_start",
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

  defp fire_payment_failed(invoice_id, sub_id) do
    next_attempt_unix =
      DateTime.utc_now() |> DateTime.add(2 * 86_400, :second) |> DateTime.to_unix()

    canonical = stub_invoice_fetch(invoice_id, sub_id, next_attempt_unix)
    event = StripeFixtures.webhook_event("invoice.payment_failed", canonical)
    DefaultHandler.handle(event)
  end

  defp disable_campaign! do
    # WR-04: use schema-VALID values so this fixture is a faithful, bootable
    # host config. `:stripe_native`/`:cancel` are rejected by the @schema
    # {:in, ...} constraints — the prior fixture only passed because it wrote
    # straight to app env and the read accessors never re-validate.
    Application.put_env(:accrue, :dunning,
      mode: :stripe_smart_retries,
      grace_days: 14,
      terminal_action: :canceled,
      campaign: [enabled: false, steps: []]
    )

    :ok = Accrue.Config.validate_at_boot!()
  end

  # --- D-09 first-transition elector + day-0 enqueue -----------------

  describe "campaign start on the real webhook path (D-09, campaign enabled)" do
    test "first invoice.payment_failed sets the anchor and enqueues one day-0 DunningStep",
         %{sub: sub, sub_id: sub_id} do
      assert is_nil(Repo.reload!(sub).dunning_campaign_started_at)

      assert {:ok, _} = fire_payment_failed("in_fake_start1", sub_id)

      reloaded = Repo.reload!(sub)
      assert %DateTime{} = reloaded.dunning_campaign_started_at

      jobs = all_enqueued(worker: DunningStep)
      assert length(jobs) == 1
      [job] = jobs
      assert job.args["subscription_id"] == sub.id
      assert job.args["step_key"] == "reminder"
      assert is_binary(job.args["campaign_started_at"])

      {:ok, anchor, _} = DateTime.from_iso8601(job.args["campaign_started_at"])
      assert DateTime.compare(anchor, reloaded.dunning_campaign_started_at) == :eq
    end

    test "second in-window failure enqueues NO additional day-0 step (count==0 no-op)",
         %{sub: sub, sub_id: sub_id} do
      assert {:ok, _} = fire_payment_failed("in_fake_start2a", sub_id)
      first_anchor = Repo.reload!(sub).dunning_campaign_started_at
      assert %DateTime{} = first_anchor
      assert length(all_enqueued(worker: DunningStep)) == 1

      # Second failure in the same window — anchor already set.
      assert {:ok, _} = fire_payment_failed("in_fake_start2b", sub_id)

      # Anchor unchanged, still exactly one day-0 step.
      assert Repo.reload!(sub).dunning_campaign_started_at == first_anchor
      assert length(all_enqueued(worker: DunningStep)) == 1
    end

    test "campaign enabled REPLACES the standalone :invoice_payment_failed email (D-15)",
         %{sub_id: sub_id} do
      assert {:ok, _} = fire_payment_failed("in_fake_start3", sub_id)

      # No standalone invoice_payment_failed email dispatched — campaign
      # step-1 owns day-0 (the Test adapter sends a tuple on every dispatch;
      # none should arrive for this type).
      refute_received {:accrue_email_delivered, :invoice_payment_failed, _}

      # Campaign day-0 step IS enqueued instead.
      assert length(all_enqueued(worker: DunningStep)) == 1
    end
  end

  # --- D-15 REPLACE — campaign disabled ------------------------------

  describe "campaign disabled fires the standalone email (D-15)" do
    test "standalone :invoice_payment_failed dispatches and NO DunningStep enqueued",
         %{sub_id: sub_id} do
      disable_campaign!()

      assert {:ok, _} = fire_payment_failed("in_fake_start4", sub_id)

      # No campaign step — the campaign is opted out.
      assert all_enqueued(worker: DunningStep) == []

      # Standalone invoice_payment_failed email DOES fire (deduped at enqueue
      # by Plan 04 in the real Oban lane; here the Test adapter records the
      # one dispatch).
      assert_received {:accrue_email_delivered, :invoice_payment_failed, _}
    end
  end
end
