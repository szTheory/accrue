# Research Summary — v1.8 ORG-04

**Milestone:** v1.8 Org billing recipes & host integration depth  
**Synthesized:** 2026-04-21

## Stack additions

**None required** at the Accrue package level. Hosts continue to choose phx.gen.auth, Pow, Sigra, or custom; v1.8 adds **documentation + proof alignment**, not new Hex dependencies for auth stacks.

## Feature table stakes

1. One clear **documentation spine** for non-Sigra org-shaped billing (session → billable → `Accrue.Billing`).
2. **phx.gen.auth** and **Pow** recipe sections with honest maintenance notes.
3. **Custom org** recipe emphasizing `owner_type` / `owner_id` and **ORG-03** boundaries (admin, webhooks, replay).
4. **Adoption proof matrix / VERIFY-01** updated so at least one non-Sigra org archetype is traceable to a verifier or explicitly advisory.

## Architecture integration

Recipes sit **above** existing `Accrue.Billable` + `Accrue.Auth` contracts; Sigra remains the first-party adapter, with non-Sigra paths as **parallel documented** patterns.

## Watch out for

- **Cross-tenant reads** from sloppy queries or admin components.
- **Proof drift** — matrix rows without an owning script/test.
- **Scope creep** into **PROC-08** or **FIN-03** (milestone non-goals).

## Recommended roadmap shape

Three phases: **(37)** spine + phx.gen.auth → **(38)** Pow + custom org boundaries → **(39)** proof/matrix + CI doc alignment.
