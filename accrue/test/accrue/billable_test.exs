defmodule Accrue.BillableTest do
  @moduledoc """
  Tests for `use Accrue.Billable` macro and `Accrue.Billing` context
  round-trip against the Fake processor.
  """

  use Accrue.RepoCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Events.Event

  # -----------------------------------------------------------------------
  # Test schemas — these use binary_id PKs to match the accrue_customers
  # table's owner_id (string). No real DB table needed for the macro tests;
  # the Billing context tests use accrue_customers directly.
  # -----------------------------------------------------------------------

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
      # No real table — only used to test macro injection
    end
  end

  defmodule TestOrg do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "Organization"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_orgs" do
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

  # -----------------------------------------------------------------------
  # Test 1: Default billable_type from module name
  # -----------------------------------------------------------------------
  describe "__accrue__/1 reflection" do
    test "default billable_type is last segment of module name" do
      assert TestUser.__accrue__(:billable_type) == "TestUser"
    end

    # -------------------------------------------------------------------
    # Test 2: Override billable_type
    # -------------------------------------------------------------------
    test "overridden billable_type uses provided value" do
      assert TestOrg.__accrue__(:billable_type) == "Organization"
    end
  end

  # -----------------------------------------------------------------------
  # Test 3: create_customer round-trip
  # -----------------------------------------------------------------------
  describe "Billing.create_customer/1" do
    test "inserts an accrue_customers row with matching owner_type/owner_id/processor" do
      user = %TestUser{id: Ecto.UUID.generate()}

      assert {:ok, %Customer{} = customer} = Billing.create_customer(user)
      assert customer.owner_type == "TestUser"
      assert customer.owner_id == to_string(user.id)
      assert customer.processor == "fake"
      assert customer.processor_id =~ "cus_fake_"
    end
  end

  # -----------------------------------------------------------------------
  # Test 4: Lazy fetch-or-create
  # -----------------------------------------------------------------------
  describe "Billing.customer/1 lazy fetch-or-create" do
    test "first call creates, second call fetches same customer" do
      user = %TestUser{id: Ecto.UUID.generate()}

      assert {:ok, %Customer{} = created} = Billing.customer(user)
      assert created.processor_id =~ "cus_fake_"

      assert {:ok, %Customer{} = fetched} = Billing.customer(user)
      assert fetched.id == created.id
      assert fetched.processor_id == created.processor_id
    end

    test "organization billables preserve the existing owner contract" do
      organization = %TestOrg{id: Ecto.UUID.generate()}

      assert {:ok, %Customer{} = customer} = Billing.customer(organization)
      assert customer.owner_type == "Organization"
      assert customer.owner_id == to_string(organization.id)
      assert customer.processor == "fake"
    end
  end

  # -----------------------------------------------------------------------
  # Test 5: Transactional event invariant (EVT-04)
  # -----------------------------------------------------------------------
  describe "EVT-04 transactional event" do
    test "create_customer emits an accrue_events row in the same transaction" do
      user = %TestUser{id: Ecto.UUID.generate()}

      assert {:ok, %Customer{} = customer} = Billing.create_customer(user)

      events =
        Accrue.TestRepo.all(
          from(e in Event, where: e.type == "customer.created" and e.subject_id == ^customer.id)
        )

      assert length(events) == 1
      [event] = events
      assert event.subject_type == "Customer"
      assert event.type == "customer.created"
    end
  end

  # -----------------------------------------------------------------------
  # Test 6: Rollback causes both customer and event to disappear
  # -----------------------------------------------------------------------
  describe "EVT-04 rollback invariant" do
    test "rolling back transaction removes both customer and event" do
      user = %TestUser{id: Ecto.UUID.generate()}
      owner_id = to_string(user.id)

      result =
        Accrue.TestRepo.transaction(fn ->
          {:ok, customer} = Billing.create_customer(user)

          # Verify they exist inside the transaction
          assert Accrue.TestRepo.one(
                   from(c in Customer,
                     where: c.owner_id == ^owner_id and c.owner_type == "TestUser"
                   )
                 )

          assert Accrue.TestRepo.one(
                   from(e in Event,
                     where: e.subject_id == ^customer.id and e.type == "customer.created"
                   )
                 )

          Accrue.TestRepo.rollback(:test_rollback)
        end)

      assert {:error, :test_rollback} = result

      # After rollback, both should be gone
      assert Accrue.TestRepo.all(
               from(c in Customer, where: c.owner_id == ^owner_id and c.owner_type == "TestUser")
             ) == []

      assert Accrue.TestRepo.all(from(e in Event, where: e.type == "customer.created")) == []
    end
  end
end
