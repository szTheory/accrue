# Requirements: Accrue

**Defined:** 2026-10-10  
**Milestone:** v1.65 — Accrue Admin Language & Consistency  
**Core Value:** Phoenix developers can install Accrue and its companion Admin UI to launch a real SaaS with subscription billing, with clear billing state and low integration risk.

## v1 Requirements

### Operator Language

- [x] **LANG-01**: On targeted existing Admin screens, support and billing operators can understand the primary activity or state label without decoding an implementation key, and the label remains faithful to the underlying event or state.

### Outcomes and Recovery

- [x] **STATE-01**: For targeted completed, failed, blocked, or unknown outcomes, Admin copy states only what the available evidence confirms, makes clear whether the requested action took effect, and gives a supported next step without inventing a cause.

### Investigation Evidence

- [x] **EVID-01**: When Admin presents a human-readable event or state label, operators can still access the exact event key and relevant record identifiers and timestamps for investigation.

### Shared Language and Patterns

- [x] **CONS-01**: Across targeted existing Admin screens, repeated headings and action names use consistent operator-facing language, and each link or control accurately describes its destination or effect.

## Milestone Guardrails

- Focus only on copy and repeated-pattern issues confirmed in current rendered Admin screens and their owning source/tests. Home's recent activity is an initial candidate; confirm each issue before changing it.
- State what happened, whether an action took effect, and what the operator can safely do next. Keep technical evidence available at the point of investigation.
- Preserve distinctions that affect decisions, including completed versus requested, failure versus inability to confirm, and current state versus historical evidence. Do not ban necessary billing or developer terms wholesale.
- Reuse existing `AccrueAdmin.Copy`, LiveView, and browser test owners. Tie copy assertions to rendered output and exact supporting evidence; do not create a new broad lint rule or CI lane.
- The Mailglass and Scrypath reports supplied by the maintainer provide transferable wording and evidence-provenance lessons. They are guidance, not claims that those repositories' current uncommitted changes shipped or were freshly verified.
- Seed 004 contributes only its operator-clarity and content-hierarchy guardrails. Its diagnosis functions and new-room ideas remain out of scope.

## v2 Requirements

None promoted. Broader Admin information-architecture changes and new diagnosis capabilities remain deferred.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New billing behavior, diagnosis functions, or authorization changes | This milestone refines presentation of existing behavior; semantic or policy defects require separate evidence-backed scope. |
| Portal refinement | The confirmed goal is limited to existing Admin operator screens. |
| New Admin rooms, including Usage or checkout-session surfaces | These are feature expansion and exceed the confirmed cleanup. |
| Admin redesign, rebrand, or broad visual-system changes | The milestone addresses confirmed language and repeated-pattern defects within the incumbent interface. |
| Blanket banned-word or AI-writing lint | It risks suppressing necessary domain vocabulary and does not establish that visible copy is clear or truthful. |
| New test framework or CI lane | Existing copy, LiveView, and browser owners should carry recurring checks. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LANG-01 | Phase 244 | Complete |
| STATE-01 | Phase 244 | Complete |
| EVID-01 | Phase 244 | Complete |
| CONS-01 | Phase 244 | Complete |

**Coverage:**
- v1 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0
- Duplicate mappings: 0

---
*Requirements defined: 2026-10-10*
*Last updated: 2026-10-10 after Phase 244 roadmap mapping*
