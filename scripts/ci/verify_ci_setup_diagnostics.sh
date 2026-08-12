#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
diagnostic="$root_dir/scripts/ci/ci_setup_diagnostic.sh"

fail() {
  echo "verify_ci_setup_diagnostics: $*" >&2
  exit 1
}

[ -x "$diagnostic" ] || fail "missing executable setup diagnostic registry"

assert_registry_contract() {
  local code expected_owner output
  for code in node_missing_or_version npm_lock_or_registry playwright_binary_or_revision linux_browser_dependency browser_launch port_or_server_readiness fixture_or_database host_gate_failure; do
    case "$code" in linux_browser_dependency) expected_owner=CI ;; *) expected_owner=host ;; esac
    output="$("$diagnostic" describe "$code")" || fail "setup code must resolve: $code"
    printf '%s\n' "$output" | grep -Fx "code=$code" >/dev/null || fail "missing stable code: $code"
    printf '%s\n' "$output" | grep -Fx "owner=$expected_owner" >/dev/null || fail "wrong owner for $code"
    printf '%s\n' "$output" | grep -E '^next_command=.{8,}$' >/dev/null || fail "missing narrow repair command for $code"
    printf '%s\n' "$output" | grep -E '^evidence_location=.{4,}$' >/dev/null || fail "missing evidence location for $code"
  done

  if "$diagnostic" describe unknown_setup_code >/dev/null 2>&1; then
    fail "unknown setup codes must fail closed"
  fi
}

assert_node_preflight_fixture() {
  local temp_dir output facts
  temp_dir="$(mktemp -d)"
  facts="$temp_dir/facts.ndjson"
  trap 'rm -rf "$temp_dir"' RETURN

  mkdir -p "$temp_dir/bin"
  cat >"$temp_dir/bin/node" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "$temp_dir/bin/node"

  set +e
  output="$(PATH="$temp_dir/bin:$PATH" ACCRUE_CI_SETUP_FACTS="$facts" bash "$root_dir/scripts/ci/accrue_host_verify_browser.sh" 2>&1)"
  local command_status=$?
  set -e
  [ "$command_status" -ne 0 ] || fail "wrong-major Node fixture must fail"
  printf '%s\n' "$output" | grep -Fx 'SETUP_CODE=node_missing_or_version' >/dev/null ||
    fail "wrong-major Node fixture must preserve the setup code"
  printf '%s\n' "$output" | grep -Fx 'OWNER=host' >/dev/null ||
    fail "wrong-major Node fixture must preserve host ownership"
  grep -Fq '"code":"node_missing_or_version"' "$facts" || fail "Node failure must emit its fact"
}

assert_privacy_rejection() {
  local temp_dir facts
  temp_dir="$(mktemp -d)"
  facts="$temp_dir/facts.ndjson"
  trap 'rm -rf "$temp_dir"' RETURN

  if ACCRUE_CI_SETUP_FACTS="$facts" "$diagnostic" emit node_missing_or_version --node-identity 'https://user:token@example.test' >/dev/null 2>&1; then
    fail "unsafe dynamic values must be rejected"
  fi
  [ ! -s "$facts" ] || fail "unsafe dynamic values must not reach facts"
}

assert_browser_boundary_contract() {
  local browser_script="$root_dir/scripts/ci/accrue_host_verify_browser.sh"
  local wrapper_script="$root_dir/scripts/ci/accrue_host_uat.sh"
  local config="$root_dir/examples/accrue_host/playwright.config.js"
  local temp_dir code output facts command_status

  for code in npm_lock_or_registry playwright_binary_or_revision fixture_or_database browser_launch port_or_server_readiness; do
    grep -Fq "$code" "$browser_script" || fail "browser script must classify $code"
  done
  grep -Fq 'mix verify.full' "$wrapper_script" || fail "wrapper must preserve host proof delegation"
  [ "$(grep -Ec '^[[:space:]]*mix verify\.full$' "$wrapper_script")" -eq 1 ] || fail "wrapper must delegate exactly once"
  grep -Fq 'fullyParallel: false' "$config" || fail "Playwright must stay single-flow"
  grep -Fq ': 1' "$config" || fail "Playwright must retain one worker"
  ! grep -Eq '^[[:space:]]*retries:' "$config" || fail "Playwright retries must remain at the zero default"
  grep -Fq 'trace: "retain-on-failure"' "$config" || fail "failure trace retention changed"
  grep -Fq 'screenshot: "only-on-failure"' "$config" || fail "failure screenshot retention changed"
  grep -Fq 'verify01-admin-a11y.spec.js' "$browser_script" || fail "accessibility evidence comment missing"
  grep -Fq 'npm ci' "$browser_script" || fail "host duplicate npm provisioning must remain"
  grep -Fq 'npm run e2e:install' "$browser_script" || fail "host duplicate browser provisioning must remain"

  temp_dir="$(mktemp -d)"
  facts="$temp_dir/facts.ndjson"
  trap 'rm -rf "$temp_dir"' RETURN
  for code in npm_lock_or_registry playwright_binary_or_revision fixture_or_database browser_launch port_or_server_readiness; do
    set +e
    output="$(ACCRUE_CI_SETUP_FACTS="$facts" ACCRUE_HOST_SETUP_DIAGNOSTIC_FIXTURE="$code" bash "$browser_script" 2>&1)"
    command_status=$?
    set -e
    [ "$command_status" -ne 0 ] || fail "fixture must fail for $code"
    printf '%s\n' "$output" | grep -Fx "SETUP_CODE=$code" >/dev/null || fail "fixture did not classify $code"
    printf '%s\n' "$output" | grep -Fx 'OWNER=host' >/dev/null || fail "fixture ownership drifted for $code"
  done
}

assert_wrapper_diagnostic_contract() {
  local wrapper_script="$root_dir/scripts/ci/accrue_host_uat.sh"
  local temp_dir facts output command_status mix_calls
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  mkdir -p "$temp_dir/bin"
  cat >"$temp_dir/bin/mix" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[ "$1" = "verify.full" ] || exit 64
if [ -n "${ACCRUE_TEST_MIX_CALLS:-}" ]; then
  printf '%s\n' "$*" >>"$ACCRUE_TEST_MIX_CALLS"
fi
case "${ACCRUE_TEST_MIX_MODE:-}" in
  inner_failure)
    "$ACCRUE_TEST_DIAGNOSTIC" emit fixture_or_database --result failure --duration-ms 0 --node-identity fixture --playwright-identity fixture --lockfile-identity fixture --browser-class fixture --cache-state fixture
    exit 73
    ;;
  aggregate_failure) exit 74 ;;
  success) exit 0 ;;
  *) exit 64 ;;
esac
EOF
  chmod +x "$temp_dir/bin/mix"

cat >"$temp_dir/bin/pg_isready" <<'EOF'
#!/usr/bin/env bash
if [ "${ACCRUE_TEST_PG_ISREADY_MODE:-}" = "initial_failure" ]; then
  exit 47
fi
exit 0
EOF
  chmod +x "$temp_dir/bin/pg_isready"

  facts="$temp_dir/initial-readiness.ndjson"
  mix_calls="$temp_dir/initial-readiness-mix-calls.log"
  set +e
  output="$(PATH="$temp_dir/bin:$PATH" ACCRUE_CI_SETUP_FACTS="$facts" ACCRUE_TEST_MIX_CALLS="$mix_calls" ACCRUE_TEST_PG_ISREADY_MODE=initial_failure PGHOST='db.internal.example' PGPORT='6543' PGUSER='billing_user' PGPASSWORD='private-password' PGDATABASE='billing_database' bash "$wrapper_script" 2>&1)"
  command_status=$?
  set -e
  [ "$command_status" -eq 47 ] || fail "initial readiness fixture must preserve pg_isready status"
  [ "$(grep -Fc '"code":"fixture_or_database"' "$facts")" -eq 1 ] || fail "initial readiness fixture must emit exactly one database fact"
  ! grep -Fq '"code":"host_gate_failure"' "$facts" || fail "initial readiness fixture must not add aggregate classification"
  printf '%s\n' "$output" | grep -Fx 'SETUP_CODE=fixture_or_database' >/dev/null || fail "initial readiness fixture must render database setup code"
  printf '%s\n' "$output" | grep -Fx 'OWNER=host' >/dev/null || fail "initial readiness fixture must render host ownership"
  printf '%s\n' "$output" | grep -Fx 'NEXT_COMMAND=cd examples/accrue_host && mix verify.full' >/dev/null || fail "initial readiness fixture must render exact repair command"
  printf '%s\n' "$output" | grep -Fx 'EVIDENCE_LOCATION=local host preflight stderr' >/dev/null || fail "initial readiness fixture must render evidence location"
  printf '%s\n' "$output" | grep -Fx 'FAILED_GATE=host-integration' >/dev/null || fail "initial readiness fixture must preserve FAILED_GATE compatibility"
  [ ! -s "$mix_calls" ] || fail "initial readiness fixture must not invoke mix verify.full"
  for sensitive_value in db.internal.example 6543 billing_user private-password billing_database; do
    ! grep -Fq "$sensitive_value" "$facts" || fail "initial readiness facts must not contain database values"
    ! printf '%s\n' "$output" | grep -Fq "$sensitive_value" || fail "initial readiness output must not contain database values"
  done

  for mode in inner_failure aggregate_failure success; do
    facts="$temp_dir/$mode.ndjson"
    set +e
    output="$(PATH="$temp_dir/bin:$PATH" ACCRUE_CI_SETUP_FACTS="$facts" ACCRUE_TEST_DIAGNOSTIC="$diagnostic" ACCRUE_TEST_MIX_MODE="$mode" bash "$wrapper_script" 2>&1)"
    command_status=$?
    set -e

    case "$mode" in
      inner_failure)
        [ "$command_status" -eq 73 ] || fail "inner fact fixture must preserve delegated status"
        [ "$(grep -Fc '"code":"fixture_or_database"' "$facts")" -eq 1 ] || fail "inner fact fixture must retain exactly one narrower fact"
        ! grep -Fq '"code":"browser_launch"' "$facts" || fail "inner fact fixture must not add browser classification"
        ! grep -Fq '"code":"host_gate_failure"' "$facts" || fail "inner fact fixture must not add aggregate classification"
        ;;
      aggregate_failure)
        [ "$command_status" -eq 74 ] || fail "aggregate fixture must preserve delegated status"
        [ "$(grep -Fc '"code":"host_gate_failure"' "$facts")" -eq 1 ] || fail "aggregate fixture must emit exactly one host-gate fact"
        printf '%s\n' "$output" | grep -Fx 'SETUP_CODE=host_gate_failure' >/dev/null || fail "aggregate fixture must render host-gate code"
        printf '%s\n' "$output" | grep -Fx 'OWNER=host' >/dev/null || fail "aggregate fixture must retain host ownership"
        printf '%s\n' "$output" | grep -Fx 'NEXT_COMMAND=cd examples/accrue_host && mix verify.full' >/dev/null || fail "aggregate fixture must render exact host repair command"
        printf '%s\n' "$output" | grep -Fx 'EVIDENCE_LOCATION=GitHub Actions host-integration command log' >/dev/null || fail "aggregate fixture must render host command log evidence"
        ;;
      success)
        [ "$command_status" -eq 0 ] || fail "successful delegation must exit zero"
        [ ! -s "$facts" ] || fail "successful delegation must not add a failure fact"
        ;;
    esac
    printf '%s\n' "$output" | grep -Fx 'FAILED_GATE=host-integration' >/dev/null || {
      [ "$mode" = success ] || fail "failed delegation must preserve FAILED_GATE compatibility"
    }
  done

  grep -Fq 'mix verify.full' "$wrapper_script" || fail "wrapper must preserve host proof delegation"
  [ "$(grep -Ec '^[[:space:]]*mix verify\.full$' "$wrapper_script")" -eq 1 ] || fail "wrapper must delegate exactly once"
}

assert_workflow_setup_contract() {
  local workflow host_region
  workflow="$(cat "$root_dir/.github/workflows/ci.yml")"
  host_region="$(printf '%s\n' "$workflow" | sed -n '/^  host-integration:/,/^  playwright-e2e:/p')"
  printf '%s\n' "$host_region" | grep -Fq 'id: host_setup_summary' || fail "host setup summary step id missing"
  printf '%s\n' "$host_region" | grep -Fq 'id: host_setup_artifact' || fail "host setup artifact step id missing"
  printf '%s\n' "$host_region" | grep -Fq 'ACCRUE_CI_SETUP_FACTS: ${{ runner.temp }}/' || fail "setup facts must be rooted under runner temp"
  printf '%s\n' "$host_region" | grep -Fq 'accrue-host-ci-setup-facts' || fail "setup artifact name drifted"
}

assert_registry_contract
assert_node_preflight_fixture
assert_privacy_rejection
assert_browser_boundary_contract
assert_wrapper_diagnostic_contract
assert_workflow_setup_contract
echo "verify_ci_setup_diagnostics: ok"
