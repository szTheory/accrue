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
end
