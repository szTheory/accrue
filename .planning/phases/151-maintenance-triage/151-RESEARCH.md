# Phase 151: Maintenance & Triage - Research

**Researched:** 2026-05-29
**Domain:** Codebase Maintenance, Triage, and Audit
**Confidence:** HIGH

## Summary

This phase focuses on preparing Accrue for a stable closure milestone (v1.46). It is a maintenance phase dedicated to executing dependency updates, resolving outstanding code review items (specifically ENT-10 regarding webhook caching), and verifying the project’s health against strict "Three Zeros" criteria. No new functional capabilities are introduced.

**Primary recommendation:** Follow a strict sequential approach: update dependencies first (`mix deps.update --all` for minor/patches in all sub-projects), resolve the ENT-10 code review feedback, ensure the test suite passes, and finally run the required shift-left audit scripts in `scripts/ci/` to achieve "The Three Zeros".

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Triage priority
- **D-01:** "Clean Room" Triage & Money-Safety First. Establish a strict priority tier: Tier 1: Core Billing/Money-Safety & Provider Sync drift. Tier 2: `docs-contracts-shift-left` and Adoption Proof Matrix failures. Tier 3: Planning tooling friction. Defer any new feature requests to "Post-1.x".

### Dependency updates
- **D-02:** "Final Stable Bump & Pin" (Conservative Minor/Patch). Run a final `mix deps.update --all` for minor/patch versions. Run the full test suite (`test` + `dialyzer` + `credo`). If green, lock them. Do not bump any major versions. Update `mix.exs` to reflect the latest compatible ranges. This ensures maximum compatibility and shelf-life before BitRot sets in.

### Closure criteria
- **D-03:** "The Three Zeros". Explicitly define closure as: 1. All P0/P1 triage items are closed. 2. Zero audit gaps (successful, clean run of `verify_adoption_proof_matrix.sh` and `verify_package_docs`). 3. Zero Nyquist (test coverage) gaps missing. 4. A final Hex publish patch release with matching Git tags.

### Folded Todos
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)**
  Original Problem: Pending code-review feedback regarding caching logic in webhooks.
  Fit: Resolving technical debt and implementing code-review feedback fits perfectly within the maintenance and triage scope.

### the agent's Discretion
None - discussion stayed strictly within phase scope.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MNT-01 | Perform routine issue triage and repository maintenance. | Execute dependency updates, close out ENT-10, and run the 'Three Zeros' verification tasks. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency Updates | OS/Environment | API / Backend | Handled by Elixir/Mix within the local environments and `mix.exs` constraints. |
| Webhook Caching (ENT-10) | API / Backend | Database | Webhooks are handled by the API layer, but caching impacts Ecto/DB state to ensure idempotency. |
| Verification / Audit | CI / Scripts | — | Bash scripts in `scripts/ci/` run assertions against the codebase state. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:mix` | 1.19+ | Dependency management | Native to Elixir; manages updates via `deps.update`. |
| `:credo` | `~> 1.7` | Static analysis | Required for closure criteria to ensure code quality. |
| `:dialyxir` | `~> 1.4` | Static type checking | Required for closure criteria to ensure type safety. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `excoveralls` | `~> 0.18` | Coverage | Used to ensure "Zero Nyquist gaps" (100% test coverage) are met. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix deps.update --all` | Manual `mix.lock` edits | Never edit `mix.lock` by hand. The command respects `mix.exs` minor/patch constraints. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. Run the Package Legitimacy Gate protocol before completing this section.

*This phase updates existing dependencies via `mix deps.update --all` and does not introduce new external packages. A legitimacy audit for new packages is not applicable.*

## Architecture Patterns

### Recommended Project Structure
Since this is an existing monorepo, maintenance must occur across packages:
```
accrue/
├── mix.exs            # Core package constraints
├── mix.lock           # Core package lockfile
├── accrue_admin/
│   ├── mix.exs        # Admin package constraints
│   └── mix.lock       # Admin package lockfile
├── accrue_portal/     
│   ├── mix.exs        # Portal package constraints
│   └── mix.lock       # Portal package lockfile
└── scripts/ci/        # Shift-left CI scripts for verification
```

### Pattern 1: Monorepo Dependency Syncing
**What:** Running updates in all workspace sub-projects.
**When to use:** When doing dependency maintenance on a monorepo without a workspace root configuration.
**Example:**
```bash
# In each package directory
mix deps.update --all
mix test
mix dialyzer
mix credo --strict
```

### Anti-Patterns to Avoid
- **Unconstrained Updates:** Using `mix deps.update <dep>` without verifying if it jumps a major version. Always rely on the strict `~>` constraints in `mix.exs`.
- **Ignoring Audit Failures:** Bypassing `scripts/ci/verify_adoption_proof_matrix.sh` or `scripts/ci/verify_package_docs.sh` if they fail. The closure criteria explicitly demand zero gaps.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification of Documentation | Manual visual inspection | `scripts/ci/verify_package_docs.sh` | Automated verification ensures strict adherence to project standards without human error. |
| Verification of Matrix | Manual visual inspection | `scripts/ci/verify_adoption_proof_matrix.sh` | Automated check ensures nothing is missed in the adoption proofs. |

## Common Pitfalls

### Pitfall 1: Breaking Webhook Idempotency
**What goes wrong:** While addressing the ENT-10 code review feedback on webhook caching, idempotency is inadvertently broken.
**Why it happens:** Caching logic often touches how repeat webhooks are handled.
**How to avoid:** Ensure the test suite for `Accrue.Webhooks` remains green and specifically covers duplicate webhook deliveries.

### Pitfall 2: Asymmetric Updates
**What goes wrong:** Packages (`accrue`, `accrue_admin`, `accrue_portal`) drift in dependency versions after an update.
**Why it happens:** Running `mix deps.update` in one directory but forgetting the others.
**How to avoid:** Always run the dependency updates sequentially in all three project directories.

## Code Examples

Verified patterns from official sources:

### [Running Shift-Left Audits]
```bash
# Verify the adoption proof matrix
./scripts/ci/verify_adoption_proof_matrix.sh

# Verify package documentation honesty
./scripts/ci/verify_package_docs.sh
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ad-hoc dependency updates | Minor/Patch bound updates | Ongoing | Maintains stability for 1.x releases without introducing breaking changes. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

*All claims in this research were verified via codebase inspection — no user confirmation needed.*

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | Mix tasks, test suite | ✓ | 1.19.5 | — |
| `bash` | CI verification scripts | ✓ | (System) | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test && mix dialyzer && mix credo --strict` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MNT-01 | Webhook caching logic integrity (ENT-10) | unit | `mix test` | ✅ Wave 0 |
| MNT-01 | Closure criteria validation | smoke | `./scripts/ci/verify_adoption_proof_matrix.sh && ./scripts/ci/verify_package_docs.sh` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test && mix dialyzer && mix credo --strict`
- **Phase gate:** Full suite green before `/gsd:verify-work` AND all "Three Zeros" audit scripts pass.

### Wave 0 Gaps
None — existing test infrastructure covers all phase requirements.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Webhook caching must properly sanitize/validate identifiers to prevent collision. |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Mix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dependency Confusion | Tampering | Using `mix.lock` and Hex package manager. |
| Caching Collision | Information Disclosure | Scoping webhook cache keys properly by tenant/processor. |

## Sources

### Primary (HIGH confidence)
- `151-CONTEXT.md` - Defined the "Clean Room" strategy, "The Three Zeros" closure criteria, and the ENT-10 folded todo.
- `PROJECT.md` - Monorepo architecture and dependency boundaries.
- `scripts/ci/` - Verified existence of `verify_adoption_proof_matrix.sh` and `verify_package_docs.sh`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir tools (`mix`, `credo`, `dialyzer`).
- Architecture: HIGH - Defined explicitly in CONTEXT.md and existing CI scripts.
- Pitfalls: HIGH - Monorepo drift and webhook idempotency are well-known constraints.

**Research date:** 2026-05-29
**Valid until:** 30 days (Milestone closure phase)