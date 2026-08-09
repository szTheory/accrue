#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
canonical_input="$root_dir/.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json"

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
  echo "verify_ci_baseline_contract: self-test ok"
  exit 0
fi

validate_input "$input"
echo "verify_ci_baseline_contract: ok"
