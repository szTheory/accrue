defmodule Accrue.Billing.InvoiceProjection do
  @moduledoc """
  Deterministic decomposition of a processor (Stripe- or Fake-shaped)
  invoice into a flat attrs map ready for `Accrue.Billing.Invoice.changeset/2`
  plus a list of per-line attrs ready for
  `Accrue.Billing.InvoiceItem.changeset/2`.

  Mirrors `Accrue.Billing.SubscriptionProjection` (D3-13..17): extracts
  every D3-14 rollup column, converts unix-seconds timestamps to
  `DateTime`, preserves the full upstream map in the `data` jsonb column,
  and handles both string-keyed (Stripe wire shape via `Map.from_struct/1`)
  and atom-keyed (`Accrue.Processor.Fake` state) inputs.

  Used by both the user-path actions in `Accrue.Billing.InvoiceActions`
  (Plan 05) and the webhook DefaultHandler reconcile path (Plan 07) so
  that both code paths converge on identical rows.
  """

  alias Accrue.Billing.SubscriptionProjection

  @valid_statuses ~w(draft open paid uncollectible void)a

  @type decomposed :: %{invoice_attrs: map(), item_attrs: [map()]}

  @spec decompose(map()) :: {:ok, decomposed()}
  def decompose(stripe_inv) when is_map(stripe_inv) do
    currency = SubscriptionProjection.get(stripe_inv, :currency)
    status_transitions = SubscriptionProjection.get(stripe_inv, :status_transitions) || %{}

    discount = SubscriptionProjection.get(stripe_inv, :discount)

    total_discount_amounts =
      case SubscriptionProjection.get(stripe_inv, :total_discount_amounts) do
        nil -> []
        list when is_list(list) -> list
        _ -> []
      end

    discount_minor =
      cond do
        total_discount_amounts != [] ->
          Enum.reduce(total_discount_amounts, 0, fn d, acc ->
            acc + (SubscriptionProjection.get(d, :amount) || 0)
          end)

        match?(%{}, discount) ->
          SubscriptionProjection.get(discount, :amount_off)

        true ->
          nil
      end

    invoice_attrs = %{
      processor_id: SubscriptionProjection.get(stripe_inv, :id),
      status: parse_status(SubscriptionProjection.get(stripe_inv, :status)),
      subtotal_minor: SubscriptionProjection.get(stripe_inv, :subtotal),
      tax_minor: SubscriptionProjection.get(stripe_inv, :tax),
      discount_minor: discount_minor,
      # Wrap in a map because the `:total_discount_amounts` Ecto field
      # is `:map` (jsonb) which rejects top-level arrays. Mirror
      # Stripe's own list-object shape (`%{"object": "list",
      # "data": [...]}`) for admin-LV ergonomics.
      total_discount_amounts: %{
        "data" => SubscriptionProjection.to_string_keys(total_discount_amounts)
      },
      total_minor: SubscriptionProjection.get(stripe_inv, :total),
      amount_due_minor: SubscriptionProjection.get(stripe_inv, :amount_due),
      amount_paid_minor: SubscriptionProjection.get(stripe_inv, :amount_paid),
      amount_remaining_minor: SubscriptionProjection.get(stripe_inv, :amount_remaining),
      currency: currency,
      number: SubscriptionProjection.get(stripe_inv, :number),
      hosted_url:
        SubscriptionProjection.get(stripe_inv, :hosted_invoice_url) ||
          SubscriptionProjection.get(stripe_inv, :hosted_url),
      pdf_url:
        SubscriptionProjection.get(stripe_inv, :invoice_pdf) ||
          SubscriptionProjection.get(stripe_inv, :pdf_url),
      period_start: unix_dt(SubscriptionProjection.get(stripe_inv, :period_start)),
      period_end: unix_dt(SubscriptionProjection.get(stripe_inv, :period_end)),
      due_date: unix_dt(SubscriptionProjection.get(stripe_inv, :due_date)),
      collection_method: SubscriptionProjection.get(stripe_inv, :collection_method),
      billing_reason: SubscriptionProjection.get(stripe_inv, :billing_reason),
      finalized_at:
        unix_dt(SubscriptionProjection.get(stripe_inv, :finalized_at)) ||
          unix_dt(SubscriptionProjection.get(status_transitions, :finalized_at)),
      paid_at:
        unix_dt(SubscriptionProjection.get(stripe_inv, :paid_at)) ||
          unix_dt(SubscriptionProjection.get(status_transitions, :paid_at)),
      voided_at:
        unix_dt(SubscriptionProjection.get(stripe_inv, :voided_at)) ||
          unix_dt(SubscriptionProjection.get(status_transitions, :voided_at)),
      # WR-11: string-normalize so Fake (atom-keyed) and Stripe
      # (string-keyed) paths persist the same shape. Avoids drift on
      # reload where a second decompose/1 sees a different key shape.
      data: SubscriptionProjection.to_string_keys(stripe_inv),
      metadata: SubscriptionProjection.get(stripe_inv, :metadata) || %{}
    }

    item_attrs =
      stripe_inv
      |> SubscriptionProjection.get(:lines)
      |> case do
        nil -> []
        %{} = m -> SubscriptionProjection.get(m, :data) || []
        list when is_list(list) -> list
      end
      |> Enum.map(fn line ->
        period = SubscriptionProjection.get(line, :period) || %{}
        price = SubscriptionProjection.get(line, :price)

        %{
          stripe_id: SubscriptionProjection.get(line, :id),
          description: SubscriptionProjection.get(line, :description),
          amount_minor: SubscriptionProjection.get(line, :amount),
          currency: SubscriptionProjection.get(line, :currency) || currency,
          quantity: SubscriptionProjection.get(line, :quantity) || 1,
          period_start: unix_dt(SubscriptionProjection.get(period, :start)),
          period_end: unix_dt(SubscriptionProjection.get(period, :end)),
          proration: SubscriptionProjection.get(line, :proration) == true,
          price_ref: price_id_of(price),
          subscription_item_ref: SubscriptionProjection.get(line, :subscription_item),
          data: line
        }
      end)

    {:ok, %{invoice_attrs: invoice_attrs, item_attrs: item_attrs}}
  end

  defp price_id_of(nil), do: nil
  defp price_id_of(str) when is_binary(str), do: str
  defp price_id_of(%{} = m), do: SubscriptionProjection.get(m, :id)

  defp parse_status(nil), do: :draft
  defp parse_status(atom) when is_atom(atom) do
    if atom in @valid_statuses, do: atom, else: :draft
  end

  defp parse_status(str) when is_binary(str) do
    try do
      atom = String.to_existing_atom(str)
      if atom in @valid_statuses, do: atom, else: :draft
    rescue
      ArgumentError -> :draft
    end
  end

  defp unix_dt(nil), do: nil
  defp unix_dt(0), do: nil
  defp unix_dt(%DateTime{} = dt), do: dt
  defp unix_dt(n) when is_integer(n), do: DateTime.from_unix!(n)
  defp unix_dt(_), do: nil
end
