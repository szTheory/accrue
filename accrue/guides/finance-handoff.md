# Finance handoff: Stripe-native reporting

This guide is for **Phoenix teams using Accrue as billing orchestration** who need
finance, tax, and revenue operations to live in **Stripe and downstream analytics** —
not inside Accrue's database as a parallel ledger.

Accrue models **billing state** (subscriptions, invoices, payments, tax-location
health, and an append-only audit trail). It does **not** implement GAAP revenue
recognition, deferred revenue schedules, or general-ledger postings.

## Stripe Revenue Recognition (Stripe RR)

Use [Stripe Revenue Recognition](https://docs.stripe.com/revenue-recognition) when
you need **accrual-style revenue reporting inside Stripe** from Stripe Billing
objects (subscriptions, invoices, line items) that Accrue already keeps in sync with
the processor.

**When it fits**

- Finance wants month-by-month recognized revenue tied to **Stripe** as the system of
  record for billings.
- You are comfortable with Stripe's RR product rules and exclusions (see Stripe docs
  for current coverage of usage meters, credits, multi-currency edge cases, etc.).

**What you correlate**

- Stripe **Customer**, **Subscription**, **Invoice**, **Invoice line item**, and
  **PaymentIntent** / **Charge** IDs already flow through Accrue's processor adapters.
- Accrue's local rows mirror those IDs in `processor_id` fields and related
  projections — use them to join Accrue operational views to Stripe RR exports **only
  for the same Stripe account** you configured on the host.

Accrue does **not** compute recognized revenue amounts; Stripe RR does.

## Sigma (scheduled SQL over Stripe data)

Use [Sigma](https://docs.stripe.com/stripe-data/sigma) when finance or data teams need
**repeatable SQL reports** over Stripe-hosted billing and payment facts (MRR
movement, churn cohorts, tax by jurisdiction, etc.) without building a warehouse first.

**When it fits**

- Reporting stays **inside Stripe's query product** with scheduled delivery.
- You want parameterized queries over canonical Stripe tables, not ad-hoc pulls from
  Accrue's Postgres.

**Caveat**

Sigma answers questions about **Stripe objects**. Accrue may hold short-lived
operational fields (for example automatic-tax disabled reasons) that are not Sigma
tables — for those, export from your **host-authorized** application database if
needed, not from Accrue as a hosted SaaS.

## Stripe Data Pipeline (warehouse export)

Use the [Stripe Data Pipeline](https://docs.stripe.com/stripe-data/access-data-in-warehouse)
when you need **Stripe facts in Snowflake / BigQuery / Redshift** (or the supported
destinations Stripe documents) for BI, forecasting, or ERP *staging*.

**When it fits**

- Finance wants a **warehouse** as the analytics layer, with Stripe as the ingestion
  source.
- You will model joins between Stripe pipeline tables and your **host** dimensions
  (accounts, organizations, internal SKUs).

Accrue does not run the pipeline or warehouse jobs; it stays the **Elixir billing
orchestration** layer that keeps Stripe consistent with your host's product state.

## Mapping Accrue concepts to Stripe (and your host)

| Accrue / host concern | Typical join keys | Notes |
|----------------------|-------------------|--------|
| Billable (e.g. `User`, `Organization`) | Host issues Stripe **Customer**; Accrue stores `processor_id` on `Accrue.Billing.Customer` | Ownership is always `owner_type` + `owner_id` on the host billable. |
| Subscription | Stripe **Subscription** id on local subscription row | Lifecycle events arrive via webhooks Accrue verifies and reduces. |
| Invoice | Stripe **Invoice** id | Tax amounts should follow Stripe's canonical tax fields; see tax guides. |
| Payment / capture | **PaymentIntent** / **Charge** ids | Refunds and fees remain Stripe-sourced. |
| Tax location health | Customer address / tax signals + Stripe automatic-tax state | Accrue surfaces **local** recovery UX; jurisdiction logic stays Stripe Tax. |
| Audit narrative | `accrue_events` (append-only) | Operator and compliance **story** — not a substitute for GL or RR schedules. |

Always join in the context of **one Stripe account** (your platform or connected
account strategy as configured). Accrue never replaces Stripe as the tax or payment
system of record.

## Tax evidence

For Stripe Tax, **evidence and filing obligations** remain with Stripe and your
finance team's processes. Accrue persists **narrow** automatic-tax observability for
subscriptions and invoices so operators can see enablement, disabled reasons, and
finalization failures — use that for **support and engineering**, not as standalone
tax filing evidence.

## Audit ledger (`accrue_events`)

The append-only event feed records **what Accrue did and why** (including webhook and
operator-driven actions). It is invaluable for **support, disputes, and internal
compliance narrative**. It is **not** a double-entry ledger and must not be treated as
GAAP journal entries.

## Boundaries: what Accrue explicitly does *not* do (FIN-02)

- **No Accrue-owned revenue recognition engine** — no ASC 606 / IFRS 15 schedules, no
  standalone "recognized revenue" API from Accrue.
- **No GAAP interpretation** — pairing Stripe RR or your ERP is the finance team's
  domain.
- **No hosted finance CSV product in v1.3** — downloadable exports that mix PII,
  retention, and audience rules belong in **host-owned** product decisions (see FIN-03
  in future milestones).

## wrong-audience finance exports

Any finance-facing export or Sigma query that could expose **another organization's**
billing data must be **host-authorized** (authenticated role, tenant scope, explicit
export action). Accrue's admin and APIs assume the **host application** enforces
organization and membership boundaries; never ship ad-hoc "export all rows" tools
to the wrong internal audience.

If you add exports, treat **audience**, **retention**, and **storage** as first-class
requirements — they are out of scope for Accrue core v1.3 but are called out here so
product teams do not accidentally leak cross-tenant financial detail.

## See also

- [Testing](testing.md) — Fake vs Stripe test vs live Stripe lanes.
- [Testing live Stripe](https://github.com/szTheory/accrue/blob/main/guides/testing-live-stripe.md) — advisory live-mode
  checks at repository root (`guides/` vs package `accrue/guides/`).
- [Troubleshooting](troubleshooting.md) — tax-location and rollout recovery.
