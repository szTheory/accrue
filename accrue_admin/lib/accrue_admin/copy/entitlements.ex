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
end
