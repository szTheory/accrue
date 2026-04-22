---
status: passed
phase: 49
updated: 2026-04-22
---

# Phase 49 verification

## Must-haves (from plans)

| Criterion | Evidence |
|-----------|----------|
| SubscriptionLive breadcrumbs match InvoiceLive-style trail with customer + ScopedPath | `subscription_live.ex` `Breadcrumbs.breadcrumbs` items; `customer_label/1` matches `InvoiceLive` |
| Related card ≤5 links; `customer_id` only on invoices/charges; no `subscription_id=` | HEEx `article.ax-card` nav + `rg` gate in plan |
| Copy SSOT `subscription_drill_*` | `copy.ex` |
| LiveViewTest asserts `/customers/`, `org=`, `customer_id=` | `subscription_live_test.exs` |
| Host `live/2` on `/billing/subscriptions/:id` | `admin_mount_test.exs` |
| README router vs sidebar | `README.md` Admin routes section |

## Commands run

```bash
cd accrue_admin && mix compile --warnings-as-errors
cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs
cd examples/accrue_host && mix test test/accrue_host_web/admin_mount_test.exs
```

All exited **0**.

## Gaps

None.
