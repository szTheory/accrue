if Code.ensure_loaded?(StreamData) do
  defmodule Accrue.Test.Generators do
    @moduledoc """
    StreamData generators for Phase 3 property tests (D3-81).

    Gated behind `Code.ensure_loaded?(StreamData)` so the module only
    exists when the `:stream_data` dependency is available (i.e. `:dev`
    and `:test`). Host apps that pull Accrue in `:prod` never see this
    module.
    """

    import StreamData

    @doc "Integer amounts in minor units, up to ~$10M."
    def money_amount_minor, do: integer(0..1_000_000_000)

    @doc "ISO 4217 currency atoms covered by Phase 3 tests."
    def currency, do: member_of([:usd, :eur, :gbp, :jpy])

    @doc "Stripe proration_behavior values."
    def proration_behavior, do: member_of([:create_prorations, :none, :always_invoice])

    @doc "Stripe subscription status atoms (all eight Phase 3 states)."
    def stripe_status do
      member_of([
        :trialing,
        :active,
        :past_due,
        :canceled,
        :unpaid,
        :incomplete,
        :incomplete_expired,
        :paused
      ])
    end

    @doc "Operation IDs as used by Accrue.Actor.put_operation_id/1."
    def operation_id, do: string(:alphanumeric, min_length: 8, max_length: 64)

    @doc "Subject identifiers for idempotency key derivation."
    def subject_id, do: string(:alphanumeric, min_length: 3, max_length: 64)
  end
end
