# Phase 26 — Pattern map

**Inputs:** `26-CONTEXT.md`, `26-RESEARCH.md`

---

## Target files → role → closest analog

| Target (modify / test) | Role | Analog (reference) |
|------------------------|------|---------------------|
| `accrue_admin/lib/accrue_admin/live/customers_live.ex` | Money index shell + row signals | `subscriptions_live.ex`, `invoices_live.ex`, `charges_live.ex` |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | Money detail hierarchy | `subscription_live.ex`, `invoice_live.ex`, `charge_live.ex` |
| `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` | Admin list density | `customers_live.ex` (table + KPI header pattern) |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` | Detail + KPI | `invoice_live.ex` (inspector-style sections) |
| `accrue_admin/assets/css/theme.css` | Semantic tokens | Existing `--ax-space-*`, `--ax-base`, chip utilities |
| `accrue_admin/test/accrue_admin/live/*_live_test.exs` | LiveViewTest contracts | `customers_live_test.exs`, `app_shell_test.exs` |
| `.planning/phases/25-admin-ux-inventory/25-INV-03-spec-alignment.md` | Evidence / status rows | Phase 25 plan 03 output format |

---

## Excerpt: list signal cell (current)

`customers_live.ex` — `billing_signals_cell/1` builds two chips; typography class `ax-text-12` is a known mismatch vs `26-UI-SPEC.md` (14px label for chips).

---

## Excerpt: page shell (current)

`customers_live.ex` render — `AppShell.app_shell` … `<section class="ax-page">` … single KPI grid then `DataTable` — **good** top-level shape; other indexes should match after UX-01 edits.

---

## PATTERN MAPPING COMPLETE
