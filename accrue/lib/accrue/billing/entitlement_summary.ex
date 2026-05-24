defmodule Accrue.Billing.EntitlementSummary do
  @moduledoc """
  Ecto schema for `accrue_entitlement_summaries` (ENT-10).

  An **advisory, observational-only** local cache of Stripe's
  `entitlements.active_entitlement_summary` object, written when a host
  explicitly enables `config :accrue, :entitlements, stripe_native_sync: :advisory`.

  This schema stores a thin local projection of the summary payload — one
  row per customer (keyed on `customer_id` — there is no processor-side
  identifier field, because the summary object has **no top-level `id`**;
  its identity is the customer it belongs to). Stripe is canonical for
  entitlement state;
  Accrue persists only the typed columns operators read on, plus a `data`
  jsonb with the full payload (including the `entitlements.url` pagination
  handle) for the deferred `lattice_stripe >= 1.2` paginated reconcile.

  ## Observational-only (D-01)

  The gate path (`Accrue.entitled?/2`, `has_active_plan?/2`,
  `Accrue.Entitlements.Resolver`, `LocalMap`) NEVER reads this table.
  Local plan->feature mapping stays canonical; this cache is recorded,
  ledgered, telemetered, and exposed via a read-only seam, but never
  consulted to decide a grant.

  ## Force-style write path

  There is no user write path — Stripe is the sole source of these rows.
  `force_changeset/2` skips status allowlists (there is no status) and
  carries `optimistic_lock(:lock_version)` + `unique_constraint(:customer_id)`
  (the one-row-per-customer upsert target) + `foreign_key_constraint(:customer_id)`.
  The monotonic skip-stale guard (Plan 02) keys off the
  `last_stripe_event_ts` / `last_stripe_event_id` watermark columns.

  ## Truncation honesty (D-07)

  Stripe inlines at most 10 entitlements; `entitlements.has_more` maps to
  the typed `truncated` column (queryable / partially-indexed) so operators
  can find known-incomplete caches. Because the cache is observational-only,
  truncation can never affect a gate decision.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_entitlement_summaries" do
    field(:processor, :string, default: "stripe")
    belongs_to(:customer, Accrue.Billing.Customer)
    field(:stripe_customer_id, :string)
    field(:livemode, :boolean)
    field(:entitlement_count, :integer)
    field(:truncated, :boolean, default: false)
    field(:data, :map, default: %{})
    field(:synced_at, :utc_datetime_usec)
    field(:lock_version, :integer, default: 1)
    field(:last_stripe_event_ts, :utc_datetime_usec)
    field(:last_stripe_event_id, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    processor customer_id stripe_customer_id livemode entitlement_count
    truncated data synced_at lock_version
    last_stripe_event_ts last_stripe_event_id
  ]a

  @doc """
  Webhook-path changeset. Stripe is canonical for entitlement-summary
  state; this path skips any status allowlist (there is none) so
  out-of-order events can settle arbitrary state without validation
  failing. Carries the optimistic lock, the one-per-customer unique
  constraint, and the customer foreign-key constraint.
  """
  @spec force_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def force_changeset(summary_or_changeset, attrs \\ %{}) do
    summary_or_changeset
    |> cast(attrs, @cast_fields)
    |> optimistic_lock(:lock_version)
    |> unique_constraint(:customer_id)
    |> foreign_key_constraint(:customer_id)
  end
end
