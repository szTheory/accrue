# Phase 208: prove-convergence-on-the-representative-slice-wire-ci-accept - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 208-prove-convergence-on-the-representative-slice-wire-ci-accept
**Areas discussed:** Evidence depth and freeze bar, Deterministic CI proof style, Sign-off artifact and follow-on runbook

---

## Evidence Depth And Freeze Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Reducer-only freeze after `CONVERGED` | Smallest change, but too shallow for maintainer ACCEPT and can bless placeholder/all-zero states. | |
| Phase-200-style evidence bundle + explicit reducer `--freeze` | Structured evidence bundle, strict freeze preflight, explicit local freeze command, verifier-backed sign-off. | yes |
| Visual-baseline service or pixel snapshot acceptance | Mature visual-review idiom, but out of scope and adds service/flake/cost risk. | |
| Full-surface freeze before milestone ACCEPT | Stronger broad confidence, but violates Phase 209 scope gate and expands Phase 208. | |

**User's choice:** Discuss/consider all areas and produce one coherent recommendation set.
**Notes:** Parallel advisor research recommended the Phase-200-style evidence bundle.
Key rationale: Phase 208 needs a maintainer-accepted proof package, not just reducer
mechanics. Freeze must be explicit, local, non-hidden, non-placeholder, and guarded
by a score/coverage/regression/sign-off preflight.

---

## Deterministic CI Proof Style

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated Node-only frozen-verify job | Fast deterministic job, no BEAM/Postgres/browser cost, no LLM key, sharp ratchet failure signal. | yes |
| Dedicated job with `needs` on existing UI gates | Single combined status, but blurs failure ownership and can produce skipped/unclear checks. | |
| Fold ratchet proof into `admin-phase200-guardrails` | Less workflow surface, but violates requested new job and hides ratchet regressions in Phase 200. | |
| Full browser/Mix ratchet CI run | Exercises more pipeline, but risks flake, credentials, and LLM/browser creep. | |

**User's choice:** Discuss/consider all areas and produce one coherent recommendation set.
**Notes:** Parallel advisor research recommended a dedicated Node-only job. Key
rationale: Phase 208 CI is a baseline gate, not a live evaluator gate. It should
run self-tests, non-mutating frozen verification, and scratch-fixture red-path
proofs. Freeze stays local and explicit; existing UI gates stay separate.

---

## Sign-Off Artifact And Follow-On Runbook

| Option | Description | Selected |
|--------|-------------|----------|
| Single `UI-RATCHET-SIGN-OFF.md` with embedded runbook and strict verifier | Matches UI-SPEC and Phase 200 precedent, but needs verifier discipline. | |
| Structured evidence manifest + generated sign-off/runbook Markdown | Best defense against stale PASS claims; structured evidence feeds the Markdown. | yes |
| Separate sign-off plus linked runbook | Cleaner reading modes, but risks decision-surface ambiguity and file drift. | |
| CI job-summary-first package with artifact uploads | Good PR UX, but ephemeral and not durable enough as canonical evidence. | |

**User's choice:** Discuss/consider all areas and produce one coherent recommendation set.
**Notes:** Parallel advisor research recommended structured evidence as the
implementation backbone, packaged as one committed `UI-RATCHET-SIGN-OFF.md` with
an embedded `## Follow-On Runbook`. CI summaries may mirror results but do not
replace committed evidence and verifier output.

---

## Claude's Discretion

- Exact structured evidence filename/schema.
- Exact non-mutating CI verification surface (`--check-frozen`, wrapper script, or exported function).
- Exact GitHub artifact names and step-summary layout.
- Exact example surface in the follow-on runbook.

## Deferred Ideas

- Full-surface sweep remains Phase 209 / SWEEP-01.
- Pixel-diff visual-regression service remains future TOOL-02-style work.
- Advisory LLM in CI remains deferred.
