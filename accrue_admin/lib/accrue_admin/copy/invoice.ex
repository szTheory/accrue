defmodule AccrueAdmin.Copy.Invoice do
  @moduledoc false

  # Invoice list + detail (InvoicesLive, InvoiceLive) — Phase 54, ADM-08

  def invoices_index_empty_title, do: "No invoices for this organization yet"

  def invoices_index_empty_copy,
    do:
      "Invoices are created as Accrue records billing activity. If you expected invoices, adjust filters or confirm organization scope."

  def invoice_select_action_warning, do: "Select an invoice action before confirming."

  def invoice_pdf_open_info, do: "Open PDF now uses the shared invoice render path."

  def invoice_action_recorded_info, do: "Invoice action recorded."

  def invoices_page_title_index, do: "Invoices"

  def invoices_index_breadcrumb_invoices, do: "Invoices"

  def invoices_index_eyebrow, do: "Invoices"

  def invoices_index_headline, do: "Collections and invoice review"

  def invoices_index_body,
    do:
      "Inspect invoice state, open detail pages, and route high-risk state changes through the shared billing workflow and audit seams."

  def invoices_kpi_section_aria_label, do: "Invoice summary"

  def invoices_kpi_open_label, do: "Open"

  def invoices_kpi_open_meta, do: "Invoices still collecting payment"

  def invoices_kpi_paid_label, do: "Paid"

  def invoices_kpi_paid_meta, do: "Settled invoices in the local projection"

  def invoices_kpi_uncollectible_label, do: "Uncollectible"

  def invoices_kpi_uncollectible_void_delta_suffix, do: " void"

  def invoices_kpi_uncollectible_meta, do: "Operator-driven collection stops"

  def invoices_column_invoice, do: "Invoice"
  def invoices_column_customer, do: "Customer"
  def invoices_column_billing_signals, do: "Billing signals"
  def invoices_column_status, do: "Status"
  def invoices_column_balance, do: "Balance"
  def invoices_column_collection, do: "Collection"

  def invoices_card_customer, do: "Customer"

  def invoices_filter_search, do: "Search"
  def invoices_filter_status, do: "Status"
  def invoices_filter_customer_id, do: "Customer id"
  def invoices_filter_collection, do: "Collection"

  def invoices_filter_status_draft, do: "Draft"
  def invoices_filter_status_open, do: "Open"
  def invoices_filter_status_paid, do: "Paid"
  def invoices_filter_status_uncollectible, do: "Uncollectible"
  def invoices_filter_status_void, do: "Void"

  def invoices_filter_collection_automatic, do: "Automatic"
  def invoices_filter_collection_send_invoice, do: "Send invoice"

  def invoices_balance_word_due, do: "due"
  def invoices_balance_word_paid, do: "paid"
  def invoices_balance_word_remaining, do: "remaining"
  def invoices_balance_sep, do: " · "

  def invoices_balance_summary(due, paid, remaining) do
    sep = invoices_balance_sep()

    "#{due} #{invoices_balance_word_due()}#{sep}#{paid} #{invoices_balance_word_paid()}#{sep}#{remaining} #{invoices_balance_word_remaining()}"
  end

  def invoice_page_title_detail, do: "Invoice"

  def invoice_breadcrumb_invoices, do: "Invoices"

  def invoice_detail_eyebrow, do: "Invoice detail"

  def invoice_detail_due_prefix, do: "due "

  def invoice_detail_kpi_section_aria_label, do: "Invoice summary"

  def invoice_kpi_status_label, do: "Status"

  def invoice_kpi_amount_due_label, do: "Amount due"

  def invoice_kpi_amount_due_delta_suffix, do: " paid"

  def invoice_kpi_amount_remaining_meta_suffix, do: " remaining"

  def invoice_kpi_line_items_label, do: "Line items"

  def invoice_kpi_line_items_meta,
    do: "PDF preview stays on the Phase 6 invoice render path"

  def invoice_tax_risk_eyebrow, do: "Tax risk"

  def invoice_tax_risk_heading, do: "Invoice finalization needs tax-location recovery"

  def invoice_tax_disabled_reason_label, do: "Automatic tax disabled reason:"

  def invoice_tax_finalization_failure_label, do: "Finalization failure code:"

  def invoice_tax_recovery_body,
    do:
      "This view reflects local invoice state only. Repair the customer tax location, then retry finalization from Accrue."

  def invoice_actions_eyebrow, do: "Admin actions"

  def invoice_actions_heading, do: "Invoice workflow controls"

  def invoice_actions_body,
    do: "Actions run through the existing billing facade and record admin audit rows."

  def invoice_action_finalize, do: "Finalize invoice"
  def invoice_action_manual_pay, do: "Manual pay"
  def invoice_action_void, do: "Void invoice"
  def invoice_action_mark_uncollectible, do: "Mark uncollectible"

  def invoice_confirm_panel_label, do: "Confirm action"

  def invoice_confirm_action_verb, do: "Confirm"

  def invoice_confirm_cancel, do: "Cancel"

  def invoice_confirm_workflow_message(action_label, source_suffix),
    do: "#{action_label} will use the existing invoice workflow APIs.#{source_suffix}"

  def invoice_confirm_source_event_suffix(source_event_id),
    do: " Source event ##{source_event_id} will be linked."

  def invoice_pdf_section_eyebrow, do: "PDF"

  def invoice_pdf_heading, do: "Preview and download"

  def invoice_pdf_body,
    do:
      "Open PDF reuses `Accrue.Billing.render_invoice_pdf/2` and never invents a new storage path."

  def invoice_open_pdf_button, do: "Open PDF"

  def invoice_processor_pdf_link, do: "Processor PDF"

  def invoice_hosted_invoice_link, do: "Hosted invoice"

  def invoice_open_rendered_pdf_link, do: "Open rendered PDF"

  def invoice_download_rendered_pdf_link, do: "Download rendered PDF"

  def invoice_line_items_eyebrow, do: "Line items"

  def invoice_line_items_heading, do: "Invoice rows"

  def invoice_line_item_qty_prefix, do: "qty "

  def invoice_line_item_proration_suffix, do: " · proration"

  def invoice_line_item_period_separator, do: " to "

  def invoice_line_items_empty, do: "No line items are projected for this invoice yet."

  def invoice_timeline_eyebrow, do: "Timeline"

  def invoice_timeline_heading, do: "Invoice events"

  def invoice_timeline_label, do: "Invoice events"

  def invoice_timeline_empty, do: "No invoice-scoped events yet"

  def invoice_source_event_label, do: "Source event"

  def invoice_source_event_none, do: "None"

  def invoice_pdf_render_failed_prefix, do: "Could not render PDF: "

  def invoice_pdf_summary_processor_ready, do: "processor PDF ready"

  def invoice_pdf_summary_hosted_ready, do: "hosted invoice ready"

  def invoice_pdf_summary_render_on_demand, do: "render on demand"
end
