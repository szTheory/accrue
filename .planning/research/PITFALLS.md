# Domain Pitfalls

**Domain:** Elixir/Phoenix billing library + mounted LiveView packages  
**Researched:** 2026-05-31

## Critical Pitfalls

### Pitfall 1: Support-Contract Drift
**What goes wrong:** Runtime behavior, support matrix, docs, and verifiers diverge for processor capabilities.  
**Why it happens:** Feature work lands without same-PR contract updates.  
**Consequences:** Adopter confusion, false expectations, regression risk at release time.  
**Prevention:** Enforce “behavior + matrix + docs + verifier” atomic change policy.  
**Detection:** Failing contract scripts or support labels inconsistent with API docs.

### Pitfall 2: Hidden Host Ownership Assumptions
**What goes wrong:** Integrators assume Accrue starts Repo/Oban/auth or auto-fixes host wiring.  
**Why it happens:** Library ergonomics hide operational prerequisites.  
**Consequences:** Boot/runtime failures, delayed onboarding, support burden.  
**Prevention:** Keep setup diagnostics explicit; treat host wiring checks as release gates.  
**Detection:** Frequent `ConfigError` classes and setup/troubleshooting issue recurrence.

### Pitfall 3: LiveView Auth Boundary Inconsistency
**What goes wrong:** Plug auth checks and LiveView `on_mount` checks drift or are incomplete.  
**Why it happens:** Mounted packages evolve routes/hooks separately.  
**Consequences:** Unauthorized access paths or inconsistent tenant scoping.  
**Prevention:** Test both HTTP and LiveView mount authorization paths per route family.  
**Detection:** Wrong-tenant tests, auth hook regressions, unexpected redirect loops.

## Moderate Pitfalls

### Pitfall 1: Over-expanding Braintree semantics
**What goes wrong:** Attempts to mimic Stripe-native previews/item mutations where unsupported.  
**Prevention:** Preserve bounded support + typed unsupported errors; do not invent synthetic parity.

### Pitfall 2: Metrics cardinality creep
**What goes wrong:** High-cardinality IDs leak into metric tags.  
**Prevention:** Keep IDs in span metadata only; enforce low-cardinality tag policy in metric recipes.

### Pitfall 3: Oban queue coupling and starvation
**What goes wrong:** Queue limits/pool sizing mismatch causes delayed billing side effects.  
**Prevention:** Keep queue topology documented and assert host wiring in verifier/proof scripts.

## Minor Pitfalls

### Pitfall 1: Optional dependency ambiguity
**What goes wrong:** Consumers misread optional vs required runtime surface in core package.  
**Prevention:** Publish explicit compatibility/optional-feature matrix and test lanes.

### Pitfall 2: Package README depth mismatch
**What goes wrong:** `accrue_portal` appears less discoverable than core/admin docs.  
**Prevention:** Add concise but explicit host integration and security expectations in portal docs.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| API stabilization | Freezing internal modules by accident | Publish a strict public API boundary list and enforce with docs verifier. |
| Migration ownership hardening | Library starts behaving like migration runner | Keep host-executed migration model; validate via `mix accrue.install --check`. |
| Router/mount ergonomics | Route or session key surprises | Add explicit mount-contract tests and failure diagnostics. |
| Release gate consolidation | Too many scripts without risk mapping | Create one release gate map by risk class and required pass criteria. |

## Sources

- Repo-local: `.planning/processor-support-matrix.md`, `.planning/STRATEGY.md`, `.planning/PROJECT.md` (HIGH)
- Repo-local: `accrue/lib/accrue/application.ex`, `accrue/lib/accrue/repo.ex`, `accrue/lib/accrue/webhook/plug.ex`, `accrue_admin/lib/accrue_admin/router.ex`, `accrue_portal/lib/accrue_portal/router.ex` (HIGH)
- Repo-local: `scripts/ci/verify_*.sh` inventory and package/guides docs (HIGH)
- https://hexdocs.pm/phoenix_live_view/security-model.html (HIGH)
- https://hexdocs.pm/oban/unique_jobs.html (HIGH)
- https://hexdocs.pm/telemetry/1.4.1/telemetry.html (HIGH)
