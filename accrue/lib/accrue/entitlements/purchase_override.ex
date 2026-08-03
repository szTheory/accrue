defmodule Accrue.Entitlements.PurchaseOverride do
  @moduledoc false

  use Accrue.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @ttl_seconds 900

  schema "accrue_entitlement_purchase_overrides" do
    field(:account_id, :binary_id)
    field(:capability_digest, :string)
    field(:rail, Ecto.Enum, values: [:stripe, :apple])
    field(:logical_plan, :string)
    field(:reason, :string)
    field(:sources_digest, :string)
    field(:decision_revision, :integer)
    field(:actor_id, :string)
    field(:justification, :string)
    field(:expires_at, :utc_datetime_usec)
    field(:operation_id, :string)
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(override, attrs) do
    override
    |> cast(attrs, [
      :account_id,
      :capability_digest,
      :rail,
      :logical_plan,
      :reason,
      :sources_digest,
      :decision_revision,
      :actor_id,
      :justification,
      :expires_at,
      :operation_id
    ])
    |> validate_required([
      :account_id,
      :capability_digest,
      :rail,
      :logical_plan,
      :reason,
      :sources_digest,
      :decision_revision,
      :actor_id,
      :justification,
      :expires_at
    ])
    |> validate_length(:justification, max: 280)
    |> unique_constraint(:capability_digest)
  end

  @doc "Issues an opaque, server-side capability for one current blocking decision."
  def issue(repo, account_id, decision, justification, actor_id, opts \\ []) do
    capability = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    now = Keyword.get(opts, :now, DateTime.utc_now())

    attrs = %{
      account_id: account_id,
      capability_digest: digest(capability),
      rail: decision.target_rail,
      logical_plan: Atom.to_string(decision.logical_plan),
      reason: Atom.to_string(decision.reason),
      sources_digest: sources_digest(decision.sources),
      decision_revision: decision.revision,
      actor_id: actor_id,
      justification: justification,
      expires_at: DateTime.add(now, Keyword.get(opts, :ttl_seconds, @ttl_seconds), :second)
    }

    case repo.insert(changeset(%__MODULE__{}, attrs)) do
      {:ok, _override} -> {:ok, capability}
      {:error, _changeset} -> :error
    end
  end

  @doc "Validates and binds a capability to exactly one durable purchase operation."
  def authorize_operation(repo, capability, account_id, decision, operation_id, opts \\ [])

  def authorize_operation(repo, capability, account_id, decision, operation_id, opts)
      when is_binary(capability) and is_binary(operation_id) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    result =
      repo.transaction(fn ->
        override =
          repo.one(
            from(override in __MODULE__,
              where:
                override.account_id == ^account_id and
                  override.capability_digest == ^digest(capability),
              lock: "FOR UPDATE"
            )
          )

        if valid_for?(override, decision, operation_id, now) do
          case override.operation_id do
            nil ->
              override
              |> changeset(%{operation_id: operation_id})
              |> repo.update!()

            ^operation_id ->
              :ok
          end

          :ok
        else
          repo.rollback(:unauthorized)
        end
      end)

    match?({:ok, :ok}, result)
  end

  def authorize_operation(_repo, _capability, _account_id, _decision, _operation_id, _opts),
    do: false

  defp valid_for?(nil, _decision, _operation_id, _now), do: false

  defp valid_for?(override, decision, operation_id, now) do
    override.rail == decision.target_rail and
      override.logical_plan == Atom.to_string(decision.logical_plan) and
      override.reason == Atom.to_string(decision.reason) and
      override.sources_digest == sources_digest(decision.sources) and
      override.decision_revision == decision.revision and
      DateTime.compare(override.expires_at, now) == :gt and
      (is_nil(override.operation_id) or override.operation_id == operation_id)
  end

  defp sources_digest(sources) do
    sources
    |> Enum.map(fn source ->
      {
        Map.get(source, :rail),
        Map.get(source, :environment),
        Map.get(source, :logical_plan),
        Map.get(source, :effective_at),
        Map.get(source, :expires_at),
        Map.get(source, :revoked_at)
      }
    end)
    |> Enum.sort()
    |> :erlang.term_to_binary([:deterministic])
    |> digest()
  end

  defp digest(value),
    do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
