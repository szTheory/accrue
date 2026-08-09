#!/usr/bin/env bash
# Collects reduced GitHub Actions metadata only. It never requests logs or downloads artifacts.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() {
  cat <<'EOF'
Usage: capture_ci_baseline.sh --run-id ID [--run-id ID ...] --output PATH [--fixture-dir PATH]

Collects allowlisted GitHub Actions run, job, step, artifact, and branch-policy metadata.
Fixture mode reads sanitized run.json, jobs.json, artifacts.json, rules.json, and
required_status_checks.json responses from the supplied directory instead of GitHub.
EOF
}

fail() { echo "capture_ci_baseline: $*" >&2; exit 2; }

run_ids=()
output=""
fixture_dir=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --run-id) [ "$#" -ge 2 ] || fail "--run-id requires an ID"; run_ids+=("$2"); shift 2 ;;
    --output) [ "$#" -ge 2 ] || fail "--output requires a path"; output="$2"; shift 2 ;;
    --fixture-dir) [ "$#" -ge 2 ] || fail "--fixture-dir requires a path"; fixture_dir="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

[ "${#run_ids[@]}" -gt 0 ] || fail "at least one --run-id is required"
[ -n "$output" ] || fail "--output is required"
for run_id in "${run_ids[@]}"; do [[ "$run_id" =~ ^[0-9]+$ ]] || fail "run ID must be numeric: $run_id"; done
command -v jq >/dev/null 2>&1 || fail "jq is required"

repo="${GITHUB_REPOSITORY:-}"
if [ -z "$repo" ]; then
  remote_url="$(git -C "$root_dir" config --get remote.origin.url 2>/dev/null || true)"
  repo="$(printf '%s' "$remote_url" | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##')"
fi
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail "could not derive owner/repo; set GITHUB_REPOSITORY"

if [ -z "$fixture_dir" ]; then command -v gh >/dev/null 2>&1 || fail "gh is required outside fixture mode"; else [ -d "$fixture_dir" ] || fail "fixture directory does not exist: $fixture_dir"; fi

tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

api_get() {
  local endpoint="$1" body="$2"
  gh api -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' "$endpoint" >"$body"
}

copy_fixture() {
  local source="$1" destination="$2"
  [ -f "$fixture_dir/$source" ] || fail "fixture response missing: $source"
  cp "$fixture_dir/$source" "$destination"
}

policy_for_job() {
  local job_name="$1" event="$2"
  if [ "$event" = "schedule" ] && [[ "$job_name" != *"live-stripe"* ]]; then printf 'conditional';
  elif [[ "$job_name" =~ \[advisory\] ]] || [[ "$job_name" == *"ratchet"* ]]; then printf 'advisory';
  else printf 'required'; fi
}

build_run() {
  local run_id="$1" run_raw="$tmp_dir/run-$run_id.raw.json" jobs_raw="$tmp_dir/jobs-$run_id.raw.json" artifacts_raw="$tmp_dir/artifacts-$run_id.raw.json"
  if [ -n "$fixture_dir" ]; then
    copy_fixture "run-${run_id}.json" "$run_raw"
    copy_fixture "jobs-${run_id}.json" "$jobs_raw"
    copy_fixture "artifacts-${run_id}.json" "$artifacts_raw"
  else
    api_get "/repos/$repo/actions/runs/$run_id" "$run_raw"
    api_get "/repos/$repo/actions/runs/$run_id/attempts/$(jq -r '.run_attempt' "$run_raw")/jobs?per_page=100" "$jobs_raw"
    api_get "/repos/$repo/actions/runs/$run_id/artifacts?per_page=100" "$artifacts_raw"
  fi

  # Immediately reduce transient provider data to the documented metadata allowlist.
  jq -e '
    {run: {id: .id, workflow: .name, event: .event, head_sha: .head_sha, attempt: .run_attempt,
      status: .status, conclusion: .conclusion, created_at: .created_at, completed_at: .updated_at,
      url: .html_url, wall_seconds: (if .created_at and .updated_at then ((.updated_at|fromdateiso8601)-(.created_at|fromdateiso8601)) else null end),
      eligible: (.event == "workflow_dispatch" and .run_attempt == 1 and .conclusion == "success"),
      exclusion_reason: (if (.event == "workflow_dispatch" and .run_attempt == 1 and .conclusion == "success") then null else "event, attempt, or conclusion is not eligible" end)}}' "$run_raw" >"$tmp_dir/run-$run_id.allowed.json"

  local event
  event="$(jq -r '.run.event' "$tmp_dir/run-$run_id.allowed.json")"
  jq -e --arg event "$event" '
    .jobs // . | map({id, name, status, conclusion, started_at, completed_at,
      steps: [(.steps // [])[] | {name, conclusion, started_at, completed_at,
        duration_seconds: (if .started_at and .completed_at then ((.completed_at|fromdateiso8601)-(.started_at|fromdateiso8601)) else null end)}]})' "$jobs_raw" >"$tmp_dir/jobs-$run_id.allowed.json"

  jq -e '
    .artifacts // . | map({id, name, size_in_bytes, expires_at, expired})' "$artifacts_raw" >"$tmp_dir/artifacts-$run_id.allowed.json"

  jq -n --argjson run "$(cat "$tmp_dir/run-$run_id.allowed.json")" --argjson jobs "$(cat "$tmp_dir/jobs-$run_id.allowed.json")" --argjson artifacts "$(cat "$tmp_dir/artifacts-$run_id.allowed.json")" --arg event "$event" '
    $run + {jobs: [$jobs[] | . + {
      policy: (if $event == "schedule" and (.name | contains("live-stripe") | not) then "conditional" elif (.name | test("\\[advisory\\]"; "i") or test("ratchet"; "i")) then "advisory" else "required" end),
      proof_state: (if .conclusion == "skipped" then "skipped" elif ($event == "schedule" and (.name | contains("live-stripe") | not)) then "not-applicable" elif (.name | test("\\[advisory\\]"; "i") or test("ratchet"; "i")) then "advisory" elif $run.run.eligible and .conclusion == "success" then "proved" else "not-applicable" end),
      duration_seconds: (if .started_at and .completed_at then ((.completed_at|fromdateiso8601)-(.started_at|fromdateiso8601)) else null end),
      cache_state: (if any(.steps[]?; .name == "Create accrue PLTs" and .conclusion == "skipped") then "observed-hit" elif any(.steps[]?; .name == "Create accrue PLTs" and .conclusion == "success") then "observed-miss" else "unknown" end)
    }], artifacts: $artifacts}' >"$tmp_dir/record-$run_id.json"
}

for run_id in "${run_ids[@]}"; do build_run "$run_id"; done

rules_raw="$tmp_dir/rules.raw.json"
classic_raw="$tmp_dir/classic.raw.json"
if [ -n "$fixture_dir" ]; then
  copy_fixture rules.json "$rules_raw"; copy_fixture required_status_checks.json "$classic_raw"
else
  api_get "/repos/$repo/rules/branches/main" "$rules_raw"
  if ! api_get "/repos/$repo/branches/main/protection/required_status_checks" "$classic_raw" 2>/dev/null; then
    printf '{"response_state":"not-found"}\n' >"$classic_raw"
  fi
fi

jq -e '
  if type == "array" then {rules_response_state: "ok", rules: [.[].rules[]? | select(.type == "required_status_checks") | .parameters.required_status_checks[]? | {context: .context, app_id: .integration_id}]} else {rules_response_state: (.response_state // "ok"), rules: []} end' "$rules_raw" >"$tmp_dir/rules.allowed.json"
jq -e '
  if .response_state == "not-found" then {classic_response_state: "not-found", classic_checks: []}
  else {classic_response_state: "ok", classic_checks: ([((.contexts // [])[] | {context: ., app_id: null})] + [((.checks // [])[] | {context: .context, app_id: .app_id})])} end' "$classic_raw" >"$tmp_dir/classic.allowed.json"

jq -s --arg repo "$repo" --argjson rules "$(cat "$tmp_dir/rules.allowed.json")" --argjson classic "$(cat "$tmp_dir/classic.allowed.json")" '
  {schema_version: 1, repository: $repo,
   privacy: {logs_downloaded: false, artifact_archives_downloaded: false, env_values_recorded: false, raw_payloads_recorded: false,
     allowlist: ["run identity and timestamps", "job and step metadata", "cache state", "artifact name/size/expiry", "required-check context/app ID"]},
   required_check_snapshot: ($rules + $classic + {enforcement_state: (if ($rules.rules | length) == 0 and ($classic.classic_checks | length) == 0 and $classic.classic_response_state == "not-found" then "none-enforced" else "enforced" end)}),
   runs: .}' "$tmp_dir"/record-*.json >"$tmp_dir/output.json"

jq -e . "$tmp_dir/output.json" >/dev/null
output_dir="$(dirname "$output")"; [ -d "$output_dir" ] || fail "output directory does not exist: $output_dir"
mv "$tmp_dir/output.json" "$output"
