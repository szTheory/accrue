# GSD Repo Hygiene Prompt

Use this before starting a new milestone, before a release-prep pass, or any
time the repo feels operationally cluttered. The goal is to reach a clean local
checkout, clean GSD state, triaged GitHub inbox, green CI, and an explicit
release/no-release decision.

## Intent

Get the Accrue repository ready for the next focused work session:

- local `main` clean and synced with `origin/main`
- all registered git worktrees clean or intentionally removed
- no uncommitted tracked changes or unexpected untracked files
- `.planning/` health is green and points at either an active milestone or a
  deliberate "awaiting next milestone" state
- open GitHub issues and PRs triaged
- stale automation refs identified and pruned when safe
- main CI green
- Release Please/Hex publishing state understood, with no accidental package
  release unless explicitly requested

## Default Policy

Unless explicitly overridden:

- Do not publish to Hex.
- Do not merge a Release Please PR.
- Do not push all local tags.
- Keep local-only GSD milestone tags local.
- Push `main` directly only after local validation passes and `origin/main` has
  not advanced unexpectedly.
- Delete stale release-please remote branches only when they have no open PR.

## Checklist

1. Inspect local state.
   - `git status --short --branch`
   - `git rev-list --count origin/main..HEAD`
   - `git rev-list --count HEAD..origin/main`
   - `git worktree list --porcelain`
2. Inspect every registered worktree.
   - For each path from `git worktree list --porcelain`, run
     `git -C <path> status --short --branch`.
3. Run GSD health.
   - `gsd-tools query validate.health`
   - If the tool is not on `PATH`, use the project or agent-local
     `gsd-tools.cjs` shim.
4. Review GitHub inbox.
   - `gh pr list --state open --json number,title,headRefName,baseRefName,url`
   - `gh issue list --state open --json number,title,url`
   - Merge, close, label, or defer only with explicit rationale.
5. Review refs.
   - `git fetch --prune origin`
   - `git branch -vv`
   - `gh api repos/szTheory/accrue/branches --paginate`
   - Delete stale release-please branches only when there is no open PR.
6. Validate locally.
   - Run the narrow checks matching the changes.
   - For release-adjacent changes, include release manifest and release contract
     scripts.
   - For planning-only changes, include GSD health and roadmap/planning hygiene
     scripts.
7. Push and watch CI.
   - Push only after local checks pass.
   - Watch the push-triggered `CI` workflow on `main`.
   - If the periodic/manual CI lane is relevant, run `workflow_dispatch` and
     verify it separately.
8. Confirm final state.
   - `git status --short --branch` is clean and not ahead/behind.
   - GSD health is green.
   - open PR/issue lists are triaged or empty.
   - main CI is green.
   - Release Please did not create an unexpected publish path.

## Final Report

Report:

- local branch and worktree cleanliness
- pushed commit range
- GitHub PR/issue count
- CI run IDs and conclusions
- stale branches/tags pruned or intentionally left alone
- whether any release was prepared or published
