# Technology Stack

**Project:** Accrue  
**Researched:** 2026-05-31

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | `~> 1.17` | Language/runtime baseline | Matches current project and modern library ecosystem support. |
| Phoenix | `~> 1.8` | Router/web integration seams | Idiomatic mounted-router model for package integration. |
| Phoenix LiveView | `~> 1.1` | Admin/portal interactive UI | Stable first-party approach for mounted package UX. |
| Plug | `~> 1.16+` | Request pipeline and reusable module plugs | Canonical way to expose host-integrated HTTP boundaries. |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ecto | `~> 3.13+` | Domain modeling, changesets, queries | Idiomatic context+schema+changeset architecture for Elixir libs. |
| Ecto SQL | `~> 3.13+` | Migrations and SQL adapter APIs | Host-run migrations with library-generated artifacts is standard. |
| Postgrex | `~> 0.22` | PostgreSQL adapter | Aligns with Accrue’s current schema and index strategy (`pg_trgm`, constraints). |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Oban | `~> 2.21+` | Durable background jobs, cron, replay workflows | Best-practice fit for billing/webhook idempotent async work. |
| Telemetry | `~> 1.3+` | Event instrumentation contract | Native observability primitive in Elixir ecosystem. |
| OpenTelemetry (optional) | `~> 1.7` | Distributed tracing export | Correctly host-opt-in, avoids forcing tracing stack in core. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `telemetry_metrics` | `~> 1.1` | Default metrics recipes | Use when host app exposes Prometheus/StatsD style counters. |
| `nimble_options` | `~> 1.1` | Config schema validation | Keep for boot-time config correctness and low-surprise failures. |
| `mailglass` / `mailglass_admin` | `~> 1.0` | Email ops and preview tooling | Use for operational visibility; keep host lifecycle ownership explicit. |
| `lattice_stripe` | `~> 1.1` | Stripe processor adapter integration | Keep as Stripe-first production lane. |
| `braintree` | `~> 0.16` | Braintree bounded support lane | Keep bounded to matrix-defined capabilities only. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Background jobs | Oban | Exq / custom GenServer orchestration | Weaker durability/operability contract for billing-critical retries and replay. |
| UI package model | Mounted LiveView packages | Generated host dashboards | Harder to maintain parity and upgrades; higher adopter maintenance burden. |
| Cross-processor abstraction | Capability-explicit facade | Full parity abstraction across all processors | Historically causes lowest-common-denominator or misleading APIs. |

## Installation

```bash
# Core
mix deps.get
mix accrue.install

# Host migration/runtime
mix ecto.migrate

# Optional package mounts
# add accrue_admin / accrue_portal deps at same version train
```

## Sources

- https://hexdocs.pm/phoenix/Phoenix.Router.html (HIGH)
- https://hexdocs.pm/phoenix/contexts.html (HIGH)
- https://hexdocs.pm/phoenix_live_view/security-model.html (HIGH)
- https://hexdocs.pm/ecto/Ecto.Multi.html (HIGH)
- https://hexdocs.pm/ecto_sql/Ecto.Migration.html (HIGH)
- https://hexdocs.pm/oban/Oban.Telemetry.html (HIGH)
- https://hexdocs.pm/oban/unique_jobs.html (HIGH)
- https://hexdocs.pm/plug/Plug.html (HIGH)
- Repo-local: `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue_portal/mix.exs`, `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/repo.ex` (HIGH)
