defmodule AccrueAdmin.Components.DunningBanner do
  @moduledoc """
  A headless HEEx component that conditionally renders its inner block (or a default message)
  only if the given customer is currently in an active dunning campaign.
  """
  use Phoenix.Component

  @doc """
  Renders the dunning banner content if `Accrue.Dunning.requires_attention?/1` is true.

  ## Assigns
  * `:customer` - The customer or billable struct to check for dunning attention. Required.
  * `:inner_block` - The content to render if attention is required. Optional. If omitted, a default message is rendered.
  """
  attr(:customer, :any, required: true, doc: "The customer or billable struct")
  slot(:inner_block, required: false)

  def dunning_banner(assigns) do
    if Accrue.Dunning.requires_attention?(assigns.customer) do
      ~H"""
      <div class="accrue-dunning-banner-wrapper">
        <%= if @inner_block != [] do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <div
            class="accrue-default-dunning-banner"
            style="background-color: #fef2f2; color: #991b1b; padding: 1rem; text-align: center; border-bottom: 1px solid #fecaca; font-weight: 500;"
          >
            Action Required: We were unable to process your recent payment. Please update your payment method to avoid service interruption.
          </div>
        <% end %>
      </div>
      """
    else
      ~H""
    end
  end
end
