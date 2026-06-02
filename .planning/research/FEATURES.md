# Feature Landscape

**Domain:** Phoenix billing library + mounted admin/customer portal packages  
**Researched:** 2026-05-31

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Stable billing facade context (`Accrue.Billing`) | Phoenix users expect context-first public APIs | Med | Already strong; keep API drift tightly controlled. |
| Host-owned webhook ingest + replay + idempotent processing | Billing correctness requires durable event handling | High | Must stay first-class, including DLQ/replay operations. |
| Host-owned migrations with package-generated artifacts | Ecto users expect `mix ecto.migrate` ownership | Med | Preserve no-hidden-migration behavior. |
| Mounted admin LiveView package | Operators expect inspect/replay/triage UI | Med | Keep auth/session boundary explicit and least-surprise. |
| Mounted customer portal package | Self-serve billing and payment methods expected | Med | Maintain clear hosted vs local-provider semantics. |
| Oban-backed async jobs and cron | Billing lifecycles and reconciliation are async by nature | Med | Queue naming and host wiring should remain explicit. |
| Telemetry + ops event catalog | Production adopters need observability | Med | Continue low-cardinality metrics + rich span metadata discipline. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Capability-explicit dual-processor matrix | Honest support labeling avoids adoption traps | High | Major trust differentiator; keep matrix/script/doc lockstep. |
| Fail-closed entitlement APIs + guards | Security-by-default for paid feature gating | Med | Strong fit with LiveView `on_mount` and Plug pipelines. |
| Fake-first deterministic proof lane | Fast CI + local confidence without provider dependency | Med | Continue as merge-blocking lane; keep live-provider lanes advisory. |
| Rich verifier suite (docs/contracts/support matrix) | Prevents silent drift in OSS library promises | Med | Rare strength; should become a release hard-gate rubric. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Implied full parity for unsupported Braintree semantics | Creates hidden behavior divergence and support debt | Keep typed unsupported errors + matrix honesty. |
| Runtime ownership of host app infra (Repo/Oban/auth) | Violates principle of least surprise for Elixir libs | Keep host-owned lifecycle with explicit setup diagnostics. |
| Expanding into finance/accounting system scope (FIN-03 style) | Dilutes billing-library focus | Keep Stripe/reporting handoff guidance and boundary docs. |
| Auto-generated mutable dashboard code in host app | Increases maintenance burden and upgrade pain | Keep mounted package model with explicit extension seams. |

## Feature Dependencies

```text
Host repo/runtime config → migrations applied → webhook route/body reader
→ signed event ingest + outbox/Oban → billing lifecycle projections
→ admin observability + portal self-serve

Auth adapter + session keys → admin/portal on_mount resolution
→ tenant/owner scope correctness

Processor matrix contract → capability guards/errors/docs/verifiers
→ release confidence + support honesty
```

## MVP Recommendation

Prioritize:
1. Public API boundary hardening and support-contract clarity
2. Release-gate consolidation (verifiers + host proof + docs parity)
3. Mounted admin/portal auth/session DX polish (no net-new domain scope)

Defer: broader processor-surface expansion (preview/quantity/subscription-item on non-native lanes) until current bounded support contract is operationally frictionless.

## Sources

- Repo-local: `.planning/PROJECT.md`, `.planning/processor-support-matrix.md`, `.planning/STRATEGY.md`, `.planning/ROADMAP.md` (HIGH)
- Repo-local: `accrue/README.md`, `accrue_admin/README.md`, `accrue_portal/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/production-readiness.md`, `accrue/guides/testing.md` (HIGH)
- https://hexdocs.pm/phoenix/contexts.html (HIGH)
- https://hexdocs.pm/phoenix_live_view/security-model.html (HIGH)
