defmodule Accrue.Events.RecordTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Events
  alias Accrue.Events.Event

  @valid_attrs %{
    type: "subscription.created",
    subject_type: "Subscription",
    subject_id: "sub_123"
  }

  setup do
    # Each test starts with a clean actor context; some tests mutate it
    # via Accrue.Actor.put_current/1 and we don't want leakage.
    Accrue.Actor.put_current(nil)
    :ok
  end

  describe "record/1" do
    test "minimal attrs round-trip with system actor default" do
      assert {:ok, %Event{} = event} = Events.record(@valid_attrs)
      assert event.type == "subscription.created"
      assert event.subject_type == "Subscription"
      assert event.subject_id == "sub_123"
      assert event.actor_type == "system"
      assert event.actor_id == nil
      assert event.schema_version == 1
      assert event.data == %{}
      assert %DateTime{} = event.inserted_at
    end

    test "actor auto-populated from Accrue.Actor.current/0" do
      Accrue.Actor.put_current(%{type: :webhook, id: "evt_abc"})
      assert {:ok, event} = Events.record(@valid_attrs)
      assert event.actor_type == "webhook"
      assert event.actor_id == "evt_abc"
    end

    test "caller-supplied :actor overrides process dict" do
      Accrue.Actor.put_current(%{type: :system, id: nil})

      assert {:ok, event} =
               Events.record(Map.put(@valid_attrs, :actor, %{type: :admin, id: "u_42"}))

      assert event.actor_type == "admin"
      assert event.actor_id == "u_42"
    end

    test "caller-supplied actor_type/actor_id override anything" do
      assert {:ok, event} =
               Events.record(
                 Map.merge(@valid_attrs, %{actor_type: "oban", actor_id: "job_7"})
               )

      assert event.actor_type == "oban"
      assert event.actor_id == "job_7"
    end

    test "data payload round-trips" do
      payload = %{"amount_minor" => 1000, "currency" => "usd"}
      assert {:ok, event} = Events.record(Map.put(@valid_attrs, :data, payload))
      assert event.data == payload
    end

    test "duplicate idempotency_key returns the existing row" do
      attrs = Map.put(@valid_attrs, :idempotency_key, "evt_stripe_111")
      assert {:ok, first} = Events.record(attrs)

      # Second record with the same key must return the same row (same id).
      assert {:ok, second} = Events.record(Map.put(attrs, :type, "mutated"))
      assert second.id == first.id
      assert second.type == "subscription.created"
    end

    test "missing required fields returns changeset error" do
      assert {:error, %Ecto.Changeset{valid?: false} = cs} =
               Events.record(%{type: "x"})

      assert "can't be blank" in errors_on_field(cs, :subject_type)
      assert "can't be blank" in errors_on_field(cs, :subject_id)
    end

    test "invalid actor_type returns changeset error at Ecto layer" do
      assert {:error, %Ecto.Changeset{valid?: false} = cs} =
               Events.record(Map.put(@valid_attrs, :actor_type, "root"))

      refute cs.valid?
      assert "is invalid" in errors_on_field(cs, :actor_type)
    end

    test "trace_id is populated from Accrue.Telemetry.current_trace_id/0" do
      # Without OTel loaded the helper returns nil, but a caller override
      # through attrs must be preserved.
      assert {:ok, event} = Events.record(Map.put(@valid_attrs, :trace_id, "trace_xyz"))
      assert event.trace_id == "trace_xyz"
    end
  end

  describe "record_multi/3" do
    test "inserts event via Ecto.Multi pipeline" do
      multi =
        Ecto.Multi.new()
        |> Events.record_multi(:event, @valid_attrs)

      assert {:ok, %{event: %Event{} = event}} = Accrue.TestRepo.transaction(multi)
      assert event.type == "subscription.created"
      assert event.actor_type == "system"
    end

    test "record_multi with idempotency_key uses on_conflict: :nothing" do
      key = "evt_multi_#{System.unique_integer([:positive])}"
      attrs = Map.put(@valid_attrs, :idempotency_key, key)

      {:ok, %{event: first}} =
        Ecto.Multi.new()
        |> Events.record_multi(:event, attrs)
        |> Accrue.TestRepo.transaction()

      {:ok, %{event: _second}} =
        Ecto.Multi.new()
        |> Events.record_multi(:event, attrs)
        |> Accrue.TestRepo.transaction()

      # Only one row must exist for this key regardless of how many
      # transactions tried to insert it (partial unique index +
      # ON CONFLICT DO NOTHING).
      import Ecto.Query

      count =
        Accrue.TestRepo.one(
          from e in Event,
            where: e.idempotency_key == ^key,
            select: count(e.id)
        )

      assert count == 1
      assert first.id
    end
  end

  # --- helpers ----------------------------------------------------------

  defp errors_on_field(changeset, field) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Regex.replace(~r"%\{(\w+)\}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Map.get(field, [])
  end
end
