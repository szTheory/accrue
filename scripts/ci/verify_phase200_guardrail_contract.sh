#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
package_file="$root_dir/accrue_admin/package.json"
runner_file="$root_dir/scripts/ci/verify_phase200_admin_guardrails.sh"
package_docs_file="$root_dir/scripts/ci/verify_package_docs.sh"
storybook_spec="$root_dir/accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js"
page_flow_spec="$root_dir/accrue_admin/e2e/admin-page-flow-phase200.spec.js"
phase199_spec="$root_dir/accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js"
reduced_motion_spec="$root_dir/accrue_admin/e2e/reduced-motion.spec.js"
scorecard_generator="$root_dir/accrue_admin/e2e/phase200-scorecard.mjs"
scorecard_verifier="$root_dir/scripts/ci/verify_phase200_scorecard.mjs"
signoff_verifier="$root_dir/scripts/ci/verify_phase200_signoff.mjs"
component_registry_test="$root_dir/accrue_admin/test/accrue_admin/dev/component_registry_test.exs"
component_group_registry_test="$root_dir/accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs"
storybook_coverage_test="$root_dir/accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs"
storybook_asset_test="$root_dir/accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs"
theme_test="$root_dir/accrue_admin/test/accrue_admin/theme_test.exs"

fail() {
  echo "verify_phase200_guardrail_contract: $*" >&2
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

require_no_broad_playwright() {
  local label="$1"
  local source="$2"

  while IFS= read -r line; do
    if [[ "$line" == *"playwright test"* && "$line" != *"e2e/"* ]]; then
      fail "broad Playwright command in ${label}: ${line}"
    fi
  done <<< "$source"
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
  "$package_docs_file" \
  "$storybook_spec" \
  "$page_flow_spec" \
  "$phase199_spec" \
  "$reduced_motion_spec" \
  "$scorecard_generator" \
  "$scorecard_verifier" \
  "$signoff_verifier" \
  "$component_registry_test" \
  "$component_group_registry_test" \
  "$storybook_coverage_test" \
  "$storybook_asset_test" \
  "$theme_test"
do
  require_file "$file"
done

require_fixed "$runner_file" "bash scripts/ci/verify_package_docs.sh"
require_fixed "$runner_file" "cd accrue_admin && npm run phase200:storybook"
require_fixed "$runner_file" "cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs"
require_fixed "$runner_file" "cd accrue_admin && npm run e2e:group-contracts"
require_fixed "$runner_file" "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-page-flow-phase200.spec.js --workers=1"
require_fixed "$runner_file" "cd accrue_admin && npm run e2e:phase199"
require_fixed "$runner_file" "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1"
require_fixed "$runner_file" "cd accrue_admin && npm run phase200:scorecard"
require_fixed "$runner_file" "cd accrue_admin && npm run phase200:signoff"

storybook_script="$(package_script_value "phase200:storybook")"
scorecard_script="$(package_script_value "phase200:scorecard")"
signoff_script="$(package_script_value "phase200:signoff")"
guardrails_script="$(package_script_value "phase200:guardrails")"

printf '%s\n' "$storybook_script" | grep -Fq "test/accrue_admin/dev/storybook_coverage_test.exs" ||
  fail "phase200:storybook must run storybook_coverage_test.exs"
printf '%s\n' "$storybook_script" | grep -Fq "test/accrue_admin/dev/storybook_asset_test.exs" ||
  fail "phase200:storybook must run storybook_asset_test.exs"
printf '%s\n' "$storybook_script" | grep -Fq "test/accrue_admin/theme_test.exs" ||
  fail "phase200:storybook must run theme_test.exs"
printf '%s\n' "$storybook_script" | grep -Fq "e2e/admin-storybook-a11y-phase200.spec.js" ||
  fail "phase200:storybook must run rendered Storybook Phase 200 Playwright spec"

printf '%s\n' "$scorecard_script" | grep -Fq "node e2e/phase200-scorecard.mjs" ||
  fail "phase200:scorecard must regenerate final scorecard artifacts"
printf '%s\n' "$scorecard_script" | grep -Fq "node ../scripts/ci/verify_phase200_scorecard.mjs" ||
  fail "phase200:scorecard must run the full scorecard verifier"

printf '%s\n' "$signoff_script" | grep -Fq "node ../scripts/ci/verify_phase200_signoff.mjs --require-accept" ||
  fail "phase200:signoff must require ACCEPT in CI/final guardrails"
printf '%s\n' "$signoff_script" | grep -Fq "node ../scripts/ci/generate_phase200_closeout_reports.mjs --record-final-statuses" ||
  fail "phase200:signoff must regenerate closeout command statuses before final ACCEPT verification"

printf '%s\n' "$guardrails_script" | grep -Fq "bash ../scripts/ci/verify_phase200_admin_guardrails.sh" ||
  fail "phase200:guardrails must point at ../scripts/ci/verify_phase200_admin_guardrails.sh"

require_fixed "$package_file" '"phase200:storybook"'
require_fixed "$package_file" '"phase200:scorecard"'
require_fixed "$package_file" '"phase200:signoff"'
require_fixed "$package_file" '"phase200:guardrails"'
require_regex "$package_file" '"phase200:guardrails"[[:space:]]*:[[:space:]]*"bash \.\./scripts/ci/verify_phase200_admin_guardrails\.sh"'

runner_source="$(cat "$runner_file")"
phase200_script_values="$storybook_script
$scorecard_script
$signoff_script
$guardrails_script"

for pattern in \
  'npm run e2e([[:space:]"'\'';&|]|$)' \
  'score-visuals' \
  'baseline:artifacts|baseline-artifacts' \
  'phase200-judge\.mjs' \
  'phase200-signoff\.mjs' \
  'screenshot[[:space:]_-]*capture|capture[[:space:]_-]*screenshot' \
  'trace[[:space:]_-]*capture|capture[[:space:]_-]*trace' \
  'maintainer[[:space:]_-]*sign|human[[:space:]_-]*sign'
do
  require_absent_regex "${runner_file#$root_dir/}" "$runner_source" "$pattern"
  require_absent_regex "accrue_admin/package.json phase200:* scripts" "$phase200_script_values" "$pattern"
done

require_no_broad_playwright "${runner_file#$root_dir/}" "$runner_source"
require_no_broad_playwright "accrue_admin/package.json phase200:* scripts" "$phase200_script_values"

echo "verify_phase200_guardrail_contract: ok"
