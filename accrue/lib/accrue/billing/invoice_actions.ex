defmodule Accrue.Billing.InvoiceActions do
  @moduledoc """
  Invoice write surface.

  Exposes five user-path invoice actions on `Accrue.Billing` via a
  `defdelegate` facade: `finalize_invoice`, `void_invoice`,
  `pay_invoice`, `mark_uncollectible`, `send_invoice`, `add_invoice_item`,
  `remove_invoice_item`.

  Each action follows a consistent pattern: call the Stripe API, decompose
  the response into local schema changes via `InvoiceProjection`, write
  the updated invoice row and upsert its line items, and record an audit
  event — all in a single database transaction.

  `pay_invoice/2` returns an intent result (`{:ok, %Invoice{}}` or
  `{:ok, :requires_action, pi}`) because Stripe may surface SCA/3DS.
  The other four actions return plain `{:ok, %Invoice{}}`.
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

  @spec add_invoice_item(Invoice.t(), map(), keyword()) ::
          {:ok, Invoice.t()} | {:error, term()}
  def add_invoice_item(%Invoice{} = invoice, attrs, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    with :ok <- ensure_draft_invoice(invoice) do
      op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
      processor_opts = [idempotency_key: Idempotency.key(:invoice_item_create, invoice.id, op_id)] ++ sanitize_opts(opts)
      params = invoice_item_params(invoice, attrs)

      Repo.transact(fn ->
        with {:ok, created_item} <- Processor.invoice_item_create(params, processor_opts),
             {:ok, stripe_invoice} <-
               Processor.__impl__().retrieve_invoice(invoice.processor_id, sanitize_opts(opts)),
             {:ok, %{invoice_attrs: invoice_attrs, item_attrs: item_attrs_list}} <-
               InvoiceProjection.decompose(stripe_invoice),
             {:ok, updated} <- update_invoice_row(invoice, invoice_attrs),
             {:ok, _} <- sync_items(updated, item_attrs_list),
             {:ok, _event} <- record_event("invoice.item_added", updated, event_data(created_item)) do
          {:ok, Repo.preload(updated, :items, force: true)}
        end
      end)
    end
  end

  @spec add_invoice_item!(Invoice.t(), map(), keyword()) :: Invoice.t()
  def add_invoice_item!(invoice, attrs, opts \\ []),
    do: bang!(add_invoice_item(invoice, attrs, opts), "add_invoice_item!/3")

  @spec remove_invoice_item(Invoice.t(), InvoiceItem.t(), keyword()) ::
          {:ok, Invoice.t()} | {:error, term()}
  def remove_invoice_item(%Invoice{} = invoice, %InvoiceItem{} = item, opts \\ [])
      when is_list(opts) do
    with :ok <- ensure_draft_invoice(invoice) do
      op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
      processor_id = item.stripe_id || item.data["id"] || item.data[:id]

      Repo.transact(fn ->
        with true <-
               is_binary(processor_id) ||
                 {:error, draft_invoice_error(invoice, "invoice item must have a processor id")},
             {:ok, _deleted} <-
               Processor.invoice_item_delete(
                 processor_id,
                 %{},
                 [idempotency_key: Idempotency.key(:invoice_item_delete, item.id, op_id)] ++
                   sanitize_opts(opts)
               ),
             {:ok, stripe_invoice} <-
               Processor.__impl__().retrieve_invoice(invoice.processor_id, sanitize_opts(opts)),
             {:ok, %{invoice_attrs: invoice_attrs, item_attrs: item_attrs_list}} <-
               InvoiceProjection.decompose(stripe_invoice),
             {:ok, updated} <- update_invoice_row(invoice, invoice_attrs),
             {:ok, _} <- sync_items(updated, item_attrs_list),
             {:ok, _event} <- record_event("invoice.item_removed", updated, event_data(item)) do
          {:ok, Repo.preload(updated, :items, force: true)}
        end
      end)
    end
  end

  @spec remove_invoice_item!(Invoice.t(), InvoiceItem.t(), keyword()) :: Invoice.t()
  def remove_invoice_item!(invoice, item, opts \\ []),
    do: bang!(remove_invoice_item(invoice, item, opts), "remove_invoice_item!/3")

  defp bang!({:ok, %Invoice{} = v}, _), do: v
  defp bang!({:error, err}, _) when is_exception(err), do: raise(err)
  defp bang!({:error, other}, label), do: raise("#{label} failed: #{inspect(other)}")

  # ---------------------------------------------------------------------
  # workflow shape — one Repo.transact per user action
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
                 {:ok, _event} <- record_event(event_type, updated, %{}) do
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
    # reduce_while + non-bang variants so changeset errors propagate
    # into the enclosing Repo.transact with-chain.
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

  defp sync_items(%Invoice{} = invoice, item_attrs_list) when is_list(item_attrs_list) do
    import Ecto.Query, only: [from: 2]

    stripe_ids =
      item_attrs_list
      |> Enum.map(& &1[:stripe_id])
      |> Enum.filter(&is_binary/1)

    delete_query =
      case stripe_ids do
        [] ->
          from(i in InvoiceItem, where: i.invoice_id == ^invoice.id)

        _ ->
          from(i in InvoiceItem,
            where: i.invoice_id == ^invoice.id and (is_nil(i.stripe_id) or i.stripe_id not in ^stripe_ids)
          )
      end

    _ = Repo.repo().delete_all(delete_query)
    upsert_items(invoice, item_attrs_list)
  end

  defp record_event(type, %Invoice{} = inv, data) do
    Events.record(%{
      type: type,
      subject_type: "Invoice",
      subject_id: inv.id,
      data: Map.merge(%{source: "api"}, data)
    })
  end

  defp ensure_draft_invoice(%Invoice{status: :draft}), do: :ok
  defp ensure_draft_invoice(%Invoice{} = invoice), do: {:error, draft_invoice_error(invoice)}

  defp draft_invoice_error(%Invoice{} = invoice, message \\ "manual invoice items require a draft invoice") do
    invoice
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(:status, message)
  end

  defp invoice_item_params(%Invoice{} = invoice, attrs) do
    attrs
    |> Map.put(:customer, customer_processor_id(invoice))
    |> Map.put(:invoice, invoice.processor_id)
  end

  defp customer_processor_id(%Invoice{} = invoice) do
    invoice
    |> Repo.preload(:customer)
    |> Map.fetch!(:customer)
    |> Map.fetch!(:processor_id)
  end

  defp event_data(%InvoiceItem{} = item) do
    %{
      item_id: item.id,
      item_processor_id: item.stripe_id
    }
  end

  defp event_data(item) when is_map(item) do
    %{
      item_processor_id: item[:id] || item["id"]
    }
  end

  defp sanitize_opts(opts) do
    Keyword.drop(opts, [:operation_id])
  end

  defp tag({:ok, _}), do: :ok
  defp tag(_), do: :error
end
