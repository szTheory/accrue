defmodule Accrue.Webhook.DefaultHandlerTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Invoice
  alias Accrue.Webhook.DefaultHandler

  test "invoice.updated reconciles invalid-location rollback state" do
    {:ok, processor_customer} =
      Accrue.Processor.create_customer(
        %{email: "rollout@example.com", address: %{line1: "27 Fredrick Ave", country: "US"}},
        []
      )

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: processor_customer.id,
        email: "rollout@example.com"
      })
      |> Repo.insert()

    {:ok, stripe_inv} =
      Fake.create_invoice(
        %{
          customer: customer.processor_id,
          collection_method: "charge_automatically",
          automatic_tax: %{enabled: true}
        },
        []
      )

    event =
      StripeFixtures.webhook_event(
        "invoice.updated",
        StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => customer.processor_id})
      )

    assert {:ok, updated} = DefaultHandler.handle(event)
    assert updated.automatic_tax == false
    assert updated.automatic_tax_status == "requires_location_inputs"
    assert updated.automatic_tax_disabled_reason == "finalization_requires_location_inputs"
  end

  test "invoice.finalization_failed stores finalization error code" do
    {:ok, processor_customer} =
      Accrue.Processor.create_customer(
        %{email: "finalization@example.com", address: %{line1: "27 Fredrick Ave", country: "US"}},
        []
      )

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: processor_customer.id,
        email: "finalization@example.com"
      })
      |> Repo.insert()

    {:ok, stripe_inv} =
      Fake.create_invoice(
        %{
          customer: customer.processor_id,
          collection_method: "charge_automatically",
          automatic_tax: %{enabled: true}
        },
        []
      )

    event =
      StripeFixtures.webhook_event(
        "invoice.finalization_failed",
        StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => customer.processor_id})
      )

    assert {:ok, %Invoice{} = updated} = DefaultHandler.handle(event)
    assert updated.automatic_tax_disabled_reason == "finalization_requires_location_inputs"
    assert updated.last_finalization_error_code == "customer_tax_location_invalid"
  end

  describe "braintree webhook normalization" do
    test "ignores unknown braintree events" do
      event = %Accrue.Webhook.Event{
        processor: :braintree,
        object_id: "sub_123",
        processor_event_id: "evt_123",
        created_at: DateTime.utc_now()
      }

      assert :ok = DefaultHandler.handle_event("some_random_event", event, %{})
    end

    test "emits missing_object_id telemetry for braintree events without object_id" do
      event = %Accrue.Webhook.Event{
        processor: :braintree,
        object_id: nil,
        processor_event_id: "evt_123",
        created_at: DateTime.utc_now()
      }

      :telemetry.attach(
        "test-braintree-missing-id",
        [:accrue, :webhooks, :missing_object_id],
        fn _name, _measurements, metadata, _config ->
          send(self(), {:telemetry_missing_id, metadata})
        end,
        nil
      )

      assert :ok = DefaultHandler.handle_event("subscription_canceled", event, %{})

      assert_received {:telemetry_missing_id,
                       %{type: "subscription_canceled", processor: :braintree}}

      :telemetry.detach("test-braintree-missing-id")
    end

    test "normalizes braintree events and dispatches to reducers" do
      event = %Accrue.Webhook.Event{
        processor: :braintree,
        object_id: "sub_123",
        processor_event_id: "evt_bt_123",
        created_at: DateTime.utc_now()
      }

      # We can't easily mock `dispatch`, but we know that if dispatch is called, 
      # the Fake processor will attempt to fetch the object. 
      # For braintree, invoice.paid fetches a :subscription.
      # Fake.fetch(:subscription, "sub_123") will return {:error, %APIError{code: "resource_missing"}}.
      # If normalization works, handle_event will return the error from the reducer.
      assert {:error, %Accrue.APIError{code: "resource_missing"}} =
               DefaultHandler.handle_event("subscription_charged_successfully", event, %{})

      # For customer.subscription.deleted, it also fetches a :subscription.
      assert {:error, %Accrue.APIError{code: "resource_missing"}} =
               DefaultHandler.handle_event("subscription_canceled", event, %{})
    end
  end
end
