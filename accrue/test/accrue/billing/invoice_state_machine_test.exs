defmodule Accrue.Billing.InvoiceStateMachineTest do
  @moduledoc """
  D3-17 dual-changeset pattern. `changeset/2` enforces legal user-path
  transitions; `force_status_changeset/2` bypasses validation because
  Stripe (via webhook reconcile) is canonical.
  """
  use ExUnit.Case, async: true

  alias Accrue.Billing.Invoice

  test "draft to open is legal" do
    cs = Invoice.changeset(%Invoice{status: :draft}, %{status: :open})
    assert cs.valid?
  end

  test "open to paid is legal" do
    cs = Invoice.changeset(%Invoice{status: :open}, %{status: :paid})
    assert cs.valid?
  end

  test "draft to paid is illegal via user path" do
    cs = Invoice.changeset(%Invoice{status: :draft}, %{status: :paid})
    refute cs.valid?

    assert {msg, _} = cs.errors[:status]
    assert msg =~ "illegal user-path transition from draft to paid"
  end

  test "paid to open is illegal" do
    cs = Invoice.changeset(%Invoice{status: :paid}, %{status: :open})
    refute cs.valid?
  end

  test "force_status_changeset bypasses all transitions" do
    cs = Invoice.force_status_changeset(%Invoice{status: :paid}, %{status: :draft})
    assert cs.valid?
  end
end
