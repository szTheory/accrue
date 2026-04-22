# Phase 49 — Pattern Map

Analogs for **`SubscriptionLive`** drill polish.

---

## Breadcrumbs — gold standard

**File:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex`

```elixir
<Breadcrumbs.breadcrumbs
  items={[
    %{label: "Dashboard", href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)},
    %{label: "Invoices", href: ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope)},
    %{
      label: customer_label(@customer),
      href: ScopedPath.build(@admin_mount_path, "/customers/#{@customer.id}", @current_owner_scope)
    },
    %{label: invoice_label(@invoice)}
  ]}
/>
```

**Apply to:** `subscription_live.ex` — insert **customer** crumb between **Subscriptions** index and terminal subscription label; use **`ScopedPath.build`** for all `href` entries.

---

## Scoped list link with honest filter

**Pattern:** `ScopedPath.build(mount, "/invoices", scope, %{"customer_id" => id})`

**Analog:** `InvoicesLive` + `AccrueAdmin.Queries.Invoices.decode_filter/1` accepts **`customer_id`**.

---

## Customer label helper

**File:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex` — **`customer_label/1`** private near bottom.

**Apply:** Reuse or **duplicate verbatim** in `subscription_live.ex` if not extracted (prefer **private defp** in same module to avoid public API churn unless a shared helper already exists).

---

## Related card chrome

**Pattern:** Existing **`article.ax-card`** blocks inside **`SubscriptionLive`** (e.g. “Admin actions” section ~169+).

**Apply:** New card after **`ax-kpi-grid`** or before **TaxOwnershipCard** — match **`ax-eyebrow` + `ax-heading`** header trio used elsewhere on the page.

---

## Host mount session

**File:** `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` — billing admin + org session + `live(conn, "/billing")`.

**Apply:** Second test follows same fixture pattern but navigates to **`/billing/subscriptions/<id>`** with a subscription id from host repo fixtures (use **`Repo`** + existing factory/fixtures if present; otherwise minimal insert per host test conventions).
