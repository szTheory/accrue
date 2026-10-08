defmodule Accrue.CheckoutTest do
  @moduledoc """
  Phase 4 Plan 07 (CHKT-01/02/03/06) — Accrue.Checkout context, Session
  struct (hosted + embedded), LineItem helpers, and `reconcile/1` that
  mirrors a Stripe Checkout Session into local projections.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Checkout
  alias Accrue.Checkout.{LineItem, Session}
  alias Accrue.Billing
  alias Accrue.Billing.Subscription

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_checkout",
        email: "checkout@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "Accrue.Checkout.Session.create/1" do
    test "with mode :hosted returns a hosted session struct with :url and nil client_secret",
         %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Session.create(%{
                 customer: customer,
                 mode: :subscription,
                 ui_mode: :hosted,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel"
               })

      assert is_binary(session.id)
      assert String.starts_with?(session.id, "cs_fake_")
      assert is_binary(session.url)
      assert session.client_secret == nil
      assert session.mode == "subscription"
      assert session.ui_mode == "hosted"
    end

    test "with mode :embedded returns a session with client_secret and nil url",
         %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Session.create(%{
                 customer: customer,
                 mode: :subscription,
                 ui_mode: :embedded,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 return_url: "https://example.com/return"
               })

      assert is_binary(session.client_secret)
      assert session.url == nil
      assert session.ui_mode == "embedded"
    end

    test "defaults mode to :subscription and ui_mode to :hosted", %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Session.create(%{
                 customer: customer,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 success_url: "https://example.com/s"
               })

      assert session.mode == "subscription"
      assert session.ui_mode == "hosted"
      assert is_binary(session.url)
    end

    test "accepts a stripe customer id string instead of a Customer struct",
         %{customer: customer} do
      assert {:ok, %Session{}} =
               Session.create(%{
                 customer: customer.processor_id,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 success_url: "https://example.com/s"
               })
    end

    test "projects enabled automatic tax state and amount_tax", %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Session.create(%{
                 customer: customer,
                 mode: :subscription,
                 ui_mode: :hosted,
                 automatic_tax: true,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel"
               })

      assert session.automatic_tax == true
      assert session.amount_tax == 100
    end

    test "projects disabled automatic tax state and zero amount_tax", %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Session.create(%{
                 customer: customer,
                 mode: :subscription,
                 ui_mode: :hosted,
                 automatic_tax: false,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel"
               })

      assert session.automatic_tax == false
      assert session.amount_tax == 0
    end
  end

  describe "Accrue.Checkout.LineItem" do
    test "from_price/2 returns a string-keyed Stripe line_item map" do
      assert %{"price" => "price_abc", "quantity" => 2} = LineItem.from_price("price_abc", 2)
    end

    test "from_price/1 defaults quantity to 1" do
      assert %{"price" => "price_abc", "quantity" => 1} = LineItem.from_price("price_abc")
    end

    test "from_price_data/1 returns a price_data line_item map" do
      result =
        LineItem.from_price_data(%{
          currency: "usd",
          unit_amount: 1500,
          product_data: %{name: "One-off"},
          quantity: 3
        })

      assert is_map(result["price_data"])
      assert result["quantity"] == 3
    end
  end

  describe "Accrue.Checkout.Session.retrieve/1" do
    test "returns the previously-created session", %{customer: customer} do
      {:ok, created} =
        Session.create(%{
          customer: customer,
          line_items: [LineItem.from_price("price_basic_monthly", 1)],
          success_url: "https://example.com/s"
        })

      assert {:ok, %Session{} = fetched} = Session.retrieve(created.id)
      assert fetched.id == created.id
    end
  end

  describe "Accrue.Checkout.reconcile/1" do
    test "unpaid Fake sessions are not treated as completion evidence",
         %{customer: customer} do
      {:ok, session} =
        Session.create(%{
          customer: customer,
          line_items: [LineItem.from_price("price_basic_monthly", 1)],
          success_url: "https://example.com/s"
        })

      assert {:ok, mirrored} = Checkout.reconcile(session.id)
      assert mirrored.payment_status == "unpaid"
      assert Repo.get_by(Customer, processor_id: customer.processor_id)
      assert Repo.all(Accrue.Billing.Subscription) == []
    end

    test "paid Fake session reconciliation is idempotent under parallel returns", %{
      customer: customer
    } do
      {:ok, subscription} = Billing.subscribe(customer, "price_basic")
      Repo.delete!(subscription)

      {:ok, session} =
        Session.create(%{
          customer: customer,
          line_items: [LineItem.from_price("price_basic_monthly", 1)],
          success_url: "https://example.com/s"
        })

      :ok =
        Accrue.Processor.Fake.stub(:checkout_session_fetch, fn id, _opts ->
          {:ok,
           %{
             id: id,
             status: "complete",
             payment_status: "paid",
             customer: customer.processor_id,
             subscription: subscription.processor_id,
             metadata: %{"plan_id" => "price_basic_monthly"}
           }}
        end)

      results =
        1..8
        |> Task.async_stream(fn _ -> Checkout.reconcile(session.id) end,
          max_concurrency: 8,
          timeout: 10_000
        )
        |> Enum.to_list()

      assert Enum.all?(results, &match?({:ok, {:ok, %{payment_status: "paid"}}}, &1))
      assert [%Subscription{processor_id: processor_id}] = Repo.all(Subscription)
      assert processor_id == subscription.processor_id
      assert Accrue.Processor.Fake.call_count(:checkout_session_fetch) == 8

      :ok = Accrue.Processor.Fake.unstub(:checkout_session_fetch)
    end

    test "rejects a fetched session whose trusted metadata belongs to another context" do
      :ok =
        Accrue.Processor.Fake.scripted_response(
          :checkout_session_fetch,
          {:ok,
           %{
             id: "cs_fake_context",
             status: "complete",
             payment_status: "paid",
             metadata: %{"billable_id" => "different-workspace"}
           }}
        )

      assert {:error, :checkout_context_mismatch} =
               Checkout.reconcile("cs_fake_context",
                 expected_metadata: %{"billable_id" => "workspace-1"}
               )
    end

    test "returns error tuple for unknown session id" do
      assert {:error, _} = Checkout.reconcile("cs_fake_nonexistent_99999")
    end
  end

  describe "Inspect masking on Session.client_secret" do
    test "client_secret is replaced with a redacted marker", %{customer: customer} do
      {:ok, session} =
        Session.create(%{
          customer: customer,
          ui_mode: :embedded,
          line_items: [LineItem.from_price("price_basic_monthly", 1)],
          return_url: "https://example.com/return"
        })

      assert is_binary(session.client_secret)
      output = inspect(session)
      assert output =~ "redacted"
      refute output =~ session.client_secret
    end
  end
end
