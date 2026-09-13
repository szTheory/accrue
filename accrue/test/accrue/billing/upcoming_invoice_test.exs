defmodule Accrue.Billing.UpcomingInvoiceTest do
  @moduledoc """
  BILL-10 / D3-19: `preview_upcoming_invoice/2` returns a non-persistent
  `%Accrue.Billing.UpcomingInvoice{}` snapshot with Money-typed lines.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, UpcomingInvoice}

  test "preview_upcoming_invoice returns %UpcomingInvoice{} with lines" do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_upcoming",
        email: "upcoming@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")

    assert {:ok, %UpcomingInvoice{} = preview} =
             Billing.preview_upcoming_invoice(sub,
               new_price_id: "price_pro",
               proration: :create_prorations
             )

    assert is_list(preview.lines)
    assert %Accrue.Money{} = preview.total
    assert %Accrue.Money{} = preview.subtotal
  end

  test "preview remains available after supported quantity changes on the active-change lane" do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_upcoming_quantity",
        email: "upcoming-quantity@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    {:ok, updated_sub} = Billing.update_quantity(sub, 3)

    assert {:ok, %UpcomingInvoice{} = preview} =
             Billing.preview_upcoming_invoice(updated_sub, proration: :create_prorations)

    assert is_list(preview.lines)
    assert %Accrue.Money{} = preview.total
    assert %Accrue.Money{} = preview.subtotal
  end

  test "forwards proration_date in subscription_details" do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_preview_date",
        email: "preview-date@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    proration_date = 1_789_260_000

    assert {:ok, %UpcomingInvoice{}} =
             Billing.preview_upcoming_invoice(sub,
               new_price_id: "price_pro",
               proration: :create_prorations,
               proration_date: proration_date
             )

    assert Enum.any?(Accrue.Processor.Fake.calls(), fn
             {:create_invoice_preview,
              [%{subscription_details: %{proration_date: ^proration_date}}, _opts]} ->
               true

             _ ->
               false
           end)
  end

  test "projects Dahlia nested proration and pricing fields" do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_dahlia_preview",
        email: "dahlia-preview@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")

    Accrue.Processor.Fake.stub(:create_invoice_preview, fn _params, _opts ->
      {:ok,
       %{
         currency: "usd",
         lines: %{
           data: [
             %LatticeStripe.Invoice.LineItem{
               amount: 1_000,
               description: "Dahlia proration",
               extra: %{
                 "parent" => %{
                   "invoice_item_details" => %{"proration" => true}
                 },
                 "pricing" => %{
                   "price_details" => %{"price" => "price_pro"}
                 }
               }
             }
           ]
         }
       }}
    end)

    assert {:ok, %UpcomingInvoice{lines: [line]}} =
             Billing.preview_upcoming_invoice(sub,
               new_price_id: "price_pro",
               proration: :create_prorations
             )

    assert line.proration?
    assert line.price_id == "price_pro"
  end
end
