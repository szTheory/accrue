# Phase 229: Repository Truth & Recovery Safety - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-12
**Phase:** 229-repository-truth-recovery-safety
**Areas discussed:** Inventory authority, recovery safety, CI observation, remote-effect boundary

---

## Inventory Authority

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic source plus rendered view | Sanitized machine-readable evidence generates concise Markdown and is independently verified. | ✓ |
| Hand-maintained Markdown | Simple to author but can drift from observed refs and SHAs. | |
| Ephemeral command output | Avoids artifacts but is not reviewable or reproducible across sessions. | |

**User's choice:** Auto-selected the recommended deterministic source-plus-rendered-view pattern under the user's explicit authorization to follow recommendations.
**Notes:** The user emphasized elegant, self-documenting work without churn; v1.61 already established this evidence pattern.

---

## Recovery Safety

| Option | Description | Selected |
|--------|-------------|----------|
| Named preservation refs plus verified bundle | Preserves divergent tracked history independently before synchronization. | ✓ |
| Reflog only | Convenient but local, expiring, and incomplete for durable recovery. | |
| Copy the whole worktree | Preserves untracked bytes but obscures Git provenance and creates unnecessary bulk. | |

**User's choice:** Auto-selected the recommended preservation refs plus verified bundle.
**Notes:** Untracked artifacts are inventoried and hashed separately; none are deleted or adopted in Phase 229.

---

## CI Observation

| Option | Description | Selected |
|--------|-------------|----------|
| One repo-owned structured monitor | Exact-repository and exact-SHA run inspection with observable failure output; existing watcher becomes compatibility entry point. | ✓ |
| Depend on missing external helper | Preserves the skill's nominal path but leaves the repository unable to verify live CI. | |
| Keep the minimal watcher unchanged | Watches one run but cannot provide the required structured inventory and failure detail. | |

**User's choice:** Auto-selected the repo-owned structured monitor.
**Notes:** No workflow dispatch, rerun, cancel, or provider authorization is in scope.

---

## Remote-Effect Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Read-only remote inspection | Observe GitHub and refresh local knowledge only after recovery points exist. | ✓ |
| Push preservation branches | Adds remote state before the integration strategy is reviewed. | |
| Begin integration immediately | Mixes discovery with mutation and weakens rollback confidence. | |

**User's choice:** Auto-selected read-only remote inspection.
**Notes:** Phase 230 owns history integration; Phase 232 owns authorized cleanup and PR creation.

## the agent's Discretion

- Exact evidence filenames and JSON/NDJSON layout.
- Backup-ref naming and external bundle location, provided both are collision-safe and verified.
- Compatibility-wrapper mechanics for `scripts/ci/watch_ci.sh`.

## Deferred Ideas

- No new ideas were added. Later milestone phases retain integration, release proof, bounded cleanup, and handoff ownership.
