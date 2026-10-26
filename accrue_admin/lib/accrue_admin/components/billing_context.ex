defmodule AccrueAdmin.Components.BillingContext do
  @moduledoc "Quiet account and automatic-tax facts shared by billing lists."
  use Phoenix.Component

  alias AccrueAdmin.BillingPresentation
  alias AccrueAdmin.Components.StatusBadge

  attr(:row, :map, required: true)

  def billing_context(assigns) do
    assigns =
      assigns
      |> assign(:owner, assigns.row[:owner_type] || "Account type unavailable")
      |> assign(:tax, tax_observation(assigns.row))

    ~H"""
    <span class="ax-data-table-value">
      <span><%= @owner %></span>
      <span :if={@tax in [:active, :off]} class="ax-data-table-value-detail">
        Automatic tax <%= if @tax == :active, do: "on", else: "off" %>
      </span>
      <StatusBadge.status_badge :if={@tax == :invalid_or_blocked} status={:warning} tone="amber" label="Tax needs review" />
    </span>
    """
  end

  defp tax_observation(row) do
    case BillingPresentation.tax_health(row) do
      :off -> if is_nil(row[:automatic_tax]), do: :unknown, else: :off
      observed -> observed
    end
  end
end
