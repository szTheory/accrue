#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ci_file="$root_dir/.github/workflows/ci.yml"
package_file="$root_dir/accrue_admin/package.json"
ledger_verifier="$root_dir/scripts/ci/verify_ratchet_ledger.mjs"
signoff_verifier="$root_dir/scripts/ci/verify_ui_ratchet_signoff.mjs"
contract_file="$root_dir/scripts/ci/verify_admin_ui_ratchet_ci_contract.sh"

fail() {
  echo "verify_admin_ui_ratchet_ci_contract: $*" >&2
  exit 1
}

require_file() {
  local file="$1"
  [ -f "$file" ] || fail "missing file: ${file#$root_dir/}"
}

require_fixed() {
  local file="$1"
  local needle="$2"
  grep -Fq "$needle" "$file" || fail "missing '${needle}' in ${file#$root_dir/}"
}

require_source_fixed() {
  local label="$1"
  local source="$2"
  local needle="$3"

  printf '%s\n' "$source" | grep -Fq "$needle" ||
    fail "missing '${needle}' in ${label}"
}

require_source_regex() {
  local label="$1"
  local source="$2"
  local pattern="$3"

  printf '%s\n' "$source" | grep -Eq "$pattern" ||
    fail "missing /${pattern}/ in ${label}"
}

require_source_absent_regex() {
  local label="$1"
  local source="$2"
  local pattern="$3"

  if printf '%s\n' "$source" | grep -Eiq "$pattern"; then
    fail "forbidden /${pattern}/ found in ${label}"
  fi
}

job_body() {
  local job_id="$1"

  awk -v job_id="$job_id" '
    $0 == "  " job_id ":" { in_job = 1 }
    in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" { exit }
    in_job { print }
  ' "$ci_file"
}

package_script_value() {
  local script_name="$1"

  node -e '
    const fs = require("fs");
    const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const script = pkg.scripts && pkg.scripts[process.argv[2]];
    if (!script) process.exit(1);
    process.stdout.write(script);
  ' "$package_file" "$script_name" || fail "missing package script: ${script_name}"
}

for file in "$ci_file" "$package_file" "$ledger_verifier" "$signoff_verifier" "$contract_file"; do
  require_file "$file"
done

require_fixed "$ci_file" "admin-ui-ratchet-guardrails:"
require_fixed "$ci_file" "Admin UI ratchet guardrails"
require_fixed "$ci_file" "bash scripts/ci/verify_admin_ui_ratchet_ci_contract.sh"

ratchet_job="$(job_body "admin-ui-ratchet-guardrails")"
[ -n "$ratchet_job" ] || fail "could not extract admin-ui-ratchet-guardrails job"

for needle in \
  "name: Admin UI ratchet guardrails" \
  "if: github.event_name != 'schedule'" \
  "runs-on: ubuntu-24.04" \
  "uses: actions/checkout@v6" \
  "uses: actions/setup-node@v6" \
  "node-version: '22'" \
  "cache: npm" \
  "cache-dependency-path: accrue_admin/package-lock.json" \
  "cd accrue_admin && npm ci" \
  "cd accrue_admin && npm run ratchet:ledger:self-test" \
  "cd accrue_admin && npm run ratchet:ledger:verify-frozen" \
  "cd accrue_admin && npm run ratchet:signoff:self-test" \
  "cd accrue_admin && npm run ratchet:signoff" \
  "cd accrue_admin && npm run ratchet:ci-contract" \
  "PASS - ANTHROPIC_API_KEY is not required for this job" \
  "PASS - deterministic ratchet guardrails are clean" \
  "PASS - finding-regressions.ndjson is 0 bytes" \
  "PASS - independent recompute matches ledger.baseline.json" \
  "PASS - synthetic count increase blocks the gate" \
  "PASS - regressed lens count increase blocks the gate" \
  "PASS - admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift are green" \
  "PASS - accrue_admin.css is fresh" \
  "phase208-ratchet-evidence" \
  "accrue_admin/e2e/ratchet/ledger.baseline.json" \
  "accrue_admin/e2e/ratchet/finding-regressions.ndjson" \
  "accrue_admin/e2e/ratchet/rounds.ndjson" \
  ".planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/UI-RATCHET-SIGN-OFF.md" \
  "if-no-files-found: ignore"
do
  require_source_fixed "admin-ui-ratchet-guardrails job" "$ratchet_job" "$needle"
done

require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Install admin Node dependencies'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Run ratchet ledger self-tests'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Verify frozen ratchet evidence'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Verify UI ratchet sign-off'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Phase 208 CI contract'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Ratchet status summary'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'uses: actions/upload-artifact@v7'

sanitized_job="$(printf '%s\n' "$ratchet_job" | grep -Fv "PASS - ANTHROPIC_API_KEY is not required for this job")"
for pattern in \
  'continue-on-error:[[:space:]]*true' \
  'secrets\.' \
  'ANTHROPIC_API_KEY' \
  'ratchet-propose' \
  'ratchet-verify' \
  'ui\.round' \
  'ui\.fix' \
  'playwright[[:space:]]+test' \
  'screenshot[[:space:]_-]*capture|capture[[:space:]_-]*screenshot' \
  'trace[[:space:]_-]*capture|capture[[:space:]_-]*trace' \
  'browser[[:space:]_-]*capture|capture[[:space:]_-]*browser' \
  '(^|[[:space:]])--freeze([[:space:]]|$)'
do
  require_source_absent_regex "admin-ui-ratchet-guardrails job" "$sanitized_job" "$pattern"
done

for script_name in \
  "ratchet:ledger:verify-frozen" \
  "ratchet:signoff:self-test" \
  "ratchet:signoff" \
  "ratchet:ci-contract"
do
  package_script_value "$script_name" >/dev/null
done

ledger_verify_script="$(package_script_value "ratchet:ledger:verify-frozen")"
signoff_self_test_script="$(package_script_value "ratchet:signoff:self-test")"
signoff_script="$(package_script_value "ratchet:signoff")"
ci_contract_script="$(package_script_value "ratchet:ci-contract")"

require_source_fixed "ratchet:ledger:verify-frozen package script" "$ledger_verify_script" "node ../scripts/ci/verify_ratchet_ledger.mjs --verify-frozen"
require_source_fixed "ratchet:signoff:self-test package script" "$signoff_self_test_script" "node ../scripts/ci/verify_ui_ratchet_signoff.mjs --self-test"
require_source_fixed "ratchet:signoff package script" "$signoff_script" "node ../scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept"
require_source_fixed "ratchet:ci-contract package script" "$ci_contract_script" "bash ../scripts/ci/verify_admin_ui_ratchet_ci_contract.sh"

package_scripts="$ledger_verify_script
$signoff_self_test_script
$signoff_script
$ci_contract_script"

for pattern in \
  '(^|[[:space:]])--freeze([[:space:]]|$)' \
  'ui\.round' \
  'ui\.fix' \
  'ratchet-propose' \
  'ratchet-verify'
do
  require_source_absent_regex "Phase 208 package scripts" "$package_scripts" "$pattern"
done

annotation_job="$(job_body "annotation-sweep")"
[ -n "$annotation_job" ] || fail "could not extract annotation-sweep job"
require_source_fixed "annotation-sweep job" "$annotation_job" "admin-ui-ratchet-guardrails"
require_source_fixed "annotation-sweep job" "$annotation_job" "bash scripts/ci/annotation_sweep.sh"
require_source_regex "annotation-sweep job" "$annotation_job" 'annotation_sweep\.sh .*admin-ui-ratchet-guardrails|admin-ui-ratchet-guardrails.*annotation_sweep\.sh'

echo "verify_admin_ui_ratchet_ci_contract: ok"
