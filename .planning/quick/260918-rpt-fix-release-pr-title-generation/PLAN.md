---
type: quick
slug: rpt-fix-release-pr-title-generation
status: in-progress
---

# Fix release-PR title generation so the release pipeline stops wedging

## Problem

Release `1.6.0` (PR #46) merged, then tagged nothing while the Release Please
workflow reported `success`. Root cause, traced to commit `a7d3c39b` (phase
232-05), which added:

```json
"group-pull-request-title-pattern": "chore: release accrue-monorepo ${version}"
```

release-please 17.6.0 `plugins/merge.js` builds the grouped PR title from
`rootRelease?.pullRequest.title.version`, where `rootRelease` is the candidate
whose path is exactly `.`. This repo has no package at `.`, so the version is
`undefined` and `${version}` renders empty. `strategies/base.js` then fails to
parse the versionless title, logs `Bad pull request title`, tags nothing, and
aborts all future release PRs with `There are untagged, merged release PRs
outstanding`.

D-43 in `232-CONTEXT.md` added this key specifically to prevent a "silent skip
of GitHub Release and tag creation". It caused that exact failure instead.

## Evidence

Round-trip run against release-please@17.6.0's own modules with `rootRelease=null`:

| config | generated title | parses at release time |
|---|---|---|
| pattern with `${version}` (current) | `chore: release accrue-monorepo` | NULL — Bad pull request title |
| no group pattern (the fix) | `chore: release main` | OK |
| pattern without `${version}` | `chore: release accrue-monorepo` | NULL |

Only the fix round-trips, and it reproduces `chore: release main` — the title used
by every successful release before this one (#28/#29/#30/#33/#39/#42).

## Tasks

1. Remove `group-pull-request-title-pattern` from `release-please-config.json`;
   change nothing else in that file.
2. Add `scripts/ci/verify_release_pr_title_roundtrip.sh` — fails when the key is
   set without a root package at `.`, or when a grouped pattern omits `${version}`.
   Comment must carry the mechanism, not just the ban.
3. Wire it into the existing `release-manifest-ssot` CI job.
4. Correct `RELEASING.md`, which documented the removed key as current truth.

## Acceptance

- Guard passes on the fixed config and fails on the exact `a7d3c39b` config.
- No other release-please behavior changes.
