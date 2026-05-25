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
      update: "all first-party"
    },
    payment_method: %{
      vault_acquisition: "all first-party",
      create: "all first-party",
      list: "all first-party",
      update: "all first-party",
      delete: "all first-party",
      set_default: "all first-party"
    },
    subscription: %{
      direct_create: "all first-party",
      fetch: "all first-party",
      cancel: "all first-party",
      lifecycle_webhook_projection: "all first-party",
      update: "all first-party",
      swap_plan: "official active-subscription-change",
      update_quantity: "official active-subscription-change",
      cancel_at_period_end: "staged first-party target",
      cancel_immediately: "all first-party",
      pause: "out of slice",
      resume: "out of slice"
    },
    subscription_item: %{
      add: "official active-subscription-change",
      remove: "official active-subscription-change",
      update_quantity: "official active-subscription-change"
    },
    invoice: %{
      lifecycle_webhook_projection: "all first-party",
      preview_upcoming_invoice: "official active-subscription-change"
    },
    checkout: %{
      create: "first-party local portal",
      fetch: "first-party local portal",
      hosted: "first-party local portal",
      embedded: "out of slice"
    },
    billing_portal: %{
      create: "first-party local portal"
    },
    webhook: %{
      verify: "all first-party",
      parse: "all first-party"
    },
    entitlements: %{
      local_mapping: "all first-party",
      stripe_native_sync: "Stripe-native advisory (observational)"
    },
    dunning: %{
      campaign: "all first-party",
      smart_retry_alignment: "provider-divergent (see dunning guide)"
    }
  }

  @provider_support_labels %{
    subscription: %{
      swap_plan: %{
        fake: "testing/local-only",
        stripe: "native",
        braintree: "bounded first-party"
      },
      update_quantity: %{
        fake: "testing/local-only",
        stripe: "native",
        braintree: "unsupported"
      }
    },
    subscription_item: %{
      add: %{
        fake: "testing/local-only",
        stripe: "native",
        braintree: "unsupported"
      },
      remove: %{
        fake: "testing/local-only",
        stripe: "native",
        braintree: "unsupported"
      },
      update_quantity: %{
        fake: "testing/local-only",
        stripe: "native",
        braintree: "unsupported"
      }
    },
    invoice: %{
      preview_upcoming_invoice: %{
        fake: "testing/local-only",
        stripe: "native",
        braintree: "unsupported"
      }
    },
    # CONVERGENCE row — unlike every divergence lane above, entitlement
    # resolution is provider-INDEPENDENT local derivation (D-03), so all three
    # providers carry the same "local-identical" lane. Never a native/
    # unsupported/bounded label here (the drift gate enforces this).
    entitlements: %{
      local_mapping: %{
        fake: "local-identical",
        stripe: "local-identical",
        braintree: "local-identical"
      },
      # DIVERGENCE row (D-10) — the OPTIONAL, off-by-default Stripe-native
      # entitlement-summary sync is an advisory/observational overlay only on
      # Stripe; it never displaces local-first resolution and does NOT change
      # `entitled?/2` / `has_active_plan?/2`. Fake/Braintree are out of slice /
      # unsupported. Unlike `local_mapping` above, this row legitimately carries
      # per-provider divergence labels (the drift gate exempts THIS row by name
      # while still protecting the `local_mapping` convergence contract).
      stripe_native_sync: %{
        fake: "out of slice",
        stripe: "native (advisory)",
        braintree: "unsupported"
      }
    },
    # CONVERGENCE row — the dunning campaign cadence is provider-INDEPENDENT local
    # derivation driven off `dunning_campaign_started_at` / `past_due_since` and
    # `Accrue.Clock`, with zero processor calls. All three providers carry the same
    # "local-identical" lane. The campaign schedule, step sequencing, and termination
    # are all Accrue-clock-driven; no processor API is consulted. This row must NEVER
    # carry a native/unsupported/bounded label (the drift gate enforces this).
    dunning: %{
      campaign: %{
        fake: "local-identical",
        stripe: "local-identical",
        braintree: "local-identical"
      },
      # DIVERGENCE row — processor-native payment-retry behavior differs across
      # providers. Stripe has adaptive Smart Retries that run beneath Accrue's campaign
      # cadence and may recover a payment before the next step fires. Braintree is
      # clock-driven only and has no smart-retry overlay — Accrue's cadence is the sole
      # retry signal. Fake is the deterministic proof lane that exercises the campaign
      # step sequencer locally and in CI with no network access.
      smart_retry_alignment: %{
        fake: "testing/local-only",
        stripe: "native (Smart Retries)",
        braintree: "unsupported (clock-driven only)"
      }
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

  @spec provider_support_label(atom(), atom() | [atom()]) :: String.t() | nil
  def provider_support_label(provider, path) when is_atom(path),
    do: provider_support_label(provider, [path])

  def provider_support_label(provider, path)
      when is_atom(provider) and is_list(path) do
    case get_in(@provider_support_labels, path ++ [provider]) do
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
