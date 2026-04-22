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

  def step_up_submit_label, do: "Verify identity"

  @doc "Step-up modal eyebrow label."
  def step_up_eyebrow, do: "Sensitive action"

  @doc "Step-up modal title."
  def step_up_title, do: "Step-up required"

  @doc "Default challenge body when none is supplied."
  def step_up_default_challenge_message, do: "Confirm your identity to continue."

  @doc "Step-up dismiss control label."
  def step_up_cancel_label, do: "Cancel"

  def customers_index_table_caption, do: "Searchable customer projections"

  def webhooks_index_table_caption, do: "Replay, inspect, and trace webhook delivery"

  # --- Operator dashboard (DashboardLive) — Phase 35, OPS-05

  def dashboard_breadcrumb_home, do: "Dashboard"

  def dashboard_chrome_eyebrow, do: "Billing health"

  def dashboard_display_headline, do: "Local billing projections at a glance"

  def dashboard_page_copy_primary,
    do:
      "Dashboard KPIs are sourced from `accrue_*` tables, the event ledger, and webhook projections already stored locally."

  def dashboard_kpi_section_aria_label, do: "Billing KPI summary"

  def dashboard_activity_section_aria_label, do: "Dashboard activity"

  def dashboard_kpi_customers_label, do: "Customers"

  def dashboard_kpi_active_subscriptions_label, do: "Active subscriptions"

  def dashboard_kpi_open_invoice_balance_label, do: "Open invoice balance"

  def dashboard_kpi_webhook_backlog_label, do: "Webhook backlog"

  def dashboard_kpi_customers_meta, do: "Total local customer records"

  def dashboard_kpi_active_subscriptions_meta, do: "Canonical active + trialing predicates"

  def dashboard_kpi_open_invoice_balance_meta,
    do: "Remaining amount due from local invoice projections"

  def dashboard_kpi_webhook_backlog_meta,
    do: "Failed + dead webhook rows waiting for operator attention"

  def dashboard_meter_reporting_failures_label, do: "Meter reporting failures"

  def dashboard_meter_reporting_failures_meta,
    do:
      "Counts accrue_meter_events rows in stripe_status=\"failed\" (terminal meter reporting failures)."

  def dashboard_meter_reporting_failures_aria_label,
    do: "Open billing event ledger; events list is not limited to meter rows."

  def dashboard_kpi_customers_aria_label, do: "Open customers list"

  def dashboard_kpi_subscriptions_aria_label, do: "Open subscriptions list"

  def dashboard_kpi_invoices_aria_label, do: "Open invoices list"

  def dashboard_kpi_webhooks_aria_label, do: "Open webhooks list"

  def dashboard_kpi_active_subscriptions_canceling_suffix, do: " canceling"

  def dashboard_kpi_open_invoice_delta_suffix, do: " open invoices"

  def dashboard_kpi_webhook_events_suffix, do: " events in 24h"

  def dashboard_activity_event_ledger_eyebrow, do: "Event ledger"

  def dashboard_activity_recent_local_heading, do: "Recent local activity"

  def dashboard_activity_webhook_health_eyebrow, do: "Webhook health"

  def dashboard_activity_projection_pipeline_heading, do: "Projection pipeline"

  def dashboard_timeline_events_label, do: "Recent event ledger rows"

  def dashboard_timeline_events_empty, do: "No local events recorded yet"

  def dashboard_timeline_webhooks_label, do: "Recent webhook processing rows"

  def dashboard_timeline_webhooks_empty, do: "No webhook rows recorded yet"
end
