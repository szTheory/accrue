---
status: passed
phase: 27-microcopy-and-operator-strings
verified: 2026-04-20
---

# Phase 27 — Verification

## Automated

- `cd accrue_admin && mix test` — **PASS** (full package suite after plans 27-01–27-03).
- Plan-scoped tests from `27-01-PLAN.md`, `27-02-PLAN.md`, and `27-03-PLAN.md` verification sections — **PASS** during execution.

## Coverage (requirements)

| ID       | Evidence in this phase |
| -------- | ------------------------ |
| **COPY-01** | Centralized strings in `accrue_admin/lib/accrue_admin/copy.ex` and empty-state copy on `accrue_admin/lib/accrue_admin/components/data_table.ex`, wired through the money index LiveViews `customers_live.ex`, `subscriptions_live.ex`, `invoices_live.ex`, and `charges_live.ex`; ExUnit coverage under `accrue_admin/test/accrue_admin/live/` exercises those empty states (plan 27-01). |
| **COPY-02** | Operator-facing literals in `accrue_admin/lib/accrue_admin/copy/locked.ex` plus money-detail flashes on LiveViews such as `subscription_live.ex` and `customer_live.ex` (and related detail surfaces in `invoice_live.ex` / `charge_live.ex`) per plan 27-02. |
| **COPY-03** | `accrue_admin/lib/accrue_admin/copy.ex` remains the SSOT for user-visible copy alongside `accrue_admin/lib/accrue_admin/copy/locked.ex`; `webhooks_live.ex` / `webhook_live.ex` preserve stable webhook literals with tests cited in `27-03-SUMMARY.md` across plans 27-01..03. |

## Notes

- Host Playwright (`examples/accrue_host`) not re-run in this session; webhook literals preserved and package tests lock replay copy.
