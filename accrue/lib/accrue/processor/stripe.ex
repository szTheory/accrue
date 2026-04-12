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

  @default_api_version "2026-03-25.dahlia"

  # ---------------------------------------------------------------------------
  # Behaviour callbacks
  # ---------------------------------------------------------------------------

  @impl Accrue.Processor
  def create_customer(params, opts) when is_map(params) and is_list(opts) do
    Telemetry.span(
      [:accrue, :processor, :customer, :create],
      %{adapter: :stripe, operation: :create_customer},
      fn ->
        client = build_client!()

        client
        |> LatticeStripe.Customer.create(stringify_keys(params), opts)
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
        client = build_client!()

        client
        |> LatticeStripe.Customer.retrieve(id, opts)
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
        client = build_client!()

        client
        |> LatticeStripe.Customer.update(id, stringify_keys(params), opts)
        |> translate_customer()
      end
    )
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  @spec build_client!() :: LatticeStripe.Client.t()
  defp build_client! do
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

    api_version = Application.get_env(:accrue, :stripe_api_version, @default_api_version)

    LatticeStripe.Client.new!(api_key: key, api_version: api_version)
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
