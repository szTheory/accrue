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

    LatticeStripe.Client.new!(api_key: key, api_version: api_version)
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
