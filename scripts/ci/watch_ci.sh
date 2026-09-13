#!/usr/bin/env bash
# Compatibility entry point for the structured, bounded CI monitor.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
branch=""

# Preserve the documented optional branch positional while allowing monitor flags.
if [[ $# -gt 0 && "$1" != --* ]]; then
  branch="$1"
  shift
fi

has_option() {
  local option="$1"
  local argument
  for argument in "$@"; do
    [[ "$argument" == "$option" ]] && return 0
  done
  return 1
}

monitor_args=()
if [[ -n "$branch" ]] && ! has_option --sha "$@"; then
  monitor_args+=(--branch "$branch")
fi
if ! has_option --timeout-seconds "$@"; then
  monitor_args+=(--timeout-seconds 900)
fi
if ! has_option --poll-seconds "$@"; then
  monitor_args+=(--poll-seconds 10)
fi

exec node "$repo_root/scripts/ci/ci_monitor.cjs" watch --repo szTheory/accrue "${monitor_args[@]}" "$@"
