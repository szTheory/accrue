# Phase 156: Entitlements Gating Adopter Proof - Research

**Researched:** 2026-05-31
**Domain:** Phoenix LiveView entitlement `on_mount` gating hardening for adopter-proof host example
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
### NotLoaded guard placement
- **D-01:** Normalize `%Ecto.Association.NotLoaded{}` defensively in core guard/decision code, preferably inside `Accrue.Entitlements.Guard` where billable resolution and allow/deny decisions already live. Do not put the primary decision logic in `Accrue.Live.Entitlements`; that module should remain the LiveView surface translator.
- **D-02:** Also make the `examples/accrue_host` billable resolver and router comment explicit about the expected host pattern. The example should teach that auth/scope loading must run before `Accrue.Live.Entitlements`, and that unloaded/missing billable state fails closed.
- **D-03:** Treat `Ecto.Association.NotLoaded` as "not a usable billable", not as data to pass into entitlement resolution. The outcome should be a safe denial, not a crash and not accidental entitlement.

### Fail-closed user path
- **D-04:** Keep the entitlement-denial UX generic for Phase 156. Missing/unloaded `active_organization` should fail closed through the entitlement guard rather than adding a new "select organization first" flow.
- **D-05:** Do not add a new pre-entitlement organization-presence `on_mount` hook in this phase. That would be a host UX capability, not required by PRF-01, and it would expand the behavioral surface beyond adopter-proof hardening.
- **D-06:** Preserve the security layering: authenticate/load scope first, authorize entitlement second. The example comment should make the ordering contract clear without changing the user-facing denial semantics.

### Proof shape
- **D-07:** Keep the existing positive and negative host tests in `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` as merge-blocking proof.
- **D-08:** Add an explicit host-level regression for `%Ecto.Association.NotLoaded{}` in the same test module. It should exercise the real `live_session`/`on_mount` route and prove the route redirects/halts safely instead of raising.
- **D-09:** Prefer one focused host regression over duplicative broad unit coverage unless the planner finds the core guard helper needs a tiny unit test to make the implementation straightforward. The adopter-facing proof is the host route behavior.

### Router comment contract
- **D-10:** Use a hybrid documentation shape: a concise inline contract near `live_session :entitled_reports` in `examples/accrue_host/lib/accrue_host_web/router.ex`, plus a canonical guide/doc reference for the fuller recipe.
- **D-11:** The inline comment should state the contract, not become a tutorial: auth/scope-loading `on_mount` first; `Accrue.Live.Entitlements` after; deny target outside the gated session; unloaded/missing billable state fails closed.
- **D-12:** Keep detailed variants and rationale in canonical docs such as `accrue/guides/entitlements.md` and/or the host adoption matrix. Avoid long router comments that drift from docs.

### Folded Todos
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)** - Filed 2026-05-24 from Phase 127 code review. It originally resolved Phase 154 and informed the v1.47 entitlement-adopter-proof posture, but the Phase 156 slice should not reopen advisory-cache fixes already closed by Phases 154 and 155. Use it only as historical context for preserving fail-closed entitlement proof and support-truth discipline.

### the agent's Discretion
- No separate `the agent's Discretion` block exists in `156-CONTEXT.md`; treat remaining choices as implementation detail under locked decisions. [VERIFIED: codebase grep]

### Deferred Ideas (OUT OF SCOPE)
- Add a distinct "select an organization first" or "organization scope missing" UX flow before entitlement denial. Useful later, but out of scope for Phase 156 because it adds host UX behavior beyond PRF-01.
- Add broader docs around multi-tenant org-selection flows. Keep Phase 156 focused on the entitlement guard proof and ordering recipe.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRF-01 | Developer adopting Accrue can see a working `Accrue.Live.Entitlements` `on_mount` guard in `examples/accrue_host` that gracefully handles an unloaded billable association (defensive `NotLoaded` guard + router comment documenting `on_mount` order); existing positive + negative test cases verified passing | Add fail-closed `%Ecto.Association.NotLoaded{}` normalization in `Accrue.Entitlements.Guard`, add concise router ordering contract comment near `live_session :entitled_reports`, and add one host regression in `entitlements_guard_test.exs` that mounts `/app/reports/advanced` with unloaded association state and asserts safe redirect/halt. [VERIFIED: codebase grep] |

## Summary

Phase 156 is a safety-and-proof slice, not an API expansion slice. `Accrue.Live.Entitlements` is already a thin `on_mount` adapter over `Accrue.Entitlements.Guard.check/3`, and the checked-in host already proves entitled and non-entitled outcomes for `/app/reports/advanced`; the missing proof is explicit handling of unloaded billable associations so adoption cannot crash on common preload mistakes. [VERIFIED: codebase grep]

The current `examples/accrue_host` entitlements resolver reads `current_scope.active_organization` directly and falls back to user, while guard default probing currently accepts any non-`nil` value. Without explicit `%Ecto.Association.NotLoaded{}` normalization, a host can pass an unusable sentinel into the entitlement path. [VERIFIED: codebase grep]

**Primary recommendation:** implement `%Ecto.Association.NotLoaded{}` fail-closed normalization in `Accrue.Entitlements.Guard` billable resolution, keep `Accrue.Live.Entitlements` surface thin, and prove behavior with one real-route host regression plus a router ordering contract comment. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Normalize unloaded billable association into safe denial | API/Backend (`Accrue.Entitlements.Guard`) | Frontend Server (`on_mount` adapter) | Guard module owns shared entitlement decision and billable resolution for plug+live surfaces. [VERIFIED: codebase grep] |
| Enforce auth-before-entitlements ordering for adopters | Frontend Server router (`live_session`) | Documentation guides | `on_mount` ordering is declared where the chain is defined (`router.ex`), with canonical details in guides. [VERIFIED: codebase grep] |
| Prove adopter behavior end-to-end | Host integration test tier (`examples/accrue_host`) | Core guard unit tests (optional) | PRF-01 success criteria require route-level proof and existing positive/negative coverage unchanged. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | `~> 1.1.0` (host), `~> 1.1` (core) | `on_mount` guard surface used by adopter route proof | Existing phase scope is explicitly LiveView route gating in `examples/accrue_host`. [VERIFIED: codebase grep] |
| `ecto` / `ecto_sql` | `~> 3.13` | Association sentinel type `%Ecto.Association.NotLoaded{}` and persistence model around billables/scopes | Guard hardening target is an Ecto association loading edge case. [VERIFIED: codebase grep] |
| `ex_unit` | bundled | Existing proof tests and new regression test execution | Success criteria require existing tests to continue passing. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Plug.Conn` | project dependency (`~> 1.16`) | Existing deny/halt behavior in shared guard path for plug surface | No changes required unless planner adds complementary plug-path assertion. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Core guard normalization | Normalize only in example resolver | Leaves other host resolvers vulnerable and violates locked D-01 preference for shared guard hardening. [VERIFIED: codebase grep] |
| Host-level UX pre-guard hook | Add organization-presence `on_mount` gate | Out of scope for PRF-01 and explicitly rejected by locked D-05. [VERIFIED: codebase grep] |

**Installation:**
```bash
# No new packages required for Phase 156.
```

**Version verification:**
```bash
rg -n "phoenix_live_view|ecto_sql|ecto" accrue/mix.exs examples/accrue_host/mix.exs
```

## Package Legitimacy Audit

Not required for this phase because no new external package installation is recommended. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
LiveView request to /app/reports/advanced
  -> Router live_session :entitled_reports
    -> on_mount #1: AccrueHostWeb.UserAuth.require_authenticated
      -> assigns current_scope/current_user
    -> on_mount #2: Accrue.Live.Entitlements {:require_feature, :advanced_reports}
      -> Accrue.Entitlements.Guard.check(:live, socket, ...)
        -> resolve billable once
        -> normalize NotLoaded -> nil (fail-closed)
        -> Accrue.Entitlements.entitled?/3
          -> allow => {:cont, socket}
          -> deny => {:halt, redirect + generic flash}
```

### Recommended Project Structure
```text
accrue/
├── lib/accrue/entitlements/guard.ex                        # shared decision logic + NotLoaded normalization point
├── lib/accrue/live/entitlements.ex                         # thin on_mount translation layer
├── guides/entitlements.md                                  # canonical ordering/usage guidance
└── test/accrue/live/entitlements_test.exs                  # optional small core test if needed

examples/accrue_host/
├── config/config.exs                                       # host billable resolver example
├── lib/accrue_host_web/router.ex                           # live_session ordering contract comment
└── test/accrue_host_web/live/entitlements_guard_test.exs   # adopter-proof route regression
```

### Pattern 1: Fail-Closed Billable Normalization in Guard
**What:** Convert `%Ecto.Association.NotLoaded{}` to `nil` before entitlement predicate calls. [VERIFIED: codebase grep]  
**When to use:** Any resolver output can include Ecto unloaded association sentinels. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: accrue/lib/accrue/entitlements/guard.ex + phase D-01/D-03
defp normalize_billable(%Ecto.Association.NotLoaded{}), do: nil
defp normalize_billable(other), do: other

defp safe_apply(fun, container) do
  container
  |> then(fun)
  |> normalize_billable()
rescue
  _ -> nil
catch
  _ -> nil
  _, _ -> nil
end
```

### Pattern 2: Route-Level Regression for Real `live_session` Chain
**What:** Exercise `/app/reports/advanced` through `live/2`, not direct function-only tests. [VERIFIED: codebase grep]  
**When to use:** Adopter-proof requirement targets router `on_mount` behavior and ordering expectations. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs pattern
result = live(conn_with_unloaded_scope, "/app/reports/advanced")
assert {:error, {:redirect, %{to: "/", flash: %{"error" => _}}}} = result
```

### Anti-Patterns to Avoid
- **Decision logic in `Accrue.Live.Entitlements`:** breaks layering and duplicates core decision code. [VERIFIED: codebase grep]
- **Assuming auth ordering is implicit:** missing comment at route declaration leads adopters to spurious fail-closed denials. [VERIFIED: codebase grep]
- **Adding UX branch in this phase:** expands scope beyond PRF-01 locked behavior. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Authorization decision branching in router/live modules | Custom per-route entitlement checks | `Accrue.Entitlements.Guard.check/3` via `Accrue.Live.Entitlements` | Shared fail-closed semantics and consistent deny handling already exist. [VERIFIED: codebase grep] |
| Adopter docs in large router comments | Long tutorial blocks in `router.ex` | Short contract comment + canonical guide link | Reduces drift and keeps DSL readable. [VERIFIED: codebase grep] |

**Key insight:** This phase should harden one shared normalization seam and prove it at host route level; everything else should remain unchanged. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Unloaded association treated as billable
**What goes wrong:** `%Ecto.Association.NotLoaded{}` reaches entitlement predicates and can crash or misbehave. [VERIFIED: codebase grep]  
**Why it happens:** Resolver paths read association fields that may be unloaded in real host flows. [VERIFIED: codebase grep]  
**How to avoid:** Normalize unloaded associations to `nil` at the shared guard resolution seam. [VERIFIED: codebase grep]  
**Warning signs:** Route mount raises instead of returning redirect/halt deny response. [VERIFIED: codebase grep]

### Pitfall 2: `on_mount` order undocumented
**What goes wrong:** Adopters place entitlement guard before auth scope loader and get global deny behavior. [VERIFIED: codebase grep]  
**Why it happens:** `on_mount` execution order is list order and guard depends on populated assigns. [VERIFIED: codebase grep]  
**How to avoid:** Add concise router comment where `live_session :entitled_reports` is declared. [VERIFIED: codebase grep]  
**Warning signs:** Entitled users get redirected with generic denial immediately after integration. [ASSUMED]

## Code Examples

### Router comment contract
```elixir
# Source: examples/accrue_host/lib/accrue_host_web/router.ex (to add near live_session)
# Ordering contract:
# 1) auth/scope on_mount must run first
# 2) Accrue.Live.Entitlements runs after scope exists
# 3) deny target must be outside this gated session
# 4) missing/unloaded billable fails closed (deny, never raise)
```

### Defensive host resolver shape (example-side clarity)
```elixir
# Source: examples/accrue_host/config/config.exs (recommend explicit defensive branch)
scope = Map.get(container.assigns, :current_scope)
org = if scope, do: Map.get(scope, :active_organization), else: nil
case org do
  %Ecto.Association.NotLoaded{} -> Map.get(scope, :user)
  _ -> org || (scope && Map.get(scope, :user)) || Map.get(container.assigns, :current_user)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Assume resolver output is always loaded billable or nil | Normalize unloaded association sentinel at shared guard boundary | Planned in Phase 156 | Converts host preload mistakes into deterministic safe denial instead of crash risk. [VERIFIED: codebase grep] |
| Route works for happy/negative paths only | Add explicit unloaded-association regression at route level | Planned in Phase 156 | Improves adopter confidence and protects against regressions. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Relying on implicit `on_mount` order without inline contract comment in example host. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Entitled users are likely to mis-order `on_mount` without explicit comment guidance | Common Pitfalls | Medium; may still pass internal tests but degrade adopter DX |

## Open Questions

1. **Should `NotLoaded` normalization also be asserted in `accrue/test/accrue/live/entitlements_test.exs`?**
   - What we know: Host route regression is mandatory proof; core live test file already exists and is non-async. [VERIFIED: codebase grep]
   - What's unclear: Whether one additional unit assertion improves maintainability enough to justify extra scope.
   - Recommendation: Keep optional; only add if implementation introduces a new helper that benefits from direct unit coverage.

## Environment Availability

Step 2.6: SKIPPED (no new external dependencies required; this phase is code+test+comment updates in existing Elixir/Phoenix toolchain). [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`) [VERIFIED: codebase grep] |
| Config file | `examples/accrue_host/test/test_helper.exs` and `accrue/test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs` [ASSUMED] |
| Full suite command | `cd examples/accrue_host && mix verify.full` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRF-01 | Unloaded billable association denies safely without raise; ordering contract documented; existing pos/neg tests still pass | integration (LiveView route) | `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs`
- **Per wave merge:** `cd examples/accrue_host && mix test`
- **Phase gate:** `cd examples/accrue_host && mix verify.full` before `$gsd-verify-work`

### Wave 0 Gaps
- None — target test module already exists and already covers positive/negative paths. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep auth/scope `on_mount` before entitlement `on_mount`; no auth bypass changes in this phase. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Continue using existing session-derived scope loading from `AccrueHostWeb.UserAuth`. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Fail-closed deny on missing/unloaded billable; no grant on ambiguous state. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Treat non-usable resolver outputs (`NotLoaded`) as invalid billables -> deny. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No cryptographic behavior touched in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for Phoenix entitlement guards

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Authorization bypass via fail-open on resolver edge cases | Elevation of privilege | Normalize unresolved/unloaded billable states to `nil` and deny. [VERIFIED: codebase grep] |
| Denial loop / mount churn due to redirect target inside gated session | Denial of service | Document deny target placement outside gated `live_session`. [VERIFIED: codebase grep] |
| Information disclosure in deny path | Information disclosure | Keep generic denial flash; do not reveal feature/plan in response. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `accrue/lib/accrue/entitlements/guard.ex` - shared check flow, resolver logic, deny behavior. [VERIFIED: codebase grep]
- `accrue/lib/accrue/live/entitlements.ex` - `on_mount` adapter and existing ordering/deny docs. [VERIFIED: codebase grep]
- `examples/accrue_host/config/config.exs` - host `:entitlements` billable resolver used by adopter proof route. [VERIFIED: codebase grep]
- `examples/accrue_host/lib/accrue_host_web/router.ex` - `live_session :entitled_reports` and `on_mount` chain target for comment contract. [VERIFIED: codebase grep]
- `examples/accrue_host/lib/accrue_host_web/user_auth.ex` - auth/scope `on_mount` that must precede entitlement guard. [VERIFIED: codebase grep]
- `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` - existing positive/negative adopter proof tests. [VERIFIED: codebase grep]
- `.planning/phases/156-entitlements-gating-adopter-proof/156-CONTEXT.md` - locked decisions and out-of-scope boundaries. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - PRF-01 requirement text and phase mapping. [VERIFIED: codebase grep]
- `.planning/STATE.md` - phase status and independence context. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all dependencies and usage points are already in-repo and directly inspected.
- Architecture: HIGH - module boundaries and route/test integration points are explicit in source.
- Pitfalls: MEDIUM - primary pitfalls are code-backed, but one adopter-behavior prediction remains assumed.

**Research date:** 2026-05-31
**Valid until:** 2026-06-30
