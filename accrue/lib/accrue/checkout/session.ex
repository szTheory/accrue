defmodule Accrue.Checkout.Session do
  @moduledoc """
  Stripe Checkout Session wrapper (CHKT-01/02).

  Wraps the processor-level `checkout_session_create/2` and
  `checkout_session_fetch/2` callbacks, projects the raw Stripe
  payload into a tightly-typed struct, and masks the embedded-mode
  `:client_secret` field in `Inspect` output (T-04-07-08) — anyone
  holding a `client_secret` can mount the embedded checkout flow on
  the customer's behalf until the session expires.

  Two `ui_mode` values are supported:

    * `:hosted` (default) — Stripe-hosted Checkout page; the
      returned `%Session{}` has a `:url` to redirect the customer to.
    * `:embedded` — the host app mounts Stripe.js's embedded form;
      the returned `%Session{}` has a `:client_secret` to hand to
      the front end.

  The `:mode` option mirrors the Stripe Checkout `mode` parameter:
  `:subscription` (default), `:payment`, or `:setup`.
  """

  alias Accrue.Billing.Customer
  alias Accrue.Processor

  @enforce_keys [:id]
  defstruct [
    :id,
    :object,
    :mode,
    :ui_mode,
    :automatic_tax,
    :url,
    :client_secret,
    :status,
    :payment_status,
    :customer,
    :subscription,
    :payment_intent,
    :amount_total,
    :amount_tax,
    :currency,
    :expires_at,
    :metadata,
    :data
  ]

  @type t :: %__MODULE__{}

  @create_schema [
    mode: [type: {:in, [:subscription, :payment, :setup]}, default: :subscription],
    ui_mode: [type: {:in, [:hosted, :embedded]}, default: :hosted],
    customer: [
      type: {:or, [:string, {:struct, Customer}, nil]},
      default: nil
    ],
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
  Creates a Checkout Session through the configured processor.

  See module docs for accepted options. Returns `{:ok, %Session{}}`
  on success.
  """
  @spec create(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def create(params) when is_list(params), do: create(Map.new(params))

  def create(params) when is_map(params) do
    opts = NimbleOptions.validate!(Map.to_list(params), @create_schema)
    {stripe_params, request_opts} = build_stripe_params(opts)

    case Processor.__impl__().checkout_session_create(stripe_params, request_opts) do
      {:ok, stripe_session} -> {:ok, from_stripe(stripe_session)}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Bang variant of `create/1`. Raises `Accrue.APIError` (or a generic
  `RuntimeError`) on failure.
  """
  @spec create!(map() | keyword()) :: t()
  def create!(params) do
    case create(params) do
      {:ok, session} ->
        session

      {:error, err} when is_exception(err) ->
        raise err

      {:error, other} ->
        raise "Accrue.Checkout.Session.create/1 failed: #{inspect(other)}"
    end
  end

  @doc """
  Retrieves a Checkout Session by id.
  """
  @spec retrieve(String.t()) :: {:ok, t()} | {:error, term()}
  def retrieve(id) when is_binary(id) do
    case Processor.__impl__().checkout_session_fetch(id, []) do
      {:ok, stripe_session} -> {:ok, from_stripe(stripe_session)}
      {:error, err} -> {:error, err}
    end
  end

  @doc false
  @spec from_stripe(map()) :: t()
  def from_stripe(stripe) when is_map(stripe) do
    %__MODULE__{
      id: get(stripe, :id),
      object: get(stripe, :object) || "checkout.session",
      mode: to_string_or_nil(get(stripe, :mode)),
      ui_mode: to_string_or_nil(get(stripe, :ui_mode)),
      automatic_tax: automatic_tax_enabled(stripe),
      url: get(stripe, :url),
      client_secret: get(stripe, :client_secret),
      status: to_string_or_nil(get(stripe, :status)),
      payment_status: to_string_or_nil(get(stripe, :payment_status)),
      customer: get(stripe, :customer),
      subscription: get(stripe, :subscription),
      payment_intent: get(stripe, :payment_intent),
      amount_total: get(stripe, :amount_total),
      amount_tax: amount_tax(stripe),
      currency: to_string_or_nil(get(stripe, :currency)),
      expires_at: get(stripe, :expires_at),
      metadata: get(stripe, :metadata) || %{},
      data: stripe
    }
  end

  defp build_stripe_params(opts) do
    {operation_id, opts} = Keyword.pop(opts, :operation_id)

    customer_id =
      case opts[:customer] do
        nil -> nil
        bin when is_binary(bin) -> bin
        %Customer{processor_id: pid} -> pid
      end

    base =
      %{
        "mode" => Atom.to_string(opts[:mode]),
        "ui_mode" => Atom.to_string(opts[:ui_mode]),
        "automatic_tax" => %{"enabled" => opts[:automatic_tax]}
      }
      |> put_unless_nil("customer", customer_id)
      |> put_unless_nil("success_url", opts[:success_url])
      |> put_unless_nil("cancel_url", opts[:cancel_url])
      |> put_unless_nil("return_url", opts[:return_url])
      |> put_unless_nil("metadata", opts[:metadata])
      |> put_unless_nil("client_reference_id", opts[:client_reference_id])
      |> Map.put("line_items", opts[:line_items] || [])

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

  defp automatic_tax_enabled(stripe) do
    stripe
    |> get(:automatic_tax)
    |> case do
      nil -> false
      automatic_tax -> get(automatic_tax, :enabled) || false
    end
  end

  defp amount_tax(stripe) do
    stripe
    |> get(:total_details)
    |> case do
      nil -> nil
      total_details -> get(total_details, :amount_tax)
    end
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(v) when is_atom(v), do: Atom.to_string(v)
  defp to_string_or_nil(v) when is_binary(v), do: v
  defp to_string_or_nil(_), do: nil
end

defimpl Inspect, for: Accrue.Checkout.Session do
  import Inspect.Algebra

  # T-04-07-08: client_secret is the embedded-mode bearer credential
  # that authorizes mounting Stripe.js Elements on behalf of the
  # customer. Mask it the same way Phase 2 masks WebhookEvent.raw_body.
  def inspect(%Accrue.Checkout.Session{} = session, opts) do
    fields = [
      id: session.id,
      mode: session.mode,
      ui_mode: session.ui_mode,
      status: session.status,
      payment_status: session.payment_status,
      url: session.url,
      client_secret: if(session.client_secret, do: "<redacted>", else: nil),
      customer: session.customer,
      subscription: session.subscription,
      amount_total: session.amount_total,
      currency: session.currency
    ]

    pairs =
      fields
      |> Enum.map(fn {k, v} ->
        concat([Atom.to_string(k), ": ", to_doc(v, opts)])
      end)
      |> Enum.intersperse(", ")

    concat(["#Accrue.Checkout.Session<" | pairs] ++ [">"])
  end
end
