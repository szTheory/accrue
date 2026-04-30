defmodule AccrueAdmin.Copy.CustomerPaymentMethods do
  @moduledoc false

  @doc false
  def section_heading, do: "Payment methods"

  @doc false
  def empty_copy, do: "No payment methods on file."

  @doc false
  def section_body,
    do:
      "Review the local payment-method projection here. Add or replace cards in the host billing flow, then sync this view."

  @doc false
  def row_fallback_label, do: "Payment method"

  @doc false
  def card_last4_mask, do: "·••••"

  @doc false
  def sync_action, do: "Sync payment methods"

  @doc false
  def sync_success, do: "Payment methods synced."

  @doc false
  def set_default_action, do: "Set default payment method"

  @doc false
  def set_default_success, do: "Default payment method updated."

  @doc false
  def delete_action, do: "Delete payment method"

  @doc false
  def delete_success, do: "Payment method deleted."

  @doc false
  def delete_warning, do: "Review dependencies before you continue."

  @doc false
  def delete_blocked_in_use, do: "This payment method still funds an active subscription."

  @doc false
  def delete_blocked_replacement_required,
    do: "Set another default payment method before deleting this one."

  @doc false
  def replace_handoff, do: "Replace payment method in host billing"

  @doc false
  def default_badge, do: "Default"

  @doc false
  def in_use_badge, do: "In use"
end
