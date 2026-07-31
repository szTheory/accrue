defmodule AccrueAdmin.Copy.Entitlements do
  @moduledoc false

  @doc false
  def section_title, do: "Active entitlements"

  @doc false
  def drift_section_title, do: "Plan mapping"

  @doc false
  def active_plans_label, do: "Active plans"

  @doc false
  def features_label, do: "Granted features"

  @doc false
  def quantities_label, do: "Seats & limits"

  @doc false
  def grace_label, do: "In grace period"

  @doc false
  def unmapped_badge, do: "⚠ Unmapped plan"

  @doc false
  def unmapped_hint,
    do: "This subscription's price isn't in your :plans config, so the resolver drops it."

  @doc false
  def empty_title, do: "No active entitlements"

  @doc false
  def empty_copy,
    do:
      "This customer has no entitling subscriptions, so no plans or features are currently granted."

  @doc false
  def no_drift_copy, do: "All active subscriptions map to a configured plan."

  @doc false
  def raw_map_label, do: "Show resolved map"

  @doc false
  def error_copy,
    do:
      "Entitlements couldn't be resolved for this customer right now. The gate fails closed, so no access is granted on error — retry shortly."

  @doc false
  def canonical_group_title, do: "Accrue access (canonical)"

  @doc false
  def advisory_group_title, do: "Stripe observation (advisory)"

  @doc false
  def advisory_boundary, do: "Stripe advisory snapshot — does not change access."

  @doc false
  def advisory_recorded_title, do: "Snapshot recorded"

  @doc false
  def advisory_disabled_title, do: "Not enabled"

  @doc false
  def advisory_disabled_copy, do: "Stripe advisory sync is off for this host. Local access above is unchanged."

  @doc false
  def advisory_count(count), do: "#{count} entitlements observed"

  @doc false
  def advisory_observed_at(timestamp), do: "Observed #{DateTime.to_iso8601(timestamp)}"

  @doc false
  def advisory_source_label, do: "Source"

  @doc false
  def advisory_source_pull, do: "Pull refresh"

  @doc false
  def advisory_completeness_label, do: "Completeness"

  @doc false
  def advisory_complete, do: "Complete"

  @doc false
  def advisory_observed_entitlements_label, do: "Observed entitlements"

  @doc false
  def advisory_lookup_keys_label, do: "Lookup keys"

  @doc false
  def advisory_observed_at_label, do: "Observed at"

  @doc false
  def advisory_unavailable_title, do: "Snapshot unavailable"

  @doc false
  def advisory_source_unavailable, do: "Source unavailable"

  @doc false
  def advisory_incomplete, do: "Incomplete"

  @doc false
  def advisory_unavailable, do: "Unavailable"
end
