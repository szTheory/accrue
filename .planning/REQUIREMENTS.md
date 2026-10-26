# Requirements: Accrue

**Defined:** 2026-10-26
**Milestone:** v1.68 UI Storybook Stress Testing
**Core Value:** A Phoenix developer can install Accrue and its companion interfaces and launch a real SaaS with understandable, production-grade subscription billing on day one.

The owner approved the [reviewed subscription-first proposal](research/ui-quality-engine/MILESTONE-PROPOSAL.md) with “what do u rec? do that”. These atomic requirements derive from that scope; routine wording and implementation choices do not reopen its approval. [Owner direction](notes/2026-10-26-ui-storybook-quality-direction.md) and [recommendations](research/ui-quality-engine/RECOMMENDATIONS.md) carry the rationale and evidence limits. v1.68 implementation is underway; SBK-02, SBK-03, SCEN-01, and SCEN-02 have implementation evidence. Prior requirements are preserved in [v1.67's archive](milestones/v1.67-REQUIREMENTS.md).

## v1.68 Requirements

### Production-backed stories and a real job

- [ ] **SBK-01**: Maintainer can locate the subscription job's real production callers and useful component → group → area → section → page compositions in one current coverage map, with reachable, uncovered and not-applicable states distinguished and remaining UI jobs visible as gaps.
- [x] **SBK-02**: Reviewer can open each retained subscription situation from a stable story/variation URL with its actor, job, input source, production renderer and static-versus-mounted proof lane identified; generated discovery reconciles with actual rendered variations, and metadata-only markers cannot satisfy rendering coverage.
- [x] **SBK-03**: Reviewer can inspect complete active, scheduled-cancellation and incomplete-evidence subscription areas rendered by the same production-owned summary/facts/action components used by the application, in light/dark and narrow/desktop contexts, without copied markup or story-local formatting, copy, eligibility or scoped-link rules.
- [ ] **SBK-04**: Reviewer can inspect the actual subscription collection toolbar/result/table/pagination composition for new-host empty, filtered-empty, one-row, multiple-row and page-boundary situations, plus source-supported loading/error states; existing DataTable lifecycle and event targeting remain intact.
- [ ] **SBK-05**: Reviewer can inspect a production-shared whole subscription detail screen composed from its real areas, including supported review/action presentation and legitimate incomplete evidence, without a story-specific parallel page or a universal page-schema refactor.
- [ ] **SBK-06**: An authorized operator can follow the real subscription list → detail → supported action review/result → context-preserving return journey, with mounted automated proof of current scope, fresh authority, exact target, applicable step-up, dismissal without dispatch and truthful outcome; stories do not claim persistence or provider completion.

### Realistic shared scenario facts

- [x] **SCEN-01**: Maintainer can select deterministic launch/new-account and growing-team situations in the existing Cadence world from one DB-free fact source, with explicit actor, billed entity, supported provider, lifecycle, fixed clock and stable identities, consumed through narrow story/test/seed adapters rather than a cross-package fixture framework.
- [x] **SCEN-02**: Maintainer can reject impossible realistic fixtures before rendering using real domain helpers and cross-record invariants for enums, relationships, provider compatibility, money and chronology; deliberately invalid enum, orphan, provider, amount and timestamp controls demonstrate rejection without duplicating billing rules.
- [ ] **SCEN-03**: Maintainer can persist representative shared scenarios through a narrow disposable Repo adapter and prove actual database constraints and resulting record relationships match the source facts; DB-free validation alone is never reported as persisted conformance.
- [ ] **SCEN-04**: Reviewer can use plausible ordinary data and separately labelled held-out stress data without cross-lane contamination, real personal data or secrets; existing guarded writes and exact cleanup authority remain proved, including refusal to remove unrelated children.

### Safe review tooling and publication boundaries

- [ ] **LAB-01**: Maintainer can launch the reused lab with documented prerequisites, an explicit disposable database/namespace, distinct loopback port and process identity, refusal of unexpected existing-server reuse, and a negative control proving a normal test reset cannot alter review-session data; DB-free rendering is distinguished from DB-backed endpoint startup.
- [ ] **LAB-02**: An adopter can compile and use production packages without scenario payloads, fixture imports, Storybook runtime requirements or Node tooling, with production-route absence and package-content/compile checks; canonical example-host dev mounts and the independent component kitchen remain preserved.

### Recurring checks and affordable execution

- [ ] **CIQ-01**: A change confined to any consumed story, shared scenario, component, registry, generated manifest, token or runner root invokes its named required CI owner, proved by representative positive path/classifier controls and an unrelated-path negative control; in-job selection cannot substitute for workflow admission.
- [ ] **CIQ-02**: Maintainer can see which changed/affected scenarios and stable sentinels the recurring browser checks ran, with total/selected IDs, explicit exclusions and conservative broad selection when dependency metadata is missing or ambiguous; isolated pure-story cases can be scheduled independently without unsafe parallel resets of shared mounted fixtures.
- [ ] **CIQ-03**: Maintainer can compare selected subscription states in both themes and meaningful narrow/desktop contexts using the existing Linux visual-baseline owner, deterministic data/fonts/motion and current source/served-asset identity, with deliberate reviewed baseline changes and no masking of essential identity, money, state or actions.
- [ ] **CIQ-04**: Maintainer can reproduce measured cold startup, warm preview/check and incremental CI costs and use a frozen affordable selection/budget before widening coverage; targets begin at under 10s warm preview where feasible, under 60s focused checks, at most 3min additional warm browser work and 5min incremental CI critical path, with deviations explicitly resolved without weakening existing checks.

### Responsive, accessible and intentionally designed UI

- [ ] **UXQ-01**: Operator can read essential identities, exact amounts, state and actions and use the selected subscription compositions at 320 CSS px, representative wider/container widths and affected breakpoint edges in both themes, without page-level horizontal overflow or hiding essential content to pass a check.
- [ ] **UXQ-02**: Operator can use the selected compositions with keyboard/focus, applicable target-size and contrast rules, meaningful accessible names, supported text enlargement/reflow and normal/reduced-motion behavior, proved through existing browser/axe/component owners; unresolved axe observations and standard exceptions have narrow explicit dispositions rather than silent passes or broad suppressions.
- [ ] **UXQ-03**: Operator can understand consistent subscription labels, destinations, action consequences and recovery messages using existing Copy/voice/domain owners, while engineering investigation retains exact identifiers and technical evidence and locked legal/replay meaning remains unchanged.
- [ ] **UXQ-04**: Maintainer can inspect one bounded source-bound rendered review/correction/confirmation record for typography, color, hierarchy, redundancy, affordances, microcopy and journey coherence across representative mobile/desktop and both themes, with confirmed defects fixed at their lowest owning tier and mechanically verifiable outcomes tested; no aesthetic score, screenshot stability or owner manual UAT substitutes for evidence.

### Curation and continued coverage

- [ ] **CURATE-01**: Maintainer can merge or retire stale, impossible or duplicate subscription stories with recorded reachability/reason and a surviving owner or replacement ID, while preserving meaningful legacy/API/negative regression protection and existing kitchen proof; no deletion follows solely from grep absence or similar screenshots.
- [ ] **CURATE-02**: Maintainer can choose the next existing UI job from a current actor/job/composition gap map and distinct adopter-profile briefs, with remaining Admin/Portal horizons, uncovered states, review triggers and maintenance cost explicit; raw story counts or decorative industry demos do not drive expansion.

## Future Requirements

Directional, not committed to this milestone. See the [rolling roadmap](research/ui-quality-engine/MILESTONE-PROPOSAL.md#rolling-roadmap-beyond-the-first-milestone).

- **Near:** customer investigation, invoice/payment queues and details, then recovery/webhook work using the demonstrated compositions; recovery expansion first reconciles retry/campaign-history fixture integrity.
- **Mid:** remaining investigation/catalog/Connect sections and Portal personal/organization/read-only/host-brand journeys, after current contract verification and explicit dev/test harness wiring. Reconcile PRODUCT.md's stale proposed-versus-shipped mixed-account wording against code.
- **Long:** supported adopter incidents and new equivalence classes, cross-section journeys, justified browser/device sentinels, better impact selection and continual pruning. Learner/operations/self-hosted profiles are synthetic briefs until a distinct case is selected.
- **HIGH, independent correctness candidate:** `accrue_events.inserted_at` follows the Postgres session timezone under its current default. A migration or app-side timestamp correction remains separate; fixed story clocks do not resolve it and this milestone is not authority for indefinite deferral.
- **Preserved prior backlog:** wider `_build` caching; Phase250 helper awareness of provider-proof `should_run`; webhook multi-status/raw-type duplication; retry-history seed integrity; LiveView lock alignment; ExMoney/Storybook asset notices; Sigra wrong-password datetime triage; dead Phase190 workflow alternation; mailglass 1.x-cap documentation; stale historical evidence-verifier recapture/retirement. Source detail remains in [v1.67 Future Requirements](milestones/v1.67-REQUIREMENTS.md#future-requirements).

## Out of Scope

| Item | Reason |
|---|---|
| New billing capabilities, provider parity or money-movement semantics | Existing-surface quality and evidence are the approved scope. |
| Portal implementation or all-page extraction in v1.68 | Wider jobs are rolling direction; first prove the subscription loop's value and cost. |
| New Admin rooms, diagnosis APIs/graphs, SEED-004 M2/M3 | Delivered M1 clarity/hierarchy is context, not authorization for new domains. |
| Rebrand, token-ownership migration, broad Tailwind/style bans | Preserve current brand roles, Admin implementation scales and host-owned Portal identity. |
| New dependency campaign, paid judge or parked ratchet revival | Reuse existing tools and bounded in-session review; keep dependency trees small. |
| Removing the component kitchen or canonical-host mount changes | Independent test renderer and dev-route boundaries have explicit existing contracts. |
| Exhaustive prop/persona/provider/viewport Cartesian products | Cover distinct reachable situations; broader sweeps must justify cost. |
| Weakening gates, automatic screenshot approval, misleading quality claims | Mechanical stability, static rendering and metadata do not establish design excellence or behavior. |
| Mandatory repeated owner UAT, public push/merge/publication or tag push | Automated acceptance remains the default; milestone initialization does not authorize external release actions. |

## Traceability

Each requirement is assigned to exactly one of the approved Phases 252–254. All remain Pending; mapping is not implementation evidence.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SBK-01 | Phase 252 | Pending |
| SBK-02 | Phase 252 | Complete |
| SBK-03 | Phase 252 | Complete |
| SBK-04 | Phase 253 | Pending |
| SBK-05 | Phase 253 | Pending |
| SBK-06 | Phase 253 | Pending |
| SCEN-01 | Phase 252 | Complete |
| SCEN-02 | Phase 252 | Complete |
| SCEN-03 | Phase 252 | Pending |
| SCEN-04 | Phase 252 | Pending |
| LAB-01 | Phase 252 | Pending |
| LAB-02 | Phase 252 | Pending |
| CIQ-01 | Phase 252 | Pending |
| CIQ-02 | Phase 254 | Pending |
| CIQ-03 | Phase 254 | Pending |
| CIQ-04 | Phase 254 | Pending |
| UXQ-01 | Phase 253 | Pending |
| UXQ-02 | Phase 254 | Pending |
| UXQ-03 | Phase 253 | Pending |
| UXQ-04 | Phase 254 | Pending |
| CURATE-01 | Phase 254 | Pending |
| CURATE-02 | Phase 254 | Pending |

**Coverage:**
- v1.68 requirements: 22 total
- Mapped to phases: 22/22 (Phase 252: 10; Phase 253: 5; Phase 254: 7)
- Unmapped: 0
- Duplicate mappings: 0
- Implementation status: 4 Complete, 18 Pending

---
*Requirements defined: 2026-10-26 from the owner-approved reviewed proposal.*
*Last updated: 2026-10-26 after scope approval; implementation remains pending.*
