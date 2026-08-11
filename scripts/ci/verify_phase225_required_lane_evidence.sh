#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
incident_file="${INCIDENT_FILE:-$root_dir/.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md}"

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

incident_section() {
  local incident_id="$1"

  awk -v incident_id="$incident_id" '
    $0 == "## " incident_id { in_section = 1; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$incident_file"
}

require_incident_ledger_contract() {
  local incident_id
  local section
  local field
  local incident_count

  incident_count="$(rg -c '^## INC-225-' "$incident_file")"
  [ "$incident_count" -eq 2 ] ||
    fail "expected exactly two Phase 225 incident sections"

  for incident_id in INC-225-RELEASE-WEBHOOK INC-225-ADMIN-PAGEFLOW; do
    section="$(incident_section "$incident_id")"
    [ -n "$section" ] || fail "missing incident section: $incident_id"

    for field in \
      '**What failed:**' \
      '**Classification:**' \
      '**Next command:**' \
      '**Evidence:**' \
      '**Incident ID/status:**' \
      '**Normalized signature:**' \
      '**Classification/confidence:**' \
      '**Affected cells:**' \
      '**Canonical owner and repair surface:**' \
      '**Narrow repro:**' \
      '**Immutable evidence/artifact links:**' \
      '**Ruled-out hypotheses:**' \
      '**Root cause:**' \
      '**Corrective change:**' \
      '**Negative-control proof:**' \
      '**Fresh repair SHA:**' \
      '**Fresh repair run ID:**' \
      '**Residual owner/status:**'
    do
      printf '%s\n' "$section" | rg -Fq "$field" ||
        fail "$incident_id is missing required field: $field"
    done
  done

  section="$(incident_section INC-225-RELEASE-WEBHOOK)"
  for field in \
    'Floor `[required]`' \
    'Primary dev target `[required]`' \
    'Primary dev target with OpenTelemetry `[required]`' \
    'Primary dev target with Sigra `[advisory]`' \
    'Sigra is not required release proof.'
  do
    printf '%s\n' "$section" | rg -Fq "$field" ||
      fail "release incident does not preserve required/advisory classification: $field"
  done

  section="$(incident_section INC-225-ADMIN-PAGEFLOW)"
  for field in \
    '`admin-hardening-guardrails` `[required]`' \
    'phase192-admin-playwright-report' \
    'phase192-generated-evidence'
  do
    printf '%s\n' "$section" | rg -Fq "$field" ||
      fail "Admin incident is missing required evidence: $field"
  done
}

require_command gh
require_command jq
[ -f "$incident_file" ] || fail "missing incident ledger"
require_incident_ledger_contract

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
  . as $response |
  all(
    ["phase192-admin-playwright-report", "phase192-generated-evidence"][];
    . as $name | any($response.artifacts[]; .name == $name and .expired == false)
  )
' >/dev/null || fail "run $run_id is missing a required non-expired Phase 192 artifact"

echo "verify_phase225_required_lane_evidence: ok (run $run_id, sha $repair_sha)"
