defmodule Accrue.Billing.CheckoutSessionFacadeTest do
  @moduledoc false

  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Checkout.{LineItem, Session}
  alias Accrue.Processor.Fake

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_checkout_facade",
        email: "checkout_facade@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "create_checkout_session/2" do
    test "happy path returns Fake session", %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Billing.create_checkout_session(customer,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel",
                 mode: :subscription,
                 ui_mode: :hosted
               )

      assert String.starts_with?(session.id, "cs_fake_")
    end

    test "failure path respects Fake.scripted_response/2", %{customer: customer} do
      err = %Accrue.APIError{code: "checkout_rejected", http_status: 400, message: "nope"}

      :ok =
        Fake.scripted_response(:checkout_session_create, {:error, err})

      assert {:error, %Accrue.APIError{code: "checkout_rejected"}} =
               Billing.create_checkout_session(customer,
                 line_items: [LineItem.from_price("price_basic_monthly", 1)],
                 success_url: "https://example.com/success",
                 cancel_url: "https://example.com/cancel",
                 mode: :subscription,
                 ui_mode: :hosted
               )
    end

    test "telemetry metadata allowlists checkout dimensions and omits secrets", %{
      customer: customer
    } do
      handler_id = "billing_checkout_facade_test_#{:erlang.unique_integer([:positive])}"
      parent = self()

      :ok =
        :telemetry.attach(
          handler_id,
          [:accrue, :billing, :checkout_session, :create, :start],
          fn _event, _measurements, metadata, _config ->
            send(parent, {:telemetry_start, metadata})
          end,
          nil
        )

      try do
        assert {:ok, %Session{}} =
                 Billing.create_checkout_session(customer,
                   mode: :subscription,
                   ui_mode: :hosted,
                   line_items: [
                     LineItem.from_price("price_basic_monthly", 1),
                     LineItem.from_price("price_basic_monthly", 1)
                   ],
                   success_url: "https://example.com/success",
                   cancel_url: "https://example.com/cancel"
                 )

        assert_receive {:telemetry_start, metadata}
        assert metadata[:operation] == "checkout_session.create"
        assert Map.get(metadata, :checkout_line_items_count) == 2
        assert Map.get(metadata, :checkout_mode) != nil
        assert Map.get(metadata, :checkout_ui_mode) != nil

        refute String.contains?(inspect(metadata), "client_secret")
        refute String.contains?(inspect(metadata), "http")
      after
        :telemetry.detach(handler_id)
      end
    end

    test "rejects unknown attrs at the Billing facade", %{customer: customer} do
      assert_raise NimbleOptions.ValidationError, fn ->
        Billing.create_checkout_session(customer, %{not_a_real_key: true})
      end
    end
  end

  describe "create_checkout_session!/2" do
    test "accepts a map of attrs", %{customer: customer} do
      session =
        Billing.create_checkout_session!(customer, %{
          line_items: [LineItem.from_price("price_basic_monthly", 1)],
          success_url: "https://example.com/s2",
          cancel_url: "https://example.com/c2"
        })

      assert %Session{} = session
      assert String.starts_with?(session.id, "cs_fake_")
    end
  end
end
