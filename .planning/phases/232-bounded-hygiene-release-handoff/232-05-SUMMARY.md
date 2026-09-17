---
phase: 232-bounded-hygiene-release-handoff
plan: 05
subsystem: infra
tags: [release-please, ci, release-readiness, rel-05, shell]

requires:
  - phase: 232-03
    provides: "docs-contracts-shift-left CI job structure this plan's readiness step sits adjacent to (release-manifest-ssot job, a sibling merge-blocking job)"
provides:
  - "scripts/ci/verify_release_pr_readiness.sh -- a side-effect-free, committed, re-runnable REL-05 proof that release-please is ready to produce a version-and-changelog-consistent release PR"
  - "release-please-config.json commit-search-depth (2000) and group-pull-request-title-pattern (version-bearing) safety keys"
  - "RELEASING.md refreshed last-verified line and a documented REL-05 subsection"
  - "a token-gated, non-continue-on-error CI step in release-manifest-ssot running the readiness proof"
affects: [232-06, 232-07, 232-08, 232-09, 232-10, 232-11]

actuals:
  tokens: 3506
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "release-please release-pr --dry-run against the actual unreleased-commit-bearing branch (not the repo's current default branch, which may be fully released with zero pending commits) -- reading config/commits from GitHub by branch name, never the local working tree"
    - "fail() + ROOT_DIR shell verifier shape (verify_release_manifest_alignment.sh) reused for a script that wraps and asserts an external CLI's dry-run output"
    - "named, live-re-derived expected-count constants with an inline comment stating what they count, rather than a transcribed number"

key-files:
  created:
    - scripts/ci/verify_release_pr_readiness.sh
  modified:
    - release-please-config.json
    - RELEASING.md
    - .github/workflows/ci.yml
    - .planning/phases/232-bounded-hygiene-release-handoff/232-RELEASE-PR-DRYRUN.log

key-decisions:
  - "The readiness script's dry-run target is integration/v1.62-candidate, not main. Measured live: origin/main is already fully released at 1.5.1 with zero pending commits (D-01/D-02: main was re-released directly, independent of the candidate), so a dry run against main produces an empty plan (\"Would open 0 pull requests\") and every count-based assertion (updates: 7, exactly 3 module-attribute lines, same-version-across-packages, version > current) would be vacuously unsatisfiable. The candidate branch carries the real, unreleased commits this milestone's REL-04 integration PR will eventually merge to main, and a live dry run against it reproduces 232-CONTEXT.md's D-35/D-36 measurements exactly (14 changelog bullets, 1.6.0 lockstep, updates: 7, commit-search-depth walk well under the ceiling). Overridable via RELEASE_PR_READINESS_TARGET_BRANCH once the candidate has merged and a later branch needs the same proof."
  - "Token handling: accept GH_TOKEN or GITHUB_TOKEN, fail closed with a distinctly-named error when both are absent (verified via a negative control with both unset). In CI, the step uses the automatic secrets.GITHUB_TOKEN (read-only, always available including to same-repo runs) rather than the release-please.yml workflow's write-scoped RELEASE_PLEASE_TOKEN PAT -- the dry run only reads."
  - "The current manifest version compared against the planned version is fetched LIVE from the target branch via the GitHub Contents API (gh api repos/.../contents/.release-please-manifest.json?ref=<branch>), not read from the local working tree's .release-please-manifest.json -- this branch's own local manifest reads 1.4.0 (a different, stale line per D-02), which would make the greater-than comparison meaningless if used."
  - "gh api's -f ref=<value> flag silently 404s on a GET request for the contents endpoint in this environment; appending ?ref=<value> directly to the URL path works. Fixed during Task 2's own verification before committing."
  - "CI gating is a bash-level conditional inside the step's run: block (not a GitHub Actions step-level if:), so the skip path is VISIBLE as literal step output (\"...SKIPPED -- no GH_TOKEN available...\") rather than an opaque grey \"skipped\" step with no explanatory text, per the task's explicit requirement."

patterns-established:
  - "Live-fetch-from-target-branch, never-trust-local-working-tree for any check whose subject is 'is branch X ready', when the working tree may be on a different, stale line of history than X."

requirements-completed: [REL-05, HYG-02]

coverage:
  - id: D1
    description: "release-please-config.json gains commit-search-depth (2000) and a version-bearing group-pull-request-title-pattern; no last-release-sha/bootstrap-sha added, changelog-type and include-component-in-tag unchanged; the sibling dependency-operator contract is re-verified (not re-argued) and both accrue_admin/accrue_portal measured live to declare {:accrue, \"~> #{@version}\"}"
    requirement: REL-05
    verification:
      - kind: other
        ref: "python3 config-assertion script -> 'config ok'"
        status: pass
      - kind: integration
        ref: "bash scripts/ci/verify_release_manifest_alignment.sh -> exit 0, 'OK: release manifest and mix.exs @version aligned at 1.4.0 ...'"
        status: pass
      - kind: other
        ref: "git diff --name-only for the task's own commit lists no mix.exs and no CLAUDE.md (forbidden_edits=0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "scripts/ci/verify_release_pr_readiness.sh proves REL-05 by a single side-effect-free release-please release-pr --dry-run, asserting CLI exit 0, no truncation warning, live-re-derived planned update count (7), exactly 3 module-attribute version lines, all three packages on the same target version, and that version stable-semver-greater-than the target branch's live current manifest version"
    requirement: REL-05
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_release_pr_readiness.sh -> exit 0, PASS line naming target=integration/v1.62-candidate, plan=1.5.1->1.6.0, updates=7, all 6 assertions logged in order"
        status: pass
      - kind: other
        ref: "open PR count (gh pr list --state open --search 'chore: release') identical before (0) and after (0) the run"
        status: pass
      - kind: other
        ref: "tag count (git ls-remote --tags origin | wc -l) identical before (66) and after (66) the run"
        status: pass
      - kind: other
        ref: "env -u GH_TOKEN -u GITHUB_TOKEN bash scripts/ci/verify_release_pr_readiness.sh -> exit 1, error names 'GH_TOKEN or GITHUB_TOKEN' explicitly (negative control)"
        status: pass
      - kind: other
        ref: "grep -nE '/Users/|/home/|\\$HOME' 232-RELEASE-PR-DRYRUN.log; test $? -eq 1 -> leak sweep matches nothing"
        status: pass
      - kind: other
        ref: "bash -n scripts/ci/verify_release_pr_readiness.sh && shellcheck scripts/ci/verify_release_pr_readiness.sh -> both clean, exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "RELEASING.md's last-verified line names 2026-09-16 and commit 0327347a (the commit at which the Task 2 dry run executed); documents verify_release_pr_readiness.sh as side-effect free and branch-sourced; documents both new config keys with a one-sentence rationale each; no published CHANGELOG section touched"
    requirement: REL-05
    verification:
      - kind: other
        ref: "grep -n 'Last verified against' RELEASING.md -> dated 2026-09-16, commit 0327347a"
        status: pass
      - kind: other
        ref: "grep -c verify_release_pr_readiness.sh RELEASING.md -> 2 (>0)"
        status: pass
      - kind: other
        ref: "git diff --name-only for Task 3's commit -> RELEASING.md, .github/workflows/ci.yml only; no accrue*/CHANGELOG.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "release-manifest-ssot gains a step named exactly 'Release PR readiness dry run (REL-05)' invoking the script, no continue-on-error, workflow parses as YAML, gated with a visible skip message on missing token"
    requirement: REL-05
    verification:
      - kind: other
        ref: "python3 yaml.safe_load(.github/workflows/ci.yml) + step-presence/continue-on-error/run-content assertion -> 'wired ok'"
        status: pass
    human_judgment: false

duration: ~45min
completed: 2026-09-16
status: complete
---

# Phase 232 Plan 05: Side-effect-free REL-05 release-readiness proof Summary

**Shipped `scripts/ci/verify_release_pr_readiness.sh`, proving live against `integration/v1.62-candidate` that Release Please would produce a clean 1.5.1 -> 1.6.0 lockstep release PR across all three packages with 7 planned updates and zero truncation, pinned the two latent release-please safety keys, and wired the proof as a token-gated, non-continue-on-error step in `release-manifest-ssot`.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-09-16 (session continuation from 232-04)
- **Completed:** 2026-09-16
- **Tasks:** 3/3 completed
- **Files modified:** 5 (1 created, 4 modified, including the archived dry-run log)

## Accomplishments

- `release-please-config.json` gained `commit-search-depth: 2000` (pure safety ceiling — the walk breaks once every package's release SHA is seen, measured at 500 already in steady state, so raising it costs nothing) and `group-pull-request-title-pattern: "chore: release accrue-monorepo ${version}"` (a grouped title that cannot yield a version silently skips GitHub Release/tag creation per upstream issues #2306/#2712). Neither `last-release-sha` nor `bootstrap-sha` added; `changelog-type` and `include-component-in-tag` unchanged. The sibling dependency-operator contract was re-measured live rather than re-argued: both `accrue_admin/mix.exs` and `accrue_portal/mix.exs` declare `{:accrue, "~> #{@version}"}`, and `verify_release_manifest_alignment.sh` exits 0.
- `scripts/ci/verify_release_pr_readiness.sh` runs `npx --yes release-please@17.6.0 release-pr --dry-run` exactly once against `integration/v1.62-candidate` — the branch carrying the milestone's real, unreleased commits (measured live: `main` itself is already fully released at 1.5.1 with **zero** pending commits, so testing against `main` today would produce an empty, vacuous plan). It asserts, each with its own named `fail()` message: CLI exit 0; no commit-window truncation warning (`Expected N commits, only found M`, release-please's own message shape, confirmed via source); a live-re-derived planned update count (**7**: 1 CHANGELOG.md + 1 mix.exs per package x 3, + 1 shared manifest); exactly 3 `updating module attribute version` lines; all three packages landing on the same target version; and that version being stable semver and greater than the target branch's own **live-fetched** current manifest version (via the GitHub Contents API, not the local working tree's — this branch's local manifest reads a different, stale 1.4.0).
- Live run reproduced 232-CONTEXT.md's D-35/D-36 measurements exactly: 14 changelog bullets, all three packages to **1.6.0** (from 1.5.1), `updates: 7`, commit-search depth well under the 2000 ceiling with no truncation.
- Negative controls: open PR count (0) and tag count (66) confirmed identical before and after the run; a run with both `GH_TOKEN` and `GITHUB_TOKEN` unset exits non-zero naming the missing variable explicitly, rather than silently passing or skipping.
- `RELEASING.md`'s last-verified line refreshed to 2026-09-16 / commit `0327347a` (the commit where Task 2's dry run executed), with a new "Release PR readiness proof (REL-05)" subsection documenting the script and both new config keys.
- `release-manifest-ssot` gained a `Release PR readiness dry run (REL-05)` step after the existing linked-release-contract step, gated on `GH_TOKEN` (via `secrets.GITHUB_TOKEN`) with a **visible** bash-level skip message (not an opaque GitHub Actions step-level `if:` skip) so a fork PR without secrets prints why it skipped instead of producing a misleading red or a silent grey skip with no explanation. No `continue-on-error`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pin the two release-please safeties and re-verify the sibling dependency contract** - `a7d3c39b` (feat)
2. **Task 2: Ship the side-effect-free release-readiness proof** - `0327347a` (feat)
3. **Task 3: Refresh the release documentation truth line and wire the readiness proof into CI** - `4d61261e` (docs)

**Plan metadata:** commit pending (this SUMMARY + STATE/ROADMAP update)

## Files Created/Modified

- `release-please-config.json` - two new top-level safety keys
- `scripts/ci/verify_release_pr_readiness.sh` - new REL-05 readiness proof script
- `.planning/phases/232-bounded-hygiene-release-handoff/232-RELEASE-PR-DRYRUN.log` - archived captured dry-run output (leak-swept before commit)
- `RELEASING.md` - refreshed last-verified line + new REL-05 documentation subsection
- `.github/workflows/ci.yml` - new merge-blocking, token-gated `release-manifest-ssot` step

## Decisions Made

See `key-decisions` in frontmatter for full rationale on: targeting `integration/v1.62-candidate` instead of `main` (main has zero pending commits today); token handling and env-var precedence; live-fetching the comparison manifest version from the target branch instead of the local working tree; the `gh api -f ref=` vs `?ref=` query-string fix found during Task 2's own verification; and the bash-level (not GitHub-Actions-level) CI skip gating.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `gh api ... -f ref=<branch>` silently 404s on the Contents API GET; `?ref=<branch>` in the URL works**
- **Found during:** Task 2, first live run of the script's manifest-comparison assertion
- **Issue:** `gh api "repos/.../contents/.release-please-manifest.json" -f ref="$TARGET_BRANCH"` returned `{"message":"Not Found","status":"404"}` even though the path and branch both exist. Appending the ref as a literal query-string parameter on the path (`?ref=<branch>`) instead of via `-f` succeeded and returned the correct branch-scoped content.
- **Fix:** Changed the `gh api` invocation to embed `?ref=${TARGET_BRANCH}` directly in the URL path.
- **Files modified:** `scripts/ci/verify_release_pr_readiness.sh`.
- **Verification:** Re-ran the full script end to end; assertion 6 now correctly reports the target branch's live manifest version (1.5.1) and passes.
- **Committed in:** `0327347a` (Task 2 commit — found and fixed before the first commit, not a separate fix commit).

---

**Total deviations:** 1 auto-fixed (Rule 1 — a real bug in the script's own draft, found via its own mandated live verification before committing).
**Impact on plan:** Necessary for Task 2's own `<verify>` command to pass. No behavior change to any other script's documented contract.

## Issues Encountered

The first `npx --yes release-please@17.6.0 release-pr --dry-run` invocation against `integration/v1.62-candidate` hit a transient `ECONNRESET` while paginating merge-commit file lists via GraphQL (a ~527-commit history walk makes many individual API calls). A bare retry of the identical command succeeded with exit 0. No code change was needed; this is external network flakiness, not a defect in the script or configuration, and the script itself does not retry internally (a hung or failed dry run should surface as a failure, not be silently retried past).

## User Setup Required

None - no external service configuration required. A `GH_TOKEN` or `GITHUB_TOKEN` with repo read access is required to run the script, documented in both the script's own header and `RELEASING.md`.

## Next Phase Readiness

REL-05 is now provable by one committed, re-runnable command (`bash scripts/ci/verify_release_pr_readiness.sh`) with `human_judgment: false` — it reads everything, writes nothing, and its own negative control proves the fail-closed token path. The commit-window ceiling and version-bearing grouped title are configured with no forbidden key added. `RELEASING.md`'s verification claim is current and names the new proof. No blockers for 232-06 or later plans. `HYG-02` remains a shared ID declared across multiple plans in this phase and flips complete only when every declaring plan finishes (per the shared-ID gate); `REL-05` is declared solely by this plan.

## Self-Check: PASSED

- FOUND: `scripts/ci/verify_release_pr_readiness.sh` (verified via `bash -n` and `shellcheck`, both clean)
- FOUND: `a7d3c39b`, `0327347a`, `4d61261e` (all three task commits) in `git log --oneline`
- Re-ran all plan-level `<verification>` commands: `bash scripts/ci/verify_release_pr_readiness.sh` -> exit 0, all 6 assertions named; PR count (0) and tag count (66) identical before/after; missing-token negative control -> exit 1, names the variable; `release-manifest-ssot` step presence + no-`continue-on-error` + workflow-parses assertion -> `wired ok`; `RELEASING.md` last-verified line -> dated 2026-09-16, commit `0327347a` (confirmed live)

---
*Phase: 232-bounded-hygiene-release-handoff*
*Completed: 2026-09-16*
