# Customer Portal Configuration Checklist (CHKT-05)

This guide documents the three Stripe Dashboard toggles every Accrue
host app **must** enable on its Customer Billing Portal configuration
before going live. All three close revenue-recovery loopholes that the
default portal config leaves wide open.

## Background — the "cancel without dunning" footgun

Stripe's out-of-the-box Customer Portal lets customers cancel
**immediately** with one click and zero friction. From the host app's
point of view, this turns the portal into a "cancel my account" button
that bypasses every dunning workflow Accrue offers
(`Accrue.Billing.Dunning`, `[:accrue, :ops, :dunning_exhaustion]`,
grace periods, retain-offer flows, and so on).

Pitfall 6 of the Phase 4 research is exactly this: the portal's
defaults erase the entire revenue-recovery surface unless three
specific toggles are flipped in the Stripe Dashboard. Flipping them is
free, takes 30 seconds, and is a one-time per-mode (test + live)
action.

**Programmatic configuration via `BillingPortal.Configuration` is
deferred to a future processor release.** Until then this guide is the
canonical install-time checklist — same convention as Pay (Rails) and
Cashier (Laravel).

## The three required toggles

Open the Stripe Dashboard → **Settings → Billing → Customer portal**
in *both* test mode and live mode and configure the following:

### 1. Retain offers — **ENABLED**

Section: **Cancellations → Retain offers**.

Action: enable at least one retain offer (e.g. "50% off the next
month", "switch to annual for 20% off"). Stripe presents the offer to
customers who click cancel before processing the cancellation.

Why: this is the single highest-impact lever in the entire portal.
Empirically, retain offers convert ~10–25% of cancellations into
saves. With it disabled the portal cancels with no resistance.

### 2. Require cancellation reason — **ENABLED**

Section: **Cancellations → Cancellation reason**.

Action: toggle "Ask for a cancellation reason" on. Choose either
"required" or "optional with reasons list" — required is strongly
preferred for the survey signal.

Why: gives the host app a structured `cancellation_details.reason`
field on the resulting `customer.subscription.deleted` /
`customer.subscription.updated` webhook payload. Without this you have
no churn-reason data to feed back into product / pricing / support.

### 3. Cancellation timing — `at_period_end` (NOT immediate)

Section: **Cancellations → When to cancel**.

Action: select **"At end of billing period"**. Do **NOT** select
"Immediately".

Why: with "Immediately" selected the customer is refunded prorated
charges and loses access on the spot. With `at_period_end` the
customer keeps access through the period they already paid for, the
subscription transitions to `cancel_at_period_end: true`, and
`Accrue.Billing.subscription_canceling?/1` returns true so the host
app can trigger any "we're sorry to see you go" mailers, retention
campaigns, or win-back flows during the grace period.

This is also the only setting that makes
`Accrue.Billing.uncancel/2` (BILL-08) useful — you can't un-cancel a
subscription that has already been hard-deleted.

## Verifying the checklist

After flipping all three toggles, click "Save" in the Dashboard.
Stripe assigns the new configuration a `bpc_*` id which you can find
under **Settings → Billing → Customer portal → Active configuration**.

To pin Accrue to that exact configuration (recommended for production
so a future Dashboard edit can't silently reset the toggles), pass
the id to `Accrue.BillingPortal.Session.create/1`:

```elixir
{:ok, session} =
  Accrue.BillingPortal.Session.create(%{
    customer: current_user.customer,
    return_url: url(~p"/account"),
    configuration: "bpc_1Nx9aB2eZvKYlo2C..."
  })
```

If `:configuration` is omitted Stripe uses the account default — fine
for development, risky for production because a future Dashboard edit
to the default config silently affects every portal session.

## Future programmatic support

When `BillingPortal.Configuration` lands in a future processor
release, this checklist will be replaced (additively, no breaking
change) with an `Accrue.BillingPortal.Configuration.create/1` helper
that ensures the three toggles are set in code. Until then the
Dashboard checklist above is the source of truth.

## See also

- `Accrue.BillingPortal.Session` — wrapper module
- `Accrue.Billing.Dunning` — the revenue-recovery surface that these
  toggles protect
- Phase 4 Plan 07 PLAN/SUMMARY — full requirement traceability
  (CHKT-04, CHKT-05, CHKT-06)
