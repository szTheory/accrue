# Proposed v1.68: UI Storybook Stress Testing

**Date:** 2026-10-26. **Status:** reviewed planning proposal; canonical milestone not opened.
**Starting phase if selected:** 252, continuing from v1.67's Phase 251.
**Direction:** [owner brief](../../notes/2026-10-26-ui-storybook-quality-direction.md).
**Decision rationale:** [recommendations](RECOMMENDATIONS.md), [adversarial review](ADVERSARIAL-REVIEW.md).

## Milestone summary for confirmation

**Goal:** Make one important existing billing job inspectable and improvable through real production compositions, domain-valid situations and repeatable mobile/light/dark checks, then use that demonstrated loop to guide wider UI coverage.

**Initial job:** a vendor support/billing operator finds a subscription, understands its state and evidence, reviews a supported next action, and moves between the list and detail with correct scope and context.

**Target features:**
- Real components → groups → areas → section → page examples for this job, with production-owned rendering and no copied screen implementation.
- Shared DB-free scenario facts for stories and narrow persisted/mounted adapters, extending current realism and safety contracts.
- Reachable situation/variation coverage and auditable pruning, with explicit static-versus-mounted evidence.
- Mobile-first responsive layout, both themes, professional hierarchy and microcopy, and fixes to confirmed defects at their lowest owning tier.
- Focused recurring checks in existing CI owners, selected visual evidence and bounded design review with measured cost.

**Reopen basis:** the owner's explicit strategy direction on 2026-10-26 plus concrete source-backed quality-process gaps: metadata-only group rendering and a copied, outdated subscription screen. This is quality of existing surfaces, not a new billing feature campaign.

**Boundaries:** preserve current identity, provider support, host authority and runtime/package boundaries; retain the deterministic kitchen and mounted behavior tests. No product-code changes in this research session. No new dependency, paid evaluator, new Admin room, broad page rewrite, automatic visual rebaseline, or implied provider parity. Wider Admin/Portal jobs remain rolling targets until selected.

## Ordered phase proposal

These are candidate phases and acceptance outcomes, not PLAN files or canonical requirement IDs. Formal requirements and success criteria follow the new-milestone summary confirmation.

| Phase | Deliverable | Observable success | What is deliberately bounded |
|---|---|---|---|
| **252 — Production-backed subscription stories** | Minimal current job/caller coverage map; scenario contract and validators; a shared Subscription summary/facts/action area used by production and Storybook; replace the copied exemplar; first useful variation-aware manifest and render checks; safe isolated lab launch and CI path admission. | Reviewer can open complete active, scheduled-cancellation and incomplete-evidence situations from stable URLs in both themes at narrow and desktop widths. They see the production renderer and real copy/capability inputs. Invalid scenario variants fail validation. Story/scenario/registry/manifest/token-only changes demonstrably trigger the owning checks. | Start with launch/team profile facts in existing Cadence. Existing list/new-account fixtures are mapped without inventing an empty subscription record. DB-free rendering can use the existing DB-backed server only with isolated disposable DB/port and no implicit server reuse. No all-page extraction or separate quality platform. |
| **253 — Real groups and a whole subscription job** | Actual collection toolbar/result/table/pagination composition; replace metadata-only coverage claims for the chosen group; production-shared full subscription screen composition; real list→detail→return behavior. | New-host empty, filtered empty, one/multiple/page-boundary results and actual error/permission states have meaningful, attributable evidence. Production and stories agree on the rendered facts/actions. Mounted tests prove supported navigation, fresh authority, staged action and truth of result. | Keep DataTable stateful. Static stories cover settled presentation; lifecycle/auth/query semantics retain mounted proof. Full-page reuse stops at legitimate session/router/behavior boundaries. |
| **254 — Recurring quality checks, reviewed fixes and curation** | Harden affected-consumer selection and baseline comparison in existing owners; close confirmed responsive/theme/copy/hierarchy findings; useful scenario retirement records; integrated proof and timings; next-job coverage map. | Changed/affected cases and stable sentinels run in CI with non-vacuous negative controls. Relevant breakpoint edges, theme, focus, targets, text resizing and reduced-motion owners are checked. One bounded design review/correction/confirmation is evidenced; no machine score is called design excellence. Duplicate subscription stories retire with their surviving owners. | Checks begin in 252/253; this phase consolidates them, not postpones verification. No unbounded aesthetic loop or owner manual-UAT gate. New rules expose debt explicitly and cannot silently bless regressions. |

Each phase must improve the real reviewer/operator experience as well as the machinery. A named source-backed candidate becomes a product-defect claim only after fresh mounted confirmation. Preserve before/after scenario and rendered evidence when fixing a real UI issue. A valid first outcome can be correcting the known Storybook parity defects; do not invent application defects to meet an arbitrary quota.

## Proposed acceptance outcomes to turn into requirements

1. The selected subscription job has a current composition/caller map through all useful tiers and explicit uncovered/N/A states.
2. Every counted scenario/variation names a real job and situation, its production owner, valid input source and proof lane; aggregate metadata alone cannot satisfy rendering coverage.
3. Subscription area and full-page presentation use production rendering, formatting, copy, scoped-link and eligibility owners; no story-local duplicate business logic.
4. The selected real collection group covers empty/no-results/one/many/page boundary and other applicable states with real component behavior retained.
5. Shared scenario facts are deterministic, domain-valid and distinguish actor, billed entity, provider and lifecycle; deliberately invalid controls fail, and persisted adapters satisfy actual DB constraints.
6. Ordinary preview and held-out stress data remain separate, privacy-safe and bounded in write/cleanup authority.
7. Production builds, package contents and runtime compile paths exclude scenario payloads/dev-only tooling requirements; local review routes have explicit access boundaries and a disposable DB/distinct loopback port, isolated from test reset authorities and unexpected existing-server reuse. A negative control proves normal test reset cannot alter review-session data.
8. Selected compositions preserve essential facts and actions at 320px, representative wider/container widths and relevant breakpoint edges, in both themes.
9. Existing mechanical checks cover applicable accessibility, focus, targets, copy, token/asset identity and motion/text/reflow behavior, with explicit unresolved observations and narrow dispositions.
10. Mounted acceptance proves the real list/detail/action job, fresh authority, exact target and truthful result; stories claim only their actual evidence.
11. Current rendered captures receive one bounded review of hierarchy, typography, color, redundancy, language and job coherence, with confirmed fixes verified at shared owners and source-bound evidence limits.
12. CI path-trigger admission includes every consumed story, scenario support, shared component, registry, manifest, token and runner path with positive/negative controls; manifest/coverage reconciliation and conservative impact selection fail closed. Curation preserves surviving regression protection, and timings determine a frozen affordable selection before broad expansion.

## Rolling roadmap beyond the first milestone

Horizons express sequence and triggers, not dates or assigned versions. The end goal includes all existing useful Admin and Portal jobs; the first milestone's narrow scope is a way to establish and prove the method, not an exclusion of the rest.

| Horizon | Focus | Entry trigger | Exit / next decision |
|---|---|---|---|
| **Immediate — proposed v1.68** | Subscription components, groups, areas and job pages; launch/team facts; real renderer parity and focused quality loop. | Owner scope confirmation of this proposal. | Useful faster inspection, honest story/mounted proof, concrete improvements and measured recurring cost. Select the next highest-value job from the coverage map. |
| **Near — core Admin work** | Customer investigation, invoice/payment queues and details, then recovery and webhook work; reuse list/detail/metrics/timeline patterns. Add learner/operations facts only for distinct cases. | First loop works; current caller inventory ranks frequency, safety and coverage gaps. Recovery expansion requires coherent retry/campaign history. | Each selected job has happy/error/empty/boundary coverage, full-page context and navigation handoffs; shared pattern improvements propagate. Keep uncovered jobs visible. |
| **Mid — broader sections and customer journeys** | Remaining investigation/catalog/Connect compositions and Portal personal/organization/read-only cases; host branding, configurable mounts and coherent customer return paths. Introduce the single-tenant profile only where it changes behavior. | Admin method measured and stable; current Portal contract verified; explicit dev/test host access and dependency/packaging design proved. | Both surfaces share scenario semantics while preserving different actors, density, voice and branding. No account-context authority is inferred from presentation. |
| **Long — continuous curation and deeper stress** | New supported states/adopter incidents, cross-section journeys, additional browser/device sentinels when justified; improve impact selection and reuse of owner-labelled examples. | A new state, supported adopter model or concrete failure exposes a missing equivalence class. | Coverage grows in useful situations and defects prevented, obsolete stories shrink, preview/CI cost stays sustainable. No obligation to simulate every industry or create another critic framework. |

At each milestone boundary, refresh the actor/job map, prune stale or redundant stories with provenance, review coverage gaps and baseline/suppression scope, and measure maintenance cost. Repeated design judgments can become a focused deterministic rule only when that property is actually machine-decidable.

## Cost and stopping rules

Reuse the Admin test lab for the first slice; leave canonical example-host mounts unchanged. Its existing bootstrap starts TestRepo, Oban and Fake: the story renderer can be DB-free while server startup is not. Provide and test a documented disposable DB/namespace and distinct loopback port, identify the process being used, and refuse accidental reuse of another server. Interactive review must not share a mutable server/database with reset-capable mounted tests. Keep cold infrastructure startup separate from warm render/check measurements. A later combined dev/test lab may need an explicit top-level dev/test edge to the **already used** PhoenixStorybook package; justify that then, rather than pretending downstream dev dependencies propagate automatically.

Wire CI admission in Phase 252, not only final consolidation: the current browser-workflow filters omit root `storybook/`, and a proposed `dev_support/` root would also need explicit coverage. Test representative path changes for every consumed story, scenario, shared component, registry, generated manifest, token and runner root, plus an unrelated-path negative control. Name the required owning job and prove invocation; an unconditional existing owner is valid without widening every workflow. The execution/impact selector must never report coverage for a workflow that was not triggered.

Provisional targets for measurement: preview response under 10s warm where feasible, focused local checks under 60s, no more than 3min additional warm browser execution and 5min incremental CI critical-path cost. These are planning targets, not benchmarks or promises. Record boot/setup separately; prefer existing browser jobs and bounded selections. Freeze the actual budget after first-slice measurements. Shared-token changes select all affected consumers; missing impact information broadens selection. Full-manifest broad sweeps run scheduled/on demand initially and graduate stable affordable portions to PR.

Stop research now unless a finding changes scope, order, safety or acceptance. Stop infrastructure expansion if the first real composition is not useful or materially faster to inspect. Stop a review after the agreed batch unless a named unresolved defect justifies more work. Do not lower a gate, hide a finding, or add impossible data to satisfy a count.

## Continuity and other work

- **Session-timezone correctness:** `accrue_events.inserted_at` remains a separate HIGH-priority candidate in v1.67's Future Requirements. This UI proposal neither fixes it nor justifies indefinitely postponing it; a narrow independent correctness fix may be selected before or alongside subsequent UI work. Fixed story clocks cannot prove that DB defect is resolved.
- **SEED-004:** carry delivered M1 hierarchy/operator-clarity guardrails; do not reopen M2 diagnosis APIs/graphs or M3 new rooms.
- **SEED-003:** use bounded prerequisite hygiene when activating the milestone, not a second repository-cleanup campaign.
- **Doc drift:** PRODUCT.md's old statement that mixed-account Portal support is only proposed conflicts with the recorded Phase233 shipped decision. Reconcile against actual code in an authorized Portal/docs slice; do not duplicate implementation based on stale prose.
- **Research carry-forward:** opening this milestone should reuse these findings rather than repeat fan-out. Resolve any later missing requirement narrowly. Preserve canonical historical evidence and local milestone-tag policy.

## Remaining owner decision

Recommend selecting **v1.68 UI Storybook Stress Testing, proposed Phases 252–254**, with the rolling horizons above. Confirm this concrete scope through the new-milestone summary gate before PROJECT/STATE/REQUIREMENTS/ROADMAP writes. No additional brand, architecture, dependency or fixture-style decision needs to be pushed back to the owner at this stage.
