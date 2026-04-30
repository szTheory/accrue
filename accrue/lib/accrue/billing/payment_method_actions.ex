defmodule Accrue.Billing.PaymentMethodActions do
  @moduledoc """
  Payment method orchestration.

  Canonical CRUD verbs are projection-first:

    * `add_payment_method/3`
    * `update_payment_method/3`
    * `delete_payment_method/2`
    * `set_default_payment_method/3`
    * `list_payment_methods/2`
    * `sync_payment_methods/2`

  Legacy `attach_payment_method/3` and `detach_payment_method/2` stay in place
  as compatibility wrappers for the existing Stripe/Fake semantics.
  """

  import Ecto.Query, only: [from: 2]

  alias Accrue.Actor
  alias Accrue.APIError
  alias Accrue.Billing.{Customer, PaymentMethod, Subscription}
  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Processor.Idempotency
  alias Accrue.Repo

  @list_payment_methods_opts_schema [
    type: [type: {:or, [:string, nil]}, default: nil],
    limit: [type: {:or, [:pos_integer, nil]}, default: nil],
    starting_after: [type: {:or, [:string, nil]}, default: nil],
    ending_before: [type: {:or, [:string, nil]}, default: nil],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @list_payment_method_param_keys [:type, :limit, :starting_after, :ending_before]

  @spec add_payment_method(Customer.t(), map() | String.t(), keyword()) ::
          {:ok, PaymentMethod.t()} | {:error, term()}
  def add_payment_method(customer, attrs_or_id, opts \\ [])

  def add_payment_method(%Customer{} = customer, pm_processor_id, opts)
      when is_binary(pm_processor_id) do
    attach_payment_method(customer, pm_processor_id, opts)
  end

  def add_payment_method(%Customer{} = customer, attrs, opts)
      when is_map(attrs) and is_list(opts) do
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:add_payment_method, customer.id, op_id)

    params =
      attrs
      |> stringify_keys()
      |> Map.put("customer", customer.processor_id)

    with :ok <- validate_add_params(params),
         {:ok, created} <-
           Processor.__impl__().create_payment_method(
             params,
             [idempotency_key: idem_key] ++ sanitize_opts(opts)
           ),
         {:ok, _synced} <- sync_payment_methods(customer, opts),
         {:ok, payment_method} <- get_payment_method(customer.id, get_field(created, :id)),
         {:ok, _} <-
           record_event("payment_method.added", payment_method, %{
             processor_id: payment_method.processor_id
           }) do
      {:ok, payment_method}
    end
  end

  @spec add_payment_method!(Customer.t(), map() | String.t(), keyword()) :: PaymentMethod.t()
  def add_payment_method!(%Customer{} = customer, attrs, opts \\ []) do
    case add_payment_method(customer, attrs, opts) do
      {:ok, payment_method} -> payment_method
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "add_payment_method!/3 failed: #{inspect(other)}"
    end
  end

  @spec update_payment_method(PaymentMethod.t(), map(), keyword()) ::
          {:ok, PaymentMethod.t()} | {:error, term()}
  def update_payment_method(%PaymentMethod{} = payment_method, attrs, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    customer = Repo.get!(Customer, payment_method.customer_id)
    make_default? = Map.get(attrs, :make_default, Map.get(attrs, "make_default", false))
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:update_payment_method, payment_method.id, op_id)

    params =
      attrs
      |> stringify_keys()
      |> Map.put_new("customer", customer.processor_id)

    with {:ok, updated} <-
           Processor.__impl__().update_payment_method(
             payment_method.processor_id,
             params,
             [idempotency_key: idem_key] ++ sanitize_opts(opts)
           ),
         {:ok, _synced} <- sync_payment_methods(customer, opts),
         refreshed_customer = Repo.get!(Customer, customer.id),
         {:ok, replacement} <- get_payment_method(customer.id, get_field(updated, :id)),
         {:ok, _customer} <- maybe_set_default(refreshed_customer, replacement, make_default?),
         {:ok, _} <-
           record_event("payment_method.updated", replacement, %{
             replaced_payment_method_id: payment_method.id
           }) do
      {:ok, replacement}
    end
  end

  @spec update_payment_method!(PaymentMethod.t(), map(), keyword()) :: PaymentMethod.t()
  def update_payment_method!(%PaymentMethod{} = payment_method, attrs, opts \\ []) do
    case update_payment_method(payment_method, attrs, opts) do
      {:ok, replacement} -> replacement
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "update_payment_method!/3 failed: #{inspect(other)}"
    end
  end

  @spec delete_payment_method(PaymentMethod.t(), keyword()) ::
          {:ok, PaymentMethod.t()} | {:error, term()}
  def delete_payment_method(%PaymentMethod{} = payment_method, opts \\ []) do
    customer = Repo.get!(Customer, payment_method.customer_id)

    with :ok <- ensure_delete_allowed(customer, payment_method),
         {:ok, _} <-
           Processor.__impl__().detach_payment_method(
             payment_method.processor_id,
             sanitize_opts(opts)
           ),
         {:ok, _synced} <- sync_payment_methods(customer, opts),
         {:ok, _} <-
           record_event("payment_method.deleted", payment_method, %{
             processor_id: payment_method.processor_id
           }) do
      {:ok, payment_method}
    end
  end

  @spec delete_payment_method!(PaymentMethod.t(), keyword()) :: PaymentMethod.t()
  def delete_payment_method!(%PaymentMethod{} = payment_method, opts \\ []) do
    case delete_payment_method(payment_method, opts) do
      {:ok, payment_method} -> payment_method
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "delete_payment_method!/2 failed: #{inspect(other)}"
    end
  end

  @spec sync_payment_methods(Customer.t(), keyword()) ::
          {:ok, [PaymentMethod.t()]} | {:error, term()}
  def sync_payment_methods(%Customer{} = customer, opts \\ []) when is_list(opts) do
    if Processor.supports?([:payment_method, :list]) do
      params = list_params_for_processor(customer, opts)

      with {:ok, remote} <-
             Processor.__impl__().list_payment_methods(params, sanitize_opts(opts)),
           {:ok, payment_methods} <- reproject_payment_methods(customer, remote_payment_methods(remote)) do
        {:ok, payment_methods}
      end
    else
      list_payment_methods(customer, opts)
    end
  end

  @spec sync_payment_methods!(Customer.t(), keyword()) :: [PaymentMethod.t()]
  def sync_payment_methods!(%Customer{} = customer, opts \\ []) when is_list(opts) do
    case sync_payment_methods(customer, opts) do
      {:ok, payment_methods} -> payment_methods
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "sync_payment_methods!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # Compatibility wrappers
  # ---------------------------------------------------------------------

  @spec attach_payment_method(Customer.t(), String.t(), keyword()) ::
          {:ok, PaymentMethod.t()} | {:error, term()}
  def attach_payment_method(%Customer{} = customer, pm_processor_id, opts \\ [])
      when is_binary(pm_processor_id) do
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:attach_payment_method, customer.id, op_id)
    sanitized_opts = sanitize_opts(opts)

    Repo.transact(fn ->
      with {:ok, canonical} <-
             Processor.__impl__().retrieve_payment_method(pm_processor_id, sanitized_opts),
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

  @spec attach_payment_method!(Customer.t(), String.t(), keyword()) :: PaymentMethod.t()
  def attach_payment_method!(%Customer{} = customer, pm_processor_id, opts \\ []) do
    case attach_payment_method(customer, pm_processor_id, opts) do
      {:ok, pm} -> pm
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "attach_payment_method!/3 failed: #{inspect(other)}"
    end
  end

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
            {:ok, _} =
              Processor.__impl__().detach_payment_method(pm_processor_id, sanitize_opts(opts))

            winner =
              Repo.get_by!(PaymentMethod,
                customer_id: customer.id,
                fingerprint: fingerprint
              )

            {:ok, %{winner | existing?: true}}
        end

      %PaymentMethod{} = existing ->
        {:ok, _} =
          Processor.__impl__().detach_payment_method(pm_processor_id, sanitize_opts(opts))

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

  @spec detach_payment_method(PaymentMethod.t(), keyword()) ::
          {:ok, PaymentMethod.t()} | {:error, term()}
  def detach_payment_method(%PaymentMethod{} = payment_method, opts \\ []) do
    Repo.transact(fn ->
      with {:ok, _} <-
             Processor.__impl__().detach_payment_method(
               payment_method.processor_id,
               sanitize_opts(opts)
             ),
           {:ok, _} <- Repo.delete(payment_method),
           {:ok, _} <-
             record_event("payment_method.detached", payment_method, %{
               processor_id: payment_method.processor_id
             }) do
        {:ok, payment_method}
      end
    end)
  end

  @spec detach_payment_method!(PaymentMethod.t(), keyword()) :: PaymentMethod.t()
  def detach_payment_method!(payment_method, opts \\ []) do
    case detach_payment_method(payment_method, opts) do
      {:ok, payment_method} -> payment_method
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "detach_payment_method!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # Shared helpers
  # ---------------------------------------------------------------------

  @spec set_default_payment_method(Customer.t(), PaymentMethod.t(), keyword()) ::
          {:ok, Customer.t()} | {:error, term()}
  def set_default_payment_method(%Customer{} = customer, %PaymentMethod{} = payment_method, opts \\ []) do
    unless payment_method.customer_id == customer.id do
      raise Accrue.Error.NotAttached,
        customer_id: customer.id,
        payment_method_id: payment_method.id,
        message:
          "Accrue.Billing.set_default_payment_method/2 refused to wire " <>
            "payment_method #{inspect(payment_method.id)} as the default for " <>
            "customer #{inspect(customer.id)} because the PM is attached " <>
            "to a different customer. Call attach_payment_method/2 first."
    end

    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:set_default_payment_method, customer.id, op_id)

    Repo.transact(fn ->
      with {:ok, _} <-
             Processor.__impl__().set_default_payment_method(
               customer.processor_id,
               %{invoice_settings: %{default_payment_method: payment_method.processor_id}},
               [idempotency_key: idem_key] ++ sanitize_opts(opts)
             ),
           {:ok, updated} <- update_customer_default(customer, payment_method.id),
           {:ok, _} <-
             record_event("customer.default_payment_method_changed", updated, %{
               payment_method_id: payment_method.id
             }) do
        {:ok, updated}
      end
    end)
  end

  @spec set_default_payment_method!(Customer.t(), PaymentMethod.t(), keyword()) :: Customer.t()
  def set_default_payment_method!(customer, payment_method, opts \\ []) do
    case set_default_payment_method(customer, payment_method, opts) do
      {:ok, customer} -> customer
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "set_default_payment_method!/3 failed: #{inspect(other)}"
    end
  end

  @spec list_payment_methods(Customer.t(), keyword()) ::
          {:ok, [PaymentMethod.t()]} | {:error, term()}
  def list_payment_methods(%Customer{} = customer, opts \\ []) when is_list(opts) do
    NimbleOptions.validate!(opts, @list_payment_methods_opts_schema)
    {:ok, local_payment_methods(customer)}
  end

  @spec list_payment_methods!(Customer.t(), keyword()) :: [PaymentMethod.t()]
  def list_payment_methods!(%Customer{} = customer, opts \\ []) when is_list(opts) do
    {:ok, payment_methods} = list_payment_methods(customer, opts)
    payment_methods
  end

  defp reproject_payment_methods(%Customer{} = customer, remote_payment_methods) do
    Repo.transact(fn ->
      existing =
        Repo.all(from p in PaymentMethod, where: p.customer_id == ^customer.id)

      existing_by_processor_id = Map.new(existing, &{&1.processor_id, &1})
      remote_ids = MapSet.new(Enum.map(remote_payment_methods, &get_field(&1, :id)))

      synced_rows =
        Enum.map(remote_payment_methods, fn remote_payment_method ->
          attrs = payment_method_attrs(customer, remote_payment_method)
          processor_id = attrs.processor_id

          case Map.get(existing_by_processor_id, processor_id) do
            nil ->
              %PaymentMethod{}
              |> PaymentMethod.changeset(attrs)
              |> Repo.insert!()

            %PaymentMethod{} = existing_row ->
              existing_row
              |> PaymentMethod.changeset(attrs)
              |> Repo.update!()
          end
        end)

      Enum.each(existing, fn existing_row ->
        unless MapSet.member?(remote_ids, existing_row.processor_id) do
          {:ok, _deleted_row} = Repo.delete(existing_row)
        end
      end)

      default_processor_id =
        Enum.find_value(remote_payment_methods, fn remote_payment_method ->
          if truthy?(get_field(remote_payment_method, :default)),
            do: get_field(remote_payment_method, :id)
        end)

      default_row =
        Enum.find(synced_rows, fn row ->
          row.processor_id == default_processor_id
        end)

      Enum.each(synced_rows, fn row ->
        row
        |> PaymentMethod.changeset(%{is_default: default_row != nil and row.id == default_row.id})
        |> Repo.update!()
      end)

      _updated_customer =
        customer
        |> Customer.changeset(%{default_payment_method_id: default_row && default_row.id})
        |> Repo.update!()

      {:ok, local_payment_methods(customer)}
    end)
  end

  defp payment_method_attrs(customer, remote_payment_method) do
    card = get_field(remote_payment_method, :card) || %{}

    %{
      customer_id: customer.id,
      processor: processor_name(),
      processor_id: get_field(remote_payment_method, :id),
      type: normalize_type(get_field(remote_payment_method, :type)),
      is_default: truthy?(get_field(remote_payment_method, :default)),
      fingerprint: get_field(card, :fingerprint),
      card_brand: get_field(card, :brand),
      card_last4: get_field(card, :last4),
      card_exp_month: integer_field(card, :exp_month),
      card_exp_year: integer_field(card, :exp_year),
      exp_month: integer_field(card, :exp_month),
      exp_year: integer_field(card, :exp_year),
      metadata: get_field(remote_payment_method, :metadata) || %{},
      data: stringify(remote_payment_method)
    }
  end

  defp maybe_set_default(customer, payment_method, true), do: update_customer_default(customer, payment_method.id)
  defp maybe_set_default(customer, _payment_method, false), do: {:ok, customer}

  defp ensure_delete_allowed(customer, payment_method) do
    cond do
      active_braintree_subscription_uses?(customer, payment_method) ->
        {:error,
         %APIError{
           code: "payment_method_still_in_use",
           http_status: 409,
           message: "payment method is still funding an active subscription"
         }}

      customer.default_payment_method_id == payment_method.id and has_other_usable_methods?(customer, payment_method) ->
        {:error,
         %APIError{
           code: "payment_method_replacement_required",
           http_status: 409,
           message: "default payment method replacement is required before deletion"
         }}

      true ->
        :ok
    end
  end

  defp active_braintree_subscription_uses?(customer, payment_method) do
    customer.id
    |> active_braintree_subscriptions()
    |> Enum.any?(fn subscription ->
      get_in(subscription.data, ["payment_method_token"]) == payment_method.processor_id
    end)
  end

  defp active_braintree_subscriptions(customer_id) do
    Repo.all(
      from s in Subscription,
        where: s.customer_id == ^customer_id and s.processor == "braintree"
    )
    |> Enum.filter(&Subscription.active?/1)
  end

  defp has_other_usable_methods?(customer, payment_method) do
    customer
    |> local_payment_methods()
    |> Enum.reject(&(&1.id == payment_method.id))
    |> Enum.any?()
  end

  defp local_payment_methods(%Customer{} = customer) do
    payment_methods =
      Repo.all(
        from p in PaymentMethod,
          where: p.customer_id == ^customer.id,
          order_by: [asc: p.inserted_at]
      )

    Enum.sort_by(payment_methods, fn payment_method ->
      {payment_method.id != customer.default_payment_method_id, payment_method.inserted_at}
    end)
  end

  defp update_customer_default(customer, payment_method_id) do
    customer
    |> Customer.changeset(%{default_payment_method_id: payment_method_id})
    |> Repo.update()
  end

  defp get_payment_method(customer_id, processor_id) when is_binary(processor_id) do
    case Repo.get_by(PaymentMethod, customer_id: customer_id, processor_id: processor_id) do
      %PaymentMethod{} = payment_method -> {:ok, payment_method}
      nil -> {:error, invalid_request("payment-method sync did not project processor row #{processor_id}")}
    end
  end

  defp get_payment_method(_customer_id, _processor_id),
    do: {:error, invalid_request("processor response did not include a payment-method id")}

  defp validate_add_params(params) do
    if processor_name() == "braintree" do
      case get_in(params, ["vault_acquisition", "reference"]) do
        reference when is_binary(reference) and reference != "" ->
          :ok

        _ ->
          {:error, invalid_request("Braintree add_payment_method requires vault_acquisition.reference")}
      end
    else
      :ok
    end
  end

  defp remote_payment_methods(%{data: payment_methods}) when is_list(payment_methods), do: payment_methods
  defp remote_payment_methods(payment_methods) when is_list(payment_methods), do: payment_methods
  defp remote_payment_methods(_), do: []

  defp list_params_for_processor(%Customer{} = customer, opts) when is_list(opts) do
    opts
    |> Keyword.take(@list_payment_method_param_keys)
    |> Enum.reduce(%{customer: customer.processor_id}, fn
      {_k, nil}, acc -> acc
      {k, v}, acc -> Map.put(acc, k, v)
    end)
  end

  defp get_card_fingerprint(canonical) do
    case get_field(canonical, :card) do
      %{} = card -> get_field(card, :fingerprint)
      _ -> nil
    end
  end

  defp integer_field(map, key) do
    case get_field(map, key) do
      value when is_integer(value) -> value
      value when is_binary(value) -> String.to_integer(value)
      _ -> nil
    end
  rescue
    ArgumentError -> nil
  end

  defp truthy?(value), do: value in [true, "true", 1, "1"]

  defp normalize_type(atom) when is_atom(atom) and not is_nil(atom), do: Atom.to_string(atom)
  defp normalize_type(str) when is_binary(str), do: str
  defp normalize_type(_), do: nil

  defp record_event(type, %PaymentMethod{} = payment_method, data) do
    Events.record(%{
      type: type,
      subject_type: "PaymentMethod",
      subject_id: payment_method.id,
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

  defp invalid_request(message) do
    %APIError{
      code: "invalid_request_error",
      http_status: 400,
      message: message
    }
  end

  defp get_field(%{} = map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp get_field(_, _), do: nil

  defp processor_name do
    Processor.name()
  end

  defp sanitize_opts(opts), do: Keyword.drop(opts, [:operation_id])

  defp stringify_keys(value) when is_map(value) and not is_struct(value) do
    for {key, nested_value} <- value, into: %{} do
      rendered_key = if is_atom(key), do: Atom.to_string(key), else: key
      {rendered_key, stringify_keys(nested_value)}
    end
  end

  defp stringify_keys(value) when is_list(value), do: Enum.map(value, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp stringify(value) when is_map(value) and not is_struct(value) do
    for {key, nested_value} <- value, into: %{} do
      rendered_key = if is_atom(key), do: Atom.to_string(key), else: key
      {rendered_key, stringify(nested_value)}
    end
  end

  defp stringify(value) when is_list(value), do: Enum.map(value, &stringify/1)
  defp stringify(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp stringify(value) when is_atom(value) and not is_nil(value), do: Atom.to_string(value)
  defp stringify(%_{} = struct), do: struct |> Map.from_struct() |> stringify()
  defp stringify(value), do: value
end
