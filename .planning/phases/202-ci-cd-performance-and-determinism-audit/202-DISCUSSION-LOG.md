# Phase 202: ci-cd-performance-and-determinism-audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 202-ci-cd-performance-and-determinism-audit
**Areas discussed:** Measurement boundary, Recommendation stance, Provider and determinism truth, Phase 204 handoff shape

---

## Measurement Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Static-only + metrics-needed plan | Fully matches audit-only scope and keeps repo evidence primary, but gives Phase 204 weaker prioritization evidence. | |
| Opportunistic read-only GitHub run-history snapshot | Adds real run/job evidence without changing CI; must be labeled with date/run count and kept partial if data is incomplete. | yes |
| Require baseline metrics before finalizing | Strongest evidence, but turns the audit into a measurement milestone and conflicts with CI-05 allowing missing metrics to be recorded. | |

**User's choice:** User asked to consider all areas, use subagent research, and make one coherent recommendation set without requiring manual tradeoff review.
**Notes:** Selected static-first audit with opportunistic read-only GitHub Actions run-history snapshot when available. Missing metrics do not block Phase 202; they remain `Baseline Metrics Needed`.

---

## Recommendation Stance

| Option | Description | Selected |
|--------|-------------|----------|
| Soft keep-everything audit | Preserves all current confidence but hides duplicated work and weakens Phase 204 input. | |
| Blunt measure-first split | Calls out duplicated/low-signal gates directly while requiring metrics before demotion or deletion. | yes |
| Aggressive fast-path demotion | Maximizes likely PR-runtime savings, but risks lowering release confidence before evidence supports it. | |
| Finalizer/check consolidation first | Improves required-check UX but does not reduce runner work by itself and can obscure failures. | |

**User's choice:** User asked for the expert recommendation.
**Notes:** Selected blunt but not deletion-first. Target recommendations preserve high-value gates while classifying duplicated release-gate work, browser setup repetition, Docker smoke long-tail risk, annotation sweep critical-path cost, and release recovery order dependence as follow-up hardening candidates.

---

## Provider And Determinism Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Audit-only truthful classification | Fits Phase 202 scope and separates static evidence from run-history truth, but does not fix misleading green scheduled runs by itself. | yes |
| Mandatory live-provider canary | Makes green mean Stripe test-mode parity was actually proved, but requires maintained secrets/fixtures and can false-red on provider/account drift. | |
| Advisory skip-capable provider canary | Honest when credentials cannot be guaranteed, but weaker as a drift detector. | |
| Proved matrix fidelity contract | Makes optional matrix cells meaningful, but requires future negative proof or dependency-state assertions. | yes |

**User's choice:** User asked for binary, coherent recommendations across all lenses.
**Notes:** Selected binary proved/skipped/advisory language. Fake-backed deterministic tests remain the default contributor loop. `live-stripe` should either fail early when mandatory credentials are absent or be renamed advisory. Matrix cells must materially prove distinct dependency/compile/test behavior.

---

## Phase 204 Handoff Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Readable human audit only | Best for maintainer scanning, but Phase 204 must re-extract ranking fields. | |
| Phase-204 ranking matrix only | Directly sortable, but too dry and prone to false precision before cross-audit ranking. | |
| Readable audit + structured Phase 204 handoff table | Keeps reasoning readable and gives Phase 204 sortable fields without creating implementation commitments. | yes |
| Issue-ready implementation backlog | Most actionable later, but over-prescribes before Phase 204 ranks CI against other hardening needs. | |

**User's choice:** User asked for a perfect recommendation set that is coherent with project goals and Phase 204.
**Notes:** Selected hybrid artifact: readable audit plus final `Phase 204 Handoff` table with evidence, risk, impact, tradeoff, implementation approach, verification, rollback, metric-needed status, and slice fit.

---

## Claude's Discretion

- Use subagent-backed research and parent synthesis rather than more interactive question rounds.
- Treat user instruction as approval to discuss all gray areas and proceed to context capture.
- Apply UI/UX principles as developer-experience principles because Phase 202 is CI/CD audit work, not a UI phase.

## Deferred Ideas

- Actual CI topology or branch-protection changes.
- Live-Stripe behavior changes.
- Optional matrix redesign.
- Release recovery preflight implementation.
- Playwright/Docker/cache setup changes.
- UI/admin/portal design-system todos matched by the todo scanner.
