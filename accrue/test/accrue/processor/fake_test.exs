defmodule Accrue.Processor.FakeTest do
  use ExUnit.Case, async: false

  alias Accrue.Processor
  alias Accrue.Processor.Fake

  setup do
    # Start the Fake GenServer (may already be running from a prior test).
    case Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Fake.reset()
    :ok
  end

  describe "create_customer/2" do
    test "returns deterministic zero-padded ids starting at cus_fake_00001" do
      assert {:ok, %{id: "cus_fake_00001", email: "a@b"}} =
               Processor.create_customer(%{email: "a@b"}, [])

      assert {:ok, %{id: "cus_fake_00002"}} =
               Processor.create_customer(%{email: "c@d"}, [])

      assert {:ok, %{id: "cus_fake_00003"}} =
               Processor.create_customer(%{email: "e@f"}, [])
    end

    test "persists params into the returned customer map" do
      assert {:ok, customer} =
               Processor.create_customer(%{email: "x@y", name: "Jane"}, [])

      assert customer.email == "x@y"
      assert customer.name == "Jane"
      assert customer.id == "cus_fake_00001"
      assert customer.object == "customer"
      assert %DateTime{} = customer.created
    end
  end

  describe "retrieve_customer/2" do
    test "returns previously-created customer" do
      {:ok, %{id: id}} = Processor.create_customer(%{email: "a@b"}, [])
      assert {:ok, %{id: ^id, email: "a@b"}} = Processor.retrieve_customer(id, [])
    end

    test "returns Accrue.APIError with resource_missing for unknown id" do
      assert {:error, %Accrue.APIError{} = err} =
               Processor.retrieve_customer("cus_nonexistent", [])

      assert err.code == "resource_missing"
      assert err.http_status == 404
      assert err.message =~ "cus_nonexistent"
    end
  end

  describe "update_customer/3" do
    test "merges new params into the stored customer" do
      {:ok, %{id: id}} = Processor.create_customer(%{email: "a@b", name: "Old"}, [])

      assert {:ok, %{id: ^id, name: "New", email: "a@b"}} =
               Processor.update_customer(id, %{name: "New"}, [])

      assert {:ok, %{name: "New"}} = Processor.retrieve_customer(id, [])
    end

    test "returns APIError for unknown id" do
      assert {:error, %Accrue.APIError{code: "resource_missing"}} =
               Processor.update_customer("cus_missing", %{name: "X"}, [])
    end
  end

  describe "test clock" do
    test "current_time/0 defaults to the epoch module attribute" do
      assert %DateTime{year: 2026, month: 1, day: 1} = Fake.current_time()
    end

    test "advance/2 moves the clock forward by N seconds" do
      before = Fake.current_time()
      :ok = Fake.advance(Fake, 3600)
      after_advance = Fake.current_time()

      assert DateTime.diff(after_advance, before, :second) == 3600
    end

    test "reset/0 restores the clock and zeros counters" do
      {:ok, %{id: "cus_fake_00001"}} = Processor.create_customer(%{email: "a@b"}, [])
      :ok = Fake.advance(Fake, 7200)
      :ok = Fake.reset()

      # Counter restarts
      assert {:ok, %{id: "cus_fake_00001"}} = Processor.create_customer(%{email: "x@y"}, [])

      # Clock restored
      assert %DateTime{year: 2026, month: 1, day: 1, hour: 0} = Fake.current_time()
    end
  end

  describe "created timestamps" do
    test "use the Fake's in-memory clock, not wall time" do
      :ok = Fake.advance(Fake, 86_400)
      {:ok, customer} = Processor.create_customer(%{email: "a@b"}, [])
      assert DateTime.compare(customer.created, ~U[2026-01-02 00:00:00Z]) == :eq
    end
  end
end
