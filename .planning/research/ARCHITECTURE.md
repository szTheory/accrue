# Architecture Patterns

**Domain:** Elixir billing core with mounted LiveView packages  
**Researched:** 2026-05-31

## Recommended Architecture

Use a strict layered library architecture:

`Host App (Repo/Auth/Runtime/Telemetry handlers)`  
→ `Accrue Public Facade Contexts (Billing/Entitlements/Webhooks)`  
→ `Processor adapters + persistence projections + Oban jobs`  
→ `Mounted UI packages (accrue_admin / accrue_portal) via router macros`

This is already mostly in place and should be stabilized, not reworked.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| Host app | Owns Repo lifecycle, Oban supervision, auth/session, runtime secrets | Accrue config + generated billing facade |
| `Accrue.Billing` context | Public write/read facade and capability-guarded operations | Repo facade, processor behavior, telemetry spans |
| `Accrue.Webhook.Plug` + ingest | Verify signatures, persist event, enqueue dispatch atomically | Host pipeline, Repo, Oban |
| `Accrue.Repo` facade | Runtime-resolved gateway to host repo | Host-configured `MyApp.Repo` |
| Oban workers/jobs | Deferred reconciliation, dunning, replay-related workflows | Billing/query modules, processor adapters |
| `accrue_admin` package | Operator LiveView UI, replay/inspection/analytics | Host session/auth adapter, Accrue read APIs |
| `accrue_portal` package | Customer self-serve LiveView/Controller flows | Host session/auth adapter, billing facade |

### Data Flow

1. Host route forwards webhooks to `Accrue.Webhook.Plug` with processor-specific config.
2. Plug verifies payload, runs ingest transaction (`event row + dispatch job + ledger event`).
3. Oban worker executes projection/reducer logic, updating local billing tables.
4. Public facade (`Accrue.Billing`) exposes host-facing operations and telemetry spans.
5. Admin/portal packages read via facade/query modules and enforce auth via `on_mount` hooks + plugs.

## Patterns to Follow

### Pattern 1: Context-As-Contract
**What:** All app-facing billing operations go through `Accrue.Billing` (`ok/error` + bang variants), not internal modules.  
**When:** Always for host integration code and guides.  
**Example:**
```elixir
case Accrue.Billing.subscribe(customer, "price_123", operation_id: op_id) do
  {:ok, sub} -> {:ok, sub}
  {:error, reason} -> {:error, reason}
end
```

### Pattern 2: Host-Owned Runtime, Library-Owned Validation
**What:** Host starts infra; Accrue fails early with config diagnostics.  
**When:** Repo/Oban/auth/secret wiring and boot checks.  
**Example:**
```elixir
config :accrue, repo: MyApp.Repo
config :my_app, Oban, queues: [accrue_webhooks: 10]
```

### Pattern 3: LiveView Auth Dual Enforcement
**What:** Keep plug pipeline checks plus `on_mount` authorization checks.  
**When:** Mounted admin/portal routes and live sessions.  
**Example:**
```elixir
live_session :accrue_admin, on_mount: [{AccrueAdmin.AuthHook, :ensure_admin}] do
  live "/", AccrueAdmin.Live.DashboardLive, :index
end
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Expanding “official support” without matrix + verifier updates
**What:** Shipping behavior before support labels/docs/verifiers are updated together.  
**Why bad:** Causes adopter trust erosion and inconsistent release expectations.  
**Instead:** Require matrix/doc/verifier updates in same PR for processor-surface changes.

### Anti-Pattern 2: Leaking internal schema modules as implicit public API
**What:** Encouraging hosts to depend on internal table/struct details.  
**Why bad:** Freezes internals and blocks safe evolution.  
**Instead:** Keep stable facade API and document internals as non-contract.

### Anti-Pattern 3: Library-supervised host dependencies
**What:** Starting host Repo/Oban/telemetry pipelines from library app.  
**Why bad:** Violates ownership expectations and complicates operations.  
**Instead:** Keep empty-supervisor posture with actionable boot diagnostics.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Webhook throughput | Single queue defaults | Queue partitioning + DLQ alerting | Dedicated ingest/reducer tuning + strict idempotency enforcement |
| Query performance (admin) | Basic indexes | Add targeted search indices (`pg_trgm`) | Read-model/materialized projections for hot UI paths |
| Job pressure (dunning/metering) | Low | Queue isolation per domain | Queue SLOs + backpressure instrumentation + replay automation |
| Telemetry volume | Mostly logs/counters | Curated ops alerts | Cardinality governance + trace sampling strategy |

## Sources

- Repo-local: `accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/router.ex`, `accrue/lib/accrue/webhook/plug.ex`, `accrue/lib/accrue/repo.ex`, `accrue/lib/accrue/application.ex` (HIGH)
- Repo-local: `accrue_admin/lib/accrue_admin/router.ex`, `accrue_portal/lib/accrue_portal/router.ex`, `accrue_admin/lib/accrue_admin/auth_hook.ex`, `accrue_portal/lib/accrue_portal/auth_hook.ex` (HIGH)
- https://hexdocs.pm/phoenix/Phoenix.Router.html (HIGH)
- https://hexdocs.pm/phoenix_live_view/security-model.html (HIGH)
- https://hexdocs.pm/ecto/Ecto.Multi.html (HIGH)
- https://hexdocs.pm/oban/Oban.Telemetry.html (HIGH)
