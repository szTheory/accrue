#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
canonical_input="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"
ci_file="$root_dir/.github/workflows/ci.yml"
ownership_file="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md"

fail() {
  echo "verify_ci_baseline_contract: $*" >&2
  exit 1
}

input="$canonical_input"
self_test=false
if [ "${1:-}" = "--self-test" ]; then
  [ "$#" -eq 1 ] || fail "--self-test accepts no other arguments"
  self_test=true
elif [ "${1:-}" = "--input" ]; then
  [ "$#" -eq 2 ] || fail "--input requires a path"
  input="$2"
elif [ "$#" -ne 0 ]; then
  fail "usage: $0 [--input PATH]"
fi

[ -x "$root_dir/scripts/ci/capture_ci_baseline.sh" ] || fail "missing executable collector: scripts/ci/capture_ci_baseline.sh"

require_source_fixed() {
  local label="$1" source="$2" needle="$3"
  printf '%s\n' "$source" | grep -Fq "$needle" || fail "missing '${needle}' in ${label}"
}

job_body() {
  local job_id="$1"
  awk -v job_id="$job_id" '
    $0 == "  " job_id ":" { in_job = 1 }
    in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" { exit }
    in_job { print }
  ' "$ci_file"
}

validate_repository_contract() {
  [ -f "$ci_file" ] || fail "missing workflow: .github/workflows/ci.yml"
  [ -f "$ownership_file" ] || fail "missing ownership runbook"

  local docs_job release_job admin_drift_job host_job playwright_job annotation_job invocations required_cells
  docs_job="$(job_body docs-contracts-shift-left)"
  release_job="$(job_body release-gate)"
  admin_drift_job="$(job_body admin-drift-docs)"
  host_job="$(job_body host-integration)"
  playwright_job="$(job_body playwright-e2e)"
  annotation_job="$(job_body annotation-sweep)"
  [ -n "$docs_job" ] && [ -n "$release_job" ] && [ -n "$admin_drift_job" ] && [ -n "$host_job" ] && [ -n "$playwright_job" ] && [ -n "$annotation_job" ] || fail "missing stable CI job identity"

  invocations="$(printf '%s\n' "$docs_job" | grep -Fc 'bash scripts/ci/verify_ci_baseline_contract.sh' || true)"
  [ "$invocations" -eq 1 ] || fail "baseline contract must have exactly one docs-contracts-shift-left invocation"
  ! printf '%s\n' "$ci_file" | awk '/^  docs-contracts-shift-left:/{seen=1; next} seen && /^  [A-Za-z0-9_-]+:/{seen=0} !seen{print}' | grep -Fq 'bash scripts/ci/verify_ci_baseline_contract.sh' || fail "baseline contract invocation escaped docs-contracts-shift-left"

  for needle in "needs: [release-gate]" "needs: [admin-drift-docs, docs-contracts-shift-left]" "needs: [host-integration]" "release-gate" "admin-drift-docs" "host-integration" "playwright-e2e"; do
    require_source_fixed "critical CI chain" "$admin_drift_job$host_job$playwright_job$annotation_job" "$needle"
  done
  require_source_fixed "release-gate matrix" "$release_job" "support: 'required'"
  required_cells="$(grep -Fc "support: 'required'" <<<"$release_job")"
  [ "$required_cells" -eq 3 ] || fail "release-gate must retain three required cells"
  require_source_fixed "release-gate matrix" "$release_job" "sigra: 'on'"
  require_source_fixed "release-gate matrix" "$release_job" "support: 'advisory'"
  require_source_fixed "release-gate policy" "$release_job" "continue-on-error:"
  require_source_fixed "release-gate policy" "$release_job" "matrix.support == 'advisory'"

  for artifact in phase192-admin-playwright-report phase192-admin-playwright-evidence phase192-generated-evidence; do
    require_source_fixed "Phase 192 artifacts" "$(job_body admin-hardening-guardrails)" "$artifact"
  done
  for command in "bash scripts/ci/accrue_host_uat.sh" "cd examples/accrue_host && mix verify.full" "npm ci" "npm run e2e:install" "accrue_host_verify_browser.sh"; do
    require_source_fixed "ownership runbook" "$(cat "$ownership_file")" "$command"
  done
  for proof_state in required advisory skipped not-applicable; do
    require_source_fixed "ownership proof taxonomy" "$(cat "$ownership_file")" "$proof_state"
  done

  jq -e '
    .privacy.logs_downloaded == false and
    .privacy.artifact_archives_downloaded == false and
    .privacy.env_values_recorded == false and
    .privacy.raw_payloads_recorded == false and
    .required_check_snapshot.rules_response_state == "ok" and
    .required_check_snapshot.classic_response_state == "not-found" and
    .required_check_snapshot.enforcement_state == "none-enforced" and
    (.required_check_snapshot.rules | length == 0) and
    (.required_check_snapshot.classic_checks | length == 0) and
    (.phase_227_selection_gate.required_evidence_fields | sort == ["affected_critical_path_stage", "baseline_median_or_range", "eligible_run_ids", "json_paths"]) and
    (.phase_227_selection_gate.candidates | length >= 1) and
    all(.phase_227_selection_gate.candidates[]; (.eligible_run_ids | length > 0) and (.json_paths | length > 0) and (.affected_critical_path_stage | type == "string") and (.baseline_median_or_range | type == "string"))
  ' "$canonical_input" >/dev/null || fail "baseline privacy, provider snapshot, or Phase 227 selection contract failed"
}

validate_input() {
  local candidate="$1"
  [ -f "$candidate" ] || fail "missing baseline input: ${candidate#$root_dir/}"
  jq -e '
    .schema_version == 1 and
    (.repository | type == "string" and test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) and
    (.privacy.logs_downloaded == false and .privacy.artifact_archives_downloaded == false and .privacy.env_values_recorded == false and .privacy.raw_payloads_recorded == false) and
    (.required_check_snapshot.enforcement_state == "none-enforced" or .required_check_snapshot.enforcement_state == "enforced") and
    (.required_check_snapshot.rules_response_state == "ok") and
    ((.required_check_snapshot.classic_response_state == "ok") or (.required_check_snapshot.classic_response_state == "not-found")) and
    (if .required_check_snapshot.enforcement_state == "none-enforced" then ((.required_check_snapshot.rules | length) == 0 and (.required_check_snapshot.classic_checks | length) == 0 and .required_check_snapshot.classic_response_state == "not-found") else true end) and
    (.runs | type == "array" and length > 0) and
    all(.runs[]; . as $run |
      (.run.id | type == "number") and
      (.run.event | type == "string") and
      (.run.head_sha | type == "string" and test("^[0-9a-f]{40}$")) and
      (.run.attempt | type == "number") and
      (.run.wall_seconds | type == "number" or . == null) and
      (.run.critical_queue_seconds | type == "number" or . == null) and
      (.jobs | type == "array") and
      all(.jobs[];
        (.policy == "required" or .policy == "advisory" or .policy == "conditional") and
        (.proof_state == "proved" or .proof_state == "skipped" or .proof_state == "advisory" or .proof_state == "not-applicable") and
        (.cache_state == "observed-hit" or .cache_state == "observed-miss" or .cache_state == "unknown") and
        (if .proof_state == "proved" then (.policy == "required" and .conclusion == "success" and $run.run.eligible == true and $run.run.attempt == 1) else true end)
      )
    )' "$candidate" >/dev/null || fail "schema, taxonomy, or proof-state contract failed: ${candidate#$root_dir/}"

  if jq -e '.. | objects | to_entries[]? | select((.key | test("(secret|token|env|payload|log|archive|trace|screenshot|server_output)"; "i")) and (.key != "logs_downloaded" and .key != "artifact_archives_downloaded" and .key != "env_values_recorded" and .key != "raw_payloads_recorded"))' "$candidate" >/dev/null; then
    fail "privacy contract rejected forbidden key in ${candidate#$root_dir/}"
  fi
  if jq -e '.. | strings | select(test("https?://[^[:space:]]+\\?"))' "$candidate" >/dev/null; then
    fail "privacy contract rejected query-bearing URL in ${candidate#$root_dir/}"
  fi
}

if [ "$self_test" = true ]; then
  tmp_dir="$(mktemp -d)"
  cleanup() { rm -rf "$tmp_dir"; }
  trap cleanup EXIT
  fixture_dir="$tmp_dir/fixture"; mkdir "$fixture_dir"
  printf '%s\n' '{"id":1,"name":"CI","event":"workflow_dispatch","head_sha":"1111111111111111111111111111111111111111","run_attempt":1,"status":"completed","conclusion":"success","created_at":"2026-08-09T15:56:11Z","updated_at":"2026-08-09T15:56:21Z","html_url":"https://github.com/szTheory/accrue/actions/runs/1"}' >"$fixture_dir/run-1.json"
  printf '%s\n' '{"jobs":[{"id":2,"name":"release-gate (Floor)","status":"completed","conclusion":"success","started_at":"2026-08-09T15:56:12Z","completed_at":"2026-08-09T15:56:20Z","steps":[{"name":"Create accrue PLTs","conclusion":"skipped","started_at":"2026-08-09T15:56:13Z","completed_at":"2026-08-09T15:56:14Z"}]},{"id":3,"name":"release-gate (Primary + Sigra) [advisory]","status":"completed","conclusion":"success","started_at":"2026-08-09T15:56:12Z","completed_at":"2026-08-09T15:56:20Z","steps":[]},{"id":4,"name":"failure-only upload","status":"completed","conclusion":"skipped","started_at":null,"completed_at":null,"steps":[]}]}' >"$fixture_dir/jobs-1.json"
  printf '%s\n' '{"artifacts":[{"id":5,"name":"metadata-only-evidence","size_in_bytes":2,"expires_at":"2026-09-09T15:56:21Z","expired":false}]}' >"$fixture_dir/artifacts-1.json"
  printf '%s\n' '[]' >"$fixture_dir/rules.json"
  printf '%s\n' '{"response_state":"not-found"}' >"$fixture_dir/required_status_checks.json"
  bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 1 --fixture-dir "$fixture_dir" --output "$tmp_dir/safe.json"
  validate_input "$tmp_dir/safe.json"
  jq '.id = 2 | .event = "schedule" | .html_url = "https://github.com/szTheory/accrue/actions/runs/2"' "$fixture_dir/run-1.json" >"$fixture_dir/run-2.json"
  cp "$fixture_dir/jobs-1.json" "$fixture_dir/jobs-2.json"
  cp "$fixture_dir/artifacts-1.json" "$fixture_dir/artifacts-2.json"
  bash "$root_dir/scripts/ci/capture_ci_baseline.sh" --run-id 2 --fixture-dir "$fixture_dir" --output "$tmp_dir/scheduled.json"
  jq -e '.runs[0].jobs[0].proof_state == "not-applicable"' "$tmp_dir/scheduled.json" >/dev/null || fail "event-excluded lane was not not-applicable"
  jq '.runs[0].jobs[0].env = {"BAD_SECRET":"value"}' "$tmp_dir/safe.json" >"$tmp_dir/unsafe.json"
  if (validate_input "$tmp_dir/unsafe.json"); then fail "unsafe synthetic input unexpectedly passed"; fi
  jq '.runs[0].run.url = "https://example.test/run?token=bad"' "$tmp_dir/safe.json" >"$tmp_dir/query-url.json"
  if (validate_input "$tmp_dir/query-url.json"); then fail "query URL synthetic input unexpectedly passed"; fi
  jq -e '[.runs[0].jobs[].proof_state] | index("proved") and index("skipped") and index("advisory")' "$tmp_dir/safe.json" >/dev/null || fail "synthetic proof states incomplete"
  validate_repository_contract
  cp "$ci_file" "$tmp_dir/ci.yml"
  sed -i.bak 's/  host-integration:/  host-integration-renamed:/' "$tmp_dir/ci.yml"
  ci_file="$tmp_dir/ci.yml"
  if (validate_repository_contract); then fail "renamed required job unexpectedly passed"; fi
  ci_file="$root_dir/.github/workflows/ci.yml"
  cp "$ownership_file" "$tmp_dir/ownership.md"
  sed -i.bak 's/npm run e2e:install/npm run e2e-install/g' "$tmp_dir/ownership.md"
  ownership_file="$tmp_dir/ownership.md"
  if (validate_repository_contract); then fail "missing ownership command unexpectedly passed"; fi
  ownership_file="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md"
  jq 'del(.privacy.raw_payloads_recorded)' "$canonical_input" >"$tmp_dir/no-privacy-field.json"
  canonical_input="$tmp_dir/no-privacy-field.json"
  if (validate_repository_contract); then fail "missing privacy field unexpectedly passed"; fi
  canonical_input="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"
  echo "verify_ci_baseline_contract: self-test ok"
  exit 0
fi

validate_input "$input"
validate_repository_contract
echo "verify_ci_baseline_contract: ok"
