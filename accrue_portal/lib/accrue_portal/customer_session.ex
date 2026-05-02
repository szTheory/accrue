defmodule Accrue.Portal.CustomerSession do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Processor
  alias Accrue.Repo

  @spec resolve(map(), keyword()) :: {:ok, Accrue.Auth.user(), Customer.t()} | {:error, term()}
  def resolve(session, opts \\ []) when is_map(session) and is_list(opts) do
    create? = Keyword.get(opts, :create?, true)

    case Accrue.Auth.current_user(session) do
      nil ->
        {:error, :unauthenticated}

      %{__struct__: mod, id: id} = user ->
        resolve_customer(user, mod, id, create?)

      user ->
        {:error, {:unsupported_user_shape, user}}
    end
  end

  defp resolve_customer(user, _mod, _id, true) do
    case Billing.customer(user) do
      {:ok, customer} -> {:ok, user, customer}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_customer(user, mod, id, false) do
    billable_type = mod.__accrue__(:billable_type)
    owner_id = to_string(id)

    query =
      from(customer in Customer,
        where:
          customer.owner_type == ^billable_type and customer.owner_id == ^owner_id and
            customer.processor == ^Processor.name(),
        limit: 1
      )

    case Repo.one(query) do
      %Customer{} = customer -> {:ok, user, customer}
      nil -> {:error, :customer_not_found}
    end
  end
end

defmodule AccruePortal.CustomerSession do
  @moduledoc false

  defdelegate resolve(session, opts \\ []), to: Accrue.Portal.CustomerSession
end
