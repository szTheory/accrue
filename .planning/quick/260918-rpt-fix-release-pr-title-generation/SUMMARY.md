---
type: quick
slug: rpt-fix-release-pr-title-generation
status: complete
human_judgment: false
completed: 2026-09-18
pr: 48
---

# Summary

Fixed the release-PR title generation defect that made release `1.6.0` tag
nothing while reporting success, and guarded it.

## Root cause

`a7d3c39b` (phase 232, D-43) added
`"group-pull-request-title-pattern": "chore: release accrue-monorepo ${version}"`.
release-please 17.6.0's `plugins/merge.js` sources that `${version}` from the
release candidate whose path is exactly `.`. This repo has no package at `.`,
so the version is `undefined`, `${version}` renders empty, and the generated
title fails `PullRequestTitle.parse` at release time — producing
`Bad pull request title`, zero tags, zero releases, and a pipeline that would
refuse every later release PR.

D-43 was added to prevent a "silent skip of GitHub Release and tag creation".
It caused one.

## Changes

- `release-please-config.json`: removed the one key. Nothing else touched.
- `scripts/ci/verify_release_pr_title_roundtrip.sh`: new merge-blocking guard in
  `release-manifest-ssot`. Fails when a grouped pattern is set with no root
  package to supply the version, and when a grouped pattern omits `${version}`.
  `shellcheck` clean; capture-then-filter, not `| grep -q`.
- `RELEASING.md`: documented the removed key as current truth; corrected.
- `232-CONTEXT.md`: D-43 annotated as superseded, with the mechanism.
- `232-VERIFICATION.md`: `covered_digest` restamped via the repo's exported
  `computeDigest` (the ci.yml edit is inside its covered set).

## Verification

Generation→parse round-trip against release-please@17.6.0's own modules:

| config | generated | parses |
|---|---|---|
| pattern with `${version}` | `chore: release accrue-monorepo` | NULL |
| no group pattern (shipped) | `chore: release main` | OK |
| pattern without `${version}` | `chore: release accrue-monorepo` | NULL |

Guard controls, against the committed script: exact `a7d3c39b` config → rc=1;
pattern without `${version}` (no root pkg) → rc=1; root pkg + no `${version}`
→ rc=1; root pkg + `${version}` → rc=0; shipped config → rc=0.

## Note for the next reader

The one-time unwedge of 1.6.0 was a manual retitle of merged PR #46; that is
not part of this fix and is not repeatable. Also note `main` has no branch
protection, so none of these guards actually block a merge — they are
convention.
