# Stack Research

**Domain:** Elixir / Phoenix library adoption, docs-as-code, LiveView admin  
**Researched:** 2026-04-21  
**Confidence:** HIGH (milestone extends existing Accrue stack; no greenfield platform choice)

## Recommended Stack

### Core Technologies (unchanged for v1.7)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / OTP | 1.17+ / 27+ | Accrue runtime floor | Already locked in PROJECT.md; installer and guides must not imply older stacks. |
| Phoenix / LiveView | ~> 1.8 / ~> 1.1 | Host + `accrue_admin` | Admin dashboards and operator flows stay on function components + `ax-*` patterns from v1.6. |
| Playwright | project-pinned | VERIFY-01 browser proof | Community default for Phoenix host e2e; already encodes Fake-first admin paths. |
| GitHub Actions | YAML matrix | CI truth | Existing jobs separate merge-blocking Fake lanes from advisory Stripe test-mode—preserve that split in any doc or script churn. |

### Supporting / DX

| Library / tool | Purpose | When to Use |
|----------------|---------|-------------|
| `gsd-sdk` / shell contract scripts | README + CI consistency | Any new doc path for VERIFY-01 should be enforced by existing `verify_*` scripts where possible rather than human-only checklists. |
| `AccrueAdmin.Copy` | Stable literals | All new operator-visible strings in v1.7 admin work. |

### What NOT to Add for v1.7

| Avoid | Why |
|-------|-----|
| New JS UI kits, charting SaaS, or heavy client bundles | Conflicts with Phase 20/21 “no new registries” posture; dashboards should be LiveView + existing CSS tokens. |
| Extra Stripe SDK surface in docs | Milestone is not PROC-08; docs should not imply unsupported adapters. |

## Sources

- `.planning/PROJECT.md` — stack constraints and v1.6 decisions  
- `.planning/milestones/v1.5-ROADMAP.md` — adoption proof matrix precedent  
- `.planning/milestones/v1.6-ROADMAP.md` — admin UI-SPEC and CI patterns  

---
*Stack research for: Accrue v1.7 Adoption DX + operator admin depth*
