defmodule Accrue.Billing.InvoiceProjectionTest do
  @moduledoc """
  Plan 05 Task 1: `Accrue.Billing.InvoiceProjection.decompose/1` is the
  deterministic decomposer that converts a processor (Stripe- or Fake-
  shaped) invoice map into a flat attrs map plus a list of child item
  attrs, ready for `Invoice.changeset/2` and `InvoiceItem.changeset/2`.

  Mirrors `Accrue.Billing.SubscriptionProjection` in shape: handles both
  string-keyed (StripeFixtures wire shape) and atom-keyed (Fake state)
  inputs, extracts every D3-14 rollup column, and preserves the full
  upstream map in the `data` jsonb column.
  """
  use ExUnit.Case, async: true

  alias Accrue.Billing.InvoiceProjection
  alias Accrue.Test.StripeFixtures

  describe "decompose/1 (string-keyed wire shape)" do
    test "decomposes status, rollups, and period dates" do
      inv =
        StripeFixtures.invoice(%{
          "status" => "open",
          "subtotal" => 1500,
          "total" => 1500,
          "amount_due" => 1500
        })

      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
      assert attrs.processor_id == inv["id"]
      assert attrs.status == :open
      assert attrs.subtotal_minor == 1500
      assert attrs.total_minor == 1500
      assert attrs.amount_due_minor == 1500
      assert attrs.currency == "usd"
      assert attrs.number == "TEST-001"
      assert attrs.hosted_url == "https://invoice.stripe.com/test"
      assert attrs.pdf_url == "https://invoice.stripe.com/test.pdf"
      assert attrs.collection_method == "charge_automatically"
      assert attrs.billing_reason == "subscription_create"
      assert %DateTime{} = attrs.period_start
      assert %DateTime{} = attrs.period_end
    end

    test "decomposes lines.data into item attrs" do
      inv = StripeFixtures.invoice()
      {:ok, %{item_attrs: items}} = InvoiceProjection.decompose(inv)
      assert length(items) >= 1
      [item | _] = items
      assert item.amount_minor == 1000
      assert item.currency == "usd"
      assert item.description == "Basic Plan"
      assert item.quantity == 1
      assert item.proration == false
      assert item.price_ref == "price_test_basic"
      assert is_map(item.data)
      assert item.stripe_id =~ ~r/^il_test_/
    end

    test "status paid -> :paid atom" do
      inv = StripeFixtures.invoice(%{"status" => "paid"})
      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
      assert attrs.status == :paid
    end

    test "status void -> :void atom" do
      inv = StripeFixtures.invoice(%{"status" => "void"})
      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
      assert attrs.status == :void
    end

    test "preserves full stripe map in data" do
      inv = StripeFixtures.invoice()
      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
      assert attrs.data == inv
    end

    test "projects automatic tax state and tax amount from string-keyed payloads" do
      inv =
        StripeFixtures.invoice(%{
          "automatic_tax" => %{"enabled" => true, "status" => "complete"},
          "tax" => nil,
          "total_details" => %{"amount_tax" => 175}
        })

      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
      assert attrs.automatic_tax == true
      assert attrs.automatic_tax_status == "complete"
      assert attrs.tax_minor == 175
    end

    test "falls back to 0 when automatic tax is enabled but no tax amount is present" do
      inv =
        StripeFixtures.invoice(%{
          "automatic_tax" => %{"enabled" => true, "status" => "requires_location_inputs"},
          "tax" => nil,
          "total_details" => %{}
        })

      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
      assert attrs.automatic_tax == true
      assert attrs.automatic_tax_status == "requires_location_inputs"
      assert attrs.tax_minor == 0
    end

    test "nil status defaults to :draft" do
      inv = StripeFixtures.invoice() |> Map.put("status", nil)
      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
      assert attrs.status == :draft
    end
  end

  describe "decompose/1 (atom-keyed Fake shape)" do
    test "handles atom-keyed invoices from Accrue.Processor.Fake" do
      fake_inv = %{
        id: "in_fake_00001",
        object: "invoice",
        status: :draft,
        amount_due: 2000,
        amount_paid: 0,
        amount_remaining: 2000,
        currency: "usd",
        created: DateTime.utc_now(),
        lines: %{
          object: "list",
          data: [
            %{
              id: "il_fake_1",
              object: "line_item",
              description: "Pro Plan",
              amount: 2000,
              currency: "usd",
              quantity: 1,
              period: %{start: 0, end: 0},
              proration: false,
              price: %{id: "price_pro"}
            }
          ]
        }
      }

      {:ok, %{invoice_attrs: attrs, item_attrs: items}} =
        InvoiceProjection.decompose(fake_inv)

      assert attrs.status == :draft
      assert attrs.amount_due_minor == 2000
      assert attrs.currency == "usd"
      assert attrs.automatic_tax == false
      assert attrs.automatic_tax_status == nil
      assert length(items) == 1
      assert hd(items).amount_minor == 2000
      assert hd(items).price_ref == "price_pro"
    end

    test "prefers atom-keyed total_details.amount_tax when tax field is absent" do
      fake_inv = %{
        id: "in_fake_00002",
        object: "invoice",
        status: :open,
        amount_due: 2000,
        amount_paid: 0,
        amount_remaining: 2000,
        currency: "usd",
        automatic_tax: %{enabled: true, status: "complete"},
        tax: nil,
        total_details: %{amount_tax: 225},
        lines: %{object: "list", data: []}
      }

      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(fake_inv)
      assert attrs.automatic_tax == true
      assert attrs.automatic_tax_status == "complete"
      assert attrs.tax_minor == 225
    end
  end
end
