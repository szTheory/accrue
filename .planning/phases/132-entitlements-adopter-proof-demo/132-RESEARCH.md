# Phase 132: Entitlements Adopter-Proof Demo - Research

**Researched:** 2024-05-18
**Domain:** Entitlements Gating API & Integration Verification
**Confidence:** HIGH

## Summary

The canonical demo for Phase 132 requires gating a page in `examples/accrue_host` based on a billable's active plans. To achieve this realistically for a B2B (Organization-scoped) demo, the host needs a configured `Accrue.Live.Entitlements` gate in its router and a matching `config :accrue, :entitlements` mapping. The default entitlement probe resolves to `current_scope.user`, so the demo MUST configure `:billable` to resolve `current_scope.organization` to prove the org-billed gating pattern.

**Primary recommendation:** Add a dummy `/app/reports/advanced` LiveView gated on `{:require_feature, :advanced_reports}`, configure `LocalMap` entitlements for `:advanced_reports`, and write a focused LiveView test (and update e2e seeds) to prove the end-to-end flow. Update `adoption-proof-matrix.md` and the verify script to lock the contract.

<user_constraints>
## User Constraints (from Phase 132 Requirements)

### Locked Decisions
- The canonical `examples/accrue_host` MUST demonstrate the v1.39 headline JTBD (gating access on what a customer has paid for) end-to-end.
- `examples/accrue_host` MUST gate at least one route or page on an entitlement using the v1.39 gate API (`Accrue.Live.Entitlements` / `Accrue.Plug.RequireEntitlement` / `Accrue.entitled?`).
- An entitled billable MUST reach the gated surface, and a non-entitled billable MUST be denied.
- `examples/accrue_host/docs/adoption-proof-matrix.md` MUST gain a matching row proving the entitlement-gating demo is part of the proof-posture contract.
- Updating the matrix REQUIRES co-updating `scripts/ci/verify_adoption_proof_matrix.sh` in the same change set.

### the agent's Discretion
- The name of the gated route (e.g., `/app/advanced-reports`, `/app/premium-feature`).
- The specific feature name to gate on (e.g., `:advanced_reports`, `:premium_access`).
- Which file to place the test/seed data in (e.g., `seed_e2e_cleanup_test.exs`, `priv/repo/seeds.exs`, or a new `entitlements_test.exs` within the host).

### Deferred Ideas (OUT OF SCOPE)
- Custom/external entitlement resolvers (stick to `LocalMap` and static config).
- Complex quota/limits gating (focus on a boolean feature gate for the primary demo).
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Router Gate | Frontend Server (SSR) | — | Phoenix router `live_session` handles declarative `on_mount` lifecycle hooks before mount. |
| Feature Map | Backend / Config | — | Entitlement boundaries (`LocalMap` config) are defined server-side statically. |
| Verification | CI / ExUnit | — | Both Bounded test suites (`mix verify`) and CI bash scripts enforce the proof contract. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Accrue.Live.Entitlements` | v1.39 | LiveView route gating | Canonical v1.39 enforcement API that fail-closes natively. |
| `Accrue.Config.entitlements/0` | v1.39 | Plan -> Feature Map | Decoupled entitlements definition without external APIs. |

### Anti-Patterns to Avoid
- **[Anti-pattern]:** Forgetting to override `:billable` in config. The default probe `current_scope.user -> current_user -> nil` will resolve the user instead of the organization, breaking org-billed feature gates.
- **[Anti-pattern]:** Placing `Accrue.Live.Entitlements` before the auth `on_mount` hook in `router.ex`. The auth hook MUST run first to populate `current_scope`, or the gate fails closed immediately.
- **[Anti-pattern]:** Gating on a `price_id` directly. The gate MUST be `{:require_feature, :feature_name}` or `{:require_plan, :plan_name}`.

## Code Examples

### 1. Entitlements Config
```elixir
# examples/accrue_host/config/config.exs
config :accrue, :entitlements,
  billable: fn container ->
    case Map.get(container.assigns, :current_scope) do
      %{organization: org} when not is_nil(org) -> org
      _ -> Map.get(container.assigns, :current_user)
    end
  end,
  plans: [
    basic: [
      price_ids: ["price_basic"]
    ],
    premium: [
      features: [:advanced_reports],
      price_ids: ["price_premium"]
    ]
  ]
```

### 2. Router Gate
```elixir
# examples/accrue_host/lib/accrue_host_web/router.ex
live_session :entitled_reports,
  on_mount: [
    {AccrueHostWeb.UserAuth, :require_authenticated},
    {Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}
  ] do
  live("/app/reports/advanced", AccrueHostWeb.AdvancedReportsLive, :index)
end
```

### 3. Dummy Gated LiveView
```elixir
# examples/accrue_host/lib/accrue_host_web/live/advanced_reports_live.ex
defmodule AccrueHostWeb.AdvancedReportsLive do
  use AccrueHostWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Advanced Reports")}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Advanced Reports</h1>
      <p>You have access to this premium feature.</p>
    </div>
    """
  end
end
```

### 4. Updating the E2E Seed
Update `scripts/ci/accrue_host_seed_e2e.exs` to ensure that at least one seeded subscription provisions the `price_premium` item, making the feature reachable to e2e test users. Alternatively, create a dedicated `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` that sets up its own fixtures and hits `/app/reports/advanced`.

## Matrix and Verifier Changes

The matrix file `examples/accrue_host/docs/adoption-proof-matrix.md` needs a new row under the `## Blocking: Fake-backed host + browser` section:

| Concern | Proof | Where |
|--------|--------|--------|
| Entitlement gating (`Accrue.Live.Entitlements`) | Gated `/app/reports/advanced` with `{:require_feature, :advanced_reports}`; `entitlements_guard_test.exs` | `examples/accrue_host` router + `Accrue.Config.entitlements()` |

The `scripts/ci/verify_adoption_proof_matrix.sh` file MUST be updated with matching `require_substring` assertions:
```bash
require_substring "Entitlement gating" "Entitlement gating row"
require_substring "Accrue.Live.Entitlements" "Accrue.Live.Entitlements API reference"
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` |
| Quick run command | `cd examples/accrue_host && mix test` |
| Full suite command | `cd examples/accrue_host && mix verify` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Entitled billable can access page | integration | `mix test test/accrue_host_web/live/entitlements_guard_test.exs` | ❌ Wave 0 |
| REQ-02 | Non-entitled billable is denied | integration | `mix test test/accrue_host_web/live/entitlements_guard_test.exs` | ❌ Wave 0 |
| REQ-03 | Matrix proof shell script | unit | `bash ../../scripts/ci/verify_adoption_proof_matrix.sh` | ✅ |
