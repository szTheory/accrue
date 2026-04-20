defmodule AccrueAdmin.Copy do
  @moduledoc """
  Tier A host-contract copy for admin surfaces (Phase 27).

  Strings here are the single source of truth for operator-facing empty states
  and related chrome described in `.planning/phases/27-microcopy-and-operator-strings/27-CONTEXT.md`.
  """

  def data_table_default_empty_title, do: "Nothing in this list yet"

  def data_table_default_empty_copy,
    do:
      "Billing records appear here when they match this view. If you expected rows, check filters or organization scope."

  def customers_index_empty_title, do: "No customers for this organization yet"

  def customers_index_empty_copy,
    do:
      "Customers show up when someone pays through Accrue for this organization. If you expected a customer, widen filters or confirm you are in the right organization."

  def subscriptions_index_empty_title, do: "No subscriptions for this organization yet"

  def subscriptions_index_empty_copy,
    do:
      "Subscriptions appear when billing is active for this organization. If you expected one, adjust filters or confirm organization scope."

  def invoices_index_empty_title, do: "No invoices for this organization yet"

  def invoices_index_empty_copy,
    do:
      "Invoices are created as Accrue records billing activity. If you expected invoices, adjust filters or confirm organization scope."

  def charges_index_empty_title, do: "No charges for this organization yet"

  def charges_index_empty_copy,
    do:
      "Charges appear when payments are recorded for this organization. If you expected charges, adjust filters or confirm organization scope."
end
