defmodule Accrue.Billing.DiscountDenormalizationTest do
  @moduledoc """
  Phase 4 Plan 05 (BILL-28) — webhook denormalization of Stripe's
  discount fields into local `accrue_invoices.discount_minor` +
  `total_discount_amounts` and `accrue_subscriptions.discount_id`.
  Stripe is canonical; Accrue mirrors, never computes.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Invoice, InvoiceProjection, SubscriptionProjection}
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_discount"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "InvoiceProjection.decompose/1 — discount fields" do
    test "extracts discount_minor as the sum of total_discount_amounts" do
      fixture =
        StripeFixtures.invoice(%{
          "total_discount_amounts" => [
            %{"amount" => 500, "discount" => "di_1"},
            %{"amount" => 250, "discount" => "di_2"}
          ]
        })

      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(fixture)

      assert attrs.discount_minor == 750
      assert %{"data" => list} = attrs.total_discount_amounts
      assert length(list) == 2
    end

    test "empty/missing total_discount_amounts yields %{data: []} and nil discount_minor" do
      fixture = StripeFixtures.invoice()
      {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(fixture)

      assert attrs.total_discount_amounts == %{"data" => []}
      assert attrs.discount_minor == nil
    end
  end

  describe "Invoice.force_discount_changeset/2" do
    test "does not validate negative discount_minor (Stripe canonical)" do
      cs =
        Invoice.force_discount_changeset(%Invoice{lock_version: 1}, %{
          discount_minor: -999
        })

      assert cs.valid?
      assert Ecto.Changeset.get_change(cs, :discount_minor) == -999
    end

    test "preserves existing values when attrs omit the keys" do
      cs =
        Invoice.force_discount_changeset(
          %Invoice{discount_minor: 500, total_discount_amounts: %{"foo" => 1}, lock_version: 1},
          %{}
        )

      assert cs.valid?
      refute Map.has_key?(cs.changes, :discount_minor)
    end
  end

  describe "webhook reduce_invoice — discount denormalization" do
    test "invoice.finalized with total_discount_amounts sets discount_minor + mirror",
         %{customer: customer} do
      fixture =
        StripeFixtures.invoice(%{
          "customer" => customer.processor_id,
          "status" => "open",
          "total_discount_amounts" => [
            %{"amount" => 500, "discount" => "di_123"}
          ]
        })

      Accrue.Processor.Fake.stub(:retrieve_invoice, fn _id, _opts -> {:ok, fixture} end)

      event = StripeFixtures.webhook_event("invoice.finalized", fixture)
      assert {:ok, %Invoice{} = invoice} = DefaultHandler.handle(event)

      assert invoice.discount_minor == 500
      assert %{"data" => list} = invoice.total_discount_amounts
      assert length(list) == 1
    end

    test "invoice.finalized re-projects and overwrites prior discount values",
         %{customer: customer} do
      {:ok, existing} =
        %Invoice{customer_id: customer.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: "in_fake_reproj",
          discount_minor: 9999,
          total_discount_amounts: %{"stale" => true}
        })
        |> Repo.insert()

      fixture =
        StripeFixtures.invoice(%{
          "id" => existing.processor_id,
          "customer" => customer.processor_id,
          "total_discount_amounts" => [
            %{"amount" => 200, "discount" => "di_fresh"}
          ]
        })

      Accrue.Processor.Fake.stub(:retrieve_invoice, fn _id, _opts -> {:ok, fixture} end)

      event = StripeFixtures.webhook_event("invoice.finalized", fixture)
      assert {:ok, %Invoice{} = invoice} = DefaultHandler.handle(event)

      assert invoice.discount_minor == 200
    end

    test "invoice.finalized with no discounts yields [] and nil discount_minor",
         %{customer: customer} do
      fixture =
        StripeFixtures.invoice(%{
          "customer" => customer.processor_id,
          "status" => "open"
        })

      Accrue.Processor.Fake.stub(:retrieve_invoice, fn _id, _opts -> {:ok, fixture} end)

      event = StripeFixtures.webhook_event("invoice.finalized", fixture)
      assert {:ok, %Invoice{} = invoice} = DefaultHandler.handle(event)

      assert invoice.discount_minor in [nil, 0]
      assert invoice.total_discount_amounts == %{"data" => []}
    end
  end

  describe "SubscriptionProjection — discount_id" do
    test "extracts discount_id from nested %{id: _}" do
      fixture = StripeFixtures.subscription_created(%{"discount" => %{"id" => "di_abc"}})
      {:ok, attrs} = SubscriptionProjection.decompose(fixture)
      assert attrs.discount_id == "di_abc"
    end

    test "handles string-shaped discount (bare id)" do
      fixture = StripeFixtures.subscription_created(%{"discount" => "di_plain"})
      {:ok, attrs} = SubscriptionProjection.decompose(fixture)
      assert attrs.discount_id == "di_plain"
    end

    test "nil discount yields nil discount_id" do
      fixture = StripeFixtures.subscription_created()
      {:ok, attrs} = SubscriptionProjection.decompose(fixture)
      assert attrs.discount_id == nil
    end
  end
end
