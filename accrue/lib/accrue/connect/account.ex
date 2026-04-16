defmodule Accrue.Connect.Account do
  @moduledoc """
  Ecto schema for `accrue_connect_accounts` — the local projection of a
  Stripe Connected Account (D5-02, CONN-01/03).

  ## Predicates (D3-04, pattern 3)

  Never inspect raw booleans on the account struct. Use the predicates
  below — each ships 3 clauses (struct match, bare-map match, catch-all)
  so they work equally well on `%__MODULE__{}` rows and on raw atom/string
  keyed maps returned from the processor before the changeset settles.

    * `charges_enabled?/1`
    * `payouts_enabled?/1`
    * `details_submitted?/1`
    * `fully_onboarded?/1` — all three above must be true
    * `deauthorized?/1` — truthy `deauthorized_at`

  ## Changesets

    * `changeset/2` — strict path; validates `:type` inclusion and
      requires `[:stripe_account_id, :type]`.
    * `force_status_changeset/2` — webhook path (D3-17); bypasses
      required validation so out-of-order `account.updated` reducers
      can settle arbitrary state without tripping the strict gate.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @types ["standard", "express", "custom"]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_connect_accounts" do
    field(:stripe_account_id, :string)
    field(:owner_type, :string)
    field(:owner_id, :string)
    field(:type, :string)
    field(:country, :string)
    field(:email, :string)
    field(:charges_enabled, :boolean, default: false)
    field(:details_submitted, :boolean, default: false)
    field(:payouts_enabled, :boolean, default: false)
    field(:capabilities, :map, default: %{})
    field(:requirements, :map, default: %{})
    field(:data, :map, default: %{})
    field(:deauthorized_at, :utc_datetime_usec)
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    stripe_account_id owner_type owner_id type country email
    charges_enabled details_submitted payouts_enabled
    capabilities requirements data deauthorized_at lock_version
  ]a

  @required_fields ~w[stripe_account_id type]a

  @state_fields ~w[
    charges_enabled details_submitted payouts_enabled
    capabilities requirements data deauthorized_at
  ]a

  @doc "Canonical list of Connect account types (D5-02)."
  @spec types() :: [String.t()]
  def types, do: @types

  @doc """
  Builds a changeset for creating or updating a connected account.
  Validates `:type` and enforces the unique `stripe_account_id` constraint.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(account_or_changeset, attrs \\ %{}) do
    account_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, @types)
    |> unique_constraint(:stripe_account_id)
    |> optimistic_lock(:lock_version)
  end

  @doc """
  Webhook-path changeset (D3-17). Casts only the state fields so
  out-of-order `account.updated` reducers can settle arbitrary state
  without failing the user-path required-field guard.
  """
  @spec force_status_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def force_status_changeset(account_or_changeset, attrs \\ %{}) do
    account_or_changeset
    |> cast(attrs, @state_fields)
    |> optimistic_lock(:lock_version)
  end

  # ---------------------------------------------------------------------------
  # Predicates (D3-04 / PATTERNS pattern 3)
  # ---------------------------------------------------------------------------

  @doc "True if the account can accept charges."
  @spec charges_enabled?(%__MODULE__{} | map()) :: boolean()
  def charges_enabled?(%__MODULE__{charges_enabled: true}), do: true
  def charges_enabled?(%{charges_enabled: true}), do: true
  def charges_enabled?(_), do: false

  @doc "True if Stripe has approved payouts for the account."
  @spec payouts_enabled?(%__MODULE__{} | map()) :: boolean()
  def payouts_enabled?(%__MODULE__{payouts_enabled: true}), do: true
  def payouts_enabled?(%{payouts_enabled: true}), do: true
  def payouts_enabled?(_), do: false

  @doc "True if the account owner finished the onboarding flow."
  @spec details_submitted?(%__MODULE__{} | map()) :: boolean()
  def details_submitted?(%__MODULE__{details_submitted: true}), do: true
  def details_submitted?(%{details_submitted: true}), do: true
  def details_submitted?(_), do: false

  @doc """
  True if the account has charges, payouts, AND onboarding completed —
  the canonical "ready to do business" predicate.
  """
  @spec fully_onboarded?(%__MODULE__{} | map()) :: boolean()
  def fully_onboarded?(acct) do
    charges_enabled?(acct) and payouts_enabled?(acct) and details_submitted?(acct)
  end

  @doc "True if the account has been deauthorized (D5-05)."
  @spec deauthorized?(%__MODULE__{} | map()) :: boolean()
  def deauthorized?(%__MODULE__{deauthorized_at: %DateTime{}}), do: true
  def deauthorized?(%{deauthorized_at: %DateTime{}}), do: true
  def deauthorized?(_), do: false
end
