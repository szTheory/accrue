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
end
