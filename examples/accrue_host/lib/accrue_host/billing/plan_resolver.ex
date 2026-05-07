defmodule AccrueHost.Billing.PlanResolver do
  @moduledoc """
  Host-owned plan resolver used to promote processor-aware swap-plan flows.
  """

  @behaviour Accrue.PlanResolver

  alias AccrueHost.Billing.Plans

  @impl Accrue.PlanResolver
  def resolve_price(price_id) when is_binary(price_id) do
    case Plans.get(price_id) do
      nil ->
        {:error, :unknown_price_id}

      plan ->
        {:ok,
         %{
           price_id: plan.id,
           processor: processor_name(),
           processor_plan_id: plan.id,
           unit_amount_minor: plan.unit_amount_minor,
           currency: plan.currency,
           billing_cycle: plan.billing_cycle
         }}
    end
  end

  defp processor_name do
    case Application.get_env(:accrue, :processor, Accrue.Processor.Fake) do
      Accrue.Processor.Braintree -> "braintree"
      Accrue.Processor.Stripe -> "stripe"
      _ -> "fake"
    end
  end
end
