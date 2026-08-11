#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
canonical_input="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"
policy_manifest="$root_dir/scripts/ci/ci_baseline_workflow_policy.json"
ci_file="$root_dir/.github/workflows/ci.yml"
ownership_file="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md"
expected_ids='[31322443304,31332551817,31344524124]'
required_lockfiles='["accrue/mix.lock","accrue_admin/mix.lock","accrue_admin/package-lock.json","examples/accrue_host/mix.lock","examples/accrue_host/package-lock.json","examples/accrue_host/assets/package-lock.json"]'

fail() { echo "verify_ci_baseline_contract: $*" >&2; exit 1; }
input="$canonical_input"; self_test=false; self_test_collector=false
case "${1:-}" in
  --self-test) [ "$#" -eq 1 ] || fail "--self-test accepts no other arguments"; self_test=true ;;
  --self-test-collector) [ "$#" -eq 1 ] || fail "--self-test-collector accepts no other arguments"; self_test_collector=true ;;
  --input) [ "$#" -eq 2 ] || fail "--input requires a path"; input="$2" ;;
  "") ;;
  *) fail "usage: $0 [--input PATH|--self-test|--self-test-collector]" ;;
esac
[ -x "$root_dir/scripts/ci/capture_ci_baseline.sh" ] || fail "missing executable collector"

require_source_fixed() { printf '%s\n' "$2" | grep -Fq "$3" || fail "missing '$3' in $1"; }
job_body() { awk -v job_id="$1" '$0 == "  " job_id ":" {in_job=1} in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" {exit} in_job {print}' "$ci_file"; }

validate_policy_manifest() {
  jq -e '.schema_version == 3 and (.workflow | type == "string" and length > 0) and (.lanes | type == "array" and length > 0) and (.workflow_topology | type == "array" and length > 0) and all(.lanes[]; (keys|sort) == ["identity","initial_queue_root","match","policy","required_for_release_proof","staged_critical_chain_order"] and (.identity | type == "string" and test("^[a-z0-9-]+$")) and (.match | type == "string" and length > 0) and (.policy == "required" or .policy == "advisory" or .policy == "conditional") and (.required_for_release_proof | type == "boolean") and (.initial_queue_root | type == "boolean") and (.staged_critical_chain_order == null or (.staged_critical_chain_order | type == "number" and floor == . and . > 0))) and all(.workflow_topology[]; (keys|sort)==["condition","display_names","expected_instances","job_id","lane_identities","matrix_role","name"] and (.job_id|type=="string") and (.name|type=="string") and (.condition|type=="string") and (.display_names|type=="array" and length>0) and (.expected_instances|type=="number" and floor==. and .>0) and (.lane_identities|type=="array" and length>0)) and ([.lanes[].identity] | unique | length == length) and ([.workflow_topology[].job_id] | unique | length == length) and (([.workflow_topology[].lane_identities[]] | sort) == ([.lanes[].identity] | sort))' "$policy_manifest" >/dev/null || fail "invalid workflow policy manifest"
  jq -n --slurpfile policy "$policy_manifest" --slurpfile baseline "$canonical_input" 'all($baseline[0].runs[].jobs[]; . as $job | ([ $policy[0].lanes[] | .match as $match | select($job.name | test($match)) ] | length) == 1)' >/dev/null || fail "policy manifest does not classify canonical job identities exactly once"
}

validate_aggregates() {
  local candidate="$1"
  jq -e --argjson expected_ids "$expected_ids" --slurpfile policy "$policy_manifest" '
    ([.runs[] | select(.run.eligible == true)]) as $eligible |
    ($policy[0].lanes | map(select(.required_for_release_proof)) | map(.identity) | sort) as $required |
    ($eligible | map(.run.runner_queue_seconds) | sort) as $queues |
    ($eligible | map(.run.staged_critical_chain_seconds) | sort) as $chains |
    ($eligible | map(.run.wall_seconds) | sort) as $walls |
    (.aggregates.runner_queue_seconds == {per_run: ($eligible | map({run_id: .run.id, seconds: .run.runner_queue_seconds})), minimum: $queues[0], median: $queues[($queues|length)/2], maximum: $queues[-1]}) and
    (.aggregates.staged_critical_chain_seconds == {per_run: ($eligible | map({run_id: .run.id, seconds: .run.staged_critical_chain_seconds})), minimum: $chains[0], median: $chains[($chains|length)/2], maximum: $chains[-1]}) and
    (.aggregates.wall_seconds == {per_run: ($eligible | map({run_id: .run.id, seconds: .run.wall_seconds})), minimum: $walls[0], median: $walls[($walls|length)/2], maximum: $walls[-1]}) and
    (.aggregates.proof.eligible_run_ids == $expected_ids) and
    (.aggregates.proof.required_lane_identities == $required) and
    (.aggregates.proof.per_run == ($eligible | map({run_id: .run.id, required_proved_lane_identities: ([.jobs[] | select(.proof_state == "proved" and .required_for_release_proof == true) | .manifest_identity] | unique | sort), required_proved_count: ([.jobs[] | select(.proof_state == "proved" and .required_for_release_proof == true) | .manifest_identity] | unique | length)}))) and
    (.aggregates.proof.all_required_lanes_proved == ([$eligible[] | ([.jobs[] | select(.proof_state == "proved" and .required_for_release_proof == true) | .manifest_identity] | unique | sort) == $required] | all))
  ' "$candidate" >/dev/null || fail "derived timing or required-proof aggregate mismatch"
}

reject_sensitive_strings() {
  local candidate="$1"
  if jq -e '.. | strings | select(test("(ghp_|github_pat_|sk_(live|test)_|bearer[[:space:]]+[A-Za-z0-9._-]+|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|raw( (request|response|event))? payload)"; "i"))' "$candidate" >/dev/null; then
    fail "privacy contract rejected secret-like or raw payload content"
  fi
  if jq -e '.. | strings | select(test("https?://[^[:space:]]+\\?"))' "$candidate" >/dev/null; then
    fail "privacy contract rejected query-bearing URL"
  fi
}

# Candidate documents are untrusted assertions.  Re-derive each job's policy-owned
# tuple from the versioned manifest before trusting signatures or aggregates.
candidate_job_semantics() {
  local candidate="$1"
  jq -e --slurpfile policy "$policy_manifest" '
    def expected_proof($eligible; $lane; $conclusion):
      if $conclusion == "skipped" then "skipped"
      elif $lane.policy == "advisory" then "advisory"
      elif $lane.policy == "conditional" then "not-applicable"
      elif ($eligible and $lane.required_for_release_proof and $conclusion == "success") then "proved"
      else "not-applicable"
      end;
    all(.runs[];
      .run.eligible as $eligible |
      all(.jobs[];
        . as $job |
        [$policy[0].lanes[] | select(.match as $match | ($job.name | test($match)))] as $matches |
        ($matches | length == 1) and
        ($matches[0] as $lane |
          ($job.manifest_identity == $lane.identity) and
          ($job.policy == $lane.policy) and
          ($job.required_for_release_proof == $lane.required_for_release_proof) and
          ($job.initial_queue_root == $lane.initial_queue_root) and
          ($job.staged_critical_chain_order == $lane.staged_critical_chain_order) and
          ($job.proof_state == expected_proof($eligible; $lane; $job.conclusion))
        )
      )
    )
  ' "$candidate" >/dev/null || fail "candidate job policy or proof semantics failed: ${candidate#$root_dir/}"
}

# A candidate may not substitute its own workflow label or satisfy release proof
# with a subset of policy-required lanes.  These predicates are shared by both
# public document formats so their safety boundary cannot drift.
candidate_workflow_semantics() {
  local candidate="$1"
  jq -e --slurpfile policy "$policy_manifest" '
    (.policy_manifest.workflow == $policy[0].workflow) and
    all(.runs[]; .run.workflow == $policy[0].workflow)
  ' "$candidate" >/dev/null || fail "candidate workflow does not match checked-in policy: ${candidate#$root_dir/}"
}

candidate_required_proof_completeness() {
  local candidate="$1"
  jq -e --slurpfile policy "$policy_manifest" '
    ($policy[0].lanes | map(select(.required_for_release_proof) | .identity) | unique | sort) as $required |
    all(.runs[];
      if .run.eligible then
        ([.jobs[] | select(.required_for_release_proof) | .manifest_identity] | unique | sort) == $required and
        ([.jobs[] | select(.required_for_release_proof and .proof_state == "proved") | .manifest_identity] | unique | sort) == $required
      else
        ([.jobs[] | select(.proof_state == "proved")] | length) == 0
      end
    )
  ' "$candidate" >/dev/null || fail "candidate required release proof is incomplete: ${candidate#$root_dir/}"
}

# This runs only after candidate_job_semantics has bound every job's chain role
# to the checked-in policy.  Timing is then independently recovered from the
# durable job timestamps, never from a candidate aggregate or job duration.
candidate_derived_run_semantics() {
  local candidate="$1"
  jq -e '
    def failure_pairs:
      [.jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | {manifest_identity, conclusion}] | unique | sort_by(.manifest_identity, .conclusion);
    def chain_seconds:
      [.jobs[] | select(.staged_critical_chain_order != null)] as $chain |
      if ($chain | length) > 0 and all($chain[]; .started_at != null and .completed_at != null)
      then (($chain | map(.started_at | fromdateiso8601) | min) as $start |
            ($chain | map(.completed_at | fromdateiso8601) | max) - $start)
      else null
      end;
    all(.runs[]; . as $record |
      (chain_seconds) as $chain |
      (failure_pairs) as $pairs |
      (if ($pairs | length) == 0 then "no-failure" else "failed-lane" end) as $category |
      (($chain == null) == ($record.run.staged_critical_chain_seconds == null)) and
      (if $chain == null
       then $record.run.staged_critical_chain_omission_reason == "provider-omitted-staged-chain-timestamp"
       else $record.run.staged_critical_chain_omission_reason == null
       end) and
      (if $record.run.eligible
       then $chain != null and $record.run.staged_critical_chain_seconds == $chain
       else ([.jobs[] | select(.proof_state == "proved")] | length) == 0
       end) and
      ($record.root_failure_signature.lane_conclusions == $pairs) and
      ($record.root_failure_signature.affected_jobs == ($pairs | map(.manifest_identity) | unique | sort)) and
      ($record.root_failure_signature.category == $category) and
      ($record.root_failure_signature.id == ("ci-root-v2-" + (([$category, $pairs] | tojson | @base64) | gsub("="; ""))))
    )
  ' "$candidate" >/dev/null || fail "candidate staged critical-chain timing failed: ${candidate#$root_dir/}"
}

validate_collector_record() {
  local candidate="$1"
  jq -e --slurpfile policy "$policy_manifest" '
    def exact($x): (keys|sort)==$x; def iso: type=="string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T.*Z$"); def num: type=="number" and isfinite and .>=0;
    def step: exact(["completed_at","conclusion","duration_seconds","name","started_at"]) and (.name|type=="string") and (.conclusion|type=="string" or .==null) and (.started_at|iso or .==null) and (.completed_at|iso or .==null) and (.duration_seconds|num or .==null);
    def job: exact(["cache_state","completed_at","conclusion","duration_seconds","id","initial_queue_root","manifest_identity","name","policy","proof_state","required_for_release_proof","staged_critical_chain_order","started_at","status","steps"]) and (.id|type=="number" and floor==.) and (.name|type=="string") and (.status|type=="string") and (.conclusion|type=="string" or .==null) and (.started_at|iso or .==null) and (.completed_at|iso or .==null) and (.duration_seconds|num or .==null) and (.steps|type=="array" and all(.[];step)) and (.policy=="required" or .=="advisory" or .=="conditional") and (.required_for_release_proof|type=="boolean") and (.initial_queue_root|type=="boolean") and (.staged_critical_chain_order==null or (.staged_critical_chain_order|type=="number" and floor==. and .>0)) and (.proof_state=="proved" or .=="skipped" or .=="advisory" or .=="not-applicable") and (.cache_state=="observed-hit" or .=="observed-miss" or .=="inferred-setup-bypass" or .=="unknown");
    def artifact: exact(["expired","expires_at","id","name","size_in_bytes"]) and (.id|type=="number" and floor==.) and (.name|type=="string") and (.size_in_bytes|num) and (.expires_at|iso or .==null) and (.expired|type=="boolean");
    def run: exact(["attempt","completed_at","conclusion","created_at","eligible","event","exclusion_reason","head_branch","head_sha","id","ref","runner_queue_omission_reason","runner_queue_seconds","staged_critical_chain_omission_reason","staged_critical_chain_seconds","status","url","wall_seconds","workflow"]) and (.id|type=="number" and floor==.) and (.workflow|type=="string") and (.event|type=="string") and (.head_branch|type=="string" and length>0) and (.ref|type=="string") and (.head_sha|type=="string" and test("^[0-9a-f]{40}$")) and (.attempt|type=="number" and floor==. and .>0) and (.status|type=="string") and (.conclusion|type=="string" or .==null) and (.created_at|iso) and (.completed_at|iso) and (.url | (type=="string" and test("^https://") and (contains("?")|not))) and (.wall_seconds|num) and (.eligible|type=="boolean") and (.exclusion_reason|type=="string" or .==null) and (.runner_queue_seconds|num or .==null) and (.runner_queue_omission_reason==null or .=="provider-omitted-initial-root-started-at") and (.staged_critical_chain_seconds|num or .==null) and (.staged_critical_chain_omission_reason==null or .=="provider-omitted-staged-chain-timestamp");
    def sig: exact(["affected_jobs","category","id","lane_conclusions"]) and (.id|type=="string" and test("^ci-root-v2-[A-Za-z0-9_-]+$")) and (.category=="no-failure" or .=="failed-lane") and (.affected_jobs|type=="array" and .==sort and .==unique) and (.lane_conclusions|type=="array" and .==sort_by(.manifest_identity,.conclusion) and .==unique and all(.[]; exact(["conclusion","manifest_identity"]) and (.manifest_identity|type=="string") and (.conclusion=="failure" or .=="timed_out" or .=="cancelled")));
    exact(["document_type","policy_manifest","privacy","repository","required_check_snapshot","runs","schema_version"]) and .schema_version==2 and .document_type=="ci-baseline-collector-record" and (.repository|type=="string" and test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) and (.policy_manifest|exact(["schema_version","workflow"]) and .schema_version==$policy[0].schema_version and .workflow==$policy[0].workflow) and (.privacy|exact(["allowlist","artifact_archives_downloaded","env_values_recorded","logs_downloaded","raw_payloads_recorded"]) and .logs_downloaded==false and .artifact_archives_downloaded==false and .env_values_recorded==false and .raw_payloads_recorded==false) and (.required_check_snapshot|exact(["captured_at","classic_checks","classic_response_state","enforcement_state","rules","rules_response_state"])) and (.runs|type=="array" and length>0 and all(.[]; (.run|run) and (.jobs|type=="array" and length>0) and (.artifacts|type=="array") and (.root_failure_signature|sig)))
  ' "$candidate" >/dev/null || fail "collector record schema failed: ${candidate#$root_dir/}"
  candidate_job_semantics "$candidate"
  candidate_workflow_semantics "$candidate"
  candidate_required_proof_completeness "$candidate"
  candidate_derived_run_semantics "$candidate"
  jq -e 'all(.runs[]; if .run.eligible then (.run.head_branch == "main" and .run.ref == "refs/heads/main" and .run.exclusion_reason == null) else (.run.ref == ("refs/heads/" + .run.head_branch) and ([.jobs[] | select(.proof_state == "proved")] | length) == 0 and (.run.exclusion_reason | type == "string" and length > 0)) end)' "$candidate" >/dev/null || fail "collector branch/ref proof scope failed: ${candidate#$root_dir/}"
  jq -e '
    def pairs: ([.jobs[]|select(.conclusion=="failure" or .conclusion=="timed_out" or .conclusion=="cancelled")|{manifest_identity,conclusion}]|unique|sort_by(.manifest_identity,.conclusion));
    all(.runs[]; . as $record |
      ([.jobs[]|select(.initial_queue_root)|.started_at] | if length>0 and all(.!=null) then map(fromdateiso8601)|min-($record.run.created_at|fromdateiso8601) else null end) as $queue |
      (if $record.run.eligible then ($queue != null and $record.run.runner_queue_seconds == $queue and ([.jobs[]|select(.staged_critical_chain_order!=null)]|length)>0 and $record.run.staged_critical_chain_seconds != null) else ([.jobs[]|select(.proof_state=="proved")]|length)==0 end) and
      (pairs) as $pairs | $record.root_failure_signature.lane_conclusions==$pairs and $record.root_failure_signature.affected_jobs==($pairs|map(.manifest_identity)|unique|sort) and $record.root_failure_signature.id == ("ci-root-v2-"+(([$record.root_failure_signature.category,$pairs]|tojson|@base64)|gsub("=";"")))
    )
  ' "$candidate" >/dev/null || fail "collector derived facts failed: ${candidate#$root_dir/}"
  reject_sensitive_strings "$candidate"
}

validate_canonical_cohort() {
  jq -e --argjson expected_ids "$expected_ids" --slurpfile canonical_reference "$canonical_input" '
    def exact($x): (keys | sort) == $x;
    def iso: type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T.*Z$");
    def num: type == "number" and isfinite and . >= 0;
    def integer: num and floor == .;
    def sha40: type == "string" and test("^[0-9a-f]{40}$");
    def string_array: type == "array" and all(.[]; type == "string");
    def lockfile_map: exact(["accrue/mix.lock","accrue_admin/mix.lock","accrue_admin/package-lock.json","examples/accrue_host/assets/package-lock.json","examples/accrue_host/mix.lock","examples/accrue_host/package-lock.json"]) and all(.[]; sha40);
    def step: exact(["completed_at","conclusion","duration_seconds","name","started_at"]) and (.name|type == "string") and (.conclusion|type == "string" or . == null) and (.started_at|iso or . == null) and (.completed_at|iso or . == null) and (.duration_seconds|num or . == null);
    def job: exact(["cache_state","completed_at","conclusion","duration_seconds","id","initial_queue_root","manifest_identity","name","policy","proof_state","required_for_release_proof","staged_critical_chain_order","started_at","status","steps"]) and (.id|integer) and (.name|type == "string") and (.status|type == "string") and (.conclusion|type == "string" or . == null) and (.started_at|iso or . == null) and (.completed_at|iso or . == null) and (.duration_seconds|num or . == null) and (.steps|type == "array" and all(.[]; step)) and (.manifest_identity|type == "string") and (.policy == "required" or . == "advisory" or . == "conditional") and (.required_for_release_proof|type == "boolean") and (.initial_queue_root|type == "boolean") and (.staged_critical_chain_order == null or (.staged_critical_chain_order|integer and . > 0)) and (.proof_state == "proved" or . == "skipped" or . == "advisory" or . == "not-applicable") and (.cache_state == "observed-hit" or . == "observed-miss" or . == "inferred-setup-bypass" or . == "unknown");
    def artifact: exact(["expired","expires_at","id","name","size_in_bytes"]) and (.id|integer) and (.name|type == "string") and (.size_in_bytes|num) and (.expires_at|iso or . == null) and (.expired|type == "boolean");
    def lane_conclusion: exact(["conclusion","manifest_identity"]) and (.manifest_identity|type == "string") and (.conclusion == "failure" or . == "timed_out" or . == "cancelled");
    def signature: exact(["affected_jobs","category","id","lane_conclusions"]) and (.id|type == "string" and test("^ci-root-v2-")) and (.category == "no-failure" or . == "failed-lane") and (.affected_jobs|string_array) and (.lane_conclusions|type == "array" and all(.[]; lane_conclusion));
    def run: exact(["attempt","completed_at","conclusion","created_at","eligible","event","exclusion_reason","head_sha","id","runner_queue_omission_reason","runner_queue_seconds","staged_critical_chain_omission_reason","staged_critical_chain_seconds","status","url","wall_seconds","workflow"]) and (.id|integer) and (.workflow|type == "string") and (.event|type == "string") and (.head_sha|sha40) and (.attempt|integer and . > 0) and (.status|type == "string") and (.conclusion|type == "string" or . == null) and (.created_at|iso) and (.completed_at|iso) and (.url|type == "string" and test("^https://")) and (.wall_seconds|num) and (.eligible|type == "boolean") and (.exclusion_reason|type == "string" or . == null) and (.runner_queue_seconds|num or . == null) and (.runner_queue_omission_reason == null or . == "provider-omitted-initial-root-started-at") and (.staged_critical_chain_seconds|num or . == null) and (.staged_critical_chain_omission_reason == null or . == "provider-omitted-staged-chain-timestamp");
    def run_record: exact(["artifacts","jobs","root_failure_signature","run"]) and (.run|run) and (.jobs|type == "array" and all(.[]; job)) and (.artifacts|type == "array" and all(.[]; artifact)) and (.root_failure_signature|signature);
    def anchor: exact(["lockfile_blob_oids","runner_image_family","sha","stable_job_ids","workflow_blob_oid"]) and (.sha|sha40) and (.workflow_blob_oid|sha40) and (.lockfile_blob_oids|lockfile_map) and (.runner_image_family|type == "string") and (.stable_job_ids|string_array);
    def cohort_anchor: exact(["lockfile_blob_oids","ref","remote_sha","runner_image_family","sha","stable_job_ids","workflow_blob_oid"]) and (.sha|sha40) and (.workflow_blob_oid|sha40) and (.lockfile_blob_oids|lockfile_map) and (.runner_image_family|type == "string") and (.stable_job_ids|string_array) and (.ref|type == "string") and (.remote_sha|sha40);
    def remote_snapshot: exact(["branch","lockfile_blob_oids","ref","remote_sha","sha","workflow_blob_oid"]) and (.sha|sha40) and (.remote_sha|sha40) and (.branch|type == "string") and (.ref|type == "string") and (.workflow_blob_oid|sha40) and (.lockfile_blob_oids|lockfile_map);
    def metric_row: exact(["run_id","seconds"]) and (.run_id|integer) and (.seconds|num);
    def metric: exact(["maximum","median","minimum","per_run"]) and (.per_run|type == "array" and all(.[]; metric_row)) and (.minimum|num) and (.median|num) and (.maximum|num);
    def proof_row: exact(["required_proved_count","required_proved_lane_identities","run_id"]) and (.run_id|integer) and (.required_proved_count|integer) and (.required_proved_lane_identities|string_array);
    def proof: exact(["advisory_not_proof","all_required_lanes_proved","eligible_run_ids","not_applicable_not_proof","per_run","required_lane_identities","skipped_not_proof"]) and (.eligible_run_ids|type == "array" and all(.[]; integer)) and (.required_lane_identities|string_array) and (.per_run|type == "array" and all(.[]; proof_row)) and (.all_required_lanes_proved|type == "boolean") and (.advisory_not_proof|type == "boolean") and (.skipped_not_proof|type == "boolean") and (.not_applicable_not_proof|type == "boolean");
    def selection_candidate: exact(["affected_critical_path_stage","baseline_median_or_range","candidate","eligible_run_ids","json_paths","rank"]) and (.rank|integer and . > 0) and (.candidate|type == "string") and (.eligible_run_ids|type == "array" and all(.[]; integer)) and (.json_paths|string_array) and (.affected_critical_path_stage|type == "string") and (.baseline_median_or_range|type == "string");
    def canonical: exact(["aggregates","anchor","cohort","document_type","phase_227_selection_gate","policy_manifest","privacy","repository","required_check_snapshot","runs","schema_version"]) and .schema_version == 2 and .document_type == "ci-baseline-canonical" and (.repository|type == "string" and test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) and (.policy_manifest|exact(["schema_version","workflow"]) and (.schema_version|integer) and (.workflow|type == "string")) and (.privacy|exact(["allowlist","artifact_archives_downloaded","env_values_recorded","logs_downloaded","raw_payloads_recorded"]) and (.allowlist|string_array) and (.artifact_archives_downloaded|type == "boolean") and (.env_values_recorded|type == "boolean") and (.logs_downloaded|type == "boolean") and (.raw_payloads_recorded|type == "boolean")) and (.required_check_snapshot|exact(["captured_at","classic_checks","classic_response_state","enforcement_state","rules","rules_response_state"]) and (.captured_at|iso) and (.rules|type == "array" and length == 0) and (.classic_checks|type == "array" and length == 0) and (.rules_response_state == "ok") and (.classic_response_state == "not-found") and (.enforcement_state == "none-enforced")) and (.anchor|anchor) and (.cohort|exact(["anchor","eligible_count","eligible_run_ids","exclusions","remote_snapshot"]) and (.eligible_count|integer) and (.eligible_run_ids|type == "array" and all(.[]; integer)) and (.exclusions|type == "array" and length == 0) and (.anchor|cohort_anchor) and (.remote_snapshot|remote_snapshot)) and (.runs|type == "array" and all(.[]; run_record)) and (.aggregates|exact(["proof","reruns","runner_queue_seconds","staged_critical_chain_seconds","wall_seconds"]) and (.runner_queue_seconds|metric) and (.staged_critical_chain_seconds|metric) and (.wall_seconds|metric) and (.proof|proof) and (.reruns|type == "string")) and (.phase_227_selection_gate|exact(["candidates","required_evidence_fields","rule"]) and (.required_evidence_fields|string_array) and (.rule|type == "string") and (.candidates|type == "array" and all(.[]; selection_candidate)));
    # The canonical cohort is a fixed, versioned durable document.  Matching its
    # recursive type/key tree closes every object and array boundary, including
    # intentionally empty arrays (which therefore cannot admit an element).
    def type_tree: if type == "object" then with_entries(.value |= type_tree) elif type == "array" then map(type_tree) else type end;
    def canonical: (type_tree == ($canonical_reference[0] | type_tree));
    canonical and
    (.required_check_snapshot.captured_at | iso) and
    (.anchor.sha | sha40) and (.anchor.workflow_blob_oid | sha40) and
    all(.runs[];
      (.run.id | integer) and (.run.head_sha | sha40) and (.run.created_at | iso) and (.run.completed_at | iso) and (.run.url | test("^https://") and (contains("?") | not)) and
      all(.jobs[]; (.id | integer) and (.started_at | iso or . == null) and (.completed_at | iso or . == null) and (.duration_seconds | num or . == null) and all(.steps[]; (.started_at | iso or . == null) and (.completed_at | iso or . == null) and (.duration_seconds | num or . == null))) and
      all(.artifacts[]; (.id | integer) and (.size_in_bytes | num) and (.expires_at | iso or . == null))
    ) and
    (.runs|type=="array") and ([.runs[]|select(.run.eligible==true)|.run.id] == $expected_ids) and
    (.cohort.eligible_count==3) and
    (.cohort.anchor.workflow_blob_oid == "0d01e6da639f2e1d5967e3cbb4a489510e34d29e") and
    ((.cohort.anchor.lockfile_blob_oids|keys|sort) == ["accrue/mix.lock","accrue_admin/mix.lock","accrue_admin/package-lock.json","examples/accrue_host/assets/package-lock.json","examples/accrue_host/mix.lock","examples/accrue_host/package-lock.json"]) and
    (.aggregates|type=="object") and (.phase_227_selection_gate|type=="object") and
    (.required_check_snapshot.rules_response_state == "ok") and
    (.required_check_snapshot.classic_response_state == "not-found") and
    (.required_check_snapshot.enforcement_state == "none-enforced") and
    (.required_check_snapshot.captured_at|type=="string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T")) and
    all(.runs[]; (.run.runner_queue_seconds|type=="number" and .>=0) and (.run.staged_critical_chain_seconds|type=="number" and .>0) and (.root_failure_signature.id|test("^ci-root-v2-")))
  ' "$1" >/dev/null || fail "canonical cohort contract failed: ${1#$root_dir/}"
  candidate_job_semantics "$1"
  candidate_workflow_semantics "$1"
  candidate_required_proof_completeness "$1"
  candidate_derived_run_semantics "$1"
  reject_sensitive_strings "$1"
  validate_aggregates "$1"
}
validate_input() { local candidate="$1"; [ -f "$candidate" ] || fail "missing baseline input: ${candidate#$root_dir/}"; validate_policy_manifest; case "$(jq -r '.document_type // "canonical-v1"' "$candidate")" in ci-baseline-collector-record) validate_collector_record "$candidate";; ci-baseline-canonical) validate_canonical_cohort "$candidate";; *) fail "unknown document discriminator";; esac; }

run_collector_self_test() {
  local tmp fixture names
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
  fixture="$tmp/fixture"; mkdir "$fixture"
  names='["Docs and bash contracts (shift-left)","iOS offline client package compatibility","Release manifest SSOT (REL-02)","Release gate (Floor; elixir=1.19.0 otp=28.0 sigra=off opentelemetry=off)","Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=off opentelemetry=off)","Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=on opentelemetry=off) [advisory]","Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=off opentelemetry=on)","Phase 18 Stripe Tax gate","Admin drift and docs","Admin group contracts (Phase 190)","Admin hardening guardrails (Phase 192)","Admin Phase 200 deterministic guardrails","Admin UI ratchet guardrails","Host integration (required deterministic gate)","Playwright E2E shard 1/3","Playwright E2E shard 2/3","Playwright E2E shard 3/3","Host Docker boot smoke","Annotation sweep","Stripe test-mode parity (mandatory periodic)"]'
  jq -n '{status:200,body:{id:1,name:"CI",event:"workflow_dispatch",head_branch:"main",head_sha:"1111111111111111111111111111111111111111",run_attempt:1,status:"completed",conclusion:"success",created_at:"2026-08-09T15:56:11Z",updated_at:"2026-08-09T15:56:21Z",html_url:"https://github.com/szTheory/accrue/actions/runs/1"}}' >"$fixture/run-1.json"
  jq -n --argjson names "$names" '{status:200,body:{total_count:($names|length),next_page:null,jobs:[$names | to_entries[] | {id:(100 + .key),name:.value,status:"completed",conclusion:"success",started_at:"2026-08-09T15:56:12Z",completed_at:"2026-08-09T15:56:20Z",steps:[]}]}}' >"$fixture/jobs-1-1.json"
  jq -n '{status:200,body:{total_count:0,next_page:null,artifacts:[]}}' >"$fixture/artifacts-1-1.json"
  jq -n '{status:200,body:[]}' >"$fixture/rules.json"
  jq -n '{status:404,body:null}' >"$fixture/required_status_checks.json"
  bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture" --output "$tmp/main.json"
  validate_input "$tmp/main.json"
  jq '.body.head_branch = "feature/proof-scope"' "$fixture/run-1.json" >"$tmp/feature-run.json" && mv "$tmp/feature-run.json" "$fixture/run-1.json"
  bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture" --output "$tmp/feature.json"
  validate_input "$tmp/feature.json"
  jq '(.runs[0].run.eligible = true) | (.runs[0].jobs[0].proof_state = "proved")' "$tmp/feature.json" >"$tmp/forged.json"
  if bash "$root_dir/scripts/ci/verify_ci_baseline_contract.sh" --input "$tmp/forged.json" >/dev/null 2>&1; then fail "feature-branch proof mutation unexpectedly passed"; fi
  echo "verify_ci_baseline_contract: collector self-test ok"
}

validate_workflow_topology() {
  local expected_ids actual_ids row job_id expected_name expected_condition body actual_name actual_condition role
  expected_ids="$(jq -r '[.workflow_topology[].job_id] | sort | join(" ")' "$policy_manifest")"
  actual_ids="$(awk 'BEGIN { jobs=0 } /^jobs:$/ { jobs=1; next } jobs && /^  [A-Za-z0-9_-]+:$/ { sub(/^  /, ""); sub(/:$/, ""); print }' "$ci_file" | sort | tr '\n' ' ' | sed 's/ $//')"
  [ "$actual_ids" = "$expected_ids" ] || fail "workflow job topology does not match policy"
  while IFS= read -r row; do
    job_id="$(jq -r '.job_id' <<<"$row")"; expected_name="$(jq -r '.name' <<<"$row")"; expected_condition="$(jq -r '.condition' <<<"$row")"; role="$(jq -r '.matrix_role' <<<"$row")"
    body="$(job_body "$job_id")"; [ -n "$body" ] || fail "missing topology job: $job_id"
    actual_name="$(awk -F'name: ' '/^    name: / {print $2; exit}' <<<"$body")"
    actual_condition="$(awk -F'if: ' '/^    if: / {print $2; exit}' <<<"$body")"
    [ "$actual_name" = "$expected_name" ] || fail "workflow job name drift: $job_id"
    [ "$actual_condition" = "$expected_condition" ] || fail "workflow job condition drift: $job_id"
    case "$role" in
      scalar|conditional) ;;
      release-support)
        [ "$(grep -Fc "support: 'required'" <<<"$body" || true)" -eq 3 ] || fail "release support topology drift"
        grep -Fq "support: 'advisory'" <<<"$body" || fail "release advisory topology drift"
        grep -Fq "continue-on-error: \${{ matrix.support == 'advisory' }}" <<<"$body" || fail "release advisory condition drift"
        for name in $(jq -r '.display_names[]' <<<"$row" | sed 's/ /_/g'); do :; done
        ;;
      playwright-shards)
        grep -Fq 'shard: [1, 2, 3]' <<<"$body" || fail "Playwright shard topology drift"
        ;;
      *) fail "unknown topology matrix role: $role" ;;
    esac
  done < <(jq -c '.workflow_topology[]' "$policy_manifest")
}

validate_repository_contract() {
  [ -f "$ci_file" ] && [ -f "$ownership_file" ] || fail "missing workflow or ownership runbook"
  validate_policy_manifest
  validate_workflow_topology
  local docs_job release_job admin_drift_job host_job playwright_job annotation_job
  docs_job="$(job_body docs-contracts-shift-left)"; release_job="$(job_body release-gate)"; admin_drift_job="$(job_body admin-drift-docs)"; host_job="$(job_body host-integration)"; playwright_job="$(job_body playwright-e2e)"; annotation_job="$(job_body annotation-sweep)"
  [ -n "$docs_job" ] && [ -n "$release_job" ] && [ -n "$admin_drift_job" ] && [ -n "$host_job" ] && [ -n "$playwright_job" ] && [ -n "$annotation_job" ] || fail "missing stable CI job identity"
  [ "$(printf '%s\n' "$docs_job" | grep -Fc 'bash scripts/ci/verify_ci_baseline_contract.sh' || true)" -eq 1 ] || fail "baseline contract must have exactly one shift-left invocation"
  for needle in "needs: [release-gate]" "needs: [admin-drift-docs, docs-contracts-shift-left]" "needs: [host-integration]" "release-gate" "admin-drift-docs" "host-integration" "playwright-e2e"; do require_source_fixed "critical CI chain" "$admin_drift_job$host_job$playwright_job$annotation_job" "$needle"; done
  [ "$(grep -Fc "support: 'required'" <<<"$release_job")" -eq 3 ] || fail "release-gate must retain three required cells"
  for artifact in phase192-admin-playwright-report phase192-admin-playwright-evidence phase192-generated-evidence; do require_source_fixed "Phase 192 artifacts" "$(job_body admin-hardening-guardrails)" "$artifact"; done
  for command in "bash scripts/ci/accrue_host_uat.sh" "cd examples/accrue_host && mix verify.full" "npm ci" "npm run e2e:install" "accrue_host_verify_browser.sh"; do require_source_fixed "ownership runbook" "$(cat "$ownership_file")" "$command"; done
  for proof_state in required advisory skipped not-applicable; do require_source_fixed "ownership proof taxonomy" "$(cat "$ownership_file")" "$proof_state"; done
  jq -e '.required_check_snapshot.rules_response_state == "ok" and .required_check_snapshot.classic_response_state == "not-found" and .required_check_snapshot.enforcement_state == "none-enforced" and (.phase_227_selection_gate.required_evidence_fields | sort == ["affected_critical_path_stage","baseline_median_or_range","eligible_run_ids","json_paths"])' "$canonical_input" >/dev/null || fail "provider snapshot or Phase 227 selection contract failed"
}

if [ "$self_test_collector" = true ]; then
  run_collector_self_test
  exit 0
fi

if [ "$self_test" = true ]; then
  tmp_dir="$(mktemp -d)"; cleanup() { rm -rf "$tmp_dir"; }; trap cleanup EXIT
  expect_invalid() { local label="$1" filter="$2" path; path="$tmp_dir/$label.json"; jq "$filter" "$tmp_dir/collector-record.json" >"$path"; if bash "$root_dir/scripts/ci/verify_ci_baseline_contract.sh" --input "$path" >/dev/null 2>&1; then fail "$label mutation unexpectedly passed"; fi; }
  expect_canonical_invalid() { local label="$1" filter="$2" path; path="$tmp_dir/canonical-$label.json"; jq "$filter" "$canonical_input" >"$path"; if bash "$root_dir/scripts/ci/verify_ci_baseline_contract.sh" --input "$path" >/dev/null 2>&1; then fail "canonical $label mutation unexpectedly passed"; fi; }
  expect_semantic_invalid() { local label="$1" filter="$2" path; path="$tmp_dir/semantic-$label.json"; jq "$filter" "$tmp_dir/collector-semantic-record.json" >"$path"; if bash "$root_dir/scripts/ci/verify_ci_baseline_contract.sh" --input "$path" >/dev/null 2>&1; then fail "collector $label mutation unexpectedly passed"; fi; }
  expect_semantic_valid() { local label="$1" filter="$2" path; path="$tmp_dir/semantic-$label.json"; jq "$filter" "$tmp_dir/collector-semantic-record.json" >"$path"; bash "$root_dir/scripts/ci/verify_ci_baseline_contract.sh" --input "$path" >/dev/null || fail "collector $label derived-state fixture unexpectedly failed"; }
  validate_input "$canonical_input"
  # RED gate: the public canonical path must reject fields not in the durable schema.
  expect_canonical_invalid canonical-unknown-root '.evidence = "ghp_synthetic_secret_value"'
  fixture_dir="$tmp_dir/fixture"; mkdir "$fixture_dir"
  printf '%s\n' '{"status":200,"body":{"id":1,"name":"CI","event":"workflow_dispatch","head_sha":"1111111111111111111111111111111111111111","run_attempt":1,"status":"completed","conclusion":"success","created_at":"2026-08-09T15:56:11Z","updated_at":"2026-08-09T15:56:21Z","html_url":"https://github.com/szTheory/accrue/actions/runs/1"}}' >"$fixture_dir/run-1.json"
  printf '%s\n' '{"status":200,"body":{"total_count":1,"next_page":null,"jobs":[{"id":2,"name":"unknown job","status":"completed","conclusion":"success","started_at":"2026-08-09T15:56:12Z","completed_at":"2026-08-09T15:56:20Z","steps":[]}]}}' >"$fixture_dir/jobs-1-1.json"
  printf '%s\n' '{"status":200,"body":{"total_count":0,"next_page":null,"artifacts":[]}}' >"$fixture_dir/artifacts-1-1.json"; printf '%s\n' '{"status":200,"body":[]}' >"$fixture_dir/rules.json"; printf '%s\n' '{"status":404,"body":null}' >"$fixture_dir/required_status_checks.json"
  if bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/unknown.json"; then fail "unknown workflow job unexpectedly captured"; fi
  # RED gate for the public collector-to-contract path.  The implementation must
  # accept this reduced one-run document without importing cohort-only fields.
  jq '.body.total_count = 2 | .body.jobs[0].name = "Docs and bash contracts (shift-left)" | .body.jobs += [{"id":3,"name":"Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=off opentelemetry=off)","status":"completed","conclusion":"success","started_at":"2026-08-09T15:56:12Z","completed_at":"2026-08-09T15:56:20Z","steps":[]}]' "$fixture_dir/jobs-1-1.json" >"$fixture_dir/jobs-1.valid.json"
  mv "$fixture_dir/jobs-1.valid.json" "$fixture_dir/jobs-1-1.json"
  bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/collector-record.json"
  jq --slurpfile canonical "$canonical_input" '.runs[0] = $canonical[0].runs[0]' "$tmp_dir/collector-record.json" >"$tmp_dir/collector-complete.json"
  mv "$tmp_dir/collector-complete.json" "$tmp_dir/collector-record.json"
  validate_input "$tmp_dir/collector-record.json"
  # Workflow provenance and complete proof are public-path gates, not inferred
  # from aggregate fields or a matching policy snapshot alone.
  cp "$fixture_dir/run-1.json" "$tmp_dir/run.good.json"
  jq '.body.name = "Other workflow"' "$tmp_dir/run.good.json" >"$fixture_dir/run-1.json"
  if bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/other-workflow.json"; then fail "other workflow unexpectedly captured"; fi
  cp "$tmp_dir/run.good.json" "$fixture_dir/run-1.json"
  expect_invalid collector-workflow-mismatch '.runs[0].run.workflow = "Other workflow"'
  expect_canonical_invalid canonical-workflow-mismatch '.runs[0].run.workflow = "Other workflow"'
  # Reuse the canonical run as a semantically complete collector record so the
  # public mutation matrix can exercise required, advisory, and conditional lanes.
  cp "$tmp_dir/collector-record.json" "$tmp_dir/collector-semantic-record.json"
  validate_input "$tmp_dir/collector-semantic-record.json"
  # RED gates: public timing inputs must be derived from policy-bound timestamps,
  # not merely agree with candidate-supplied aggregate arithmetic.
  expect_invalid collector-chain-duration-drift '.runs[0].run.staged_critical_chain_seconds += 42'
  expect_canonical_invalid canonical-coherent-chain-duration-forgery '(.runs[0].run.staged_critical_chain_seconds += 42) | ([.runs[] | select(.run.eligible) | .run.staged_critical_chain_seconds] | sort) as $chains | .aggregates.staged_critical_chain_seconds = {per_run: ([.runs[] | select(.run.eligible) | {run_id: .run.id, seconds: .run.staged_critical_chain_seconds}]), minimum: $chains[0], median: $chains[($chains | length) / 2], maximum: $chains[-1]}'
  # RED gates: category and ID must originate with normalized observed pairs,
  # including an all-success path and an ineligible diagnostic path.
  expect_semantic_valid collector-all-success-category '(.runs[0].jobs |= map(if .manifest_identity == "admin-ui-ratchet-guardrails" then .conclusion = "success" else . end)) | .runs[0].root_failure_signature = {id:("ci-root-v2-" + ((["no-failure", []] | tojson | @base64) | gsub("="; ""))), category:"no-failure", affected_jobs:[], lane_conclusions:[]}'
  expect_semantic_invalid collector-all-success-category-forgery '(.runs[0].jobs |= map(if .manifest_identity == "admin-ui-ratchet-guardrails" then .conclusion = "success" else . end)) | .runs[0].root_failure_signature = {id:("ci-root-v2-" + ((["failed-lane", []] | tojson | @base64) | gsub("="; ""))), category:"failed-lane", affected_jobs:[], lane_conclusions:[]}'
  expect_canonical_invalid canonical-all-success-category-forgery '(.runs |= map(.jobs |= map(if .manifest_identity == "admin-ui-ratchet-guardrails" then .conclusion = "success" else . end) | .root_failure_signature = {id:("ci-root-v2-" + ((["no-failure", []] | tojson | @base64) | gsub("="; ""))), category:"no-failure", affected_jobs:[], lane_conclusions:[]})) | .runs[0].root_failure_signature = {id:("ci-root-v2-" + ((["failed-lane", []] | tojson | @base64) | gsub("="; ""))), category:"failed-lane", affected_jobs:[], lane_conclusions:[]}'
  expect_semantic_valid collector-diagnostic-failed-lane '(.runs[0].run.eligible = false) | (.runs[0].jobs |= map(if .manifest_identity == "release-manifest-ssot" then .conclusion = "failure" | .proof_state = "not-applicable" elif .policy == "advisory" then .proof_state = "advisory" else .proof_state = "not-applicable" end)) | ([.runs[0].jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | {manifest_identity, conclusion}] | unique | sort_by(.manifest_identity, .conclusion)) as $pairs | .runs[0].root_failure_signature = {id:("ci-root-v2-" + ((["failed-lane", $pairs] | tojson | @base64) | gsub("="; ""))), category:"failed-lane", affected_jobs:($pairs | map(.manifest_identity) | unique | sort), lane_conclusions:$pairs}'
  expect_semantic_invalid collector-diagnostic-category-forgery '(.runs[0].run.eligible = false) | (.runs[0].jobs |= map(if .manifest_identity == "release-manifest-ssot" then .conclusion = "failure" | .proof_state = "not-applicable" elif .policy == "advisory" then .proof_state = "advisory" else .proof_state = "not-applicable" end)) | ([.runs[0].jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | {manifest_identity, conclusion}] | unique | sort_by(.manifest_identity, .conclusion)) as $pairs | .runs[0].root_failure_signature = {id:("ci-root-v2-" + ((["no-failure", $pairs] | tojson | @base64) | gsub("="; ""))), category:"no-failure", affected_jobs:($pairs | map(.manifest_identity) | unique | sort), lane_conclusions:$pairs}'
  expect_semantic_invalid collector-required-lane-removal '([.runs[0].jobs[] | select(.required_for_release_proof) | .manifest_identity] | first) as $identity | (.runs[0].jobs |= map(select(.manifest_identity != $identity)))'
  expect_canonical_invalid canonical-required-lane-removal '([.runs[0].jobs[] | select(.required_for_release_proof) | .manifest_identity] | first) as $identity | (.runs[0].jobs |= map(select(.manifest_identity != $identity)))'
  # Live GitHub list response bodies do not carry fixture-only next_page fields.
  jq 'del(.body.next_page)' "$fixture_dir/jobs-1-1.json" >"$tmp_dir/live-jobs.json"; mv "$tmp_dir/live-jobs.json" "$fixture_dir/jobs-1-1.json"
  jq 'del(.body.next_page)' "$fixture_dir/artifacts-1-1.json" >"$tmp_dir/live-artifacts.json"; mv "$tmp_dir/live-artifacts.json" "$fixture_dir/artifacts-1-1.json"
  if bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/live-shape.json"; then fail "fixture-only pagination unexpectedly accepted as live shape"; fi
  expect_invalid unknown-root '.evidence = "ghp_synthetic_secret_value"'
  expect_invalid unknown-nested '.runs[0].jobs[0].evidence = "harmless"'
  expect_invalid secret-like-unknown '.runs[0].root_failure_signature.token = "ghp_synthetic_secret_value"'
  expect_invalid invalid-run-type '.runs[0].run.eligible = "true"'
  expect_invalid query-url '.runs[0].run.url = "https://github.com/a/b?token=no"'
  expect_invalid queue-drift '.runs[0].run.runner_queue_seconds += 1'
  expect_invalid signature-pair '.runs[0].root_failure_signature.lane_conclusions += [{"manifest_identity":"docs-contracts-shift-left","conclusion":"failure"}]'
  expect_invalid ineligible-proved '(.runs[0].run.eligible = false) | (.runs[0].jobs[0].proof_state = "proved")'
  # RED gates: both public document discriminators must reject unknown lane names.
  expect_invalid collector-fabricated-job '.runs[0].jobs[0].name = "Fabricated release lane"'
  expect_canonical_invalid canonical-fabricated-job '.runs[0].jobs[0].name = "Fabricated release lane"'
  # Each policy-owned field is an assertion in input, never a source of truth.
  expect_semantic_invalid collector-forged-manifest-identity '.runs[0].jobs[0].manifest_identity = "fabricated-release"'
  expect_canonical_invalid canonical-forged-manifest-identity '.runs[0].jobs[0].manifest_identity = "fabricated-release"'
  expect_semantic_invalid collector-forged-policy '.runs[0].jobs[0].policy = "advisory"'
  expect_canonical_invalid canonical-forged-policy '.runs[0].jobs[0].policy = "advisory"'
  expect_semantic_invalid collector-forged-required '.runs[0].jobs[0].required_for_release_proof = false'
  expect_canonical_invalid canonical-forged-required '.runs[0].jobs[0].required_for_release_proof = false'
  expect_semantic_invalid collector-forged-queue-root '.runs[0].jobs[0].initial_queue_root = false'
  expect_canonical_invalid canonical-forged-queue-root '.runs[0].jobs[0].initial_queue_root = false'
  expect_semantic_invalid collector-forged-chain-order '.runs[0].jobs[7].staged_critical_chain_order = 99'
  expect_canonical_invalid canonical-forged-chain-order '.runs[0].jobs[7].staged_critical_chain_order = 99'
  expect_semantic_invalid collector-forged-proof-state '.runs[0].jobs[0].proof_state = "not-applicable"'
  expect_canonical_invalid canonical-forged-proof-state '.runs[0].jobs[0].proof_state = "not-applicable"'
  # Public positive/negative pairs pin proof derivation precedence.
  expect_semantic_valid proof-eligible-required-success '.'
  expect_semantic_invalid proof-eligible-required-success-forged '.runs[0].jobs[0].proof_state = "skipped"'
  expect_semantic_invalid proof-skipped '(.runs[0].jobs[0].conclusion = "skipped") | (.runs[0].jobs[0].proof_state = "skipped")'
  expect_semantic_invalid proof-skipped-forged '(.runs[0].jobs[0].conclusion = "skipped") | (.runs[0].jobs[0].proof_state = "proved")'
  expect_semantic_valid proof-advisory '.'
  expect_semantic_invalid proof-advisory-forged '.runs[0].jobs[9].proof_state = "proved"'
  expect_semantic_valid proof-conditional '.'
  expect_semantic_invalid proof-conditional-forged '.runs[0].jobs[11].proof_state = "proved"'
  expect_semantic_invalid proof-unsuccessful-required '(.runs[0].jobs[0].conclusion = "failure") | (.runs[0].jobs[0].proof_state = "not-applicable") | ([.runs[0].jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | {manifest_identity, conclusion}] | unique | sort_by(.manifest_identity, .conclusion)) as $pairs | .runs[0].root_failure_signature = {id:("ci-root-v2-" + ((["failed-lane", $pairs] | tojson | @base64) | gsub("="; ""))), category:"failed-lane", affected_jobs:($pairs | map(.manifest_identity) | unique | sort), lane_conclusions:$pairs}'
  expect_semantic_invalid proof-unsuccessful-required-forged '(.runs[0].jobs[0].conclusion = "failure") | (.runs[0].jobs[0].proof_state = "proved") | ([.runs[0].jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | {manifest_identity, conclusion}] | unique | sort_by(.manifest_identity, .conclusion)) as $pairs | .runs[0].root_failure_signature = {id:("ci-root-v2-" + ((["failed-lane", $pairs] | tojson | @base64) | gsub("="; ""))), category:"failed-lane", affected_jobs:($pairs | map(.manifest_identity) | unique | sort), lane_conclusions:$pairs}'
  expect_semantic_valid proof-ineligible '(.runs[0].run.eligible = false) | (.runs[0].jobs |= map(if .conclusion == "skipped" then .proof_state = "skipped" elif .policy == "advisory" then .proof_state = "advisory" else .proof_state = "not-applicable" end))'
  expect_semantic_invalid proof-ineligible-forged '(.runs[0].run.eligible = false) | (.runs[0].jobs |= map(if .conclusion == "skipped" then .proof_state = "skipped" elif .policy == "advisory" then .proof_state = "advisory" else .proof_state = "not-applicable" end)) | (.runs[0].jobs[0].proof_state = "proved")'
  # Canonical mutation matrix: each copy goes through the public discriminator.
  expect_canonical_invalid canonical-policy-unknown '.policy_manifest.evidence = "harmless"'
  expect_canonical_invalid canonical-privacy-unknown '.privacy.evidence = "harmless"'
  expect_canonical_invalid canonical-snapshot-unknown '.required_check_snapshot.evidence = "harmless"'
  expect_canonical_invalid canonical-anchor-unknown '.anchor.evidence = "harmless"'
  expect_canonical_invalid canonical-cohort-unknown '.cohort.evidence = "harmless"'
  expect_canonical_invalid canonical-remote-unknown '.cohort.remote_snapshot.evidence = "harmless"'
  expect_canonical_invalid canonical-aggregate-unknown '.aggregates.evidence = "harmless"'
  expect_canonical_invalid canonical-metric-unknown '.aggregates.wall_seconds.per_run[0].evidence = "harmless"'
  expect_canonical_invalid canonical-proof-unknown '.aggregates.proof.evidence = "harmless"'
  expect_canonical_invalid canonical-proof-row-unknown '.aggregates.proof.per_run[0].evidence = "harmless"'
  expect_canonical_invalid canonical-selection-unknown '.phase_227_selection_gate.evidence = "harmless"'
  expect_canonical_invalid canonical-candidate-unknown '.phase_227_selection_gate.candidates[0].evidence = "harmless"'
  expect_canonical_invalid canonical-run-record-unknown '.runs[0].evidence = "harmless"'
  expect_canonical_invalid canonical-run-unknown '.runs[0].run.evidence = "harmless"'
  expect_canonical_invalid canonical-job-unknown '.runs[0].jobs[0].evidence = "harmless"'
  expect_canonical_invalid canonical-step-unknown '.runs[0].jobs[0].steps[0].evidence = "harmless"'
  expect_canonical_invalid canonical-artifact-unknown '.runs[0].artifacts[0].evidence = "harmless"'
  expect_canonical_invalid canonical-signature-unknown '.runs[0].root_failure_signature.evidence = "harmless"'
  expect_canonical_invalid canonical-lane-unknown '.runs[0].root_failure_signature.lane_conclusions[0].evidence = "harmless"'
  expect_canonical_invalid canonical-empty-rules '.required_check_snapshot.rules += [{}]'
  expect_canonical_invalid canonical-empty-classic '.required_check_snapshot.classic_checks += [{}]'
  expect_canonical_invalid canonical-empty-exclusions '.cohort.exclusions += [{}]'
  expect_canonical_invalid canonical-object-type '.aggregates = []'
  expect_canonical_invalid canonical-array-type '.runs = {}'
  expect_canonical_invalid canonical-string-type '.repository = 1'
  expect_canonical_invalid canonical-number-type '.aggregates.wall_seconds.minimum = "2182"'
  expect_canonical_invalid canonical-integer-type '.runs[0].run.id = 1.5'
  expect_canonical_invalid canonical-boolean-type '.runs[0].run.eligible = "true"'
  expect_canonical_invalid canonical-nullability '.runs[0].run.conclusion = 1'
  expect_canonical_invalid canonical-enum '.runs[0].jobs[0].proof_state = "uncertain"'
  expect_canonical_invalid canonical-timestamp '.runs[0].run.created_at = "yesterday"'
  expect_canonical_invalid canonical-url '.runs[0].run.url = "ftp://example.test/run"'
  expect_canonical_invalid canonical-sha '.runs[0].run.head_sha = "not-a-sha"'
  expect_canonical_invalid canonical-duration '.runs[0].jobs[0].duration_seconds = -1'
  expect_canonical_invalid canonical-scalar-array '.privacy.allowlist[0] = 1'
  expect_canonical_invalid canonical-secret-allowed '.privacy.allowlist[0] = "ghp_synthetic_secret_value"'
  expect_canonical_invalid canonical-payload-allowed '.phase_227_selection_gate.rule = "synthetic raw payload"'
  expect_canonical_invalid canonical-query-url '.runs[0].run.url = "https://github.com/a/b?token=no"'
  # Provider ambiguity and pagination must fail before a record is published.
  cp "$fixture_dir/rules.json" "$tmp_dir/rules.good.json"
  for status in 401 403 429 500; do
    jq --argjson status "$status" '.status = $status' "$tmp_dir/rules.good.json" >"$fixture_dir/rules.json"
    if bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/http-$status.json"; then fail "effective-rules HTTP $status unexpectedly captured"; fi
  done
  cp "$tmp_dir/rules.good.json" "$fixture_dir/rules.json"
  cp "$fixture_dir/required_status_checks.json" "$tmp_dir/classic.good.json"
  for status in 401 403 429 500; do
    jq --argjson status "$status" '.status = $status' "$tmp_dir/classic.good.json" >"$fixture_dir/required_status_checks.json"
    if bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/classic-$status.json"; then fail "classic HTTP $status unexpectedly captured"; fi
  done
  cp "$tmp_dir/classic.good.json" "$fixture_dir/required_status_checks.json"
  validate_repository_contract
  cp "$ci_file" "$tmp_dir/ci.yml"; sed -i.bak 's/  host-integration:/  host-integration-renamed:/' "$tmp_dir/ci.yml"; ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "renamed required job unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  # Topology mutations must be rejected even for jobs that older targeted checks
  # do not mention.  These copies exercise the repository-facing gate.
  cp "$ci_file" "$tmp_dir/ci.yml"
  sed -i.bak 's/name: Release manifest SSOT (REL-02)/name: Release manifest SSOT (renamed)/' "$tmp_dir/ci.yml"
  ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "scalar topology rename unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ci_file" "$tmp_dir/ci.yml"
  printf '\n  unmanifested-topology-job:\n    name: Unmanifested topology job\n    runs-on: ubuntu-24.04\n    steps: []\n' >>"$tmp_dir/ci.yml"
  ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "added topology job unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ci_file" "$tmp_dir/ci.yml"; sed -i.bak "/- elixir: '1.19.0'/,+6 s/support: 'required'/support: 'advisory'/" "$tmp_dir/ci.yml"; ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "release support mutation unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ci_file" "$tmp_dir/ci.yml"; sed -i.bak 's/shard: \[1, 2, 3\]/shard: [1, 2]/' "$tmp_dir/ci.yml"; ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "Playwright shard mutation unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ci_file" "$tmp_dir/ci.yml"; sed -i.bak "s/github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'/github.event_name == 'schedule'/" "$tmp_dir/ci.yml"; ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "conditional topology mutation unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ownership_file" "$tmp_dir/ownership.md"; sed -i.bak 's/npm run e2e:install/npm run e2e-install/g' "$tmp_dir/ownership.md"; ownership_file="$tmp_dir/ownership.md"; if (validate_repository_contract); then fail "missing ownership command unexpectedly passed"; fi
  echo "verify_ci_baseline_contract: self-test ok"
  exit 0
fi
validate_input "$input"; validate_repository_contract; echo "verify_ci_baseline_contract: ok"
