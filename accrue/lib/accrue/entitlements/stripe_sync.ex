defmodule Accrue.Entitlements.StripeSync do
  @moduledoc """
  Read-only observational seam over the optional Stripe-native
  entitlement-summary cache (`accrue_entitlement_summaries`, ENT-10).

  This module exposes the advisory cache row for a customer so operators
  and dashboards can *observe* what Stripe last reported — it is NOT a gate
  API and answers no grant/deny question.

  ## Observational-only (D-01 / D-11)

  The advisory cache is recorded, ledgered, telemetered, and surfaced here,
  but it is **never consulted to decide a grant**. Local plan→feature
  mapping stays canonical. The gate path — `Accrue.entitled?/2`,
  `Accrue.has_active_plan?/2`, `Accrue.Entitlements.Resolver`, and
  `Accrue.Entitlements.Resolver.LocalMap` — MUST NOT reference this module
  or the `Accrue.Billing.EntitlementSummary` schema. The static gate
  `scripts/ci/verify_entitlement_sync_isolation.sh` (Plan 03) enforces this
  at merge time; this module deliberately keeps the dependency one-way.

  ## One-way dependency

  `seam → billing read`, never `gate → seam`. Nothing under the gate path
  references this module; it only reads through `Accrue.Repo`. The cache is
  written exclusively by `Accrue.Webhook.DefaultHandler` when a host opts
  into `config :accrue, :entitlements, stripe_native_sync: :advisory`.
  """

  alias Accrue.Billing.{Customer, EntitlementSummary}
  alias Accrue.Repo

  # Returns the cached `Accrue.Billing.EntitlementSummary` row for
  # `customer`, or `nil` if none has been synced. Observational-only:
  # callers MUST NOT use the returned row to make an entitlement grant
  # decision — local plan→feature mapping is canonical.
  @doc false
  @spec summary_for_customer(Customer.t()) :: EntitlementSummary.t() | nil
  def summary_for_customer(%Customer{} = customer) do
    Repo.get_by(EntitlementSummary, customer_id: customer.id)
  end
end
