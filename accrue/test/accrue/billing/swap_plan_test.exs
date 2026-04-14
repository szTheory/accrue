defmodule Accrue.Billing.SwapPlanTest do
  @moduledoc """
  D3-22: `:proration` is REQUIRED on every swap_plan/3 call. Accrue
  NEVER inherits Stripe defaults.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_swap",
        email: "swap@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    %{customer: customer, sub: sub}
  end

  test "missing :proration raises ArgumentError with exact D3-22 text", %{sub: sub} do
    assert_raise ArgumentError, ~r/requires an explicit :proration option/, fn ->
      Billing.swap_plan(sub, "price_pro", [])
    end
  end

  test "proration :create_prorations succeeds", %{sub: sub} do
    assert {:ok, updated} = Billing.swap_plan(sub, "price_pro", proration: :create_prorations)
    assert updated.id == sub.id
  end

  test "proration :none succeeds", %{sub: sub} do
    assert {:ok, _} = Billing.swap_plan(sub, "price_pro", proration: :none)
  end

  test "proration :always_invoice succeeds", %{sub: sub} do
    assert {:ok, _} = Billing.swap_plan(sub, "price_pro", proration: :always_invoice)
  end

  test "invalid :proration value raises ArgumentError", %{sub: sub} do
    assert_raise ArgumentError, fn ->
      Billing.swap_plan(sub, "price_pro", proration: :invalid)
    end
  end
end
