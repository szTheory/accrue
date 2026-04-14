defmodule Accrue.Billing.PaymentMethodActions do
  @moduledoc """
  Phase 3 Plan 06 payment method write surface (BILL-23, BILL-25).

  Ships three public entry points, all exposed via `defdelegate` on
  `Accrue.Billing`:

    * `attach_payment_method/3` — attaches a processor-side payment
      method to a customer, with **fingerprint dedup** (BILL-23). If an
      existing PaymentMethod row for the same `(customer_id, fingerprint)`
      exists, the processor-side duplicate is detached and the existing
      row is returned with `existing?: true`. A concurrent race that
      slips past the application-level check hits the
      `accrue_payment_methods_customer_fingerprint_idx` partial unique
      index and is rescued via `Ecto.ConstraintError`.
    * `detach_payment_method/2` — detaches on the processor and deletes
      the local row.
    * `set_default_payment_method/3` — asserts `pm.customer_id ==
      customer.id` (BILL-25, strict attachment check) and raises
      `Accrue.Error.NotAttached` otherwise. Never silently wires a
      foreign PM as a customer default.
  """

  import Ecto.Query, only: [from: 2]

  alias Accrue.Actor
  alias Accrue.Billing.{Customer, PaymentMethod}
  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Processor.Idempotency
  alias Accrue.Repo

  # ---------------------------------------------------------------------
  # attach_payment_method/3 (BILL-23)
  # ---------------------------------------------------------------------

  @doc """
  Attaches a processor-side payment method to a customer with fingerprint
  dedup (BILL-23). Returns `{:ok, %PaymentMethod{}}`; the
  `existing?: true` virtual flag is set when dedup hit an existing row.
  """
  @spec attach_payment_method(Customer.t(), String.t(), keyword()) ::
          {:ok, PaymentMethod.t()} | {:error, term()}
  def attach_payment_method(%Customer{} = customer, pm_processor_id, opts \\ [])
      when is_binary(pm_processor_id) do
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:attach_payment_method, customer.id, op_id)

    Repo.transact(fn ->
      with {:ok, canonical} <- Processor.__impl__().retrieve_payment_method(pm_processor_id, []),
           fingerprint = get_card_fingerprint(canonical),
           {:ok, pm} <-
             dedup_or_attach(customer, canonical, fingerprint, pm_processor_id, idem_key, opts),
           {:ok, _} <-
             record_event("payment_method.attached", pm, %{
               deduped: pm.existing? == true,
               fingerprint: fingerprint
             }) do
        {:ok, pm}
      end
    end)
  end

  @doc "Raising variant of `attach_payment_method/3`."
  @spec attach_payment_method!(Customer.t(), String.t(), keyword()) :: PaymentMethod.t()
  def attach_payment_method!(%Customer{} = customer, pm_processor_id, opts \\ []) do
    case attach_payment_method(customer, pm_processor_id, opts) do
      {:ok, pm} -> pm
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "attach_payment_method!/3 failed: #{inspect(other)}"
    end
  end

  # nil fingerprint: always fresh insert (cannot dedup without a key)
  defp dedup_or_attach(customer, _canonical, nil, pm_processor_id, idem_key, opts) do
    attach_and_insert(customer, pm_processor_id, idem_key, opts)
  end

  defp dedup_or_attach(customer, _canonical, fingerprint, pm_processor_id, idem_key, opts)
       when is_binary(fingerprint) do
    existing =
      Repo.one(
        from(p in PaymentMethod,
          where: p.customer_id == ^customer.id and p.fingerprint == ^fingerprint
        )
      )

    case existing do
      nil ->
        try do
          attach_and_insert(customer, pm_processor_id, idem_key, opts)
        rescue
          Ecto.ConstraintError ->
            # Race: another process inserted concurrently between our
            # SELECT and INSERT. Detach the loser's Stripe PM and return
            # the winner's row.
            {:ok, _} = Processor.__impl__().detach_payment_method(pm_processor_id, [])

            winner =
              Repo.get_by!(PaymentMethod,
                customer_id: customer.id,
                fingerprint: fingerprint
              )

            {:ok, %{winner | existing?: true}}
        end

      %PaymentMethod{} = existing ->
        # Dupe found at application level: detach the new Stripe PM.
        {:ok, _} = Processor.__impl__().detach_payment_method(pm_processor_id, [])
        {:ok, %{existing | existing?: true}}
    end
  end

  defp attach_and_insert(customer, pm_processor_id, idem_key, opts) do
    with {:ok, attached} <-
           Processor.__impl__().attach_payment_method(
             pm_processor_id,
             %{customer: customer.processor_id},
             [idempotency_key: idem_key] ++ sanitize_opts(opts)
           ) do
      card = get_field(attached, :card) || %{}

      attrs = %{
        customer_id: customer.id,
        processor: processor_name(),
        processor_id: get_field(attached, :id),
        type: normalize_type(get_field(attached, :type)),
        fingerprint: get_field(card, :fingerprint),
        card_brand: get_field(card, :brand),
        card_last4: get_field(card, :last4),
        card_exp_month: get_field(card, :exp_month),
        card_exp_year: get_field(card, :exp_year),
        exp_month: get_field(card, :exp_month),
        exp_year: get_field(card, :exp_year),
        data: stringify(attached),
        metadata: get_field(attached, :metadata) || %{}
      }

      %PaymentMethod{}
      |> PaymentMethod.changeset(attrs)
      |> Repo.insert()
    end
  end

  # ---------------------------------------------------------------------
  # detach_payment_method/2
  # ---------------------------------------------------------------------

  @doc """
  Detaches a payment method from its customer on the processor and
  deletes the local row in the same transaction.
  """
  @spec detach_payment_method(PaymentMethod.t(), keyword()) ::
          {:ok, PaymentMethod.t()} | {:error, term()}
  def detach_payment_method(%PaymentMethod{} = pm, _opts \\ []) do
    Repo.transact(fn ->
      with {:ok, _} <- Processor.__impl__().detach_payment_method(pm.processor_id, []),
           {:ok, _} <- Repo.delete(pm),
           {:ok, _} <-
             record_event("payment_method.detached", pm, %{
               processor_id: pm.processor_id
             }) do
        {:ok, pm}
      end
    end)
  end

  @doc "Raising variant of `detach_payment_method/2`."
  @spec detach_payment_method!(PaymentMethod.t(), keyword()) :: PaymentMethod.t()
  def detach_payment_method!(pm, opts \\ []) do
    case detach_payment_method(pm, opts) do
      {:ok, pm} -> pm
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "detach_payment_method!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # set_default_payment_method/3 (BILL-25)
  # ---------------------------------------------------------------------

  @doc """
  Sets a payment method as the customer's default. Raises
  `Accrue.Error.NotAttached` if `pm.customer_id != customer.id` (BILL-25
  strict attachment check — never silently wires a foreign PM as
  default).
  """
  @spec set_default_payment_method(Customer.t(), PaymentMethod.t(), keyword()) ::
          {:ok, Customer.t()} | {:error, term()}
  def set_default_payment_method(%Customer{} = customer, %PaymentMethod{} = pm, opts \\ []) do
    unless pm.customer_id == customer.id do
      raise Accrue.Error.NotAttached,
        customer_id: customer.id,
        payment_method_id: pm.id,
        message:
          "Accrue.Billing.set_default_payment_method/2 refused to wire " <>
            "payment_method #{inspect(pm.id)} as the default for " <>
            "customer #{inspect(customer.id)} because the PM is attached " <>
            "to a different customer. Call attach_payment_method/2 first."
    end

    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:set_default_payment_method, customer.id, op_id)

    Repo.transact(fn ->
      with {:ok, _} <-
             Processor.__impl__().set_default_payment_method(
               customer.processor_id,
               %{invoice_settings: %{default_payment_method: pm.processor_id}},
               [idempotency_key: idem_key] ++ sanitize_opts(opts)
             ),
           {:ok, updated} <-
             customer
             |> Customer.changeset(%{default_payment_method_id: pm.id})
             |> Repo.update(),
           {:ok, _} <-
             record_event("customer.default_payment_method_changed", updated, %{
               payment_method_id: pm.id
             }) do
        {:ok, updated}
      end
    end)
  end

  @doc "Raising variant of `set_default_payment_method/3`."
  @spec set_default_payment_method!(Customer.t(), PaymentMethod.t(), keyword()) :: Customer.t()
  def set_default_payment_method!(customer, pm, opts \\ []) do
    case set_default_payment_method(customer, pm, opts) do
      {:ok, c} -> c
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "set_default_payment_method!/3 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------

  defp get_card_fingerprint(canonical) do
    case get_field(canonical, :card) do
      %{} = card -> get_field(card, :fingerprint)
      _ -> nil
    end
  end

  defp normalize_type(atom) when is_atom(atom) and not is_nil(atom), do: Atom.to_string(atom)
  defp normalize_type(str) when is_binary(str), do: str
  defp normalize_type(_), do: nil

  defp record_event(type, %PaymentMethod{} = pm, data) do
    Events.record(%{
      type: type,
      subject_type: "PaymentMethod",
      subject_id: pm.id,
      data: data
    })
  end

  defp record_event(type, %Customer{} = customer, data) do
    Events.record(%{
      type: type,
      subject_type: "Customer",
      subject_id: customer.id,
      data: data
    })
  end

  defp get_field(%{} = m, key) when is_atom(key) do
    Map.get(m, key) || Map.get(m, Atom.to_string(key))
  end

  defp get_field(_, _), do: nil

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp sanitize_opts(opts), do: Keyword.drop(opts, [:operation_id])

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
