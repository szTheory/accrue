# Phase 38 — Technical Research

**Phase:** 38 — Org billing recipes — Pow + custom org boundaries  
**Question:** What do we need to know to **plan** ORG-07 and ORG-08 doc delivery without duplicating Phase 37’s spine?

## Findings

### Current codebase anchors

- **`guides/organization_billing.md`** already defers Pow/custom depth to Phase 38 / ORG-07 / ORG-08 (ORG-03 intro + User-as-billable aside). Phase 38 should **fill** those deferred sections, not fork a second spine.
- **`guides/auth_adapters.md`** already ships a complete **`MyApp.Auth.Pow`** example (`Pow.Plug.current_user/1`, `require_admin_plug/0`, audit + step-up stubs). ORG-07 should **reference** this SSOT and focus on **org resolution + ORG-03** obligations that Pow does not solve.
- **`guides/webhooks.md`** (if present) and host webhook replay patterns should be cited from ORG-08 for **replay scoping** — research assumption: executor reads webhooks guide for consistent cross-links.

### Pow — planning notes

- **Identity boundary:** Pow exposes **user** identity via plugs; **active organization** remains **host-owned** (session key + membership table or equivalent). Plans must warn against implying `Pow.Plug.current_user/1` substitutes for org membership checks.
- **Version variance:** Accrue should not pin documentation to a specific Pow release line beyond **public Plug APIs**; hosts pin `{:pow, ...}` / storage adapters in their own `mix.exs`.
- **Maintenance posture:** Document as **community-maintained** with upgrade verification steps (grep for deprecated Pow APIs in host app) — avoids false “vendor SLA” language.

### Custom org models — planning notes

- **Non-session org keys:** Subdomain tenancy, `x-tenant-id` headers, or database sharding keys must still converge on a **single verified `Organization` struct** (or id) before any `Accrue.Billing` call.
- **ORG-03 replay class:** Replay tooling often uses elevated DB access — the recipe must call out **explicit billable resolution from event metadata** + **actor attribution** (`Accrue.Auth.actor_id/1`) so audit rows do not imply cross-org access.

### Risk: merge conflicts

- Both ORG-07 and ORG-08 touch **`organization_billing.md`**. Sequencing **wave 2** plan after **wave 1** reduces conflict risk vs parallel edits.

## Validation Architecture

This phase is **documentation-first**; automated feedback must prove (1) guides build under ExDoc, (2) ORG-07/ORG-08 acceptance strings exist in the spine + contract test, (3) no regression to Phase 37 anchors.

### Dimension 8 — Doc and contract sampling

| Dimension | Signal | Instrument |
|-----------|--------|------------|
| Doc build | No new ExDoc warnings on edited guides | `cd accrue && MIX_ENV=test mix docs` |
| ORG-07 | Pow checklist + `MyApp.Auth.Pow` + membership-gated org language | `organization_billing_guide_test.exs` + `rg` on `organization_billing.md` |
| ORG-08 | Custom org section + anti-pattern table covering all four ORG-03 path classes | Same contract test + `rg` |
| Cross-guide | Pow section in `auth_adapters.md` links to spine | `rg` on `auth_adapters.md` |

### Manual-only (acceptable)

- Editorial readability — human review at SUMMARY time.

---

## RESEARCH COMPLETE

*Phase 38 — research synthesized 2026-04-21 for `/gsd-plan-phase 38`.*
