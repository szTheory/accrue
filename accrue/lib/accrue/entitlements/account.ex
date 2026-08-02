defmodule Accrue.Entitlements.Account do
  @moduledoc """
  Durable, owner-stable entitlement identity.

  Hosts authenticate and supply the opaque owner identity before calling this
  boundary. The resulting UUID is not derived from the owner and is suitable
  for future rail-specific account binding.
  """

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "accrue_entitlement_accounts" do
    field(:owner_type, :string)
    field(:owner_id, :string)
    field(:revision, :integer, default: 0)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @doc "Builds the owner-identity changeset and maps the database uniqueness authority."
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(account_or_changeset, attrs \\ %{}) do
    account_or_changeset
    |> cast(attrs, [:owner_type, :owner_id, :revision])
    |> validate_required([:owner_type, :owner_id])
    |> validate_number(:revision, greater_than_or_equal_to: 0)
    |> unique_constraint(:owner_id, name: :accrue_entitlement_accounts_owner_identity_index)
  end

  @doc "Fetches or creates the single durable account for an authenticated owner identity."
  @spec fetch_or_create(Ecto.Repo.t(), String.t(), String.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def fetch_or_create(repo, owner_type, owner_id)
      when is_binary(owner_type) and is_binary(owner_id) do
    changeset = changeset(%__MODULE__{}, %{owner_type: owner_type, owner_id: owner_id})

    case repo.insert(changeset,
           on_conflict: :nothing,
           conflict_target: [:owner_type, :owner_id]
         ) do
      {:ok, _account} ->
        {:ok, repo.get_by!(__MODULE__, owner_type: owner_type, owner_id: owner_id)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
