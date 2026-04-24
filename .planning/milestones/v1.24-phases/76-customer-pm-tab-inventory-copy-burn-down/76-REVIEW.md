---
status: clean
phase: 76
depth: standard
reviewed: "2026-04-24"
---

# Phase 76 — Code review

## Scope

Plans **76-01** (docs / inventory) and **76-02** (`AccrueAdmin.Copy.CustomerPaymentMethods`, `CustomerLive` `payment_methods` branch, ExUnit, `export_copy_strings` allowlist, generated JSON).

## Findings

None material. **Scope guard:** `payment_methods` branch is the only `customer_live.ex` region touched for literals; deferred strings (**`No charges projected yet.`**, subscriptions KPI delta) remain unchanged.

## Notes

- Local **`mix test`** for **`accrue_admin`** requires Postgres credentials (e.g. **`PGUSER=jon`**) per **`config/test.exs`**.
