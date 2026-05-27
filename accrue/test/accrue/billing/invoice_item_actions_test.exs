defmodule Accrue.Billing.InvoiceItemActionsTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Invoice, InvoiceItem}
  alias Accrue.Events.Event

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_invoice_items",
        email: "invoice-items@example.com"
      })
      |> Repo.insert()

    {:ok, stripe_invoice} =
      Fake.create_invoice(%{customer: customer.processor_id, amount_due: 1500}, [])

    {:ok, invoice} =
      %Invoice{customer_id: customer.id, processor: "fake"}
      |> Invoice.force_status_changeset(%{
        processor_id: stripe_invoice.id,
        status: :draft,
        currency: "usd",
        subtotal_minor: 1500,
        total_minor: 1500,
        amount_due_minor: 1500,
        amount_remaining_minor: 1500
      })
      |> Repo.insert()

    {:ok, open_invoice} =
      %Invoice{customer_id: customer.id, processor: "fake"}
      |> Invoice.force_status_changeset(%{
        processor_id: "in_fake_open_fixture",
        status: :open,
        currency: "usd",
        subtotal_minor: 1500,
        total_minor: 1500,
        amount_due_minor: 1500,
        amount_remaining_minor: 1500
      })
      |> Repo.insert()

    %{invoice: invoice, open_invoice: open_invoice}
  end

  describe "add_invoice_item/3" do
    test "adds a manual item to a draft invoice and updates totals", %{invoice: invoice} do
      assert {:ok, updated} =
               Billing.add_invoice_item(invoice, %{
                 amount: 250,
                 currency: "usd",
                 description: "Manual support credit"
               })

      assert updated.subtotal_minor == 1750
      assert updated.total_minor == 1750
      assert updated.amount_due_minor == 1750

      updated = Repo.preload(updated, :items, force: true)
      assert length(updated.items) == 1

      [item] = updated.items
      assert item.amount_minor == 250
      assert item.description == "Manual support credit"
      assert is_binary(item.stripe_id)
    end

    test "records an invoice.item_added event", %{invoice: invoice} do
      assert {:ok, updated} =
               Billing.add_invoice_item(invoice, %{
                 amount: 300,
                 currency: "usd",
                 description: "Operator adjustment"
               })

      event =
        Repo.one!(
          from(e in Event,
            where: e.type == "invoice.item_added" and e.subject_id == ^updated.id
          )
        )

      assert (event.data["source"] || event.data[:source]) == "api"
      assert event.data["item_processor_id"] || event.data[:item_processor_id]
    end

    test "rejects non-draft invoices", %{open_invoice: open_invoice} do
      assert {:error, %Ecto.Changeset{} = changeset} =
               Billing.add_invoice_item(open_invoice, %{
                 amount: 200,
                 currency: "usd",
                 description: "Should fail"
               })

      assert Keyword.has_key?(changeset.errors, :status)
    end
  end

  describe "remove_invoice_item/3" do
    test "removes a manual item from a draft invoice and updates totals", %{invoice: invoice} do
      {:ok, updated} =
        Billing.add_invoice_item(invoice, %{
          amount: 400,
          currency: "usd",
          description: "Temporary fee"
        })

      [item] = Repo.preload(updated, :items, force: true).items

      assert {:ok, removed} = Billing.remove_invoice_item(updated, item)
      assert removed.subtotal_minor == 1500
      assert removed.total_minor == 1500
      assert removed.amount_due_minor == 1500
      assert Repo.aggregate(InvoiceItem, :count, :id) == 0
    end

    test "records an invoice.item_removed event", %{invoice: invoice} do
      {:ok, updated} =
        Billing.add_invoice_item(invoice, %{
          amount: 400,
          currency: "usd",
          description: "Temporary fee"
        })

      [item] = Repo.preload(updated, :items, force: true).items
      assert {:ok, removed} = Billing.remove_invoice_item(updated, item)

      event =
        Repo.one!(
          from(e in Event,
            where: e.type == "invoice.item_removed" and e.subject_id == ^removed.id
          )
        )

      assert (event.data["item_id"] || event.data[:item_id]) == item.id
      assert (event.data["item_processor_id"] || event.data[:item_processor_id]) == item.stripe_id
    end

    test "rejects non-draft invoices", %{invoice: invoice, open_invoice: open_invoice} do
      {:ok, updated} =
        Billing.add_invoice_item(invoice, %{
          amount: 125,
          currency: "usd",
          description: "Removable"
        })

      [item] = Repo.preload(updated, :items, force: true).items

      assert {:error, %Ecto.Changeset{} = changeset} =
               Billing.remove_invoice_item(open_invoice, item)

      assert Keyword.has_key?(changeset.errors, :status)
    end
  end
end
