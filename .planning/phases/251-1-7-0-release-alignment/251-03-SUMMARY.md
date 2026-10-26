---
phase: 251-1-7-0-release-alignment
plan: "03"
subsystem: release-automation
status: complete
completed: 2026-10-26
requirements-completed: []
tags: [changelog, release-please, sc1, positive-control, ci, rls-01]
requires: [251-02]
provides:
  - scripts/ci/verify_release_changelog_curated.sh (section-scoped SC1 gate + self-test), merge-blocking in docs-contracts-shift-left
  - a fix-PR head (ci/release-please-repair) that passes the full locally runnable fix-PR gate set
affects: [251-04, 251-05]
key-files:
  created:
    - scripts/ci/verify_release_changelog_curated.sh
    - .planning/phases/251-1-7-0-release-alignment/251-03-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/README.md
    - scripts/ci/verify_release_branch_repair_safety.sh
    - .planning/phases/251-1-7-0-release-alignment/251-VERIFICATION.md
    - .planning/phases/251-1-7-0-release-alignment/251-UAT.md
decisions:
  - "SC1 is decided by a committed gate that reads only the ## [manifest version] section of each package CHANGELOG; versions below CURATED_FROM=1.7.0 are grandfathered released history."
  - "The phase-scoped bullet pattern is widened to hyphen-suffixed scopes (quick-261008-lbv, 247-post-review, 241-ui), which the plan's pattern missed on the real 963ad2cd candidate; an empty release section also fails."
  - "The repair-safety fixture identity moved to fixture@example.test (an allowlisted reserved domain) rather than widening the 250 pre-push e-mail allowlist."
actuals:
  tokens: 9500
  tasks: 2
  commits: 3
plan_head_before: bd669b949c19f8f3a51cb50350e97789d407ee93
plan_head_after: c7320139
coverage:
  - id: G1
    description: the SC1 curated-CHANGELOG gate exists, is merge-blocking, passes its self-test controls, is grandfathered-green on the 1.6.0 tree, and fails the real uncurated 963ad2cd release-please candidate for all three packages
    requirement: RLS-01
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_changelog_curated.sh --self-test"
        status: pass
      - kind: command
        ref: "bash scripts/ci/verify_release_changelog_curated.sh"
        status: pass
      - kind: command
        ref: "R=$(mktemp -d) && for p in accrue accrue_admin accrue_portal; do mkdir -p $R/$p && git show 963ad2cd:$p/CHANGELOG.md > $R/$p/CHANGELOG.md; done && ! bash scripts/ci/verify_release_changelog_curated.sh --root $R --version 1.7.0"
        status: pass
    human_judgment: false
---

# Phase 251 Plan 03: Curated Release CHANGELOG Gate Summary

SC1 ("no raw phase-scoped lines in the release CHANGELOGs") is now `scripts/ci/verify_release_changelog_curated.sh`, a merge-blocking check that reads only each package's `## [<manifest version>]` section. It catches release-please's real `* **233-05:**` / hash-link rendering, and it fails the real uncurated candidate `963ad2cd` for all three packages (18, 168 and 41 raw lines). On today's 1.6.0 tree it prints `grandfathered` and exits 0.

## What was built

- `scripts/ci/verify_release_changelog_curated.sh` (`set -euo pipefail`, prefixed `fail`, here-string matching, no `producer | grep -q`). Options: `--root <dir>` (default repo root), `--version <x.y.z>` (default `jq -r .accrue` of the root manifest), `--self-test`. `CURATED_FROM=1.7.0`, compared with `sort -V`. The section is extracted with the same awk idiom as `verify_release_notes_contract.sh` (exact heading prefix `## [<V>]` to the next `## [`). Any line matching one of three patterns is counted, and the script prints `<pkg>: <n> raw line(s)` per package:
  - phase-scoped bullet: `^\* \*\*([0-9]{3}(-[0-9a-z]+)*|phase-[0-9]+(-[0-9a-z]+)*|quick-[0-9a-z]+(-[0-9a-z]+)*):\*\*`;
  - conventional-commit subject: `(feat|fix)\([0-9]{3}`;
  - raw commit link: `\(\[[0-9a-f]{7}\]\(https://github\.com/<owner>/<repo>/commit/[0-9a-f]{40}\)\)`.
  The script fails on any non-zero count, on a missing section, or on an empty section. Grep exit 2 fails closed.
- `ci.yml` `docs-contracts-shift-left`: the step `Release CHANGELOG sections are curated (Phase 251 SC1)` (`--self-test && live run`) sits directly after `Release notes freshness contract`.
- `scripts/ci/README.md`: a `Triage: verify_release_changelog_curated.sh` section covering the patterns, the grandfather floor, the release-branch remedy, the controls and the wiring.

No CHANGELOG and no file under `accrue/`, `accrue_admin/` or `accrue_portal/` changed. `verify_release_notes_contract.sh` is untouched.

## Control evidence

Raw outputs are in `.planning/251-evidence.local/` (git-ignored, persistent): `251-03-selftest.out`, `251-03-live.out`, `251-03-raw-positive.out`, `251-03-drafts-negative.out`, `251-03-replay-pre.out`, `251-03-replay.out`, `251-03-prepush-pre.out` and `251-03-prepush.out`.

### Self-test (rc 0)

```
self-test raw **233-05:** bullet: FAIL as required (accrue_portal: 1 raw line(s))
self-test suffixed **quick-261008-lbv:** / **247-post-review:** / **phase-12-gap:** bullets: FAIL as required (accrue_portal: 3 raw line(s))
self-test feat(233-05) line: FAIL as required (accrue_portal: 1 raw line(s))
self-test hash-link-only bullet: FAIL as required (accrue_portal: 1 raw line(s))
self-test missing ## [1.7.0] section: FAIL as required (accrue_portal/CHANGELOG.md has no ## [1.7.0] section)
self-test empty ## [1.7.0] section: FAIL as required (accrue_portal/CHANGELOG.md ## [1.7.0] section is empty)
self-test curated section: PASS as required (OK (1.7.0): curated release sections)
self-test manifest 1.7.0 is enforced, not grandfathered: FAIL as required (accrue_portal: 1 raw line(s))
self-test curated 1.7.0 above raw 1.6.0 (section scoping): PASS as required (OK (1.7.0): curated release sections)
self-test raw 1.6.0 under version 1.6.0: PASS as required (grandfathered (released before the curated-notes rule)
self-test PASS (raw bullet, suffixed scopes, conventional line, hash link, missing section, empty section, curated, inclusive floor, section scoping, grandfathered)
```

Each failing fixture isolates one pattern. The hash-link fixture has no phase scope, and the conventional fixture has neither a scope nor a link. Each fixture also asserts the expected output line, not only the exit code. The curated fixture includes a `* **Portal:**` bold label, which shows that non-phase bold labels pass. The self-test proved its worth on the first run: the plan-literal link pattern `\([0-9a-f]{7}\]` (missing the `\[`) could not find the hash-link positive, and the self-test failed with `expected FAIL, got rc 0`. That was fixed before the commit.

### Live tree (manifest 1.6.0, rc 0)

`[verify_release_changelog_curated] 1.6.0: grandfathered (released before the curated-notes rule, which applies from 1.7.0)`

### Real-data positive control: 963ad2cd (resolvable, `git cat-file -t` = commit; rc 1, as required)

```
accrue: 18 raw line(s)
accrue_admin: 168 raw line(s)
accrue_portal: 41 raw line(s)
[verify_release_changelog_curated] FAIL: 227 raw release-please line(s) in the ## [1.7.0] sections; curate them into adopter-readable notes
```

The research measured 17/155/41 with a bullet-only pattern. The per-pattern breakdown on the candidate:

| Package | Phase bullets | Commit links | Non-blank section lines | Counted |
|---------|---------------|--------------|-------------------------|---------|
| accrue | 17 | 18 | 20 | 18 |
| accrue_admin | 150 | 168 | 170 | 168 |
| accrue_portal | 36 | 41 | 43 | 41 |

Every raw bullet in the candidate carries a hash link, so the counted total is the bullet count. The candidate's manifest reads 1.7.0, and the default (no `--version`) run also fails, with the same counts.

### Negative control on the planned curated text

The three `## [1.7.0]` drafts in `251-CHANGELOG-DRAFTS.md`, each placed under `# Changelog / ## Unreleased` in a temp root, give `accrue: 0`, `accrue_admin: 0`, `accrue_portal: 0` and `OK (1.7.0): curated release sections` (rc 0).

## Fix-PR gate replay (local, committed head c7320139)

All rc 0. Last output line of each:

| Gate | Result |
|------|--------|
| SL-G fixed point | `artifact fixed point: PASS (... phase 251, artifacts: 2, edges: 21, ...)` |
| SL-E completion evidence | `completion evidence: PASS (... 12 parsed, 10 complete, 10 evidenced, 0 skipped as future)` |
| exec-UAT `--self-test` | `executable UAT contract self-test: PASS` |
| exec-UAT `--all-opted-in` | `PASS (5 opted-in phases, 3 complete, 28 summaries, 103 automated UAT tests)` |
| exec-UAT `--all-since 229` | `PASS (23 phases since 229, 163 summaries, 443 automated UAT tests)` |
| exec-UAT `--phase 251` | `PASS (phase 251, 2 summaries, 4 automated UAT tests)` before this SUMMARY |
| pipefail idiom ban | `PASS (verified: require-idiom-ban; 60 files, 27 pipelines, 0 offenders)` |
| no home paths `--self-test` / `--repo` | `SELF-TEST OK` / `OK (mode repo)` |
| sensitive-token census (TAP, fixtures, repo, as ci.yml) | `PASS (fixtures ... 15 scenarios)` / `PASS (... 1 entries, 5462 tracked files scanned ...)` |
| CI efficiency contract | `PASS (... 18 jobs ...; 23 third-party uses pinned across 9 workflow files)` |
| CI script contract (as ci.yml `--repo .`) | `PASS (verified: require-cohort-floor, require-guard-coverage, require-non-vacuity)` |
| release contract | `verify_release_contract: v1.59 OK` |
| manifest alignment | `OK: release manifest and mix.exs @version aligned at 1.6.0 ...` |
| PR title round-trip | `OK: no group-pull-request-title-pattern; ...` |
| release notes freshness | `verify_release_notes_contract: OK (1.6.0)` |
| repair-safety `--self-test` / `--repo .` | `self-test PASS (...)` / `OK: ... wedge detector in job 'release-pr-wedge-check'; scope canary present` |
| curated-changelog `--self-test` / live | `self-test PASS (...)` / `1.6.0: grandfathered ...` |
| actionlint ci.yml + release-please.yml | clean |
| 250 pre-push `--hygiene-only` over `db1b6d85..HEAD` | `guard: all checks passed` (8 PASS, including its own positive controls) |

The final post-SUMMARY replay is recorded in `251-03-replay.out`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The plan-literal commit-link pattern could not match a link**
- **Found during:** Task 1 (first self-test run)
- **Issue:** `([0-9a-f]{7}](...))` as written omits the `[` that release-please puts after `(`, so the hash-link-only fixture passed.
- **Fix:** `\(\[[0-9a-f]{7}\]\(https://github\.com/<owner>/<repo>/commit/[0-9a-f]{40}\)\)`. The fixture now fails as required.
- **Commit:** 03aeac54

**2. [Rule 2 - Strengthening] The phase-scoped bullet pattern missed hyphen-suffixed scopes**
- **Found during:** Task 1 real-data control
- **Issue:** The plan's pattern does not match `* **quick-261008-lbv:**` (5 portal lines), `* **241-ui:**`, `* **246-identity:**` or `* **247-post-review:**` on 963ad2cd. On the candidate these lines were caught only through their hash links, so a curated draft that dropped the links but kept the scopes would have passed.
- **Fix:** the pattern now allows `(-[0-9a-z]+)*` suffixes. This is a strict superset of the plan's pattern. A dedicated self-test fixture covers it.
- **Commit:** 03aeac54

**3. [Rule 2 - Strengthening] An empty release section fails**
- An empty `## [1.7.0]` heading would vacuously have zero raw lines. It now fails, and a fixture covers that case.
- **Commit:** 03aeac54

**4. [Rule 1 - Bug, gate replay] The 250 pre-push hygiene scan was red on the fix-PR range**
- **Found during:** Task 2 replay
- **Issue:** `FAIL: no secret/e-mail/username in added lines`, which flagged `scripts/ci/verify_release_branch_repair_safety.sh:297` and `:327` (the 251-02 fixture identity `fixture@example.invalid`). The guard's e-mail allowlist covers example.com/org/test/net, not `.invalid`. Plan 04 would have hit this before its push.
- **Fix:** at source, `fixture@example.test`. The guard is unchanged. Both repair-safety modes still PASS. The pre-fix guard run (`251-03-prepush-pre.out`, rc 1) is the positive control showing that the scan finds such lines.
- **Commit:** c7320139

## Notes for 251-04 / 251-05

- The fix-PR head is locally green on the full gate set above, so plan 04 can push it. The branch is `ci/release-please-repair`, and every commit sits above `db1b6d85`.
- Once 1.7.0 is in the manifest, the new step makes the release PR red until each package's `## [1.7.0]` section is curated. This is intended and adds to "release PRs open red by design". The remedy is the curated text on the release branch. The `251-CHANGELOG-DRAFTS.md` drafts already pass (0/0/0), but their claims still need code verification (RESEARCH A2).
- Release-please renders `**admin:**` / `**regression:**` scopes too. These are not phase-scoped, but they carry hash links, so the link pattern catches them. Curated text must not keep commit links.
- `963ad2cd` was resolvable on 2026-10-26, so the plan-05 fallback control is not needed. Plan 05 may still re-run the check against the live raw release commit as extra evidence.
- The pre-push guard requires `GSD_SCRATCH` exported (it fails closed otherwise).

## Self-Check: PASSED

- FOUND: scripts/ci/verify_release_changelog_curated.sh
- FOUND: 03aeac54, da52c6ab, c7320139 (ancestors of HEAD)
