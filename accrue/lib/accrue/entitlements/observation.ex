defmodule Accrue.Entitlements.Observation do
  @moduledoc """
  Privacy-bounded, rail-qualified entitlement evidence received from a provider.

  Observations retain only normalized fields needed for later projection and
  repair. Raw receipts, JWS payloads, notification bodies, and owner identity
  must remain outside this durable queryable boundary.
  """

  use Accrue.Schema

  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @rails [:stripe, :apple]
  @environments [:production, :sandbox]
  @states [:received, :qualified, :quarantined, :retrying]
  @evidence_ref_max_bytes 255
  # Provider provenance is retained only as bounded normalized identifiers.
  @provider_event_id_max_bytes 255
  @provider_transaction_id_max_bytes 255
  @kind_max_bytes 64
  @provider_lineage_id_max_bytes 255
  @provider_product_id_max_bytes 255
  @provider_order_key_max_bytes 128
  @evidence_ref_pattern ~r/\Aopaque:\/\/[A-Za-z0-9_-]+(?:\/[A-Za-z0-9_-]+)*\z/
  # The only projection metadata retained in Phase 216. Metadata is not a
  # provider-payload escape hatch: other provenance belongs in typed fields.
  @metadata_sources ["apple_server", "fake_observer"]

  schema "accrue_entitlement_observations" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    field(:rail, Ecto.Enum, values: @rails)
    field(:environment, Ecto.Enum, values: @environments)
    field(:provider_event_id, :string)
    field(:provider_transaction_id, :string)
    field(:kind, :string)
    field(:provider_lineage_id, :string)
    field(:provider_product_id, :string)
    field(:provider_order, :integer, default: 0)
    field(:provider_order_key, :string)
    field(:observed_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:state, Ecto.Enum, values: @states, default: :received)
    field(:quarantine_reason, :string)
    field(:retry_count, :integer, default: 0)
    field(:next_retry_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})
    field(:evidence_digest, :string)
    field(:evidence_ref, :string)
    field(:evidence_expires_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @ingest_fields ~w[
    account_id rail environment provider_event_id provider_transaction_id kind
    provider_lineage_id provider_product_id provider_order provider_order_key observed_at expires_at state
    quarantine_reason retry_count next_retry_at metadata evidence_digest
    evidence_ref evidence_expires_at
  ]a

  @required_fields ~w[
    account_id rail environment kind provider_lineage_id provider_product_id
    provider_order observed_at state retry_count metadata evidence_digest
  ]a

  @doc "Builds the bounded ingest changeset and maps database identity constraints."
  @spec ingest_changeset(map()) :: Ecto.Changeset.t()
  def ingest_changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(normalize_optional_identities(attrs), @ingest_fields)
    |> validate_required(@required_fields)
    |> validate_identity()
    |> validate_provider_provenance_lengths()
    |> validate_number(:provider_order, greater_than_or_equal_to: 0)
    |> validate_length(:provider_order_key, max: @provider_order_key_max_bytes, count: :bytes)
    |> validate_number(:retry_count, greater_than_or_equal_to: 0)
    |> validate_format(:evidence_digest, ~r/\A[a-f0-9]{64}\z/)
    |> validate_metadata()
    |> validate_evidence_pair()
    |> validate_evidence_reference()
    |> foreign_key_constraint(:account_id, name: :accrue_entitlement_observations_account_id_fkey)
    |> unique_constraint(:provider_event_id,
      name: :accrue_entitlement_observations_provider_event_identity_index
    )
    |> unique_constraint(:provider_transaction_id,
      name: :accrue_entitlement_observations_transaction_kind_identity_index
    )
    |> check_constraint(:evidence_ref,
      name: :accrue_entitlement_observations_evidence_reference_pair_check
    )
    |> check_constraint(:provider_event_id,
      name: :accrue_entitlement_observations_identity_present_check
    )
    |> check_constraint(:provider_event_id,
      name: :accrue_entitlement_observations_identity_nonblank_check
    )
    |> check_constraint(:evidence_ref,
      name: :accrue_entitlement_observations_evidence_reference_locator_check
    )
    |> check_constraint(:rail, name: :accrue_entitlement_observations_rail_domain_check)
    |> check_constraint(:environment,
      name: :accrue_entitlement_observations_environment_domain_check
    )
    |> check_constraint(:state, name: :accrue_entitlement_observations_state_domain_check)
    |> check_constraint(:provider_order,
      name: :accrue_entitlement_observations_provider_order_nonnegative_check
    )
    |> check_constraint(:provider_order_key,
      name: :accrue_ent_obs_provider_order_key_bytes_check
    )
    |> check_constraint(:retry_count,
      name: :accrue_entitlement_observations_retry_count_nonnegative_check
    )
    |> check_constraint(:provider_event_id, name: :accrue_ent_obs_provider_event_id_bytes_check)
    |> check_constraint(:provider_transaction_id,
      name: :accrue_ent_obs_provider_transaction_id_bytes_check
    )
    |> check_constraint(:kind, name: :accrue_ent_obs_kind_bytes_check)
    |> check_constraint(:provider_lineage_id,
      name: :accrue_ent_obs_provider_lineage_id_bytes_check
    )
    |> check_constraint(:provider_product_id,
      name: :accrue_ent_obs_provider_product_id_bytes_check
    )
    |> check_constraint(:metadata, name: :accrue_ent_obs_metadata_projection_check)
  end

  @doc "Inserts an observation once and returns the durable row selected by PostgreSQL."
  @spec insert_idempotently(Ecto.Repo.t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def insert_idempotently(repo, attrs) when is_map(attrs) do
    changeset = ingest_changeset(attrs)

    if changeset.valid? do
      case repo.insert(changeset,
             on_conflict: :nothing,
             conflict_target: conflict_target(changeset)
           ) do
        {:ok, _observation} -> resolve_identity_owner(repo, changeset)
        {:error, error_changeset} -> {:error, error_changeset}
      end
    else
      {:error, changeset}
    end
  end

  defp resolve_identity_owner(repo, changeset) do
    observation = fetch_by_identity!(repo, changeset)

    if observation.account_id == get_field(changeset, :account_id) do
      {:ok, observation}
    else
      {:error, add_error(changeset, :account_id, "provider identity is already owned")}
    end
  end

  defp validate_provider_provenance_lengths(changeset) do
    changeset
    |> validate_length(:provider_event_id, max: @provider_event_id_max_bytes, count: :bytes)
    |> validate_length(:provider_transaction_id,
      max: @provider_transaction_id_max_bytes,
      count: :bytes
    )
    |> validate_length(:kind, max: @kind_max_bytes, count: :bytes)
    |> validate_length(:provider_lineage_id, max: @provider_lineage_id_max_bytes, count: :bytes)
    |> validate_length(:provider_product_id, max: @provider_product_id_max_bytes, count: :bytes)
  end

  defp validate_identity(changeset) do
    event_id = get_field(changeset, :provider_event_id)
    transaction_id = get_field(changeset, :provider_transaction_id)

    if present?(event_id) or present?(transaction_id) do
      changeset
    else
      add_error(changeset, :provider_event_id, "or provider_transaction_id must be present")
    end
  end

  defp normalize_optional_identities(attrs) do
    attrs
    |> normalize_optional_identity(:provider_event_id)
    |> normalize_optional_identity(:provider_transaction_id)
  end

  defp normalize_optional_identity(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} when is_binary(value) ->
        if String.trim(value) == "", do: Map.put(attrs, key, nil), else: attrs

      _ ->
        attrs
    end
  end

  defp validate_metadata(changeset) do
    case get_field(changeset, :metadata) do
      metadata when is_map(metadata) ->
        if valid_metadata?(metadata),
          do: changeset,
          else: add_error(changeset, :metadata, "must use the fixed normalized source contract")

      _ ->
        add_error(changeset, :metadata, "must be a map")
    end
  end

  defp valid_metadata?(%{} = metadata) when map_size(metadata) == 0, do: true

  defp valid_metadata?(%{"source" => source} = metadata)
       when map_size(metadata) == 1 and source in @metadata_sources,
       do: true

  defp valid_metadata?(_metadata), do: false

  defp validate_evidence_pair(changeset) do
    ref = get_field(changeset, :evidence_ref)
    expiry = get_field(changeset, :evidence_expires_at)

    if is_nil(ref) == is_nil(expiry) do
      changeset
    else
      add_error(changeset, :evidence_ref, "must be paired with evidence_expires_at")
    end
  end

  defp validate_evidence_reference(changeset) do
    case get_field(changeset, :evidence_ref) do
      nil ->
        changeset

      ref when is_binary(ref) ->
        if byte_size(ref) <= @evidence_ref_max_bytes and Regex.match?(@evidence_ref_pattern, ref),
          do: changeset,
          else: add_error(changeset, :evidence_ref, "must be a bounded opaque locator")

      _ ->
        add_error(changeset, :evidence_ref, "must be a bounded opaque locator")
    end
  end

  defp conflict_target(changeset) do
    if present?(get_field(changeset, :provider_event_id)) do
      {:unsafe_fragment,
       "(rail, environment, provider_event_id) WHERE provider_event_id IS NOT NULL"}
    else
      {:unsafe_fragment,
       "(rail, environment, provider_transaction_id, kind) WHERE provider_event_id IS NULL AND provider_transaction_id IS NOT NULL"}
    end
  end

  defp fetch_by_identity!(repo, changeset) do
    rail = get_field(changeset, :rail)
    environment = get_field(changeset, :environment)

    query =
      from(observation in __MODULE__,
        where: observation.rail == ^rail and observation.environment == ^environment
      )

    query =
      if event_id = get_field(changeset, :provider_event_id) do
        from(observation in query, where: observation.provider_event_id == ^event_id)
      else
        transaction_id = get_field(changeset, :provider_transaction_id)
        kind = get_field(changeset, :kind)

        from(observation in query,
          where:
            is_nil(observation.provider_event_id) and
              observation.provider_transaction_id == ^transaction_id and observation.kind == ^kind
        )
      end

    repo.one!(query)
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
