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
end
