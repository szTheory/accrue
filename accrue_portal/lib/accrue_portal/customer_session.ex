defmodule Accrue.Portal.CustomerSession do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Processor
  alias Accrue.Repo

  @spec resolve(map(), keyword()) :: {:ok, Accrue.Portal.Context.t()} | {:error, term()}
  def resolve(session, opts \\ []) when is_map(session) and is_list(opts) do
    create? = Keyword.get(opts, :create?, true)

    case Accrue.Auth.current_user(session) do
      nil ->
        {:error, :unauthenticated}

      %{__struct__: _mod, id: _id} = actor ->
        case context_adapter(session, opts) do
          nil -> resolve_personal(actor, create?)
          adapter -> resolve_custom(actor, adapter, session, create?, opts)
        end

      _actor ->
        {:error, :unavailable}
    end
  end

  @doc "Re-resolves a signed form locator against the current actor and host policy."
  def resolve_pin(session, pin, opts \\ [])

  def resolve_pin(session, pin, opts) when is_map(session) and is_list(opts) do
    endpoint = Keyword.get(opts, :endpoint)

    with actor when is_map(actor) <- Accrue.Auth.current_user(session),
         {:ok, identity} <- Accrue.Portal.Context.verify_pin(pin, endpoint),
         {:ok, context} <- resolve_pinned_context(actor, identity, session, opts),
         true <- context.customer.id |> to_string() == identity["customer_id"] do
      {:ok, context}
    else
      {:error, reason} when reason in [:forbidden, :unauthenticated] -> {:error, reason}
      _ -> {:error, :unavailable}
    end
  end

  def resolve_pin(_, _, _), do: {:error, :unavailable}

  defp resolve_personal(actor, create?) do
    with {:ok, owner_type, owner_id} <- Accrue.Portal.Context.owner_identity(actor),
         customers <- find_personal_customers(owner_type, owner_id) do
      case customers do
        [%Customer{} = customer] ->
          Accrue.Portal.Context.personal(actor, customer)

        [] when create? ->
          with {:ok, %Customer{} = customer} <- Billing.create_customer(actor),
               true <-
                 customer.owner_type == owner_type and customer.owner_id == owner_id and
                   is_binary(customer.processor) and customer.processor != "" do
            Accrue.Portal.Context.personal(actor, customer)
          else
            {:error, reason} -> {:error, reason}
            _ -> {:error, :unavailable}
          end

        [] ->
          {:error, :customer_not_found}

        _multiple ->
          {:error, :unavailable}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_pinned_context(actor, identity, session, opts) do
    case context_adapter(session, opts) do
      nil ->
        with {:ok, owner_type, owner_id} <- Accrue.Portal.Context.owner_identity(actor),
             true <- owner_type == identity["owner_type"] and owner_id == identity["owner_id"],
             %Customer{} = customer <- find_customer_by_id(identity["customer_id"]),
             true <- exact_customer_identity?(customer, identity),
             {:ok, context} <- Accrue.Portal.Context.personal(actor, customer) do
          {:ok, context}
        else
          _ -> {:error, :unavailable}
        end

      adapter ->
        portal = Map.get(session, "accrue_portal", %{})
        mount_path = Keyword.get(opts, :mount_path, Map.get(portal, "mount_path"))

        selection = %{
          source: :pin,
          values: %{
            "owner_type" => identity["owner_type"],
            "owner_id" => identity["owner_id"]
          }
        }

        with {:ok, context} <-
               Accrue.Portal.Context.resolve(actor, adapter, selection, mount_path),
             true <-
               context.owner_type == identity["owner_type"] and
                 context.owner_id == identity["owner_id"] and
                 context.processor == identity["processor"] and
                 context.processor == Processor.name(),
             %Customer{} = customer <- find_customer_by_id(identity["customer_id"]),
             true <- exact_customer_identity?(customer, identity) do
          {:ok, Accrue.Portal.Context.with_customer(context, customer)}
        else
          {:error, reason} -> {:error, reason}
          _ -> {:error, :unavailable}
        end
    end
  end

  defp resolve_custom(actor, adapter, session, create?, opts) do
    portal = Map.get(session, "accrue_portal", %{})
    session_keys = Keyword.get(opts, :session_keys, Map.get(portal, "context_session_keys", []))
    values = Map.take(session, session_keys)
    selection = %{source: :session, values: values}

    mount_path =
      Keyword.get(
        opts,
        :mount_path,
        Map.get(portal, "mount_path", Accrue.Config.portal_mount_path())
      )

    with {:ok, context} <- Accrue.Portal.Context.resolve(actor, adapter, selection, mount_path),
         {:ok, customer} <- resolve_custom_customer(context, create?) do
      {:ok, Accrue.Portal.Context.with_customer(context, customer)}
    end
  end

  defp resolve_custom_customer(context, create?) do
    case find_customer(context.owner_type, context.owner_id) do
      %Customer{} = customer ->
        {:ok, customer}

      nil when not create? ->
        {:error, :customer_not_found}

      nil ->
        case Billing.create_customer(context.billable) do
          {:ok, %Customer{} = customer} ->
            if exact_customer?(customer, context),
              do: {:ok, customer},
              else: {:error, :unavailable}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp find_personal_customers(owner_type, owner_id) do
    query =
      from(customer in Customer,
        where: customer.owner_type == ^owner_type and customer.owner_id == ^owner_id
      )

    Repo.all(query)
  end

  defp find_customer(owner_type, owner_id) do
    query =
      from(customer in Customer,
        where:
          customer.owner_type == ^owner_type and customer.owner_id == ^owner_id and
            customer.processor == ^Processor.name(),
        limit: 1
      )

    Repo.one(query)
  end

  defp find_customer_by_id(id) do
    Repo.get(Customer, id)
  end

  defp exact_customer_identity?(customer, identity) do
    customer.owner_type == identity["owner_type"] and
      to_string(customer.owner_id) == identity["owner_id"] and
      customer.processor == identity["processor"] and
      to_string(customer.id) == identity["customer_id"]
  end

  defp exact_customer?(customer, context) do
    customer.owner_type == context.owner_type and customer.owner_id == context.owner_id and
      customer.processor == context.processor
  end

  defp context_adapter(session, opts) do
    case Keyword.get(opts, :context_adapter) ||
           get_in(session, ["accrue_portal", "context_adapter"]) do
      adapter when is_atom(adapter) -> adapter
      _ -> nil
    end
  end
end

defmodule AccruePortal.CustomerSession do
  @moduledoc false

  defdelegate resolve(session, opts \\ []), to: Accrue.Portal.CustomerSession
  defdelegate resolve_pin(session, pin, opts \\ []), to: Accrue.Portal.CustomerSession
end
