defmodule AccruePortal.CustomerSession do
  @moduledoc false

  alias Accrue.Billing

  def resolve(session) when is_map(session) do
    case Accrue.Auth.current_user(session) do
      nil ->
        {:error, :unauthenticated}

      user ->
        case Billing.customer(user) do
          {:ok, customer} -> {:ok, user, customer}
          {:error, reason} -> {:error, reason}
        end
    end
  end
end
