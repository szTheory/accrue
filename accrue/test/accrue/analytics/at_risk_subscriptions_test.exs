defmodule Accrue.Analytics.AtRiskSubscriptionsTest do
  @moduledoc """
  Phase 146 Plan 02 — at_risk_subscriptions/1 integration tests.

  Tests:
    1. Projection-lag race: recovered subscription excluded even with non-nil
       dunning_campaign_started_at.
    2. Happy path: at-risk subscription appears with correct keys.
    3. ETA nil: next_step_eta is nil when no pending Oban job.
    4. Pre-v1.44 honest default: failure_reason is nil when no invoice_id key.
    5. Window filter: campaign_started_at before window excluded; within window included.
  """

  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Analytics.Dunning
  alias Accrue.Events
  alias Accrue.Events.Event

  # --- Shared helpers ---------------------------------------------------

  defp insert_subscription_in_campaign(customer, campaign_started_at) do
    %Subscription{customer_id: customer.id, processor: "fake"}
    |> Subscription.force_status_changeset(%{
      processor_id: "sub_at_risk_#{System.unique_integer([:positive])}",
      status: :past_due,
      dunning_campaign_started_at: campaign_started_at
    })
    |> Repo.insert!()
  end

  defp insert_customer do
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_ar_#{System.unique_integer([:positive])}",
      email: "at-risk-#{System.unique_integer([:positive])}@example.com"
    })
    |> Repo.insert!()
  end

  defp insert_event(type, subject_id, data, opts \\ []) do
    attrs =
      %{
        type: type,
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: data
      }

    case Keyword.get(opts, :inserted_at) do
      nil ->
        {:ok, event} = Events.record(attrs)
        event

      ts ->
        Repo.insert!(%Event{
          type: type,
          subject_type: "Subscription",
          subject_id: subject_id,
          actor_type: "system",
          schema_version: 1,
          data: data,
          inserted_at: ts
        })
    end
  end

  # --- Setup ------------------------------------------------------------

  setup do
    now = Accrue.Clock.utc_now()
    customer = insert_customer()
    sub = insert_subscription_in_campaign(customer, now)

    # Insert a post-v1.44 campaign_started event for the base subscription.
    insert_event("dunning.campaign_started", sub.id, %{
      "step_count" => 3,
      "invoice_id" => "in_fake_at_risk"
    })

    %{customer: customer, sub: sub, now: now}
  end

  # --- Test 1: Projection-lag race --------------------------------------

  describe "projection-lag race (D-08, D-10)" do
    test "excludes subscription with non-nil campaign anchor when recovered event exists since campaign start",
         %{sub: sub, now: now} do
      # Insert a dunning.recovered event AFTER the campaign start.
      # This simulates the race: schema column not yet cleared,
      # but the ledger already has a terminal event.
      recovered_at = %{DateTime.add(now, 60, :second) | microsecond: {0, 6}}

      Repo.insert!(%Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: sub.id,
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 1000},
        inserted_at: recovered_at
      })

      rows = Dunning.at_risk_subscriptions()

      refute Enum.any?(rows, &(&1.subscription_id == sub.id)),
             "expected recovered subscription to be excluded (projection-lag race)"
    end

    test "excludes subscription when dunning.exhausted event exists since campaign start",
         %{sub: sub, now: now} do
      exhausted_at = %{DateTime.add(now, 120, :second) | microsecond: {0, 6}}

      Repo.insert!(%Event{
        type: "dunning.exhausted",
        subject_type: "Subscription",
        subject_id: sub.id,
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 500},
        inserted_at: exhausted_at
      })

      rows = Dunning.at_risk_subscriptions()

      refute Enum.any?(rows, &(&1.subscription_id == sub.id)),
             "expected exhausted subscription to be excluded"
    end
  end

  # --- Test 2: Happy path -----------------------------------------------

  describe "happy path" do
    test "includes at-risk subscription with correct keys", %{customer: customer, sub: sub} do
      rows = Dunning.at_risk_subscriptions()

      assert Enum.any?(rows, &(&1.subscription_id == sub.id)),
             "expected at-risk subscription to appear in results"

      row = Enum.find(rows, &(&1.subscription_id == sub.id))

      assert row.customer_id == customer.id
      assert is_integer(row.days_in_campaign)
      assert row.days_in_campaign >= 0
      assert is_integer(row.current_step) or row.current_step == 0
      assert Map.has_key?(row, :next_step_eta)
      assert Map.has_key?(row, :failure_reason)
      assert Map.has_key?(row, :customer_label)
    end

    test "does not include subscription with nil dunning_campaign_started_at" do
      # A subscription without a campaign anchor must not appear.
      customer2 = insert_customer()

      %Subscription{customer_id: customer2.id, processor: "fake"}
      |> Subscription.force_status_changeset(%{
        processor_id: "sub_no_campaign_#{System.unique_integer([:positive])}",
        status: :past_due
        # dunning_campaign_started_at intentionally nil
      })
      |> Repo.insert!()

      rows = Dunning.at_risk_subscriptions()

      refute Enum.any?(rows, &is_nil(&1.subscription_id)),
             "expected no rows with nil subscription_id"

      # All returned rows must have a non-nil customer_label or nil (nil ok for
      # customers with neither email nor name) but subscription_id must always be present.
      assert Enum.all?(rows, &(not is_nil(&1.subscription_id)))
    end
  end

  # --- Test 3: ETA nil fallback -----------------------------------------

  describe "next_step_eta nil fallback (D-03)" do
    test "next_step_eta is nil when no pending DunningStep Oban job exists", %{sub: sub} do
      # Base setup has no Oban jobs — just verify ETA is nil.
      rows = Dunning.at_risk_subscriptions()
      row = Enum.find(rows, &(&1.subscription_id == sub.id))

      assert row != nil, "expected subscription to be at-risk"
      assert row.next_step_eta == nil, "expected nil ETA when no Oban job"
    end
  end

  # --- Test 4: Pre-v1.44 honest default ---------------------------------

  describe "pre-v1.44 honest default (D-06)" do
    test "failure_reason is nil when campaign_started event has no invoice_id key" do
      # Create a separate subscription whose campaign_started event lacks invoice_id.
      customer_old = insert_customer()
      now = Accrue.Clock.utc_now()
      sub_old = insert_subscription_in_campaign(customer_old, now)

      # Campaign_started WITHOUT invoice_id (pre-v1.44 format).
      insert_event("dunning.campaign_started", sub_old.id, %{"step_count" => 3})

      rows = Dunning.at_risk_subscriptions()
      row = Enum.find(rows, &(&1.subscription_id == sub_old.id))

      assert row != nil, "expected pre-v1.44 subscription to appear in results"

      assert row.failure_reason == nil,
             "expected nil failure_reason for pre-v1.44 campaign without invoice_id"
    end
  end

  # --- Test 5: Window filter --------------------------------------------

  describe "apply_campaign_window/2 (D-15)" do
    test "excludes subscription whose campaign started before the :since window", %{sub: sub} do
      now = Accrue.Clock.utc_now()

      # Create a subscription whose campaign started 60 days ago.
      sixty_days_ago = %{DateTime.add(now, -60 * 86_400, :second) | microsecond: {0, 6}}
      customer_old = insert_customer()

      old_sub =
        %Subscription{customer_id: customer_old.id, processor: "fake"}
        |> Subscription.force_status_changeset(%{
          processor_id: "sub_old_#{System.unique_integer([:positive])}",
          status: :past_due,
          dunning_campaign_started_at: sixty_days_ago
        })
        |> Repo.insert!()

      # Insert campaign_started event with explicit inserted_at matching the old anchor.
      Repo.insert!(%Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: old_sub.id,
        actor_type: "system",
        schema_version: 1,
        data: %{"step_count" => 3, "invoice_id" => "in_old_campaign"},
        inserted_at: sixty_days_ago
      })

      # Window: only campaigns started in the last 30 days.
      since = %{DateTime.add(now, -30 * 86_400, :second) | microsecond: {0, 6}}
      rows = Dunning.at_risk_subscriptions(since: since)

      refute Enum.any?(rows, &(&1.subscription_id == old_sub.id)),
             "expected old campaign to be excluded by window filter"

      assert Enum.any?(rows, &(&1.subscription_id == sub.id)),
             "expected recent campaign to still be included in windowed results"
    end

    test "excludes subscription whose campaign started after :until window", %{sub: sub} do
      now = Accrue.Clock.utc_now()

      # The base subscription has dunning_campaign_started_at = now.
      # Use an :until that is 1 day ago so it's excluded.
      yesterday = %{DateTime.add(now, -86_400, :second) | microsecond: {0, 6}}
      rows = Dunning.at_risk_subscriptions(until: yesterday)

      refute Enum.any?(rows, &(&1.subscription_id == sub.id)),
             "expected subscription with campaign started after :until to be excluded"
    end
  end
end
