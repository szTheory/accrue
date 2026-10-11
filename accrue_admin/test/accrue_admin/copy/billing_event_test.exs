defmodule AccrueAdmin.Copy.BillingEventTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.Copy

  test "events index empty state matches UI-SPEC" do
    assert Copy.billing_events_table_empty_title() == "No billing events matched"

    assert String.starts_with?(
             Copy.billing_events_table_empty_copy(),
             "Loosen filters or trigger"
           )
  end

  test "events KPI labels" do
    assert Copy.billing_events_kpi_label_ledger_rows() == "Ledger rows"
    assert Copy.billing_events_kpi_label_webhook_sourced() == "Webhook sourced"
  end

  test "events filter toolbar CTA" do
    assert Copy.billing_events_apply_filters() == "Apply filters"
  end

  test "billing events remain distinct from webhook deliveries" do
    assert Copy.events_list_heading() == "Trace billing activity"
    assert Copy.events_list_result_label_pair() == {"event", "events"}
    assert Copy.webhooks_list_result_label_pair() == {"webhook delivery", "webhook deliveries"}
    assert Copy.webhooks_retry_cancel_label() == "Keep deliveries"
  end

  test "confirmed event keys describe the operation without changing raw keys" do
    assert Copy.billing_event_label("customer.updated") == "Customer updated"
    assert Copy.billing_event_label("customer.local_updated") == "Customer record updated locally"
    assert Copy.billing_event_label("webhook.received") == "Webhook received"
    assert Copy.billing_event_label("webhook.replay_requested") == "Webhook replay requested"
  end

  test "unknown and missing event keys stay neutral and honest" do
    assert Copy.billing_event_label("provider.event_with_unicode_λ") == "Billing event"
    assert Copy.billing_event_label("") == "Event details unavailable"
    assert Copy.billing_event_label(nil) == "Event details unavailable"
    assert Copy.billing_event_label(:malformed) == "Event details unavailable"
  end
end
