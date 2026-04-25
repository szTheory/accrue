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
    automatic_tax = automatic_tax_fields(get(stripe_sub, :automatic_tax))

    {:ok,
     %{
       processor_id: get(stripe_sub, :id),
       status: parse_status(get(stripe_sub, :status)),
       cancel_at_period_end: get(stripe_sub, :cancel_at_period_end) || false,
       pause_collection: parse_pause_collection(get(stripe_sub, :pause_collection)),
       automatic_tax: automatic_tax.enabled,
       automatic_tax_status: automatic_tax.status,
       automatic_tax_disabled_reason: automatic_tax.disabled_reason,
       current_period_start: unix_to_dt(get(stripe_sub, :current_period_start)),
       current_period_end: unix_to_dt(get(stripe_sub, :current_period_end)),
       trial_start: unix_to_dt(get(stripe_sub, :trial_start)),
       trial_end: unix_to_dt(get(stripe_sub, :trial_end)),
       canceled_at: unix_to_dt(get(stripe_sub, :canceled_at)),
       ended_at: unix_to_dt(get(stripe_sub, :ended_at)),
       discount_id: parse_discount_id(get(stripe_sub, :discount)),
       data: normalize_data(stripe_sub),
       metadata: get(stripe_sub, :metadata) || %{}
     }}
  end

  # Phase 4 Plan 05 (BILL-28) — project Stripe's nested `discount`
  # object down to just the discount id for the local `discount_id`
  # column. Supports both the string form (`"di_..."`) and the nested
  # `%{id: ...}` shape.
  defp parse_discount_id(nil), do: nil
  defp parse_discount_id(s) when is_binary(s), do: s
  defp parse_discount_id(%{} = m), do: get(m, :id)
  defp parse_discount_id(_), do: nil

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

  @doc false
  def automatic_tax_fields(nil), do: %{enabled: false, status: nil, disabled_reason: nil}

  def automatic_tax_fields(%{} = automatic_tax) do
    %{
      enabled: get(automatic_tax, :enabled) || false,
      status: get(automatic_tax, :status),
      disabled_reason: get(automatic_tax, :disabled_reason)
    }
  end

  def automatic_tax_fields(_), do: %{enabled: false, status: nil, disabled_reason: nil}

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
  normalization rather than storing atom-keyed data and getting shape
  drift on reload.
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
