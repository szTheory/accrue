# VERIFY-01 — v1.12 materially touched admin paths

Mounted admin base path is typically **`/billing`** (host-configurable). Organization-scoped screens append **`?org=<slug>`** using the fixture / session slug pattern from **`examples/accrue_host`**.

Union of v1.12 surfaces exercised by merge-blocking VERIFY-01 and related drills:

1. **Dashboard (billing home)** — after **“Go to billing”**, root under the mount, e.g. **`/billing?org=<slug>`** (exact home URL depends on host router; treat as dashboard entry tied to the billing mount).
2. **Customers index** — **`/billing/customers?org=<slug>`**
3. **Subscriptions index** — **`/billing/subscriptions?org=<slug>`**
4. **Subscription detail** — **`/billing/subscriptions/:id?org=<slug>`** (canonical drill target for **SubscriptionLive**).

Use placeholders (`:id`, `<slug>`) in docs and tickets — never paste live customer IDs or processor identifiers.
