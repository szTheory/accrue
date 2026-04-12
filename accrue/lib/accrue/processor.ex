defmodule Accrue.Processor do
  @moduledoc """
  Behaviour every processor adapter implements, plus a runtime-dispatching
  facade so every caller looks like `Accrue.Processor.create_customer(...)`
  regardless of which adapter is wired.

  ## Phase 1 callback surface

  Phase 1 defines only the customer callbacks needed to prove the Fake's
  shape and exercise the facade:

  - `create_customer/2`
  - `retrieve_customer/2`
  - `update_customer/3`

  Phase 3 grows this behaviour to the full Stripe Billing surface:

      # Phase 3 additions (not yet implemented)
      # @callback create_subscription/2
      # @callback retrieve_subscription/2
      # @callback cancel_subscription/3
      # @callback create_payment_intent/2
      # @callback confirm_payment_intent/3
      # @callback create_payment_method/2
      # @callback attach_payment_method/3
      # @callback detach_payment_method/2
      # @callback create_invoice/2
      # @callback retrieve_invoice/2
      # @callback finalize_invoice/2

  `Accrue.Processor.Fake` is shaped to accommodate these from day one via
  per-resource counters (`cus_fake_`, `sub_fake_`, `in_fake_`, `pi_fake_`,
  `pm_fake_`) so Phase 3 grows the callback list without schema churn.

  ## Runtime dispatch

  The public `create_customer/2`, `retrieve_customer/2`, and
  `update_customer/3` functions resolve the concrete adapter at call time
  via `Application.get_env(:accrue, :processor, Accrue.Processor.Fake)`.
  The default is the Fake — production deploys flip it to
  `Accrue.Processor.Stripe` in `config/runtime.exs`.

  ## Telemetry

  Each public call is wrapped in `Accrue.Telemetry.span/3` emitting
  `[:accrue, :processor, :customer, :<action>, :start | :stop | :exception]`
  per OBS-01 (D-17). Metadata includes `:adapter` (the resolved module),
  `:operation`, and the merged `Accrue.Actor.current/0`. **Raw params and
  return values are NEVER auto-injected into metadata** — the Stripe adapter
  must not shove PII or raw processor errors into telemetry payloads
  (T-OBS-01 mitigation).
  """

  alias Accrue.Telemetry

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Exception.t()}

  @callback create_customer(params(), opts()) :: result()
  @callback retrieve_customer(id(), opts()) :: result()
  @callback update_customer(id(), params(), opts()) :: result()

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
