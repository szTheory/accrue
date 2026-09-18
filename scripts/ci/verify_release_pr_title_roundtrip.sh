#!/usr/bin/env bash

set -euo pipefail

# Guard: the grouped release-PR title must round-trip through release-please.
#
# WHY (mechanism, not superstition -- this cost release 1.6.0 a wedged pipeline):
#
# release-please's Merge plugin builds the grouped PR title with
#   PullRequestTitle.ofComponentTargetBranchVersion(
#     rootRelease?.pullRequest.title.component,
#     targetBranch,
#     rootRelease?.pullRequest.title.version,   <-- the ${version} source
#     groupPullRequestTitlePattern)
# where `rootRelease` is the release candidate whose path is exactly ".".
#
# This repo has NO package at path "." -- only accrue, accrue_admin and
# accrue_portal. So `rootRelease` is null, the version argument is undefined,
# and a `${version}` placeholder in the group pattern renders EMPTY. The
# generated title comes out as "chore: release accrue-monorepo".
#
# At release time strategies/base.js parses that title back:
#   PullRequestTitle.parse(title, perPackagePattern)
#     || PullRequestTitle.parse(title, groupPattern)
# Both return null for a versionless title, so release-please logs
# "Bad pull request title", tags NOTHING, and then blocks every future
# release PR with "There are untagged, merged release PRs outstanding".
# The workflow still reports success, so the failure is silent.
#
# Therefore: a group-pull-request-title-pattern is only safe here once a
# root package at path "." exists to supply the version. Until then the
# default pattern ("chore: release ${branch}") is the correct choice -- it
# generates "chore: release main", which parses, and which every successful
# release before 1.6.0 used.

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "[verify_release_pr_title_roundtrip] $*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required but not installed"

CONFIG="$ROOT_DIR/release-please-config.json"
[[ -f "$CONFIG" ]] || fail "missing $CONFIG"

# Capture-then-filter rather than `... | grep -q`: under `set -euo pipefail`
# a short-circuiting consumer kills the producer with SIGPIPE, pipefail
# promotes that to a failure, and an `if !` inversion would silently skip a
# real violation. See the SL-D guard work for the full write-up.
group_pattern=$(jq -r '."group-pull-request-title-pattern" // empty' "$CONFIG")
has_root_package=$(jq -r 'if (.packages | has(".")) then "yes" else "no" end' "$CONFIG")

if [[ -z "$group_pattern" ]]; then
  echo "[verify_release_pr_title_roundtrip] OK: no group-pull-request-title-pattern; release-please uses the default 'chore: release \${branch}' title, which round-trips."
  exit 0
fi

if [[ "$has_root_package" != "yes" ]]; then
  fail "group-pull-request-title-pattern is set to '$group_pattern' but release-please-config.json declares no package at path \".\".
Without a root package the Merge plugin has no version to substitute, so the generated title loses its version, fails to parse at release time, and wedges the release pipeline (this is exactly what happened to release 1.6.0 / PR #46).
Fix: remove group-pull-request-title-pattern, or add a package at path \".\" to supply the version."
fi

# A root package exists, so ${version} can resolve. Still require that the
# pattern actually asks for a version -- a versionless grouped title does not
# parse either (verified against release-please 17.6.0).
# shellcheck disable=SC2016  # the single quotes are deliberate: we match the
# LITERAL four-character placeholder ${version} in the config value, and must
# not let the shell expand it.
case "$group_pattern" in
  *'${version}'*)
    echo "[verify_release_pr_title_roundtrip] OK: root package present and pattern carries \${version}."
    ;;
  *)
    fail "group-pull-request-title-pattern '$group_pattern' contains no \${version}; a versionless grouped title fails PullRequestTitle.parse at release time and tags nothing."
    ;;
esac
