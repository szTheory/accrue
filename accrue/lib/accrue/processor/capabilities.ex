defmodule Accrue.Processor.Capabilities do
  @moduledoc """
  Capability map for bounded processor slices.

  Accrue's processor behaviour is historically Stripe-shaped. This module
  keeps the public support contract explicit: adapters declare the slices they
  actually implement, while support labels describe whether a row is part of
  the official first-party promise, staged, or intentionally out of slice.
  """

  @support_labels %{
    customer: %{
      create: "all first-party",
      retrieve: "all first-party",
      update: "staged first-party target"
    },
    payment_method: %{
      vault_acquisition: "all first-party",
      list: "out of slice"
    },
    subscription: %{
      direct_create: "all first-party",
      fetch: "all first-party",
      cancel: "staged first-party target",
      lifecycle_webhook_projection: "all first-party",
      update: "out of slice",
      cancel_at_period_end: "out of slice",
      cancel_immediately: "out of slice",
      pause: "out of slice",
      resume: "out of slice"
    },
    invoice: %{
      lifecycle_webhook_projection: "all first-party"
    },
    checkout: %{
      create: "Stripe-only",
      fetch: "Stripe-only",
      hosted: "Stripe-only",
      embedded: "out of slice"
    },
    billing_portal: %{
      create: "Stripe-only"
    },
    webhook: %{
      verify: "all first-party",
      parse: "all first-party"
    }
  }

  @spec for(module()) :: map()
  def for(adapter) when is_atom(adapter) do
    case Code.ensure_loaded?(adapter) and function_exported?(adapter, :capabilities, 0) do
      true ->
        case adapter.capabilities() do
          %{} = capabilities -> capabilities
          _ -> %{}
        end

      false ->
        %{}
    end
  end

  @spec supports?(map(), [atom()]) :: boolean()
  def supports?(capabilities, path) when is_map(capabilities) and is_list(path) do
    case get_in(capabilities, path) do
      true -> true
      _ -> false
    end
  end

  @spec support_label(atom() | [atom()]) :: String.t() | nil
  def support_label(path) when is_atom(path), do: support_label([path])

  def support_label(path) when is_list(path) do
    case get_in(@support_labels, path) do
      label when is_binary(label) -> label
      _ -> nil
    end
  end

  @spec first_party_supported?(map(), atom() | [atom()]) :: boolean()
  def first_party_supported?(capabilities, path) when is_atom(path),
    do: first_party_supported?(capabilities, [path])

  def first_party_supported?(capabilities, path)
      when is_map(capabilities) and is_list(path) do
    support_label(path) == "all first-party" and supports?(capabilities, path)
  end
end
