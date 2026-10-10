---
phase: 241-billing-operator-journeys
status: passed
checked: 2026-10-09
plan_count: 7
wave_count: 4
next_command: "$gsd-execute-phase 241"
---

# Phase 241 — Verified Planning Handoff

## Current position

Phase 241 planning is complete and ready for execution. Phase 240 is the last
completed implementation. Phase 241 has zero executed plans; JRN-01 through
JRN-04 remain pending implementation and verification. Milestone v1.64 remains
1/4 phases complete, with 6/13 currently planned plans executed.

After clearing context, run:

```text
$gsd-execute-phase 241
```

This handoff and STATE.md's current focus/session supersede older discussion
or planning commands retained in historical milestone prose. Do not repeat
milestone kickoff, Phase 240 delivery, Phase 241 discussion, broad research,
UI contract creation or planning. Reopen an accepted decision only for a named
new defect or contradictory evidence.

## Execution inventory

| Wave | Plans | Work |
|------|-------|------|
| 1 | 241-01, 241-02 | Subscription facts/customer invoice destinations; validated return meaning and invoice returns |
| 2 | 241-03, 241-04 | Payment/customer/subscription returns; scoped Recovery and campaign windows |
| 3 | 241-05, 241-06 | Subscription action reviews; refund and payment-method reviews |
| 4 | 241-07 | Package browser and mounted-host journey/served-asset evidence |

All seven plans are autonomous, with two `type="auto"` tasks each. Dependencies
are declared in plan frontmatter; use those for execution scheduling. Each task
owns executable acceptance and a failure direction. There is no required human
UAT checkpoint. The repository's executable-acceptance policy governs vertical
slices; generic tracer tags must not add a human handoff.

| Requirement | Owning plans |
|-------------|--------------|
| JRN-01 | 241-01, 241-07 |
| JRN-02 | 241-02, 241-03, 241-07 |
| JRN-03 | 241-04, 241-07 |
| JRN-04 | 241-05, 241-06, 241-07 |

## Planning gate evidence

- Independent typed plan recheck: **VERIFICATION PASSED**, seven plans, zero
  remaining blockers or warnings. One bounded revision resolved two blockers:
  execution references now use portable `$HOME` paths, and package assets build
  before browser proof.
- Decision coverage gate: **20/20 covered**, zero uncovered decisions.
- Registered post-planning gap gate: **24/24 covered** (four requirements and
  twenty decisions), `passed: true`, `block: false`.
- Verify-path probe: **14 commands**, zero blockers/warnings, `readError: null`.
- Failure-direction probe: **14 commands**, zero blockers/warnings,
  `readError: null`. These probes inspect authored commands; they do not run tests.
- UI contract independently approved after inherited-authority corrections.
  Compiled UI criteria: **40 applicable / 40 explicit / zero unresolved**;
  edge criteria: **20 applicable / 20 explicit / zero unresolved**. Canonical
  resolutions are preserved in UI-SPEC.md and PROBE-COVERAGE.md. These are
  contract coverage results, not implementation evidence.
- UI prerequisite gate: UI-SPEC present, no block. API contract and assumption
  delta detectors found no applicable new contract. No schema or AI integration
  work is introduced.
- Validation remains appropriately **draft**, `nyquist_compliant: false` and
  `wave_0_complete: false` until the planned assertions execute. No source
  implementation, server, browser suite or implementation test ran in planning.

## Execution constraints that prevent churn

Read CONTEXT.md, UI-SPEC.md, RESEARCH.md, PATTERNS.md, VALIDATION.md and
PROBE-COVERAGE.md with the selected plan. Preserve the Phase 240 system and
closed v1.63 contracts. Keep customer invoice sets distinct from broader scope
queues; derive a return label and href from one validated supported meaning.
Existing scope, authorization, step-up, exact-money, stale-state and duplicate
protections remain at their current owners. Results must distinguish accepted,
pending, completed, failed, denied and unknown evidence.

Build package assets in 241-07 Task 1 before package browser checks. Use fresh
CI servers; Task 2 consumes that same build for mounted-host served-byte proof.
Generated CSS/JS are explicitly owned by 241-07. Source inspection alone cannot
close mounted or served-asset acceptance. Preserve the Linux snapshot-set guard;
final reviewed golden closure remains Phase 243.

Use existing ExUnit, browser and host owners. Add focused checks with each
owning change; introduce no new dependency, billing capability or CI matrix.
Inspect each changed consumer for keyboard/focus, narrow/coarse-pointer use,
effective themes and patch/reconnect behavior. Keep one inspection batch, one
corrective batch and at most one confirming inspection per delivery batch.
Optional maintainer feedback does not replace executable acceptance.

## Bookkeeping

Registered GSD writers recorded Ready to execute, seven plans, the roadmap's
0/7 Planned row, and four wave groups. The roadmap writer retains older
freeform next-command prose and the `Plans: TBD` description; the explicit
seven-plan checklist, progress row, current STATE focus/session and this handoff
provide the current execution authority. No direct STATE/ROADMAP edits were used.

Manual invocation leaves persistent auto-advance disabled and clears the
ephemeral chain flag. The next operation is execution through the command above.
