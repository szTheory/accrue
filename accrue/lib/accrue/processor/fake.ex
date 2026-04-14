defmodule Accrue.Processor.Fake do
  @moduledoc """
  Deterministic in-memory processor adapter (D-19, D-20).

  The Fake is Accrue's **primary test surface** (TEST-01). It implements
  the `Accrue.Processor` behaviour entirely in-process with a GenServer +
  struct state:

  - **Deterministic ids** per resource with 5-digit zero-padded counters:
    `cus_fake_00001`, `sub_fake_00001`, `in_fake_00001`, `pi_fake_00001`,
    `pm_fake_00001` (D-20).
  - **Test clock** — all timestamps derive from an in-memory clock that
    starts at `Accrue.Processor.Fake.State.epoch/0` and moves only via
    `advance/2`. Matches Stripe's test-clock API (D-19).
  - **Clean reset** — `reset/0` zeros all counters, clears state, and
    restores the clock to the epoch. Call in `setup` blocks.

  ## Startup

  The Fake is a `GenServer` with a fixed name (`__MODULE__`). It is **not**
  started by `Accrue.Application` — Phase 1 leaves the application
  supervisor empty (Plan 06 decides). Tests that need it call:

      setup do
        case Accrue.Processor.Fake.start_link([]) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
        end

        :ok = Accrue.Processor.Fake.reset()
        :ok
      end

  This keeps Wave 2 plans (04 + 05) free of OTP boot coupling.

  ## Id prefixes

  Prefixes are module attributes so they are greppable and future-proof:

      @customer_prefix "cus_fake_"
      @subscription_prefix "sub_fake_"
      @invoice_prefix "in_fake_"
      @payment_intent_prefix "pi_fake_"
      @payment_method_prefix "pm_fake_"
  """

  @behaviour Accrue.Processor

  use GenServer

  alias Accrue.Processor.Fake.State

  @customer_prefix "cus_fake_"
  @subscription_prefix "sub_fake_"
  @invoice_prefix "in_fake_"
  @payment_intent_prefix "pi_fake_"
  @payment_method_prefix "pm_fake_"

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Starts the Fake processor with a fixed name.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Resets all counters, stored resources, and the clock.
  """
  @spec reset() :: :ok
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Advances the in-memory clock by `seconds` seconds.
  """
  @spec advance(GenServer.server(), integer()) :: :ok
  def advance(server \\ __MODULE__, seconds) when is_integer(seconds) do
    GenServer.call(server, {:advance, seconds})
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

  # ---------------------------------------------------------------------------
  # Behaviour callbacks
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
  # GenServer
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(:ok) do
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %State{}}
  end

  def handle_call({:advance, seconds}, _from, %State{clock: clock} = state) do
    {:reply, :ok, %{state | clock: DateTime.add(clock, seconds, :second)}}
  end

  def handle_call(:current_time, _from, %State{clock: clock} = state) do
    {:reply, clock, state}
  end

  def handle_call({:stub, callback, fun}, _from, %State{stubs: stubs} = state) do
    {:reply, :ok, %{state | stubs: Map.put(stubs, callback, fun)}}
  end

  def handle_call({:create_customer, params, opts}, _from, state) do
    case stub_hit(state, :create_customer, [params, opts]) do
      {:hit, reply} ->
        {:reply, reply, state}

      :miss ->
        idem_key = Keyword.get(opts, :idempotency_key)

        case idempotency_hit(state, idem_key) do
          {:hit, cached_result} ->
            {:reply, cached_result, state}

          :miss ->
            next = bump(state, :customer)
            id = id_for(:customer, next.counters.customer)

            customer =
              params
              |> Map.put(:id, id)
              |> Map.put(:object, "customer")
              |> Map.put(:created, state.clock)

            result = {:ok, customer}
            next = %{next | customers: Map.put(next.customers, id, customer)}
            next = cache_idempotency(next, idem_key, result)
            {:reply, result, next}
        end
    end
  end

  def handle_call({:retrieve_customer, id, opts}, _from, state) do
    case stub_hit(state, :retrieve_customer, [id, opts]) do
      {:hit, reply} ->
        {:reply, reply, state}

      :miss ->
        case Map.fetch(state.customers, id) do
          {:ok, customer} -> {:reply, {:ok, customer}, state}
          :error -> {:reply, {:error, resource_missing(id)}, state}
        end
    end
  end

  def handle_call({:update_customer, id, params, opts}, _from, state) do
    case stub_hit(state, :update_customer, [id, params, opts]) do
      {:hit, reply} ->
        {:reply, reply, state}

      :miss ->
        case Map.fetch(state.customers, id) do
          {:ok, existing} ->
            updated = Map.merge(existing, params)
            state = %{state | customers: Map.put(state.customers, id, updated)}
            {:reply, {:ok, updated}, state}

          :error ->
            {:reply, {:error, resource_missing(id)}, state}
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

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
      payment_method: @payment_method_prefix
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
end
