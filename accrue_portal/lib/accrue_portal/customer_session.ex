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
end
