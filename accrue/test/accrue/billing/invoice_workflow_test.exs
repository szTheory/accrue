defmodule Accrue.Billing.InvoiceWorkflowTest do
  @moduledoc """
  Plan 05 Task 2: `Accrue.Billing.{finalize,void,pay,mark_uncollectible,
  send}_invoice/2` drive the D3-18 one-shape workflow — Stripe call,
  decompose, user-path changeset (enforces transitions), upsert items,
  emit event, all in one `Repo.transact/2`.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Invoice
  alias Accrue.Events.Event

  setup do
    {:ok, cus} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_inv_workflow",
        email: "inv-workflow@example.com"
      })
      |> Repo.insert()

    {:ok, stripe_inv} =
      Fake.create_invoice(%{customer: cus.processor_id, amount_due: 1500}, [])

    {:ok, inv} =
      %Invoice{customer_id: cus.id, processor: "fake"}
      |> Invoice.force_status_changeset(%{
        processor_id: stripe_inv.id,
        status: :draft,
        currency: "usd",
        amount_due_minor: 1500,
        total_minor: 1500
      })
      |> Repo.insert()

    %{cus: cus, inv: inv, stripe_id: stripe_inv.id}
  end

  test "finalize_invoice transitions :draft -> :open and preloads items", %{inv: inv} do
    assert {:ok, updated} = Billing.finalize_invoice(inv)
    assert updated.status == :open
    assert is_list(updated.items)
  end

  test "finalize_invoice records accrue_events row in same transaction", %{inv: inv} do
    pre_count = Repo.aggregate(Event, :count, :id)
    assert {:ok, _} = Billing.finalize_invoice(inv)
    post_count = Repo.aggregate(Event, :count, :id)
    assert post_count == pre_count + 1
  end

  test "void_invoice transitions to :void from :draft", %{inv: inv} do
    assert {:ok, updated} = Billing.void_invoice(inv)
    assert updated.status == :void
  end

  test "pay_invoice :open -> :paid (requires finalize first)", %{inv: inv} do
    assert {:ok, open_inv} = Billing.finalize_invoice(inv)
    assert open_inv.status == :open
    assert {:ok, paid} = Billing.pay_invoice(open_inv)
    assert paid.status == :paid
  end

  test "mark_uncollectible :open -> :uncollectible", %{inv: inv} do
    assert {:ok, open_inv} = Billing.finalize_invoice(inv)
    assert {:ok, updated} = Billing.mark_uncollectible(open_inv)
    assert updated.status == :uncollectible
  end

  test "send_invoice returns {:ok, invoice}", %{inv: inv} do
    assert {:ok, sent} = Billing.send_invoice(inv)
    assert %Invoice{} = sent
  end

  test "finalize_invoice! bang variant returns raw struct", %{inv: inv} do
    assert %Invoice{status: :open} = Billing.finalize_invoice!(inv)
  end

  test "illegal user-path transition (draft -> paid) returns changeset error",
       %{inv: inv} do
    # Don't finalize first — calling pay_invoice on a :draft row forces an
    # illegal user-path transition. The Fake returns :paid, projection
    # decomposes to :paid, Invoice.changeset/2 rejects the transition.
    result = Billing.pay_invoice(inv)

    case result do
      {:error, %Ecto.Changeset{} = cs} ->
        assert Keyword.has_key?(cs.errors, :status)
        msg = cs.errors[:status] |> elem(0)
        assert msg =~ "illegal"

      {:ok, %Invoice{}} ->
        flunk("expected user-path transition to reject draft -> paid")
    end
  end

  test "InvoiceActions does NOT CALL force_status_changeset (source audit)" do
    # The webhook bypass exists for Plan 07, not for user-path actions.
    # A docstring reference is allowed; an actual call is not.
    src = File.read!("lib/accrue/billing/invoice_actions.ex")
    refute src =~ "Invoice.force_status_changeset"
    refute src =~ ~r/\|>\s*force_status_changeset/
  end
end
