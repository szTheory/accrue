# Phase 49 — Technical Research

**Question:** What do we need to know to plan **ADM-02/ADM-03** drill polish for **`SubscriptionLive`**?

## RESEARCH COMPLETE

---

## 1. Baseline asymmetry (verified)

| Surface | Breadcrumb pattern | Customer in trail? |
|---------|-------------------|-------------------|
| `InvoiceLive` | `Dashboard` → `Invoices` → **Customer** → invoice label | Yes — **`ScopedPath.build`** on each `href` |
| `SubscriptionLive` (today) | `Dashboard` → `Subscriptions` → subscription id | **No** — operator loses “who is this for?” vs index |

Source: `accrue_admin/lib/accrue_admin/live/invoice_live.ex` ~133–142 vs `subscription_live.ex` ~129–137.

---

## 2. Org-safe path helper

**`AccrueAdmin.ScopedPath.build/4`** appends **`?org=slug`** in **organization** owner mode. **`InvoiceLive`** uses it for breadcrumbs; **`SubscriptionLive`** today uses **`scoped_mount_path/3`** (parallel logic). Planning recommendation: **standardize subscription breadcrumbs on `ScopedPath.build`** so one code path matches **048-CONTEXT** “ScopedPath / existing scope helpers”.

---

## 3. Honest deep links for “Related billing” (query parity)

| Target list | Query param | Supported in `decode_filter`? | Honest for “this subscription’s customer”? |
|-------------|-------------|----------------------------------|---------------------------------------------|
| Invoices | `customer_id` | **Yes** — `AccrueAdmin.Queries.Invoices` | **Yes** — same `customer_id` as subscription’s customer |
| Charges | `customer_id` | **Yes** — `AccrueAdmin.Queries.Charges` | **Yes** |
| Invoices | `subscription_id` | **No** — not in `decode_filter` / `filter_query` | **Do not ship** |
| Charges | `subscription_id` | **No** | **Do not ship** |
| Events | `subject_id` + `Subscription` | **Partial** — `subject_type` exists; **`subject_id` filter not in `decode_filter`** | **Index-only** **`/events`** or neutral copy |

---

## 4. Tests already in place

- **`accrue_admin/test/accrue_admin/live/subscription_live_test.exs`** — extend with **`Phoenix.LiveViewTest`** assertions on **`href`** in rendered HTML for breadcrumbs + related region.
- **`examples/accrue_host/test/accrue_host_web/admin_mount_test.exs`** — pattern for mounted **`/billing`** + org session; add **one** path that hits **`/billing/subscriptions/:id`** (or mount-relative equivalent per host router).

---

## 5. ADM-03 (README)

**049-CONTEXT D-08** forbids nav structure edits; **D-09** allows README clarification when **router truth** vs **sidebar curation** could confuse contributors. Router SSOT: **`accrue_admin/lib/accrue_admin/router.ex`**. README: **`accrue_admin/README.md`** — update only if Phase 49 work would otherwise make the **Admin routes** table **incorrect** (unlikely if routes unchanged) **or** add a **short** note explaining **sidebar order ≠ router order** per discussion in **049-CONTEXT**.

---

## Validation Architecture

> Nyquist / execution sampling: dimension mapping for **`049-VALIDATION.md`**.

| Dimension | Phase 49 signal | Automated anchor |
|-----------|-----------------|------------------|
| D1 Goal | ADM-02 drill smoother | `mix test` in `accrue_admin` + `examples/accrue_host` |
| D2 Regression | No nav structure diff | `rg` on `nav.ex` — no new `sidebar` item arrays changed (plan uses explicit acceptance) |
| D3 Security / scope | Org links never drop `org` | LiveView tests assert query string contains `org=` when fixture uses org scope |
| D4 Honesty | No fake subscription filters | `rg` forbids `subscription_id=` in new `ScopedPath` calls from `SubscriptionLive` |
| D5 A11y | Related region labeled | `html =~` or `element` + `aria-label` attribute test |
| D6 Copy SSOT | No raw English in HEEx for new strings | `rg` Copy function names in `subscription_live.ex` |
| D7 Performance | No N+1 in plan | Reuse **`assign(:customer, subscription.customer)`** — no extra preload pass required for links |
| D8 Nyquist continuity | Every task has automated verify | See **`049-VALIDATION.md`** per-task map |

---

## Sources

- `.planning/phases/49-drill-flows-navigation/049-CONTEXT.md`
- `.planning/phases/48-admin-metering-billing-signals/48-CONTEXT.md`
- `accrue_admin/lib/accrue_admin/queries/invoices.ex`
- `accrue_admin/lib/accrue_admin/queries/charges.ex`
- `accrue_admin/lib/accrue_admin/queries/events.ex`
