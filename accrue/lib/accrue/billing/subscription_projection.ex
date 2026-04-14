defmodule Accrue.Billing.SubscriptionProjection do
  @moduledoc """
  Decomposes a processor (Stripe- or Fake-shaped) subscription map into
  a flat attrs map ready for `Accrue.Billing.Subscription.changeset/2`
  (D3-02).

  Handles both the atom-keyed shape produced by `Accrue.Processor.Fake`
  and the string-keyed shape produced by `Accrue.Processor.Stripe`
  (after `Map.from_struct/1`).
  """

  @valid_statuses ~w(trialing active past_due canceled unpaid incomplete incomplete_expired paused)a

  @spec decompose(map()) :: {:ok, map()}
  def decompose(stripe_sub) when is_map(stripe_sub) do
    {:ok,
     %{
       processor_id: get(stripe_sub, :id),
       status: parse_status(get(stripe_sub, :status)),
       cancel_at_period_end: get(stripe_sub, :cancel_at_period_end) || false,
       pause_collection: parse_pause_collection(get(stripe_sub, :pause_collection)),
       current_period_start: unix_to_dt(get(stripe_sub, :current_period_start)),
       current_period_end: unix_to_dt(get(stripe_sub, :current_period_end)),
       trial_start: unix_to_dt(get(stripe_sub, :trial_start)),
       trial_end: unix_to_dt(get(stripe_sub, :trial_end)),
       canceled_at: unix_to_dt(get(stripe_sub, :canceled_at)),
       ended_at: unix_to_dt(get(stripe_sub, :ended_at)),
       data: normalize_data(stripe_sub),
       metadata: get(stripe_sub, :metadata) || %{}
     }}
  end

  # Expose helpers so SubscriptionActions can reuse them.
  @doc false
  def get(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  @doc false
  def unix_to_dt(nil), do: nil
  def unix_to_dt(%DateTime{} = dt), do: dt
  def unix_to_dt(0), do: nil
  def unix_to_dt(n) when is_integer(n), do: DateTime.from_unix!(n)
  # Fake adapter may echo back the literal "now" trial_end param; treat as Clock.utc_now.
  def unix_to_dt("now"), do: Accrue.Clock.utc_now()
  def unix_to_dt(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_status(nil), do: :incomplete

  defp parse_status(atom) when is_atom(atom) do
    if atom in @valid_statuses, do: atom, else: :incomplete
  end

  defp parse_status(str) when is_binary(str) do
    try do
      atom = String.to_existing_atom(str)
      if atom in @valid_statuses, do: atom, else: :incomplete
    rescue
      ArgumentError -> :incomplete
    end
  end

  defp parse_pause_collection(nil), do: nil
  defp parse_pause_collection(%{} = m) when map_size(m) == 0, do: nil
  defp parse_pause_collection(%{} = m), do: m

  # Persisted `data` jsonb should be string-keyed (JSON round-trip safe).
  defp normalize_data(map) when is_map(map) do
    map
    |> to_string_keys()
  end

  @doc """
  Recursively converts atom-keyed maps to string-keyed maps and
  DateTimes to ISO8601 strings so the result is jsonb round-trip safe.

  Public so `Accrue.Billing.InvoiceProjection` can reuse the same
  normalization (WR-11) rather than storing atom-keyed data and
  getting shape drift on reload.
  """
  @spec to_string_keys(term()) :: term()
  def to_string_keys(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  def to_string_keys(%{__struct__: _} = struct),
    do: struct |> Map.from_struct() |> to_string_keys()

  def to_string_keys(map) when is_map(map) do
    for {k, v} <- map, into: %{} do
      {to_string(k), to_string_keys(v)}
    end
  end

  def to_string_keys(list) when is_list(list), do: Enum.map(list, &to_string_keys/1)
  def to_string_keys(other), do: other
end
