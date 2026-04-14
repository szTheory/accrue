defmodule Accrue.Billing.RefundActions do
  @moduledoc """
  Phase 3 Plan 06 refund write surface (BILL-26, D3-45..47).

  Ships `create_refund/2` with **sync best-effort fee math**: when the
  processor response carries an expanded
  `charge.balance_transaction.fee_refunded`, the refund row is persisted
  with `stripe_fee_refunded_amount_minor`, `merchant_loss_amount_minor`,
  and `fees_settled_at`. When the balance_transaction is not yet
  populated, those columns stay nil — the webhook backstop in Plan 07
  (`charge.refund.updated`) fills them asynchronously.

  Return shape is uniform `{:ok, %Refund{}}` — **no** tagged variant
  like `{:ok, :pending_fees, _}` — because fee settlement state is a
  property of the row (`fees_settled?/1` predicate), not a branch in the
  caller's control flow (D3-47).
  """

  alias Accrue.Actor
  alias Accrue.Billing.{Charge, Refund}
  alias Accrue.Events
  alias Accrue.Money
  alias Accrue.Processor
  alias Accrue.Processor.Idempotency
  alias Accrue.Repo

  # ---------------------------------------------------------------------
  # create_refund/2 (BILL-26)
  # ---------------------------------------------------------------------

  @doc """
  Creates a refund for the given `%Charge{}`. Always returns
  `{:ok, %Refund{}}` on success — fee settlement state is tracked via
  `Refund.fees_settled?/1`.

  ## Options

    * `:amount` — `%Accrue.Money{}`, defaults to the full charge amount
      (`charge.amount_cents`).
    * `:reason` — refund reason string passed to the processor.
    * `:operation_id` — deterministic idempotency seed.
  """
  @spec create_refund(Charge.t(), keyword()) ::
          {:ok, Refund.t()} | {:error, term()}
  def create_refund(%Charge{} = charge, opts \\ []) do
    amount_minor =
      case Keyword.get(opts, :amount) do
        nil -> charge.amount_cents
        %Money{amount_minor: n} -> n
      end

    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    subject_uuid = Idempotency.subject_uuid(:create_refund, op_id)
    idem_key = Idempotency.key(:create_refund, subject_uuid, op_id)

    params =
      %{
        charge: charge.processor_id,
        amount: amount_minor,
        expand: ["balance_transaction", "charge.balance_transaction"]
      }
      |> put_if_present(:reason, Keyword.get(opts, :reason))

    Repo.transact(fn ->
      with {:ok, stripe_refund} <-
             Processor.__impl__().create_refund(
               params,
               [idempotency_key: idem_key] ++ sanitize_opts(opts)
             ),
           {:ok, refund_row} <-
             insert_or_fetch_refund(subject_uuid, charge, stripe_refund, amount_minor),
           {:ok, _} <-
             record_event("refund.created", refund_row, %{
               amount_minor: amount_minor,
               charge_id: charge.id
             }) do
        {:ok, refund_row}
      end
    end)
  end

  @doc "Raising variant of `create_refund/2`."
  @spec create_refund!(Charge.t(), keyword()) :: Refund.t()
  def create_refund!(charge, opts \\ []) do
    case create_refund(charge, opts) do
      {:ok, refund} -> refund
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "create_refund!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------

  defp insert_or_fetch_refund(id, charge, stripe_refund, amount_minor) do
    case Repo.get(Refund, id) do
      %Refund{} = existing ->
        {:ok, existing}

      nil ->
        insert_refund(id, charge, stripe_refund, amount_minor)
    end
  end

  defp insert_refund(id, %Charge{} = charge, stripe_refund, amount_minor) do
    charge_bt =
      case get_field(stripe_refund, :charge) do
        %{} = c -> get_field(c, :balance_transaction) || %{}
        _ -> %{}
      end

    fee = get_field(charge_bt, :fee)
    fee_refunded = get_field(charge_bt, :fee_refunded)

    {stripe_fee_refunded, merchant_loss, settled_at} =
      case {fee, fee_refunded} do
        {f, fr} when is_integer(f) and is_integer(fr) ->
          {fr, f - fr, Accrue.Clock.utc_now()}

        _ ->
          {nil, nil, nil}
      end

    status =
      case get_field(stripe_refund, :status) do
        s when is_atom(s) and not is_nil(s) -> s
        s when is_binary(s) -> String.to_existing_atom(s)
        _ -> :pending
      end

    currency =
      case get_field(stripe_refund, :currency) do
        c when is_binary(c) -> c
        c when is_atom(c) and not is_nil(c) -> Atom.to_string(c)
        _ -> charge.currency
      end

    attrs = %{
      charge_id: charge.id,
      stripe_id: get_field(stripe_refund, :id),
      amount_minor: get_field(stripe_refund, :amount) || amount_minor,
      currency: currency,
      reason: get_field(stripe_refund, :reason),
      status: status,
      stripe_fee_refunded_amount_minor: stripe_fee_refunded,
      merchant_loss_amount_minor: merchant_loss,
      fees_settled_at: settled_at,
      data: stringify(stripe_refund),
      metadata: get_field(stripe_refund, :metadata) || %{}
    }

    %Refund{}
    |> Refund.changeset(attrs)
    |> Ecto.Changeset.force_change(:id, id)
    |> Repo.insert()
  end

  defp record_event(type, %Refund{} = refund, data) do
    Events.record(%{
      type: type,
      subject_type: "Refund",
      subject_id: refund.id,
      data: data
    })
  end

  defp get_field(%{} = m, key) when is_atom(key) do
    Map.get(m, key) || Map.get(m, Atom.to_string(key))
  end

  defp get_field(_, _), do: nil

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp sanitize_opts(opts), do: Keyword.drop(opts, [:amount, :reason, :operation_id])

  defp stringify(value) when is_map(value) and not is_struct(value) do
    for {k, v} <- value, into: %{} do
      key = if is_atom(k), do: Atom.to_string(k), else: k
      {key, stringify(v)}
    end
  end

  defp stringify(value) when is_list(value), do: Enum.map(value, &stringify/1)
  defp stringify(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp stringify(value) when is_atom(value) and not is_nil(value) and not is_boolean(value),
    do: Atom.to_string(value)

  defp stringify(value), do: value
end
