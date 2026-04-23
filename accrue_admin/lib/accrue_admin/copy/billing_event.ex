defmodule AccrueAdmin.Copy.BillingEvent do
  @moduledoc false

  # --- Events index (EventsLive) — prefix billing_events_*

  def billing_events_page_title, do: "Events"

  def billing_events_breadcrumb_events, do: "Events"

  def billing_events_kpi_section_aria_label, do: "Event summary"

  def billing_events_kpi_label_ledger_rows, do: "Ledger rows"

  def billing_events_kpi_meta_total_append_only, do: "Total append-only events recorded locally"

  def billing_events_kpi_label_webhook_sourced, do: "Webhook sourced"

  def billing_events_kpi_delta_admin_suffix, do: " admin"

  def billing_events_kpi_meta_webhook_cause_chain, do: "Rows linked back to a webhook cause chain"

  def billing_events_kpi_label_last_24h, do: "Last 24h"

  def billing_events_kpi_delta_subject_types_suffix, do: " subject types"

  def billing_events_kpi_meta_recent_cross_resource, do: "Recent cross-resource billing activity"

  def billing_events_table_column_event, do: "Event"

  def billing_events_table_column_subject, do: "Subject"

  def billing_events_table_column_actor, do: "Actor"

  def billing_events_table_column_webhook_source, do: "Webhook source"

  def billing_events_table_column_when, do: "When"

  def billing_events_filter_label_search, do: "Search"

  def billing_events_filter_label_event_type, do: "Event type"

  def billing_events_filter_label_actor_type, do: "Actor type"

  def billing_events_filter_label_subject_type, do: "Subject type"

  def billing_events_filter_label_source_webhook_id, do: "Source webhook id"

  def billing_events_table_empty_title, do: "No billing events matched"

  def billing_events_table_empty_copy,
    do: "Loosen filters or trigger a subscription or invoice change, then refresh this index."

  def billing_events_apply_filters, do: "Apply filters"

  def billing_events_eyebrow_organization, do: "Organization activity feed"

  def billing_events_eyebrow_global, do: "Global activity feed"

  def billing_events_heading_organization, do: "Billing activity for the active organization"

  def billing_events_heading_global, do: "Append-only billing and admin activity"

  def billing_events_copy_organization,
    do:
      "This feed stays scoped to the active organization so linked webhook and admin activity can't reveal other billing owners."

  def billing_events_copy_global,
    do:
      "This complements the scoped subject timelines with one operations-wide ledger view over `accrue_events`."

  def billing_events_webhook_source_direct, do: "Direct"

  def billing_events_when_unknown, do: "Unknown"
end
