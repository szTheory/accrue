defmodule Accrue.Entitlements.Device do
  @moduledoc "Account-scoped device registration with durable revocation history."

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @states [:active, :revoked, :superseded]
  @opaque_identifier_max_bytes 255
  @opaque_identifier_pattern ~r/\A[A-Za-z0-9][A-Za-z0-9._:-]*\z/
  @jwk_members ~w[crv kty x y]
  @coordinate_pattern ~r/\A[A-Za-z0-9_-]{43}\z/

  schema "accrue_entitlement_devices" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    field(:installation_id, :string)
    field(:public_jwk, :map)
    field(:key_thumbprint, :string)
    field(:state, Ecto.Enum, values: @states, default: :active)
    field(:registered_at, :utc_datetime_usec)
    field(:last_seen_at, :utc_datetime_usec)
    field(:last_accepted_revision, :integer, default: 0)
    field(:revoked_at, :utc_datetime_usec)
    field(:superseded_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}
  @fields ~w[account_id installation_id public_jwk key_thumbprint state registered_at last_seen_at last_accepted_revision revoked_at superseded_at]a
  @required ~w[account_id installation_id key_thumbprint state registered_at last_accepted_revision]a

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(device_or_changeset, attrs \\ %{}) do
    device_or_changeset
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_opaque_identifier(:installation_id)
    |> validate_public_jwk()
    |> validate_thumbprint()
    |> validate_number(:last_accepted_revision, greater_than_or_equal_to: 0)
    |> validate_lifecycle_timestamps()
    |> check_constraint(:state, name: :accrue_entitlement_devices_state_domain_check)
    |> check_constraint(:last_accepted_revision,
      name: :accrue_entitlement_devices_last_accepted_revision_nonnegative_check
    )
    |> check_constraint(:state, name: :accrue_entitlement_devices_lifecycle_check)
    |> check_constraint(:installation_id,
      name: :accrue_ent_devices_installation_id_opaque_check
    )
    |> check_constraint(:key_thumbprint,
      name: :accrue_ent_devices_key_thumbprint_opaque_check
    )
    |> check_constraint(:public_jwk, name: :accrue_entitlement_devices_public_jwk_check)
    |> foreign_key_constraint(:account_id, name: :accrue_entitlement_devices_account_id_fkey)
    |> unique_constraint(:installation_id,
      name: :accrue_entitlement_devices_current_installation_identity_index
    )
    |> unique_constraint(:key_thumbprint,
      name: :accrue_entitlement_devices_current_thumbprint_identity_index
    )
  end

  @spec thumbprint(map()) :: String.t()
  def thumbprint(%{"kty" => "EC", "crv" => "P-256", "x" => x, "y" => y})
      when is_binary(x) and is_binary(y) do
    "{\"crv\":\"P-256\",\"kty\":\"EC\",\"x\":\"#{x}\",\"y\":\"#{y}\"}"
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  def thumbprint(_), do: ""

  defp validate_opaque_identifier(changeset, field) do
    case get_field(changeset, field) do
      value when is_binary(value) ->
        changeset
        |> validate_length(field, max: @opaque_identifier_max_bytes, count: :bytes)
        |> validate_format(field, @opaque_identifier_pattern,
          message: "must be a bounded opaque identifier"
        )

      _ ->
        changeset
    end
  end

  defp validate_public_jwk(changeset) do
    case get_field(changeset, :public_jwk) do
      nil ->
        changeset

      jwk when is_map(jwk) ->
        if valid_public_jwk?(jwk),
          do: changeset,
          else: add_error(changeset, :public_jwk, "must be an exact public P-256 JWK")

      _ ->
        add_error(changeset, :public_jwk, "must be an exact public P-256 JWK")
    end
  end

  defp validate_thumbprint(changeset) do
    jwk = get_field(changeset, :public_jwk)
    thumbprint = get_field(changeset, :key_thumbprint)

    cond do
      is_nil(jwk) -> validate_opaque_identifier(changeset, :key_thumbprint)
      valid_public_jwk?(jwk) and thumbprint == thumbprint(jwk) -> changeset
      true -> add_error(changeset, :key_thumbprint, "must match the public JWK thumbprint")
    end
  end

  defp valid_public_jwk?(%{"kty" => "EC", "crv" => "P-256", "x" => x, "y" => y} = jwk) do
    Map.keys(jwk) |> Enum.sort() == @jwk_members and valid_coordinate?(x) and valid_coordinate?(y)
  end

  defp valid_public_jwk?(_), do: false

  defp valid_coordinate?(value) when is_binary(value) do
    Regex.match?(@coordinate_pattern, value) and
      match?({:ok, <<_::binary-size(32)>>}, Base.url_decode64(value, padding: false))
  end

  defp valid_coordinate?(_), do: false

  defp validate_lifecycle_timestamps(changeset) do
    state = get_field(changeset, :state)
    revoked_at = get_field(changeset, :revoked_at)
    superseded_at = get_field(changeset, :superseded_at)

    valid? =
      case state do
        :active -> is_nil(revoked_at) and is_nil(superseded_at)
        :revoked -> not is_nil(revoked_at) and is_nil(superseded_at)
        :superseded -> is_nil(revoked_at) and not is_nil(superseded_at)
      end

    if valid?,
      do: changeset,
      else: add_error(changeset, :state, "must match revocation or supersession timestamps")
  end
end
