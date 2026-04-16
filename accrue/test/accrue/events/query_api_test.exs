defmodule Accrue.Events.QueryAPITest do
  use Accrue.RepoCase

  alias Accrue.Events
  alias Accrue.Events.Event

  # NOTE: Sandbox transaction → Postgres now() returns the txn start time,
  # so every event recorded via Events.record/1 inside a single test gets
  # the same inserted_at. To exercise time-based assertions we insert
  # events directly with an explicit inserted_at, which Postgres honors
  # over the column DEFAULT. We bypass the changeset's cast/3 (inserted_at
  # is not in @cast_fields) by using Ecto.Changeset.change/2.

  setup do
    subject_id = Ecto.UUID.generate()
    {:ok, subject_id: subject_id, base_ts: ~U[2026-04-01 12:00:00.000000Z]}
  end

  describe "timeline_for/3" do
    test "returns events ordered ascending by inserted_at", %{subject_id: sid, base_ts: t0} do
      insert_event!("subscription.created", sid, %{"a" => 1}, t0)
      insert_event!("subscription.updated", sid, %{"a" => 2}, DateTime.add(t0, 1, :second))
      insert_event!("subscription.canceled", sid, %{"a" => 3}, DateTime.add(t0, 2, :second))

      events = Events.timeline_for("Subscription", sid)

      assert length(events) == 3

      assert Enum.map(events, & &1.type) ==
               ["subscription.created", "subscription.updated", "subscription.canceled"]
    end

    test "respects :limit option", %{subject_id: sid, base_ts: t0} do
      for n <- 1..5 do
        insert_event!("subscription.updated", sid, %{"n" => n}, DateTime.add(t0, n, :second))
      end

      events = Events.timeline_for("Subscription", sid, limit: 3)
      assert length(events) == 3
    end

    test "scopes to subject_type and subject_id", %{subject_id: sid, base_ts: t0} do
      insert_event!("subscription.created", sid, %{}, t0)
      insert_event!("subscription.created", Ecto.UUID.generate(), %{}, t0)

      events = Events.timeline_for("Subscription", sid)
      assert length(events) == 1
    end
  end

  describe "state_as_of/3" do
    test "returns folded state as of a past timestamp", %{subject_id: sid, base_ts: t0} do
      e1 = insert_event!("subscription.created", sid, %{"status" => "trialing"}, t0)
      cutoff = DateTime.add(t0, 1, :second)

      _e2 =
        insert_event!(
          "subscription.updated",
          sid,
          %{"status" => "active"},
          DateTime.add(t0, 5, :second)
        )

      result = Events.state_as_of("Subscription", sid, cutoff)

      assert result.event_count == 1
      assert result.state["status"] == "trialing"
      assert DateTime.compare(result.last_event_at, e1.inserted_at) == :eq
    end

    test "folds multiple events into combined state", %{subject_id: sid, base_ts: t0} do
      insert_event!("subscription.created", sid, %{"status" => "trialing", "qty" => 1}, t0)

      insert_event!(
        "subscription.updated",
        sid,
        %{"status" => "active"},
        DateTime.add(t0, 1, :second)
      )

      insert_event!("subscription.updated", sid, %{"qty" => 5}, DateTime.add(t0, 2, :second))

      result = Events.state_as_of("Subscription", sid, DateTime.add(t0, 10, :second))
      assert result.event_count == 3
      assert result.state["status"] == "active"
      assert result.state["qty"] == 5
    end
  end

  describe "bucket_by/2" do
    test "groups by day for matching event type", %{subject_id: sid, base_ts: t0} do
      for _ <- 1..3, do: insert_event!("charge.succeeded", sid, %{}, t0)
      for _ <- 1..2, do: insert_event!("charge.failed", sid, %{}, t0)

      buckets = Events.bucket_by([type: "charge.succeeded"], :day)

      assert length(buckets) == 1
      [{_dt, count}] = buckets
      assert count == 3
    end

    test "supports :week and :month bucket sizes", %{subject_id: sid, base_ts: t0} do
      for _ <- 1..2, do: insert_event!("invoice.paid", sid, %{}, t0)

      assert [{_, 2}] = Events.bucket_by([type: "invoice.paid"], :week)
      assert [{_, 2}] = Events.bucket_by([type: "invoice.paid"], :month)
    end

    test "returns empty list when no matches", %{subject_id: _sid} do
      assert [] = Events.bucket_by([type: "nonexistent.event"], :day)
    end
  end

  # --- helpers ----------------------------------------------------------

  defp insert_event!(type, subject_id, data, %DateTime{} = ts) do
    %Event{}
    |> Ecto.Changeset.change(%{
      type: type,
      schema_version: 1,
      actor_type: "system",
      subject_type: "Subscription",
      subject_id: subject_id,
      data: data,
      inserted_at: ts
    })
    |> Accrue.TestRepo.insert!()
  end
end
