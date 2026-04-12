defmodule Accrue.Processor.Fake.State do
  @moduledoc """
  Internal state struct for `Accrue.Processor.Fake`.

  Shape is intentionally wider than Phase 1 needs so Phase 3+ can grow the
  Fake's callback list without state-shape churn (per-resource counters for
  subscriptions/invoices/payment_intents/payment_methods are already
  provisioned — D-20).
  """

  @type id :: String.t()

  @type t :: %__MODULE__{
          customers: %{optional(id()) => map()},
          subscriptions: %{optional(id()) => map()},
          invoices: %{optional(id()) => map()},
          payment_intents: %{optional(id()) => map()},
          payment_methods: %{optional(id()) => map()},
          counters: %{
            customer: non_neg_integer(),
            subscription: non_neg_integer(),
            invoice: non_neg_integer(),
            payment_intent: non_neg_integer(),
            payment_method: non_neg_integer()
          },
          clock: DateTime.t(),
          stubs: %{optional(atom()) => (... -> term())},
          idempotency_cache: %{optional(String.t()) => term()}
        }

  @epoch ~U[2026-01-01 00:00:00Z]

  defstruct customers: %{},
            subscriptions: %{},
            invoices: %{},
            payment_intents: %{},
            payment_methods: %{},
            counters: %{
              customer: 0,
              subscription: 0,
              invoice: 0,
              payment_intent: 0,
              payment_method: 0
            },
            clock: @epoch,
            stubs: %{},
            idempotency_cache: %{}

  @doc "The module's epoch DateTime — the value `clock` is reset to on `reset/0`."
  @spec epoch() :: DateTime.t()
  def epoch, do: @epoch
end
