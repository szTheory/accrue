defmodule Accrue.Billing.InvoiceItemsTest do
  @moduledoc """
  Plan 05 Task 2: InvoiceItem child rows are decomposed from
  `lines.data` and upserted by `stripe_id` inside the same
  `Repo.transact/2` as the parent Invoice update — repeat workflow
  calls must be idempotent (no duplicate InvoiceItem rows).
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Invoice, InvoiceItem, InvoiceProjection}

  setup do
    {:ok, cus} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_inv_items",
        email: "inv-items@example.com"
      })
      |> Repo.insert()

    %{cus: cus}
  end

  test "decompose + insert creates InvoiceItem rows linked to invoice",
       %{cus: cus} do
    stripe_inv = StripeFixtures.invoice()

    {:ok, %{invoice_attrs: attrs, item_attrs: item_attrs_list}} =
      InvoiceProjection.decompose(stripe_inv)

    {:ok, inv} =
      %Invoice{customer_id: cus.id, processor: "fake"}
      |> Invoice.force_status_changeset(attrs)
      |> Repo.insert()

    for ia <- item_attrs_list do
      ia = Map.put(ia, :invoice_id, inv.id)

      assert {:ok, %InvoiceItem{}} =
               %InvoiceItem{}
               |> InvoiceItem.changeset(ia)
               |> Repo.insert()
    end

    inv = Repo.preload(inv, :items)
    assert length(inv.items) >= 1
    assert hd(inv.items).amount_minor == 1000
    assert hd(inv.items).price_ref == "price_test_basic"
  end

  test "upsert via workflow updates existing item by stripe_id (idempotent)",
       %{cus: cus} do
    # Seed invoice via Fake
    {:ok, stripe_inv} =
      Fake.create_invoice(%{customer: cus.processor_id, amount_due: 2500}, [])

    # Build local Invoice row at :draft, mimicking the steady state
    {:ok, inv} =
      %Invoice{customer_id: cus.id, processor: "fake"}
      |> Invoice.force_status_changeset(%{
        processor_id: stripe_inv.id,
        status: :draft,
        currency: "usd"
      })
      |> Repo.insert()

    # First finalize: creates items (if the Fake's create_invoice returned
    # any lines). Capture count.
    {:ok, _} = Billing.finalize_invoice(inv)
    count_after_first = Repo.aggregate(InvoiceItem, :count, :id)

    # Re-fetch the row and void it — same stripe_id lines should upsert,
    # not duplicate. (The Fake's void action preserves lines as-is.)
    inv2 = Repo.get!(Invoice, inv.id)
    {:ok, _} = Billing.void_invoice(inv2)
    count_after_second = Repo.aggregate(InvoiceItem, :count, :id)

    assert count_after_second == count_after_first
  end
end
