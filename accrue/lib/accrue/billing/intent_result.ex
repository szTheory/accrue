defmodule Accrue.Billing.IntentResult do
  @moduledoc """
  Wraps Stripe intent-capable responses into the `intent_result` tagged
  union (D3-06..D3-08).

  Every Phase 3 write path that may surface a PaymentIntent (SCA/3DS)
  runs its processor result through `wrap/1`. The result is one of:

    * `{:ok, struct_or_map}` — happy path
    * `{:ok, :requires_action, pi_map}` — customer action required
    * `{:error, exception}` — anything else

  The wrapper inspects either:

    * A Stripe subscription with an expanded
      `latest_invoice.payment_intent` whose status is `"requires_action"`
    * A direct PaymentIntent / SetupIntent response whose status is
      `"requires_action"` / `"requires_confirmation"` /
      `"requires_payment_method"`

  Fake adapter returns atom-keyed maps; the Stripe adapter returns
  string-keyed maps after `Map.from_struct/1`. The wrapper handles both
  key shapes.
  """

  alias Accrue.Billing.Charge
  alias Accrue.Billing.Invoice
  alias Accrue.Billing.Subscription

  @type ok_value :: map() | struct()
  @type t ::
          {:ok, ok_value()}
          | {:ok, :requires_action, map()}
          | {:error, Exception.t()}

  @doc """
  Wrap a processor or Repo.transact result into the tagged intent_result.

  Pass-through for errors. Leaves `{:ok, %Subscription{}}` and other
  Ecto structs alone unless they carry an embedded requires_action
  payment intent in their `data` column.
  """
  @spec wrap(term()) :: t()
  def wrap({:error, _} = err), do: err

  def wrap({:ok, %Subscription{} = sub} = ok) do
    case sub_pending_intent(sub) do
      %{} = pi ->
        if requires_action?(pi), do: {:ok, :requires_action, pi}, else: ok

      _ ->
        ok
    end
  end

  # WR-02: Invoice and Charge structs carry their canonical Stripe
  # payload in `data`. Peek for an embedded `latest_invoice.payment_intent`
  # (invoice) or `payment_intent` (charge) with requires_action and
  # surface it to the caller — D3-07 `pay_invoice/2` needs this.
  def wrap({:ok, %Invoice{data: data}} = ok) when is_map(data) do
    case get_nested(data, [:payment_intent]) ||
           get_nested(data, [:latest_invoice, :payment_intent]) do
      %{} = pi ->
        if requires_action?(pi), do: {:ok, :requires_action, pi}, else: ok

      _ ->
        ok
    end
  end

  def wrap({:ok, %Charge{data: data}} = ok) when is_map(data) do
    case get_nested(data, [:payment_intent]) do
      %{} = pi ->
        if requires_action?(pi), do: {:ok, :requires_action, pi}, else: ok

      _ ->
        ok
    end
  end

  def wrap({:ok, %{__struct__: _} = _struct} = ok), do: ok

  def wrap({:ok, map}) when is_map(map) do
    cond do
      (pi = get_nested(map, [:latest_invoice, :payment_intent])) && requires_action?(pi) ->
        {:ok, :requires_action, pi}

      requires_action?(map) and has_intent_shape?(map) ->
        {:ok, :requires_action, map}

      pending_error_shape?(map) ->
        {:error,
         %Accrue.CardError{
           message: status_of(map),
           code: status_of(map),
           processor_error: map
         }}

      true ->
        {:ok, map}
    end
  end

  def wrap(other), do: other

  # ---------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------

  @spec sub_pending_intent(Subscription.t()) :: map() | nil
  defp sub_pending_intent(%Subscription{data: data}) when is_map(data),
    do: get_nested(data, [:latest_invoice, :payment_intent])

  defp sub_pending_intent(_), do: nil

  defp requires_action?(%{} = m), do: status_of(m) == "requires_action"
  defp requires_action?(_), do: false

  defp pending_error_shape?(%{} = m) when map_size(m) > 0 do
    status_of(m) in ["requires_confirmation", "requires_payment_method"] and has_intent_shape?(m)
  end

  defp pending_error_shape?(_), do: false

  defp has_intent_shape?(%{} = m) do
    Map.has_key?(m, :client_secret) or Map.has_key?(m, "client_secret") or
      Map.has_key?(m, :next_action) or Map.has_key?(m, "next_action") or
      object_of(m) in ["payment_intent", "setup_intent"]
  end

  defp status_of(%{} = m) do
    case Map.get(m, :status) || Map.get(m, "status") do
      nil -> nil
      atom when is_atom(atom) -> Atom.to_string(atom)
      str when is_binary(str) -> str
      _ -> nil
    end
  end

  defp object_of(%{} = m) do
    case Map.get(m, :object) || Map.get(m, "object") do
      nil -> nil
      atom when is_atom(atom) -> Atom.to_string(atom)
      str when is_binary(str) -> str
      _ -> nil
    end
  end

  defp get_nested(map, [k | rest]) when is_map(map) do
    val = Map.get(map, k) || Map.get(map, to_string(k))

    case {rest, val} do
      {[], v} -> v
      {_, %{} = next} -> get_nested(next, rest)
      _ -> nil
    end
  end
end
