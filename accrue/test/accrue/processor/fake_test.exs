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

    test "returns customer_tax_location_invalid for immediate validation with insufficient location" do
      {:ok, %{id: id}} = Processor.create_customer(%{email: "a@b"}, [])

      assert {:error, %Accrue.APIError{} = error} =
               Processor.update_customer(
                 id,
                 %{
                   address: %{line1: "27 Fredrick Ave", country: "US"},
                   tax: %{validate_location: "immediately", ip_address: "203.0.113.10"}
                 },
                 []
               )

      assert error.code == "customer_tax_location_invalid"
      assert error.http_status == 400
      assert error.message =~ "update customer address or shipping"
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

    test "reset_preserve_connect/0 clears customers but keeps connect accounts" do
      assert {:ok, connect} =
               Fake.create_account(
                 %{type: "standard", country: "US", email: "owner@example.com"},
                 []
               )

      assert {:ok, %{id: "cus_fake_00001"}} = Processor.create_customer(%{email: "a@b"}, [])
      :ok = Fake.reset_preserve_connect()

      assert {:ok, _} = Fake.retrieve_account(connect.id, [])

      assert {:error, %Accrue.APIError{code: "resource_missing"}} =
               Processor.retrieve_customer("cus_fake_00001", [])
    end
  end

  describe "created timestamps" do
    test "use the Fake's in-memory clock, not wall time" do
      :ok = Fake.advance(Fake, 86_400)
      {:ok, customer} = Processor.create_customer(%{email: "a@b"}, [])
      assert DateTime.compare(customer.created, ~U[2026-01-02 00:00:00Z]) == :eq
    end
  end

  describe "automatic tax payloads" do
    test "subscription creation emits disabled_reason when stored customer lacks required location inputs" do
      {:ok, %{id: customer_id}} =
        Processor.create_customer(
          %{email: "a@b", address: %{line1: "27 Fredrick Ave", country: "US"}},
          []
        )

      assert {:ok, subscription} =
               Fake.create_subscription(
                 %{
                   customer: customer_id,
                   items: [%{price: "price_basic"}],
                   automatic_tax: %{enabled: true}
                 },
                 []
               )

      assert subscription.automatic_tax == %{
               enabled: false,
               status: "requires_location_inputs",
               disabled_reason: "requires_location_inputs"
             }
    end

    test "subscription creation exposes enabled automatic_tax state" do
      assert {:ok, subscription} =
               Fake.create_subscription(
                 %{
                   customer: "cus_fake_00001",
                   items: [%{price: "price_basic"}],
                   automatic_tax: %{enabled: true}
                 },
                 []
               )

      assert subscription.automatic_tax == %{enabled: true, status: "complete"}
    end

    test "subscription creation exposes disabled automatic_tax state from string keys" do
      assert {:ok, subscription} =
               Fake.create_subscription(
                 %{
                   "customer" => "cus_fake_00001",
                   "items" => [%{"price" => "price_basic"}],
                   "automatic_tax" => %{"enabled" => false}
                 },
                 []
               )

      assert subscription.automatic_tax == %{enabled: false, status: nil}
    end

    test "invoice creation emits deterministic tax fields when automatic tax is enabled" do
      assert {:ok, invoice} =
               Fake.create_invoice(
                 %{
                   customer: "cus_fake_00001",
                   amount_due: 2_500,
                   automatic_tax: %{enabled: true}
                 },
                 []
               )

      assert invoice.automatic_tax == %{enabled: true, status: "complete"}
      assert invoice.tax == 250
      assert invoice.total_details == %{amount_tax: 250}
    end

    test "invoice creation emits zero or nil tax fields when automatic tax is disabled" do
      assert {:ok, invoice} =
               Fake.create_invoice(
                 %{
                   customer: "cus_fake_00001",
                   amount_due: 2_500,
                   automatic_tax: %{enabled: false}
                 },
                 []
               )

      assert invoice.automatic_tax == %{enabled: false, status: nil}
      assert invoice.tax == nil
      assert invoice.total_details == %{amount_tax: 0}
    end

    test "invoice creation emits recurring disabled-reason payloads for invalid customer location" do
      {:ok, %{id: customer_id}} =
        Processor.create_customer(
          %{email: "a@b", address: %{line1: "27 Fredrick Ave", country: "US"}},
          []
        )

      assert {:ok, invoice} =
               Fake.create_invoice(
                 %{
                   customer: customer_id,
                   amount_due: 2_500,
                   automatic_tax: %{enabled: true}
                 },
                 []
               )

      assert invoice.automatic_tax == %{
               enabled: false,
               status: "requires_location_inputs",
               disabled_reason: "finalization_requires_location_inputs"
             }

      assert invoice.last_finalization_error == %{code: "customer_tax_location_invalid"}
    end

    test "invoice preview exposes requires_location_inputs status for invalid customer location" do
      {:ok, %{id: customer_id}} =
        Processor.create_customer(
          %{email: "a@b", address: %{line1: "27 Fredrick Ave", country: "US"}},
          []
        )

      assert {:ok, preview} =
               Fake.create_invoice_preview(
                 %{
                   customer: customer_id,
                   automatic_tax: %{enabled: true},
                   subscription_details: %{items: [%{price: "price_basic"}]}
                 },
                 []
               )

      assert preview.automatic_tax == %{enabled: true, status: "requires_location_inputs"}
    end

    test "checkout creation emits deterministic tax fields when automatic tax is enabled" do
      assert {:ok, session} =
               Fake.checkout_session_create(
                 %{
                   mode: "subscription",
                   line_items: [%{price: "price_basic", quantity: 2}],
                   automatic_tax: %{enabled: true}
                 },
                 []
               )

      assert session.automatic_tax == %{enabled: true, status: "complete"}
      assert session.total_details == %{amount_tax: 200}
    end

    test "checkout creation emits zero tax fields when automatic tax is disabled" do
      assert {:ok, session} =
               Fake.checkout_session_create(
                 %{
                   "mode" => "subscription",
                   "line_items" => [%{"price" => "price_basic", "quantity" => 2}],
                   "automatic_tax" => %{"enabled" => false}
                 },
                 []
               )

      assert session.automatic_tax == %{enabled: false, status: nil}
      assert session.total_details == %{amount_tax: 0}
    end
  end
end
