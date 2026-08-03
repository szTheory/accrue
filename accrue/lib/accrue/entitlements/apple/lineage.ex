defmodule Accrue.Entitlements.Apple.Lineage do
  @moduledoc false
  use Accrue.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_entitlement_apple_lineages" do
    field(:environment, Ecto.Enum, values: [:production, :sandbox])
    field(:original_transaction_id, :string)
    field(:account_id, :binary_id)
    field(:binding_state, Ecto.Enum, values: [:unbound, :bound], default: :unbound)
    field(:verified_token_digest, :string)
    field(:provider_order_high_water, :integer, default: 0)
    field(:last_reason, :string, default: "received")
    field(:attempts, :integer, default: 0)
    field(:next_retry_at, :utc_datetime_usec)
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(lineage, attrs) do
    lineage
    |> cast(attrs, [
      :environment,
      :original_transaction_id,
      :account_id,
      :binding_state,
      :verified_token_digest,
      :provider_order_high_water,
      :last_reason,
      :attempts,
      :next_retry_at
    ])
    |> validate_required([:environment, :original_transaction_id, :binding_state, :last_reason])
    |> validate_length(:original_transaction_id, max: 255, count: :bytes)
    |> validate_format(:verified_token_digest, ~r/\A[a-f0-9]{64}\z/, allow_nil: true)
    |> unique_constraint(:original_transaction_id,
      name: :accrue_apple_lineages_environment_original_transaction_index
    )
  end

  def lock_or_insert(repo, environment, original_transaction_id, attrs \\ %{}) do
    changeset =
      changeset(
        %__MODULE__{},
        Map.merge(attrs, %{
          environment: environment,
          original_transaction_id: original_transaction_id
        })
      )

    {:ok, _} =
      repo.insert(changeset,
        on_conflict: :nothing,
        conflict_target: [:environment, :original_transaction_id]
      )

    repo.one!(
      from(l in __MODULE__,
        where:
          l.environment == ^environment and l.original_transaction_id == ^original_transaction_id,
        lock: "FOR UPDATE"
      )
    )
  end

  def claim(repo, lineage, account_id, token, opts \\ [])

  def claim(repo, %__MODULE__{} = lineage, account_id, token, _opts)
      when is_binary(token) do
    digest = :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)

    cond do
      lineage.account_id == nil and token == account_id ->
        {:ok, updated} =
          repo.update(
            changeset(lineage, %{
              account_id: account_id,
              binding_state: :bound,
              verified_token_digest: digest,
              last_reason: "verified"
            })
          )

        {:claimed, updated}

      lineage.account_id == account_id and token == account_id ->
        {:owned, lineage}

      true ->
        {:ownership_conflict, lineage}
    end
  end

  def claim(_repo, lineage, _account_id, _token, _opts), do: {:verified_unbound, lineage}
end
