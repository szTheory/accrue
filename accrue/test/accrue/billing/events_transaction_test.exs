defmodule Accrue.Billing.EventsTransactionTest do
  @moduledoc """
  EVT-04 rollback proof and transactional event recording tests.

  Proves that every Billing context write emits an accrue_events row in
  the same transaction, and that rollback removes both the state change
  and the event atomically.
  """

  use Accrue.RepoCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Events.Event

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
        Accrue.TestRepo.one!(
          from(e in Event, where: e.type == "customer.created", limit: 1)
        )

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

          assert Accrue.Repo.repo().one(
                   from(e in Event, where: e.subject_id == ^customer.id)
                 )

          Accrue.Repo.repo().rollback(:test_rollback)
        end)

      assert {:error, :test_rollback} = result

      # After rollback, counts should return to baseline — BOTH rows gone
      assert Accrue.TestRepo.aggregate(Customer, :count) == customer_count_before
      assert Accrue.TestRepo.aggregate(Event, :count) == event_count_before
    end
  end

  # ---------------------------------------------------------------------------
  # D2-07: update_customer metadata validation
  # ---------------------------------------------------------------------------

  describe "update_customer/2 metadata validation" do
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
