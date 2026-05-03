defmodule Accrue.Billing.MeteredRenewalInvoiceTest do
  @moduledoc """
  Phase 103 Plan 02 RED tests for local renewal-window invoice authoring.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{
    Customer,
    Invoice,
    InvoiceItem,
    MeterDefinitions,
    MeterEvent,
    MeteredRenewal,
    MeteredRenewalInvoice,
    Subscription,
    SubscriptionItem
  }

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id: "cus_metered_invoice_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "metered-invoice@example.com"
      })
      |> Repo.insert()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_metered_invoice_" <> Integer.to_string(System.unique_integer([:positive])),
        status: :active,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    {:ok, subscription_item} =
      %SubscriptionItem{}
      |> SubscriptionItem.changeset(%{
        subscription_id: subscription.id,
        processor: "braintree",
        processor_id: "si_metered_invoice_" <> Integer.to_string(System.unique_integer([:positive])),
        price_id: "price_ai_tokens_v1",
        processor_plan_id: "plan_ai_tokens_v1",
        quantity: 1,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    assert {:ok, definition} =
             MeterDefinitions.upsert_meter_definition("ai_tokens", %{
               subscription_item_id: subscription_item.id,
               aggregation_mode: "sum",
               active: true,
               billing_snapshot: %{
                 "price_id" => "price_ai_tokens_v1",
                 "processor_plan_id" => "plan_ai_tokens_v1",
                 "unit_amount_minor" => 2,
                 "description" => "AI token overage"
               }
             })

    snapshot = %{
      "subscription_id" => subscription.id,
      "subscription_processor_id" => subscription.processor_id,
      "subscription_item_id" => subscription_item.id,
      "price_id" => "price_ai_tokens_v1",
      "processor_plan_id" => "plan_ai_tokens_v1",
      "meter_definitions" => [
        %{
          "meter_definition_id" => definition.id,
          "event_name" => "ai_tokens",
          "subscription_item_id" => subscription_item.id,
          "price_id" => "price_ai_tokens_v1",
          "processor_plan_id" => "plan_ai_tokens_v1",
          "aggregation_mode" => "sum",
          "billing_snapshot" => %{
            "price_id" => "price_ai_tokens_v1",
            "processor_plan_id" => "plan_ai_tokens_v1",
            "unit_amount_minor" => 2,
            "description" => "AI token overage"
          }
        }
      ]
    }

    {:ok, renewal} =
      %MeteredRenewal{}
      |> MeteredRenewal.changeset(%{
        subscription_id: subscription.id,
        customer_id: customer.id,
        processor: "braintree",
        state: :pending,
        period_start: ~U[2026-04-01 00:00:00Z],
        period_end: ~U[2026-05-01 00:00:00Z],
        trigger_source: "braintree_webhook",
        snapshot: snapshot
      })
      |> Repo.insert()

    in_window =
      insert_meter_event(customer, %{
        event_name: "ai_tokens",
        value: 1200,
        identifier: "evt-in-window"
      })

    _other_event_name =
      insert_meter_event(customer, %{
        event_name: "api_calls",
        value: 300,
        identifier: "evt-other-name"
      })

    _outside_window =
      insert_meter_event(customer, %{
        event_name: "ai_tokens",
        value: 400,
        identifier: "evt-outside-window",
        occurred_at: ~U[2026-05-10 00:00:00Z]
      })

    %{
      customer: customer,
      subscription: subscription,
      subscription_item: subscription_item,
      definition: definition,
      renewal: renewal,
      in_window: in_window
    }
  end

  test "aggregates only matching in-window events and authors one local invoice with decomposed items",
       %{renewal: renewal, in_window: in_window, subscription_item: subscription_item} do
    assert {:ok, result} = MeteredRenewalInvoice.author_invoice(renewal.id)

    assert %Invoice{} = result.invoice
    assert result.invoice.customer_id == renewal.customer_id
    assert result.invoice.subscription_id == renewal.subscription_id
    assert result.invoice.processor == "braintree"
    assert result.invoice.status == :open
    assert result.invoice.billing_reason == "metered_cycle"
    assert result.invoice.period_start == renewal.period_start
    assert result.invoice.period_end == renewal.period_end

    invoice = Repo.preload(result.invoice, :items)
    assert length(invoice.items) == 1

    [item] = invoice.items
    assert %InvoiceItem{} = item
    assert item.quantity == 1200
    assert item.amount_minor == 2400
    assert item.currency == "usd"
    assert item.description == "AI token overage"
    assert item.period_start == renewal.period_start
    assert item.period_end == renewal.period_end
    assert item.price_ref == "price_ai_tokens_v1"
    assert item.subscription_item_ref == subscription_item.id

    resolved_event = Repo.get!(MeterEvent, in_window.id)
    assert resolved_event.billing_status == "matched"
    assert resolved_event.metered_renewal_id == renewal.id
  end

  test "uses the renewal snapshot as the stable explanation even if current subscription data changes",
       %{renewal: renewal, subscription_item: subscription_item} do
    {:ok, _updated_item} =
      subscription_item
      |> SubscriptionItem.changeset(%{
        price_id: "price_ai_tokens_v2",
        processor_plan_id: "plan_ai_tokens_v2",
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.update()

    assert {:ok, result} = MeteredRenewalInvoice.author_invoice(renewal.id)

    invoice = Repo.preload(result.invoice, :items)
    [item] = invoice.items

    assert item.price_ref == "price_ai_tokens_v1"
    assert item.subscription_item_ref == subscription_item.id
    assert item.description == "AI token overage"
    assert item.period_start == renewal.period_start
    assert item.period_end == renewal.period_end
    assert item.data["snapshot"]["price_id"] == "price_ai_tokens_v1"
    assert item.data["snapshot"]["processor_plan_id"] == "plan_ai_tokens_v1"
  end

  defp insert_meter_event(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      event_name: "ai_tokens",
      value: 100,
      identifier: "evt-" <> Integer.to_string(System.unique_integer([:positive])),
      occurred_at: ~U[2026-04-15 12:00:00Z],
      operation_id: "test-" <> Ecto.UUID.generate()
    }

    {:ok, event} =
      defaults
      |> Map.merge(attrs)
      |> then(&MeterEvent.pending_changeset/1)
      |> Repo.insert()

    event
  end
end
