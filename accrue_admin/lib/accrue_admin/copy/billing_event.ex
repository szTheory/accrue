defmodule AccrueAdmin.Copy.BillingEvent do
  @moduledoc false

  # --- Events index (EventsLive) — prefix billing_events_*

  def billing_events_page_title, do: "Events"

  def billing_events_breadcrumb_events, do: "Events"

  def events_list_heading, do: "Trace billing activity"

  def events_list_subtitle, do: "Read the append-only billing event ledger."

  def events_list_first_run_empty_title, do: "No billing events yet."

  def events_list_first_run_empty_body,
    do: "Events appear when billing state changes are recorded."

  def events_list_filtered_empty_title, do: "No ledger rows match these filters."

  def events_list_filtered_empty_body,
    do: "Clear filters or adjust actor and source filters to see ledger rows."

  def events_list_loading_label, do: "Loading billing events."

  def events_list_default_lens_label, do: "All ledger"

  def events_list_all_lens_label, do: "All ledger"

  def events_list_admin_changes_label, do: "Admin changes"

  def events_list_result_label_pair, do: {"event", "events"}

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

  def billing_events_heading_organization, do: "Event log"

  def billing_events_heading_global, do: "Event log"

  def billing_events_copy_organization,
    do:
      "An append-only record of every billing and admin action in this organization. Filter by actor or subject to trace who did what, and when."

  def billing_events_copy_global,
    do:
      "An append-only record of every billing and admin action across all organizations. Filter by actor or subject to trace who did what, and when."

  def billing_events_webhook_source_direct, do: "Direct"

  def billing_events_when_unknown, do: "Unknown"

  def billing_event_not_found,
    do: "Event not found. Open the events list and confirm owner scope before retrying."

  # --- Event detail (EventLive) — prefix event_detail_*

  def event_detail_eyebrow, do: "Event detail"

  def event_detail_section_heading, do: "Event details"
end
