# Phase 114: Contract Drift Gate Closeout - Planning Pattern Map

**Mapped:** 2026-05-07
**Primary analogs:** Phase 112 and Phase 113
**Secondary analogs:** Phases 109, 110, 111

## Reusable Plan Structure

- Use a 3-plan sequence with one plan per wave: `01` runtime/canonical truth first, `02` docs and user-facing mirrors second, `03` drift gates + proof closeout last.
- Keep each `*-PLAN.md` to 2 `type="auto"` tasks. Both Phase 112 and Phase 113 use a strict 2-task shape across all three plans.
- Start each plan with YAML frontmatter, then `<objective>`, `<execution_context>`, `<context>`, `<tasks>`, `<threat_model>`, `<verification>`, `<success_criteria>`, and `<output>`.
- Each task should include `name`, `files`, `read_first`, `acceptance_criteria`, `action`, `verify`, and `done`.
- Keep plans narrowly scoped to one truth seam at a time. Avoid mixing runtime semantics, docs, and drift gates in the same wave unless the seam is inseparable.

## Wave Sizing

| Pattern | Evidence |
|---|---|
| Wave 1 closes the canonical/runtime truth first | [112-01-PLAN.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-01-PLAN.md:1), [113-01-PLAN.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-01-PLAN.md:1) |
| Wave 2 mirrors that truth into docs/UI/host surfaces | [112-03-PLAN.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-03-PLAN.md:1), [113-02-PLAN.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-02-PLAN.md:1) |
| Wave 3 adds drift gates and targeted proof after wording settles | [112-02-PLAN.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-02-PLAN.md:1), [113-03-PLAN.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-03-PLAN.md:1) |

Recommended Phase 114 sizing:

1. `114-01`: canonical contract/mirror closeout and concise planning-mirror fixes.
2. `114-02`: package docs and example-host docs align to the matrix without becoming a second spec.
3. `114-03`: tighten the targeted CI bundle and add final closeout proof/readme guidance.

## Frontmatter Conventions

Copy the plan frontmatter shape from [113-01-PLAN.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-01-PLAN.md:1):

```yaml
phase: 113-cancellation-semantics-closure
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - path/to/file
autonomous: true
requirements:
  - PROC-22
must_haves:
  truths:
    - "..."
  artifacts:
    - path: path/to/file
      provides: ...
  key_links:
    - from: path/a
      to: path/b
      via: "..."
      pattern: "..."
```

Stable conventions across 109-113:

- `phase` uses the full phase slug, not just the number.
- `plan` is zero-padded: `01`, `02`, `03`.
- `wave` matches the plan order and stays single-wave per file.
- `depends_on` is empty only for plan `01`; later plans depend on earlier ones explicitly.
- `requirements` names requirement IDs directly.
- `must_haves.truths` captures the user-visible truths the wave must make real.
- `must_haves.artifacts` lists concrete outputs with `provides`.
- `must_haves.key_links` describes cross-file couplings the executor must preserve.

## Verification Style

- Pair every task with one automated command. This is consistent in [112-VALIDATION.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-VALIDATION.md:1), [113-VALIDATION.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-VALIDATION.md:1), and [110-VALIDATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-VALIDATION.md:1).
- Use ExUnit for runtime semantics and bash/`rg` gates for fixed wording or matrix drift. Phase 114 should preserve that split instead of introducing a mega-verifier.
- Keep verification commands focused and local to the touched seam. Full bundle commands belong in the plan-level `<verification>` section and the phase `*-VALIDATION.md`, not in every task.
- Validation files use this frontmatter shape:

```yaml
phase: 113
slug: cancellation-semantics-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
```

- Validation body convention:
  - `Coverage Audit` when multiple locked decisions need explicit traceability.
  - `Test Infrastructure` with quick/full commands and runtime estimate.
  - `Sampling Rate` with after-task and after-wave cadence.
  - `Per-Task Verification Map` keyed by `Task ID`.
  - `Wave 0 Requirements` proving all proof lanes and scripts already exist.

## Plan-Check Pattern

- Keep a phase-level `*-PLAN-CHECK.md` with `## VERIFICATION PASSED`, coverage summary, plan summary, and gate notes.
- Gate notes should explicitly confirm:
  - requirement coverage
  - dependency correctness
  - Nyquist compliance
  - scope sanity
  - pattern compliance against `*-PATTERNS.md`
  - research/context resolution

Best analogs: [112-PLAN-CHECK.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-PLAN-CHECK.md:1), [109-PLAN-CHECK.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-phases/109-support-contract-truth/109-PLAN-CHECK.md:1).

## Summary Artifact Pattern

- After each plan, write a `*-SUMMARY.md`.
- Newer summaries in Phase 113 have richer frontmatter and are the better template for Phase 114:
  - `subsystem`
  - `tags`
  - `requires`
  - `provides`
  - `affects`
  - `tech-stack`
  - `key-files`
  - `key-decisions`
  - `patterns-established`
  - `requirements-completed`
  - `duration`
  - `completed`
- Body sections usually include:
  - `Performance`
  - `Accomplishments`
  - `Task Commits`
  - `Files Created/Modified`
  - `Decisions Made`
  - `Deviations from Plan`
  - `Issues Encountered`
  - `Next Phase Readiness`
  - `Self-Check`

Best analogs: [113-01-SUMMARY.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-01-SUMMARY.md:1), [113-02-SUMMARY.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-02-SUMMARY.md:1), [113-03-SUMMARY.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-03-SUMMARY.md:1).

## Closeout Patterns From 112/113

- Closeout phases end with explicit verification and review artifacts, not just summaries.
- `*-VERIFICATION.md` should score observable truths against the phase goal and cite concrete evidence links. Best analogs: [112-VERIFICATION.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-VERIFICATION.md:1), [111-VERIFICATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-phases/111-webhook-operator-closure/111-VERIFICATION.md:1).
- `*-REVIEW.md` should be terse YAML + findings summary. Phase 113 shows the preferred “review findings first, remediation second” closeout pattern even when the final status is clean: [113-REVIEW.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-REVIEW.md:1).
- Auto-fixed issues belong in the plan summary under `Deviations from Plan`, with the fix constrained to the planned seam. Best analogs: [112-REVIEW.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-REVIEW.md:1), [113-01-SUMMARY.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-01-SUMMARY.md:1).

## Phase 114-Specific Reuse

- Reuse the Phase 113 sequencing most directly:
  - Plan 01: co-update canonical matrix plus concise planning mirrors.
  - Plan 02: align package docs and example-host docs to the canonical contract.
  - Plan 03: tighten targeted bash gates and document the support-contract bundle in `scripts/ci/README.md`.
- Reuse the Phase 112/113 rule that runtime/proof truth moves before wording mirrors, and wording mirrors settle before drift gates harden.
- Keep the example host thin. The Phase 112 host-helper work and the Phase 114 context both reject turning `examples/accrue_host` into a second spec.

## Recommended Files For Phase 114 Planning

| Artifact | Closest planning analog |
|---|---|
| `114-01-PLAN.md` | [113-01-PLAN.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-01-PLAN.md:1) |
| `114-02-PLAN.md` | [113-02-PLAN.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-02-PLAN.md:1) |
| `114-03-PLAN.md` | [113-03-PLAN.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-03-PLAN.md:1) |
| `114-VALIDATION.md` | [113-VALIDATION.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-VALIDATION.md:1) |
| `114-PLAN-CHECK.md` | [112-PLAN-CHECK.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-PLAN-CHECK.md:1) |
| `114-0x-SUMMARY.md` | [113-0x-SUMMARY.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-01-SUMMARY.md:1) |
| `114-VERIFICATION.md` | [112-VERIFICATION.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-VERIFICATION.md:1) |
| `114-REVIEW.md` | [113-REVIEW.md](/Users/jon/projects/accrue/.planning/phases/113-cancellation-semantics-closure/113-REVIEW.md:1) |
