defmodule AccrueAdmin.Copy.CustomerPaymentMethods do
  @moduledoc false

  @doc false
  def section_heading, do: "Payment methods"

  @doc false
  def empty_copy, do: "No payment methods on file."

  @doc false
  def row_fallback_label, do: "Payment method"

  @doc false
  def card_last4_mask, do: "·••••"
end
