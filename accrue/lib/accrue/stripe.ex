defmodule Accrue.Stripe do
  @moduledoc """
  Stripe-specific helpers for host applications (D2-15).

  This module provides process-dictionary-scoped overrides for Stripe
  API settings. The primary use case is traffic-split API version
  rollouts:

      Accrue.Stripe.with_api_version("2026-03-25.dahlia", fn ->
        Accrue.Billing.create_customer(user)
      end)

  The scoped version is read by `Accrue.Processor.Stripe` via the
  three-level precedence chain (D2-14):

      opts[:api_version] > pdict > Accrue.Config.stripe_api_version/0
  """

  @doc """
  Runs `fun` with the given Stripe API version set in the process
  dictionary. Restores the prior value (or clears it) in an `after`
  block, even if `fun` raises.

  ## Examples

      Accrue.Stripe.with_api_version("2025-01-01.test", fn ->
        Accrue.Billing.create_customer(user)
      end)
  """
  @spec with_api_version(String.t(), (-> result)) :: result when result: var
  def with_api_version(version, fun) when is_binary(version) and is_function(fun, 0) do
    old = Process.get(:accrue_stripe_api_version)
    Process.put(:accrue_stripe_api_version, version)

    try do
      fun.()
    after
      if old do
        Process.put(:accrue_stripe_api_version, old)
      else
        Process.delete(:accrue_stripe_api_version)
      end
    end
  end
end
