defmodule Accrue.BillingPortal.Session do
  @moduledoc """
  Stripe Customer Billing Portal session wrapper.

  Wraps the processor-level `portal_session_create/2` callback,
  projects the response into a tightly-typed struct, and **masks the
  `:url` field in `Inspect` output** — the portal URL is
  a single-use, short-lived (~5 minute) authenticated bearer
  credential that impersonates the customer in the Stripe portal.
  Any leak via Logger, APM, crash dumps, or telemetry handlers is an
  account-takeover vector within the TTL window.

  ## Configuration

  Programmatic `BillingPortal.Configuration` support is deferred to a
  future processor release. For now, host apps configure portal
  behavior in the Stripe Dashboard (matching the Pay/Cashier
  convention) and pass the resulting `bpc_*` id via the
  `:configuration` option on `create/1`. See
  `guides/portal_configuration_checklist.md` for the three required
  Dashboard toggles that defend against the "cancel-without-dunning"
  footgun (Pitfall 6).
  """

  alias Accrue.Billing.Customer
  alias Accrue.Processor

  @enforce_keys [:id]
  defstruct [
    :id,
    :object,
    :customer,
    :url,
    :return_url,
    :configuration,
    :flow,
    :locale,
    :on_behalf_of,
    :livemode,
    :created,
    :data
  ]

  @type t :: %__MODULE__{}

  @create_schema [
    customer: [
      type: {:or, [:string, {:struct, Customer}]},
      required: true
    ],
    return_url: [type: {:or, [:string, nil]}, default: nil],
    configuration: [type: {:or, [:string, nil]}, default: nil],
    flow_data: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    locale: [type: {:or, [:string, nil]}, default: nil],
    on_behalf_of: [type: {:or, [:string, nil]}, default: nil],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @doc """
  Creates a Customer Billing Portal session through the configured
  processor.
  """
  @spec create(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def create(params) when is_list(params), do: create(Map.new(params))

  def create(params) when is_map(params) do
    opts = NimbleOptions.validate!(Map.to_list(params), @create_schema)
    {stripe_params, request_opts} = build_params(opts)

    case Processor.__impl__().portal_session_create(stripe_params, request_opts) do
      {:ok, stripe_session} -> {:ok, from_stripe(stripe_session)}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Bang variant of `create/1`. Raises on failure.
  """
  @spec create!(map() | keyword()) :: t()
  def create!(params) do
    case create(params) do
      {:ok, session} ->
        session

      {:error, err} when is_exception(err) ->
        raise err

      {:error, other} ->
        raise "Accrue.BillingPortal.Session.create/1 failed: #{inspect(other)}"
    end
  end

  @doc false
  @spec from_stripe(map()) :: t()
  def from_stripe(stripe) when is_map(stripe) do
    %__MODULE__{
      id: get(stripe, :id),
      object: get(stripe, :object) || "billing_portal.session",
      customer: get(stripe, :customer),
      url: get(stripe, :url),
      return_url: get(stripe, :return_url),
      configuration: get(stripe, :configuration),
      flow: get(stripe, :flow),
      locale: get(stripe, :locale),
      on_behalf_of: get(stripe, :on_behalf_of),
      livemode: get(stripe, :livemode) || false,
      created: get(stripe, :created),
      data: stripe
    }
  end

  defp build_params(opts) do
    {operation_id, opts} = Keyword.pop(opts, :operation_id)

    customer_id =
      case opts[:customer] do
        bin when is_binary(bin) -> bin
        %Customer{processor_id: pid} -> pid
      end

    base =
      %{"customer" => customer_id}
      |> put_unless_nil("return_url", opts[:return_url])
      |> put_unless_nil("configuration", opts[:configuration])
      |> put_unless_nil("flow_data", opts[:flow_data])
      |> put_unless_nil("locale", opts[:locale])
      |> put_unless_nil("on_behalf_of", opts[:on_behalf_of])

    request_opts =
      []
      |> put_kw_unless_nil(:operation_id, operation_id)

    {base, request_opts}
  end

  defp put_unless_nil(map, _key, nil), do: map
  defp put_unless_nil(map, key, value), do: Map.put(map, key, value)

  defp put_kw_unless_nil(kw, _key, nil), do: kw
  defp put_kw_unless_nil(kw, key, value), do: Keyword.put(kw, key, value)

  defp get(%{} = map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end

defimpl Inspect, for: Accrue.BillingPortal.Session do
  import Inspect.Algebra

  # `:url` is a single-use, short-lived (~5 min) bearer
  # credential that impersonates the customer in the portal until it
  # expires. Any leak via Logger / APM / crash dumps / telemetry
  # handlers is an account-takeover vector. Mask it in Inspect output
  # the same way other sensitive structs mask raw payloads.
  def inspect(%Accrue.BillingPortal.Session{} = session, opts) do
    fields = [
      id: session.id,
      object: session.object,
      customer: session.customer,
      url: if(session.url, do: "<redacted>", else: nil),
      return_url: session.return_url,
      configuration: session.configuration,
      locale: session.locale,
      livemode: session.livemode
    ]

    pairs =
      fields
      |> Enum.map(fn {k, v} ->
        concat([Atom.to_string(k), ": ", to_doc(v, opts)])
      end)
      |> Enum.intersperse(", ")

    concat(["#Accrue.BillingPortal.Session<" | pairs] ++ [">"])
  end
end
