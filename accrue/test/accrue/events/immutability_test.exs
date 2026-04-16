defmodule Accrue.Events.ImmutabilityTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Events
  alias Accrue.Events.Event

  @valid_attrs %{
    type: "subscription.created",
    subject_type: "Subscription",
    subject_id: "sub_123"
  }

  describe "append-only trigger (D-09)" do
    test "raw UPDATE raises Postgrex.Error with pg_code 45A01" do
      {:ok, %Event{id: id}} = Events.record(@valid_attrs)

      assert {:error, %Postgrex.Error{postgres: pg}} =
               Accrue.TestRepo.query(
                 "UPDATE accrue_events SET type = 'mutated' WHERE id = $1",
                 [id]
               )

      # Pitfall #2: Postgrex 0.22 puts unknown SQLSTATE codes on pg_code
      # (string) and leaves :code as nil. Assert BOTH are accepted so
      # the test survives a future Postgrex bump that assigns an atom.
      assert pg.pg_code == "45A01" or pg.code == :accrue_event_immutable
      assert pg.message =~ "append-only"
    end

    test "raw DELETE raises Postgrex.Error with pg_code 45A01" do
      {:ok, %Event{id: id}} = Events.record(@valid_attrs)

      assert {:error, %Postgrex.Error{postgres: pg}} =
               Accrue.TestRepo.query(
                 "DELETE FROM accrue_events WHERE id = $1",
                 [id]
               )

      assert pg.pg_code == "45A01" or pg.code == :accrue_event_immutable
      assert pg.message =~ "append-only"
    end

    test "Accrue.Repo.update/2 re-raises as EventLedgerImmutableError" do
      {:ok, %Event{} = event} = Events.record(@valid_attrs)
      changeset = Ecto.Changeset.change(event, type: "mutated")

      assert_raise Accrue.EventLedgerImmutableError, ~r/append-only/, fn ->
        Accrue.Repo.update(changeset)
      end
    end
  end

  describe "actor_type CHECK constraint (EVT-08)" do
    test "inserting actor_type='root' at the raw SQL layer raises check_violation" do
      assert {:error, %Postgrex.Error{postgres: pg}} =
               Accrue.TestRepo.query(
                 """
                 INSERT INTO accrue_events
                   (type, schema_version, actor_type, subject_type, subject_id)
                 VALUES ($1, $2, $3, $4, $5)
                 """,
                 ["x", 1, "root", "S", "s1"]
               )

      assert pg.code == :check_violation
      assert pg.constraint == "accrue_events_actor_type_check"
    end

    test "Accrue.Events.record rejects actor_type='root' at changeset layer" do
      assert {:error, %Ecto.Changeset{valid?: false}} =
               Events.record(Map.put(@valid_attrs, :actor_type, "root"))
    end
  end

  describe "idempotency_key unique index" do
    test "two records with the same non-nil key collapse to one row" do
      key = "evt_unique_#{System.unique_integer([:positive])}"

      {:ok, e1} = Events.record(Map.put(@valid_attrs, :idempotency_key, key))
      {:ok, e2} = Events.record(Map.put(@valid_attrs, :idempotency_key, key))

      assert e1.id == e2.id

      import Ecto.Query

      count =
        Accrue.TestRepo.one(
          from(e in Event, where: e.idempotency_key == ^key, select: count(e.id))
        )

      assert count == 1
    end

    test "two records with nil idempotency_key both insert (partial index)" do
      {:ok, e1} = Events.record(@valid_attrs)
      {:ok, e2} = Events.record(@valid_attrs)

      refute e1.id == e2.id
    end
  end
end
