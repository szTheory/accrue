#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
diagnostic="$root_dir/scripts/ci/ci_setup_diagnostic.sh"

fail() {
  echo "verify_ci_setup_diagnostics: $*" >&2
  exit 1
}

[ -x "$diagnostic" ] || fail "missing executable setup diagnostic registry"

assert_node_contract() {
  local output
  output="$("$diagnostic" describe node_missing_or_version)" || fail "node setup code must resolve"

  printf '%s\n' "$output" | grep -Fx 'code=node_missing_or_version' >/dev/null ||
    fail "missing stable Node code"
  printf '%s\n' "$output" | grep -Fx 'owner=host' >/dev/null ||
    fail "Node preflight must be host-owned"
  printf '%s\n' "$output" | grep -Fx 'next_command=Install Node 22 with your version manager, then run mix verify.full.' >/dev/null ||
    fail "Node preflight must provide the fixed repair command"
  printf '%s\n' "$output" | grep -Fx 'evidence_location=local host preflight stderr' >/dev/null ||
    fail "Node preflight must provide its evidence location"
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

assert_node_contract
assert_node_preflight_fixture
assert_privacy_rejection
echo "verify_ci_setup_diagnostics: ok"
