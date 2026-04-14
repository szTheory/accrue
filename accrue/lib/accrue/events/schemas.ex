defmodule Accrue.Events.Schemas do
  @moduledoc """
  Registry mapping Phase 3 event atoms to their canonical schema
  modules (D3-66, D3-68).

  The registry covers all 24 Phase 3 event types. Seven events have
  fully-typed schema modules (created, updated, canceled,
  plan_swapped, invoice.paid, refund.created, card.expiring_soon);
  the remaining 17 are minimal stubs that establish the
  `Accrue.Events.Upcaster` contract at `schema_version: 1` but do not
  yet enumerate every typed field. Future revisions can expand any
  stub into a typed struct without touching the registry shape.

  ## Usage

      iex> Accrue.Events.Schemas.for(:"subscription.created")
      Accrue.Events.Schemas.SubscriptionCreated

      iex> Accrue.Events.Schemas.for(:"unknown.event")
      nil

      iex> Accrue.Events.Schemas.count()
      24
  """

  @registry %{
    :"subscription.created" => Accrue.Events.Schemas.SubscriptionCreated,
    :"subscription.updated" => Accrue.Events.Schemas.SubscriptionUpdated,
    :"subscription.trial_started" => Accrue.Events.Schemas.SubscriptionTrialStarted,
    :"subscription.trial_ended" => Accrue.Events.Schemas.SubscriptionTrialEnded,
    :"subscription.canceled" => Accrue.Events.Schemas.SubscriptionCanceled,
    :"subscription.resumed" => Accrue.Events.Schemas.SubscriptionResumed,
    :"subscription.paused" => Accrue.Events.Schemas.SubscriptionPaused,
    :"subscription.plan_swapped" => Accrue.Events.Schemas.SubscriptionPlanSwapped,
    :"invoice.created" => Accrue.Events.Schemas.InvoiceCreated,
    :"invoice.finalized" => Accrue.Events.Schemas.InvoiceFinalized,
    :"invoice.paid" => Accrue.Events.Schemas.InvoicePaid,
    :"invoice.payment_failed" => Accrue.Events.Schemas.InvoicePaymentFailed,
    :"invoice.voided" => Accrue.Events.Schemas.InvoiceVoided,
    :"invoice.marked_uncollectible" => Accrue.Events.Schemas.InvoiceMarkedUncollectible,
    :"charge.succeeded" => Accrue.Events.Schemas.ChargeSucceeded,
    :"charge.failed" => Accrue.Events.Schemas.ChargeFailed,
    :"charge.refunded" => Accrue.Events.Schemas.ChargeRefunded,
    :"refund.created" => Accrue.Events.Schemas.RefundCreated,
    :"refund.fees_settled" => Accrue.Events.Schemas.RefundFeesSettled,
    :"payment_method.attached" => Accrue.Events.Schemas.PaymentMethodAttached,
    :"payment_method.detached" => Accrue.Events.Schemas.PaymentMethodDetached,
    :"payment_method.updated" => Accrue.Events.Schemas.PaymentMethodUpdated,
    :"customer.default_payment_method_changed" =>
      Accrue.Events.Schemas.CustomerDefaultPaymentMethodChanged,
    :"card.expiring_soon" => Accrue.Events.Schemas.CardExpiringSoon
  }

  @doc """
  Returns the schema module for an event type atom, or `nil` for
  unknown types.
  """
  @spec for(atom()) :: module() | nil
  def for(type) when is_atom(type), do: Map.get(@registry, type)

  @doc "Returns the full `event_type => module` registry."
  @spec all() :: %{atom() => module()}
  def all, do: @registry

  @doc "Number of registered event types (always 24 in Phase 3)."
  @spec count() :: non_neg_integer()
  def count, do: map_size(@registry)
end

# ---------------------------------------------------------------------------
# Stub modules for the 17 non-typed Phase 3 event types.
#
# Each stub implements the Accrue.Events.Upcaster contract with an
# identity `upcast/1` and `schema_version/0 == 1`. They are defined in
# this file (rather than 17 separate files) because the stubs have no
# type information to document — expanding any one into a typed struct
# is a single file move.
# ---------------------------------------------------------------------------

for {name, _mod} <- [
      {:SubscriptionTrialStarted, nil},
      {:SubscriptionTrialEnded, nil},
      {:SubscriptionResumed, nil},
      {:SubscriptionPaused, nil},
      {:InvoiceCreated, nil},
      {:InvoiceFinalized, nil},
      {:InvoicePaymentFailed, nil},
      {:InvoiceVoided, nil},
      {:InvoiceMarkedUncollectible, nil},
      {:ChargeSucceeded, nil},
      {:ChargeFailed, nil},
      {:ChargeRefunded, nil},
      {:RefundFeesSettled, nil},
      {:PaymentMethodAttached, nil},
      {:PaymentMethodDetached, nil},
      {:PaymentMethodUpdated, nil},
      {:CustomerDefaultPaymentMethodChanged, nil}
    ] do
  defmodule Module.concat(Accrue.Events.Schemas, name) do
    @moduledoc false
    @behaviour Accrue.Events.Upcaster

    @derive Jason.Encoder
    defstruct data: %{}, source: :api

    @spec schema_version() :: pos_integer()
    def schema_version, do: 1

    @impl Accrue.Events.Upcaster
    def upcast(payload), do: {:ok, payload}
  end
end
