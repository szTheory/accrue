# Edge-states seed.
#
# Adds host-dev billing records that mirror the key edge states needed for
# the developer's local click-through (mix ecto.reset / mix run seeds.exs):
#
#   - Long-name customer (110-char name) — exercises name-truncation paths
#   - At-risk / dunning subscription (:past_due) — populates Recovery dashboard
#   - Canceling subscription (status :active + cancel_at_period_end: true)
#   - JPY charge (zero-decimal multi-currency path)
#   - JPY invoice (:open status, ¥55,000)
#
# FULLY IDEMPOTENT: every record is keyed on a deterministic processor_id and
# inserted via get-or-insert, so re-running seeds.exs any number of times
# never duplicates rows.
#
# Processor IDs are in the "e2e_edge_" namespace so cleanup helpers can scope
# deletions to this sub-seed without touching hero or showcase rows.

alias AccrueHost.Repo

alias Accrue.Billing.{
  Charge,
  Customer,
  Invoice,
  Subscription
}

now = Accrue.Clock.utc_now()
days_ago = fn days -> DateTime.add(now, -days * 86_400, :second) end

# ---------------------------------------------------------------------------
# Helpers (copied verbatim from showcase.exs for consistency)
# ---------------------------------------------------------------------------

# Generic get-or-insert keyed on processor + processor_id. `attrs` must include
# :processor and :processor_id. Returns the existing or newly inserted struct.
upsert = fn schema, changeset_fun, processor_id, attrs ->
  case Repo.get_by(schema, processor: "fake", processor_id: processor_id) do
    nil ->
      attrs = attrs |> Map.put(:processor, "fake") |> Map.put(:processor_id, processor_id)

      struct(schema)
      |> changeset_fun.(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

# ---------------------------------------------------------------------------
# 1. LONG-NAME CUSTOMER
#    processor_id "cus_e2e_edge_1" matches the allowlist in accrue_host_seed_e2e.exs
# ---------------------------------------------------------------------------

long_name_customer =
  upsert.(Customer, &Customer.changeset/2, "cus_e2e_edge_1", %{
    owner_type: "User",
    owner_id: Ecto.UUID.generate(),
    name: "E2E Edge LongName — " <> String.duplicate("A", 90),
    email: "edge-longname@example.test",
    metadata: %{},
    data: %{}
  })

# ---------------------------------------------------------------------------
# 2. AT-RISK / DUNNING SUBSCRIPTION (:past_due)
#    Must use force_status_changeset to bypass transition guards when setting
#    :past_due directly on a new subscription row.
#    processor_id "sub_e2e_edge_at_risk"
# ---------------------------------------------------------------------------

at_risk_sub =
  case Repo.get_by(Subscription, processor: "fake", processor_id: "sub_e2e_edge_at_risk") do
    nil ->
      attrs = %{
        customer_id: long_name_customer.id,
        processor: "fake",
        processor_id: "sub_e2e_edge_at_risk",
        status: :past_due,
        past_due_since: days_ago.(5),
        dunning_campaign_started_at: days_ago.(5),
        cancel_at_period_end: false,
        lock_version: 1,
        metadata: %{},
        data: %{}
      }

      %Subscription{}
      |> Subscription.force_status_changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end

# ---------------------------------------------------------------------------
# 3. CANCELING SUBSCRIPTION (status :active + cancel_at_period_end: true)
#    processor_id "sub_e2e_edge_canceling"
# ---------------------------------------------------------------------------

_canceling_sub =
  upsert.(Subscription, &Subscription.changeset/2, "sub_e2e_edge_canceling", %{
    customer_id: long_name_customer.id,
    status: :active,
    cancel_at_period_end: true,
    current_period_end: DateTime.add(now, 7 * 86_400, :second),
    lock_version: 1,
    metadata: %{},
    data: %{}
  })

# ---------------------------------------------------------------------------
# 4. JPY CHARGE (zero-decimal multi-currency)
#    processor_id "ch_e2e_edge_jpy"
# ---------------------------------------------------------------------------

_jpy_charge =
  upsert.(Charge, &Charge.changeset/2, "ch_e2e_edge_jpy", %{
    customer_id: long_name_customer.id,
    subscription_id: at_risk_sub.id,
    currency: "jpy",
    amount_cents: 55_000,
    status: "succeeded",
    lock_version: 1,
    metadata: %{},
    data: %{}
  })

# ---------------------------------------------------------------------------
# 5. JPY INVOICE (:open status)
#    Uses Invoice.changeset/2 — :open is a non-terminal status and
#    new-record transitions (data.status == nil) pass validation for any
#    status. Reserve force_status_changeset/2 for terminal statuses only.
#    processor_id "in_e2e_edge_jpy"
# ---------------------------------------------------------------------------

_jpy_invoice =
  upsert.(Invoice, &Invoice.changeset/2, "in_e2e_edge_jpy", %{
    customer_id: long_name_customer.id,
    subscription_id: at_risk_sub.id,
    status: :open,
    number: "EDGE-JPY-001",
    currency: "jpy",
    total_minor: 55_000,
    total_cents: 55_000,
    amount_due_minor: 55_000,
    amount_paid_minor: 0,
    amount_remaining_minor: 55_000,
    collection_method: "charge_automatically",
    total_discount_amounts: %{},
    metadata: %{},
    data: %{}
  })

# ---------------------------------------------------------------------------
# STATE-MATRIX cells populated by this file (host:edge_states.exs):
#
#   CustomersLive     — Long-strings, Dunning/At-risk, Dark-contrast
#   SubscriptionsLive — Dunning/At-risk, Long-strings, Dark-contrast
#   InvoicesLive      — Multi-currency (¥55,000), Long-strings, Dark-contrast
#   ChargesLive       — Multi-currency (¥ symbol), Long-strings
#   CustomerLive      — Dunning/At-risk, Long-strings, Dark-contrast
#   SubscriptionLive  — Dunning/At-risk, Long-strings, Dark-contrast
#   InvoiceLive       — Multi-currency (zero-decimal JPY), Long-strings, Dark-contrast
#   ChargeLive        — Multi-currency (¥ symbol), Long-strings
#   RecoveryLive      — Populated, Dunning/At-risk, Dark-contrast
#   CampaignLive      — Populated, Dunning/At-risk, Dark-contrast
#   DashboardLive     — Dunning/At-risk (sidebar Recovery badge), Dark-contrast
# ---------------------------------------------------------------------------

:ok
