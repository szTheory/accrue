# Showcase enrichment seed.
#
# Adds realistic billing records (invoices, charges, refunds, coupons,
# promotion codes, a few extra subscription states, and ledger events) tied to
# the hero demo customers so every admin screen renders meaningful content.
#
# FULLY IDEMPOTENT: every record is keyed on a deterministic processor_id (or
# idempotency_key for events) and inserted via get-or-insert / on_conflict, so
# re-running this file any number of times never duplicates rows.
#
# All amounts and dates are deterministic (no randomness, no wall-clock reads
# beyond the single `now` anchor) so the demo looks identical on every reset.

alias AccrueHost.Repo

alias Accrue.Billing.{
  Charge,
  Coupon,
  Customer,
  Invoice,
  PromotionCode,
  Refund,
  Subscription
}

import Ecto.Query

now = Accrue.Clock.utc_now()
days_ago = fn days -> DateTime.add(now, -days * 86_400, :second) end

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Resolve a hero customer by its organization slug. The hero_accounts seed
# creates these via subscribe/2; we only read here so the showcase stays
# decoupled from the processor. Returns nil if the hero org/customer is absent
# (e.g. showcase run before hero_accounts) — callers skip gracefully.
customer_for_slug = fn slug ->
  case Repo.get_by(AccrueHost.Accounts.Organization, slug: slug) do
    nil ->
      nil

    org ->
      Repo.one(
        from(c in Customer,
          where: c.owner_type == "Organization" and c.owner_id == ^to_string(org.id),
          limit: 1
        )
      )
  end
end

# The newest subscription for a customer — used to tie charges/invoices to a sub.
sub_for_customer = fn
  nil ->
    nil

  %Customer{id: cid} ->
    Repo.one(
      from(s in Subscription,
        where: s.customer_id == ^cid,
        order_by: [desc: s.inserted_at],
        limit: 1
      )
    )
end

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

# Coupons have no processor_id uniqueness in this schema's changeset, so key on
# processor_id via get_by for idempotency.
upsert_coupon = fn processor_id, attrs ->
  case Repo.get_by(Coupon, processor: "fake", processor_id: processor_id) do
    nil ->
      attrs = attrs |> Map.put(:processor, "fake") |> Map.put(:processor_id, processor_id)
      Coupon.changeset(%Coupon{}, attrs) |> Repo.insert!()

    existing ->
      existing
  end
end

# Refunds key on stripe_id (no processor field on the schema).
upsert_refund = fn stripe_id, attrs ->
  case Repo.get_by(Refund, stripe_id: stripe_id) do
    nil ->
      attrs = Map.put(attrs, :stripe_id, stripe_id)
      Refund.changeset(%Refund{}, attrs) |> Repo.insert!()

    existing ->
      existing
  end
end

# Append-only event insert keyed on idempotency_key (mirrors hero_accounts
# helper). NOTE: keys are prefixed "seed-showcase-" so they never collide with
# the "seed-dunning-" events the idempotency test counts.
record_event = fn attrs, idempotency_key, at ->
  row =
    attrs
    |> Map.put(:idempotency_key, idempotency_key)
    |> Map.put(:inserted_at, at)
    |> Map.put_new(:actor_type, "system")
    |> Map.put_new(:schema_version, 1)
    |> Map.put_new(:data, %{})

  Repo.insert_all(Accrue.Events.Event, [row],
    on_conflict: :nothing,
    conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
  )

  :ok
end

# Resolve hero customers once.
healthy = customer_for_slug.("healthy-co")
past_due = customer_for_slug.("past-due-co")
canceled = customer_for_slug.("canceled-co")
enterprise = customer_for_slug.("enterprise-co")
trialing = customer_for_slug.("trialing-co")

# ---------------------------------------------------------------------------
# INVOICES — one per status, varied amounts & currencies (incl. JPY zero-decimal)
# ---------------------------------------------------------------------------

invoice_specs = [
  # {processor_id, customer, attrs}
  {"in_showcase_draft", healthy,
   %{
     status: :draft,
     number: "DEMO-DRAFT-0001",
     currency: "usd",
     subtotal_minor: 4900,
     tax_minor: 0,
     total_minor: 4900,
     total_cents: 4900,
     amount_due_minor: 4900,
     amount_paid_minor: 0,
     amount_remaining_minor: 4900,
     billing_reason: "subscription_cycle",
     collection_method: "charge_automatically",
     period_start: days_ago.(2),
     period_end: days_ago.(0)
   }},
  {"in_showcase_open", past_due,
   %{
     status: :open,
     number: "DEMO-OPEN-0002",
     currency: "usd",
     subtotal_minor: 12_000,
     tax_minor: 960,
     total_minor: 12_960,
     total_cents: 12_960,
     amount_due_minor: 12_960,
     amount_paid_minor: 0,
     amount_remaining_minor: 12_960,
     due_date: days_ago.(-5),
     billing_reason: "subscription_cycle",
     collection_method: "send_invoice",
     finalized_at: days_ago.(8),
     period_start: days_ago.(38),
     period_end: days_ago.(8)
   }},
  {"in_showcase_paid_usd", healthy,
   %{
     status: :paid,
     number: "DEMO-PAID-0003",
     currency: "usd",
     subtotal_minor: 4900,
     tax_minor: 392,
     total_minor: 5292,
     total_cents: 5292,
     amount_due_minor: 5292,
     amount_paid_minor: 5292,
     amount_remaining_minor: 0,
     paid_at: days_ago.(30),
     finalized_at: days_ago.(33),
     billing_reason: "subscription_cycle",
     collection_method: "charge_automatically",
     period_start: days_ago.(63),
     period_end: days_ago.(33)
   }},
  {"in_showcase_paid_jpy", enterprise,
   %{
     status: :paid,
     number: "DEMO-PAID-JPY-0004",
     currency: "jpy",
     subtotal_minor: 50_000,
     tax_minor: 5000,
     total_minor: 55_000,
     total_cents: 55_000,
     amount_due_minor: 55_000,
     amount_paid_minor: 55_000,
     amount_remaining_minor: 0,
     paid_at: days_ago.(20),
     finalized_at: days_ago.(22),
     billing_reason: "subscription_create",
     collection_method: "charge_automatically",
     period_start: days_ago.(52),
     period_end: days_ago.(22)
   }},
  {"in_showcase_void", canceled,
   %{
     status: :void,
     number: "DEMO-VOID-0005",
     currency: "usd",
     subtotal_minor: 4900,
     tax_minor: 0,
     total_minor: 4900,
     total_cents: 4900,
     amount_due_minor: 4900,
     amount_paid_minor: 0,
     amount_remaining_minor: 0,
     voided_at: days_ago.(12),
     finalized_at: days_ago.(15),
     billing_reason: "subscription_cycle",
     collection_method: "charge_automatically",
     period_start: days_ago.(45),
     period_end: days_ago.(15)
   }},
  {"in_showcase_uncollectible", past_due,
   %{
     status: :uncollectible,
     number: "DEMO-UNCOLL-0006",
     currency: "usd",
     subtotal_minor: 12_000,
     tax_minor: 960,
     total_minor: 12_960,
     total_cents: 12_960,
     amount_due_minor: 12_960,
     amount_paid_minor: 0,
     amount_remaining_minor: 12_960,
     finalized_at: days_ago.(40),
     billing_reason: "subscription_cycle",
     collection_method: "charge_automatically",
     period_start: days_ago.(70),
     period_end: days_ago.(40)
   }}
]

for {pid, customer, attrs} <- invoice_specs, customer != nil do
  attrs = Map.put(attrs, :customer_id, customer.id)
  upsert.(Invoice, &Invoice.force_status_changeset/2, pid, attrs)
end

# ---------------------------------------------------------------------------
# CHARGES — succeeded / refunded / failed, with fee fields
# ---------------------------------------------------------------------------

charge_specs = [
  {"ch_showcase_succeeded", healthy,
   %{
     status: "succeeded",
     amount_cents: 5292,
     currency: "usd",
     stripe_fee_amount_minor: 183,
     stripe_fee_currency: "usd",
     fees_settled_at: days_ago.(29)
   }},
  {"ch_showcase_refunded", healthy,
   %{
     status: "succeeded",
     amount_cents: 9900,
     currency: "usd",
     stripe_fee_amount_minor: 317,
     stripe_fee_currency: "usd",
     fees_settled_at: days_ago.(18)
   }},
  {"ch_showcase_partial_refunded", enterprise,
   %{
     status: "succeeded",
     amount_cents: 20_000,
     currency: "usd",
     stripe_fee_amount_minor: 610,
     stripe_fee_currency: "usd",
     fees_settled_at: days_ago.(10)
   }},
  {"ch_showcase_failed", past_due,
   %{
     status: "failed",
     amount_cents: 12_960,
     currency: "usd"
   }}
]

charges_by_pid =
  for {pid, customer, attrs} <- charge_specs, customer != nil, into: %{} do
    attrs = Map.put(attrs, :customer_id, customer.id)
    {pid, upsert.(Charge, &Charge.changeset/2, pid, attrs)}
  end

# ---------------------------------------------------------------------------
# REFUNDS — one full, one partial (with fee reconciliation fields)
# ---------------------------------------------------------------------------

if charge = charges_by_pid["ch_showcase_refunded"] do
  upsert_refund.("re_showcase_full", %{
    charge_id: charge.id,
    processor_id: "re_showcase_full",
    amount_minor: 9900,
    currency: "usd",
    reason: "requested_by_customer",
    status: :succeeded,
    stripe_fee_refunded_amount_minor: 317,
    merchant_loss_amount_minor: 0,
    fees_settled_at: days_ago.(17)
  })
end

if charge = charges_by_pid["ch_showcase_partial_refunded"] do
  upsert_refund.("re_showcase_partial", %{
    charge_id: charge.id,
    processor_id: "re_showcase_partial",
    amount_minor: 5000,
    currency: "usd",
    reason: "duplicate",
    status: :succeeded,
    stripe_fee_refunded_amount_minor: 0,
    merchant_loss_amount_minor: 153,
    fees_settled_at: days_ago.(9)
  })
end

# ---------------------------------------------------------------------------
# COUPONS — percent-off, amount-off, and an expired/invalid one
# ---------------------------------------------------------------------------

percent_coupon =
  upsert_coupon.("coupon_showcase_pct", %{
    name: "Launch 25% Off",
    percent_off: Decimal.new("25"),
    duration: "repeating",
    duration_in_months: 3,
    max_redemptions: 100,
    times_redeemed: 12,
    valid: true
  })

amount_coupon =
  upsert_coupon.("coupon_showcase_amt", %{
    name: "$10 Welcome Credit",
    amount_off_cents: 1000,
    amount_off_minor: 1000,
    currency: "usd",
    duration: "once",
    max_redemptions: 500,
    times_redeemed: 87,
    valid: true
  })

_expired_coupon =
  upsert_coupon.("coupon_showcase_expired", %{
    name: "Black Friday (expired)",
    percent_off: Decimal.new("40"),
    duration: "once",
    redeem_by: days_ago.(30),
    max_redemptions: 1000,
    times_redeemed: 642,
    valid: false
  })

# ---------------------------------------------------------------------------
# PROMOTION CODES — active + redeemed/inactive, linked to coupons
# ---------------------------------------------------------------------------

if percent_coupon do
  upsert.(PromotionCode, &PromotionCode.changeset/2, "promo_showcase_active", %{
    code: "LAUNCH25",
    coupon_id: percent_coupon.id,
    active: true,
    max_redemptions: 100,
    times_redeemed: 12,
    expires_at: days_ago.(-60)
  })
end

if amount_coupon do
  upsert.(PromotionCode, &PromotionCode.changeset/2, "promo_showcase_inactive", %{
    code: "WELCOME10",
    coupon_id: amount_coupon.id,
    active: false,
    max_redemptions: 500,
    times_redeemed: 500,
    expires_at: days_ago.(15)
  })
end

# ---------------------------------------------------------------------------
# SUBSCRIPTIONS — add paused / unpaid / incomplete states on hero customers.
# These are additional rows (deterministic processor_ids) so the existing hero
# subscriptions are untouched. Inserted via force_status_changeset (bypasses
# user-path transition guards) since they are seeded into a terminal-ish state.
# ---------------------------------------------------------------------------

extra_sub_specs = [
  {"sub_showcase_paused", enterprise,
   %{
     status: :paused,
     paused_at: days_ago.(6),
     pause_behavior: "void",
     current_period_start: days_ago.(36),
     current_period_end: days_ago.(6)
   }},
  {"sub_showcase_unpaid", past_due,
   %{
     status: :unpaid,
     past_due_since: days_ago.(14),
     current_period_start: days_ago.(44),
     current_period_end: days_ago.(14)
   }},
  {"sub_showcase_incomplete", trialing,
   %{
     status: :incomplete,
     current_period_start: days_ago.(1),
     current_period_end: days_ago.(-29)
   }}
]

# IMPORTANT: these extra subscriptions are inserted with a back-dated
# `inserted_at` so they are always OLDER than the hero subscription on the same
# customer. `AccrueHost.Billing.current_subscription/1` returns the newest
# subscription by `inserted_at`, so back-dating guarantees these demo rows never
# shadow the hero subscription (which carries the dunning anchor the demo/tests
# depend on) while still rendering on list/detail screens.
sub_backdate = days_ago.(120)

for {pid, customer, attrs} <- extra_sub_specs, customer != nil do
  case Repo.get_by(Subscription, processor: "fake", processor_id: pid) do
    nil ->
      attrs =
        attrs
        |> Map.put(:customer_id, customer.id)
        |> Map.put(:processor, "fake")
        |> Map.put(:processor_id, pid)

      %Subscription{}
      |> Subscription.force_status_changeset(attrs)
      |> Ecto.Changeset.put_change(:inserted_at, sub_backdate)
      |> Ecto.Changeset.put_change(:updated_at, sub_backdate)
      |> Repo.insert!()

    _existing ->
      :ok
  end
end

# ---------------------------------------------------------------------------
# LEDGER EVENTS — a handful tied to the new records so the Event log + the
# per-record "events" links render data. Keyed under "seed-showcase-" so they
# never collide with (or inflate the count of) the "seed-dunning-" events.
# ---------------------------------------------------------------------------

paid_invoice = Repo.get_by(Invoice, processor: "fake", processor_id: "in_showcase_paid_usd")

if paid_invoice do
  record_event.(
    %{
      type: "invoice.paid",
      subject_type: "Invoice",
      subject_id: paid_invoice.id,
      data: %{amount_paid_minor: 5292, currency: "usd"}
    },
    "seed-showcase-invoice-paid-usd",
    days_ago.(30)
  )
end

if charge = charges_by_pid["ch_showcase_succeeded"] do
  record_event.(
    %{
      type: "charge.succeeded",
      subject_type: "Charge",
      subject_id: charge.id,
      data: %{amount_cents: 5292, currency: "usd"}
    },
    "seed-showcase-charge-succeeded",
    days_ago.(30)
  )
end

if charge = charges_by_pid["ch_showcase_refunded"] do
  record_event.(
    %{
      type: "charge.refunded",
      subject_type: "Charge",
      subject_id: charge.id,
      data: %{amount_refunded_minor: 9900, currency: "usd"}
    },
    "seed-showcase-charge-refunded",
    days_ago.(17)
  )
end

if charge = charges_by_pid["ch_showcase_failed"] do
  record_event.(
    %{
      type: "charge.failed",
      subject_type: "Charge",
      subject_id: charge.id,
      data: %{amount_cents: 12_960, currency: "usd", failure_code: "card_declined"}
    },
    "seed-showcase-charge-failed",
    days_ago.(5)
  )
end

:ok
