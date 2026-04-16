defmodule Accrue.Billing.InvoiceActions do
  @moduledoc """
  Phase 3 Plan 05 invoice write surface (BILL-17/18/19).

  Exposes the five user-path invoice actions on `Accrue.Billing` via the
  Plan 01 `defdelegate` facade: `finalize_invoice`, `void_invoice`,
  `pay_invoice`, `mark_uncollectible`, `send_invoice`. Each follows the
  D3-18 one-shape `Repo.transact/2` pattern:

      telemetry.span
        |> Repo.transact (
             Processor.<op>(stripe_id, opts)
             |> InvoiceProjection.decompose/1
             |> update row via Invoice.changeset/2 (user path, enforces transitions)
             |> upsert child items by stripe_id
             |> Events.record/1 (same transaction — EVT-04)
           )
        |> IntentResult.wrap (pay_invoice only — may surface SCA)

  `pay_invoice/2` returns an `intent_result` tagged union because Stripe
  may surface SCA/3DS; the other four return plain `{:ok, %Invoice{}}`.
  Every action has a bang variant that raises on `{:error, _}`;
  `pay_invoice!/2` additionally raises `Accrue.ActionRequiredError` on
  `:requires_action`.

  The webhook path uses the force-status bypass on the Invoice schema —
  that bypass is NOT reachable from this module. Illegal user-path
  transitions (e.g. `draft -> paid`) are rejected by `Invoice.changeset/2`
  with an error on `:status` and propagate as
  `{:error, %Ecto.Changeset{}}`.
  """

  alias Accrue.Actor
  alias Accrue.Billing.IntentResult
  alias Accrue.Billing.Invoice
  alias Accrue.Billing.InvoiceItem
  alias Accrue.Billing.InvoiceProjection
  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Processor.Idempotency
  alias Accrue.Repo

  # ---------------------------------------------------------------------
  # public API
  # ---------------------------------------------------------------------

  @spec finalize_invoice(Invoice.t(), keyword()) ::
          {:ok, Invoice.t()} | {:error, term()}
  def finalize_invoice(%Invoice{} = inv, opts \\ []),
    do: run_action(inv, :finalize_invoice, "invoice.finalized", opts)

  @spec void_invoice(Invoice.t(), keyword()) ::
          {:ok, Invoice.t()} | {:error, term()}
  def void_invoice(%Invoice{} = inv, opts \\ []),
    do: run_action(inv, :void_invoice, "invoice.voided", opts)

  @spec mark_uncollectible(Invoice.t(), keyword()) ::
          {:ok, Invoice.t()} | {:error, term()}
  def mark_uncollectible(%Invoice{} = inv, opts \\ []),
    do: run_action(inv, :mark_uncollectible_invoice, "invoice.marked_uncollectible", opts)

  @spec send_invoice(Invoice.t(), keyword()) ::
          {:ok, Invoice.t()} | {:error, term()}
  def send_invoice(%Invoice{} = inv, opts \\ []),
    do: run_action(inv, :send_invoice, "invoice.sent", opts)

  @spec pay_invoice(Invoice.t(), keyword()) ::
          {:ok, Invoice.t()}
          | {:ok, :requires_action, map()}
          | {:error, term()}
  def pay_invoice(%Invoice{} = inv, opts \\ []) do
    result = run_action(inv, :pay_invoice, "invoice.paid", opts)
    IntentResult.wrap(result)
  end

  # --- bang variants ---

  @spec finalize_invoice!(Invoice.t(), keyword()) :: Invoice.t()
  def finalize_invoice!(inv, opts \\ []),
    do: bang!(finalize_invoice(inv, opts), "finalize_invoice!/2")

  @spec void_invoice!(Invoice.t(), keyword()) :: Invoice.t()
  def void_invoice!(inv, opts \\ []), do: bang!(void_invoice(inv, opts), "void_invoice!/2")

  @spec mark_uncollectible!(Invoice.t(), keyword()) :: Invoice.t()
  def mark_uncollectible!(inv, opts \\ []),
    do: bang!(mark_uncollectible(inv, opts), "mark_uncollectible!/2")

  @spec send_invoice!(Invoice.t(), keyword()) :: Invoice.t()
  def send_invoice!(inv, opts \\ []), do: bang!(send_invoice(inv, opts), "send_invoice!/2")

  @spec pay_invoice!(Invoice.t(), keyword()) :: Invoice.t()
  def pay_invoice!(inv, opts \\ []) do
    case pay_invoice(inv, opts) do
      {:ok, %Invoice{} = v} ->
        v

      {:ok, :requires_action, pi} ->
        raise Accrue.ActionRequiredError, payment_intent: pi

      {:error, err} when is_exception(err) ->
        raise err

      {:error, other} ->
        raise "pay_invoice!/2 failed: #{inspect(other)}"
    end
  end

  defp bang!({:ok, %Invoice{} = v}, _), do: v
  defp bang!({:error, err}, _) when is_exception(err), do: raise(err)
  defp bang!({:error, other}, label), do: raise("#{label} failed: #{inspect(other)}")

  # ---------------------------------------------------------------------
  # workflow shape (D3-18) — one Repo.transact per user action
  # ---------------------------------------------------------------------

  defp run_action(%Invoice{} = inv, processor_fn, event_type, opts) do
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(processor_fn, inv.id, op_id)
    stripe_opts = [idempotency_key: idem_key] ++ sanitize_opts(opts)

    :telemetry.span(
      [:accrue, :billing, :invoice, processor_fn],
      %{invoice_id: inv.id, processor_id: inv.processor_id},
      fn ->
        result =
          Repo.transact(fn ->
            with {:ok, stripe_inv} <-
                   apply(Processor.__impl__(), processor_fn, [inv.processor_id, stripe_opts]),
                 {:ok, %{invoice_attrs: attrs, item_attrs: item_attrs_list}} <-
                   InvoiceProjection.decompose(stripe_inv),
                 {:ok, updated} <- update_invoice_row(inv, attrs),
                 {:ok, _} <- upsert_items(updated, item_attrs_list),
                 {:ok, _event} <- record_event(event_type, updated) do
              {:ok, Repo.preload(updated, :items, force: true)}
            end
          end)

        {result, %{result: tag(result)}}
      end
    )
  end

  defp update_invoice_row(%Invoice{} = inv, attrs) do
    inv
    |> Invoice.changeset(attrs)
    |> Repo.update()
  end

  defp upsert_items(%Invoice{} = invoice, item_attrs_list) when is_list(item_attrs_list) do
    # WR-09: reduce_while + non-bang variants so changeset errors
    # propagate into the enclosing Repo.transact with-chain.
    Enum.reduce_while(item_attrs_list, {:ok, []}, fn attrs, {:ok, acc} ->
      attrs = Map.put(attrs, :invoice_id, invoice.id)

      case upsert_item(attrs) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp upsert_item(%{stripe_id: nil} = attrs) do
    %InvoiceItem{}
    |> InvoiceItem.changeset(attrs)
    |> Repo.insert()
  end

  defp upsert_item(%{stripe_id: sid} = attrs) when is_binary(sid) do
    case Repo.one(from_query(sid)) do
      nil ->
        %InvoiceItem{}
        |> InvoiceItem.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> InvoiceItem.changeset(attrs)
        |> Repo.update()
    end
  end

  defp from_query(stripe_id) do
    import Ecto.Query, only: [from: 2]
    from(i in InvoiceItem, where: i.stripe_id == ^stripe_id)
  end

  defp record_event(type, %Invoice{} = inv) do
    Events.record(%{
      type: type,
      subject_type: "Invoice",
      subject_id: inv.id,
      data: %{source: "api"}
    })
  end

  defp sanitize_opts(opts) do
    Keyword.drop(opts, [:operation_id])
  end

  defp tag({:ok, _}), do: :ok
  defp tag(_), do: :error
end
