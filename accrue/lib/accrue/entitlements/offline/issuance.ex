defmodule Accrue.Entitlements.Offline.Issuance do
  @moduledoc false

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @dispositions [:allow, :deny]
  @fields ~w[account_id device_id token_id_hash kid revision disposition issued_at fresh_until expires_at correlation_hash]a
  @required ~w[account_id device_id token_id_hash kid revision disposition issued_at fresh_until]a
  @digest_pattern ~r/\A[A-Za-z0-9_-]{43}\z/
  @kid_pattern ~r/\A[A-Za-z0-9._:-]+\z/

  schema "accrue_entitlement_offline_issuances" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    belongs_to(:device, Accrue.Entitlements.Device, type: :binary_id)
    field(:token_id_hash, :string)
    field(:kid, :string)
    field(:revision, :integer)
    field(:disposition, Ecto.Enum, values: @dispositions)
    field(:issued_at, :utc_datetime_usec)
    field(:fresh_until, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:correlation_hash, :string)
    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @retirement_buffer_seconds 86_400

  @spec retirement_requirements(Ecto.Repo.t(), DateTime.t(), keyword()) ::
          %{String.t() => :required | :eligible | :never}
  def retirement_requirements(repo, now, opts \\ []) do
    buffer =
      max(
        Keyword.get(opts, :key_retirement_buffer_seconds, @retirement_buffer_seconds),
        @retirement_buffer_seconds
      )

    import Ecto.Query

    repo.all(from(issuance in __MODULE__, select: {issuance.kid, issuance.expires_at}))
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {kid, expiries} ->
      requirement =
        if Enum.any?(expiries, &is_nil/1) do
          :never
        else
          horizon = expiries |> Enum.max_by(&DateTime.to_unix/1) |> DateTime.add(buffer, :second)
          if DateTime.compare(now, horizon) in [:eq, :gt], do: :eligible, else: :required
        end

      {kid, requirement}
    end)
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(issuance_or_changeset, attrs \\ %{}) do
    issuance_or_changeset
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_format(:token_id_hash, @digest_pattern)
    |> validate_change(:correlation_hash, &validate_optional_digest/2)
    |> validate_length(:kid, min: 1, max: 128, count: :bytes)
    |> validate_format(:kid, @kid_pattern)
    |> validate_number(:revision, greater_than_or_equal_to: 0)
    |> validate_time_order()
    |> check_constraint(:revision, name: :accrue_entitlement_offline_issuances_revision_check)
    |> check_constraint(:disposition,
      name: :accrue_entitlement_offline_issuances_disposition_check
    )
    |> check_constraint(:issued_at, name: :accrue_entitlement_offline_issuances_time_order_check)
    |> check_constraint(:token_id_hash, name: :accrue_entitlement_offline_issuances_digest_check)
    |> check_constraint(:kid, name: :accrue_entitlement_offline_issuances_kid_check)
    |> foreign_key_constraint(:account_id,
      name: :accrue_entitlement_offline_issuances_account_id_fkey
    )
    |> foreign_key_constraint(:device_id,
      name: :accrue_entitlement_offline_issuances_device_id_fkey
    )
    |> unique_constraint(:token_id_hash,
      name: :accrue_entitlement_offline_issuances_token_identity_index
    )
  end

  defp validate_optional_digest(:correlation_hash, nil), do: []

  defp validate_optional_digest(:correlation_hash, value) when is_binary(value),
    do: digest_error(value)

  defp validate_optional_digest(:correlation_hash, _), do: [correlation_hash: "is invalid"]

  defp digest_error(value) do
    if Regex.match?(@digest_pattern, value), do: [], else: [correlation_hash: "is invalid"]
  end

  defp validate_time_order(changeset) do
    issued_at = get_field(changeset, :issued_at)
    fresh_until = get_field(changeset, :fresh_until)
    expires_at = get_field(changeset, :expires_at)

    if is_struct(issued_at, DateTime) and is_struct(fresh_until, DateTime) and
         (is_nil(expires_at) or is_struct(expires_at, DateTime)) and
         DateTime.compare(issued_at, fresh_until) in [:lt, :eq] and
         (is_nil(expires_at) or DateTime.compare(fresh_until, expires_at) in [:lt, :eq]) do
      changeset
    else
      add_error(changeset, :issued_at, "must not be after freshness or expiry")
    end
  end
end
