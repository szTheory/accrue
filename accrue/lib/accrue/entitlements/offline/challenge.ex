defmodule Accrue.Entitlements.Offline.Challenge do
  @moduledoc false

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @purposes [:registration, :reconnect]
  @fields ~w[account_id installation_id nonce_digest purpose expires_at consumed_at idempotency_digest]a
  @required ~w[account_id installation_id nonce_digest purpose expires_at]a
  @digest_pattern ~r/\A[A-Za-z0-9_-]{43}\z/
  @opaque_identifier_pattern ~r/\A[A-Za-z0-9][A-Za-z0-9._:-]*\z/

  schema "accrue_entitlement_offline_challenges" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    field(:installation_id, :string)
    field(:nonce_digest, :string)
    field(:purpose, Ecto.Enum, values: @purposes)
    field(:expires_at, :utc_datetime_usec)
    field(:consumed_at, :utc_datetime_usec)
    field(:idempotency_digest, :string)
    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  defmodule Value do
    @enforce_keys [:id, :nonce, :expires_at, :purpose]
    defstruct [:id, :nonce, :expires_at, :purpose]
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(challenge_or_changeset, attrs \\ %{}) do
    challenge_or_changeset
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:installation_id, max: 255, count: :bytes)
    |> validate_format(:installation_id, @opaque_identifier_pattern)
    |> validate_format(:nonce_digest, @digest_pattern)
    |> validate_change(:idempotency_digest, &validate_optional_digest/2)
    |> check_constraint(:purpose, name: :accrue_entitlement_offline_challenges_purpose_check)
    |> check_constraint(:nonce_digest, name: :accrue_entitlement_offline_challenges_digest_check)
    |> check_constraint(:installation_id,
      name: :accrue_entitlement_offline_challenges_installation_id_check
    )
    |> foreign_key_constraint(:account_id,
      name: :accrue_entitlement_offline_challenges_account_id_fkey
    )
    |> unique_constraint(:nonce_digest,
      name: :accrue_entitlement_offline_challenges_nonce_identity_index
    )
    |> unique_constraint(:idempotency_digest,
      name: :accrue_entitlement_offline_challenges_idempotency_identity_index
    )
  end

  defp validate_optional_digest(:idempotency_digest, nil), do: []

  defp validate_optional_digest(:idempotency_digest, value) when is_binary(value),
    do: digest_error(value)

  defp validate_optional_digest(:idempotency_digest, _), do: [idempotency_digest: "is invalid"]

  defp digest_error(value) do
    if Regex.match?(@digest_pattern, value), do: [], else: [idempotency_digest: "is invalid"]
  end
end
