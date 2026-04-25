defmodule Accrue.Billing do
  @moduledoc """
  Primary context module for Accrue billing operations.

  All write operations for billable entities live here, following
  conventional Phoenix context boundaries. Host schemas gain access to
  these operations via `use Accrue.Billable`, which injects a
  convenience `customer/1` that delegates here.

  ## Customer lifecycle

    * `customer/1` — lazy fetch-or-create. First call
      auto-creates an `accrue_customers` row via the configured
      processor; subsequent calls return the cached row.
    * `create_customer/1` — explicit create, always hits the processor.
    * `customer!/1` and `create_customer!/1` — raising variants following
      the same `{:ok, _} | {:error, _}` vs `!` naming convention as the rest
      of Accrue.

  All writes use `Ecto.Multi` to ensure the customer row and the
  corresponding `accrue_events` entry are committed atomically.
  """

  alias Accrue.Billing.Customer
  alias Accrue.BillingPortal.Session
  alias Accrue.Checkout.Session, as: CheckoutSession

  alias Accrue.Billing.{
    ChargeActions,
    CouponActions,
    InvoiceActions,
    MeterEventActions,
    PaymentMethodActions,
    RefundActions,
    SubscriptionActions,
    SubscriptionItems,
    SubscriptionScheduleActions
  }

  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Repo

  import Ecto.Query, only: [from: 2]

  # ---------------------------------------------------------------------------
  # Subscription management
  # ---------------------------------------------------------------------------
  def subscribe(user, price_id_or_opts \\ [], opts \\ []) do
    span_billing(:subscription, :create, user, opts, fn ->
      SubscriptionActions.subscribe(user, price_id_or_opts, opts)
    end)
  end

  def subscribe!(user, price_id_or_opts \\ [], opts \\ []) do
    span_billing(:subscription, :create, user, opts, fn ->
      SubscriptionActions.subscribe!(user, price_id_or_opts, opts)
    end)
  end

  def get_subscription(id, opts \\ []) do
    span_billing(:subscription, :get, %{subscription_id: id}, opts, fn ->
      SubscriptionActions.get_subscription(id, opts)
    end)
  end

  def get_subscription!(id, opts \\ []) do
    span_billing(:subscription, :get, %{subscription_id: id}, opts, fn ->
      SubscriptionActions.get_subscription!(id, opts)
    end)
  end

  def swap_plan(sub, new_price_id, opts) do
    span_billing(:subscription, :swap_plan, sub, opts, fn ->
      SubscriptionActions.swap_plan(sub, new_price_id, opts)
    end)
  end

  def swap_plan!(sub, new_price_id, opts) do
    span_billing(:subscription, :swap_plan, sub, opts, fn ->
      SubscriptionActions.swap_plan!(sub, new_price_id, opts)
    end)
  end

  def cancel(sub, opts \\ []),
    do: span_subscription(:cancel, sub, opts, &SubscriptionActions.cancel/2)

  def cancel!(sub, opts \\ []),
    do: span_subscription(:cancel, sub, opts, &SubscriptionActions.cancel!/2)

  def cancel_at_period_end(sub, opts \\ []),
    do:
      span_subscription(
        :cancel_at_period_end,
        sub,
        opts,
        &SubscriptionActions.cancel_at_period_end/2
      )

  def cancel_at_period_end!(sub, opts \\ []),
    do:
      span_subscription(
        :cancel_at_period_end,
        sub,
        opts,
        &SubscriptionActions.cancel_at_period_end!/2
      )

  def resume(sub, opts \\ []),
    do: span_subscription(:resume, sub, opts, &SubscriptionActions.resume/2)

  def resume!(sub, opts \\ []),
    do: span_subscription(:resume, sub, opts, &SubscriptionActions.resume!/2)

  def pause(sub, opts \\ []),
    do: span_subscription(:pause, sub, opts, &SubscriptionActions.pause/2)

  def pause!(sub, opts \\ []),
    do: span_subscription(:pause, sub, opts, &SubscriptionActions.pause!/2)

  def unpause(sub, opts \\ []),
    do: span_subscription(:unpause, sub, opts, &SubscriptionActions.unpause/2)

  def unpause!(sub, opts \\ []),
    do: span_subscription(:unpause, sub, opts, &SubscriptionActions.unpause!/2)

  def update_quantity(sub, quantity, opts \\ []) do
    span_billing(:subscription, :update_quantity, sub, opts, fn ->
      SubscriptionActions.update_quantity(sub, quantity, opts)
    end)
  end

  def update_quantity!(sub, quantity, opts \\ []) do
    span_billing(:subscription, :update_quantity, sub, opts, fn ->
      SubscriptionActions.update_quantity!(sub, quantity, opts)
    end)
  end

  def preview_upcoming_invoice(sub_or_customer, opts \\ []) do
    span_billing(:invoice, :preview_upcoming, sub_or_customer, opts, fn ->
      SubscriptionActions.preview_upcoming_invoice(sub_or_customer, opts)
    end)
  end

  def preview_upcoming_invoice!(sub_or_customer, opts \\ []) do
    span_billing(:invoice, :preview_upcoming, sub_or_customer, opts, fn ->
      SubscriptionActions.preview_upcoming_invoice!(sub_or_customer, opts)
    end)
  end

  # ── Advanced subscription management ──────────────────────────────
  def comp_subscription(billable, price_spec, opts \\ []) do
    span_billing(:subscription, :comp, billable, opts, fn ->
      SubscriptionActions.comp_subscription(billable, price_spec, opts)
    end)
  end

  def comp_subscription!(billable, price_spec, opts \\ []) do
    span_billing(:subscription, :comp, billable, opts, fn ->
      SubscriptionActions.comp_subscription!(billable, price_spec, opts)
    end)
  end

  def add_item(sub, price_id, opts \\ []) do
    span_billing(:subscription_item, :add, sub, opts, fn ->
      SubscriptionItems.add_item(sub, price_id, opts)
    end)
  end

  def add_item!(sub, price_id, opts \\ []) do
    span_billing(:subscription_item, :add, sub, opts, fn ->
      SubscriptionItems.add_item!(sub, price_id, opts)
    end)
  end

  def remove_item(item, opts \\ []),
    do: span_subscription_item(:remove, item, opts, &SubscriptionItems.remove_item/2)

  def remove_item!(item, opts \\ []),
    do: span_subscription_item(:remove, item, opts, &SubscriptionItems.remove_item!/2)

  def update_item_quantity(item, quantity, opts \\ []) do
    span_billing(:subscription_item, :update_quantity, item, opts, fn ->
      SubscriptionItems.update_item_quantity(item, quantity, opts)
    end)
  end

  def update_item_quantity!(item, quantity, opts \\ []) do
    span_billing(:subscription_item, :update_quantity, item, opts, fn ->
      SubscriptionItems.update_item_quantity!(item, quantity, opts)
    end)
  end

  # ── SubscriptionSchedule management ───────────────────────────────
  def subscribe_via_schedule(billable, phases, opts \\ []) do
    span_billing(:subscription_schedule, :create, billable, opts, fn ->
      SubscriptionScheduleActions.subscribe_via_schedule(billable, phases, opts)
    end)
  end

  def subscribe_via_schedule!(billable, phases, opts \\ []) do
    span_billing(:subscription_schedule, :create, billable, opts, fn ->
      SubscriptionScheduleActions.subscribe_via_schedule!(billable, phases, opts)
    end)
  end

  def update_schedule(sched, params, opts \\ []) do
    span_billing(:subscription_schedule, :update, sched, opts, fn ->
      SubscriptionScheduleActions.update_schedule(sched, params, opts)
    end)
  end

  def update_schedule!(sched, params, opts \\ []) do
    span_billing(:subscription_schedule, :update, sched, opts, fn ->
      SubscriptionScheduleActions.update_schedule!(sched, params, opts)
    end)
  end

  def release_schedule(sched, opts \\ []),
    do: span_schedule(:release, sched, opts, &SubscriptionScheduleActions.release_schedule/2)

  def release_schedule!(sched, opts \\ []),
    do: span_schedule(:release, sched, opts, &SubscriptionScheduleActions.release_schedule!/2)

  def cancel_schedule(sched, opts \\ []),
    do: span_schedule(:cancel, sched, opts, &SubscriptionScheduleActions.cancel_schedule/2)

  def cancel_schedule!(sched, opts \\ []),
    do: span_schedule(:cancel, sched, opts, &SubscriptionScheduleActions.cancel_schedule!/2)

  # ── Invoice management ────────────────────────────────────────────
  def finalize_invoice(invoice, opts \\ []),
    do: span_invoice(:finalize, invoice, opts, &InvoiceActions.finalize_invoice/2)

  def finalize_invoice!(invoice, opts \\ []),
    do: span_invoice(:finalize, invoice, opts, &InvoiceActions.finalize_invoice!/2)

  def void_invoice(invoice, opts \\ []),
    do: span_invoice(:void, invoice, opts, &InvoiceActions.void_invoice/2)

  def void_invoice!(invoice, opts \\ []),
    do: span_invoice(:void, invoice, opts, &InvoiceActions.void_invoice!/2)

  def pay_invoice(invoice, opts \\ []),
    do: span_invoice(:pay, invoice, opts, &InvoiceActions.pay_invoice/2)

  def pay_invoice!(invoice, opts \\ []),
    do: span_invoice(:pay, invoice, opts, &InvoiceActions.pay_invoice!/2)

  def mark_uncollectible(invoice, opts \\ []),
    do: span_invoice(:mark_uncollectible, invoice, opts, &InvoiceActions.mark_uncollectible/2)

  def mark_uncollectible!(invoice, opts \\ []),
    do: span_invoice(:mark_uncollectible, invoice, opts, &InvoiceActions.mark_uncollectible!/2)

  def send_invoice(invoice, opts \\ []),
    do: span_invoice(:send, invoice, opts, &InvoiceActions.send_invoice/2)

  def send_invoice!(invoice, opts \\ []),
    do: span_invoice(:send, invoice, opts, &InvoiceActions.send_invoice!/2)

  # ── Charges, PaymentIntents, and SetupIntents ─────────────────────
  def charge(customer, amount_or_opts, opts \\ []) do
    span_billing(:charge, :create, customer, opts, fn ->
      ChargeActions.charge(customer, amount_or_opts, opts)
    end)
  end

  def charge!(customer, amount_or_opts, opts \\ []) do
    span_billing(:charge, :create, customer, opts, fn ->
      ChargeActions.charge!(customer, amount_or_opts, opts)
    end)
  end

  def create_payment_intent(customer, opts \\ []) do
    span_billing(:payment_intent, :create, customer, opts, fn ->
      ChargeActions.create_payment_intent(customer, opts)
    end)
  end

  def create_payment_intent!(customer, opts \\ []) do
    span_billing(:payment_intent, :create, customer, opts, fn ->
      ChargeActions.create_payment_intent!(customer, opts)
    end)
  end

  def create_setup_intent(customer, opts \\ []) do
    span_billing(:setup_intent, :create, customer, opts, fn ->
      ChargeActions.create_setup_intent(customer, opts)
    end)
  end

  def create_setup_intent!(customer, opts \\ []) do
    span_billing(:setup_intent, :create, customer, opts, fn ->
      ChargeActions.create_setup_intent!(customer, opts)
    end)
  end

  # ── PaymentMethod management ──────────────────────────────────────
  def attach_payment_method(customer, pm_id_or_opts, opts \\ []) do
    span_billing(:payment_method, :attach, customer, opts, fn ->
      PaymentMethodActions.attach_payment_method(customer, pm_id_or_opts, opts)
    end)
  end

  def attach_payment_method!(customer, pm_id_or_opts, opts \\ []) do
    span_billing(:payment_method, :attach, customer, opts, fn ->
      PaymentMethodActions.attach_payment_method!(customer, pm_id_or_opts, opts)
    end)
  end

  def detach_payment_method(payment_method, opts \\ []),
    do:
      span_billing(:payment_method, :detach, payment_method, opts, fn ->
        PaymentMethodActions.detach_payment_method(payment_method, opts)
      end)

  def detach_payment_method!(payment_method, opts \\ []),
    do:
      span_billing(:payment_method, :detach, payment_method, opts, fn ->
        PaymentMethodActions.detach_payment_method!(payment_method, opts)
      end)

  def set_default_payment_method(customer, pm_id, opts \\ []) do
    span_billing(:payment_method, :set_default, customer, opts, fn ->
      PaymentMethodActions.set_default_payment_method(customer, pm_id, opts)
    end)
  end

  def set_default_payment_method!(customer, pm_id, opts \\ []) do
    span_billing(:payment_method, :set_default, customer, opts, fn ->
      PaymentMethodActions.set_default_payment_method!(customer, pm_id, opts)
    end)
  end

  @doc """
  Lists payment methods for `customer` from the configured processor (Stripe
  or Fake). This is **read-through** processor state, not a projection of
  local `accrue_payment_methods` rows.

  Delegates to `Accrue.Billing.PaymentMethodActions.list_payment_methods/2`.
  See that module for supported `opts` filters (`type`, `limit`, pagination
  cursors).
  """
  def list_payment_methods(customer, opts \\ []) do
    span_billing(:payment_method, :list, customer, opts, fn ->
      PaymentMethodActions.list_payment_methods(customer, opts)
    end)
  end

  @doc """
  Raising variant of `list_payment_methods/2`.

  Delegates to `Accrue.Billing.PaymentMethodActions.list_payment_methods!/2`.
  """
  def list_payment_methods!(customer, opts \\ []) do
    span_billing(:payment_method, :list, customer, opts, fn ->
      PaymentMethodActions.list_payment_methods!(customer, opts)
    end)
  end

  @billing_portal_session_attrs_schema [
    return_url: [type: {:or, [:string, nil]}, default: nil],
    configuration: [type: {:or, [:string, nil]}, default: nil],
    flow_data: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    locale: [type: {:or, [:string, nil]}, default: nil],
    on_behalf_of: [type: {:or, [:string, nil]}, default: nil],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @doc """
  Creates a Customer Billing Portal session for `customer` through the
  configured processor.

  `attrs` is a keyword list or map of options aligned with
  `Accrue.BillingPortal.Session.create/1`, **except** `:customer` (supplied as
  the first argument): `:return_url`, `:configuration`, `:flow_data`,
  `:locale`, `:on_behalf_of`, `:operation_id`.

  Invalid keys or types raise `NimbleOptions.ValidationError`.

  The portal session **URL** is a short-lived bearer credential. Do **not**
  log raw session structs, processor payloads, or URLs in production telemetry
  or support tickets. For `:configuration`, see
  `guides/portal_configuration_checklist.md`.

  Emits `[:accrue, :billing, :billing_portal, :create]` (OpenTelemetry name
  `accrue.billing.billing_portal.create`).
  """
  @spec create_billing_portal_session(Customer.t(), keyword() | map()) ::
          {:ok, Session.t()} | {:error, term()}
  def create_billing_portal_session(%Customer{} = customer, attrs)
      when is_list(attrs) or is_map(attrs) do
    opts_list = if is_list(attrs), do: attrs, else: Map.to_list(attrs)
    validated = NimbleOptions.validate!(opts_list, @billing_portal_session_attrs_schema)

    span_billing(:billing_portal, :create, customer, validated, fn ->
      Session.create(Map.new([customer: customer] ++ validated))
    end)
  end

  @doc """
  Bang variant of `create_billing_portal_session/2` — returns
  `%Accrue.BillingPortal.Session{}` or raises.

  Raises `NimbleOptions.ValidationError` when `attrs` fail validation.

  On `{:error, reason}` from the underlying `Session.create/1`, re-raises when
  `reason` implements `Exception`; otherwise raises the same message shape as
  `Accrue.BillingPortal.Session.create!/1`.
  """
  @spec create_billing_portal_session!(Customer.t(), keyword() | map()) :: Session.t()
  def create_billing_portal_session!(%Customer{} = customer, attrs)
      when is_list(attrs) or is_map(attrs) do
    case create_billing_portal_session(customer, attrs) do
      {:ok, session} ->
        session

      {:error, err} when is_exception(err) ->
        raise err

      {:error, other} ->
        raise "Accrue.BillingPortal.Session.create/1 failed: #{inspect(other)}"
    end
  end

  @checkout_session_facade_attrs_schema [
    mode: [type: {:in, [:subscription, :payment, :setup]}, default: :subscription],
    ui_mode: [type: {:in, [:hosted, :embedded]}, default: :hosted],
    line_items: [type: {:list, {:map, :any, :any}}, default: []],
    success_url: [type: {:or, [:string, nil]}, default: nil],
    cancel_url: [type: {:or, [:string, nil]}, default: nil],
    return_url: [type: {:or, [:string, nil]}, default: nil],
    metadata: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    client_reference_id: [type: {:or, [:string, nil]}, default: nil],
    automatic_tax: [type: :boolean, default: false],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @doc """
  Creates a Stripe Checkout Session for `customer` through the configured
  processor.

  `attrs` is a keyword list or map of options aligned with
  `Accrue.Checkout.Session.create/1`, **except** `:customer` (supplied as the
  first argument): `:mode`, `:ui_mode`, `:line_items`, `:success_url`,
  `:cancel_url`, `:return_url`, `:metadata`, `:client_reference_id`,
  `:automatic_tax`, `:operation_id`.

  Invalid keys or types raise `NimbleOptions.ValidationError`.

  The Checkout **redirect URL** (hosted mode) and **`client_secret`** (embedded
  mode) are bearer credentials. Do **not** log raw session structs, processor
  payloads, or URLs in production telemetry or support tickets.

  Emits `[:accrue, :billing, :checkout_session, :create]` (OpenTelemetry-style
  name `accrue.billing.checkout_session.create`). See `m:Accrue.Checkout.Session`
  for field semantics and the underlying `@create_schema`.
  """
  @spec create_checkout_session(Customer.t(), keyword() | map()) ::
          {:ok, CheckoutSession.t()} | {:error, term()}
  def create_checkout_session(%Customer{} = customer, attrs)
      when is_list(attrs) or is_map(attrs) do
    opts_list = if is_list(attrs), do: attrs, else: Map.to_list(attrs)
    validated = NimbleOptions.validate!(opts_list, @checkout_session_facade_attrs_schema)

    span_billing(:checkout_session, :create, customer, validated, fn ->
      CheckoutSession.create(Map.new([customer: customer] ++ validated))
    end)
  end

  @doc """
  Bang variant of `create_checkout_session/2` — returns
  `%Accrue.Checkout.Session{}` or raises.

  Raises `NimbleOptions.ValidationError` when `attrs` fail validation.

  On `{:error, reason}` from the underlying `CheckoutSession.create/1`,
  re-raises when `reason` implements `Exception`; otherwise raises with prefix
  `Accrue.Checkout.Session.create/1 failed:`.
  """
  @spec create_checkout_session!(Customer.t(), keyword() | map()) :: CheckoutSession.t()
  def create_checkout_session!(%Customer{} = customer, attrs)
      when is_list(attrs) or is_map(attrs) do
    case create_checkout_session(customer, attrs) do
      {:ok, session} ->
        session

      {:error, err} when is_exception(err) ->
        raise err

      {:error, other} ->
        raise "Accrue.Checkout.Session.create/1 failed: #{inspect(other)}"
    end
  end

  # ── Refunds ───────────────────────────────────────────────────────
  def create_refund(charge, opts \\ []),
    do:
      span_billing(:refund, :create, charge, opts, fn ->
        RefundActions.create_refund(charge, opts)
      end)

  def create_refund!(charge, opts \\ []),
    do:
      span_billing(:refund, :create, charge, opts, fn ->
        RefundActions.create_refund!(charge, opts)
      end)

  # ── Invoice PDF rendering ─────────────────────────────────────────
  def render_invoice_pdf(invoice_or_id, opts \\ []),
    do: span_invoice(:render_pdf, invoice_or_id, opts, &Accrue.Invoices.render_invoice_pdf/2)

  def store_invoice_pdf(invoice_or_id, opts \\ []),
    do: span_invoice(:store_pdf, invoice_or_id, opts, &Accrue.Invoices.store_invoice_pdf/2)

  def fetch_invoice_pdf(invoice_or_id),
    do:
      span_invoice(:fetch_pdf, invoice_or_id, [], fn invoice, _opts ->
        Accrue.Invoices.fetch_invoice_pdf(invoice)
      end)

  # ── Metered billing ───────────────────────────────────────────────
  @report_usage_doc """
  `report_usage/3` records a metered usage event for `customer` (a `%Accrue.Billing.Customer{}` or Stripe customer id string) and `event_name`, persisting through the transactional outbox before invoking the configured processor.

  ## Options

  Keys mirror `Accrue.Billing.MeterEventActions`'s `@report_usage_schema` (types and defaults stay in sync there):

  * `:value` — non-negative integer count; default `1`.
  * `:timestamp` — `%DateTime{}`, Unix seconds as integer, or `nil`. When `nil`, normalization uses the current UTC instant; see `Accrue.Billing.MeterEventActions` for the exact normalization pipeline.
  * `:identifier` — string or `nil`; default `nil` derives a stable audit-layer identifier from customer, `event_name`, `:value`, the resolved timestamp, and optional `:operation_id` (uniqueness enforced on `accrue_meter_events.identifier`).
  * `:operation_id` — string or `nil`; when set, it participates in identifier derivation and supports idempotent replays alongside the other fields above.
  * `:payload` — map of extra dimensions or `nil`; default `nil`. Forwarded to the processor as supplemental context (e.g. `%{"dimension" => "seats"}` in tests).

  Invalid `opts` raise `NimbleOptions.ValidationError` from `NimbleOptions.validate!/2`.

  ## Error tuples vs persisted rows

  `{:error, _}` means this **call** could not advance durable meter state as
  requested (for example the processor rejected the usage report). After
  retries with the same idempotency inputs, `{:ok, %Accrue.Billing.MeterEvent{}}`
  may be returned when the row already reflects a terminal outcome — inspect
  `stripe_status` and `stripe_error` on the persisted row for the canonical
  failure details. See `guides/metering.md` for how public calls, internal rows,
  and the processor seam relate.

  ## Fake / test mode

  Host apps can configure `Accrue.Processor.Fake` (for example via `Accrue.Test.setup_fake_processor/1`) to exercise this path without outbound network calls.
  """
  @doc @report_usage_doc
  def report_usage(customer, event_name, opts \\ []) do
    span_billing(
      :meter_event,
      :report_usage,
      customer,
      Keyword.put(opts, :event_type, event_name),
      fn ->
        MeterEventActions.report_usage(customer, event_name, opts)
      end
    )
  end

  @report_usage_bang_doc """
  Bang variant of `report_usage/3` — returns `%Accrue.Billing.MeterEvent{}` or raises on error.

  See `report_usage/3` for the full options reference (`## Options`).

  Raises `NimbleOptions.ValidationError` when `opts` fail validation.

  Raises on `{:error, _}` from the underlying implementation when that tuple
  indicates a true failure for this invocation (for example a missing customer
  or a processor error that performed the failing attempt). When the non-bang
  `report_usage/3` would return `{:ok, row}` on an idempotent replay (including
  a row already in `failed`), this function returns that row without raising.
  `Accrue.APIError` (including `resource_missing` / HTTP 404) is re-raised when
  it implements `Exception`; other error tuples become a `RuntimeError` raised by
  `Accrue.Billing.MeterEventActions.report_usage!/3`.
  """
  @doc @report_usage_bang_doc
  def report_usage!(customer, event_name, opts \\ []) do
    span_billing(
      :meter_event,
      :report_usage,
      customer,
      Keyword.put(opts, :event_type, event_name),
      fn ->
        MeterEventActions.report_usage!(customer, event_name, opts)
      end
    )
  end

  # ── Coupons + PromotionCodes ──────────────────────────────────────
  def create_coupon(params, opts \\ []),
    do:
      span_billing(:coupon, :create, params, opts, fn ->
        CouponActions.create_coupon(params, opts)
      end)

  def create_coupon!(params, opts \\ []),
    do:
      span_billing(:coupon, :create, params, opts, fn ->
        CouponActions.create_coupon!(params, opts)
      end)

  def create_promotion_code(params, opts \\ []),
    do:
      span_billing(:promotion_code, :create, params, opts, fn ->
        CouponActions.create_promotion_code(params, opts)
      end)

  def create_promotion_code!(params, opts \\ []),
    do:
      span_billing(:promotion_code, :create, params, opts, fn ->
        CouponActions.create_promotion_code!(params, opts)
      end)

  def apply_promotion_code(sub, code, opts \\ []) do
    span_billing(:promotion_code, :apply, sub, opts, fn ->
      CouponActions.apply_promotion_code(sub, code, opts)
    end)
  end

  def apply_promotion_code!(sub, code, opts \\ []) do
    span_billing(:promotion_code, :apply, sub, opts, fn ->
      CouponActions.apply_promotion_code!(sub, code, opts)
    end)
  end

  # ---------------------------------------------------------------------------
  # Customer — lazy fetch-or-create
  # ---------------------------------------------------------------------------

  @doc """
  Lazily fetches or creates a `Customer` for the given billable struct.

  If a customer row already exists for the billable's `owner_type` and
  `owner_id`, returns it. Otherwise, creates one via the configured
  processor and persists it atomically with an event record.

  ## Examples

      {:ok, customer} = Accrue.Billing.customer(user)
      {:ok, ^customer} = Accrue.Billing.customer(user)  # same row
  """
  @spec customer(struct()) :: {:ok, Customer.t()} | {:error, term()}
  def customer(%{__struct__: mod, id: id} = billable) do
    span_billing(:customer, :get_or_create, billable, [], fn ->
      billable_type = mod.__accrue__(:billable_type)
      owner_id = to_string(id)

      case fetch_customer(billable_type, owner_id) do
        %Customer{} = existing ->
          {:ok, existing}

        nil ->
          case create_customer(billable) do
            {:ok, customer} ->
              {:ok, customer}

            {:error, %Ecto.Changeset{} = cs} ->
              # Unique constraint race -- another process created the customer
              # between our SELECT and INSERT. Retry the fetch.
              if cs.errors[:owner_id] do
                case fetch_customer(billable_type, owner_id) do
                  %Customer{} = existing -> {:ok, existing}
                  nil -> {:error, cs}
                end
              else
                {:error, cs}
              end

            {:error, reason} ->
              {:error, reason}
          end
      end
    end)
  end

  defp fetch_customer(billable_type, owner_id) do
    query =
      from(c in Customer,
        where: c.owner_type == ^billable_type and c.owner_id == ^owner_id,
        limit: 1
      )

    Repo.one(query)
  end

  @doc """
  Raising variant of `customer/1`. Returns the `Customer` directly or
  raises on error.
  """
  @spec customer!(struct()) :: Customer.t()
  def customer!(billable) do
    span_billing(:customer, :get_or_create, billable, [], fn ->
      case customer(billable) do
        {:ok, customer} -> customer
        {:error, reason} -> raise "Failed to fetch or create customer: #{inspect(reason)}"
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Customer — explicit create
  # ---------------------------------------------------------------------------

  @doc """
  Explicitly creates a `Customer` for the given billable struct.

  Uses `Ecto.Multi` to atomically:

    1. Create the customer on the processor side (Fake or Stripe)
    2. Insert the `accrue_customers` row with the processor-assigned ID
    3. Record a `"customer.created"` event

  Returns `{:ok, %Customer{}}` on success or `{:error, reason}` on
  failure. The entire transaction rolls back if any step fails.

  ## Examples

      {:ok, customer} = Accrue.Billing.create_customer(user)
      customer.processor_id  #=> "cus_fake_00001"
  """
  @spec create_customer(struct()) :: {:ok, Customer.t()} | {:error, term()}
  def create_customer(%{__struct__: mod, id: id} = billable) do
    span_billing(:customer, :create, billable, [], fn ->
      billable_type = mod.__accrue__(:billable_type)
      owner_id = to_string(id)
      processor_name = processor_name()

      params = build_processor_params(billable)

      Repo.transact(fn ->
        with {:ok, processor_result} <- Processor.create_customer(params),
             customer_attrs = %{
               owner_type: billable_type,
               owner_id: owner_id,
               processor: processor_name,
               processor_id: Map.get(processor_result, :id),
               name: Map.get(processor_result, :name),
               email: Map.get(processor_result, :email),
               metadata: Map.get(processor_result, :metadata, %{}),
               data:
                 Map.drop(processor_result, [
                   :address,
                   :phone,
                   :shipping,
                   "address",
                   "phone",
                   "shipping"
                 ])
             },
             {:ok, customer} <-
               %Customer{} |> Customer.changeset(customer_attrs) |> Repo.insert(),
             {:ok, _event} <-
               Events.record(%{
                 type: "customer.created",
                 subject_type: "Customer",
                 subject_id: customer.id,
                 data: %{
                   owner_type: billable_type,
                   owner_id: owner_id,
                   processor: processor_name,
                   processor_id: customer.processor_id
                 }
               }) do
          {:ok, customer}
        end
      end)
    end)
  end

  @doc """
  Raising variant of `create_customer/1`. Returns the `Customer`
  directly or raises on error.
  """
  @spec create_customer!(struct()) :: Customer.t()
  def create_customer!(billable) do
    span_billing(:customer, :create, billable, [], fn ->
      case create_customer(billable) do
        {:ok, customer} -> customer
        {:error, reason} -> raise "Failed to create customer: #{inspect(reason)}"
      end
    end)
  end

  @doc """
  Updates a processor-backed customer's tax location with immediate validation.

  This public path is distinct from `update_customer/2`, which remains a
  local-only row update for non-processor customer maintenance.
  """
  @spec update_customer_tax_location(%Customer{}, map()) :: {:ok, Customer.t()} | {:error, term()}
  def update_customer_tax_location(%Customer{} = customer, attrs) when is_map(attrs) do
    span_billing(:customer, :tax_location_update, customer, [], fn ->
      Repo.transact(fn ->
        with {:ok, processor_result} <-
               Processor.update_customer(
                 customer.processor_id,
                 processor_tax_location_attrs(attrs),
                 []
               ),
             customer_attrs = customer_projection_attrs(processor_result),
             {:ok, updated} <-
               customer |> Customer.changeset(customer_attrs) |> Repo.update(),
             {:ok, _event} <-
               Events.record(%{
                 type: "customer.tax_location_updated",
                 subject_type: "Customer",
                 subject_id: updated.id,
                 data: %{
                   processor: updated.processor,
                   processor_id: updated.processor_id,
                   validate_location: "immediately",
                   changed_fields: tax_location_field_names(attrs)
                 }
               }) do
          {:ok, updated}
        end
      end)
    end)
  end

  @doc """
  Raising variant of `update_customer_tax_location/2`.
  """
  @spec update_customer_tax_location!(%Customer{}, map()) :: Customer.t()
  def update_customer_tax_location!(%Customer{} = customer, attrs) when is_map(attrs) do
    span_billing(:customer, :tax_location_update, customer, [], fn ->
      case update_customer_tax_location(customer, attrs) do
        {:ok, updated} -> updated
        {:error, reason} -> raise "Failed to update customer tax location: #{inspect(reason)}"
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Customer — update
  # ---------------------------------------------------------------------------

  @doc """
  Updates a `Customer` with the given attributes.

  Uses `Ecto.Multi` to atomically update the customer and record a
  `"customer.updated"` event. Metadata is validated as a flat string
  map (max 50 keys, etc.). Optimistic locking via `lock_version`
  prevents torn writes.

  ## Examples

      {:ok, customer} = Accrue.Billing.update_customer(customer, %{metadata: %{"tier" => "pro"}})
  """
  @spec update_customer(%Customer{}, map()) :: {:ok, Customer.t()} | {:error, term()}
  def update_customer(%Customer{} = customer, attrs) when is_map(attrs) do
    span_billing(:customer, :update, customer, [], fn ->
      Repo.transact(fn ->
        with {:ok, updated} <- customer |> Customer.changeset(attrs) |> Repo.update(),
             {:ok, _event} <-
               Events.record(%{
                 type: "customer.updated",
                 subject_type: "Customer",
                 subject_id: updated.id,
                 data: %{
                   changes:
                     Map.take(attrs, [:metadata, :name, :email, "metadata", "name", "email"])
                 }
               }) do
          {:ok, updated}
        end
      end)
    end)
  end

  # ---------------------------------------------------------------------------
  # Data operations
  # ---------------------------------------------------------------------------

  @doc """
  Fully replaces the `data` jsonb column on a billing record.

  Used by webhook reconcile paths that receive the whole object (e.g.
  `customer.updated`). Applies optimistic locking via `lock_version`.

  ## Examples

      {:ok, updated} = Accrue.Billing.put_data(customer, %{"balance" => 0})
  """
  @spec put_data(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def put_data(%{__struct__: _schema} = record, new_data) when is_map(new_data) do
    span_billing(:record, :put_data, record, [], fn ->
      record
      |> Ecto.Changeset.change(data: new_data)
      |> Ecto.Changeset.optimistic_lock(:lock_version)
      |> Repo.update()
    end)
  end

  @doc """
  Shallow-merges `partial_data` into the existing `data` column.

  Used when a partial event carries only a delta. Applies optimistic
  locking via `lock_version`.

  ## Examples

      {:ok, patched} = Accrue.Billing.patch_data(customer, %{"balance" => 100})
  """
  @spec patch_data(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def patch_data(%{__struct__: _schema} = record, partial_data) when is_map(partial_data) do
    span_billing(:record, :patch_data, record, [], fn ->
      merged = Map.merge(record.data || %{}, partial_data)
      put_data(record, merged)
    end)
  end

  defp customer_projection_attrs(processor_result) when is_map(processor_result) do
    %{
      name: Map.get(processor_result, :name),
      email: Map.get(processor_result, :email),
      metadata: Map.get(processor_result, :metadata, %{}),
      data: sanitize_customer_data(processor_result)
    }
  end

  defp sanitize_customer_data(processor_result) when is_map(processor_result) do
    Map.drop(processor_result, [
      :address,
      :shipping,
      :phone,
      :tax,
      "address",
      "shipping",
      "phone",
      "tax"
    ])
  end

  defp processor_tax_location_attrs(attrs) when is_map(attrs) do
    attrs
    |> Map.drop(["tax"])
    |> Map.delete(:tax)
    |> Map.put(:tax, immediate_tax_validation(Map.get(attrs, :tax) || Map.get(attrs, "tax")))
  end

  defp immediate_tax_validation(nil), do: %{validate_location: "immediately"}

  defp immediate_tax_validation(%{} = tax_attrs) do
    tax_attrs
    |> Map.drop(["validate_location"])
    |> Map.delete(:validate_location)
    |> Map.put(:validate_location, "immediately")
  end

  defp tax_location_field_names(attrs) when is_map(attrs) do
    [:address, :shipping, :phone, :tax]
    |> Enum.filter(fn key ->
      Map.has_key?(attrs, key) or Map.has_key?(attrs, Atom.to_string(key))
    end)
  end

  defp span_subscription(action, sub, opts, delegate) do
    span_billing(:subscription, action, sub, opts, fn -> delegate.(sub, opts) end)
  end

  defp span_subscription_item(action, item, opts, delegate) do
    span_billing(:subscription_item, action, item, opts, fn -> delegate.(item, opts) end)
  end

  defp span_schedule(action, sched, opts, delegate) do
    span_billing(:subscription_schedule, action, sched, opts, fn -> delegate.(sched, opts) end)
  end

  defp span_invoice(action, invoice, opts, delegate) do
    span_billing(:invoice, action, invoice, opts, fn -> delegate.(invoice, opts) end)
  end

  defp span_billing(resource, action, subject, opts, fun) do
    Accrue.Telemetry.span(
      [:accrue, :billing, resource, action],
      billing_metadata(resource, action, subject, opts),
      fun
    )
  end

  defp billing_metadata(resource, action, subject, opts) do
    %{}
    |> put_metadata(:processor, safe_processor_name())
    |> put_metadata(:operation, "#{resource}.#{action}")
    |> put_metadata(:customer_id, metadata_value(:customer_id, subject, opts))
    |> put_metadata(:subscription_id, metadata_value(:subscription_id, subject, opts))
    |> put_metadata(:invoice_id, metadata_value(:invoice_id, subject, opts))
    |> put_metadata(:event_type, keyword_value(opts, :event_type))
    |> merge_checkout_session_create_metadata(resource, action, opts)
  end

  defp merge_checkout_session_create_metadata(metadata, :checkout_session, :create, opts)
       when is_list(opts) do
    line_items = Keyword.get(opts, :line_items, [])

    metadata
    |> put_metadata(:checkout_mode, Keyword.get(opts, :mode))
    |> put_metadata(:checkout_ui_mode, Keyword.get(opts, :ui_mode))
    |> Map.put(:checkout_line_items_count, length(line_items))
  end

  defp merge_checkout_session_create_metadata(metadata, _, _, _), do: metadata

  defp metadata_value(field, subject, opts) do
    subject_value(subject, field) || keyword_value(opts, field)
  end

  defp subject_value(%Customer{id: id}, :customer_id), do: id
  defp subject_value(%{customer_id: id}, :customer_id), do: id
  defp subject_value(%{"customer_id" => id}, :customer_id), do: id
  defp subject_value(%{subscription_id: id}, :subscription_id), do: id
  defp subject_value(%{"subscription_id" => id}, :subscription_id), do: id
  defp subject_value(%{invoice_id: id}, :invoice_id), do: id
  defp subject_value(%{"invoice_id" => id}, :invoice_id), do: id

  defp subject_value(%{__struct__: module, id: id}, field) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> case do
      "subscription" when field == :subscription_id -> id
      "invoice" when field == :invoice_id -> id
      _ -> nil
    end
  end

  defp subject_value(_, _), do: nil

  defp keyword_value(opts, key) when is_list(opts), do: Keyword.get(opts, key)
  defp keyword_value(_, _), do: nil

  defp put_metadata(metadata, _key, nil), do: metadata
  defp put_metadata(metadata, _key, ""), do: metadata
  defp put_metadata(metadata, key, value), do: Map.put(metadata, key, to_string(value))

  defp safe_processor_name do
    processor_name()
  rescue
    _ -> nil
  catch
    _, _ -> nil
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp processor_name do
    adapter = Processor.__impl__()

    case adapter do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp build_processor_params(%{__struct__: _mod} = billable) do
    params = %{}

    params =
      if function_exported?(billable.__struct__, :__schema__, 1) do
        fields = billable.__struct__.__schema__(:fields)

        params
        |> maybe_put(:name, billable, fields)
        |> maybe_put(:email, billable, fields)
      else
        params
      end

    params
  end

  defp maybe_put(params, field, struct, fields) do
    if field in fields do
      case Map.get(struct, field) do
        nil -> params
        value -> Map.put(params, field, value)
      end
    else
      params
    end
  end
end
