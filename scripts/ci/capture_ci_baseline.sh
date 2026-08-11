#!/usr/bin/env bash
# Collect reduced, metadata-only Actions evidence.  This script never requests logs,
# annotations, payloads, workflow dispatches, or artifact archive downloads.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
policy_manifest="$root_dir/scripts/ci/ci_baseline_workflow_policy.json"
fail() { echo "capture_ci_baseline: $*" >&2; exit 2; }
usage() { echo "Usage: capture_ci_baseline.sh --run-id ID [--run-id ID ...] --output PATH [--fixture-dir PATH]"; }

run_ids=(); output=""; fixture_dir=""
while [ "$#" -gt 0 ]; do case "$1" in
  --run-id) [ "$#" -ge 2 ] || fail "--run-id requires an ID"; run_ids+=("$2"); shift 2 ;;
  --output) [ "$#" -ge 2 ] || fail "--output requires a path"; output="$2"; shift 2 ;;
  --fixture-dir) [ "$#" -ge 2 ] || fail "--fixture-dir requires a path"; fixture_dir="$2"; shift 2 ;;
  -h|--help) usage; exit 0 ;; *) fail "unknown argument: $1" ;; esac; done
[ "${#run_ids[@]}" -gt 0 ] || fail "at least one --run-id is required"
[ -n "$output" ] || fail "--output is required"
for id in "${run_ids[@]}"; do [[ "$id" =~ ^[0-9]+$ ]] || fail "run ID must be numeric: $id"; done
command -v jq >/dev/null || fail "jq is required"
[ -f "$policy_manifest" ] || fail "missing workflow policy manifest"
jq -e '(.schema_version == 2) and (.workflow|type=="string" and length>0) and (.lanes|type=="array" and length>0) and ([.lanes[].identity]|unique|length==length) and all(.lanes[]; (keys|sort)==["identity","initial_queue_root","match","policy","required_for_release_proof","staged_critical_chain_order"] and (.identity|type=="string" and test("^[a-z0-9-]+$")) and (.match|type=="string") and (.policy=="required" or .policy=="advisory" or .policy=="conditional") and (.required_for_release_proof|type=="boolean") and (.initial_queue_root|type=="boolean") and (.staged_critical_chain_order == null or (.staged_critical_chain_order|type=="number" and floor==. and .>0)))' "$policy_manifest" >/dev/null || fail "invalid workflow policy manifest"
policy_workflow="$(jq -r '.workflow' "$policy_manifest")"

repo="${GITHUB_REPOSITORY:-}"
if [ -z "$repo" ]; then remote="$(git -C "$root_dir" config --get remote.origin.url 2>/dev/null || true)"; repo="$(printf %s "$remote" | sed -E 's#^(git@github.com:|https://github.com/)##;s#\.git$##')"; fi
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail "could not derive owner/repo; set GITHUB_REPOSITORY"
if [ -n "$fixture_dir" ]; then [ -d "$fixture_dir" ] || fail "fixture directory does not exist: $fixture_dir"; else command -v gh >/dev/null || fail "gh is required outside fixture mode"; fi
tmp_dir="$(mktemp -d)"; trap 'rm -rf "$tmp_dir"' EXIT

classify_job() { jq -cer --arg n "$1" '[.lanes[]|select(.match as $m | $n|test($m))]|if length==1 then .[0] else error("expected exactly one matching lane") end' "$policy_manifest" || fail "unknown or ambiguous workflow job identity: $1"; }
fixture_response() { # $1 fixture stem, $2 destination, $3 expected status
  local source="$fixture_dir/$1.json" status body
  [ -f "$source" ] || fail "fixture response missing: $1.json"
  jq -e '(keys|sort)==["body","status"] and (.status|type=="number" and floor==.)' "$source" >/dev/null || fail "malformed fixture envelope: $1"
  status="$(jq -r .status "$source")"; [ "$status" = "$3" ] || fail "fixture $1 returned HTTP $status, expected $3"
  jq -e .body "$source" >"$2" || fail "malformed fixture body: $1"
}
api_get_200() { # gh preserves auth and sends only a GET.  Headers/status are isolated from JSON body.
  local endpoint="$1" destination="$2" raw="$tmp_dir/http-$RANDOM"
  if ! gh api --include -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' "$endpoint" >"$raw"; then fail "GET failed without a confirmed HTTP 200: $endpoint"; fi
  local status; status="$(awk '/^HTTP\// {s=$2} END{print s}' "$raw")"; [ "$status" = 200 ] || fail "GET returned HTTP ${status:-unknown}: $endpoint"
  awk 'BEGIN{body=0} /^\r?$/{body=1;next} body{print}' "$raw" >"$destination"
  jq -e . "$destination" >/dev/null || fail "GET returned malformed JSON: $endpoint"
}
classic_response() { # confirmed 404 is the only absence state.
  local destination="$1" raw="$tmp_dir/classic-http"
  if [ -n "$fixture_dir" ]; then
    local source="$fixture_dir/required_status_checks.json" status
    [ -f "$source" ] || fail "fixture response missing: required_status_checks.json"
    jq -e '(keys|sort)==["body","status"] and (.status|type=="number" and floor==.)' "$source" >/dev/null || fail "malformed classic fixture envelope"
    status="$(jq -r .status "$source")"
    case "$status" in 200) jq -e .body "$source" >"$destination" || fail "malformed classic 200 body";; 404) jq -e '.body == null or .body == {}' "$source" >/dev/null || fail "malformed classic 404 body"; printf '{"state":"not-found"}\n' >"$destination";; *) fail "classic required-status GET returned HTTP $status";; esac
    return
  fi
  gh api --include -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' "/repos/$repo/branches/main/protection/required_status_checks" >"$raw" || true
  local status; status="$(awk '/^HTTP\// {s=$2} END{print s}' "$raw")"
  case "$status" in
    200) awk 'BEGIN{body=0} /^\r?$/{body=1;next} body{print}' "$raw" >"$destination"; jq -e . "$destination" >/dev/null || fail "malformed classic 200 body" ;;
    404) printf '{"state":"not-found"}\n' >"$destination" ;;
    *) fail "classic required-status GET returned HTTP ${status:-unknown}" ;;
  esac
}
pages() { # $1 stem, $2 jobs|artifacts, $3 output
  local stem="$1" key="$2" destination="$3" page=1 total="" seen='[]' item_pages=() run_id="${1#*-}"
  while :; do
    local page_file="$tmp_dir/$stem-$page.json" body
    if [ -n "$fixture_dir" ]; then fixture_response "$stem-$page" "$page_file" 200; else api_get_200 "/repos/$repo/actions/runs/$run_id/$key?per_page=100&page=$page" "$page_file"; fi
    if [ -n "$fixture_dir" ]; then
      jq -e --arg k "$key" '((keys|sort)==(["next_page","total_count",$k]|sort)) and (.total_count|type=="number" and floor==. and .>=0) and (.next_page == null or (.next_page|type=="number" and floor==. and .>0)) and (.[$k]|type=="array")' "$page_file" >/dev/null || fail "malformed $key fixture page $page"
    else
      # GitHub REST list bodies expose total_count and the item array. Pagination
      # links live in response headers, so a metadata-only collector derives the
      # bounded next page from total_count instead of inventing a body field.
      jq -e --arg k "$key" '((keys|sort)==(["total_count",$k]|sort)) and (.total_count|type=="number" and floor==. and .>=0) and (.[$k]|type=="array" and length<=100)' "$page_file" >/dev/null || fail "malformed $key page $page"
    fi
    local count next; count="$(jq -r .total_count "$page_file")"
    [ -z "$total" ] && total="$count"; [ "$total" = "$count" ] || fail "contradictory $key total_count"
    item_pages+=("$page_file")
    if [ -n "$fixture_dir" ]; then next="$(jq -r .next_page "$page_file")"; else if [ $((page * 100)) -lt "$total" ]; then next=$((page + 1)); else next=null; fi; fi
    [ "$next" = null ] && break
    [ "$next" -gt "$page" ] || fail "cyclic or non-forward $key pagination"
    [ "$next" -le 1000 ] || fail "unbounded $key pagination"
    page="$next"
  done
  jq -s --arg k "$key" --argjson total "$total" '[.[].[$k][]] as $items | if ($items|map(.id)|length) != ($items|map(.id)|unique|length) then error("duplicate IDs") elif ($items|length) != $total then error("total_count mismatch") else $items end' "${item_pages[@]}" >"$destination" || fail "incomplete $key pagination"
}

build_run() {
  local id="$1" run="$tmp_dir/run-$id.json" jobs="$tmp_dir/jobs-flat-$id.json" artifacts="$tmp_dir/artifacts-flat-$id.json"
  if [ -n "$fixture_dir" ]; then fixture_response "run-$id" "$run" 200; else api_get_200 "/repos/$repo/actions/runs/$id" "$run"; fi
  jq -e '(.id|type=="number") and (.name|type=="string") and (.event|type=="string") and (.head_sha|type=="string") and (.run_attempt|type=="number") and (.created_at|type=="string") and (.updated_at|type=="string") and (.html_url|type=="string")' "$run" >/dev/null || fail "malformed run response"
  [ "$(jq -r '.name' "$run")" = "$policy_workflow" ] || fail "run workflow does not match policy workflow: $policy_workflow"
  local attempt; attempt="$(jq -r .run_attempt "$run")"; pages "jobs-$id" jobs "$jobs"; pages "artifacts-$id" artifacts "$artifacts"
  jq -e --argjson policy "$(cat "$policy_manifest")" --argjson jobs "$(cat "$jobs")" --argjson artifacts "$(cat "$artifacts")" '
    def lane($name): [$policy.lanes[]|select(.match as $m | $name|test($m))]|if length==1 then .[0] else error("unknown job") end;
    def iso: type=="string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T") and (fromdateiso8601|type=="number");
    . as $raw | {id:$raw.id,workflow:$raw.name,event:$raw.event,head_sha:$raw.head_sha,attempt:$raw.run_attempt,status:$raw.status,conclusion:$raw.conclusion,created_at:$raw.created_at,completed_at:$raw.updated_at,url:$raw.html_url} as $base |
    ($jobs|map(. as $j | lane($j.name) as $l | {id:$j.id,name:$j.name,status:$j.status,conclusion:$j.conclusion,started_at:$j.started_at,completed_at:$j.completed_at,steps:(($j.steps // [])|map({name,conclusion,started_at,completed_at,duration_seconds:(if (.started_at != null and .completed_at != null) then ((.completed_at|fromdateiso8601)-(.started_at|fromdateiso8601)) else null end)})),manifest_identity:$l.identity,policy:$l.policy,required_for_release_proof:$l.required_for_release_proof,initial_queue_root:$l.initial_queue_root,staged_critical_chain_order:$l.staged_critical_chain_order,duration_seconds:(if (.started_at != null and .completed_at != null) then ((.completed_at|fromdateiso8601)-(.started_at|fromdateiso8601)) else null end),cache_state:(if any(($j.steps // [])[]?; .name=="Create accrue PLTs" and .conclusion=="skipped") then "inferred-setup-bypass" elif any(($j.steps // [])[]?; .name=="Create accrue PLTs" and .conclusion=="success") then "observed-miss" else "unknown" end)})) as $classified |
    ($base.event=="workflow_dispatch" and $base.attempt==1 and $base.status=="completed" and $base.conclusion=="success") as $base_eligible |
    ($classified|map(if .conclusion=="skipped" then .+{proof_state:"skipped"} elif .policy=="advisory" then .+{proof_state:"advisory"} elif .policy=="conditional" then .+{proof_state:"not-applicable"} elif ($base_eligible and .required_for_release_proof and .conclusion=="success") then .+{proof_state:"proved"} else .+{proof_state:"not-applicable"} end)) as $classified |
    ([$classified[]|select(.initial_queue_root)|.started_at] | if length>0 and all(.!=null) then map(fromdateiso8601)|min-($base.created_at|fromdateiso8601) else null end) as $queue |
    ([$classified[]|select(.staged_critical_chain_order!=null)]|sort_by(.staged_critical_chain_order)) as $chain |
    (if ($chain|length)>0 and all($chain[]; .started_at!=null and .completed_at!=null) then (($chain|map(.started_at|fromdateiso8601)|min) as $s | ($chain|map(.completed_at|fromdateiso8601)|max) - $s) else null end) as $chain_seconds |
    ([$classified[]|select(.conclusion=="failure" or .conclusion=="timed_out" or .conclusion=="cancelled")|{manifest_identity,conclusion}]|unique|sort_by(.manifest_identity,.conclusion)) as $pairs |
    (if ($pairs|length)==0 then "no-failure" else "failed-lane" end) as $category |
    {run:($base+{wall_seconds:(($base.completed_at|fromdateiso8601)-($base.created_at|fromdateiso8601)),eligible:($base_eligible and $queue!=null and $chain_seconds!=null),exclusion_reason:(if $base_eligible and $queue!=null and $chain_seconds!=null then null elif $base_eligible then "required timing is provider-omitted" else "event, attempt, status, or conclusion is not eligible" end),runner_queue_seconds:$queue,runner_queue_omission_reason:(if $queue==null then "provider-omitted-initial-root-started-at" else null end),staged_critical_chain_seconds:$chain_seconds,staged_critical_chain_omission_reason:(if $chain_seconds==null then "provider-omitted-staged-chain-timestamp" else null end)}),jobs:$classified,artifacts:($artifacts|map({id,name,size_in_bytes,expires_at,expired})),root_failure_signature:{id:("ci-root-v2-"+(([$category,$pairs]|tojson|@base64)|gsub("=";""))),category:$category,affected_jobs:($pairs|map(.manifest_identity)|unique|sort),lane_conclusions:$pairs}}' "$run" >"$tmp_dir/record-$id.json" || fail "failed to reduce run $id"
}
for id in "${run_ids[@]}"; do build_run "$id"; done
rules="$tmp_dir/rules.json"; classic="$tmp_dir/classic.json"
if [ -n "$fixture_dir" ]; then fixture_response rules "$rules" 200; else api_get_200 "/repos/$repo/rules/branches/main" "$rules"; fi
classic_response "$classic"
jq -e 'if type=="array" then {rules_response_state:"ok",rules:[.[].rules[]?|select(.type=="required_status_checks")|.parameters.required_status_checks[]?|{context:.context,app_id:.integration_id}]} else error("effective rules body must be an array") end' "$rules" >"$tmp_dir/rules-allowed.json" || fail "malformed effective rules response"
jq -e 'if .state=="not-found" then {classic_response_state:"not-found",classic_checks:[]} elif ((keys|sort)==["checks","contexts","strict"]) then {classic_response_state:"ok",classic_checks:([.contexts[]?|{context:.,app_id:null}]+[.checks[]?|{context:.context,app_id:.app_id}])} else error("malformed classic 200 response") end' "$classic" >"$tmp_dir/classic-allowed.json" || fail "malformed classic response"
jq -s --arg repo "$repo" --argjson policy "$(cat "$policy_manifest")" --argjson rules "$(cat "$tmp_dir/rules-allowed.json")" --argjson classic "$(cat "$tmp_dir/classic-allowed.json")" '{schema_version:2,document_type:"ci-baseline-collector-record",repository:$repo,policy_manifest:{schema_version:$policy.schema_version,workflow:$policy.workflow},privacy:{logs_downloaded:false,artifact_archives_downloaded:false,env_values_recorded:false,raw_payloads_recorded:false,allowlist:["run identity and timestamps","job and step metadata","cache state","artifact name/size/expiry","required-check context/app ID"]},required_check_snapshot:($rules+$classic+{captured_at:(now|strftime("%Y-%m-%dT%H:%M:%SZ")),enforcement_state:(if ($rules.rules|length)==0 and ($classic.classic_checks|length)==0 and $classic.classic_response_state=="not-found" then "none-enforced" else "enforced" end)}),runs:.}' "$tmp_dir"/record-*.json >"$tmp_dir/output.json"
jq -e . "$tmp_dir/output.json" >/dev/null; [ -d "$(dirname "$output")" ] || fail "output directory does not exist"; mv "$tmp_dir/output.json" "$output"
