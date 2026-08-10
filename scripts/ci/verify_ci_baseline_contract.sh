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
  jq -e '.schema_version == 1 and (.workflow | type == "string" and length > 0) and (.lanes | type == "array" and length > 0) and all(.lanes[]; (.identity | type == "string" and test("^[a-z0-9-]+$")) and (.match | type == "string" and length > 0) and (.policy == "required" or .policy == "advisory" or .policy == "conditional") and (.required_for_release_proof | type == "boolean") and (.critical_chain_root | type == "boolean")) and ([.lanes[].identity] | unique | length == length)' "$policy_manifest" >/dev/null || fail "invalid workflow policy manifest"
  jq -n --slurpfile policy "$policy_manifest" --slurpfile baseline "$canonical_input" 'all($baseline[0].runs[].jobs[]; . as $job | ([ $policy[0].lanes[] | . as $lane | select($job.name | test($lane.match)) ] | length) == 1)' >/dev/null || fail "policy manifest does not classify canonical job identities exactly once"
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

validate_input() {
  local candidate="$1"
  [ -f "$candidate" ] || fail "missing baseline input: ${candidate#$root_dir/}"
  validate_policy_manifest
  jq -e --argjson expected_ids "$expected_ids" --argjson locks "$required_lockfiles" --slurpfile policy "$policy_manifest" '
    .schema_version == 1 and (.policy_manifest.schema_version == $policy[0].schema_version and .policy_manifest.workflow == $policy[0].workflow) and
    (.repository | type == "string" and test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) and
    (.privacy.logs_downloaded == false and .privacy.artifact_archives_downloaded == false and .privacy.env_values_recorded == false and .privacy.raw_payloads_recorded == false) and
    (.required_check_snapshot.enforcement_state == "none-enforced" or .required_check_snapshot.enforcement_state == "enforced") and .required_check_snapshot.rules_response_state == "ok" and
    (.required_check_snapshot.classic_response_state == "ok" or .required_check_snapshot.classic_response_state == "not-found") and
    (if .required_check_snapshot.enforcement_state == "none-enforced" then ((.required_check_snapshot.rules|length)==0 and (.required_check_snapshot.classic_checks|length)==0 and .required_check_snapshot.classic_response_state == "not-found") else true end) and
    ([.runs[] | select(.run.eligible == true)]) as $eligible |
    ($eligible | map(.run.id)) == $expected_ids and (.cohort.eligible_count == 3 and .cohort.eligible_run_ids == $expected_ids) and
    all(.runs[]; (.run.eligible == true or (.run.exclusion_reason | type == "string" and length > 0))) and
    all($eligible[]; .run.event == "workflow_dispatch" and .run.attempt == 1 and .run.status == "completed" and .run.conclusion == "success" and (.run.critical_queue_seconds | type == "number" and . >= 0) and .run.critical_queue_omission_reason == null and (.root_failure_signature.id | type == "string" and test("^ci-root-v1-[A-Za-z0-9_-]+$")) and (.root_failure_signature.category == "no-failure" or .root_failure_signature.category == "failed-lane") and (.root_failure_signature.affected_jobs | type == "array" and . == (sort | unique)) and all(.jobs[]; . as $job | ([ $policy[0].lanes[] | . as $lane | select($job.name | test($lane.match)) | select(.identity == $job.manifest_identity and .policy == $job.policy and .required_for_release_proof == $job.required_for_release_proof and .critical_chain_root == $job.critical_chain_root)] | length) == 1 and (.proof_state == "proved" or .proof_state == "skipped" or .proof_state == "advisory" or .proof_state == "not-applicable") and (.cache_state == "observed-hit" or .cache_state == "observed-miss" or .cache_state == "inferred-setup-bypass" or .cache_state == "unknown") and (if .proof_state == "proved" then (.policy == "required" and .required_for_release_proof == true and .conclusion == "success") else true end))) and
    all($eligible[]; ([.jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | .manifest_identity] | sort | unique) == .root_failure_signature.affected_jobs and (if (.root_failure_signature.affected_jobs|length) == 0 then .root_failure_signature.category == "no-failure" else .root_failure_signature.category == "failed-lane" end)) and
    (.cohort.anchor.ref | type == "string" and length > 0) and (.cohort.anchor.sha | type == "string" and test("^[0-9a-f]{40}$")) and (.cohort.anchor.remote_sha | type == "string" and test("^[0-9a-f]{40}$")) and (.cohort.remote_snapshot.ref | type == "string" and length > 0) and (.cohort.remote_snapshot.sha | type == "string" and test("^[0-9a-f]{40}$")) and (.cohort.remote_snapshot.remote_sha | type == "string" and test("^[0-9a-f]{40}$")) and
    (.cohort.anchor.workflow_blob_oid | type == "string" and test("^[0-9a-f]{40}$")) and (.cohort.remote_snapshot.workflow_blob_oid == .cohort.anchor.workflow_blob_oid) and
    (.cohort.anchor.lockfile_blob_oids | keys | sort) == ($locks | sort) and (.cohort.remote_snapshot.lockfile_blob_oids | keys | sort) == ($locks | sort) and (.cohort.remote_snapshot.lockfile_blob_oids == .cohort.anchor.lockfile_blob_oids) and all(.cohort.anchor.lockfile_blob_oids[]; type == "string" and test("^[0-9a-f]{40}$"))
  ' "$candidate" >/dev/null || fail "cohort, manifest, signature, or provenance contract failed: ${candidate#$root_dir/}"
  validate_aggregates "$candidate"
  if jq -e '.. | objects | to_entries[]? | select((.key | test("(secret|token|env|payload|log|archive|trace|screenshot|server_output)"; "i")) and (.key != "logs_downloaded" and .key != "artifact_archives_downloaded" and .key != "env_values_recorded" and .key != "raw_payloads_recorded"))' "$candidate" >/dev/null; then fail "privacy contract rejected forbidden key"; fi
  if jq -e '.. | strings | select(test("https?://[^[:space:]]+\\?"))' "$candidate" >/dev/null; then fail "privacy contract rejected query-bearing URL"; fi
}

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
  expect_invalid() { local label="$1" filter="$2" path; path="$tmp_dir/$label.json"; jq "$filter" "$canonical_input" >"$path"; if (validate_input "$path"); then fail "$label mutation unexpectedly passed"; fi; }
  validate_input "$canonical_input"
  expect_invalid one-run '(.runs[0].run.eligible = false) | (.runs[0].run.exclusion_reason = "synthetic exclusion")'
  expect_invalid null-queue '.runs[0].run.critical_queue_seconds = null'
  expect_invalid deleted-signature 'del(.runs[0].root_failure_signature)'
  expect_invalid no-proved '(.runs[].jobs[] | select(.proof_state == "proved") | .proof_state) = "skipped"'
  expect_invalid removed-required-lane 'del(.runs[0].jobs[] | select(.manifest_identity == "release-gate-primary"))'
  expect_invalid unknown-lane '.runs[0].jobs[0].manifest_identity = "unknown-lane"'
  expect_invalid queue-aggregate '.aggregates.queue_seconds.minimum = 0'
  expect_invalid proof-aggregate '.aggregates.proof.all_required_lanes_proved = false'
  expect_invalid missing-anchor-provenance 'del(.cohort.anchor.ref)'
  expect_invalid workflow-blob-mismatch '.cohort.remote_snapshot.workflow_blob_oid = "0000000000000000000000000000000000000000"'
  for lockfile in accrue/mix.lock accrue_admin/mix.lock accrue_admin/package-lock.json examples/accrue_host/mix.lock examples/accrue_host/package-lock.json examples/accrue_host/assets/package-lock.json; do
    expect_invalid "deleted-$(basename "$lockfile")" "del(.cohort.anchor.lockfile_blob_oids[\"$lockfile\"])"
    expect_invalid "changed-$(basename "$lockfile")" ".cohort.remote_snapshot.lockfile_blob_oids[\"$lockfile\"] = \"0000000000000000000000000000000000000000\""
  done
  fixture_dir="$tmp_dir/fixture"; mkdir "$fixture_dir"
  printf '%s\n' '{"id":1,"name":"CI","event":"workflow_dispatch","head_sha":"1111111111111111111111111111111111111111","run_attempt":1,"status":"completed","conclusion":"success","created_at":"2026-08-09T15:56:11Z","updated_at":"2026-08-09T15:56:21Z","html_url":"https://github.com/szTheory/accrue/actions/runs/1"}' >"$fixture_dir/run-1.json"
  printf '%s\n' '{"jobs":[{"id":2,"name":"unknown job","status":"completed","conclusion":"success","started_at":"2026-08-09T15:56:12Z","completed_at":"2026-08-09T15:56:20Z","steps":[]}]}' >"$fixture_dir/jobs-1.json"
  printf '%s\n' '{"artifacts":[]}' >"$fixture_dir/artifacts-1.json"; printf '%s\n' '[]' >"$fixture_dir/rules.json"; printf '%s\n' '{"response_state":"not-found"}' >"$fixture_dir/required_status_checks.json"
  if bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/unknown.json"; then fail "unknown workflow job unexpectedly captured"; fi
  validate_repository_contract
  cp "$ci_file" "$tmp_dir/ci.yml"; sed -i.bak 's/  host-integration:/  host-integration-renamed:/' "$tmp_dir/ci.yml"; ci_file="$tmp_dir/ci.yml"; if (validate_repository_contract); then fail "renamed required job unexpectedly passed"; fi; ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ownership_file" "$tmp_dir/ownership.md"; sed -i.bak 's/npm run e2e:install/npm run e2e-install/g' "$tmp_dir/ownership.md"; ownership_file="$tmp_dir/ownership.md"; if (validate_repository_contract); then fail "missing ownership command unexpectedly passed"; fi
  echo "verify_ci_baseline_contract: self-test ok"
  exit 0
fi
validate_input "$input"; validate_repository_contract; echo "verify_ci_baseline_contract: ok"
