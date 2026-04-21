# Features Research

**Domain:** ORG-04 — broader non-Sigra tenancy recipes
**Researched:** 2026-04-21
**Confidence:** MEDIUM–HIGH (product direction from archived v1.3 requirements)

## Table stakes (must ship for ORG-04 to count)

| Capability | Notes |
|------------|--------|
| **Single “spine” doc** | One host-facing entry (new guide or clearly linked chapter) that states: billable = host Ecto schema + `use Accrue.Billable`; active org (if any) is **host** responsibility before Accrue APIs run. |
| **phx.gen.auth-shaped path** | Documented checklist: session → `current_user` → billable struct or org membership → `Accrue.Billing` calls; admin routes still behind `Accrue.Auth` adapter. |
| **Pow-shaped path** | Same checklist with Pow session/user conventions; call out version/community maintenance expectations honestly. |
| **Custom org model path** | Narrative + anti-patterns: `owner_type`/`owner_id` integrity, no cross-org admin reads, webhook replay actor scope (ties to **ORG-03**). |
| **Proof alignment** | Adoption proof matrix (or VERIFY-01 contract) gains at least one **archetype row** for non-Sigra org billing, with merge-blocking vs advisory stance matching existing CI policy. |

## Differentiators (nice, if time allows)

- Minimal excerpt or **optional** host fixture path (e.g. documented branch or `examples/` note) for one non-Sigra archetype — only if it does not duplicate `examples/accrue_host` Sigra-first story confusingly.
- Cross-links from `sigra_integration.md` (“if you are not on Sigra, see …”).

## Anti-features (explicitly not ORG-04)

| Anti-feature | Reason |
|--------------|--------|
| Accrue-owned org / membership tables | Host owns tenancy; Accrue stays polymorphic billable reference. |
| Official Pow/phx.gen.auth generators inside Accrue | Maintenance burden; recipes + pointers suffice. |
| FIN-03 exports / PROC-08 | Milestone non-goals. |

## Dependencies on existing shipped work

- **ORG-01..03**, **ORG-02** Sigra-first proof — recipes must not weaken row-level admin/query contracts.
- **VERIFY-01** / Phase 33 CI language — new proof rows must reuse existing verifier patterns.
