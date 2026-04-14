defmodule Accrue.Billing do
  @moduledoc """
  Primary context module for Accrue billing operations.

  All write operations for billable entities live here, following
  Phoenix context conventions (D2-05). Host schemas gain access to
  these operations via `use Accrue.Billable`, which injects a
  convenience `customer/1` that delegates here.

  ## Customer lifecycle

    * `customer/1` — lazy fetch-or-create (D2-06). First call
      auto-creates an `accrue_customers` row via the configured
      processor; subsequent calls return the cached row.
    * `create_customer/1` — explicit create, always hits the processor.
    * `customer!/1` and `create_customer!/1` — raising variants per
      Phase 1 D-05 dual API pattern.

  All writes use `Ecto.Multi` to ensure the customer row and the
  corresponding `accrue_events` entry are committed atomically
  (EVT-04 invariant).
  """

  alias Accrue.Billing.Customer

  alias Accrue.Billing.{
    ChargeActions,
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
  # Phase 3 write-surface facade (D3-03, D3-58)
  #
  # Every Phase 3 public function is declared here via `defdelegate`, pointing
  # at a per-surface action module. Wave 2 plans (04/05/06) implement the real
  # logic in those action modules and MUST NOT touch this file — that's how
  # three parallel plans can run without colliding on billing.ex.
  #
  # `defdelegate` is resolved at runtime, so these compile even though the
  # target modules are empty stubs at Plan 03-01 time. Calling any of these
  # before Wave 2 lands will raise `UndefinedFunctionError` — that's fine,
  # those calls only exist in Wave 2 tests.
  # ---------------------------------------------------------------------------

  # ── Subscription surface (Plan 04) ────────────────────────────────
  defdelegate subscribe(user, price_id_or_opts \\ [], opts \\ []), to: SubscriptionActions
  defdelegate subscribe!(user, price_id_or_opts \\ [], opts \\ []), to: SubscriptionActions
  defdelegate get_subscription(id, opts \\ []), to: SubscriptionActions
  defdelegate get_subscription!(id, opts \\ []), to: SubscriptionActions
  defdelegate swap_plan(sub, new_price_id, opts), to: SubscriptionActions
  defdelegate swap_plan!(sub, new_price_id, opts), to: SubscriptionActions
  defdelegate cancel(sub, opts \\ []), to: SubscriptionActions
  defdelegate cancel!(sub, opts \\ []), to: SubscriptionActions
  defdelegate cancel_at_period_end(sub, opts \\ []), to: SubscriptionActions
  defdelegate cancel_at_period_end!(sub, opts \\ []), to: SubscriptionActions
  defdelegate resume(sub, opts \\ []), to: SubscriptionActions
  defdelegate resume!(sub, opts \\ []), to: SubscriptionActions
  defdelegate pause(sub, opts \\ []), to: SubscriptionActions
  defdelegate pause!(sub, opts \\ []), to: SubscriptionActions
  defdelegate unpause(sub, opts \\ []), to: SubscriptionActions
  defdelegate unpause!(sub, opts \\ []), to: SubscriptionActions
  defdelegate update_quantity(sub, quantity, opts \\ []), to: SubscriptionActions
  defdelegate update_quantity!(sub, quantity, opts \\ []), to: SubscriptionActions
  defdelegate preview_upcoming_invoice(sub_or_customer, opts \\ []), to: SubscriptionActions
  defdelegate preview_upcoming_invoice!(sub_or_customer, opts \\ []), to: SubscriptionActions

  # ── Advanced subscription surface (Phase 4 Plan 03) ───────────────
  defdelegate comp_subscription(billable, price_spec, opts \\ []), to: SubscriptionActions
  defdelegate comp_subscription!(billable, price_spec, opts \\ []), to: SubscriptionActions

  defdelegate add_item(sub, price_id, opts \\ []), to: SubscriptionItems
  defdelegate add_item!(sub, price_id, opts \\ []), to: SubscriptionItems
  defdelegate remove_item(item, opts \\ []), to: SubscriptionItems
  defdelegate remove_item!(item, opts \\ []), to: SubscriptionItems
  defdelegate update_item_quantity(item, quantity, opts \\ []), to: SubscriptionItems
  defdelegate update_item_quantity!(item, quantity, opts \\ []), to: SubscriptionItems

  # ── SubscriptionSchedule surface (Phase 4 Plan 03, BILL-16) ───────
  defdelegate subscribe_via_schedule(billable, phases, opts \\ []),
    to: SubscriptionScheduleActions

  defdelegate subscribe_via_schedule!(billable, phases, opts \\ []),
    to: SubscriptionScheduleActions

  defdelegate update_schedule(sched, params, opts \\ []), to: SubscriptionScheduleActions
  defdelegate update_schedule!(sched, params, opts \\ []), to: SubscriptionScheduleActions
  defdelegate release_schedule(sched, opts \\ []), to: SubscriptionScheduleActions
  defdelegate release_schedule!(sched, opts \\ []), to: SubscriptionScheduleActions
  defdelegate cancel_schedule(sched, opts \\ []), to: SubscriptionScheduleActions
  defdelegate cancel_schedule!(sched, opts \\ []), to: SubscriptionScheduleActions

  # ── Invoice surface (Plan 05) ─────────────────────────────────────
  defdelegate finalize_invoice(invoice, opts \\ []), to: InvoiceActions
  defdelegate finalize_invoice!(invoice, opts \\ []), to: InvoiceActions
  defdelegate void_invoice(invoice, opts \\ []), to: InvoiceActions
  defdelegate void_invoice!(invoice, opts \\ []), to: InvoiceActions
  defdelegate pay_invoice(invoice, opts \\ []), to: InvoiceActions
  defdelegate pay_invoice!(invoice, opts \\ []), to: InvoiceActions
  defdelegate mark_uncollectible(invoice, opts \\ []), to: InvoiceActions
  defdelegate mark_uncollectible!(invoice, opts \\ []), to: InvoiceActions
  defdelegate send_invoice(invoice, opts \\ []), to: InvoiceActions
  defdelegate send_invoice!(invoice, opts \\ []), to: InvoiceActions

  # ── Charge / PaymentIntent / SetupIntent surface (Plan 06) ────────
  defdelegate charge(customer, amount_or_opts, opts \\ []), to: ChargeActions
  defdelegate charge!(customer, amount_or_opts, opts \\ []), to: ChargeActions
  defdelegate create_payment_intent(customer, opts \\ []), to: ChargeActions
  defdelegate create_payment_intent!(customer, opts \\ []), to: ChargeActions
  defdelegate create_setup_intent(customer, opts \\ []), to: ChargeActions
  defdelegate create_setup_intent!(customer, opts \\ []), to: ChargeActions

  # ── PaymentMethod surface (Plan 06) ───────────────────────────────
  defdelegate attach_payment_method(customer, pm_id_or_opts, opts \\ []),
    to: PaymentMethodActions

  defdelegate attach_payment_method!(customer, pm_id_or_opts, opts \\ []),
    to: PaymentMethodActions

  defdelegate detach_payment_method(payment_method, opts \\ []), to: PaymentMethodActions
  defdelegate detach_payment_method!(payment_method, opts \\ []), to: PaymentMethodActions
  defdelegate set_default_payment_method(customer, pm_id, opts \\ []), to: PaymentMethodActions
  defdelegate set_default_payment_method!(customer, pm_id, opts \\ []), to: PaymentMethodActions

  # ── Refund surface (Plan 06) ──────────────────────────────────────
  defdelegate create_refund(charge, opts \\ []), to: RefundActions
  defdelegate create_refund!(charge, opts \\ []), to: RefundActions

  # ── Metered billing surface (Phase 4 Plan 02, BILL-13) ────────────
  defdelegate report_usage(customer, event_name, opts \\ []), to: MeterEventActions
  defdelegate report_usage!(customer, event_name, opts \\ []), to: MeterEventActions

  # ---------------------------------------------------------------------------
  # Customer — lazy fetch-or-create (D2-06)
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
    case customer(billable) do
      {:ok, customer} -> customer
      {:error, reason} -> raise "Failed to fetch or create customer: #{inspect(reason)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Customer — explicit create (D2-05)
  # ---------------------------------------------------------------------------

  @doc """
  Explicitly creates a `Customer` for the given billable struct.

  Uses `Ecto.Multi` to atomically:

    1. Create the customer on the processor side (Fake or Stripe)
    2. Insert the `accrue_customers` row with the processor-assigned ID
    3. Record a `"customer.created"` event (EVT-04)

  Returns `{:ok, %Customer{}}` on success or `{:error, reason}` on
  failure. The entire transaction rolls back if any step fails.

  ## Examples

      {:ok, customer} = Accrue.Billing.create_customer(user)
      customer.processor_id  #=> "cus_fake_00001"
  """
  @spec create_customer(struct()) :: {:ok, Customer.t()} | {:error, term()}
  def create_customer(%{__struct__: mod, id: id} = billable) do
    billable_type = mod.__accrue__(:billable_type)
    owner_id = to_string(id)
    processor_name = processor_name()

    params = build_processor_params(billable)

    # WR-08: migrated from Ecto.Multi to Repo.transact/1 per D3-18.
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
  end

  @doc """
  Raising variant of `create_customer/1`. Returns the `Customer`
  directly or raises on error.
  """
  @spec create_customer!(struct()) :: Customer.t()
  def create_customer!(billable) do
    case create_customer(billable) do
      {:ok, customer} -> customer
      {:error, reason} -> raise "Failed to create customer: #{inspect(reason)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Customer — update (D2-07, D2-09)
  # ---------------------------------------------------------------------------

  @doc """
  Updates a `Customer` with the given attributes.

  Uses `Ecto.Multi` to atomically update the customer and record a
  `"customer.updated"` event (EVT-04). Metadata is validated per D2-07
  (flat string map, max 50 keys, etc.). Optimistic locking via
  `lock_version` prevents torn writes (D2-09).

  ## Examples

      {:ok, customer} = Accrue.Billing.update_customer(customer, %{metadata: %{"tier" => "pro"}})
  """
  @spec update_customer(%Customer{}, map()) :: {:ok, Customer.t()} | {:error, term()}
  def update_customer(%Customer{} = customer, attrs) when is_map(attrs) do
    # WR-08: migrated from Ecto.Multi to Repo.transact/1 per D3-18.
    Repo.transact(fn ->
      with {:ok, updated} <- customer |> Customer.changeset(attrs) |> Repo.update(),
           {:ok, _event} <-
             Events.record(%{
               type: "customer.updated",
               subject_type: "Customer",
               subject_id: updated.id,
               data: %{
                 changes: Map.take(attrs, [:metadata, :name, :email, "metadata", "name", "email"])
               }
             }) do
        {:ok, updated}
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Data operations (D2-08)
  # ---------------------------------------------------------------------------

  @doc """
  Fully replaces the `data` jsonb column on a billing record (D2-08).

  Used by webhook reconcile paths that receive the whole object (e.g.
  `customer.updated`). Applies optimistic locking via `lock_version`.

  ## Examples

      {:ok, updated} = Accrue.Billing.put_data(customer, %{"balance" => 0})
  """
  @spec put_data(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def put_data(%{__struct__: _schema} = record, new_data) when is_map(new_data) do
    record
    |> Ecto.Changeset.change(data: new_data)
    |> Ecto.Changeset.optimistic_lock(:lock_version)
    |> Repo.update()
  end

  @doc """
  Shallow-merges `partial_data` into the existing `data` column (D2-08).

  Used when a partial event carries only a delta. Applies optimistic
  locking via `lock_version`.

  ## Examples

      {:ok, patched} = Accrue.Billing.patch_data(customer, %{"balance" => 100})
  """
  @spec patch_data(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def patch_data(%{__struct__: _schema} = record, partial_data) when is_map(partial_data) do
    merged = Map.merge(record.data || %{}, partial_data)
    put_data(record, merged)
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
