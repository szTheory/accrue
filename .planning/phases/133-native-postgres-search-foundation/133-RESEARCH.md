# Phase 133: Native Postgres Search Foundation - Research

**Researched:** 2024-05-25
**Domain:** Database Search, Elixir/Ecto
**Confidence:** HIGH

## Summary

This phase introduces native text search capabilities to the database tier using PostgreSQL's `pg_trgm` extension. By keeping search inside Postgres with Generalized Inverted (GIN) indices, the application gains robust, fast similarity search without needing external dependencies like Elasticsearch or Meilisearch.

The standard pattern in Elixir/Ecto involves enabling the extension, creating GIN indices with the `gin_trgm_ops` operator class (created concurrently to avoid locking production tables), and exposing unified API queries using Ecto's `fragment/1` macro to execute trigram similarity functions (`%` operator for filtering, `similarity()` for ranking). 

**Primary recommendation:** Use `execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")` in an `@disable_ddl_transaction true` migration. Create specific GIN indices concurrently. In context functions, filter with the `%` similarity operator via `fragment/1` so Postgres uses the index, then order by `GREATEST(similarity(...))` to rank the matched results.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRCH-01 | Ecto migration adds `pg_trgm` and GIN indices on `accrue_customers`, `accrue_subscriptions`, `accrue_invoices` | Supported via `execute "CREATE EXTENSION..."` and Ecto's `create index` with raw string column names (`"email gin_trgm_ops"`) and `concurrently: true`. |
| SRCH-02 | `Accrue.Billing` context exposes `search_*/1` APIs backed by pg_trgm similarity | Supported via Ecto `fragment` using the `%` operator in `where` clauses (for index filtering) and `similarity()` in `order_by` (for result ranking). |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Full Text / Similarity Search | Database / Storage | API / Backend | Trigram indices on Postgres provide highly performant similarity matching. Pushing this to the database layer prevents moving massive amounts of text over the wire for in-memory sorting, and avoids spinning up a separate search service (like Elasticsearch) for straightforward search needs. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PostgreSQL pg_trgm | (Built-in) | Trigram string matching and similarity algorithms. | Standard Postgres extension that provides "fuzzy" search out-of-the-box. |
| Ecto SQL | ~> 3.13 | Database wrapper and query builder. | First-class support for raw SQL fragments and complex index migrations. |

**Installation:**
No new hex packages are required. `pg_trgm` is bundled with PostgreSQL (commonly available on all managed Postgres hosting like RDS, Render, Fly).

## Architecture Patterns

### Pattern 1: Similarity Filtering with Ranking
**What:** Combining a GiST or GIN trigram index with Ecto queries for fast searching.
**When to use:** When you need a "fuzzy search" endpoint that ranks by best match but doesn't do a full table scan.
**Example:**
```elixir
def search_customers(query \\ Customer, term) do
  # The WHERE clause uses the `%` operator which leverages the GIN index.
  # The ORDER BY clause uses `similarity()` to rank those filtered rows.
  query
  |> where([c], fragment("? % ?", c.email, ^term) or fragment("? % ?", c.name, ^term))
  |> order_by([c], desc: fragment("GREATEST(similarity(?, ?), similarity(?, ?))", c.email, ^term, c.name, ^term))
  |> limit(50)
end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Sorting by similarity *without* a `where` clause. E.g. `order_by: fragment("similarity(?, ?) DESC", p.name, ^term)`.
  *Why it's bad:* GIN indices do not support KNN sorting. Ordering by similarity across the whole table forces Postgres to compute the similarity for *every single row* before sorting, resulting in a full table scan. Always filter using `%` first.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fuzzy String Matching | In-memory Jaro-Winkler or Levenshtein distance in Elixir (e.g., `String.jaro_distance`). | `pg_trgm` extension in Postgres. | Pulling all records into Elixir memory just to calculate string distance is incredibly slow and scales poorly. The database handles this efficiently with indices. |
| Custom external search | Setting up Elasticsearch or Typesense | `pg_trgm` | For core domain objects (email, processor_id, name), Postgres native search is sufficient and avoids the operational complexity of syncing external data stores. |

## Common Pitfalls

### Pitfall 1: Forgetting to specify the operator class
**What goes wrong:** The GIN index is created but Postgres does not use it for `ILIKE` or `%` queries.
**Why it happens:** In Ecto, `create index(:users, [:email], using: :gin)` defaults to `varchar_ops`, which doesn't support similarity search.
**How to avoid:** You must pass the column and operator class as a raw string: `create index(:users, ["email gin_trgm_ops"], using: :gin)`.

### Pitfall 2: Locking production tables during indexing
**What goes wrong:** The migration hangs or brings down production while indexing a massive table.
**Why it happens:** Standard `CREATE INDEX` locks the table for writes until finished.
**How to avoid:** Use `concurrently: true` in the `create index` function. This requires setting `@disable_ddl_transaction true` at the top of the migration module.

## Code Examples

### Ecto Migration Pattern

```elixir
defmodule Accrue.Repo.Migrations.AddTrigramSearchFoundation do
  use Ecto.Migration
  
  @disable_ddl_transaction true

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    # Separate GIN indices are generally preferred over multi-column 
    # unless you explicitly search on concatenated fields.
    
    # Customers
    create index(:accrue_customers, ["email gin_trgm_ops"], using: :gin, concurrently: true, name: :accrue_customers_email_trgm_index)
    create index(:accrue_customers, ["name gin_trgm_ops"], using: :gin, concurrently: true, name: :accrue_customers_name_trgm_index)

    # Subscriptions
    create index(:accrue_subscriptions, ["processor_id gin_trgm_ops"], using: :gin, concurrently: true, name: :accrue_subscriptions_processor_id_trgm_index)

    # Invoices
    create index(:accrue_invoices, ["processor_id gin_trgm_ops"], using: :gin, concurrently: true, name: :accrue_invoices_processor_id_trgm_index)
    create index(:accrue_invoices, ["number gin_trgm_ops"], using: :gin, concurrently: true, name: :accrue_invoices_number_trgm_index)
  end

  def down do
    # Must drop explicitly if doing up/down
    drop index(:accrue_invoices, ["number gin_trgm_ops"], name: :accrue_invoices_number_trgm_index)
    drop index(:accrue_invoices, ["processor_id gin_trgm_ops"], name: :accrue_invoices_processor_id_trgm_index)
    
    drop index(:accrue_subscriptions, ["processor_id gin_trgm_ops"], name: :accrue_subscriptions_processor_id_trgm_index)
    
    drop index(:accrue_customers, ["name gin_trgm_ops"], name: :accrue_customers_name_trgm_index)
    drop index(:accrue_customers, ["email gin_trgm_ops"], name: :accrue_customers_email_trgm_index)
    
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/accrue/billing_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SRCH-01 | Migration executes successfully and indices are available | integration | `mix test` (Migrations run before suite) | ✅ Wave 0 |
| SRCH-02 | `Accrue.Billing.search_customers/1` returns expected subset | unit | `mix test test/accrue/billing_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/accrue/billing_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing ExUnit infrastructure and database sandbox naturally handles migration execution and context query testing.

## Sources

### Primary (HIGH confidence)
- [PostgreSQL Official Docs - pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html) - Verified similarity `%` operator, `similarity()` function, and `gin_trgm_ops`.
- [HexDocs - Ecto.Migration](https://hexdocs.pm/ecto_sql/Ecto.Migration.html) - Verified `concurrently: true` usage, `@disable_ddl_transaction true`, and string-based column definition for opclass specification.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `pg_trgm` is the de-facto standard in Postgres.
- Architecture: HIGH - Known Ecto fragments and DB operators.
- Pitfalls: HIGH - Documented Ecto caveats around opclass and `concurrently`.
