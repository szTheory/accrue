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
input="$canonical_input"; self_test=false
case "${1:-}" in
  --self-test) [ "$#" -eq 1 ] || fail "--self-test accepts no other arguments"; self_test=true ;;
  --input) [ "$#" -eq 2 ] || fail "--input requires a path"; input="$2" ;;
  "") ;;
  *) fail "usage: $0 [--input PATH]" ;;
esac
[ -x "$root_dir/scripts/ci/capture_ci_baseline.sh" ] || fail "missing executable collector"

require_source_fixed() { printf '%s\n' "$2" | grep -Fq "$3" || fail "missing '$3' in $1"; }
job_body() { awk -v job_id="$1" '$0 == "  " job_id ":" {in_job=1} in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" {exit} in_job {print}' "$ci_file"; }

validate_policy_manifest() {
  jq -e '.schema_version == 2 and (.workflow | type == "string" and length > 0) and (.lanes | type == "array" and length > 0) and all(.lanes[]; (keys|sort) == ["identity","initial_queue_root","match","policy","required_for_release_proof","staged_critical_chain_order"] and (.identity | type == "string" and test("^[a-z0-9-]+$")) and (.match | type == "string" and length > 0) and (.policy == "required" or .policy == "advisory" or .policy == "conditional") and (.required_for_release_proof | type == "boolean") and (.initial_queue_root | type == "boolean") and (.staged_critical_chain_order == null or (.staged_critical_chain_order | type == "number" and floor == . and . > 0))) and ([.lanes[].identity] | unique | length == length)' "$policy_manifest" >/dev/null || fail "invalid workflow policy manifest"
  jq -n --slurpfile policy "$policy_manifest" --slurpfile baseline "$canonical_input" 'all($baseline[0].runs[].jobs[]; . as $job | ([ $policy[0].lanes[] | .match as $match | select($job.name | test($match)) ] | length) == 1)' >/dev/null || fail "policy manifest does not classify canonical job identities exactly once"
}

validate_aggregates() {
  local candidate="$1"
  jq -e --argjson expected_ids "$expected_ids" --slurpfile policy "$policy_manifest" '
    ([.runs[] | select(.run.eligible == true)]) as $eligible |
    ($policy[0].lanes | map(select(.required_for_release_proof)) | map(.identity) | sort) as $required |
    ($eligible | map(.run.critical_queue_seconds) | sort) as $queues |
    ($eligible | map(.run.wall_seconds) | sort) as $walls |
    (.aggregates.queue_seconds == {per_run: ($eligible | map({run_id: .run.id, seconds: .run.critical_queue_seconds})), minimum: $queues[0], median: $queues[($queues|length)/2], maximum: $queues[-1]}) and
    (.aggregates.wall_seconds == {per_run: ($eligible | map({run_id: .run.id, seconds: .run.wall_seconds})), minimum: $walls[0], median: $walls[($walls|length)/2], maximum: $walls[-1]}) and
    (.aggregates.proof.eligible_run_ids == $expected_ids) and
    (.aggregates.proof.required_lane_identities == $required) and
    (.aggregates.proof.per_run == ($eligible | map({run_id: .run.id, required_proved_lane_identities: ([.jobs[] | select(.proof_state == "proved" and .required_for_release_proof == true) | .manifest_identity] | unique | sort), required_proved_count: ([.jobs[] | select(.proof_state == "proved" and .required_for_release_proof == true) | .manifest_identity] | unique | length)}))) and
    (.aggregates.proof.all_required_lanes_proved == ([$eligible[] | ([.jobs[] | select(.proof_state == "proved" and .required_for_release_proof == true) | .manifest_identity] | unique | sort) == $required] | all))
  ' "$candidate" >/dev/null || fail "derived queue or required-proof aggregate mismatch"
}

validate_collector_record() {
  local candidate="$1"
  validate_policy_manifest
  jq -e --slurpfile policy "$policy_manifest" '
    def exact($x): (keys|sort)==$x; def iso: type=="string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T.*Z$"); def num: type=="number" and isfinite and .>=0;
    def step: exact(["completed_at","conclusion","duration_seconds","name","started_at"]) and (.name|type=="string") and (.conclusion|type=="string" or .==null) and (.started_at|iso or .==null) and (.completed_at|iso or .==null) and (.duration_seconds|num or .==null);
    def job: exact(["cache_state","completed_at","conclusion","duration_seconds","id","initial_queue_root","manifest_identity","name","policy","proof_state","required_for_release_proof","staged_critical_chain_order","started_at","status","steps"]) and (.id|type=="number") and (.name|type=="string") and (.status|type=="string") and (.conclusion|type=="string" or .==null) and (.started_at|iso or .==null) and (.completed_at|iso or .==null) and (.duration_seconds|num or .==null) and (.steps|type=="array" and all(.[];step)) and (.policy=="required" or .=="advisory" or .=="conditional") and (.required_for_release_proof|type=="boolean") and (.initial_queue_root|type=="boolean") and (.staged_critical_chain_order==null or (.staged_critical_chain_order|type=="number" and floor==. and .>0)) and (.proof_state=="proved" or .=="skipped" or .=="advisory" or .=="not-applicable") and (.cache_state=="observed-hit" or .=="observed-miss" or .=="inferred-setup-bypass" or .=="unknown");
    def artifact: exact(["expired","expires_at","id","name","size_in_bytes"]) and (.id|type=="number") and (.name|type=="string") and (.size_in_bytes|num) and (.expires_at|iso or .==null) and (.expired|type=="boolean");
    def run: exact(["attempt","completed_at","conclusion","created_at","eligible","event","exclusion_reason","head_sha","id","runner_queue_omission_reason","runner_queue_seconds","staged_critical_chain_omission_reason","staged_critical_chain_seconds","status","url","wall_seconds","workflow"]) and (.id|type=="number") and (.workflow|type=="string") and (.event|type=="string") and (.head_sha|type=="string" and test("^[0-9a-f]{40}$")) and (.attempt|type=="number" and floor==. and .>0) and (.status|type=="string") and (.conclusion|type=="string" or .==null) and (.created_at|iso) and (.completed_at|iso) and (.url | (type=="string" and test("^https://") and (contains("?")|not))) and (.wall_seconds|num) and (.eligible|type=="boolean") and (.exclusion_reason|type=="string" or .==null) and (.runner_queue_seconds|num or .==null) and (.runner_queue_omission_reason==null or .=="provider-omitted-initial-root-started-at") and (.staged_critical_chain_seconds|num or .==null) and (.staged_critical_chain_omission_reason==null or .=="provider-omitted-staged-chain-timestamp");
    def sig: exact(["affected_jobs","category","id","lane_conclusions"]) and (.id|type=="string" and test("^ci-root-v2-[A-Za-z0-9_-]+$")) and (.category=="no-failure" or .=="failed-lane") and (.affected_jobs|type=="array" and .==sort and .==unique) and (.lane_conclusions|type=="array" and .==sort_by(.manifest_identity,.conclusion) and .==unique and all(.[]; exact(["conclusion","manifest_identity"]) and (.manifest_identity|type=="string") and (.conclusion=="failure" or .=="timed_out" or .=="cancelled")));
    exact(["document_type","policy_manifest","privacy","repository","required_check_snapshot","runs","schema_version"]) and .schema_version==2 and .document_type=="ci-baseline-collector-record" and (.repository|type=="string" and test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) and (.policy_manifest|exact(["schema_version","workflow"]) and .schema_version==$policy[0].schema_version and .workflow==$policy[0].workflow) and (.privacy|exact(["allowlist","artifact_archives_downloaded","env_values_recorded","logs_downloaded","raw_payloads_recorded"]) and .logs_downloaded==false and .artifact_archives_downloaded==false and .env_values_recorded==false and .raw_payloads_recorded==false) and (.required_check_snapshot|exact(["captured_at","classic_checks","classic_response_state","enforcement_state","rules","rules_response_state"])) and (.runs|type=="array" and length>0 and all(.[]; exact(["artifacts","jobs","root_failure_signature","run"]) and (.run|exact(["attempt","completed_at","conclusion","created_at","eligible","event","exclusion_reason","head_sha","id","runner_queue_omission_reason","runner_queue_seconds","staged_critical_chain_omission_reason","staged_critical_chain_seconds","status","url","wall_seconds","workflow"]) and (.eligible|type=="boolean") and (.runner_queue_seconds|type=="number" or .==null) and (.staged_critical_chain_seconds|type=="number" or .==null)) and (.jobs|type=="array" and all(.[]; exact(["cache_state","completed_at","conclusion","duration_seconds","id","initial_queue_root","manifest_identity","name","policy","proof_state","required_for_release_proof","staged_critical_chain_order","started_at","status","steps"]) and (.id|type=="number") and (.initial_queue_root|type=="boolean") and (.required_for_release_proof|type=="boolean") and (.steps|type=="array"))) and (.artifacts|type=="array" and all(.[]; exact(["expired","expires_at","id","name","size_in_bytes"]) and (.id|type=="number"))) and (.root_failure_signature|exact(["affected_jobs","category","id","lane_conclusions"]) and (.lane_conclusions|type=="array"))))
  ' "$candidate" >/dev/null || fail "collector record schema failed: ${candidate#$root_dir/}"
  if jq -e '.. | strings | select(test("https?://[^[:space:]]+\\?"))' "$candidate" >/dev/null; then fail "privacy contract rejected query-bearing URL"; fi
}

validate_canonical_cohort() { # v1 remains readable only until Plan 06 regenerates the v2 canonical artifact.
  jq -e --argjson expected_ids "$expected_ids" '.schema_version == 1 and (.runs|type=="array") and ([.runs[]|select(.run.eligible==true)|.run.id] == $expected_ids) and (.cohort.eligible_count==3) and (.aggregates|type=="object") and (.phase_227_selection_gate|type=="object")' "$1" >/dev/null || fail "canonical cohort contract failed: ${1#$root_dir/}"
}
validate_input() { local candidate="$1"; [ -f "$candidate" ] || fail "missing baseline input: ${candidate#$root_dir/}"; case "$(jq -r '.document_type // "canonical-v1"' "$candidate")" in ci-baseline-collector-record) validate_collector_record "$candidate";; canonical-v1) validate_canonical_cohort "$candidate";; *) fail "unknown document discriminator";; esac; }

validate_repository_contract() {
  [ -f "$ci_file" ] && [ -f "$ownership_file" ] || fail "missing workflow or ownership runbook"
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

if [ "$self_test" = true ]; then
  tmp_dir="$(mktemp -d)"; cleanup() { rm -rf "$tmp_dir"; }; trap cleanup EXIT
  expect_invalid() { local label="$1" filter="$2" path; path="$tmp_dir/$label.json"; jq "$filter" "$tmp_dir/collector-record.json" >"$path"; if (validate_input "$path"); then fail "$label mutation unexpectedly passed"; fi; }
  validate_input "$canonical_input"
  fixture_dir="$tmp_dir/fixture"; mkdir "$fixture_dir"
  printf '%s\n' '{"status":200,"body":{"id":1,"name":"CI","event":"workflow_dispatch","head_sha":"1111111111111111111111111111111111111111","run_attempt":1,"status":"completed","conclusion":"success","created_at":"2026-08-09T15:56:11Z","updated_at":"2026-08-09T15:56:21Z","html_url":"https://github.com/szTheory/accrue/actions/runs/1"}}' >"$fixture_dir/run-1.json"
  printf '%s\n' '{"status":200,"body":{"total_count":1,"next_page":null,"jobs":[{"id":2,"name":"unknown job","status":"completed","conclusion":"success","started_at":"2026-08-09T15:56:12Z","completed_at":"2026-08-09T15:56:20Z","steps":[]}]}}' >"$fixture_dir/jobs-1-1.json"
  printf '%s\n' '{"status":200,"body":{"total_count":0,"next_page":null,"artifacts":[]}}' >"$fixture_dir/artifacts-1-1.json"; printf '%s\n' '{"status":200,"body":[]}' >"$fixture_dir/rules.json"; printf '%s\n' '{"status":404,"body":null}' >"$fixture_dir/required_status_checks.json"
  if bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/unknown.json"; then fail "unknown workflow job unexpectedly captured"; fi
  # RED gate for the public collector-to-contract path.  The implementation must
  # accept this reduced one-run document without importing cohort-only fields.
  jq '.body.jobs[0].name = "Docs and bash contracts (shift-left)"' "$fixture_dir/jobs-1-1.json" >"$fixture_dir/jobs-1.valid.json"
  mv "$fixture_dir/jobs-1.valid.json" "$fixture_dir/jobs-1-1.json"
  bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/collector-record.json"
  validate_input "$tmp_dir/collector-record.json"
  expect_invalid unknown-root '.evidence = "ghp_synthetic_secret_value"'
  expect_invalid unknown-nested '.runs[0].jobs[0].evidence = "harmless"'
  expect_invalid secret-like-unknown '.runs[0].root_failure_signature.token = "ghp_synthetic_secret_value"'
  expect_invalid invalid-run-type '.runs[0].run.eligible = "true"'
  expect_invalid query-url '.runs[0].run.url = "https://github.com/a/b?token=no"'
  validate_repository_contract
  cp "$ci_file" "$tmp_dir/ci.yml"; sed -i.bak 's/  host-integration:/  host-integration-renamed:/' "$tmp_dir/ci.yml"; ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "renamed required job unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ownership_file" "$tmp_dir/ownership.md"; sed -i.bak 's/npm run e2e:install/npm run e2e-install/g' "$tmp_dir/ownership.md"; ownership_file="$tmp_dir/ownership.md"; if (validate_repository_contract); then fail "missing ownership command unexpectedly passed"; fi
  echo "verify_ci_baseline_contract: self-test ok"
  exit 0
fi
validate_input "$input"; validate_repository_contract; echo "verify_ci_baseline_contract: ok"
