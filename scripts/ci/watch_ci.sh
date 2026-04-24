#!/usr/bin/env bash
# Wait for the latest GitHub Actions "CI" workflow run on a branch (default: main).
# Requires: gh CLI, authenticated for this repo (gh auth login).
set -euo pipefail

branch="${1:-main}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if ! command -v gh >/dev/null 2>&1; then
  echo "watch_ci: gh CLI not found; install https://cli.github.com/" >&2
  exit 1
fi

run_id="$(gh run list --branch "$branch" --workflow CI --limit 1 --json databaseId --jq '.[0].databaseId')"
if [[ -z "$run_id" || "$run_id" == "null" ]]; then
  echo "watch_ci: no CI runs found for branch ${branch}" >&2
  exit 1
fi

echo "watch_ci: watching run ${run_id} (branch ${branch})…"
gh run watch "$run_id" --exit-status
echo "watch_ci: run ${run_id} finished successfully"
