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
end
