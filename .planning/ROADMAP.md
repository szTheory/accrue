# Roadmap: Accrue

## Active Milestone

### v1.38 Linked Release Truth

**Status:** Closeout in progress  
**Phases:** 120–122  
**Goal:** Close the already-shipped linked `1.1.1` public release cleanly: public proof already exists in Phase 121, and the remaining work is maintainer-facing mirror and inventory closeout.

Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).

| # | Phase | Goal | Requirements |
|---|-------|------|--------------|
| 120 | Release contract audit | Reconcile the real linked package set, publish order, and maintainer runbook before cutting the release. | REL-09, PPX-15 |
| 121 | Linked publish + proof sweep | Cut the release, record the ordered publish proof, and re-run the package/adoption/shift-left contracts against the published line. | REL-10, REL-11, PPX-13, PPX-14 |
| 122 | Post-publish mirrors + friction pass | Align `.planning/` to the public release truth and close the required dated maintainer certification. | HYG-03, INV-08 |

### Phase Details

**Phase 120: Release contract audit**

Goal: Make the runbook, Release Please config, manifest, and workflow speak one language about what is being released and how it is proven.

**Plans:** 3 plans

Plans:
- [x] `120-01-PLAN.md` — freeze the linked release scope decision from current automation and registry evidence
- [x] `120-02-PLAN.md` — apply the chosen scope across the runbook, Release Please config, manifest, and publish workflows
- [x] `120-03-PLAN.md` — add merge-blocking verifier coverage for the chosen release contract

Success criteria:
1. `RELEASING.md`, `release-please-config.json`, `.release-please-manifest.json`, and `.github/workflows/release-please.yml` no longer contradict each other about linked package scope or publish order.
2. The milestone settles the current `accrue_portal` release-truth question explicitly instead of leaving it implicit in automation only.
3. The maintainer-facing publish checklist is concrete enough to execute without guessing from prior milestones.

**Phase 121: Linked publish + proof sweep**

Goal: Publish the current line and prove the shipped release through tags, changelogs, registry outcomes, and merge-blocking doc/verifier lanes.

**Plans:** 3 plans

Plans:
- [x] `121-01-PLAN.md` — verify or repair the live Release Please PR and stage deterministic proof tooling before merge
- [x] `121-02-PLAN.md` — merge the verified release PR, watch the ordered publishes, and capture public release evidence
- [x] `121-03-PLAN.md` — align post-publish docs and rerun the shift-left bundle against the released line

Success criteria:
1. The linked release landed for the intended package set with matching `@version`, tag, changelog, and registry evidence.
2. Ordered publish proof exists for the dependency chain between core and UI packages in `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`.
3. `verify_package_docs`, `verify_adoption_proof_matrix`, and the touched shift-left release contracts passed against the post-release state.

**Phase 122: Post-publish mirrors + friction pass**

Goal: Make the planning mirrors and maintainer continuity docs reflect the published line cleanly after release.

Phase 122 is the maintainer-facing closeout for live planning mirrors and INV-08, not a new release-proof pass.

Success criteria:
1. `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` all state the same public release truth.
2. The dated post-publish friction certification is recorded, or new sourced friction rows are added with evidence if release work exposed real adoption gaps.
3. The milestone closes without stale active phase directories or contradictory “current public version” callouts.

## Recent Milestones

- ✅ **v1.37 Subscription Change Management** — Phases **117–119** shipped **2026-05-07**. Promoted official swap/preview semantics, shipped admin and portal change flows, and finalized bounded Braintree `:plan_resolver` support plus drift gates. Archives: [milestones/v1.37-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-ROADMAP.md), [milestones/v1.37-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-REQUIREMENTS.md).
- ✅ **v1.36 Dual-Provider Core Completion** — Phases **112–116** shipped **2026-05-07**. Promoted bounded first-party customer update, normalized provider-honest cancellation semantics, locked the support-contract verifier bundle, and restored the audit-required verification chain. Archives: [milestones/v1.36-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-ROADMAP.md), [milestones/v1.36-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-REQUIREMENTS.md).
- ✅ **v1.35 Dual-Provider Supportability Closure** — Phases **109–111** shipped **2026-05-07**. Provider-honest support contract mirrors, lifecycle semantics SSOT, and Braintree webhook/operator recovery proof. Archives: [milestones/v1.35-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-ROADMAP.md), [milestones/v1.35-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-REQUIREMENTS.md).
- ✅ **v1.34 Rendro Native Invoice PDF Default** — Phases **106–108** shipped **2026-05-06**. Rendro default invoice path, explicit Chromic compatibility path, and Hex-backed release proof. Archives: [milestones/v1.34-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-ROADMAP.md), [milestones/v1.34-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-REQUIREMENTS.md).

## Notes

- `v1.38` is intentionally a release-operational milestone, not another feature-depth milestone.
- Advanced schedules, broader pause/resume promotion, broader preview/proration parity, Hyperwallet reopening, and `FIN-03` stay out of scope unless a later milestone explicitly reopens them.
- Maintenance triage references remain canonical in the archived v1.17 inventory backlog slices: [INT-10](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

---
*Last updated: 2026-05-07 — **v1.38** opened for linked release truth.*
