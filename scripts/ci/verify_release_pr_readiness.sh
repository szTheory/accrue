#!/usr/bin/env bash

# REL-05 readiness proof: runs `release-please release-pr --dry-run` exactly
# once against the real repository on GitHub, captures its combined output,
# and asserts six things about the plan it would produce. The dry run only
# reads (config, releases, commit history) and only writes to its own log
# file -- it creates no PR, branch, tag, release, or comment. See D-39/D-35
# through D-44 in 232-CONTEXT.md and the "verify_release_pr_readiness.sh
# (D-39, REL-05 proof)" pattern entry in 232-PATTERNS.md.
#
# Usage:
#   bash scripts/ci/verify_release_pr_readiness.sh [output-log-path]
#
# Required environment:
#   GH_TOKEN or GITHUB_TOKEN -- a repo-scoped token release-please uses to
#   read config, releases, and commit history from the target branch on
#   GitHub. Fails closed with a distinctly-named error when absent -- a
#   missing credential must never silently read as a pass.

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}
cd "$ROOT_DIR"

fail() {
  echo "[verify_release_pr_readiness] $*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required but not installed"
command -v npx >/dev/null 2>&1 || fail "npx is required but not installed"
command -v gh >/dev/null 2>&1 || fail "gh is required but not installed (the target-branch and remote-manifest assertions read through the GitHub API)"

REPO=${GITHUB_REPOSITORY:-szTheory/accrue}

# The integration candidate is the branch this milestone's REL-04 integration
# PR targets for merge into `main`; it is where the real, unreleased commits
# live today -- `main` itself has zero pending commits until this candidate
# merges (D-01/D-02: main was already re-released to 1.5.1 directly, while
# the candidate carries additional commits on top that have never been
# released). Testing against an empty branch would make every assertion
# below vacuously fail (no packages appear in an empty plan), which is
# exactly the false-pass risk this proof exists to avoid.
#
# This name is REMOTE and ephemeral. Every assertion below reads the target
# through the GitHub API, so the LOCAL branch of the same name is irrelevant
# -- and the two have already diverged once in this milestone: plan 232-09's
# re-cut could not force-push the published `integration/v1.62-candidate`, so
# it published `integration/v1.62-candidate-recut` instead while the local
# branch kept the original name. The default below therefore names the
# PUBLISHED re-cut, not the local branch. Override via
# RELEASE_PR_READINESS_TARGET_BRANCH when a later re-cut publishes a new one.
TARGET_BRANCH=${RELEASE_PR_READINESS_TARGET_BRANCH:-integration/v1.62-candidate-recut}

TOKEN=${GH_TOKEN:-${GITHUB_TOKEN:-}}
[[ -n "$TOKEN" ]] || fail "missing required token: set GH_TOKEN or GITHUB_TOKEN (a repo-scoped token release-please uses to read config/releases/commits from the target branch) -- an absent token must never read as a pass"

OUTPUT_LOG=${1:-$(mktemp)}

MANIFEST="$ROOT_DIR/.release-please-manifest.json"
[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"

# release-please only ever emits `logger.warn` on a truncated commit window
# (D-38) -- it never fails the run for it, so grepping the captured log is
# the only thing standing between a silently wrong release and a green run.
# The configured ceiling below is release-please-config.json's own value,
# asserted live rather than transcribed, so this message stays accurate if
# the ceiling ever changes.
CONFIGURED_SEARCH_DEPTH=$(jq -r '."commit-search-depth" // empty' "$ROOT_DIR/release-please-config.json")
[[ -n "$CONFIGURED_SEARCH_DEPTH" ]] || fail "release-please-config.json is missing commit-search-depth -- cannot name the configured ceiling in a truncation failure"

# The number of files release-please's dry run reports as "updates" when a
# real, ready-to-release plan is produced: one CHANGELOG.md + one mix.exs
# per package (3 packages x 2 = 6), plus the single shared manifest json
# (+1) = 7. Re-derived live against the real target branch during this
# plan's execution (2026-09-16), not transcribed from CONTEXT.md (D-39).
# Counts what it counts: every file the dry-run's own "updates: N" line
# reports, not a hand-guessed total.
EXPECTED_UPDATES=7

# One "updating module attribute version" line per package (accrue,
# accrue_admin, accrue_portal) -- re-derived live the same way.
EXPECTED_MODULE_ATTRIBUTE_LINES=3

echo "verify_release_pr_readiness: target branch: $TARGET_BRANCH"

# Assertion 0: the target must not be an ALREADY-SUPERSEDED candidate. A
# release-readiness proof computed against an abandoned branch passes happily
# and proves nothing -- the exact failure this guard exists to make
# impossible. `232-ROLLBACK-POINT.json` records the object the current re-cut
# superseded; if the target's remote tip still resolves to it, the default
# above (or the override) was never re-pointed after a re-cut.
# Resolved, not hardcoded: milestone close moves phase evidence from
# `.planning/phases/` to `.planning/milestones/<version>-phases/`, and a
# frozen literal would turn this guard into a silent no-op the moment
# v1.62 was archived. A failed resolve leaves the variable empty, which
# preserves the pre-existing "record absent -> skip assertion 0" shape
# rather than aborting under `set -e`.
ROLLBACK_RELATIVE="$(node "$ROOT_DIR"/scripts/ci/phase_evidence_path.mjs 232-bounded-hygiene-release-handoff 232-ROLLBACK-POINT.json 2>/dev/null || true)"
ROLLBACK_RECORD="${ROLLBACK_RELATIVE:+$ROOT_DIR/$ROLLBACK_RELATIVE}"
if [[ -n "$ROLLBACK_RECORD" && -f "$ROLLBACK_RECORD" ]]; then
  SUPERSEDED_OBJECT=$(jq -r '.supersedes.candidate_object // empty' "$ROLLBACK_RECORD")
  TARGET_TIP=$(GH_TOKEN="$TOKEN" gh api "repos/${REPO}/commits/${TARGET_BRANCH}" --jq '.sha' 2>/dev/null) ||
    fail "target branch '$TARGET_BRANCH' does not resolve on the remote -- an unresolvable target must never read as a pass"
  [[ -n "$TARGET_TIP" ]] || fail "could not resolve the remote tip of target branch '$TARGET_BRANCH'"
  if [[ -n "$SUPERSEDED_OBJECT" && "$TARGET_TIP" == "$SUPERSEDED_OBJECT" ]]; then
    fail "target branch '$TARGET_BRANCH' still points at the superseded candidate $SUPERSEDED_OBJECT -- re-point RELEASE_PR_READINESS_TARGET_BRANCH at the current re-cut"
  fi
  echo "verify_release_pr_readiness: [0/6] target '$TARGET_BRANCH' resolves to $TARGET_TIP and is not the superseded candidate"
fi
echo "verify_release_pr_readiness: capturing dry-run output to $OUTPUT_LOG"

set +e
GH_TOKEN="$TOKEN" npx --yes release-please@17.6.0 release-pr \
  --dry-run \
  --repo-url "https://github.com/${REPO}" \
  --target-branch "$TARGET_BRANCH" \
  --config-file release-please-config.json \
  --manifest-file .release-please-manifest.json \
  --token "$TOKEN" \
  >"$OUTPUT_LOG" 2>&1
DRYRUN_EXIT=$?
set -e

# Assertion 1: the CLI itself exited zero.
if [[ "$DRYRUN_EXIT" -ne 0 ]]; then
  echo "--- captured dry-run output ---" >&2
  cat "$OUTPUT_LOG" >&2
  fail "release-please release-pr --dry-run exited $DRYRUN_EXIT (expected 0)"
fi
echo "verify_release_pr_readiness: [1/6] CLI exited 0"

# Assertion 2: no commit-window truncation warning. release-please's own
# message shape is: "Expected ${expectedShas} commits, only found
# ${releaseCommitsFound}" (manifest.js), logged as a bare warning that never
# fails the run on its own.
if grep -qE 'Expected [0-9]+ commits, only found [0-9]+' "$OUTPUT_LOG"; then
  fail "commit-window truncation warning detected -- the walk exceeded the configured commit-search-depth ($CONFIGURED_SEARCH_DEPTH) and the changelog/version-bump computation is unreliable; raise commit-search-depth in release-please-config.json"
fi
echo "verify_release_pr_readiness: [2/6] no commit-window truncation warning (configured ceiling: $CONFIGURED_SEARCH_DEPTH)"

# Assertion 3: the planned update count matches the expected number for
# this repository.
ACTUAL_UPDATES=$(grep -oE '^updates: [0-9]+' "$OUTPUT_LOG" | tail -n 1 | awk '{print $2}')
[[ -n "$ACTUAL_UPDATES" ]] || fail "could not find an 'updates: N' line in the dry-run output -- release-please may have produced an empty or unparseable plan"
[[ "$ACTUAL_UPDATES" -eq "$EXPECTED_UPDATES" ]] ||
  fail "planned update count is $ACTUAL_UPDATES, expected $EXPECTED_UPDATES (1 CHANGELOG.md + 1 mix.exs per package x 3 packages, + 1 shared manifest json)"
echo "verify_release_pr_readiness: [3/6] planned update count matches expected ($ACTUAL_UPDATES)"

# Assertion 4 + 5 + 6: exactly EXPECTED_MODULE_ATTRIBUTE_LINES
# "updating module attribute version" lines, all three packages land on the
# SAME target version, that version is stable semver (no pre-release or
# build suffix), and it compares greater than the CURRENT version recorded
# in the target branch's own manifest (not the local working tree's, which
# may be stale relative to the branch under test -- see D-38's silent-wrong
# class this whole script exists to catch).
mapfile -t MODULE_LINES < <(grep -oE 'updating module attribute version from [0-9]+\.[0-9]+\.[0-9]+ to [0-9]+\.[0-9]+\.[0-9]+' "$OUTPUT_LOG")
ACTUAL_MODULE_LINES=${#MODULE_LINES[@]}
[[ "$ACTUAL_MODULE_LINES" -eq "$EXPECTED_MODULE_ATTRIBUTE_LINES" ]] ||
  fail "found $ACTUAL_MODULE_LINES 'updating module attribute version' lines, expected exactly $EXPECTED_MODULE_ATTRIBUTE_LINES (one per package)"
echo "verify_release_pr_readiness: [4/6] found exactly $EXPECTED_MODULE_ATTRIBUTE_LINES module-attribute version update lines"

FROM_VERSIONS=()
TO_VERSIONS=()
for line in "${MODULE_LINES[@]}"; do
  FROM_VERSIONS+=("$(sed -E 's/.*from ([0-9]+\.[0-9]+\.[0-9]+) to .*/\1/' <<<"$line")")
  TO_VERSIONS+=("$(sed -E 's/.*to ([0-9]+\.[0-9]+\.[0-9]+)$/\1/' <<<"$line")")
done

FIRST_TO="${TO_VERSIONS[0]}"
for v in "${TO_VERSIONS[@]}"; do
  [[ "$v" == "$FIRST_TO" ]] || fail "packages do not all land on the same target version: saw ${TO_VERSIONS[*]}"
done
echo "verify_release_pr_readiness: [5/6] all $ACTUAL_MODULE_LINES packages land on the same target version ($FIRST_TO)"

# Stable semver only: reject any pre-release (-rc.N) or build (+meta) suffix.
[[ "$FIRST_TO" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail "planned version '$FIRST_TO' is not stable semver (no pre-release/build suffix allowed)"

# Compare against the TARGET BRANCH's own current manifest version (fetched
# live via the GitHub Contents API), never the local working tree's -- the
# working tree may be on a different line entirely (D-02: this branch's own
# manifest currently reads a lower version than the branch under test).
REMOTE_MANIFEST_JSON=$(GH_TOKEN="$TOKEN" gh api "repos/${REPO}/contents/.release-please-manifest.json?ref=${TARGET_BRANCH}" --jq '.content' | base64 -d)
CURRENT_VERSION=$(jq -r '.accrue // empty' <<<"$REMOTE_MANIFEST_JSON")
[[ -n "$CURRENT_VERSION" ]] || fail "could not read .accrue from the target branch's .release-please-manifest.json via the GitHub API"

HIGHEST=$(printf '%s\n%s\n' "$CURRENT_VERSION" "$FIRST_TO" | sort -V | tail -n 1)
[[ "$HIGHEST" == "$FIRST_TO" && "$FIRST_TO" != "$CURRENT_VERSION" ]] ||
  fail "planned version $FIRST_TO does not compare greater than the target branch's current manifest version $CURRENT_VERSION"
echo "verify_release_pr_readiness: [6/6] planned version $FIRST_TO is stable semver and greater than the current manifest version $CURRENT_VERSION"

echo "verify_release_pr_readiness: PASS -- all 6 assertions ran (target: $TARGET_BRANCH, plan: $CURRENT_VERSION -> $FIRST_TO, updates: $ACTUAL_UPDATES)"
echo "verify_release_pr_readiness: captured log at $OUTPUT_LOG"
