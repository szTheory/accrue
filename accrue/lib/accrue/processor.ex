defmodule Accrue.Processor do
  @moduledoc """
  Behaviour every processor adapter implements, plus a runtime-dispatching
  facade so every caller looks like `Accrue.Processor.create_customer(...)`
  regardless of which adapter is wired.

  ## Callback surface

  Phase 1 shipped the customer callbacks (`create_customer/2`,
  `retrieve_customer/2`, `update_customer/3`). Phase 3 (this plan, 03-03)
  grows the behaviour to the full Stripe Billing surface needed by Wave 2
  billing context functions:

  - **Subscription** — `create_subscription/2`, `retrieve_subscription/2`,
    `update_subscription/3`, `cancel_subscription/2`,
    `cancel_subscription/3`, `resume_subscription/2`,
    `pause_subscription_collection/4`
  - **Invoice** — `create_invoice/2`, `retrieve_invoice/2`,
    `update_invoice/3`, `finalize_invoice/2`, `void_invoice/2`,
    `pay_invoice/2`, `send_invoice/2`, `mark_uncollectible_invoice/2`,
    `create_invoice_preview/2`
  - **PaymentIntent** — `create_payment_intent/2`,
    `retrieve_payment_intent/2`, `confirm_payment_intent/3`
  - **SetupIntent** — `create_setup_intent/2`, `retrieve_setup_intent/2`,
    `confirm_setup_intent/3`
  - **PaymentMethod** — `create_payment_method/2`,
    `retrieve_payment_method/2`, `attach_payment_method/3`,
    `detach_payment_method/2`, `list_payment_methods/2`,
    `update_payment_method/3`, `set_default_payment_method/3`
  - **Charge** — `create_charge/2`, `retrieve_charge/2`, `list_charges/2`
  - **Refund** — `create_refund/2`, `retrieve_refund/2`
  - **Generic fetch** — `fetch/2` routes `(object_type_atom, id)` to the
    right `retrieve_*` for the webhook DefaultHandler refetch path
    (D3-48 step 3).

  All adapters return plain maps (`{:ok, map}`) or
  `{:error, Accrue.Error.t()}`; Billing context functions wrap the
  3DS/SCA branches into the `intent_result` union where applicable
  (D3-06..D3-12).

  ## Runtime dispatch

  The Phase 1 customer functions resolve the concrete adapter at call
  time via `Application.get_env(:accrue, :processor, Accrue.Processor.Fake)`.
  The Phase 3 callbacks are called directly on the adapter module by
  Billing context functions; adapter resolution is via `__impl__/0`.

  ## Telemetry

  Each public Phase 1 call is wrapped in `Accrue.Telemetry.span/3`.
  Phase 3 callbacks are telemetered inside the Billing context (Wave 2)
  so the instrumentation sees the full business op name, not just the
  processor leg.
  """

  alias Accrue.Telemetry

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Exception.t()}

  @typedoc """
  3DS/SCA-aware return type for intent-carrying ops (D3-06). Billing
  context functions use this; the processor behaviour returns plain
  `{:ok, map()}` and lets the context decide when to tag.
  """
  @type intent_result(ok) ::
          {:ok, ok}
          | {:ok, :requires_action, map()}
          | {:error, Accrue.Error.t()}

  # ---------------------------------------------------------------------------
  # Customer (Phase 1)
  # ---------------------------------------------------------------------------

  @callback create_customer(params(), opts()) :: result()
  @callback retrieve_customer(id(), opts()) :: result()
  @callback update_customer(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Subscription (Phase 3)
  # ---------------------------------------------------------------------------

  @callback create_subscription(params(), opts()) :: result()
  @callback retrieve_subscription(id(), opts()) :: result()
  @callback update_subscription(id(), params(), opts()) :: result()
  @callback cancel_subscription(id(), opts()) :: result()
  @callback cancel_subscription(id(), params(), opts()) :: result()
  @callback resume_subscription(id(), opts()) :: result()
  @callback pause_subscription_collection(id(), atom(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Invoice (Phase 3)
  # ---------------------------------------------------------------------------

  @callback create_invoice(params(), opts()) :: result()
  @callback retrieve_invoice(id(), opts()) :: result()
  @callback update_invoice(id(), params(), opts()) :: result()
  @callback finalize_invoice(id(), opts()) :: result()
  @callback void_invoice(id(), opts()) :: result()
  @callback pay_invoice(id(), opts()) :: result()
  @callback send_invoice(id(), opts()) :: result()
  @callback mark_uncollectible_invoice(id(), opts()) :: result()
  @callback create_invoice_preview(params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # PaymentIntent (Phase 3)
  # ---------------------------------------------------------------------------

  @callback create_payment_intent(params(), opts()) :: result()
  @callback retrieve_payment_intent(id(), opts()) :: result()
  @callback confirm_payment_intent(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # SetupIntent (Phase 3)
  # ---------------------------------------------------------------------------

  @callback create_setup_intent(params(), opts()) :: result()
  @callback retrieve_setup_intent(id(), opts()) :: result()
  @callback confirm_setup_intent(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # PaymentMethod (Phase 3)
  # ---------------------------------------------------------------------------

  @callback create_payment_method(params(), opts()) :: result()
  @callback retrieve_payment_method(id(), opts()) :: result()
  @callback attach_payment_method(id(), params(), opts()) :: result()
  @callback detach_payment_method(id(), opts()) :: result()
  @callback list_payment_methods(params(), opts()) :: result()
  @callback update_payment_method(id(), params(), opts()) :: result()
  @callback set_default_payment_method(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Charge (Phase 3)
  # ---------------------------------------------------------------------------

  @callback create_charge(params(), opts()) :: result()
  @callback retrieve_charge(id(), opts()) :: result()
  @callback list_charges(params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Refund (Phase 3)
  # ---------------------------------------------------------------------------

  @callback create_refund(params(), opts()) :: result()
  @callback retrieve_refund(id(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Generic refetch (Phase 3, D3-48)
  # ---------------------------------------------------------------------------

  @callback fetch(atom(), id()) :: result()

  # ---------------------------------------------------------------------------
  # Meter event (Phase 4 Plan 02, BILL-13)
  # ---------------------------------------------------------------------------

  @callback report_meter_event(Accrue.Billing.MeterEvent.t()) ::
              {:ok, map()} | {:error, Exception.t() | term()}

  # ---------------------------------------------------------------------------
  # Subscription items (Phase 4 Plan 03, BILL-12)
  # ---------------------------------------------------------------------------

  @callback subscription_item_create(params(), opts()) :: result()
  @callback subscription_item_update(id(), params(), opts()) :: result()
  @callback subscription_item_delete(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Subscription schedules (Phase 4 Plan 03, BILL-16)
  # ---------------------------------------------------------------------------

  @callback subscription_schedule_create(params(), opts()) :: result()
  @callback subscription_schedule_update(id(), params(), opts()) :: result()
  @callback subscription_schedule_release(id(), opts()) :: result()
  @callback subscription_schedule_cancel(id(), opts()) :: result()
  @callback subscription_schedule_fetch(id(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Phase 1 facade dispatch
  # ---------------------------------------------------------------------------

  @doc """
  Creates a customer through the configured processor adapter.
  """
  @spec create_customer(params(), opts()) :: result()
  def create_customer(params, opts \\ []) when is_map(params) and is_list(opts) do
    adapter = __impl__()

    Telemetry.span(
      [:accrue, :processor, :customer, :create],
      %{adapter: adapter, operation: :create_customer},
      fn -> adapter.create_customer(params, opts) end
    )
  end

  @doc """
  Retrieves a customer by id through the configured processor adapter.
  """
  @spec retrieve_customer(id(), opts()) :: result()
  def retrieve_customer(id, opts \\ []) when is_binary(id) and is_list(opts) do
    adapter = __impl__()

    Telemetry.span(
      [:accrue, :processor, :customer, :retrieve],
      %{adapter: adapter, operation: :retrieve_customer},
      fn -> adapter.retrieve_customer(id, opts) end
    )
  end

  @doc """
  Updates a customer by id through the configured processor adapter.
  """
  @spec update_customer(id(), params(), opts()) :: result()
  def update_customer(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    adapter = __impl__()

    Telemetry.span(
      [:accrue, :processor, :customer, :update],
      %{adapter: adapter, operation: :update_customer},
      fn -> adapter.update_customer(id, params, opts) end
    )
  end

  @doc false
  @spec __impl__() :: module()
  def __impl__, do: Application.get_env(:accrue, :processor, Accrue.Processor.Fake)
end
