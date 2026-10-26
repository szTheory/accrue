# Phase 238 — Planning verification

**Date:** 2026-10-08  
**Result:** Advisory only; no blocker or warning requires revision.  
**Plans verified:** 5  
**Scope:** Static goal-backward plan review. No application tests, builds, provider calls, or served-render inspection were performed.

## Coverage summary

| Requirement | Plans / tasks | Status |
|---|---|---|
| ADM-07 — investigate event/delivery history; replay only eligible work with evidence, step-up, and honest partial results | 238-01 T1–T2, 238-02 T1–T2, 238-05 T1–T2 | Covered |
| ADM-08 — inspect existing coupon, promotion-code, and Connect states/actions without implying unsupported capabilities | 238-03 T1–T2, 238-04 T1–T2, 238-05 T1–T2 | Covered |

## Verification

- All five plans pass `verify.plan-structure`; each has two tasks with the required files/action/verify/done fields.
- Dependencies are acyclic and wave-consistent: 238-01 Wave 0; 238-02/03/04 Wave 1 depend on 238-01; 238-05 Wave 2 depends on all four prior plans. Same-wave plan pairs have no identified undeclared shared-resource coupling.
- Critical key links are specified: owner-scoped reads to exact detail records, replay/override actions through fresh authorization to mutation and audit/result, and the mounted host journey to the CI Playwright shard.
- Security behavior has server-side revalidation, step-up, rejected-action no-mutation checks, and explicit queue-versus-processing and provider-versus-local distinctions.
- UI acceptance is automated through mounted-browser assertions for keyboard/focus, axe, narrow layout, themes, long content, pending and error states. VALIDATION.md does not require routine human UAT.
- The research Open Questions section now marks all three questions RESOLVED and records the plan choices. The CI resolution limits the claim to workflow/shard selection and requires actual CI evidence; it explicitly does not claim repository branch protection from local discovery.
- Plans 238-01 through 238-04 now name the mapped PATTERNS.md analog paths in relevant task actions. The previous research-resolution blocker and pattern-compliance warning are resolved.
- Orchestrator-supplied deterministic probes: verification paths 10/10 resolved; failure directions 10/10 meaningful; UI-SPEC 7/7 and state probe 14/14; API coverage precheck passes without an external integration declaration.
- Calibrated estimates remain under the 100,000-token budget (26k, 19k, 16k, 14k, 19k); all are low confidence because there are no completed-phase actuals, so treat them as rough. Task/file counts are bounded.
- No AGENTS.md, project-local skill directories, or CONTEXT.md was found/provided. Architectural tiers match the research responsibility map; no cross-plan data contract conflict was identified.

## Advisory

1. Plans 238-01, 238-03, and 238-04 still label prohibitions in `must_haves.prohibitions` as `unresolved`, although tasks specify concrete regression assertions for those constraints. This is metadata ambiguity, not missing executable coverage. Reconcile those statuses with the planned assertions when convenient.

## Structured issues

```yaml
issues:
  - plan: "238-01, 238-03, 238-04"
    dimension: prohibition_status_clarity
    severity: info
    required_property: "Prohibition status metadata should clearly correspond to its planned enforcement"
    description: "Several prohibitions remain marked unresolved despite named task behaviors and regression assertions that enforce them."
    fix_hint: "Clarify that the planned assertions are the enforcement or explain what remains unresolved."
```

## Recommendation

Advisory only — no revision required. The plans are ready for execution. Record the actual CI result at execution and keep the stated limit on local evidence versus branch-protection configuration.

## Amendment review — 238-02 T3

**Date:** 2026-10-08  
**Result:** Advisory only; no blocker or warning requires revision.  
**Scope:** Static review of the added T3 against `238-RESEARCH.md`, `238-PATTERNS.md`, `238-UI-SPEC.md`, `238-VALIDATION.md`, the existing T1/T2 contract, and the named DataTable/Events/Event/Webhook implementation seams. No application tests or provider calls were run.

### Assessment

T3 is a focused scope adjustment. The concrete failure mode is present in the named code: `DataTable` directly destructures list-query results in `reload/3` and `load-more`, derives empty state from rows, and has no unavailable state; Events separately runs summary aggregates during mount and parameter changes; Event and Webhook detail mounts currently distinguish only success from not-found (plus the existing ambiguous webhook case). The added task stays within the affected shared component and the three relevant evidence routes, with adjacent deterministic tests. It does not expand provider/replay behavior, introduce packages, or call external systems.

T3 is executable and bounded: one task, eight files, a targeted focused ExUnit command, named read-first analogs, expected database-read failure handling, explicit recovery/partial-page semantics, and negative requirements to preserve true-empty/no-match and not-found distinctions. Its test obligations include both first-page and later-page failure, retry recovery, stale selection/pagination clearing, and unchanged empty/filter behavior. The file count is at the plan's existing upper target (8), while the total plan is three tasks and the revised estimate is 27k tokens with low confidence; this is reasonable for the cross-cutting shared state and route regressions.

The existing must-haves remain covered: event/delivery evidence and exact scope are T1/T2; retry eligibility and fresh step-up are T2; unavailable local history and recovery are T3; provider observation remains explicitly separate/unknown where relevant and is not conflated with local queue acceptance. No phase requirement is dropped.

### Advisory

1. The plan-level `<success_criteria>` still names only exact event/delivery evidence and safe single replay, omitting T3's unavailable/retry/partial-load outcome. T3 has its own explicit `<acceptance_criteria>` and `<done>`, so this does not block execution, but the plan-level completion summary would be clearer if it included the new contract.

### Structured issues

```yaml
issues:
  - plan: "238-02"
    dimension: verification_derivation
    severity: info
    required_property: "Plan-level success criteria reflect all newly added must-have behavior"
    description: "The added T3 acceptance criteria and done condition cover unavailable, retry, and partial-load states, but the plan-level success_criteria still names only scoped evidence and single replay."
    fix_hint: "Optionally include the unavailable/read-recovery contract in the plan-level success_criteria."
```

### Recommendation

Advisory only — no revision required. T3 is a focused and appropriately bounded response to the observed crash and missing recovery state.
