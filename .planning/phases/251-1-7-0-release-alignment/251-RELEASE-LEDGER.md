# Phase 251 Release Ledger

This ledger is transcribed from `.planning/251-remote-writes.local`, which is git-ignored and was written at the moment of each write. It is excluded from `covered_files` because it records SHAs of commits it cannot be part of.

## Remote writes (CONTEXT A6)

| UTC timestamp | Action | Target | Result |
|---------------|--------|--------|--------|
| 2026-10-26T14:31:41Z | push | `refs/heads/ci/release-please-repair` (normal push, no force) | ok, head `8a9c1c99337b1b87dda6b02fc9f62d0803d5c744` |
| 2026-10-26T14:32:08Z | pr-create | szTheory/accrue#54 (base main) | ok |
| 2026-10-26T14:59:31Z | pr-merge | szTheory/accrue#54, `--squash --match-head-commit 8a9c1c99...` | rc 0, squash `6e285bff6a6c10a1f79b19008cd679b16e4d8be6` |
| 2026-10-26T15:21:34Z | remove-label | szTheory/accrue#50, `autorelease: pending` | rc 0 (main freeze starts) |
| 2026-10-26T15:22:24Z | workflow-dispatch | `release-please.yml` on main | rc 0, run 40348672308 |
| 2026-10-26T15:53:00Z | push | `refs/heads/release-please--branches--main` (plain fast-forward from RAW, no force) | ok, `24f8a342..2d3a4c62`, A = `2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2` |

## Identifiers

| Key | Value |
|-----|-------|
| N (fix PR) | 54 |
| F (fix PR exact head) | `8a9c1c99337b1b87dda6b02fc9f62d0803d5c744` |
| S (squash commit on main) | `6e285bff6a6c10a1f79b19008cd679b16e4d8be6` (tree equal to F's tree; base was `db1b6d85`) |
| FREEZE_SHA | `6e285bff6a6c10a1f79b19008cd679b16e4d8be6` (= S) |
| R (fresh release PR) | 55, `chore: release main`, head branch `release-please--branches--main` |
| RAW (R's raw release-please head) | `24f8a34220070ee7148ecc1b9f37d922386bf3c9` (parent = FREEZE_SHA) |
| WT_T1 (core alignment commit) | `3eb2beac10ee995c4b61f13fb8f2e14b9736fc74` |
| A (aligned release PR head = WT_T2) | `2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2` (2 commits above RAW) |
| ci.yml pull_request run at A | 40353699704 (GREEN by `250-ci-head-status --pr-base origin/main`, 20 success jobs with browser UAT; parked ratchet lane failure allowed, also red at F and S) |
| Browser UAT pull_request run at A | 40353699699 (success) |
| ci.yml pull_request run at F | 40340488190 (GREEN, 19 success jobs) |
| ci.yml push run at S | 40344886087 (GREEN vs baseline run 40281358498, 22 success jobs) |
| Release Please push run at S | 40344886221 (`failure`: Release Please=success, Release PR wedge check=failure) |
| Release Please dispatch run at FREEZE_SHA | 40348672308 (`success`: Release Please=success, Release PR wedge check=success) |
| GHREL_MARKER | `✔ Building strategies by path` |

## Detector live positive control (run 40344886221)

```
##[error]merged release PR(s) still labelled autorelease: pending (50); release-please will not open a new release PR until the label is removed
```

## Stale-label hazard: before and after (read-only `release-please@17.6.0 github-release --dry-run`)

- Before removal (rc 0): `✔ Would tag 3 releases:` for `accrue-v1.7.0`, `accrue_admin-v1.7.0` and `accrue_portal-v1.7.0`, at sha `b4310a3937c5449ae5557c565d6403511ae715ad`, `pullNumber: 50`.
- After removal (rc 0): `✔ Would tag 0 releases:`, with no `pullNumber` line.
- Merged-pending query: `[50]` before, `[]` after. The negative control (`autorelease: nonexistent-251`) returned `[]`.
