# Stack Research

**Domain:** Accrue v1.8 — non-Sigra organization billing recipes (Phoenix host integration)
**Researched:** 2026-04-21
**Confidence:** HIGH (brownfield; no new Accrue runtime deps implied)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / Phoenix / Ecto | Accrue floor (1.17+, Phoenix 1.8+) | Host apps implementing recipes | Already project constraints; recipes must not imply older Phoenix. |
| PostgreSQL | 14+ | Row-scoped `owner_type` / `owner_id` | Matches Accrue billing schema; org recipes stay row-scoped, not schema-per-tenant. |
| `accrue` + `accrue_admin` | 0.1.x | Billing + operator UI | ORG-04 is integration and documentation depth, not a new Hex dependency story. |

### Supporting Libraries (host-chosen, documented—not Accrue-enforced)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|---------------|
| **Sigra** | optional `~> 0.1` | Org-aware auth + admin scope | Already first-party path (`Accrue.Integrations.Sigra`); v1.8 adds **non-Sigra** recipes alongside, not replacing. |
| **phx.gen.auth** | Phoenix 1.8+ | Session + user schema owned by host | Common B2C / small-team billable = `User`; org-shaped billable needs explicit host pattern. |
| **Pow** | community | Session + user | Same contract: Accrue never owns `users`; billable resolution is host code. |

### What not to add for ORG-04

| Avoid | Why |
|-------|-----|
| New Accrue deps for Pow/phx.gen.auth | Recipes are host wiring + docs; optional compile deps would bloat core. |
| Second processor (**PROC-08**) | Explicitly out of v1.8 scope. |

## Installation / integration posture

- Host installs `accrue` / `accrue_admin` as today; `mix accrue.install` remains the spine.
- Non-Sigra recipes document **config + plugs + context** boundaries (`Accrue.Auth` adapter, `Accrue.Billable` target, admin `require_admin` / org scope) without vendoring Pow/phx.gen.auth into Accrue packages.

## Sources

- `.planning/PROJECT.md`, `.planning/milestones/v1.3-REQUIREMENTS.md` (ORG-01..03, deferred ORG-04)
- `accrue/guides/auth_adapters.md`, `accrue/guides/sigra_integration.md`
