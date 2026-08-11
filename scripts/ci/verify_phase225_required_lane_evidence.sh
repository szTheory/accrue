#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
incident_file="$root_dir/.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md"

fail() {
  echo "verify_phase225_required_lane_evidence: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required"
}

require_markdown_values() {
  local label="$1"
  local values

  case "$label" in
    "Fresh repair run ID")
      values="$(sed -E -n 's/^[[:space:]]*-[[:space:]]*\*\*Fresh repair run ID:\*\*[[:space:]]*\[([0-9][0-9]*)\].*/\1/p' "$incident_file")"
      ;;
    "Fresh repair SHA")
      values="$(sed -E -n 's/^[[:space:]]*-[[:space:]]*\*\*Fresh repair SHA:\*\*[[:space:]]*`([0-9a-f][0-9a-f]*)`.*/\1/p' "$incident_file")"
      ;;
    *) fail "unsupported Markdown field: $label" ;;
  esac

  [ "$(printf '%s\n' "$values" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 2 ] ||
    fail "expected two Markdown '${label}' values"

  printf '%s\n' "$values" | sed '/^$/d' | sort -u
}

require_command gh
require_command jq
[ -f "$incident_file" ] || fail "missing incident ledger"

# These fields are deliberately Markdown-aware: the ledger uses bold list labels
# and code-formatted values, not bare `Label: value` lines.
mapfile -t repair_run_ids < <(require_markdown_values "Fresh repair run ID")
mapfile -t repair_shas < <(require_markdown_values "Fresh repair SHA")

[ "${#repair_run_ids[@]}" -eq 1 ] || fail "incident sections disagree on fresh repair run ID"
[ "${#repair_shas[@]}" -eq 1 ] || fail "incident sections disagree on fresh repair SHA"

run_id="${repair_run_ids[0]}"
repair_sha="${repair_shas[0]}"
[[ "$run_id" =~ ^[0-9]{8,}$ ]] || fail "invalid fresh repair run ID: $run_id"
[[ "$repair_sha" =~ ^[0-9a-f]{40}$ ]] || fail "invalid fresh repair SHA: $repair_sha"
run_json="$(gh run view "$run_id" --json event,headSha,status,conclusion,jobs,url)" ||
  fail "could not read GitHub Actions run $run_id"

printf '%s\n' "$run_json" | jq -e --arg sha "$repair_sha" '
  .event == "workflow_dispatch" and
  .headSha == $sha and
  .status == "completed" and
  .conclusion == "success" and
  ([.jobs[] | select(.name | startswith("Release gate (")) | select((.name | contains("[advisory]")) | not)] | length == 3) and
  (all(.jobs[] | select(.name | startswith("Release gate (")) | select((.name | contains("[advisory]")) | not); .conclusion == "success")) and
  ([.jobs[] | select(.name | startswith("Release gate (")) | select(.name | contains("[advisory]"))] | length == 1) and
  (all(.jobs[] | select(.name | startswith("Release gate (")) | select(.name | contains("[advisory]")); .conclusion == "success")) and
  any(.jobs[]; .name == "Admin hardening guardrails (Phase 192)" and .conclusion == "success")
' >/dev/null || fail "run $run_id does not prove the required/advisory CI contract for $repair_sha"

artifacts_json="$(gh api "repos/{owner}/{repo}/actions/runs/$run_id/artifacts")" ||
  fail "could not read artifacts for GitHub Actions run $run_id"

printf '%s\n' "$artifacts_json" | jq -e '
  all(
    ["phase192-admin-playwright-report", "phase192-generated-evidence"][] as $name;
    any(.artifacts[]; .name == $name and .expired == false)
  )
' >/dev/null || fail "run $run_id is missing a required non-expired Phase 192 artifact"

echo "verify_phase225_required_lane_evidence: ok (run $run_id, sha $repair_sha)"
