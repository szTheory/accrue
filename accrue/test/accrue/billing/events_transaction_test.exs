defmodule Accrue.Billing.EventsTransactionTest do
  @moduledoc """
  EVT-04 rollback proof and transactional event recording tests.

  Proves that every Billing context write emits an accrue_events row in
  the same transaction, and that rollback removes both the state change
  and the event atomically.
  """

  use Accrue.RepoCase, async: false

  alias Accrue.Actor
  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Events.Event
  alias Accrue.Processor

  # Test schema matching what BillableTest uses
  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    on_exit(fn ->
      Actor.put_operation_id(nil)
    end)

    :ok
  end

  defp test_user do
    %TestUser{id: Ecto.UUID.generate()}
  end

  # ---------------------------------------------------------------------------
  # EVT-04: create_customer emits event in same transaction
  # ---------------------------------------------------------------------------

  describe "create_customer/1 transactional events" do
    test "creates both a Customer row and an accrue_events row" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)

      assert %Customer{} = customer
      assert customer.processor_id =~ "cus_fake_"

      # Event should exist
      events =
        Accrue.TestRepo.all(
          from(e in Event, where: e.subject_id == ^customer.id and e.type == "customer.created")
        )

      assert length(events) == 1
      [event] = events
      assert event.subject_type == "Customer"
      assert event.type == "customer.created"
    end

    test "event has correct subject_id matching the customer id" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)

      event =
        Accrue.TestRepo.one!(from(e in Event, where: e.type == "customer.created", limit: 1))

      assert event.subject_id == customer.id
    end
  end

  # ---------------------------------------------------------------------------
  # EVT-04 rollback invariant: BOTH rows disappear on rollback
  # ---------------------------------------------------------------------------

  describe "EVT-04 rollback invariant" do
    test "rollback removes both customer and event" do
      user = test_user()

      # Capture baseline counts (robust against pre-existing data)
      customer_count_before = Accrue.TestRepo.aggregate(Customer, :count)
      event_count_before = Accrue.TestRepo.aggregate(Event, :count)

      # Use Accrue.Repo (same facade as Billing context) so the outer
      # transaction and inner Multi share the same savepoint chain.
      result =
        Accrue.Repo.transaction(fn ->
          {:ok, customer} = Billing.create_customer(user)

          # Both should exist within the transaction
          assert Accrue.Repo.repo().get(Customer, customer.id)

          assert Accrue.Repo.repo().one(from(e in Event, where: e.subject_id == ^customer.id))

          Accrue.Repo.repo().rollback(:test_rollback)
        end)

      assert {:error, :test_rollback} = result

      # After rollback, counts should return to baseline — BOTH rows gone
      assert Accrue.TestRepo.aggregate(Customer, :count) == customer_count_before
      assert Accrue.TestRepo.aggregate(Event, :count) == event_count_before
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 112: update_customer/2 remote write-through semantics
  # ---------------------------------------------------------------------------

  describe "update_customer/2" do
    test "writes through to the processor, updates the local projection, and records a bounded event" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)
      :ok = Actor.put_operation_id("cust-update-op-1")

      assert {:ok, updated} =
               Billing.update_customer(customer, %{
                 name: "Updated Name",
                 email: "updated@example.com",
                 metadata: %{"tier" => "pro"}
               })

      assert updated.name == "Updated Name"
      assert updated.email == "updated@example.com"
      assert updated.metadata == %{"tier" => "pro"}

      assert {:ok, remote_customer} = Processor.retrieve_customer(customer.processor_id, [])
      assert remote_customer.name == "Updated Name"
      assert remote_customer.email == "updated@example.com"
      assert remote_customer.metadata == %{"tier" => "pro"}

      event =
        Accrue.TestRepo.one!(
          from(e in Event,
            where: e.subject_id == ^updated.id and e.type == "customer.updated",
            order_by: [desc: e.inserted_at],
            limit: 1
          )
        )

      assert event.data["customer_id"] == updated.id
      assert event.data["processor"] == "fake"
      assert event.data["processor_id"] == updated.processor_id
      assert event.data["operation_id"] == "cust-update-op-1"
      assert Enum.sort(event.data["changed_fields"]) == ["email", "metadata", "name"]
      refute inspect(event.data) =~ "updated@example.com"
      refute inspect(event.data) =~ "Updated Name"
    end

    test "rejects unsupported attrs before processor drift" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)
      {:ok, before_remote_customer} = Processor.retrieve_customer(customer.processor_id, [])

      assert {:error, {:unsupported_customer_update_attrs, ["preferred_locale"]}} =
               Billing.update_customer(customer, %{preferred_locale: "en"})

      assert {:ok, remote_customer} = Processor.retrieve_customer(customer.processor_id, [])
      assert remote_customer == before_remote_customer

      refute Accrue.TestRepo.one(
               from(e in Event,
                 where: e.subject_id == ^customer.id and e.type == "customer.updated",
                 limit: 1
               )
             )
    end

    test "persists a sanitized local projection from the processor response" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)

      :ok =
        Accrue.Processor.Fake.scripted_response(:update_customer, {
          :ok,
          %{
            id: customer.processor_id,
            object: "customer",
            name: "Projection Name",
            email: "projection@example.com",
            metadata: %{"plan" => "plus"},
            address: %{line1: "27 Fredrick Ave"},
            shipping: %{name: "Projection Name"},
            phone: "+1-555-0100",
            tax: %{validate_location: "immediately"}
          }
        })

      assert {:ok, updated} =
               Billing.update_customer(customer, %{
                 name: "Projection Name",
                 metadata: %{"plan" => "plus"}
               })

      assert updated.name == "Projection Name"
      assert updated.email == "projection@example.com"
      assert updated.metadata == %{"plan" => "plus"}
      assert updated.data["object"] == "customer" or updated.data[:object] == "customer"
      refute Map.has_key?(updated.data, "address") or Map.has_key?(updated.data, :address)
      refute Map.has_key?(updated.data, "shipping") or Map.has_key?(updated.data, :shipping)
      refute Map.has_key?(updated.data, "phone") or Map.has_key?(updated.data, :phone)
      refute Map.has_key?(updated.data, "tax") or Map.has_key?(updated.data, :tax)
    end

    test "nested map in metadata raises validation error" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)

      result = Billing.update_customer(customer, %{metadata: %{"key" => %{"nested" => "bad"}}})

      assert {:error, changeset} = result
      assert %Ecto.Changeset{} = changeset
      assert changeset.errors[:metadata]
    end

    test "metadata with >50 keys raises validation error" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)

      big_metadata =
        for i <- 1..51, into: %{} do
          {"key_#{i}", "value_#{i}"}
        end

      result = Billing.update_customer(customer, %{metadata: big_metadata})

      assert {:error, changeset} = result
      assert changeset.errors[:metadata]
    end

    test "returns a typed projection-sync failure and emits telemetry when remote success is followed by local write failure" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)
      :ok = Actor.put_operation_id("cust-update-op-stale")

      stale_customer = Accrue.TestRepo.get!(Customer, customer.id)

      customer
      |> Customer.changeset(%{name: "Local drift"})
      |> Accrue.TestRepo.update!()

      parent = self()
      handler_id = {__MODULE__, make_ref()}

      :telemetry.attach(
        handler_id,
        [:accrue, :ops, :customer_projection_sync_failed],
        fn event, measurements, metadata, _ ->
          send(parent, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach(handler_id)
      end)

      assert {:error,
              {:customer_projection_sync_failed,
               %{
                 customer_id: customer_id,
                 processor: "fake",
                 processor_id: processor_id,
                 operation_id: "cust-update-op-stale",
                 changed_fields: ["name"],
                 failure_kind: :stale_local_projection,
                 cause: %Ecto.Changeset{}
               }}} = Billing.update_customer(stale_customer, %{name: "Remote Wins"})

      assert customer_id == customer.id
      assert processor_id == customer.processor_id

      assert {:ok, remote_customer} = Processor.retrieve_customer(customer.processor_id, [])
      assert remote_customer.name == "Remote Wins"

      refreshed_customer = Accrue.TestRepo.get!(Customer, customer.id)
      assert refreshed_customer.name == "Local drift"

      assert_received {:telemetry, [:accrue, :ops, :customer_projection_sync_failed], %{count: 1},
                       telemetry_meta}

      assert telemetry_meta.customer_id == customer.id
      assert telemetry_meta.processor == "fake"
      assert telemetry_meta.processor_id == customer.processor_id
      assert telemetry_meta.operation_id == "cust-update-op-stale"
      assert telemetry_meta.changed_fields == ["name"]
      assert telemetry_meta.failure_kind == :stale_local_projection

      refute Accrue.TestRepo.one(
               from(e in Event,
                 where: e.subject_id == ^customer.id and e.type == "customer.updated",
                 limit: 1
               )
             )
    end
  end

  describe "update_customer_local/2" do
    test "preserves explicit local-only customer maintenance without mutating the processor" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)
      :ok = Actor.put_operation_id("cust-local-op-1")

      assert {:ok, updated} =
               Billing.update_customer_local(customer, %{
                 preferred_locale: "en",
                 preferred_timezone: "America/New_York"
               })

      assert updated.preferred_locale == "en"
      assert updated.preferred_timezone == "America/New_York"

      assert {:ok, remote_customer} = Processor.retrieve_customer(customer.processor_id, [])
      refute Map.has_key?(remote_customer, :preferred_locale)
      refute Map.has_key?(remote_customer, :preferred_timezone)

      event =
        Accrue.TestRepo.one!(
          from(e in Event,
            where: e.subject_id == ^updated.id and e.type == "customer.local_updated",
            order_by: [desc: e.inserted_at],
            limit: 1
          )
        )

      assert event.data["customer_id"] == updated.id
      assert event.data["operation_id"] == "cust-local-op-1"
      assert Enum.sort(event.data["changed_fields"]) == ["preferred_locale", "preferred_timezone"]
    end
  end

  # ---------------------------------------------------------------------------
  # D2-08: put_data/2 and patch_data/2
  # ---------------------------------------------------------------------------

  describe "put_data/2 and patch_data/2" do
    test "put_data/2 fully replaces data" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)

      {:ok, updated} = Billing.put_data(customer, %{"new_key" => "new_value"})
      assert updated.data == %{"new_key" => "new_value"}

      # Full replace: previous data gone
      {:ok, replaced} = Billing.put_data(updated, %{"other" => "data"})
      assert replaced.data == %{"other" => "data"}
      refute Map.has_key?(replaced.data, "new_key")
    end

    test "patch_data/2 shallow-merges into existing data" do
      user = test_user()
      {:ok, customer} = Billing.create_customer(user)

      {:ok, updated} = Billing.put_data(customer, %{"a" => "1", "b" => "2"})
      {:ok, patched} = Billing.patch_data(updated, %{"b" => "updated", "c" => "3"})

      assert patched.data == %{"a" => "1", "b" => "updated", "c" => "3"}
    end
  end
end
