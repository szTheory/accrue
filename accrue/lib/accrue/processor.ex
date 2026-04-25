defmodule Accrue.Processor do
  @moduledoc """
  The adapter contract between Accrue and payment processors.

  `Accrue.Processor` is an Elixir behaviour that defines every processor
  operation Accrue can perform — from creating customers to reporting
  metered usage. It also acts as a runtime-dispatching facade: callers
  always write `Accrue.Processor.create_customer(...)` and the configured
  adapter (Stripe in production, Fake in tests) handles the actual work.

  ## When you reach for this module

  Most of the time you won't call `Accrue.Processor` directly — the
  `Accrue.Billing` context does that for you. You care about this module
  when:

  - **Implementing a custom processor adapter** — implement this behaviour
    in your adapter module and point `:processor` config at it.
  - **Wiring a test double** — `Accrue.Processor.Fake` already does this;
    configure it in `test.exs` or use `Accrue.Test.setup_fake_processor/1`.
  - **Reading telemetry events** — every facade call emits
    `[:accrue, :processor, <resource>, <action>]` spans.

  ## Callback groups

  ### Customer
  `create_customer/2`, `retrieve_customer/2`, `update_customer/3`

  ### Subscription
  `create_subscription/2`, `retrieve_subscription/2`,
  `update_subscription/3`, `cancel_subscription/2`,
  `cancel_subscription/3`, `resume_subscription/2`,
  `pause_subscription_collection/4`

  ### SubscriptionItem
  `subscription_item_create/2`, `subscription_item_update/3`,
  `subscription_item_delete/3`

  ### SubscriptionSchedule
  `subscription_schedule_create/2`, `subscription_schedule_update/3`,
  `subscription_schedule_release/2`, `subscription_schedule_cancel/2`,
  `subscription_schedule_fetch/2`

  ### Invoice
  `create_invoice/2`, `retrieve_invoice/2`, `update_invoice/3`,
  `finalize_invoice/2`, `void_invoice/2`, `pay_invoice/2`,
  `send_invoice/2`, `mark_uncollectible_invoice/2`,
  `create_invoice_preview/2`

  ### Charge and PaymentIntent
  `create_charge/2`, `retrieve_charge/2`, `list_charges/2`,
  `create_payment_intent/2`, `retrieve_payment_intent/2`,
  `confirm_payment_intent/3`

  ### SetupIntent
  `create_setup_intent/2`, `retrieve_setup_intent/2`,
  `confirm_setup_intent/3`

  ### PaymentMethod
  `create_payment_method/2`, `retrieve_payment_method/2`,
  `attach_payment_method/3`, `detach_payment_method/2`,
  `list_payment_methods/2`, `update_payment_method/3`,
  `set_default_payment_method/3`

  ### Refund
  `create_refund/2`, `retrieve_refund/2`

  ### Coupon and PromotionCode
  `coupon_create/2`, `coupon_retrieve/2`,
  `promotion_code_create/2`, `promotion_code_retrieve/2`

  ### Checkout and BillingPortal
  `checkout_session_create/2`, `checkout_session_fetch/2`,
  `portal_session_create/2`

  ### Connect
  `create_account/2`, `retrieve_account/2`, `update_account/3`,
  `delete_account/2`, `reject_account/3`, `list_accounts/2`,
  `create_account_link/2`, `create_login_link/2`,
  `create_transfer/2`, `retrieve_transfer/2`

  ### Usage/Meters
  `report_meter_event/1`

  ### Generic refetch
  `fetch/2` — routes `(object_type_atom, id)` to the appropriate
  `retrieve_*` callback. Used by the webhook handler to re-fetch
  objects after receiving an event.

  ## Return types

  All adapter callbacks return `{:ok, map()} | {:error, Accrue.Error.t()}`.
  Billing context functions promote the 3DS/SCA path to an
  `intent_result` tagged tuple (`{:ok, :requires_action, payment_intent}`)
  where applicable.

  ## Runtime dispatch

  The configured adapter is resolved at call time via
  `Application.get_env(:accrue, :processor, Accrue.Processor.Fake)`.
  To use Stripe in production, add to `config/runtime.exs`:

      config :accrue, processor: Accrue.Processor.Stripe

  ## Telemetry

  The three facade functions (`create_customer/2`, `retrieve_customer/2`,
  `update_customer/3`) emit `[:accrue, :processor, :customer, <action>]`
  spans. All other operations are instrumented at the `Accrue.Billing`
  context level, where the full business operation name is available.
  """

  alias Accrue.Telemetry

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Exception.t()}

  @typedoc """
  3DS/SCA-aware return type for operations that may require additional
  customer authentication. Billing context functions use this union;
  processor behaviour callbacks return plain `{:ok, map()}` and the
  context layer decides when to promote to `{:ok, :requires_action, map()}`.
  """
  @type intent_result(ok) ::
          {:ok, ok}
          | {:ok, :requires_action, map()}
          | {:error, Accrue.Error.t()}

  # ---------------------------------------------------------------------------
  # Customer
  # ---------------------------------------------------------------------------

  @callback create_customer(params(), opts()) :: result()
  @callback retrieve_customer(id(), opts()) :: result()
  @callback update_customer(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Subscription
  # ---------------------------------------------------------------------------

  @callback create_subscription(params(), opts()) :: result()
  @callback retrieve_subscription(id(), opts()) :: result()
  @callback update_subscription(id(), params(), opts()) :: result()
  @callback cancel_subscription(id(), opts()) :: result()
  @callback cancel_subscription(id(), params(), opts()) :: result()
  @callback resume_subscription(id(), opts()) :: result()
  @callback pause_subscription_collection(id(), atom(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Invoice
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
  # PaymentIntent
  # ---------------------------------------------------------------------------

  @callback create_payment_intent(params(), opts()) :: result()
  @callback retrieve_payment_intent(id(), opts()) :: result()
  @callback confirm_payment_intent(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # SetupIntent
  # ---------------------------------------------------------------------------

  @callback create_setup_intent(params(), opts()) :: result()
  @callback retrieve_setup_intent(id(), opts()) :: result()
  @callback confirm_setup_intent(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # PaymentMethod
  # ---------------------------------------------------------------------------

  @callback create_payment_method(params(), opts()) :: result()
  @callback retrieve_payment_method(id(), opts()) :: result()
  @callback attach_payment_method(id(), params(), opts()) :: result()
  @callback detach_payment_method(id(), opts()) :: result()
  @callback list_payment_methods(params(), opts()) :: result()
  @callback update_payment_method(id(), params(), opts()) :: result()
  @callback set_default_payment_method(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Charge
  # ---------------------------------------------------------------------------

  @callback create_charge(params(), opts()) :: result()
  @callback retrieve_charge(id(), opts()) :: result()
  @callback list_charges(params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Refund
  # ---------------------------------------------------------------------------

  @callback create_refund(params(), opts()) :: result()
  @callback retrieve_refund(id(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Generic refetch
  # ---------------------------------------------------------------------------

  @callback fetch(atom(), id()) :: result()

  # ---------------------------------------------------------------------------
  # Meter event
  # ---------------------------------------------------------------------------

  @callback report_meter_event(Accrue.Billing.MeterEvent.t()) ::
              {:ok, map()} | {:error, Exception.t() | term()}

  # ---------------------------------------------------------------------------
  # Subscription items
  # ---------------------------------------------------------------------------

  @callback subscription_item_create(params(), opts()) :: result()
  @callback subscription_item_update(id(), params(), opts()) :: result()
  @callback subscription_item_delete(id(), params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Subscription schedules
  # ---------------------------------------------------------------------------

  @callback subscription_schedule_create(params(), opts()) :: result()
  @callback subscription_schedule_update(id(), params(), opts()) :: result()
  @callback subscription_schedule_release(id(), opts()) :: result()
  @callback subscription_schedule_cancel(id(), opts()) :: result()
  @callback subscription_schedule_fetch(id(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Coupons + Promotion Codes
  # ---------------------------------------------------------------------------

  @callback coupon_create(params(), opts()) :: result()
  @callback coupon_retrieve(id(), opts()) :: result()
  @callback promotion_code_create(params(), opts()) :: result()
  @callback promotion_code_retrieve(id(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Checkout + Customer Portal
  # ---------------------------------------------------------------------------

  @callback checkout_session_create(params(), opts()) :: result()
  @callback checkout_session_fetch(id(), opts()) :: result()
  @callback portal_session_create(params(), opts()) :: result()

  # ---------------------------------------------------------------------------
  # Connect
  #
  # Connected Accounts + account links + login links + platform transfers.
  # Adapter resolution threads `stripe_account` through
  # `Accrue.Processor.Stripe.resolve_stripe_account/1` → `build_client!/1`.
  # Used by `Accrue.Connect.Account`, `Accrue.Connect.AccountLink`,
  # `Accrue.Connect.LoginLink`, and `Accrue.Connect.Transfer`.
  # ---------------------------------------------------------------------------

  @callback create_account(params(), opts()) :: result()
  @callback retrieve_account(id(), opts()) :: result()
  @callback update_account(id(), params(), opts()) :: result()
  @callback delete_account(id(), opts()) :: result()
  @callback reject_account(id(), params(), opts()) :: result()
  @callback list_accounts(params(), opts()) :: result()

  @callback create_account_link(params(), opts()) :: result()
  @callback create_login_link(id(), opts()) :: result()

  @callback create_transfer(params(), opts()) :: result()
  @callback retrieve_transfer(id(), opts()) :: result()

  # Connect callbacks are optional at the behaviour level so that adapter
  # implementations can be added incrementally. Once all adapters implement
  # the full Connect surface, this `@optional_callbacks` declaration can
  # be removed to re-enable strict behaviour checks.
  @optional_callbacks create_account: 2,
                      retrieve_account: 2,
                      update_account: 3,
                      delete_account: 2,
                      reject_account: 3,
                      list_accounts: 2,
                      create_account_link: 2,
                      create_login_link: 2,
                      create_transfer: 2,
                      retrieve_transfer: 2

  # ---------------------------------------------------------------------------
  # Facade dispatch (customer operations)
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
