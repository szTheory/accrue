#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
package_file="$root_dir/accrue_admin/package.json"
runner_file="$root_dir/scripts/ci/verify_phase192_admin_guardrails.sh"
phase191_ax187_file="$root_dir/scripts/ci/verify_phase191_ax187_coverage.mjs"
group_contract_spec="$root_dir/accrue_admin/e2e/admin-group-contracts.spec.js"
phase191_spec="$root_dir/accrue_admin/e2e/admin-page-flow-phase191.spec.js"
a11y_spec="$root_dir/accrue_admin/e2e/admin-a11y.spec.js"
reduced_motion_spec="$root_dir/accrue_admin/e2e/reduced-motion.spec.js"
component_registry_test="$root_dir/accrue_admin/test/accrue_admin/dev/component_registry_test.exs"
component_group_registry_test="$root_dir/accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs"

fail() {
  echo "verify_phase192_guardrail_contract: $*" >&2
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
  local label="$1"
  local source="$2"
  local pattern="$3"

  if printf '%s\n' "$source" | grep -Eiq "$pattern"; then
    fail "forbidden /${pattern}/ found in ${label}"
  fi
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

for file in \
  "$package_file" \
  "$runner_file" \
  "$phase191_ax187_file" \
  "$group_contract_spec" \
  "$phase191_spec" \
  "$a11y_spec" \
  "$reduced_motion_spec" \
  "$component_registry_test" \
  "$component_group_registry_test"
do
  require_file "$file"
done

require_fixed "$runner_file" "cd accrue_admin && npm run baseline:parse"
require_fixed "$runner_file" "node scripts/ci/verify_phase191_ax187_coverage.mjs"
require_fixed "$runner_file" "cd accrue_admin && npm run e2e:group-contracts"
require_fixed "$runner_file" "cd accrue_admin && npm run e2e:phase191"
require_fixed "$runner_file" "cd accrue_admin && npm run e2e:a11y"
require_fixed "$runner_file" "cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1"
require_fixed "$runner_file" "cd accrue_admin && npm run phase192:component-lab"

guardrails_script="$(package_script_value "phase192:guardrails")"
component_lab_script="$(package_script_value "phase192:component-lab")"

printf '%s\n' "$guardrails_script" | grep -Fq "bash ../scripts/ci/verify_phase192_admin_guardrails.sh" ||
  fail "phase192:guardrails must point at ../scripts/ci/verify_phase192_admin_guardrails.sh"

printf '%s\n' "$component_lab_script" | grep -Fq "mix test" ||
  fail "phase192:component-lab must run mix test"
printf '%s\n' "$component_lab_script" | grep -Fq "test/accrue_admin/dev/component_registry_test.exs" ||
  fail "phase192:component-lab must include component_registry_test.exs"
printf '%s\n' "$component_lab_script" | grep -Fq "test/accrue_admin/dev/component_group_registry_test.exs" ||
  fail "phase192:component-lab must include component_group_registry_test.exs"

require_fixed "$package_file" '"phase192:guardrails"'
require_fixed "$package_file" '"phase192:component-lab"'
require_regex "$package_file" '"phase192:guardrails"[[:space:]]*:[[:space:]]*"bash \.\./scripts/ci/verify_phase192_admin_guardrails\.sh"'
require_regex "$package_file" '"phase192:component-lab"[[:space:]]*:[[:space:]]*"mix test .*component_registry_test\.exs .*component_group_registry_test\.exs"'

runner_source="$(cat "$runner_file")"
phase192_script_values="$guardrails_script
$component_lab_script"

forbidden_patterns=(
  'npm run e2e([[:space:]"'\'';&|]|$)'
  'playwright test([[:space:]]+--|[[:space:]]*(["'\'';&|]|$))'
  'score-visuals'
  'baseline:artifacts|baseline-artifacts'
  'screenshot|screenshots'
  'trace|traces'
  'maintainer[[:space:]_-]*sign|sign[[:space:]_-]*off|signoff'
)

for pattern in "${forbidden_patterns[@]}"; do
  require_absent_regex "${runner_file#$root_dir/}" "$runner_source" "$pattern"
  require_absent_regex "accrue_admin/package.json phase192:* scripts" "$phase192_script_values" "$pattern"
done

echo "verify_phase192_guardrail_contract: ok"
