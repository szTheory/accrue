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
  for code in node_missing_or_version npm_lock_or_registry playwright_binary_or_revision linux_browser_dependency browser_launch port_or_server_readiness fixture_or_database; do
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

  for code in npm_lock_or_registry playwright_binary_or_revision fixture_or_database browser_launch port_or_server_readiness; do
    grep -Fq "$code" "$browser_script" || fail "browser script must classify $code"
  done
  grep -Fq 'mix verify.full' "$wrapper_script" || fail "wrapper must preserve host proof delegation"
  [ "$(grep -Fc 'mix verify.full' "$wrapper_script")" -eq 1 ] || fail "wrapper must delegate exactly once"
  grep -Fq 'fullyParallel: false' "$config" || fail "Playwright must stay single-flow"
  grep -Fq ': 1' "$config" || fail "Playwright must retain one worker"
  ! grep -Eq '^[[:space:]]*retries:' "$config" || fail "Playwright retries must remain at the zero default"
  grep -Fq 'trace: "retain-on-failure"' "$config" || fail "failure trace retention changed"
  grep -Fq 'screenshot: "only-on-failure"' "$config" || fail "failure screenshot retention changed"
  grep -Fq 'verify01-admin-a11y.spec.js' "$browser_script" || fail "accessibility evidence comment missing"
  grep -Fq 'npm ci' "$browser_script" || fail "host duplicate npm provisioning must remain"
  grep -Fq 'npm run e2e:install' "$browser_script" || fail "host duplicate browser provisioning must remain"
}

assert_registry_contract
assert_node_preflight_fixture
assert_privacy_rejection
assert_browser_boundary_contract
echo "verify_ci_setup_diagnostics: ok"
