#!/usr/bin/env bash
# Merge a Release Please PR using the GitHub CLI after checks finish.
#
# Usage:
#   scripts/ci/gh_merge_release_pr.sh 7
#   scripts/ci/gh_merge_release_pr.sh
#
# With no PR number, requires exactly one open PR whose head branch name
# starts with `release-please--` (otherwise pass the number explicitly).
#
# Modes:
#   (default)  gh pr checks --watch  then  gh pr merge --merge
#   --auto     gh pr merge --merge --auto  (GitHub merges when requirements pass; returns now)
#
# Requires: gh auth with repo scope, merge rights on the repo.
set -euo pipefail

usage() {
  echo "usage: $0 [--auto] [<PR_NUMBER>]" >&2
  echo "  --auto   enable GitHub auto-merge instead of blocking until checks complete" >&2
}

auto=0
pr=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --auto)
      auto=1
      shift
      ;;
    *)
      if [[ -n "$pr" ]]; then
        usage
        exit 1
      fi
      pr="$1"
      shift
      ;;
  esac
done

find_release_please_pr() {
  gh pr list --state open --json number,headRefName \
    --jq '.[] | select(.headRefName | test("^release-please--")) | .number' |
    awk 'NR==1 { print; exit }'
}

if [[ -z "$pr" ]]; then
  pr="$(find_release_please_pr)"
fi

if [[ -z "$pr" ]]; then
  echo "$0: no open PR with head ref matching ^release-please-- (pass PR number explicitly)." >&2
  exit 1
fi

if [[ "$auto" == 1 ]]; then
  gh pr merge "$pr" --merge --auto
  echo "Auto-merge enabled for PR #${pr} (merge commit)."
  exit 0
fi

echo "Watching checks for PR #${pr} (Ctrl+C to abort)..."
if ! gh pr checks "$pr" --watch; then
  echo "$0: checks failed or were cancelled." >&2
  exit 1
fi

gh pr merge "$pr" --merge
echo "Merged PR #${pr} with a merge commit."
