# Requirements: Accrue v1.64 Admin Operator UI Cleanup

**Defined:** 2026-10-09
**Status:** Requirements and four-phase roadmap approved by maintainer on 2026-10-09; Phase 240 verified complete (8/18 requirements); Phases 241–243 remain.
**Core value:** A Phoenix developer can install Accrue and its companion Admin and launch subscription billing without avoidable integration or operational risk.

## Milestone requirements

### Shared design and interaction system

- [x] **DSN-01**: Operators can scan identity, current facts and next actions through consistent shared typography, spacing and hierarchy in existing list, detail and action-review compositions.
- [x] **DSN-02**: Operators can read essential facts and activate controls with long or missing data at narrow, desktop and tablet/coarse-pointer layouts, including text enlargement and zoom without lost task access.
- [x] **DSN-03**: Operators can select and retain Light, Dark or System, with one selected preference, correct effective styles and existing host-forced theme behavior.
- [x] **DSN-04**: Operators retain correct labels, icons, disabled state and task context through actual busy completion, repeated LiveView updates and reconnect, without premature enabling or replay of a staged action.
- [x] **DSN-05**: Keyboard users can complete touched navigation and review flows with visible focus, associated validation/status semantics, overlay containment and logical focus return after dismissal, correction or replacement.

### Operator journeys

- [x] **JRN-01**: Operators following subscription invoice links reach exactly the supported customer or owner result set described by the visible label.
- [x] **JRN-02**: Operators can enter existing filtered lists, open details and return with supported owner, filter/lens and customer-tab context intact through validated local destinations.
- [x] **JRN-03**: Operators opening a campaign directly return to Recovery, while navigated campaign returns preserve the selected recovery window and scope.
- [x] **JRN-04**: Operators can review supported billing actions in self-contained content showing the exact target, material customer/scope, money and consequence, then receive evidence-specific outcomes.
- [x] **JRN-05**: Operators can trace existing events and webhook deliveries through related evidence and supported replay review without hiding material failures, uncertainty or exact diagnostic detail.
- [x] **JRN-06**: Operators can inspect existing discounts, promotion-code relationships and Connect facts with supported actions and explicit stored-provider versus local-policy boundaries.
- [x] **JRN-07**: Operators can find the correct scoped record using the existing Home, navigation and search, with consistent visible selection across pointer and keyboard input.

### Domain language and state communication

- [ ] **UXC-01**: Operators see coherent resource, collection-method and action language across lists, details, filters and reviews, while exact diagnostic terms and locked audit/legal meaning remain intact.
- [x] **UXC-02**: Operators can distinguish empty, no-match, unavailable, partial, unsupported, denied, pending, failed and unknown states and choose the supported next step without inferred health or completion claims.

### Delivery and evidence

- [x] **EVR-01**: Maintainers can inspect current route, interaction, component and state coverage with source, fixture and served-asset provenance, keeping historical, rendered and exercised evidence distinct.
- [x] **EVR-02**: Maintainers receive faithful recurring regression proof with each delivery slice in existing acceptance owners, including focused failure controls for new guards and no confirmation-only human UAT dependency.
- [ ] **EVR-03**: Maintainers receive blocking visual regression results for the complete expected Linux snapshot set, with reviewed intended updates and masks that preserve task-critical information.
- [ ] **EVR-04**: Maintainers can start and use the documented Fake-backed Admin feedback preview without mutation/reset proof disturbing it, with honest transport, local/remote and provider evidence limits.

## Acceptance constraints

- Preserve completed v1.63 authorization, owner/target/material-state revalidation, step-up, duplicate protection, exact currency/minor-unit precision, provider capability and accepted/pending/completed/unknown outcome contracts. Reuse their precise existing owners; do not repeat completed feature work.
- Use the incumbent Admin Cobalt identity, Geist/Geist Mono, `--ax-*` roles and existing registry. Retain deliberate 2px dense and 1px structural exceptions; fix unexplained section compression at its source only after current mounted confirmation.
- The first delivery slice includes an actual invoice list/detail/review exemplar and a dense subscription check, not a documentation-only foundation phase. Confirm or close source candidates before propagation.
- Routine filters, scope, material blockers, action facts and uncertainty remain visible. Engineering payloads/identifiers remain discoverable through familiar disclosure. Keep current route families and Home; use tables only where comparison warrants them.
- Returns preserve enumerated supported filters/lens/window/tab meanings, not arbitrary external origins, foreign owners, all accumulated pagination, scroll position, or an unbounded multi-hop stack. No new subscription invoice filter is required.
- Checks accompany each owning change. Reuse existing ExUnit, integration, package browser, mounted host, axe, registry/token/build and Linux pixel lanes. Retain required checks and focused negative controls; no duplicate full-suite workflow, hiding exclusions, new fixed sleeps or blanket retry/tolerance increases.
- Effective styles, clickable geometry and focus/state transitions must be exercised where claimed. Axe and accessibility-tree assertions are supplementary evidence, not universal WCAG certification, screen-reader speech or physical-device proof. CSS zoom simulation is labeled separately from actual browser zoom; tool limitations are explicit.
- Motion is purposeful and restrained; repeated keyboard work stays immediate, reduced motion removes nonessential travel, and inactive overlays cannot retain hit targets. No decorative page/list stagger or animated money/counts.
- Rebuild package-owned committed assets with `mix accrue_admin.assets.build` and confirm compiled served CSS/JS/font identity. Host watchers do not establish package bundle freshness.
- Extend selected stable Linux goldens only when they add recurring protection. Missing all or part of the expected set fails; masks cover only explicitly volatile values, never money, state, action, identity or error meaning. Preserve snapshot thresholds unless a separate evidenced policy decision is approved.
- A non-GET page HTTP observer supports an HTTP-scoped claim. Broader no-mutation proof uses authoritative state/dispatch/audit assertions in disposable fixtures; LiveView frames are not automatically writes.
- Per agreed delivery batch: complete changes/checks, inspect desktop/narrow and effective themes together, apply one corrective batch, confirm at most once. Captures/scans/edits/rebuilds share that budget. Reopen only for named evidence or explicit owner feedback.
- Record lightweight comparable performance/resource diagnostics with the fresh exemplar; investigate observed deterioration. No invented timing SLA or new performance platform is required.
- Impeccable init/code-first and operator personas are settled. The [upstream decisions](research/v1.64/SUMMARY.md) are complete; don't repeat that review. Zero required human UAT is the target; subjective owner feedback after delivery is optional.

## Future requirements

No new future capability is promoted by this cleanup. SEED-004 diagnosis/causality/new rooms, Portal refinement and other existing backlog choices retain their recorded future decision gates.

## Out of scope

| Item | Reason |
|---|---|
| Portal/checkout restyling or new billing/provider capability | Admin-only refinement; completed v1.63 contracts remain protected. |
| Diagnosis backend, causality graphs or new Usage/Settings/checkout rooms | SEED-004 M1 shipped; M2/M3 are distinct future scope choices. |
| New subscription invoice filter | Correct the visible promise using existing supported context. |
| Rebrand, font/framework migration or new motion dependency | Incumbent system supports this work; avoid unnecessary migration. |
| Paid AI scoring or parked v1.56 evaluator revival | Bounded agent inspection and deterministic recurring proof meet the brief. |
| Exhaustive route × state × theme × viewport screenshot matrix | Existing semantic owners plus representative changed archetypes avoid duplicate cost. |
| Global CI redesign, release publication, unrelated ship-window or historical UAT debt | Separate recorded ownership; cleanup cannot silently reopen or waive it. |
| Required owner taste sign-off or universal accessibility/device certification | Optional feedback and precise automated evidence limits, not a delivery dependency. |

## Traceability

Each approved requirement has one primary phase owner in the approved roadmap. Shared safety, accessibility, responsive/theme, language, asset and acceptance obligations also apply to every affected later delivery slice without duplicating ownership.

| Requirement | Phase | Status |
|---|---|---|
| DSN-01 | Phase 240 | Complete |
| DSN-02 | Phase 240 | Complete |
| DSN-03 | Phase 240 | Complete |
| DSN-04 | Phase 240 | Complete |
| DSN-05 | Phase 240 | Complete |
| JRN-01 | Phase 241 | Complete |
| JRN-02 | Phase 241 | Complete |
| JRN-03 | Phase 241 | Complete |
| JRN-04 | Phase 241 | Complete |
| JRN-05 | Phase 242 | Complete |
| JRN-06 | Phase 242 | Complete |
| JRN-07 | Phase 242 | Complete |
| UXC-01 | Phase 242 | Pending |
| UXC-02 | Phase 240 | Complete |
| EVR-01 | Phase 240 | Complete |
| EVR-02 | Phase 240 | Complete |
| EVR-03 | Phase 243 | Pending |
| EVR-04 | Phase 243 | Pending |

**Coverage:** 18/18 approved requirements mapped once in the approved roadmap; 0 orphaned and 0 duplicated. Eight Phase 240 requirements are Complete after implementation and independent verification; ten later-phase requirements remain Pending.

---
*Last updated: 2026-10-09 after Phase 240 independent verification and completion.*
