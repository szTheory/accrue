# Phase 231: Exact-SHA Release Gate Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-15
**Phase:** 231-exact-sha-release-gate-proof
**Areas discussed:** Candidate SHA identity, GATE-01 local gate scope, GATE-02 GitHub proof mechanism, GATE-03 ship-window resolution
**Mode:** advisor (calibration tier `minimal_decisive`; four `gsd-advisor-researcher` agents run in parallel, each grounded in live repository measurement)

---

## Candidate SHA Identity

Surfaced by live measurement during scouting, not anticipated from the roadmap: `integration/v1.62-candidate` (`bab50d92`) is **not** an ancestor of milestone HEAD (`030a3c6e`), diverging 27/37, with 61 non-planning files differing.

| Option | Description | Selected |
|--------|-------------|----------|
| Re-cut from milestone HEAD | Repoint the candidate ref to a fresh `--no-ff` merge of `origin/main` cut from `030a3c6e`, re-apply the toolchain pin and config.ex hazard test, recompute the hazard universe, re-mint the rollback point. Record the change in Phase 231's evidence. | ✓ |
| Re-cut as a Phase 230 addendum | Same mechanics, booked as an addendum amending closed Phase 230, keeping candidate provenance inside the phase owning INTG-01..03. | |
| Freeze `bab50d92` as-is | Gate the existing candidate unchanged; zero ref churn and the existing rollback point stays valid. | |

**User's choice:** Re-cut from milestone HEAD, recorded in Phase 231's own evidence.

**Notes:** Freezing was rejected because the candidate predates its own gating verifiers — WR-01 wired `verify_integration_disposition.mjs` and `verify_phase230_archive_invariants.mjs` into merge-blocking CI on the milestone branch only, and CR-01/CR-02 fixed real bugs in them. Advance-by-merging and merge-back-then-recut were structurally disqualified before reaching the user: both break Phase 230's locked `rev-list --count == 1` and `revert -m 1` exact-undo properties. `origin/main` has not moved (`d30fc25d`) and all ancestry invariants already hold on `030a3c6e`, making the re-cut mechanical repetition of a reviewed recipe rather than new design.

---

## GATE-01 — Local Gate Scope and Environment Purity

Not escalated to the user; research was decisive and the choice is within-scope clarification of what "complete local CI-equivalent gates" means.

| Option | Description | Selected |
|--------|-------------|----------|
| Full 13-lane literal set | Run every lane named in Phase 230's "Phase-231 lanes" table verbatim. | |
| Repo-declared merge-blocking cohort | Run the closed list enumerated in `ci.yml`'s own header comment, from a scratch clone, with explicit `skipped`/`non_run` rows for credential-gated and non-existent lanes. | ✓ |

**User's choice:** Not escalated — folded into the default package.

**Notes:** The 13-lane table was a *disposition record* under Phase 230's D-20 (what 230 declined to run because the result on `origin/main` alone would be identical), not a scope proposal. Three entries are not repository gates at all: `mix hex.publish --dry-run` and `gh workflow run ci.yml` exist as no CI job, and the latter is definitionally non-local. `live-stripe` is credential-gated and `ci.yml` states it never runs on pull requests. Running the full literal set would force either a fabricated credential or a false `proved`.

---

## GATE-02 — Exact-SHA GitHub Proof Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Push branch + `workflow_dispatch` | Push `integration/v1.62-candidate` to origin (one new remote ref), then `gh workflow run ci.yml --ref <branch>`. Full merge-blocking job set, no PR object, REL-04 left to Phase 232. | ✓ |
| Push + draft PR | Push, then open a draft PR to get `pull_request`-class checks, removing event-class ambiguity but encroaching on REL-04. | |
| Harness only, defer the run to 232 | Build and self-test the fail-closed checker but push nothing; the green-check proof happens in Phase 232. | |

**User's choice:** Push branch + `workflow_dispatch`.

**Notes:** Escalated because pushing publishes a SHA to a public repository — genuinely one-way, and the project's posture requires separate explicit authorization for remote mutation. Two mechanical findings shaped the options: `ci.yml`'s `push:` trigger is filtered to `branches: [main]`, so pushing the candidate branch fires zero checks and a dispatch is mandatory; and `branches/main/protection` returns 404 with `rulesets` empty, so GitHub declares no required checks at all — a checker enumerating requirements from branch protection would pass vacuously. Accepted tradeoff: the proof is `workflow_dispatch`-class, distinct from the `pull_request`-class run Phase 232's PR will produce for the same SHA, and the evidence must say so explicitly.

---

## GATE-03 — Ship-Window Resolution

Not escalated; the policy is a decision rule derived from data already in the ledger, and the recording mechanics were settled by Phase 230's D-28.

| Option | Description | Selected |
|--------|-------------|----------|
| Extend WINDOWS.md schema | Add owner/release-impact/evidence columns directly to the ledger. | |
| Terse ledger + sibling disposition artifact | Keep WINDOWS.md's schema, flip statuses via `gsd-tools windows waive/fixed`, put the rich fields in `231-WINDOW-DISPOSITIONS.{json,md}` joined 1:1 by row id. | ✓ |

**User's choice:** Not escalated — folded into the default package.

**Notes:** Extending the schema breaks `directShipWindows`'s hardcoded 10-column parse in `verify_repository_inventory.mjs` and cascades into Phase 229/230 fixture golden files, re-litigating a schema D-28 already settled. Disposition policy splits by `kind`: `unrun-verify` rows close on whether the gate now *executes* (GATE-01's run is that evidence), `deviation` rows are not defects and close by confirming the change is intact plus rationale. Two guardrails emerged from spot-checking: row 1's recorded blocker is already stale (`playwright.config.js` now has a `chromium-mobile` project), proving evidence must be re-derived at the candidate SHA rather than copied forward; and row 5 records a real failing test, not merely an unrun gate, so it is investigate-then-fix-or-block and never auto-waived. Status flips were confirmed safe in routine CI because `readShipWindows` recomputes fresh at collection time and CI runs only `--fixtures` — the narrow hazard is re-diffing a frozen published capsule, which the context forbids.

---

## Claude's Discretion

- Exact JSON schema field names, artifact filenames, script module decomposition, and renderer layout.
- Whether GATE-01/02/03 evidence is three artifacts or fewer.
- Task decomposition and ordering, subject to re-cut-first and capsule-last.
- Whether the required-job drift check extends an existing verifier or lives in the new checker.

## Deferred Ideas

None raised during this discussion beyond the Phase-232 handoffs already recorded by Phase 230 (PR opening, hygiene classification, `commit-search-depth` pinning, CHANGELOG editorial polish, the double-prefixed audit file, adopter-named ref renaming). All are preserved in CONTEXT.md's `<deferred>` section.
