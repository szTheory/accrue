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

  def subscription_select_action_warning, do: "Select an action before confirming."

  def subscription_action_recorded_info, do: "Subscription action recorded."

  def invoice_select_action_warning, do: "Select an invoice action before confirming."

  def invoice_pdf_open_info, do: "Open PDF now uses the shared invoice render path."

  def invoice_action_recorded_info, do: "Invoice action recorded."

  def payment_processor_action_warning(payment_intent),
    do: "Processor requires action: " <> inspect(payment_intent)

  def charge_prepare_refund_warning, do: "Prepare a refund before confirming."

  def charge_refund_created_info,
    do: "Refund created with fee-aware fields from the billing facade."

  def customer_detail_no_subscriptions, do: "No subscriptions for this customer yet."

  def customer_detail_no_invoices, do: "No invoices for this customer yet."

  def webhooks_index_empty_title, do: "No webhook deliveries for this organization yet"

  def webhooks_index_empty_copy,
    do:
      "Stripe events appear here after they are recorded for this organization. If you expected deliveries, check filters or confirm your endpoint is receiving traffic."

  def webhooks_bulk_replay_confirm_question(count),
    do: "Replay #{count} failed or dead webhook rows for the active organization?"

  def webhooks_bulk_no_rows_warning,
    do: "No failed or dead-lettered webhook rows match the current filters."
end
