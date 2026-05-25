defmodule Accrue.TestSupport.TelemetryOpsInventory do
  @moduledoc false

  @doc false
  def expected_ops_events do
    [
      [:accrue, :ops, :revenue_loss],
      [:accrue, :ops, :dunning_exhaustion],
      [:accrue, :ops, :discount_mapping_invalid],
      [:accrue, :ops, :incomplete_expired],
      [:accrue, :ops, :charge_failed],
      [:accrue, :ops, :customer_projection_sync_failed],
      [:accrue, :ops, :meter_reporting_failed],
      [:accrue, :ops, :metered_renewal_stale_repaired],
      [:accrue, :ops, :metered_missing_definition],
      [:accrue, :ops, :metered_charge_awaiting_payment_method],
      [:accrue, :ops, :metered_charge_failed_exhausted],
      [:accrue, :ops, :webhook_dlq, :dead_lettered],
      [:accrue, :ops, :webhook_dlq, :replay],
      [:accrue, :ops, :webhook_dlq, :prune],
      [:accrue, :ops, :pdf_adapter_unavailable],
      [:accrue, :ops, :events_upcast_failed],
      [:accrue, :ops, :connect_account_deauthorized],
      [:accrue, :ops, :connect_capability_lost],
      [:accrue, :ops, :connect_payout_failed],
      [:accrue, :ops, :entitlement_summary_truncated],
      [:accrue, :ops, :dunning_campaign_started],
      [:accrue, :ops, :dunning_step_sent],
      [:accrue, :ops, :dunning_recovered],
      [:accrue, :ops, :dunning_exhausted]
    ]
  end

  @doc false
  def not_wired_first_party_emits do
    MapSet.new([
      [:accrue, :ops, :revenue_loss],
      [:accrue, :ops, :incomplete_expired],
      [:accrue, :ops, :charge_failed]
    ])
  end
end
