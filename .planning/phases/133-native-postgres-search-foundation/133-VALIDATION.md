# Phase 133: Native Postgres Search Foundation Validation

This file ensures nyquist_compliance by establishing automated verification testing commands for the native Postgres search capabilities.

## Automated Verification Tests

### 1. SRCH-01: pg_trgm Extension and Search Indices
**Command:** `cd accrue && mix ecto.migrations | grep -i "pg_trgm"`
**Purpose:** Ensures that an Ecto migration adding the `pg_trgm` PostgreSQL extension and necessary GIN indices on the `accrue_customers`, `accrue_subscriptions`, and `accrue_invoices` tables is present and applied.

### 2. SRCH-02: Billing Search API Implementation
**Command:** `cd accrue && mix test test/accrue/billing/search_test.exs`
**Purpose:** Validates that the `Accrue.Billing` context (or its `Search` delegate module) exposes search APIs (`search_customers`, etc.) backed by `pg_trgm` similarity queries, returning bounded and ranked results.

### 3. Code Format and Compilation
**Command:** `cd accrue && mix compile && mix format --check-formatted`
**Purpose:** General nyquist validation ensuring the new implementation files and tests compile cleanly without formatting regressions.