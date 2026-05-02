defmodule Accrue.Billing.SubscriptionProjection do
  @moduledoc """
  Translates a processor subscription response into local Ecto changesets.

  A "projection" in Accrue means decomposing a processor subscription
  response into a flat attrs map that `Accrue.Billing.Subscription`
  accepts. This module handles type coercions, provider-specific lifecycle
  fields, and `data` normalization for round-trip safety.

  Handles both the atom-keyed shape produced by `Accrue.Processor.Fake`
  and the string-keyed shape produced by remote adapters. Callers may pass
  `processor: :stripe | :paddle | ...` to force a specific projection mode;
  otherwise the configured processor name is used.
  """

  @valid_statuses ~w(trialing active past_due canceled unpaid incomplete incomplete_expired paused)a

  @spec decompose(map(), keyword()) :: {:ok, map()}
  def decompose(subscription, opts \\ [])

  def decompose(subscription, opts) when is_map(subscription) and is_list(opts) do
    processor = Keyword.get(opts, :processor, processor_atom())

    case processor do
      :paddle -> {:ok, paddle_attrs(subscription)}
      :braintree -> {:ok, braintree_attrs(subscription)}
      _ -> {:ok, stripe_attrs(subscription)}
    end
  end

  defp stripe_attrs(stripe_sub) do
    automatic_tax = automatic_tax_fields(get(stripe_sub, :automatic_tax))

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
      cancel_at: unix_to_dt(get(stripe_sub, :cancel_at)),
      canceled_at: unix_to_dt(get(stripe_sub, :canceled_at)),
      ended_at: unix_to_dt(get(stripe_sub, :ended_at)),
      discount_id: parse_discount_id(get(stripe_sub, :discount)),
      data: normalize_data(stripe_sub),
      metadata: get(stripe_sub, :metadata) || %{}
    }
  end

  defp braintree_attrs(braintree_sub) do
    status_str =
      braintree_sub
      |> get(:status)
      |> to_string()
      |> String.downcase()
      |> String.replace(" ", "_")

    status = parse_braintree_status(status_str)
    canceled_at = braintree_canceled_at(braintree_sub, status)

    %{
      processor_id: get(braintree_sub, :id),
      status: status,
      cancel_at_period_end: false,
      pause_collection: nil,
      automatic_tax: false,
      automatic_tax_status: nil,
      automatic_tax_disabled_reason: nil,
      current_period_start: unix_to_dt(get(braintree_sub, :billing_period_start_date)),
      current_period_end: unix_to_dt(get(braintree_sub, :billing_period_end_date)),
      trial_start: unix_to_dt(get(braintree_sub, :first_billing_date)),
      trial_end: nil,
      cancel_at: nil,
      canceled_at: canceled_at,
      ended_at: braintree_ended_at(braintree_sub, status, canceled_at),
      discount_id: parse_discount_id(first_discount(braintree_sub)),
      data: normalize_data(braintree_sub),
      metadata: %{}
    }
  end

  defp paddle_attrs(subscription) do
    billing_period = get(subscription, :current_billing_period) || %{}
    scheduled_change = get(subscription, :scheduled_change) || %{}
    status = parse_status(get(subscription, :status))
    cancel_action? = scheduled_change_action(scheduled_change) == "cancel"
    paused? = status == :paused or scheduled_change_action(scheduled_change) == "pause"

    %{
      processor_id: get(subscription, :id),
      status: status,
      cancel_at_period_end: cancel_action?,
      pause_collection: if(paused?, do: normalize_data(scheduled_change), else: nil),
      automatic_tax: false,
      automatic_tax_status: nil,
      automatic_tax_disabled_reason: nil,
      current_period_start:
        unix_to_dt(get(billing_period, :starts_at) || get(subscription, :current_period_start)),
      current_period_end:
        unix_to_dt(get(billing_period, :ends_at) || get(subscription, :current_period_end)),
      trial_start: unix_to_dt(get(subscription, :trial_start)),
      trial_end: unix_to_dt(get(subscription, :trial_end)),
      cancel_at: unix_to_dt(get(scheduled_change, :effective_at)),
      canceled_at: unix_to_dt(get(subscription, :canceled_at)),
      ended_at: unix_to_dt(get(subscription, :ended_at) || get(subscription, :canceled_at)),
      discount_id: parse_discount_id(first_discount(subscription)),
      data: normalize_data(subscription),
      metadata: get(subscription, :custom_data) || get(subscription, :metadata) || %{}
    }
  end

  # Project Stripe's nested `discount` object down to just the discount
  # id for the local `discount_id` column. Supports both the bare
  # string form (`"di_..."`) and the nested `%{id: ...}` shape.
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

  defp parse_braintree_status("expired"), do: :canceled
  defp parse_braintree_status(status), do: parse_status(status)

  defp braintree_canceled_at(subscription, status) when status in [:canceled] do
    unix_to_dt(get(subscription, :updated_at)) ||
      unix_to_dt(get(subscription, :billing_period_end_date))
  end

  defp braintree_canceled_at(_subscription, _status), do: nil

  defp braintree_ended_at(subscription, :canceled, canceled_at) do
    canceled_at || unix_to_dt(get(subscription, :billing_period_end_date))
  end

  defp braintree_ended_at(_subscription, _status, _canceled_at) do
    nil
  end

  # Persisted `data` jsonb should be string-keyed (JSON round-trip safe).
  defp normalize_data(map) when is_map(map) do
    map
    |> to_string_keys()
  end

  defp first_discount(subscription) do
    subscription
    |> get(:discount)
    |> case do
      nil ->
        subscription
        |> get(:discounts)
        |> case do
          [%{} = discount | _] -> discount
          _ -> nil
        end

      discount ->
        discount
    end
  end

  defp scheduled_change_action(%{} = scheduled_change), do: get(scheduled_change, :action)
  defp scheduled_change_action(_), do: nil

  defp processor_atom do
    case Accrue.Processor.name() do
      "paddle" -> :paddle
      "fake" -> :fake
      "braintree" -> :braintree
      _ -> :stripe
    end
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
