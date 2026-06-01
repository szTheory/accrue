# Roadmap: Accrue

## Milestones

- ✅ **v1.46 Maintenance & Closure** — Phases 151-153 (shipped 2026-05-30) — [archive](milestones/v1.46-ROADMAP.md)
- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- 🔄 **v1.48 Release Readiness + Stable Core Posture** — Phases 159-161

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. This milestone publishes the post-1.3.0 / v1.47 correctness work, makes that posture clear to adopters, closes stale planning anchors, and records a pause rule for broad feature work.

Future feature milestones require at least one of:
- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

No broad feature milestone is currently open.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

<details>
<summary>✅ v1.46 Maintenance & Closure (Phases 151-153) — SHIPPED 2026-05-30</summary>

- [x] Phase 151: Maintenance & Triage (3/3 plans) — completed 2026-05-30
- [x] Phase 152: Close v1.46 closure gaps: @since warnings, verification, Hex publish + tag (3/3 plans) — completed 2026-05-30
- [x] Phase 153: Close v1.46 audit trail: VERIFICATION.md for Phase 151, ROADMAP + REQUIREMENTS checkbox updates (2/2 plans) — completed 2026-05-30

Full details: [v1.46 roadmap archive](milestones/v1.46-ROADMAP.md)

</details>

<details>
<summary>✅ v1.47 ENT-10 Polish + Adopter-Proof Completeness (Phases 154-158) — SHIPPED 2026-05-31</summary>

- [x] Phase 154: Advisory Cache Core Correctness (1/1 plan) — completed 2026-05-31
- [x] Phase 155: StripeFixtures Polish + Telemetry Counters (1/1 plan) — completed 2026-05-31
- [x] Phase 156: Entitlements Gating Adopter Proof (1/1 plan) — completed 2026-05-31
- [x] Phase 157: Metered Usage Adopter Proof (1/1 plan) — completed 2026-05-31
- [x] Phase 158: Oban Cron Wiring Adopter Proof (1/1 plan) — completed 2026-05-31

Full details: [v1.47 roadmap archive](milestones/v1.47-ROADMAP.md)

</details>

<details open>
<summary>🔄 v1.48 Release Readiness + Stable Core Posture (Phases 159-161) — READY</summary>

### Phase 159: Linked Release Readiness + Publish Proof

**Goal:** Verify and publish the next linked release line after `1.3.0` with one coherent release-truth artifact across all three packages.
**Depends on:** Phase 158
**Requirements:** REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. Package versions, changelog entries, Release Please state, release notes, tags, and runbook instructions agree across `accrue`, `accrue_admin`, and `accrue_portal`.
  2. The deterministic release gate is run and documented for tests, docs, dialyzer, credo, package docs, support-matrix drift, adoption proof, and host integration checks.
  3. The linked Hex release is published in documented order and canonical proof is recorded in planning, changelogs, and release notes.
**Plans:** 2 plans

Plans:
**Wave 1**

- [x] 159-01-PLAN.md — Preserve the completed readiness scaffolding, deterministic gate proof, and blocker truth for the missing post-`1.3.0` line

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 159-02-PLAN.md — When a real combined Release Please PR and successful publish run exist, capture live linked publish proof and close REL-01/REL-03

### Phase 160: Stable-Core Public Positioning

**Goal:** Make the stable-core / demand-driven expansion posture explicit and consistent across public docs, package READMEs, support boundaries, release notes, and planning mirrors.
**Depends on:** Phase 159
**Requirements:** POS-01, POS-02, POS-03
**Success Criteria** (what must be TRUE):
  1. Public package docs and READMEs explain that Accrue is stable-core and demand-driven, not broad feature-chasing.
  2. Adopter-facing docs show the complete supported SaaS billing loop, processor support boundaries, and package ownership boundaries without requiring planning context.
  3. Release notes, package docs, support matrix, adoption proof docs, and planning mirrors describe the same stable-core posture.
**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 160-01-PLAN.md — Refresh the root/core docs spine and canonical guides for stable-core positioning

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 160-02-PLAN.md — Align thin mirrors, release notes, and the maintainer-facing processor matrix to the public docs spine

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 160-03-PLAN.md — Add the stable-core posture verifier, extend release-note checks, and wire the docs contract into CI

### Phase 161: Backlog Anchor Closure + Pause Rule

**Goal:** Retire stale roadmap pressure, classify remaining seeds/deferred ideas with revisit triggers, and close the milestone with an explicit pause rule for broad feature work.
**Depends on:** Phase 160
**Requirements:** BAK-01, BAK-02, PAU-01
**Success Criteria** (what must be TRUE):
  1. v1.17 friction anchors, resolved seeds, dormant seeds, and deferred ideas are archived, reclassified, or given explicit revisit triggers.
  2. A planning hygiene proof shows no active roadmap pointer suggests broad feature work is currently active.
  3. PROJECT/STATE/ROADMAP closeout text records that broad feature milestones remain closed unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
**Plans:** 1/1 plans complete

Plans:
- [x] 161-01-PLAN.md — Close stale backlog anchors, record revisit triggers, and write the post-v1.48 pause rule

</details>

## Phase Details

### Phase 159: Linked Release Readiness + Publish Proof
**Goal:** Verify and publish the next linked release line after `1.3.0` with one coherent release-truth artifact across all three packages.
**Depends on:** Phase 158
**Requirements:** REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. Package versions, changelog entries, Release Please state, release notes, tags, and runbook instructions agree across `accrue`, `accrue_admin`, and `accrue_portal`.
  2. The deterministic release gate is run and documented for tests, docs, dialyzer, credo, package docs, support-matrix drift, adoption proof, and host integration checks.
  3. The linked Hex release is published in documented order and canonical proof is recorded in planning, changelogs, and release notes.
**Plans:** 2/2 plans complete

Plans:
- [x] 159-01-PLAN.md — Preserve the completed readiness scaffolding, deterministic gate proof, and blocker truth for the missing post-`1.3.0` line
- [ ] 159-02-PLAN.md — When a real combined Release Please PR and successful publish run exist, capture live linked publish proof and close REL-01/REL-03

### Phase 160: Stable-Core Public Positioning
**Goal:** Make the stable-core / demand-driven expansion posture explicit and consistent across public docs, package READMEs, support boundaries, release notes, and planning mirrors.
**Depends on:** Phase 159
**Requirements:** POS-01, POS-02, POS-03
**Success Criteria** (what must be TRUE):
  1. Public package docs and READMEs explain that Accrue is stable-core and demand-driven, not broad feature-chasing.
  2. Adopter-facing docs show the complete supported SaaS billing loop, processor support boundaries, and package ownership boundaries without requiring planning context.
  3. Release notes, package docs, support matrix, adoption proof docs, and planning mirrors describe the same stable-core posture.
**Plans:** 3 plans

Plans:
- [ ] 160-01-PLAN.md — Refresh the root/core docs spine and canonical guides for stable-core positioning
- [ ] 160-02-PLAN.md — Align thin mirrors, release notes, and the maintainer-facing processor matrix to the public docs spine
- [ ] 160-03-PLAN.md — Add the stable-core posture verifier, extend release-note checks, and wire the docs contract into CI

### Phase 161: Backlog Anchor Closure + Pause Rule
**Goal:** Retire stale roadmap pressure, classify remaining seeds/deferred ideas with revisit triggers, and close the milestone with an explicit pause rule for broad feature work.
**Depends on:** Phase 160
**Requirements:** BAK-01, BAK-02, PAU-01
**Success Criteria** (what must be TRUE):
  1. v1.17 friction anchors, resolved seeds, dormant seeds, and deferred ideas are archived, reclassified, or given explicit revisit triggers.
  2. A planning hygiene proof shows no active roadmap pointer suggests broad feature work is currently active.
  3. PROJECT/STATE/ROADMAP closeout text records that broad feature milestones remain closed unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.
**Plans:** 1/1 plans complete

Plans:
- [x] 161-01-PLAN.md — Close stale backlog anchors, record revisit triggers, and write the post-v1.48 pause rule

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 151. Maintenance & Triage | v1.46 | 3/3 | Complete | 2026-05-30 |
| 152. Close v1.46 closure gaps | v1.46 | 3/3 | Complete | 2026-05-30 |
| 153. Close v1.46 audit trail | v1.46 | 2/2 | Complete | 2026-05-30 |
| 154. Advisory Cache Core Correctness | v1.47 | 1/1 | Complete | 2026-05-31 |
| 155. StripeFixtures Polish + Telemetry Counters | v1.47 | 1/1 | Complete | 2026-05-31 |
| 156. Entitlements Gating Adopter Proof | v1.47 | 1/1 | Complete | 2026-05-31 |
| 157. Metered Usage Adopter Proof | v1.47 | 1/1 | Complete | 2026-05-31 |
| 158. Oban Cron Wiring Adopter Proof | v1.47 | 1/1 | Complete | 2026-05-31 |
| 159. Linked Release Readiness + Publish Proof | v1.48 | 2/2 | Blocked on external release state | — |
| 160. Stable-Core Public Positioning | v1.48 | 3/3 | Complete    | 2026-05-31 |
| 161. Backlog Anchor Closure + Pause Rule | v1.48 | 1/1 | Complete    | 2026-06-01 |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+ and reflected in the processor support matrix. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor; no current broad feature scope follows from this link. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but are not v1.48 closeout blockers and do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| ENT-EXT-01 | deferred | Rich metered, tiered, and range entitlement math is beyond current seat-count support and lacks a sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk that cannot be solved by host-owned exports |
