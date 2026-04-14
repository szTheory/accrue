defmodule Accrue.Billing.PromotionCodeProjection do
  @moduledoc """
  Decomposes a processor promotion-code map (atom- or string-keyed)
  into a flat attrs map ready for
  `Accrue.Billing.PromotionCode.changeset/2`.

  Mirrors `Accrue.Billing.InvoiceProjection` / `SubscriptionProjection`
  shape: handles dual atom/string keys, normalizes the full upstream
  object into jsonb-safe form for the `data` column, and resolves the
  nested `coupon` reference down to the coupon's `processor_id` string
  (the caller looks up the local `coupon_id` FK from that).
  """

  alias Accrue.Billing.SubscriptionProjection

  @type decomposed :: {:ok, map(), coupon_processor_id :: String.t() | nil}

  @spec decompose(map()) :: decomposed()
  def decompose(stripe_promo) when is_map(stripe_promo) do
    coupon_ref = SubscriptionProjection.get(stripe_promo, :coupon)

    coupon_processor_id =
      case coupon_ref do
        nil -> nil
        s when is_binary(s) -> s
        %{} = m -> SubscriptionProjection.get(m, :id)
        _ -> nil
      end

    attrs = %{
      processor_id: SubscriptionProjection.get(stripe_promo, :id),
      code: SubscriptionProjection.get(stripe_promo, :code),
      active: active?(stripe_promo),
      max_redemptions: SubscriptionProjection.get(stripe_promo, :max_redemptions),
      times_redeemed: SubscriptionProjection.get(stripe_promo, :times_redeemed) || 0,
      expires_at: unix_dt(SubscriptionProjection.get(stripe_promo, :expires_at)),
      data: SubscriptionProjection.to_string_keys(stripe_promo),
      metadata: SubscriptionProjection.get(stripe_promo, :metadata) || %{}
    }

    {:ok, attrs, coupon_processor_id}
  end

  defp active?(promo) do
    case SubscriptionProjection.get(promo, :active) do
      nil -> true
      true -> true
      false -> false
      "true" -> true
      "false" -> false
      _ -> true
    end
  end

  defp unix_dt(nil), do: nil
  defp unix_dt(0), do: nil
  defp unix_dt(%DateTime{} = dt), do: dt
  defp unix_dt(n) when is_integer(n), do: DateTime.from_unix!(n)
  defp unix_dt(_), do: nil
end
