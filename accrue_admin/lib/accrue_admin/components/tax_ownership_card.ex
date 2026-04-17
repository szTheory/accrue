defmodule AccrueAdmin.Components.TaxOwnershipCard do
  @moduledoc false

  use Phoenix.Component

  alias AccrueAdmin.BillingPresentation

  attr(:row, :map, required: true)

  def tax_ownership_card(assigns) do
    row = assigns.row
    tax_health = BillingPresentation.tax_health(row)

    assigns =
      assigns
      |> assign(:ownership_label, BillingPresentation.ownership_label(row))
      |> assign(:tax_label, BillingPresentation.tax_health_label(tax_health))
      |> assign(:tax_health, tax_health)

    ~H"""
    <section class="ax-card" aria-labelledby="tax-ownership-heading">
      <h3 class="ax-heading" id="tax-ownership-heading">Tax & ownership</h3>
      <p class="ax-body">
        <span class="ax-label">Ownership</span>
        <%= @ownership_label %>
        <span class="ax-label"> · Tax health</span>
        <%= @tax_label %>
      </p>

      <div :if={@tax_health == :invalid_or_blocked}>
        <p class="ax-heading">Tax location needs attention</p>
        <p class="ax-body">
          Update the customer tax location before tax-enabled charges can proceed.
        </p>
      </div>
    </section>
    """
  end
end
