defmodule Accrue.Analytics.DunningTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Analytics.Dunning

  describe "recovered_vs_lost_mrr/1" do
    test "aggregates mrr_value_cents correctly from events" do
      # Insert events
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 1000, "source" => "webhook"}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 2000, "source" => "webhook"}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.exhausted",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 500, "source" => "webhook"}
      })

      # Unrelated events should be ignored
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 5000}
      })

      assert %{recovered_cents: 3000, lost_cents: 500} = Dunning.recovered_vs_lost_mrr()
    end

    @tag :safe_cast
    test "does not crash when a malformed string-typed mrr_value_cents row is present (DAN-08)" do
      # Malformed: mrr_value_cents stored as a JSON string instead of a JSON
      # number. The DAN-08 safe-cast wraps the cast in
      # `CASE WHEN jsonb_typeof(...) = 'number' THEN ... ELSE 0 END` so the
      # malformed row contributes 0 instead of crashing the aggregation.
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => "5000", "source" => "webhook"}
      })

      # Valid integer-typed row sums normally.
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 1000, "source" => "webhook"}
      })

      # Boundary: missing mrr_value_cents key contributes 0, does not raise.
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{}
      })

      assert %{recovered_cents: 1000, lost_cents: 0} = Dunning.recovered_vs_lost_mrr()
    end

    test "respects time windows" do
      now = Accrue.Clock.utc_now()
      now_usec = %{now | microsecond: {elem(now.microsecond, 0), 6}}
      past = DateTime.add(now_usec, -10, :day)
      past_usec = %{past | microsecond: {elem(past.microsecond, 0), 6}}
      yesterday = DateTime.add(now_usec, -1, :day)
      yesterday_usec = %{yesterday | microsecond: {elem(yesterday.microsecond, 0), 6}}

      # Old event (outside since)
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 1000},
        inserted_at: past_usec
      })

      # Current event
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 2000},
        inserted_at: now_usec
      })

      assert %{recovered_cents: 2000, lost_cents: 0} = Dunning.recovered_vs_lost_mrr(since: yesterday_usec)
      assert %{recovered_cents: 1000, lost_cents: 0} = Dunning.recovered_vs_lost_mrr(until: yesterday_usec)
    end
  end

  describe "funnel/1" do
    test "returns all-zero map on an empty ledger" do
      assert %{entered: 0, recovered: 0, exhausted: 0, active: 0} = Dunning.funnel()
    end

    @tag :funnel
    test "cycled-dunning subject collapses into 3 distinct (subject_id, anchor) tuples" do
      # One subject, three distinct campaign_anchor values:
      #   anchor_1 → recovered
      #   anchor_2 → exhausted
      #   anchor_3 → started but neither recovered nor exhausted (active)
      subject_id = Ecto.UUID.generate()
      anchor_1 = "2026-01-01T00:00:00.000000Z"
      anchor_2 = "2026-02-01T00:00:00.000000Z"
      anchor_3 = "2026-03-01T00:00:00.000000Z"

      # Anchor 1 — recovered campaign
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_1}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_1, "mrr_value_cents" => 1000}
      })

      # Anchor 2 — exhausted campaign
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_2}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.exhausted",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_2, "mrr_value_cents" => 2000}
      })

      # Anchor 3 — still active (campaign_started, no terminal event)
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_3}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_3}
      })

      assert %{entered: 3, recovered: 1, exhausted: 1, active: 1} = Dunning.funnel()
    end

    test "legacy events without campaign_anchor collapse under '__legacy__' sentinel per subject" do
      subject_id = Ecto.UUID.generate()

      # Two dunning.recovered rows for the same subject WITHOUT a campaign_anchor.
      # The COALESCE-to-'__legacy__' sentinel collapses these into ONE tuple.
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{}
      })

      assert %{entered: 1, recovered: 1, exhausted: 0, active: 0} = Dunning.funnel()
    end

    test "respects time windows on the inner subquery" do
      now = Accrue.Clock.utc_now()
      now_usec = %{now | microsecond: {elem(now.microsecond, 0), 6}}
      past = DateTime.add(now_usec, -10, :day)
      past_usec = %{past | microsecond: {elem(past.microsecond, 0), 6}}
      yesterday = DateTime.add(now_usec, -1, :day)
      yesterday_usec = %{yesterday | microsecond: {elem(yesterday.microsecond, 0), 6}}

      # OLD recovered event outside the window
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => "2024-01-01T00:00:00Z"},
        inserted_at: past_usec
      })

      # CURRENT recovered event inside the window
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => "2026-01-01T00:00:00Z"},
        inserted_at: now_usec
      })

      assert %{entered: 1, recovered: 1, exhausted: 0, active: 0} =
               Dunning.funnel(since: yesterday_usec)

      assert %{entered: 1, recovered: 1, exhausted: 0, active: 0} =
               Dunning.funnel(until: yesterday_usec)
    end

    test "campaign_started event without terminal counts toward active" do
      subject_id = Ecto.UUID.generate()

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => "2026-04-01T00:00:00Z"}
      })

      assert %{entered: 1, recovered: 0, exhausted: 0, active: 1} = Dunning.funnel()
    end
  end

  describe "campaign_timeline/2" do
    test "returns [] for subscription with no events" do
      assert [] = Dunning.campaign_timeline(Ecto.UUID.generate())
    end

    test "returns only dunning.* events for subject" do
      subject_id = Ecto.UUID.generate()

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "subscription.updated",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{}
      })

      event = Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{}
      })

      assert [returned_event] = Dunning.campaign_timeline(subject_id)
      assert returned_event.id == event.id
      assert returned_event.type == "dunning.campaign_started"
    end

    test "returns events in chronological order (asc inserted_at)" do
      subject_id = Ecto.UUID.generate()
      now = ~U[2026-01-01 10:00:00.000000Z]

      event2 = Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{},
        inserted_at: DateTime.add(now, 1, :hour)
      })

      event1 = Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{},
        inserted_at: now
      })

      assert [e1, e2] = Dunning.campaign_timeline(subject_id)
      assert e1.id == event1.id
      assert e2.id == event2.id
      assert e1.type == "dunning.step_sent"
    end
  end

  describe "campaign_timeline_grouped/2" do
    test "returns [] for subscription with no events" do
      assert [] = Dunning.campaign_timeline_grouped(Ecto.UUID.generate())
    end

    test "groups two campaigns into two arcs" do
      subject_id = Ecto.UUID.generate()
      anchor_a = "2026-01-01T00:00:00Z"
      anchor_b = "2026-02-01T00:00:00Z"

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_a},
        inserted_at: ~U[2026-01-01 10:00:00.000000Z]
      })
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_a},
        inserted_at: ~U[2026-01-01 11:00:00.000000Z]
      })
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_a},
        inserted_at: ~U[2026-01-01 12:00:00.000000Z]
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_b},
        inserted_at: ~U[2026-02-01 10:00:00.000000Z]
      })
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{"campaign_anchor" => anchor_b},
        inserted_at: ~U[2026-02-01 11:00:00.000000Z]
      })

      arcs = Dunning.campaign_timeline_grouped(subject_id)
      assert length(arcs) == 2

      [{a1, events1}, {a2, events2}] = arcs
      assert a1 == anchor_a
      assert length(events1) == 3
      assert List.last(events1).type == "dunning.recovered"

      assert a2 == anchor_b
      assert length(events2) == 2
      assert List.last(events2).type == "dunning.step_sent"
    end

    test "legacy events before first campaign_started form {nil, events} arc" do
      subject_id = Ecto.UUID.generate()

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "system",
        schema_version: 1,
        data: %{},
        inserted_at: ~U[2026-01-01 10:00:00.000000Z]
      })

      arcs = Dunning.campaign_timeline_grouped(subject_id)
      assert length(arcs) == 1
      assert [{nil, [event]}] = arcs
      assert event.type == "dunning.step_sent"
    end
  end

  describe "invoices_for_campaign/2" do
    test "returns %{} for subscription with no invoices" do
      assert %{} = Dunning.invoices_for_campaign(Ecto.UUID.generate())
    end

    test "returns map keyed by Stripe processor_id" do
      customer = Accrue.Repo.insert!(%Accrue.Billing.Customer{
        owner_type: "Tenant",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        email: "test@example.com",
        name: "Test Customer"
      })

      pm = Accrue.Repo.insert!(%Accrue.Billing.PaymentMethod{
        processor: "stripe",
        customer_id: customer.id,
        processor_id: "pm_test_xyz",
        type: "card",
        card_last4: "4242",
        card_brand: "visa"
      })

      customer = Accrue.Repo.update!(Ecto.Changeset.change(customer, default_payment_method_id: pm.id))

      subscription = Accrue.Repo.insert!(%Accrue.Billing.Subscription{
        processor: "stripe",
        customer_id: customer.id,
        status: :active,
        processor_id: "sub_test_abc"
      })

      Accrue.Repo.insert!(%Accrue.Billing.Invoice{
        processor: "stripe",
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor_id: "in_test_abc",
        amount_due_minor: 4999,
        status: :open
      })

      result = Dunning.invoices_for_campaign(subscription.id)
      assert Map.has_key?(result, "in_test_abc")
      
      entry = result["in_test_abc"]
      assert entry.status == :open
      assert entry.amount_due_cents == 4999
      assert entry.card_last4 == "4242"
      assert entry.card_brand == "visa"
    end

    test "invoice with no default payment method returns nil card fields" do
      customer = Accrue.Repo.insert!(%Accrue.Billing.Customer{
        owner_type: "Tenant",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        email: "nocards@example.com",
        name: "No Card Customer"
      })

      subscription = Accrue.Repo.insert!(%Accrue.Billing.Subscription{
        processor: "stripe",
        customer_id: customer.id,
        status: :active,
        processor_id: "sub_test_xyz"
      })

      Accrue.Repo.insert!(%Accrue.Billing.Invoice{
        processor: "stripe",
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor_id: "in_test_xyz",
        amount_due_minor: 1000,
        status: :open
      })

      result = Dunning.invoices_for_campaign(subscription.id)
      entry = result["in_test_xyz"]
      assert entry.card_last4 == nil
      assert entry.card_brand == nil
    end

    test "excludes invoices with nil processor_id" do
      customer = Accrue.Repo.insert!(%Accrue.Billing.Customer{
        owner_type: "Tenant",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        email: "nil@example.com",
        name: "Nil Processor ID Customer"
      })

      subscription = Accrue.Repo.insert!(%Accrue.Billing.Subscription{
        processor: "stripe",
        customer_id: customer.id,
        status: :active,
        processor_id: "sub_test_nil"
      })

      Accrue.Repo.insert!(%Accrue.Billing.Invoice{
        processor: "stripe",
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor_id: "in_test_valid",
        amount_due_minor: 1000,
        status: :open
      })

      Accrue.Repo.insert!(%Accrue.Billing.Invoice{
        processor: "stripe",
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor_id: nil,
        amount_due_minor: 2000,
        status: :open
      })

      result = Dunning.invoices_for_campaign(subscription.id)
      assert Map.has_key?(result, "in_test_valid")
      refute Map.has_key?(result, nil)
      assert map_size(result) == 1
    end
  end
end
