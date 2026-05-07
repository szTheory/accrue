defmodule Accrue.PlanResolver do
  @moduledoc """
  Host-owned resolver for plan metadata that the shared `price_id` facade
  does not carry by itself.

  Accrue keeps public billing calls app-facing: host apps call
  `Accrue.Billing.swap_plan/3` with a stable `price_id`, while the host owns
  any catalog knowledge needed to translate that identifier into
  processor-specific metadata.

  This resolver is required for Braintree swap-plan flows because Braintree
  requires both the target `plan_id` and the explicit target amount when a
  subscription changes plans.
  """

  alias Accrue.APIError
  alias Accrue.Config

  @type currency :: atom() | String.t()
  @type interval_unit :: :day | :week | :month | :year

  @type billing_cycle :: %{
          required(:unit) => interval_unit(),
          required(:count) => pos_integer()
        }

  @type resolved_plan :: %{
          required(:price_id) => String.t(),
          required(:processor) => String.t(),
          required(:processor_plan_id) => String.t(),
          required(:unit_amount_minor) => non_neg_integer(),
          required(:currency) => currency(),
          required(:billing_cycle) => billing_cycle()
        }

  @callback resolve_price(String.t()) ::
              {:ok, resolved_plan()}
              | {:error, term()}

  @spec impl() :: module() | nil
  def impl, do: Config.plan_resolver()

  @spec configured?() :: boolean()
  def configured?, do: not is_nil(impl())

  @spec resolve_price(String.t()) :: {:ok, resolved_plan()} | {:error, APIError.t()}
  def resolve_price(price_id) when is_binary(price_id) do
    case impl() do
      nil ->
        {:error,
         %APIError{
           code: "plan_resolution_unavailable",
           http_status: 422,
           message:
             "Accrue.Billing.swap_plan/3 requires a configured :plan_resolver for processor-aware plan changes."
         }}

      resolver ->
        case resolver.resolve_price(price_id) do
          {:ok, %{} = plan} ->
            normalize(plan, price_id)

          {:error, %APIError{} = error} ->
            {:error, error}

          {:error, reason} ->
            {:error,
             %APIError{
               code: "price_resolution_missing",
               http_status: 422,
               message:
                 "The configured :plan_resolver could not resolve #{inspect(price_id)}: #{inspect(reason)}"
             }}

          other ->
            {:error,
             %APIError{
               code: "price_resolution_invalid",
               http_status: 500,
               message:
                 "The configured :plan_resolver returned an invalid result for #{inspect(price_id)}: #{inspect(other)}"
             }}
        end
    end
  end

  defp normalize(plan, requested_price_id) do
    with {:ok, price_id} <- fetch_binary(plan, :price_id, requested_price_id),
         {:ok, processor} <- fetch_binary(plan, :processor),
         {:ok, processor_plan_id} <- fetch_binary(plan, :processor_plan_id),
         {:ok, unit_amount_minor} <- fetch_non_neg_integer(plan, :unit_amount_minor),
         {:ok, currency} <- fetch_currency(plan, :currency),
         {:ok, billing_cycle} <- fetch_billing_cycle(plan) do
      {:ok,
       %{
         price_id: price_id,
         processor: processor,
         processor_plan_id: processor_plan_id,
         unit_amount_minor: unit_amount_minor,
         currency: currency,
         billing_cycle: billing_cycle
       }}
    end
  end

  defp fetch_binary(plan, key, default \\ nil) do
    case Map.get(plan, key, default) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> invalid(key)
    end
  end

  defp fetch_non_neg_integer(plan, key) do
    case Map.get(plan, key) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> invalid(key)
    end
  end

  defp fetch_currency(plan, key) do
    case Map.get(plan, key) do
      value when is_atom(value) -> {:ok, value}
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> invalid(key)
    end
  end

  defp fetch_billing_cycle(plan) do
    case Map.get(plan, :billing_cycle) do
      %{unit: unit, count: count}
      when unit in [:day, :week, :month, :year] and is_integer(count) and count > 0 ->
        {:ok, %{unit: unit, count: count}}

      _ ->
        invalid(:billing_cycle)
    end
  end

  defp invalid(key) do
    {:error,
     %APIError{
       code: "price_resolution_invalid",
       http_status: 500,
       message:
         "The configured :plan_resolver must return #{inspect(key)} for processor-aware plan changes."
     }}
  end
end
