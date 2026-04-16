defmodule Accrue.Processor.Stripe do
  @moduledoc """
  Real-world processor adapter delegating to `:lattice_stripe`.

  **This is the ONLY module in the codebase allowed to alias, import, or
  reference `LatticeStripe`** (D-07). All raw Stripe errors cross this
  facade and are translated to `Accrue.Error` subtypes via
  `Accrue.Processor.Stripe.ErrorMapper` — downstream Billing code never
  sees raw `LatticeStripe.Error` shapes. A CI-enforced facade-lockdown test
  in `test/accrue/processor/stripe_test.exs` walks `lib/accrue/**/*.ex`
  and fails if `LatticeStripe` appears anywhere except `stripe.ex` and
  `stripe/error_mapper.ex`.

  ## Config keys (READ-ONLY)

  This module reads (never writes) the following Phase 1 keys that
  `Accrue.Config` already defines:

  - `:stripe_secret_key` — runtime only (CLAUDE.md §Config Boundaries). An
    unset key raises `Accrue.ConfigError` at call time rather than at
    `Application.compile_env!/2` load time so secrets never leak into
    compiled release artifacts.
  - `:stripe_api_version` — runtime only, defaults to `"2026-03-25.dahlia"`.

  ## PII discipline

  Raw Stripe responses often contain PII in fields like `email`, `name`,
  `address`, `phone`, `shipping`. This adapter:

  - **Does not log `processor_error` verbatim** — T-PROC-01 mitigation.
  - **Does not auto-inject params or responses into telemetry metadata**
    — only `%{adapter: :stripe, operation: ...}` at this layer.
  - **Converts `LatticeStripe.Customer` structs to plain maps** via
    `customer_to_map/1` so downstream code never pattern-matches on
    `%LatticeStripe.Customer{}`.

  ## Phase 1 scope

  Only the three customer callbacks are implemented (PROC-01, PROC-03,
  PROC-07). Wire-level integration tests against Stripe test mode are
  deferred to Phase 3 (PROC-02) — Phase 1 only proves the behaviour
  conformance, the error-mapping contract, and the facade lockdown.
  """

  @behaviour Accrue.Processor

  alias Accrue.Processor.Stripe.ErrorMapper
  alias Accrue.Telemetry

  require Logger

  # Default API version is in Accrue.Config.stripe_api_version/0.
  # Kept as documentation reference only.
  # @default_api_version "2026-03-25.dahlia"

  # ---------------------------------------------------------------------------
  # Behaviour callbacks
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_customer(params, opts) when is_map(params) and is_list(opts) do
    Telemetry.span(
      [:accrue, :processor, :customer, :create],
      %{adapter: :stripe, operation: :create_customer},
      fn ->
        client = build_client!(opts)
        idem_key = compute_idempotency_key(:create_customer, params[:email] || "new", opts)

        stripe_opts =
          opts
          |> Keyword.put(:idempotency_key, idem_key)
          |> Keyword.put(:stripe_version, resolve_api_version(opts))

        client
        |> LatticeStripe.Customer.create(stringify_keys(params), stripe_opts)
        |> translate_customer()
      end
    )
  end

  @impl Accrue.Processor
  def retrieve_customer(id, opts) when is_binary(id) and is_list(opts) do
    Telemetry.span(
      [:accrue, :processor, :customer, :retrieve],
      %{adapter: :stripe, operation: :retrieve_customer},
      fn ->
        client = build_client!(opts)

        stripe_opts = Keyword.put(opts, :stripe_version, resolve_api_version(opts))

        client
        |> LatticeStripe.Customer.retrieve(id, stripe_opts)
        |> translate_customer()
      end
    )
  end

  @impl Accrue.Processor
  def update_customer(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    Telemetry.span(
      [:accrue, :processor, :customer, :update],
      %{adapter: :stripe, operation: :update_customer},
      fn ->
        client = build_client!(opts)
        idem_key = compute_idempotency_key(:update_customer, id, opts)

        stripe_opts =
          opts
          |> Keyword.put(:idempotency_key, idem_key)
          |> Keyword.put(:stripe_version, resolve_api_version(opts))

        client
        |> LatticeStripe.Customer.update(id, stringify_keys(params), stripe_opts)
        |> translate_customer()
      end
    )
  end

  # ---------------------------------------------------------------------------
  # Subscription (Phase 3)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_subscription(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    params = ensure_expand(params, ["latest_invoice.payment_intent"])
    stripe_opts = stripe_opts(:create_subscription, subject_of(params, "sub"), opts)

    client
    |> LatticeStripe.Subscription.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_subscription(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts_no_idem(opts)

    client
    |> LatticeStripe.Subscription.retrieve(id, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def update_subscription(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    params = ensure_expand(params, ["latest_invoice.payment_intent"])
    stripe_opts = stripe_opts(:update_subscription, id, opts)

    client
    |> LatticeStripe.Subscription.update(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def cancel_subscription(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:cancel_subscription, id, opts)

    client
    |> LatticeStripe.Subscription.cancel(id, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def cancel_subscription(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:cancel_subscription, id, opts)

    client
    |> LatticeStripe.Subscription.cancel(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def resume_subscription(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:resume_subscription, id, opts)

    client
    |> LatticeStripe.Subscription.resume(id, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def pause_subscription_collection(id, behavior, params, opts)
      when is_binary(id) and is_atom(behavior) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:pause_subscription_collection, id, opts)

    client
    |> LatticeStripe.Subscription.pause_collection(
      id,
      behavior,
      stringify_keys(params),
      stripe_opts
    )
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Invoice (Phase 3)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_invoice(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:create_invoice, subject_of(params, "inv"), opts)

    client
    |> LatticeStripe.Invoice.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_invoice(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.Invoice.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def update_invoice(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:update_invoice, id, opts)

    client
    |> LatticeStripe.Invoice.update(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def finalize_invoice(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:finalize_invoice, id, opts)

    client
    |> LatticeStripe.Invoice.finalize(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def void_invoice(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:void_invoice, id, opts)

    client
    |> LatticeStripe.Invoice.void(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def pay_invoice(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:pay_invoice, id, opts)

    client
    |> LatticeStripe.Invoice.pay(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def send_invoice(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:send_invoice, id, opts)

    client
    |> LatticeStripe.Invoice.send_invoice(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def mark_uncollectible_invoice(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:mark_uncollectible_invoice, id, opts)

    client
    |> LatticeStripe.Invoice.mark_uncollectible(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def create_invoice_preview(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.Invoice.create_preview(stringify_keys(params), stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # PaymentIntent (Phase 3)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_payment_intent(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:create_payment_intent, subject_of(params, "pi"), opts)

    client
    |> LatticeStripe.PaymentIntent.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_payment_intent(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.PaymentIntent.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def confirm_payment_intent(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:confirm_payment_intent, id, opts)

    client
    |> LatticeStripe.PaymentIntent.confirm(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # SetupIntent (Phase 3)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_setup_intent(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:create_setup_intent, subject_of(params, "si"), opts)

    client
    |> LatticeStripe.SetupIntent.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_setup_intent(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.SetupIntent.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def confirm_setup_intent(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:confirm_setup_intent, id, opts)

    client
    |> LatticeStripe.SetupIntent.confirm(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # PaymentMethod (Phase 3)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_payment_method(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:create_payment_method, subject_of(params, "pm"), opts)

    client
    |> LatticeStripe.PaymentMethod.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_payment_method(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.PaymentMethod.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def attach_payment_method(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:attach_payment_method, id, opts)

    client
    |> LatticeStripe.PaymentMethod.attach(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def detach_payment_method(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:detach_payment_method, id, opts)

    client
    |> LatticeStripe.PaymentMethod.detach(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def list_payment_methods(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.PaymentMethod.list(stringify_keys(params), stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def update_payment_method(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:update_payment_method, id, opts)

    client
    |> LatticeStripe.PaymentMethod.update(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def set_default_payment_method(customer_id, params, opts)
      when is_binary(customer_id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:set_default_payment_method, customer_id, opts)

    client
    |> LatticeStripe.Customer.update(customer_id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Charge (Phase 3)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_charge(params, opts) when is_map(params) and is_list(opts) do
    # Note: Stripe no longer supports direct charge creation for new
    # integrations — PaymentIntents is the recommended path. This
    # delegation exists for legacy callers that still drive Charges
    # directly. lattice_stripe 1.0 does not expose LatticeStripe.Charge.create
    # so we route through PaymentIntent.create with confirmation_method: :automatic
    # and immediate confirm.
    params = ensure_expand(params, ["balance_transaction"])
    stripe_opts = stripe_opts(:create_charge, subject_of(params, "ch"), opts)
    client = build_client!(opts)

    client
    |> LatticeStripe.PaymentIntent.create(
      stringify_keys(Map.put(params, :confirm, true)),
      stripe_opts
    )
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_charge(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.Charge.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def list_charges(_params, _opts) do
    # lattice_stripe 1.0 does not expose LatticeStripe.Charge.list — the
    # canonical list surface is PaymentIntent.list. Return a typed error
    # so Wave 2 callers fail loudly rather than silently missing data.
    {:error,
     %Accrue.APIError{
       code: "unsupported_operation",
       http_status: 501,
       message:
         "LatticeStripe.Charge.list/3 is not available in lattice_stripe ~> 1.0; " <>
           "use Accrue.Processor.list_payment_intents/2 (Phase 4)."
     }}
  end

  # ---------------------------------------------------------------------------
  # Refund (Phase 3)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_refund(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)

    params =
      ensure_expand(params, [
        "balance_transaction",
        "charge.balance_transaction"
      ])

    stripe_opts = stripe_opts(:create_refund, subject_of(params, "re"), opts)

    client
    |> LatticeStripe.Refund.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_refund(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.Refund.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Meter event (Phase 4 Plan 02, BILL-13, D4-03)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def report_meter_event(%Accrue.Billing.MeterEvent{} = row) do
    # Stripe requires the payload `value` as a STRING (Pitfall 7) and
    # params keys as strings on the wire. Stripe's body-level
    # `identifier` + HTTP `idempotency_key` form two-layer dedup.
    params = %{
      "event_name" => row.event_name,
      "payload" => %{
        "stripe_customer_id" => row.stripe_customer_id,
        "value" => to_string(row.value)
      },
      "identifier" => row.identifier,
      "timestamp" => DateTime.to_unix(row.occurred_at, :second)
    }

    stripe_opts = [
      idempotency_key: row.identifier,
      stripe_version: resolve_api_version([])
    ]

    client = build_client!([])

    client
    |> LatticeStripe.Billing.MeterEvent.create(params, stripe_opts)
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Subscription items (Phase 4 Plan 03, BILL-12)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def subscription_item_create(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:subscription_item_create, subject_of(params, "si"), opts)

    client
    |> LatticeStripe.SubscriptionItem.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def subscription_item_update(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:subscription_item_update, id, opts)

    client
    |> LatticeStripe.SubscriptionItem.update(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def subscription_item_delete(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:subscription_item_delete, id, opts)

    client
    |> LatticeStripe.SubscriptionItem.delete(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Subscription schedules (Phase 4 Plan 03, BILL-16)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def subscription_schedule_create(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)

    stripe_opts =
      stripe_opts(:subscription_schedule_create, subject_of(params, "sub_sched"), opts)

    client
    |> LatticeStripe.SubscriptionSchedule.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def subscription_schedule_update(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:subscription_schedule_update, id, opts)

    client
    |> LatticeStripe.SubscriptionSchedule.update(id, stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def subscription_schedule_release(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:subscription_schedule_release, id, opts)

    client
    |> LatticeStripe.SubscriptionSchedule.release(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def subscription_schedule_cancel(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:subscription_schedule_cancel, id, opts)

    client
    |> LatticeStripe.SubscriptionSchedule.cancel(id, %{}, stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def subscription_schedule_fetch(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.SubscriptionSchedule.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Coupons + Promotion Codes (Phase 4 Plan 05, BILL-27)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def coupon_create(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:coupon_create, subject_of(params, "coupon"), opts)

    client
    |> LatticeStripe.Coupon.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def coupon_retrieve(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.Coupon.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def promotion_code_create(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:promotion_code_create, subject_of(params, "promo"), opts)

    client
    |> LatticeStripe.PromotionCode.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def promotion_code_retrieve(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.PromotionCode.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Checkout + Customer Portal (Phase 4 Plan 07, CHKT-01..06)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def checkout_session_create(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:checkout_session_create, subject_of(params, "cs"), opts)

    client
    |> LatticeStripe.Checkout.Session.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def checkout_session_fetch(id, opts) when is_binary(id) and is_list(opts) do
    client = build_client!(opts)

    client
    |> LatticeStripe.Checkout.Session.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  @impl Accrue.Processor
  def portal_session_create(params, opts) when is_map(params) and is_list(opts) do
    client = build_client!(opts)
    stripe_opts = stripe_opts(:portal_session_create, subject_of(params, "bps"), opts)

    client
    |> LatticeStripe.BillingPortal.Session.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Connect — Account Links + Login Links (Phase 5 Plan 03, D5-06)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_account_link(params, opts) when is_map(params) and is_list(opts) do
    # Pitfall 2: Account Links are PLATFORM-scoped — the platform
    # creates them on behalf of a connected account. The Stripe-Account
    # header MUST NOT be set regardless of the caller's
    # `Accrue.Connect.with_account/2` scope. `build_platform_client!/1`
    # bypasses `resolve_stripe_account/1` entirely to guarantee nil.
    client = build_platform_client!(opts)
    stripe_opts = stripe_opts_no_idem(opts)

    client
    |> LatticeStripe.AccountLink.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def create_login_link(acct_id, opts) when is_binary(acct_id) and is_list(opts) do
    # Pitfall 2: Login Links are also PLATFORM-scoped.
    client = build_platform_client!(opts)
    stripe_opts = stripe_opts_no_idem(opts)

    client
    |> LatticeStripe.LoginLink.create(acct_id, %{}, stripe_opts)
    |> translate_resource()
  end

  # ---------------------------------------------------------------------------
  # Connect — Transfers (Phase 5 Plan 05, CONN-05)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_transfer(params, opts) when is_map(params) and is_list(opts) do
    # Pitfall 2: Transfers are PLATFORM-authority — the platform moves
    # funds from its own balance to a connected account's balance. The
    # `Stripe-Account` header MUST NOT be set regardless of any
    # `Accrue.Connect.with_account/2` scope the caller may be inside.
    client = build_platform_client!(opts)
    stripe_opts = stripe_opts(:create_transfer, subject_of(params, "tr"), opts)

    client
    |> LatticeStripe.Transfer.create(stringify_keys(params), stripe_opts)
    |> translate_resource()
  end

  @impl Accrue.Processor
  def retrieve_transfer(id, opts) when is_binary(id) and is_list(opts) do
    client = build_platform_client!(opts)

    client
    |> LatticeStripe.Transfer.retrieve(id, stripe_opts_no_idem(opts))
    |> translate_resource()
  end

  # Builds a LatticeStripe client with `stripe_account: nil` unconditionally,
  # bypassing the `resolve_stripe_account/1` precedence chain. Used for
  # platform-scoped Connect calls (Account Links, Login Links) where any
  # inherited `Accrue.Connect.with_account/2` scope would cause Stripe to
  # 400 — the `Stripe-Account` header is forbidden on these endpoints.
  @spec build_platform_client!(keyword()) :: LatticeStripe.Client.t()
  defp build_platform_client!(opts) do
    key =
      case Application.get_env(:accrue, :stripe_secret_key) do
        nil ->
          raise Accrue.ConfigError,
            key: :stripe_secret_key,
            message:
              "Set config :accrue, :stripe_secret_key in runtime.exs before using " <>
                "Accrue.Processor.Stripe"

        "" ->
          raise Accrue.ConfigError,
            key: :stripe_secret_key,
            message: "config :accrue, :stripe_secret_key is empty; set it in runtime.exs"

        value when is_binary(value) ->
          value
      end

    LatticeStripe.Client.new!(
      api_key: key,
      api_version: resolve_api_version(opts),
      stripe_account: nil
    )
  end

  # ---------------------------------------------------------------------------
  # fetch/2 — generic refetch dispatch (D3-48)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def fetch(:subscription, id), do: retrieve_subscription(id, [])
  def fetch(:subscription_schedule, id), do: subscription_schedule_fetch(id, [])
  def fetch(:invoice, id), do: retrieve_invoice(id, [])
  def fetch(:charge, id), do: retrieve_charge(id, [])
  def fetch(:refund, id), do: retrieve_refund(id, [])
  def fetch(:payment_method, id), do: retrieve_payment_method(id, [])
  def fetch(:customer, id), do: retrieve_customer(id, [])
  def fetch(:payment_intent, id), do: retrieve_payment_intent(id, [])
  def fetch(:setup_intent, id), do: retrieve_setup_intent(id, [])
  def fetch(:checkout_session, id), do: checkout_session_fetch(id, [])

  # ---------------------------------------------------------------------------
  # Phase 3 helpers
  # ---------------------------------------------------------------------------

  @spec stripe_opts(atom(), String.t(), keyword()) :: keyword()
  defp stripe_opts(op, subject_id, opts) do
    # CR-01: Preserve an explicit caller-supplied idempotency key (from
    # the billing context, computed via Accrue.Processor.Idempotency.key/4
    # with the D3-60/61 deterministic subject_uuid). Only compute our own
    # as a fallback when the caller didn't supply one (e.g. direct adapter
    # use outside the billing context). The SHA256 seed for the
    # fallback is still based on (op, subject_id, operation_id) for
    # parity with PROC-02.
    idem_key =
      Keyword.get(opts, :idempotency_key) ||
        compute_idempotency_key(op, subject_id, opts)

    opts
    |> Keyword.put(:idempotency_key, idem_key)
    |> Keyword.put(:stripe_version, resolve_api_version(opts))
  end

  @spec stripe_opts_no_idem(keyword()) :: keyword()
  defp stripe_opts_no_idem(opts) do
    Keyword.put(opts, :stripe_version, resolve_api_version(opts))
  end

  @spec subject_of(map(), String.t()) :: String.t()
  defp subject_of(params, fallback_prefix) do
    params[:customer] || params["customer"] ||
      params[:charge] || params["charge"] ||
      params[:subscription] || params["subscription"] ||
      "#{fallback_prefix}_new"
  end

  @spec ensure_expand(map(), [String.t()]) :: map()
  defp ensure_expand(params, paths) do
    existing =
      Map.get(params, :expand) || Map.get(params, "expand") || []

    expand = Enum.uniq(existing ++ paths)

    params
    |> Map.delete("expand")
    |> Map.put(:expand, expand)
  end

  @spec translate_resource({:ok, struct() | map()} | {:error, term()}) ::
          {:ok, map()} | {:error, Exception.t()}
  defp translate_resource({:ok, %_{} = result}), do: {:ok, Map.from_struct(result)}
  defp translate_resource({:error, raw}), do: {:error, ErrorMapper.to_accrue_error(raw)}

  # ---------------------------------------------------------------------------
  # Idempotency keys (D2-11, D2-12, PROC-04)
  # ---------------------------------------------------------------------------

  @doc """
  Computes a deterministic idempotency key from the operation, subject ID,
  and a seed (D2-11). The seed resolution chain is (D2-12):

    1. `opts[:operation_id]` (explicit)
    2. `Accrue.Actor.current_operation_id/0` (process dict)
    3. Random UUID + `Logger.warning` (non-deterministic fallback)

  Returns a string like `"accr_<22 url-safe base64 chars>"`.
  """
  @spec compute_idempotency_key(atom(), String.t(), keyword()) :: String.t()
  def compute_idempotency_key(op, subject_id, opts \\ [])
      when is_atom(op) and is_list(opts) do
    seed =
      Keyword.get(opts, :operation_id) ||
        Accrue.Actor.current_operation_id() ||
        random_seed_with_warning(op, subject_id)

    raw = :crypto.hash(:sha256, "#{op}|#{subject_id}|#{seed}")
    "accr_" <> (Base.url_encode64(raw, padding: false) |> binary_part(0, 22))
  end

  # ---------------------------------------------------------------------------
  # API version override (D2-14, D2-15, PROC-06)
  # ---------------------------------------------------------------------------

  @doc """
  Resolves the Stripe API version using three-level precedence (D2-14):

    1. `opts[:api_version]` (explicit per-call override)
    2. `Process.get(:accrue_stripe_api_version)` (scoped via `Accrue.Stripe.with_api_version/2`)
    3. `Accrue.Config.stripe_api_version/0` (application config default)
  """
  @spec resolve_api_version(keyword()) :: String.t()
  def resolve_api_version(opts \\ []) when is_list(opts) do
    Keyword.get(opts, :api_version) ||
      Process.get(:accrue_stripe_api_version) ||
      Accrue.Config.stripe_api_version()
  end

  @doc """
  Resolves the Stripe-Account header using three-level precedence (D5-01):

    1. `opts[:stripe_account]` (explicit per-call override)
    2. `Process.get(:accrue_connected_account_id)` (via `Accrue.Connect.with_account/2`
       — scoped pdict key; the `Accrue.Connect` module itself lands in Plan 05-02)
    3. `Accrue.Config.connect/0` `[:default_stripe_account]` (config fallback)

  Returns `nil` when no connected-account context is set, which preserves
  platform-scoped behavior: `lattice_stripe` omits the `Stripe-Account`
  header when the client is built with `stripe_account: nil`.
  """
  @spec resolve_stripe_account(keyword()) :: String.t() | nil
  def resolve_stripe_account(opts \\ []) when is_list(opts) do
    Keyword.get(opts, :stripe_account) ||
      Process.get(:accrue_connected_account_id) ||
      Keyword.get(Accrue.Config.connect(), :default_stripe_account)
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  @spec build_client!(keyword()) :: LatticeStripe.Client.t()
  defp build_client!(opts) do
    key =
      case Application.get_env(:accrue, :stripe_secret_key) do
        nil ->
          raise Accrue.ConfigError,
            key: :stripe_secret_key,
            message:
              "Set config :accrue, :stripe_secret_key in runtime.exs before using " <>
                "Accrue.Processor.Stripe"

        "" ->
          raise Accrue.ConfigError,
            key: :stripe_secret_key,
            message: "config :accrue, :stripe_secret_key is empty; set it in runtime.exs"

        value when is_binary(value) ->
          value
      end

    api_version = resolve_api_version(opts)
    stripe_account = resolve_stripe_account(opts)

    LatticeStripe.Client.new!(
      api_key: key,
      api_version: api_version,
      stripe_account: stripe_account
    )
  end

  defp random_seed_with_warning(op, subject_id) do
    seed = Ecto.UUID.generate()

    Logger.warning(
      "Accrue.Processor.Stripe: no operation_id seed for #{op}/#{subject_id}; " <>
        "retries will NOT be idempotent"
    )

    seed
  end

  @spec translate_customer({:ok, LatticeStripe.Customer.t()} | {:error, term()}) ::
          {:ok, map()} | {:error, Exception.t()}
  defp translate_customer({:ok, %LatticeStripe.Customer{} = customer}) do
    {:ok, customer_to_map(customer)}
  end

  defp translate_customer({:error, raw}) do
    {:error, ErrorMapper.to_accrue_error(raw)}
  end

  @spec customer_to_map(LatticeStripe.Customer.t()) :: map()
  defp customer_to_map(%LatticeStripe.Customer{} = c) do
    # Convert to a plain map so downstream code never pattern-matches on
    # a LatticeStripe struct. Keep all fields — this is the full Phase 1
    # shape Billing will consume. Drop the :__struct__ key explicitly.
    c
    |> Map.from_struct()
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end
end
