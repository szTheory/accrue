#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
phase_dir="$root_dir/.planning/phases/190-navigation-data-display-meta-component-cohesion"
uat_file="$phase_dir/190-UAT.md"
verification_file="$phase_dir/190-VERIFICATION.md"
handoff_file="$phase_dir/190-PHASE-191-HANDOFF.md"
ci_file="$root_dir/.github/workflows/ci.yml"
package_file="$root_dir/accrue_admin/package.json"

fail() {
  echo "verify_phase190_automation_contract: $*" >&2
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

require_regex() {
  local file="$1"
  local pattern="$2"
  grep -Eq "$pattern" "$file" || fail "missing /${pattern}/ in ${file#$root_dir/}"
}

require_absent_regex() {
  local file="$1"
  local pattern="$2"
  if grep -Eiq "$pattern" "$file"; then
    fail "forbidden /${pattern}/ found in ${file#$root_dir/}"
  fi
}

for file in "$uat_file" "$verification_file" "$handoff_file" "$ci_file" "$package_file"; do
  require_file "$file"
done

require_fixed "$package_file" '"e2e:group-contracts"'
require_fixed "$ci_file" "admin-group-contracts:"
require_fixed "$ci_file" "npm run e2e:group-contracts"
require_fixed "$ci_file" "verify_phase190_automation_contract.sh"

require_regex "$uat_file" '^status: complete$'
require_regex "$uat_file" '^mode: shift-left$'
require_regex "$uat_file" '^human_steps_required: 0$'
require_fixed "$uat_file" "## Automation Map"
require_fixed "$uat_file" "npm run e2e:group-contracts"
require_fixed "$uat_file" "scripts/ci/verify_phase190_automation_contract.sh"
require_absent_regex "$uat_file" 'awaiting: user response|result: pending|status: testing'

pass_count="$(grep -Ec '^result: pass$' "$uat_file")"
[ "$pass_count" -ge 2 ] || fail "expected at least two passed UAT checks, found $pass_count"

require_regex "$verification_file" '^status: complete$'
require_fixed "$verification_file" 'score: "5/5 must-haves verified"'
require_fixed "$verification_file" "Automated Verification Closure"
require_fixed "$verification_file" "npm run e2e:group-contracts"
require_fixed "$verification_file" "verify_phase190_automation_contract.sh"
require_absent_regex "$verification_file" 'status: human_needed|HUMAN NEEDED|Human Verification Required|why_human'

for tag in \
  focus-trap \
  focus-restore \
  escape \
  click-outside \
  scroll-reachability \
  overlay-position \
  liveview-patch-focus \
  fixture-gaps \
  microcopy
do
  require_fixed "$handoff_file" "$tag"
done

require_fixed "$handoff_file" "npm run e2e:group-contracts"
require_absent_regex "$handoff_file" 'blocked before tests|e2e server migration startup returning|killed'

echo "verify_phase190_automation_contract: ok"
