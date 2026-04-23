# VERIFY-01 — v1.12 materially touched admin paths

Mounted admin base path is typically **`/billing`** (host-configurable). Organization-scoped screens append **`?org=<slug>`** using the fixture / session slug pattern from **`examples/accrue_host`**.

Union of v1.12 surfaces exercised by merge-blocking VERIFY-01 and related drills:

1. **Dashboard (billing home)** — after **“Go to billing”**, root under the mount, e.g. **`/billing?org=<slug>`** (exact home URL depends on host router; treat as dashboard entry tied to the billing mount).
2. **Customers index** — **`/billing/customers?org=<slug>`**
3. **Subscriptions index** — **`/billing/subscriptions?org=<slug>`**
4. **Subscription detail** — **`/billing/subscriptions/:id?org=<slug>`** (canonical drill target for **SubscriptionLive**).

Use placeholders (`:id`, `<slug>`) in docs and tickets — never paste live customer IDs or processor identifiers.

## v1.13 auxiliary (Phase 53)

Mounted paths added for **AUX-03..AUX-06** (Connect, billing events, coupons, promotion codes) under the same **`/billing`** mount and **`?org=<slug>`** org scope as VERIFY-01 v1.12 flows:

- **`/billing/connect?org=<slug>`**
- **`/billing/connect/:id?org=<slug>`** (fixture `connect_account_id` from **`scripts/ci/accrue_host_seed_e2e.exs`**)
- **`/billing/events?org=<slug>`**
- **`/billing/coupons?org=<slug>`**
- **`/billing/promotion-codes?org=<slug>`**

### VERIFY-01 spec mapping (`verify01-admin-a11y.spec.js`)

| `test.describe` title (exact) | Mounted path template | Requirement ids |
|--------------------------------|------------------------|-------------------|
| VERIFY-01 admin Connect index (auxiliary) | `/billing/connect?org=<slug>` | AUX-03, AUX-06 |
| VERIFY-01 admin Connect account detail (auxiliary) | `/billing/connect/:id?org=<slug>` | AUX-03, AUX-06 |
| VERIFY-01 admin billing events index (auxiliary) | `/billing/events?org=<slug>` | AUX-04, AUX-06 |
| VERIFY-01 admin coupons index (auxiliary) | `/billing/coupons?org=<slug>` | AUX-01, AUX-06 |
| VERIFY-01 admin promotion codes index (auxiliary) | `/billing/promotion-codes?org=<slug>` | AUX-02, AUX-06 |

## Phase 55 — v1.14 ADM-08 invoice anchor (merge-blocking)

`verify01-admin-a11y.spec.js` carries **merge-blocking** Playwright + axe coverage for the **core** invoice surfaces under the same **`/billing`** mount and **`?org=<slug>`** org scope as other VERIFY-01 rows.

| `test.describe` title (exact) | Mounted path template | Requirement ids |
|--------------------------------|------------------------|-----------------|
| `core-admin-invoices-index` | `/billing/invoices?org=<slug>` | ADM-09 |
| `core-admin-invoices-detail` | `/billing/invoices/:id?org=<slug>` | ADM-09 |
