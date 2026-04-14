defmodule Accrue.Processor.Fake do
  @moduledoc """
  Deterministic in-memory processor adapter (D-19, D-20, D3-60).

  The Fake is Accrue's **primary test surface** (TEST-01). It implements
  the `Accrue.Processor` behaviour entirely in-process with a GenServer +
  struct state:

  - **Deterministic ids** per resource with 5-digit zero-padded counters:
    `cus_fake_00001`, `sub_fake_00001`, `in_fake_00001`, `pi_fake_00001`,
    `si_fake_00001`, `pm_fake_00001`, `ch_fake_00001`, `re_fake_00001`
    (D-20).
  - **Test clock** — all timestamps derive from an in-memory clock that
    starts at `Accrue.Processor.Fake.State.epoch/0` and moves only via
    `advance/2` (or `advance_subscription/2` for subscription-aware
    clock crossing). Matches Stripe's test-clock API (D-19).
  - **Clean reset** — `reset/0` zeros all counters, clears state, and
    restores the clock to the epoch. Call in `setup` blocks.
  - **Scripted responses** — `scripted_response/2` programs a one-shot
    return value for a named op so tests can simulate processor failures
    (card declined, rate limit) without mocking.
  - **Subscription transitions** — `transition/3` moves a subscription to
    any status, optionally synthesizing `customer.subscription.updated`
    webhooks in-process.
  - **Trial crossing** — `advance_subscription/2` advances the clock and,
    if the crossing period includes `trial_end - 3d` or `trial_end`,
    synthesizes `customer.subscription.trial_will_end` or
    `customer.subscription.updated` (status→active) events (D3-82).

  ## Startup

  The Fake is a `GenServer` with a fixed name (`__MODULE__`). It is **not**
  started by `Accrue.Application` — tests that need it call:

      setup do
        case Accrue.Processor.Fake.start_link([]) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
        end

        :ok = Accrue.Processor.Fake.reset()
        :ok
      end

  ## Id prefixes

  Prefixes are module attributes so they are greppable and future-proof:

      @customer_prefix     "cus_fake_"
      @subscription_prefix "sub_fake_"
      @invoice_prefix      "in_fake_"
      @payment_intent_prefix "pi_fake_"
      @setup_intent_prefix   "si_fake_"
      @payment_method_prefix "pm_fake_"
      @charge_prefix         "ch_fake_"
      @refund_prefix         "re_fake_"
      @event_prefix          "evt_fake_"
  """

  @behaviour Accrue.Processor

  use GenServer

  alias Accrue.Processor.Fake.State

  @customer_prefix "cus_fake_"
  @subscription_prefix "sub_fake_"
  @invoice_prefix "in_fake_"
  @payment_intent_prefix "pi_fake_"
  @setup_intent_prefix "si_fake_"
  @payment_method_prefix "pm_fake_"
  @charge_prefix "ch_fake_"
  @refund_prefix "re_fake_"
  @event_prefix "evt_fake_"
  @meter_event_prefix "mev_fake_"
  @subscription_item_prefix "si_fake_"
  @subscription_schedule_prefix "sub_sched_fake_"

  # ---------------------------------------------------------------------------
  # Public API — lifecycle
  # ---------------------------------------------------------------------------

  @doc """
  Starts the Fake processor with a fixed name.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    _ = opts
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Resets all counters, stored resources, scripts, and the clock.
  """
  @spec reset() :: :ok
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Advances the in-memory clock by `seconds` seconds. Existing Phase 1
  API — preserved for tests that only need to push the clock without
  any subscription-aware webhook synthesis.

  Accepts an optional server argument for tests that explicitly name the
  GenServer.
  """
  @spec advance(GenServer.server(), integer()) :: :ok
  def advance(server \\ __MODULE__, seconds) when is_integer(seconds) do
    GenServer.call(server, {:advance, seconds})
  end

  @doc """
  Subscription-aware clock advance (D3-82). Advances the Fake clock by
  `opts[:days] * 86400 + opts[:seconds]` and, if `stripe_id` references
  a subscription with a `trial_end`, synthesizes:

  - `customer.subscription.trial_will_end` when crossing `trial_end - 3d`
  - `customer.subscription.updated` (with `status: :active`) when
    crossing `trial_end`

  Pass `synthesize_webhooks: false` to skip the in-process event
  dispatch (useful for tests that only care about the state side
  effects).
  """
  @spec advance_subscription(String.t() | nil, keyword()) :: :ok
  def advance_subscription(stripe_id, opts)
      when (is_binary(stripe_id) or is_nil(stripe_id)) and is_list(opts) do
    GenServer.call(__MODULE__, {:advance_subscription, stripe_id, opts})
  end

  @doc """
  Returns the current in-memory clock value.
  """
  @spec current_time(GenServer.server()) :: DateTime.t()
  def current_time(server \\ __MODULE__) do
    GenServer.call(server, :current_time)
  end

  @doc """
  Alias of `current_time/0` — the canonical name used by `Accrue.Clock`
  when the runtime env is `:test` (D3-86). Kept as a thin wrapper so
  callers don't have to remember to pass a server argument, and so the
  grep pattern `Fake.now` is stable across the codebase.
  """
  @spec now() :: DateTime.t()
  def now, do: current_time(__MODULE__)

  @doc """
  Overrides one behaviour callback with a custom function for the lifetime
  of the GenServer (until `reset/0`). Intended for per-test stubbing.
  """
  @spec stub(atom(), (... -> term())) :: :ok
  def stub(callback, fun) when is_atom(callback) and is_function(fun) do
    GenServer.call(__MODULE__, {:stub, callback, fun})
  end

  @doc """
  Pre-programs a one-shot return value for the named op. The next call
  to that op consumes the scripted response; subsequent calls fall back
  to the default in-memory behaviour.

      Fake.scripted_response(:create_subscription, {:error, %Accrue.CardError{...}})
  """
  @spec scripted_response(atom(), {:ok, map()} | {:error, Exception.t()}) :: :ok
  def scripted_response(op, result) when is_atom(op) do
    GenServer.call(__MODULE__, {:script, op, result})
  end

  @doc """
  Transitions a stored subscription to `new_status`. By default
  synthesizes a `customer.subscription.updated` event in-process; pass
  `synthesize_webhooks: false` to skip.
  """
  @spec transition(String.t(), atom(), keyword()) ::
          {:ok, map()} | {:error, Accrue.APIError.t()}
  def transition(stripe_id, new_status, opts \\ [])
      when is_binary(stripe_id) and is_atom(new_status) and is_list(opts) do
    GenServer.call(__MODULE__, {:transition, stripe_id, new_status, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — customer (Phase 1, atom-keyed maps)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_customer(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_customer, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_customer(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_customer, id, opts})
  end

  @impl Accrue.Processor
  def update_customer(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:update_customer, id, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — subscription
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_subscription(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_subscription, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_subscription(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_subscription, id, opts})
  end

  @impl Accrue.Processor
  def update_subscription(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:update_subscription, id, params, opts})
  end

  @impl Accrue.Processor
  def cancel_subscription(id, opts) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:cancel_subscription, id, %{}, opts})
  end

  @impl Accrue.Processor
  def cancel_subscription(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:cancel_subscription, id, params, opts})
  end

  @impl Accrue.Processor
  def resume_subscription(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:resume_subscription, id, opts})
  end

  @impl Accrue.Processor
  def pause_subscription_collection(id, behavior, params, opts)
      when is_binary(id) and is_atom(behavior) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:pause_subscription_collection, id, behavior, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — invoice
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_invoice(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_invoice, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_invoice(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_invoice, id, opts})
  end

  @impl Accrue.Processor
  def update_invoice(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:update_invoice, id, params, opts})
  end

  @impl Accrue.Processor
  def finalize_invoice(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:invoice_action, :finalize, id, opts})
  end

  @impl Accrue.Processor
  def void_invoice(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:invoice_action, :void, id, opts})
  end

  @impl Accrue.Processor
  def pay_invoice(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:invoice_action, :pay, id, opts})
  end

  @impl Accrue.Processor
  def send_invoice(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:invoice_action, :send, id, opts})
  end

  @impl Accrue.Processor
  def mark_uncollectible_invoice(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:invoice_action, :mark_uncollectible, id, opts})
  end

  @impl Accrue.Processor
  def create_invoice_preview(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_invoice_preview, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — payment intent
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_payment_intent(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_payment_intent, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_payment_intent(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_payment_intent, id, opts})
  end

  @impl Accrue.Processor
  def confirm_payment_intent(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:confirm_payment_intent, id, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — setup intent
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_setup_intent(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_setup_intent, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_setup_intent(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_setup_intent, id, opts})
  end

  @impl Accrue.Processor
  def confirm_setup_intent(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:confirm_setup_intent, id, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — payment method
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_payment_method(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_payment_method, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_payment_method(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_payment_method, id, opts})
  end

  @impl Accrue.Processor
  def attach_payment_method(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:attach_payment_method, id, params, opts})
  end

  @impl Accrue.Processor
  def detach_payment_method(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:detach_payment_method, id, opts})
  end

  @impl Accrue.Processor
  def list_payment_methods(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:list_payment_methods, params, opts})
  end

  @impl Accrue.Processor
  def update_payment_method(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:update_payment_method, id, params, opts})
  end

  @impl Accrue.Processor
  def set_default_payment_method(customer_id, params, opts \\ [])
      when is_binary(customer_id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:set_default_payment_method, customer_id, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — charge
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_charge(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_charge, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_charge(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_charge, id, opts})
  end

  @impl Accrue.Processor
  def list_charges(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:list_charges, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — refund
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_refund(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:create_refund, params, opts})
  end

  @impl Accrue.Processor
  def retrieve_refund(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:retrieve_refund, id, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — meter event (Phase 4 Plan 02, BILL-13)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def report_meter_event(%Accrue.Billing.MeterEvent{} = row) do
    GenServer.call(__MODULE__, {:report_meter_event, row})
  end

  @doc """
  Returns the Fake-stored meter events for the given customer (by
  `processor_id`) in insertion order. Test helper only — the Fake never
  exposes meter events through the behaviour (Stripe doesn't either).
  """
  @spec meter_events_for(Accrue.Billing.Customer.t() | String.t()) :: [map()]
  def meter_events_for(%Accrue.Billing.Customer{processor_id: pid}),
    do: meter_events_for(pid)

  def meter_events_for(stripe_customer_id) when is_binary(stripe_customer_id) do
    GenServer.call(__MODULE__, {:meter_events_for, stripe_customer_id})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — subscription items (Phase 4 Plan 03, BILL-12)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def subscription_item_create(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_item_create, params, opts})
  end

  @impl Accrue.Processor
  def subscription_item_update(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_item_update, id, params, opts})
  end

  @impl Accrue.Processor
  def subscription_item_delete(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_item_delete, id, params, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — subscription schedules (Phase 4 Plan 03, BILL-16)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def subscription_schedule_create(params, opts \\ []) when is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_schedule_create, params, opts})
  end

  @impl Accrue.Processor
  def subscription_schedule_update(id, params, opts \\ [])
      when is_binary(id) and is_map(params) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_schedule_update, id, params, opts})
  end

  @impl Accrue.Processor
  def subscription_schedule_release(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_schedule_release, id, opts})
  end

  @impl Accrue.Processor
  def subscription_schedule_cancel(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_schedule_cancel, id, opts})
  end

  @impl Accrue.Processor
  def subscription_schedule_fetch(id, opts \\ []) when is_binary(id) and is_list(opts) do
    GenServer.call(__MODULE__, {:subscription_schedule_fetch, id, opts})
  end

  # ---------------------------------------------------------------------------
  # Behaviour callbacks — fetch dispatch (D3-48)
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def fetch(:subscription, id), do: retrieve_subscription(id, [])
  def fetch(:invoice, id), do: retrieve_invoice(id, [])
  def fetch(:charge, id), do: retrieve_charge(id, [])
  def fetch(:refund, id), do: retrieve_refund(id, [])
  def fetch(:payment_method, id), do: retrieve_payment_method(id, [])
  def fetch(:customer, id), do: retrieve_customer(id, [])
  def fetch(:payment_intent, id), do: retrieve_payment_intent(id, [])
  def fetch(:setup_intent, id), do: retrieve_setup_intent(id, [])

  # ---------------------------------------------------------------------------
  # GenServer
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(:ok), do: {:ok, %State{}}

  @impl GenServer
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %State{}}
  end

  def handle_call({:advance, seconds}, _from, %State{clock: clock} = state) do
    {:reply, :ok, %{state | clock: DateTime.add(clock, seconds, :second)}}
  end

  def handle_call({:advance_subscription, stripe_id, opts}, _from, state) do
    days = Keyword.get(opts, :days, 0)
    seconds = Keyword.get(opts, :seconds, 0)
    total = days * 86_400 + seconds
    new_now = DateTime.add(state.clock, total, :second)
    state = %{state | clock: new_now}

    state =
      case stripe_id && Map.get(state.subscriptions, stripe_id) do
        nil ->
          state

        sub ->
          case sub[:trial_end] || sub["trial_end"] do
            nil ->
              state

            trial_end_unix when is_integer(trial_end_unix) ->
              trial_end_dt = DateTime.from_unix!(trial_end_unix)
              warn_dt = DateTime.add(trial_end_dt, -3 * 86_400, :second)

              cond do
                DateTime.compare(new_now, trial_end_dt) in [:gt, :eq] ->
                  updated = Map.put(sub, :status, :active)
                  state = %{state | subscriptions: Map.put(state.subscriptions, stripe_id, updated)}

                  maybe_synthesize(
                    state,
                    opts,
                    "customer.subscription.updated",
                    updated
                  )

                DateTime.compare(new_now, warn_dt) in [:gt, :eq] ->
                  maybe_synthesize(
                    state,
                    opts,
                    "customer.subscription.trial_will_end",
                    sub
                  )

                true ->
                  state
              end
          end
      end

    {:reply, :ok, state}
  end

  def handle_call(:current_time, _from, %State{clock: clock} = state) do
    {:reply, clock, state}
  end

  def handle_call({:stub, callback, fun}, _from, %State{stubs: stubs} = state) do
    {:reply, :ok, %{state | stubs: Map.put(stubs, callback, fun)}}
  end

  def handle_call({:script, op, result}, _from, %State{scripts: scripts} = state) do
    {:reply, :ok, %{state | scripts: Map.put(scripts, op, result)}}
  end

  def handle_call({:transition, stripe_id, new_status, opts}, _from, state) do
    case Map.fetch(state.subscriptions, stripe_id) do
      {:ok, sub} ->
        updated = Map.put(sub, :status, new_status)
        state = %{state | subscriptions: Map.put(state.subscriptions, stripe_id, updated)}

        state =
          maybe_synthesize(state, opts, "customer.subscription.updated", updated)

        {:reply, {:ok, updated}, state}

      :error ->
        {:reply, {:error, resource_missing(stripe_id)}, state}
    end
  end

  # --- customer (Phase 1 atom-keyed shape) ---

  def handle_call({:create_customer, params, opts}, _from, state) do
    with_script_or_stub(state, :create_customer, [params, opts], fn state ->
      idem_key = Keyword.get(opts, :idempotency_key)

      case idempotency_hit(state, idem_key) do
        {:hit, cached} ->
          {cached, state}

        :miss ->
          state = bump(state, :customer)
          id = id_for(:customer, state.counters.customer)

          customer =
            params
            |> Map.put(:id, id)
            |> Map.put(:object, "customer")
            |> Map.put(:created, state.clock)

          result = {:ok, customer}
          state = %{state | customers: Map.put(state.customers, id, customer)}
          state = cache_idempotency(state, idem_key, result)
          {result, state}
      end
    end)
  end

  def handle_call({:retrieve_customer, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_customer, [id, opts], fn state ->
      case Map.fetch(state.customers, id) do
        {:ok, customer} -> {{:ok, customer}, state}
        :error -> {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:update_customer, id, params, opts}, _from, state) do
    with_script_or_stub(state, :update_customer, [id, params, opts], fn state ->
      case Map.fetch(state.customers, id) do
        {:ok, existing} ->
          updated = Map.merge(existing, params)
          {{:ok, updated}, %{state | customers: Map.put(state.customers, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  # --- subscription ---

  def handle_call({:create_subscription, params, opts}, _from, state) do
    with_script_or_stub(state, :create_subscription, [params, opts], fn state ->
      state = bump(state, :subscription)
      id = id_for(:subscription, state.counters.subscription)
      sub = build_subscription(state, id, params)
      state = %{state | subscriptions: Map.put(state.subscriptions, id, sub)}
      {{:ok, sub}, state}
    end)
  end

  def handle_call({:retrieve_subscription, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_subscription, [id, opts], fn state ->
      lookup(state.subscriptions, id, state)
    end)
  end

  def handle_call({:update_subscription, id, params, opts}, _from, state) do
    with_script_or_stub(state, :update_subscription, [id, params, opts], fn state ->
      case Map.fetch(state.subscriptions, id) do
        {:ok, existing} ->
          updated = apply_subscription_update(existing, params, id)

          {{:ok, updated},
           %{state | subscriptions: Map.put(state.subscriptions, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:cancel_subscription, id, _params, opts}, _from, state) do
    with_script_or_stub(state, :cancel_subscription, [id, opts], fn state ->
      case Map.fetch(state.subscriptions, id) do
        {:ok, existing} ->
          updated =
            existing
            |> Map.put(:status, :canceled)
            |> Map.put(:canceled_at, state.clock)
            |> Map.put(:ended_at, state.clock)

          {{:ok, updated},
           %{state | subscriptions: Map.put(state.subscriptions, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:resume_subscription, id, opts}, _from, state) do
    with_script_or_stub(state, :resume_subscription, [id, opts], fn state ->
      case Map.fetch(state.subscriptions, id) do
        {:ok, existing} ->
          updated =
            existing
            |> Map.put(:status, :active)
            |> Map.put(:pause_collection, nil)

          {{:ok, updated},
           %{state | subscriptions: Map.put(state.subscriptions, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:pause_subscription_collection, id, behavior, _params, opts}, _from, state) do
    with_script_or_stub(state, :pause_subscription_collection, [id, behavior, opts], fn state ->
      case Map.fetch(state.subscriptions, id) do
        {:ok, existing} ->
          updated = Map.put(existing, :pause_collection, %{behavior: behavior})

          {{:ok, updated},
           %{state | subscriptions: Map.put(state.subscriptions, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  # --- invoice ---

  def handle_call({:create_invoice, params, opts}, _from, state) do
    with_script_or_stub(state, :create_invoice, [params, opts], fn state ->
      state = bump(state, :invoice)
      id = id_for(:invoice, state.counters.invoice)
      inv = build_invoice(state, id, params)
      {{:ok, inv}, %{state | invoices: Map.put(state.invoices, id, inv)}}
    end)
  end

  def handle_call({:retrieve_invoice, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_invoice, [id, opts], fn state ->
      lookup(state.invoices, id, state)
    end)
  end

  def handle_call({:update_invoice, id, params, opts}, _from, state) do
    with_script_or_stub(state, :update_invoice, [id, params, opts], fn state ->
      case Map.fetch(state.invoices, id) do
        {:ok, existing} ->
          updated = Map.merge(existing, params)
          {{:ok, updated}, %{state | invoices: Map.put(state.invoices, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:invoice_action, action, id, opts}, _from, state) do
    op_name =
      case action do
        :finalize -> :finalize_invoice
        :void -> :void_invoice
        :pay -> :pay_invoice
        :send -> :send_invoice
        :mark_uncollectible -> :mark_uncollectible_invoice
      end

    with_script_or_stub(state, op_name, [id, opts], fn state ->
      case Map.fetch(state.invoices, id) do
        {:ok, existing} ->
          updated = apply_invoice_action(existing, action, state.clock)
          {{:ok, updated}, %{state | invoices: Map.put(state.invoices, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:create_invoice_preview, params, opts}, _from, state) do
    with_script_or_stub(state, :create_invoice_preview, [params, opts], fn state ->
      customer = params[:customer] || params["customer"]
      subscription = params[:subscription] || params["subscription"]

      sub_details =
        params[:subscription_details] || params["subscription_details"] || %{}

      items = sub_details[:items] || sub_details["items"] || []

      lines =
        Enum.map(items, fn item ->
          price = item[:price] || item["price"]

          price_id =
            cond do
              is_binary(price) -> price
              is_map(price) -> price[:id] || price["id"]
              true -> nil
            end

          %{
            id: "il_fake_" <> Integer.to_string(:erlang.phash2(price_id, 1_000_000)),
            object: "line_item",
            description: "Preview line for #{price_id}",
            amount: 1000,
            currency: "usd",
            quantity: item[:quantity] || item["quantity"] || 1,
            period: %{
              start: DateTime.to_unix(state.clock),
              end: DateTime.to_unix(DateTime.add(state.clock, 30 * 86_400, :second))
            },
            proration: false,
            price: %{id: price_id, product: "prod_fake_#{price_id}"}
          }
        end)

      subtotal = Enum.reduce(lines, 0, &(&1.amount + &2))

      preview = %{
        object: "invoice",
        id: nil,
        customer: customer,
        subscription: subscription,
        currency: "usd",
        subtotal: subtotal,
        total: subtotal,
        amount_due: subtotal,
        starting_balance: 0,
        period_start: DateTime.to_unix(state.clock),
        period_end: DateTime.to_unix(DateTime.add(state.clock, 30 * 86_400, :second)),
        subscription_proration_date: DateTime.to_unix(state.clock),
        lines: %{object: "list", data: lines},
        created: state.clock
      }

      {{:ok, preview}, state}
    end)
  end

  # --- payment intent ---

  def handle_call({:create_payment_intent, params, opts}, _from, state) do
    with_script_or_stub(state, :create_payment_intent, [params, opts], fn state ->
      state = bump(state, :payment_intent)
      id = id_for(:payment_intent, state.counters.payment_intent)
      pi = build_payment_intent(state, id, params)
      {{:ok, pi}, %{state | payment_intents: Map.put(state.payment_intents, id, pi)}}
    end)
  end

  def handle_call({:retrieve_payment_intent, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_payment_intent, [id, opts], fn state ->
      lookup(state.payment_intents, id, state)
    end)
  end

  def handle_call({:confirm_payment_intent, id, _params, opts}, _from, state) do
    with_script_or_stub(state, :confirm_payment_intent, [id, opts], fn state ->
      case Map.fetch(state.payment_intents, id) do
        {:ok, existing} ->
          updated = Map.put(existing, :status, :succeeded)

          {{:ok, updated},
           %{state | payment_intents: Map.put(state.payment_intents, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  # --- setup intent ---

  def handle_call({:create_setup_intent, params, opts}, _from, state) do
    with_script_or_stub(state, :create_setup_intent, [params, opts], fn state ->
      state = bump(state, :setup_intent)
      id = id_for(:setup_intent, state.counters.setup_intent)
      si = build_setup_intent(state, id, params)
      {{:ok, si}, %{state | setup_intents: Map.put(state.setup_intents, id, si)}}
    end)
  end

  def handle_call({:retrieve_setup_intent, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_setup_intent, [id, opts], fn state ->
      lookup(state.setup_intents, id, state)
    end)
  end

  def handle_call({:confirm_setup_intent, id, _params, opts}, _from, state) do
    with_script_or_stub(state, :confirm_setup_intent, [id, opts], fn state ->
      case Map.fetch(state.setup_intents, id) do
        {:ok, existing} ->
          updated = Map.put(existing, :status, :succeeded)

          {{:ok, updated},
           %{state | setup_intents: Map.put(state.setup_intents, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  # --- payment method ---

  def handle_call({:create_payment_method, params, opts}, _from, state) do
    with_script_or_stub(state, :create_payment_method, [params, opts], fn state ->
      state = bump(state, :payment_method)
      id = id_for(:payment_method, state.counters.payment_method)
      pm = build_payment_method(state, id, params)
      {{:ok, pm}, %{state | payment_methods: Map.put(state.payment_methods, id, pm)}}
    end)
  end

  def handle_call({:retrieve_payment_method, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_payment_method, [id, opts], fn state ->
      lookup(state.payment_methods, id, state)
    end)
  end

  def handle_call({:attach_payment_method, id, params, opts}, _from, state) do
    with_script_or_stub(state, :attach_payment_method, [id, params, opts], fn state ->
      case Map.fetch(state.payment_methods, id) do
        {:ok, existing} ->
          updated = Map.put(existing, :customer, params[:customer] || params["customer"])
          {{:ok, updated}, %{state | payment_methods: Map.put(state.payment_methods, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:detach_payment_method, id, opts}, _from, state) do
    with_script_or_stub(state, :detach_payment_method, [id, opts], fn state ->
      case Map.fetch(state.payment_methods, id) do
        {:ok, existing} ->
          updated = Map.put(existing, :customer, nil)
          {{:ok, updated}, %{state | payment_methods: Map.put(state.payment_methods, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:list_payment_methods, params, opts}, _from, state) do
    with_script_or_stub(state, :list_payment_methods, [params, opts], fn state ->
      customer = params[:customer] || params["customer"]

      data =
        state.payment_methods
        |> Map.values()
        |> Enum.filter(fn pm -> pm[:customer] == customer end)

      {{:ok, %{object: "list", data: data, has_more: false}}, state}
    end)
  end

  def handle_call({:update_payment_method, id, params, opts}, _from, state) do
    with_script_or_stub(state, :update_payment_method, [id, params, opts], fn state ->
      case Map.fetch(state.payment_methods, id) do
        {:ok, existing} ->
          updated = Map.merge(existing, params)
          {{:ok, updated}, %{state | payment_methods: Map.put(state.payment_methods, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:set_default_payment_method, customer_id, params, opts}, _from, state) do
    with_script_or_stub(state, :set_default_payment_method, [customer_id, params, opts], fn state ->
      case Map.fetch(state.customers, customer_id) do
        {:ok, existing} ->
          pm_id = get_in(params, [:invoice_settings, :default_payment_method])

          updated =
            Map.put(existing, :invoice_settings, %{default_payment_method: pm_id})

          {{:ok, updated}, %{state | customers: Map.put(state.customers, customer_id, updated)}}

        :error ->
          {{:error, resource_missing(customer_id)}, state}
      end
    end)
  end

  # --- charge ---

  def handle_call({:create_charge, params, opts}, _from, state) do
    with_script_or_stub(state, :create_charge, [params, opts], fn state ->
      state = bump(state, :charge)
      id = id_for(:charge, state.counters.charge)
      charge = build_charge(state, id, params)
      {{:ok, charge}, %{state | charges: Map.put(state.charges, id, charge)}}
    end)
  end

  def handle_call({:retrieve_charge, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_charge, [id, opts], fn state ->
      lookup(state.charges, id, state)
    end)
  end

  def handle_call({:list_charges, params, opts}, _from, state) do
    with_script_or_stub(state, :list_charges, [params, opts], fn state ->
      customer = params[:customer] || params["customer"]

      data =
        state.charges
        |> Map.values()
        |> Enum.filter(fn c -> is_nil(customer) or c[:customer] == customer end)

      {{:ok, %{object: "list", data: data, has_more: false}}, state}
    end)
  end

  # --- refund ---

  def handle_call({:create_refund, params, opts}, _from, state) do
    with_script_or_stub(state, :create_refund, [params, opts], fn state ->
      state = bump(state, :refund)
      id = id_for(:refund, state.counters.refund)
      refund = build_refund(state, id, params)
      {{:ok, refund}, %{state | refunds: Map.put(state.refunds, id, refund)}}
    end)
  end

  def handle_call({:retrieve_refund, id, opts}, _from, state) do
    with_script_or_stub(state, :retrieve_refund, [id, opts], fn state ->
      lookup(state.refunds, id, state)
    end)
  end

  # --- meter event ---

  def handle_call({:report_meter_event, row}, _from, state) do
    with_script_or_stub(state, :report_meter_event, [row], fn state ->
      stripe_event = %{
        id: @meter_event_prefix <> row.identifier,
        object: "billing.meter_event",
        event_name: row.event_name,
        payload: %{
          stripe_customer_id: row.stripe_customer_id,
          value: to_string(row.value)
        },
        identifier: row.identifier,
        timestamp: DateTime.to_unix(row.occurred_at),
        created: DateTime.to_unix(state.clock),
        livemode: false
      }

      existing = Map.get(state.meter_events, row.stripe_customer_id, [])

      state = %{
        state
        | meter_events:
            Map.put(state.meter_events, row.stripe_customer_id, existing ++ [stripe_event])
      }

      {{:ok, stripe_event}, state}
    end)
  end

  def handle_call({:meter_events_for, stripe_customer_id}, _from, state) do
    {:reply, Map.get(state.meter_events, stripe_customer_id, []), state}
  end

  # --- subscription items (Phase 4 Plan 03, BILL-12) ---

  def handle_call({:subscription_item_create, params, opts}, _from, state) do
    with_script_or_stub(state, :subscription_item_create, [params, opts], fn state ->
      counter = (state.counters[:subscription_item] || 0) + 1
      counters = Map.put(state.counters, :subscription_item, counter)
      state = %{state | counters: counters}
      id = @subscription_item_prefix <> pad5(counter)

      price = params[:price] || params["price"]
      quantity = params[:quantity] || params["quantity"] || 1

      item = %{
        id: id,
        object: "subscription_item",
        subscription: params[:subscription] || params["subscription"],
        price: %{id: price, product: "prod_fake_" <> to_string(price)},
        quantity: quantity
      }

      {{:ok, item}, %{state | subscription_items: Map.put(state.subscription_items, id, item)}}
    end)
  end

  def handle_call({:subscription_item_update, id, params, opts}, _from, state) do
    with_script_or_stub(state, :subscription_item_update, [id, params, opts], fn state ->
      case Map.fetch(state.subscription_items, id) do
        {:ok, existing} ->
          updated = Map.merge(existing, atomize(params))

          {{:ok, updated},
           %{state | subscription_items: Map.put(state.subscription_items, id, updated)}}

        :error ->
          # Tolerate items created by build_subscription (not in the
          # subscription_items map). Return a synthesized result that
          # echoes the patch so the caller's local update succeeds.
          synthesized = %{id: id, object: "subscription_item"} |> Map.merge(atomize(params))
          {{:ok, synthesized}, state}
      end
    end)
  end

  def handle_call({:subscription_item_delete, id, params, opts}, _from, state) do
    with_script_or_stub(state, :subscription_item_delete, [id, params, opts], fn state ->
      items = Map.delete(state.subscription_items, id)
      result = %{id: id, object: "subscription_item", deleted: true}
      {{:ok, result}, %{state | subscription_items: items}}
    end)
  end

  # --- subscription schedules (Phase 4 Plan 03, BILL-16) ---

  def handle_call({:subscription_schedule_create, params, opts}, _from, state) do
    with_script_or_stub(state, :subscription_schedule_create, [params, opts], fn state ->
      counter = (state.counters[:subscription_schedule] || 0) + 1
      counters = Map.put(state.counters, :subscription_schedule, counter)
      state = %{state | counters: counters}
      id = @subscription_schedule_prefix <> pad5(counter)
      sched = build_subscription_schedule(state, id, params)

      {{:ok, sched},
       %{state | subscription_schedules: Map.put(state.subscription_schedules, id, sched)}}
    end)
  end

  def handle_call({:subscription_schedule_update, id, params, opts}, _from, state) do
    with_script_or_stub(state, :subscription_schedule_update, [id, params, opts], fn state ->
      case Map.fetch(state.subscription_schedules, id) do
        {:ok, existing} ->
          updated = Map.merge(existing, atomize(params))

          {{:ok, updated},
           %{state | subscription_schedules: Map.put(state.subscription_schedules, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:subscription_schedule_release, id, opts}, _from, state) do
    with_script_or_stub(state, :subscription_schedule_release, [id, opts], fn state ->
      case Map.fetch(state.subscription_schedules, id) do
        {:ok, existing} ->
          updated =
            existing
            |> Map.put(:status, "released")
            |> Map.put(:released_at, DateTime.to_unix(state.clock))

          {{:ok, updated},
           %{state | subscription_schedules: Map.put(state.subscription_schedules, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:subscription_schedule_cancel, id, opts}, _from, state) do
    with_script_or_stub(state, :subscription_schedule_cancel, [id, opts], fn state ->
      case Map.fetch(state.subscription_schedules, id) do
        {:ok, existing} ->
          updated =
            existing
            |> Map.put(:status, "canceled")
            |> Map.put(:canceled_at, DateTime.to_unix(state.clock))

          {{:ok, updated},
           %{state | subscription_schedules: Map.put(state.subscription_schedules, id, updated)}}

        :error ->
          {{:error, resource_missing(id)}, state}
      end
    end)
  end

  def handle_call({:subscription_schedule_fetch, id, opts}, _from, state) do
    with_script_or_stub(state, :subscription_schedule_fetch, [id, opts], fn state ->
      lookup(state.subscription_schedules, id, state)
    end)
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp with_script_or_stub(state, op, args, fun) do
    case Map.fetch(state.scripts, op) do
      {:ok, scripted_result} ->
        state = %{state | scripts: Map.delete(state.scripts, op)}
        {:reply, scripted_result, state}

      :error ->
        case stub_hit(state, op, args) do
          {:hit, reply} ->
            {:reply, reply, state}

          :miss ->
            {result, state} = fun.(state)
            {:reply, result, state}
        end
    end
  end

  defp lookup(map, id, state) do
    case Map.fetch(map, id) do
      {:ok, obj} -> {{:ok, obj}, state}
      :error -> {{:error, resource_missing(id)}, state}
    end
  end

  defp bump(%State{counters: counters} = state, resource) do
    counters = Map.update!(counters, resource, &(&1 + 1))
    %{state | counters: counters}
  end

  @doc """
  Returns the id prefix map for the Fake adapter (D-20). Phase 3 resource
  types already have counter slots and prefixes reserved here so growing
  the callback list never churns id shapes.
  """
  @spec id_prefixes() :: %{atom() => String.t()}
  def id_prefixes do
    %{
      customer: @customer_prefix,
      subscription: @subscription_prefix,
      invoice: @invoice_prefix,
      payment_intent: @payment_intent_prefix,
      setup_intent: @setup_intent_prefix,
      payment_method: @payment_method_prefix,
      charge: @charge_prefix,
      refund: @refund_prefix
    }
  end

  @spec id_for(atom(), non_neg_integer()) :: String.t()
  defp id_for(resource, n) do
    Map.fetch!(id_prefixes(), resource) <> pad5(n)
  end

  defp pad5(n) when is_integer(n) and n >= 0 do
    n |> Integer.to_string() |> String.pad_leading(5, "0")
  end

  defp resource_missing(id) do
    %Accrue.APIError{
      code: "resource_missing",
      http_status: 404,
      message: "No such resource: #{id}"
    }
  end

  defp stub_hit(%State{stubs: stubs}, callback, args) do
    case Map.fetch(stubs, callback) do
      {:ok, fun} -> {:hit, apply(fun, args)}
      :error -> :miss
    end
  end

  defp idempotency_hit(_state, nil), do: :miss

  defp idempotency_hit(%State{idempotency_cache: cache}, key) do
    case Map.fetch(cache, key) do
      {:ok, result} -> {:hit, result}
      :error -> :miss
    end
  end

  defp cache_idempotency(state, nil, _result), do: state

  defp cache_idempotency(%State{idempotency_cache: cache} = state, key, result) do
    %{state | idempotency_cache: Map.put(cache, key, result)}
  end

  # --- fixture builders (kept inside lib/ to avoid test/support dep) ---

  # Applies a subscription update map to the stored atom-keyed sub, with
  # special-case handling for the `items` param (which arrives as a flat
  # list of item patches like `[%{id: si_id, price: "price_pro"}]` and
  # must merge into the nested `items.data` list).
  defp apply_subscription_update(existing, params, sub_id) do
    {item_patches, other_params} = Map.pop(params, :items)
    {item_patches_str, other_params} = Map.pop(other_params, "items")

    patches = item_patches || item_patches_str

    merged = Map.merge(existing, other_params)

    case patches do
      nil ->
        merged

      list when is_list(list) ->
        existing_items =
          get_in(existing, [:items, :data]) || get_in(existing, ["items", "data"]) || []

        new_data =
          Enum.reduce(list, existing_items, fn patch, acc ->
            apply_item_patch(acc, patch, sub_id, length(acc) + 1)
          end)

        Map.put(merged, :items, %{object: "list", data: new_data})
    end
  end

  defp apply_item_patch(items, patch, sub_id, next_idx) do
    patch_id = patch[:id] || patch["id"]

    if patch_id do
      {updated_list, matched?} =
        Enum.map_reduce(items, false, fn item, acc ->
          item_id = item[:id] || item["id"]

          if item_id == patch_id do
            {merge_item(item, patch), true}
          else
            {item, acc}
          end
        end)

      if matched?,
        do: updated_list,
        else: items ++ [build_subscription_item(patch, sub_id, next_idx)]
    else
      items ++ [build_subscription_item(patch, sub_id, next_idx)]
    end
  end

  defp merge_item(item, patch) do
    new_price = patch[:price] || patch["price"]

    updated_price =
      case new_price do
        nil -> item[:price] || item["price"]
        p when is_binary(p) -> %{id: p, product: "prod_fake_" <> p}
        %{} = p -> p
      end

    item
    |> Map.merge(Map.drop(patch, [:price, "price"]))
    |> Map.put(:price, updated_price)
  end

  defp build_subscription(state, id, params) do
    trial_end_raw = params[:trial_end] || params["trial_end"]
    status = if trial_end_raw, do: :trialing, else: :active
    customer = params[:customer] || params["customer"]
    raw_items = params[:items] || params["items"] || []

    items =
      raw_items
      |> Enum.with_index(1)
      |> Enum.map(fn {item, idx} -> build_subscription_item(item, id, idx) end)

    trial_start =
      case trial_end_raw do
        nil -> nil
        _ -> DateTime.to_unix(state.clock)
      end

    trial_end =
      case trial_end_raw do
        nil -> nil
        "now" -> DateTime.to_unix(state.clock)
        n when is_integer(n) -> n
        %DateTime{} = dt -> DateTime.to_unix(dt)
        _ -> nil
      end

    %{
      id: id,
      object: "subscription",
      customer: customer,
      status: status,
      created: state.clock,
      trial_start: trial_start,
      trial_end: trial_end,
      cancel_at_period_end: false,
      pause_collection: nil,
      current_period_start: DateTime.to_unix(state.clock),
      current_period_end: DateTime.to_unix(DateTime.add(state.clock, 30 * 86_400, :second)),
      items: %{object: "list", data: items},
      latest_invoice: nil,
      metadata: params[:metadata] || params["metadata"] || %{}
    }
  end

  defp build_subscription_item(item, sub_id, idx) when is_map(item) do
    price = item[:price] || item["price"]

    price_map =
      case price do
        p when is_binary(p) -> %{id: p, product: "prod_fake_" <> p}
        %{} = p -> p
        nil -> %{id: nil, product: nil}
      end

    %{
      id: item[:id] || item["id"] || sub_id <> "_item_" <> Integer.to_string(idx),
      object: "subscription_item",
      price: price_map,
      quantity: item[:quantity] || item["quantity"] || 1,
      metadata: item[:metadata] || item["metadata"] || %{}
    }
  end

  defp build_invoice(state, id, params) do
    %{
      id: id,
      object: "invoice",
      customer: params[:customer] || params["customer"],
      subscription: params[:subscription] || params["subscription"],
      status: :draft,
      amount_due: params[:amount_due] || params["amount_due"] || 0,
      amount_paid: 0,
      amount_remaining: params[:amount_due] || params["amount_due"] || 0,
      currency: params[:currency] || params["currency"] || "usd",
      created: state.clock,
      lines: %{object: "list", data: []}
    }
  end

  defp apply_invoice_action(inv, :finalize, clock) do
    inv
    |> Map.put(:status, :open)
    |> Map.put(:finalized_at, clock)
  end

  defp apply_invoice_action(inv, :void, clock) do
    inv
    |> Map.put(:status, :void)
    |> Map.put(:voided_at, clock)
  end

  defp apply_invoice_action(inv, :pay, _clock) do
    amount = inv[:amount_due] || 0

    inv
    |> Map.put(:status, :paid)
    |> Map.put(:amount_paid, amount)
    |> Map.put(:amount_remaining, 0)
  end

  defp apply_invoice_action(inv, :send, _clock), do: inv

  defp apply_invoice_action(inv, :mark_uncollectible, _clock) do
    Map.put(inv, :status, :uncollectible)
  end

  defp build_payment_intent(state, id, params) do
    amount = params[:amount] || params["amount"] || 0
    currency = params[:currency] || params["currency"] || "usd"
    requires_action? = params[:requires_action_test] || params["requires_action_test"]

    base = %{
      id: id,
      object: "payment_intent",
      amount: amount,
      currency: currency,
      customer: params[:customer] || params["customer"],
      created: state.clock,
      client_secret: id <> "_secret"
    }

    if requires_action? do
      Map.merge(base, %{
        status: :requires_action,
        next_action: %{type: "use_stripe_sdk", use_stripe_sdk: %{}}
      })
    else
      Map.merge(base, %{status: :succeeded, next_action: nil})
    end
  end

  defp build_setup_intent(state, id, params) do
    requires_action? = params[:requires_action_test] || params["requires_action_test"]

    base = %{
      id: id,
      object: "setup_intent",
      customer: params[:customer] || params["customer"],
      created: state.clock,
      client_secret: id <> "_secret"
    }

    if requires_action? do
      Map.merge(base, %{
        status: :requires_action,
        next_action: %{type: "use_stripe_sdk", use_stripe_sdk: %{}}
      })
    else
      Map.merge(base, %{status: :succeeded, next_action: nil})
    end
  end

  defp build_payment_method(state, id, params) do
    %{
      id: id,
      object: "payment_method",
      type: params[:type] || params["type"] || "card",
      customer: params[:customer] || params["customer"],
      created: state.clock,
      card: params[:card] || params["card"] || %{brand: "visa", last4: "4242", exp_month: 12, exp_year: 2030, fingerprint: "fp_fake_" <> Integer.to_string(state.counters.payment_method)}
    }
  end

  defp build_charge(state, id, params) do
    %{
      id: id,
      object: "charge",
      amount: params[:amount] || params["amount"] || 0,
      amount_captured: params[:amount] || params["amount"] || 0,
      amount_refunded: 0,
      currency: params[:currency] || params["currency"] || "usd",
      customer: params[:customer] || params["customer"],
      status: :succeeded,
      created: state.clock,
      balance_transaction: %{
        id: "txn_fake_" <> Integer.to_string(state.counters.charge),
        fee: 30,
        fee_details: [%{type: "stripe_fee", amount: 30, currency: "usd"}],
        net: (params[:amount] || params["amount"] || 0) - 30
      }
    }
  end

  defp build_subscription_schedule(state, id, params) do
    phases = params[:phases] || params["phases"] || []
    customer = params[:customer] || params["customer"]

    %{
      id: id,
      object: "subscription_schedule",
      customer: customer,
      status: "not_started",
      phases: phases,
      current_phase: nil,
      created: DateTime.to_unix(state.clock),
      end_behavior: params[:end_behavior] || params["end_behavior"] || "release",
      released_at: nil,
      canceled_at: nil,
      metadata: params[:metadata] || params["metadata"] || %{}
    }
  end

  defp atomize(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {k, v}
      {k, v} when is_binary(k) ->
        try do
          {String.to_existing_atom(k), v}
        rescue
          ArgumentError -> {k, v}
        end
    end)
  end

  defp build_refund(state, id, params) do
    charge_id = params[:charge] || params["charge"]
    amount = params[:amount] || params["amount"] || 0

    %{
      id: id,
      object: "refund",
      charge: charge_id,
      amount: amount,
      currency: params[:currency] || params["currency"] || "usd",
      status: :succeeded,
      created: state.clock,
      balance_transaction: %{
        id: "txn_fake_refund_" <> Integer.to_string(state.counters.refund),
        fee: -3,
        fee_details: [%{type: "stripe_fee", amount: -3, currency: "usd"}],
        net: -(amount - 3)
      }
    }
  end

  defp maybe_synthesize(state, opts, type, object) do
    if Keyword.get(opts, :synthesize_webhooks, true) do
      synthesize_event(state, type, object)
    else
      state
    end
  end

  defp synthesize_event(state, type, object) do
    state = bump(state, :event)
    event_id = @event_prefix <> pad5(state.counters.event)

    event = %{
      id: event_id,
      object: "event",
      type: type,
      created: DateTime.to_unix(state.clock),
      data: %{object: object}
    }

    # Route through DefaultHandler in-process if loaded. Plan 07 extends
    # DefaultHandler; earlier callers should be resilient to its absence.
    # Use apply/3 to avoid compile-time binding on a function that may or
    # may not exist yet.
    handler = Accrue.Webhook.DefaultHandler

    if Code.ensure_loaded?(handler) and function_exported?(handler, :handle, 1) do
      _ = apply(handler, :handle, [event])
    end

    state
  end
end
