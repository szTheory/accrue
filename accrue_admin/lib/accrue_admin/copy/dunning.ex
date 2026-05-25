defmodule AccrueAdmin.Copy.Dunning do
  @moduledoc false

  # Read-only dunning-state panel (SubscriptionLive) — Phase 129, DUN-07 / SC#2.
  #
  # Operator-facing strings for the admin subscription-detail dunning panel.
  # Wording is the UI-SPEC contract ("Copywriting Contract → admin read-only
  # dunning-state panel"); function names are discretion (D-13). Every visible
  # string in the panel routes through these defs so the template carries no
  # hardcoded operator copy.

  alias Accrue.Billing.Subscription

  def dunning_panel_eyebrow, do: "DUNNING"

  def dunning_panel_title, do: "Dunning campaign"

  def dunning_started_label, do: "Started"

  def dunning_current_step_label, do: "Current step"

  def dunning_next_action_label, do: "Next scheduled action"

  def dunning_empty_state_heading, do: "No active dunning campaign"

  def dunning_empty_state_body, do: "This subscription has no active dunning campaign."

  def dunning_next_action_done, do: "Journey complete — awaiting grace/terminal sweep"

  def dunning_next_action_unavailable, do: "Next action unavailable"

  @doc """
  State-aware campaign badge label. Active campaigns read "Active"; a
  subscription that has never entered dunning reads "No active campaign".
  Mirrors the existing state-aware Copy defs that pattern-match the subject.
  """
  def dunning_state_label(%Subscription{} = subscription) do
    if Subscription.dunning_campaign_active?(subscription) do
      dunning_state_active()
    else
      dunning_state_none()
    end
  end

  def dunning_state_active, do: "Active"

  def dunning_state_none, do: "No active campaign"

  def dunning_state_recovered, do: "Recovered"
end
