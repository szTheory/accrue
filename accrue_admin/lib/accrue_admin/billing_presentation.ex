defmodule AccrueAdmin.BillingPresentation do
  @moduledoc false

  @type ownership_class :: :user | :org
  @type tax_health :: :off | :active | :invalid_or_blocked

  @spec ownership_class(map()) :: ownership_class()
  def ownership_class(row) when is_map(row) do
    case normalize_string(row[:owner_type] || row["owner_type"]) do
      "Organization" -> :org
      _ -> :user
    end
  end

  @spec ownership_label(map()) :: String.t()
  def ownership_label(row) when is_map(row) do
    case ownership_class(row) do
      :org -> "Org"
      :user -> "User"
    end
  end

  @spec tax_health(map()) :: tax_health()
  def tax_health(row) when is_map(row) do
    automatic_tax = row[:automatic_tax] || row["automatic_tax"]
    reason = row[:automatic_tax_disabled_reason] || row["automatic_tax_disabled_reason"]
    code = row[:last_finalization_error_code] || row["last_finalization_error_code"]

    invalid? = invalid_tax?(reason, code)
    active? = active_tax?(automatic_tax)

    cond do
      invalid? -> :invalid_or_blocked
      active? -> :active
      true -> :off
    end
  end

  @spec tax_health_label(tax_health()) :: String.t()
  def tax_health_label(:off), do: "Off"
  def tax_health_label(:active), do: "Active"
  def tax_health_label(:invalid_or_blocked), do: "Invalid or blocked"

  defp invalid_tax?(reason, code) do
    present?(reason) or invalid_code?(code)
  end

  defp invalid_code?(code) when is_binary(code) do
    code == "customer_tax_location_invalid" or String.contains?(code, "tax_location")
  end

  defp invalid_code?(_), do: false

  defp active_tax?(true), do: true
  defp active_tax?("true"), do: true
  defp active_tax?(_), do: false

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_), do: false

  defp normalize_string(value) when is_binary(value), do: value
  defp normalize_string(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_string(_), do: ""
end
