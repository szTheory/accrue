defmodule Accrue.Connect.Projection do
  @moduledoc """
  Decomposes a processor-shaped (Stripe- or Fake-produced) Connected
  Account payload into a flat attrs map ready for
  `Accrue.Connect.Account.changeset/2` (D5-02).

  Handles both the atom-keyed shape produced by `Accrue.Processor.Fake`
  and the string-keyed shape produced by `Accrue.Processor.Stripe` (after
  `Map.from_struct/1`), via the same dual-key `get/2` helper used by
  `Accrue.Billing.SubscriptionProjection.get/2`.
  """

  alias Accrue.Billing.SubscriptionProjection

  @spec decompose(map() | struct()) :: {:ok, map()}
  def decompose(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> decompose()
  end

  def decompose(stripe_account) when is_map(stripe_account) do
    {:ok,
     %{
       stripe_account_id: get(stripe_account, :id),
       type: parse_type(get(stripe_account, :type)),
       country: get(stripe_account, :country),
       email: get(stripe_account, :email),
       charges_enabled: get(stripe_account, :charges_enabled) || false,
       details_submitted: get(stripe_account, :details_submitted) || false,
       payouts_enabled: get(stripe_account, :payouts_enabled) || false,
       capabilities: get(stripe_account, :capabilities) || %{},
       requirements: get(stripe_account, :requirements) || %{},
       data: SubscriptionProjection.to_string_keys(stripe_account),
       metadata: get(stripe_account, :metadata) || %{}
     }}
  end

  @doc false
  @spec get(map(), atom()) :: term()
  def get(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp parse_type(nil), do: nil
  defp parse_type(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp parse_type(bin) when is_binary(bin), do: bin
end
