# Phase 229: Repository Truth & Recovery Safety - Context

**Gathered:** 2026-09-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish a reproducible, privacy-safe inventory of repository and CI state; preserve every pre-existing local ref and user-owned artifact before synchronization; and provide one exact-SHA CI observation path. This phase may inspect remotes and refresh local knowledge after recovery points exist. It does not integrate histories, resolve ship windows, delete refs or files, dispatch workflows, push commits, open PRs, merge, or publish.

</domain>

<decisions>
## Implementation Decisions

### Inventory Authority
- **D-01:** Use a sanitized machine-readable record as the evidence source and render a concise Markdown maintainer view deterministically from it. Reuse v1.61's source-plus-rendered-evidence pattern rather than creating a hand-maintained status narrative.
- **D-02:** Bind every remote claim to repository identity, observation time, exact object IDs, and the command that produced it. A symbolic branch name or green label without its SHA is not sufficient evidence.
- **D-03:** Record the discrepancy between live GitHub `main`, stale local `origin/main`, divergent local `main`, the current milestone branch, and the immutable v1.61 tag explicitly; do not collapse them into one assumed history.

### Recovery Safety
- **D-04:** Before any ref refresh or branch manipulation, create named local preservation refs plus an integrity-checked git bundle outside the repository, and record how each can be restored. — **Reversibility:** costly — synchronization without a proven recovery point could strand local-only history or make later provenance ambiguous.
- **D-05:** Inventory and hash user-owned untracked artifacts before any cleanup classification. Phase 229 does not delete, move, rewrite, or adopt them.
- **D-06:** Do not rely on reflog alone as the recovery mechanism; it is local, expiring, and does not preserve untracked content.

### CI Observation
- **D-07:** Establish a repository-owned `scripts/ci_monitor.cjs`-style command surface for run listing, exact-SHA inspection, failure summaries, and bounded watch behavior. Keep `scripts/ci/watch_ci.sh` as a thin compatibility entry point or clearly documented legacy wrapper rather than maintaining two independent monitor implementations.
- **D-08:** Monitoring is read-only in this phase: no workflow dispatch, rerun, cancellation, branch write, issue mutation, or provider authorization. The monitor must pass `-R szTheory/accrue` or equivalent explicit repository identity and emit observable failure details.
- **D-09:** Existing provider-proof semantics remain binding. A successful Actions conclusion does not by itself prove the live provider lane.

### Phase Exit
- **D-10:** Phase 229 ends with facts and recovery mechanisms, not integration work. Branch reconciliation begins only in Phase 230 from the committed inventory and verified recovery point.

### the agent's Discretion
- Exact JSON versus NDJSON schema, artifact filenames, and renderer layout are flexible if output is deterministic, sanitized, and independently verifiable.
- The planner may choose the narrowest backup-ref naming and bundle location that stay outside tracked project artifacts and avoid exposing secrets or machine-specific paths.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Contract
- `.planning/PROJECT.md` — v1.62 goal, stable-core posture, immutable-history decisions, and scope guardrails.
- `.planning/REQUIREMENTS.md` — REPO-01 through REPO-03 and milestone-wide exclusions.
- `.planning/ROADMAP.md` — Phase 229 boundary, dependency order, and success criteria.
- `.planning/seeds/SEED-003-repo-hygiene-before-new-milestone.md` — selected repository-hygiene checklist and release boundary.

### Repository and Release Truth
- `RELEASING.md` — recurring Release Please and linked-package release contract; planning milestone labels are distinct from package SemVer.
- `.planning/WINDOWS.md` — cross-phase ship-window ledger whose entries must be inventoried now and resolved or waived in Phase 231.
- `.planning/MILESTONES.md` — immutable v1.61 closeout facts and archive pointers.

### CI Contract
- `.github/workflows/ci.yml` — required job identities, trigger model, dependency graph, and provider-proof semantics.
- `scripts/ci/README.md` — contributor-facing CI evidence map and exact local verification commands.
- `scripts/ci/watch_ci.sh` — existing minimal monitor entry point and compatibility surface.
- `.planning/milestones/v1.61-phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` — established repository-bound CI evidence conventions.
- `.planning/milestones/v1.61-phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md` — retained candidate authority, exact-SHA evidence, and no-rerun boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/watch_ci.sh`: authenticated branch-oriented watcher suitable as a compatibility wrapper, but it currently omits explicit repository identity and structured exact-SHA output.
- `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/render_ci_baseline.mjs`, and `scripts/ci/verify_ci_baseline.mjs`: existing collect/render/verify pattern for sanitized GitHub evidence.
- `scripts/ci/phase_evidence_path.mjs`: existing archive-aware phase evidence resolver.
- `gsd_run windows status --raw`: structured source for the ship-window portion of the inventory.

### Established Patterns
- CI evidence is source data plus deterministic rendered Markdown, with repository and SHA binding and fail-closed validation.
- Required job IDs and provider-state vocabulary are stable contracts; advisory, skipped, failed, non-run, and proved states remain distinct.
- Remote mutation and provider attempts require separate authority; read-only collection grants neither.

### Integration Points
- Git object/ref inspection and GitHub repository APIs supply branch, tag, PR, release-branch, and Actions facts.
- `.planning/WINDOWS.md`, GSD state queries, and filesystem/worktree inspection supply local planning and hygiene facts.
- `scripts/ci/watch_ci.sh` should route to the single monitor implementation after compatibility is proven.

</code_context>

<specifics>
## Specific Ideas

- Prefer a compact evidence artifact that reads like a release engineer's diagnostic: fact, state, owner, next command, and immutable evidence reference.
- Make the recovery procedure executable enough that another maintainer can restore the exact pre-synchronization refs without relying on session memory.
- Keep the phase useful even when GitHub is unavailable: local inventory and backup verification should still complete, with remote observations marked unavailable rather than guessed.

</specifics>

<deferred>
## Deferred Ideas

- History integration and conflict dispositions belong to Phase 230.
- CI execution and ship-window resolution belong to Phase 231.
- File/ref cleanup, stale-branch actions, PR creation, and release handoff belong to Phase 232.
- Package publication remains outside v1.62 until separately authorized.

</deferred>

---

*Phase: 229-repository-truth-recovery-safety*
*Context gathered: 2026-09-12*
