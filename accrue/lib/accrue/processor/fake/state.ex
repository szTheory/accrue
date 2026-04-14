defmodule Accrue.Processor.Fake.State do
  @moduledoc """
  Internal state struct for `Accrue.Processor.Fake`.

  Shape is intentionally wider than Phase 1 needs so Phase 3+ can grow the
  Fake's callback list without state-shape churn (per-resource counters for
  subscriptions/invoices/payment_intents/setup_intents/payment_methods/
  charges/refunds are already provisioned — D-20, D3-60).
  """

  @type id :: String.t()

  @type t :: %__MODULE__{
          customers: %{optional(id()) => map()},
          subscriptions: %{optional(id()) => map()},
          subscription_items: %{optional(id()) => map()},
          subscription_schedules: %{optional(id()) => map()},
          invoices: %{optional(id()) => map()},
          payment_intents: %{optional(id()) => map()},
          setup_intents: %{optional(id()) => map()},
          payment_methods: %{optional(id()) => map()},
          charges: %{optional(id()) => map()},
          refunds: %{optional(id()) => map()},
          meter_events: %{optional(id()) => map()},
          coupons: %{optional(id()) => map()},
          promotion_codes: %{optional(id()) => map()},
          counters: %{
            customer: non_neg_integer(),
            subscription: non_neg_integer(),
            subscription_item: non_neg_integer(),
            subscription_schedule: non_neg_integer(),
            invoice: non_neg_integer(),
            payment_intent: non_neg_integer(),
            setup_intent: non_neg_integer(),
            payment_method: non_neg_integer(),
            charge: non_neg_integer(),
            refund: non_neg_integer(),
            coupon: non_neg_integer(),
            promotion_code: non_neg_integer(),
            event: non_neg_integer()
          },
          clock: DateTime.t(),
          stubs: %{optional(atom()) => (... -> term())},
          idempotency_cache: %{optional(String.t()) => term()},
          scripts: %{optional(atom()) => term()}
        }

  @epoch ~U[2026-01-01 00:00:00Z]

  defstruct customers: %{},
            subscriptions: %{},
            subscription_items: %{},
            subscription_schedules: %{},
            invoices: %{},
            payment_intents: %{},
            setup_intents: %{},
            payment_methods: %{},
            charges: %{},
            refunds: %{},
            meter_events: %{},
            coupons: %{},
            promotion_codes: %{},
            counters: %{
              customer: 0,
              subscription: 0,
              subscription_item: 0,
              subscription_schedule: 0,
              invoice: 0,
              payment_intent: 0,
              setup_intent: 0,
              payment_method: 0,
              charge: 0,
              refund: 0,
              coupon: 0,
              promotion_code: 0,
              event: 0
            },
            clock: @epoch,
            stubs: %{},
            idempotency_cache: %{},
            scripts: %{}

  @doc "The module's epoch DateTime — the value `clock` is reset to on `reset/0`."
  @spec epoch() :: DateTime.t()
  def epoch, do: @epoch
end
