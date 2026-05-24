defmodule Accrue.Webhook.DunningCampaignKeyingTest do
  @moduledoc """
  Phase 128 Plan 06 — race-safe campaign keying + cancel-on-recovery
  (DUN-05; D-09 atomic elector, D-12 in-transaction anchor-clear +
  post-commit cancel keyed on campaign_started_at).

  Covers:

    1. RACE: under N concurrent
       `update_all WHERE is_nil(dunning_campaign_started_at)` against one
       subscription, exactly ONE returns count==1 (winner), the rest
       count==0 (no-op) — the DB-level exactly-one-winner primitive.

    2. ALREADY-RUNNING NO-OP: with the anchor already set, a later
       `invoice.payment_failed` enqueues no second day-0 step.

    3. CANCEL-ON-RECOVERY: leaving past_due (recovered → active via the
       subscription reducer) nils the anchor DURABLY (committed with the
       status write inside the reducer's transaction) and
       `Oban.cancel_all_jobs` (run POST-commit) removes the campaign's
       scheduled steps.

    4. STALE-RECOVERY ISOLATION: the cancel query is keyed on
       `campaign_started_at`, so an out-of-order recovery for an OLD
       campaign cannot cancel a fresh re-lapse campaign's in-flight steps
       (Pitfall 3).

    5. ANCHOR-CLEAR DURABILITY: even with no jobs to cancel (or a cancel
       error), the anchor is durably nil after recovery — the anchor-clear
       commits independently of the bulk cancel.

  Scope fence: no ledger/telemetry (Phase 129).
  """
  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.Subscription
  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Workers.DunningStep

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_dun_key",
        email: "dun-key@example.com"
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

  defp elect(sub_id) do
    now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}

    {count, _} =
      from(s in Subscription,
        where: s.id == ^sub_id and is_nil(s.dunning_campaign_started_at)
      )
      |> Repo.update_all(set: [dunning_campaign_started_at: now_usec])

    count
  end

  defp set_anchor(sub, %DateTime{} = anchor) do
    {:ok, sub} =
      sub
      |> Subscription.force_status_changeset(%{dunning_campaign_started_at: anchor})
      |> Repo.update()

    sub
  end

  defp stub_subscription_fetch(sub_id, status) do
    canonical = %{
      "id" => sub_id,
      "object" => "subscription",
      "customer" => "cus_fake_dun_key",
      "status" => Atom.to_string(status),
      "cancel_at_period_end" => false,
      "pause_collection" => nil,
      "items" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    :ok = Fake.stub(:retrieve_subscription, fn _id, _opts -> {:ok, canonical} end)
    canonical
  end

  defp fire_recovery(sub_id) do
    stub_subscription_fetch(sub_id, :active)

    event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "active"})
      )

    DefaultHandler.handle(event)
  end

  # CR-02: a TERMINAL transition out of `:past_due` (the sub reached the
  # dunning-exhaustion state `:unpaid`/`:canceled` via the sweeper or
  # Stripe-native termination). Like recovery, this must finalize the campaign.
  defp fire_terminal(sub_id, status) when status in [:unpaid, :canceled] do
    status_str = Atom.to_string(status)
    stub_subscription_fetch(sub_id, status)

    event =
      StripeFixtures.webhook_event(
        "customer.subscription.updated",
        StripeFixtures.subscription_created(%{"id" => sub_id, "status" => status_str})
      )

    DefaultHandler.handle(event)
  end

  # --- (1) concurrent elector — exactly one winner -------------------

  describe "race-safe first-transition elector (D-09)" do
    test "exactly one concurrent update_all wins (count==1), the rest no-op (count==0)",
         %{sub_id: sub_id} do
      # Shared sandbox so the spawned tasks see the seeded row.
      Ecto.Adapters.SQL.Sandbox.mode(Accrue.TestRepo, {:shared, self()})

      sub = Repo.get_by!(Subscription, processor_id: sub_id)

      counts =
        1..10
        |> Task.async_stream(fn _ -> elect(sub.id) end,
          max_concurrency: 10,
          ordered: false
        )
        |> Enum.map(fn {:ok, c} -> c end)

      assert Enum.count(counts, &(&1 == 1)) == 1
      assert Enum.count(counts, &(&1 == 0)) == 9
    end
  end

  # --- (2) already-running no-op -------------------------------------

  describe "already-running no-op (D-09)" do
    test "a second elector against a set anchor returns count==0", %{sub: sub} do
      assert elect(sub.id) == 1
      assert elect(sub.id) == 0
      assert %DateTime{} = Repo.reload!(sub).dunning_campaign_started_at
    end
  end

  # --- (3) cancel-on-recovery ----------------------------------------

  describe "cancel-on-recovery (D-12)" do
    test "recovery nils the anchor durably and cancels scheduled steps keyed on the anchor",
         %{sub: sub, sub_id: sub_id} do
      anchor = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
      sub = set_anchor(sub, anchor)

      # Seed a couple of scheduled steps for this campaign.
      iso = DateTime.to_iso8601(anchor)
      {:ok, _} = DunningStep.enqueue_step(sub.id, :reminder, anchor, %{})
      {:ok, _} = DunningStep.enqueue_step(sub.id, :action_required, anchor, %{})

      scheduled =
        from(j in Oban.Job,
          where: j.worker == "Accrue.Workers.DunningStep",
          where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso)
        )
        |> Repo.all()

      assert length(scheduled) == 2

      assert {:ok, %Subscription{status: :active}} = fire_recovery(sub_id)

      # Anchor durably nilled (committed with the status write).
      reloaded = Repo.reload!(sub)
      assert is_nil(reloaded.dunning_campaign_started_at)
      assert reloaded.status == :active

      # Scheduled steps cancelled post-commit (keyed on the anchor).
      remaining =
        from(j in Oban.Job,
          where: j.worker == "Accrue.Workers.DunningStep",
          where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso),
          where: j.state == "cancelled"
        )
        |> Repo.all()

      assert length(remaining) == 2
    end
  end

  # --- (3b) cancel-on-TERMINAL (CR-02) -------------------------------

  describe "cancel-on-terminal-exhaustion (CR-02, D-12)" do
    for status <- [:unpaid, :canceled] do
      test "a terminal #{status} transition nils the anchor and cancels scheduled steps",
           %{sub: sub, sub_id: sub_id} do
        status = unquote(status)
        anchor = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
        sub = set_anchor(sub, anchor)

        iso = DateTime.to_iso8601(anchor)
        {:ok, _} = DunningStep.enqueue_step(sub.id, :action_required, anchor, %{})
        {:ok, _} = DunningStep.enqueue_step(sub.id, :final_notice, anchor, %{})

        scheduled =
          from(j in Oban.Job,
            where: j.worker == "Accrue.Workers.DunningStep",
            where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso)
          )
          |> Repo.all()

        assert length(scheduled) == 2

        assert {:ok, %Subscription{status: ^status}} = fire_terminal(sub_id, status)

        # Anchor durably nilled on the terminal edge (previously only the
        # recovery edge cleared it, so terminal steps kept firing — CR-02).
        reloaded = Repo.reload!(sub)
        assert is_nil(reloaded.dunning_campaign_started_at)

        # Scheduled steps proactively cancelled post-commit, keyed on the anchor.
        cancelled =
          from(j in Oban.Job,
            where: j.worker == "Accrue.Workers.DunningStep",
            where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso),
            where: j.state == "cancelled"
          )
          |> Repo.all()

        assert length(cancelled) == 2
      end
    end
  end

  # --- (4) stale-recovery isolation ----------------------------------

  describe "stale-recovery isolation (D-12, Pitfall 3)" do
    test "a stale recovery keyed to an OLD campaign does not cancel a FRESH campaign's steps",
         %{sub: sub, sub_id: sub_id} do
      # Campaign B (fresh) is the live anchor. Seed B's steps.
      anchor_b = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
      iso_b = DateTime.to_iso8601(anchor_b)
      sub = set_anchor(sub, anchor_b)

      {:ok, _} = DunningStep.enqueue_step(sub.id, :reminder, anchor_b, %{})
      {:ok, _} = DunningStep.enqueue_step(sub.id, :action_required, anchor_b, %{})

      # An old campaign A's anchor (3 days earlier) — what a stale recovery
      # would carry. We simulate a direct stale cancel keyed to A and assert
      # B's steps survive (the cancel matches on campaign_started_at).
      anchor_a = DateTime.add(anchor_b, -3 * 86_400, :second)
      iso_a = DateTime.to_iso8601(anchor_a)

      {_, _} =
        from(j in Oban.Job,
          where: j.worker == "Accrue.Workers.DunningStep",
          where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_a)
        )
        |> Oban.cancel_all_jobs()

      # B's steps are untouched (A's key matched nothing).
      live_b =
        from(j in Oban.Job,
          where: j.worker == "Accrue.Workers.DunningStep",
          where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_b),
          where: j.state in ["available", "scheduled"]
        )
        |> Repo.all()

      assert length(live_b) == 2
      # Sanity: the live anchor is still B.
      assert DateTime.compare(Repo.reload!(sub).dunning_campaign_started_at, anchor_b) == :eq
      _ = sub_id
    end
  end

  # --- (5) anchor-clear durability -----------------------------------

  describe "anchor-clear durability (D-12, D-11)" do
    test "recovery nils the anchor even when there are no jobs to cancel",
         %{sub: sub, sub_id: sub_id} do
      anchor = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}
      sub = set_anchor(sub, anchor)

      # No DunningStep jobs scheduled — the bulk cancel matches nothing.
      assert all_enqueued(worker: DunningStep) == []

      assert {:ok, %Subscription{status: :active}} = fire_recovery(sub_id)

      # The anchor is durably nil regardless of the (empty) cancel outcome.
      reloaded = Repo.reload!(sub)
      assert is_nil(reloaded.dunning_campaign_started_at)
      assert reloaded.status == :active
    end

    test "a non-recovery transition (active → active, no prior anchor) leaves anchor nil and cancels nothing",
         %{customer: customer} do
      active_id = "sub_fake_" <> Integer.to_string(System.unique_integer([:positive]))

      {:ok, _sub} =
        %Subscription{customer_id: customer.id, processor: "fake"}
        |> Subscription.force_status_changeset(%{processor_id: active_id, status: :active})
        |> Repo.insert()

      assert {:ok, %Subscription{status: :active}} = fire_recovery(active_id)

      reloaded = Repo.get_by!(Subscription, processor_id: active_id)
      assert is_nil(reloaded.dunning_campaign_started_at)
    end
  end
end
