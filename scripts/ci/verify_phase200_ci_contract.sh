#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ci_file="$root_dir/.github/workflows/ci.yml"
runner_file="$root_dir/scripts/ci/verify_phase200_admin_guardrails.sh"
guardrail_contract_file="$root_dir/scripts/ci/verify_phase200_guardrail_contract.sh"

fail() {
  echo "verify_phase200_ci_contract: $*" >&2
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

require_no_broad_playwright() {
  local label="$1"
  local source="$2"

  while IFS= read -r line; do
    if [[ "$line" == *"playwright test"* && "$line" != *"e2e/"* ]]; then
      fail "broad Playwright command in ${label}: ${line}"
    fi
  done <<< "$source"
}

require_order() {
  local label="$1"
  local source="$2"
  local first="$3"
  local second="$4"
  local first_line
  local second_line

  first_line=$(printf '%s\n' "$source" | grep -nF "$first" | head -n 1 | cut -d: -f1)
  second_line=$(printf '%s\n' "$source" | grep -nF "$second" | head -n 1 | cut -d: -f1)

  [ -n "$first_line" ] || fail "missing '${first}' in ${label}"
  [ -n "$second_line" ] || fail "missing '${second}' in ${label}"
  [ "$first_line" -lt "$second_line" ] || fail "expected '${first}' before '${second}' in ${label}"
}

job_body() {
  local job_id="$1"

  awk -v job_id="$job_id" '
    $0 == "  " job_id ":" { in_job = 1 }
    in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" { exit }
    in_job { print }
  ' "$ci_file"
}

for file in "$ci_file" "$runner_file" "$guardrail_contract_file"; do
  require_file "$file"
done

require_fixed "$ci_file" "admin-phase200-guardrails:"
require_fixed "$ci_file" "Admin Phase 200 deterministic guardrails"
require_fixed "$ci_file" "bash scripts/ci/verify_phase200_ci_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase200_guardrail_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase200_admin_guardrails.sh"
require_fixed "$ci_file" "phase200-admin-playwright-report"
require_fixed "$ci_file" "phase200-admin-playwright-evidence"
require_fixed "$ci_file" "phase200-generated-evidence"

phase200_job="$(job_body "admin-phase200-guardrails")"
[ -n "$phase200_job" ] || fail "could not extract admin-phase200-guardrails job"
phase200_run_lines="$(printf '%s\n' "$phase200_job" | grep -E '^[[:space:]]*run:' || true)"

for needle in \
  "if: github.event_name != 'schedule'" \
  "runs-on: ubuntu-24.04" \
  "image: postgres:15" \
  "MIX_ENV: test" \
  "PGUSER: postgres" \
  "PGPASSWORD: postgres" \
  "PGHOST: localhost" \
  "ACCRUE_ADMIN_E2E_PORT: 4019" \
  "uses: actions/checkout@v6" \
  "uses: erlef/setup-beam@v1" \
  "otp-version: '28.0'" \
  "elixir-version: '1.19.5'" \
  "mix local.hex 2.4.2 --force" \
  "uses: actions/setup-node@v6" \
  "node-version: '22'" \
  "cache-dependency-path: accrue_admin/package-lock.json" \
  "phase200-admin-deps" \
  "cd accrue_admin && mix deps.get" \
  "cd accrue_admin && mix compile --warnings-as-errors" \
  "cd accrue_admin && npm ci" \
  "cd accrue_admin && npx playwright install --with-deps chromium" \
  "bash scripts/ci/verify_phase200_ci_contract.sh" \
  "bash scripts/ci/verify_phase200_guardrail_contract.sh" \
  "bash scripts/ci/verify_phase200_admin_guardrails.sh" \
  "phase200-admin-playwright-report" \
  "path: accrue_admin/playwright-report" \
  "phase200-admin-playwright-evidence" \
  "path: accrue_admin/test-results" \
  "phase200-generated-evidence" \
  ".planning/phases/200-idempotent-verification-sign-off/baseline.union.cells.json" \
  ".planning/phases/200-idempotent-verification-sign-off/final.cells.json" \
  ".planning/phases/200-idempotent-verification-sign-off/scorecard.delta.json" \
  ".planning/phases/200-idempotent-verification-sign-off/regressions.ndjson" \
  ".planning/phases/200-idempotent-verification-sign-off/artifacts.manifest.json" \
  ".planning/phases/200-idempotent-verification-sign-off/200-SCORECARD.md" \
  ".planning/phases/200-idempotent-verification-sign-off/200-STORYBOOK-COVERAGE.md" \
  ".planning/phases/200-idempotent-verification-sign-off/200-VERIFICATION.md" \
  ".planning/phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md" \
  ".planning/phases/200-idempotent-verification-sign-off/judge.findings.json" \
  "if-no-files-found: ignore"
do
  require_source_fixed "admin-phase200-guardrails job" "$phase200_job" "$needle"
done

require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'name: Phase 200 CI contract'
require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'name: Phase 200 local guardrail contract'
require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'name: Run Phase 200 deterministic guardrails'
require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'if: always\(\)'

require_order "admin-phase200-guardrails job" "$phase200_job" \
  "cd accrue_admin && npx playwright install --with-deps chromium" \
  "bash scripts/ci/verify_phase200_ci_contract.sh"
require_order "admin-phase200-guardrails job" "$phase200_job" \
  "bash scripts/ci/verify_phase200_ci_contract.sh" \
  "bash scripts/ci/verify_phase200_guardrail_contract.sh"
require_order "admin-phase200-guardrails job" "$phase200_job" \
  "bash scripts/ci/verify_phase200_guardrail_contract.sh" \
  "bash scripts/ci/verify_phase200_admin_guardrails.sh"

for pattern in \
  'npm run e2e([[:space:]"'\'';&|]|$)' \
  'playwright test([[:space:]]+--|[[:space:]]*(["'\'';&|]|$))' \
  'score-visuals' \
  'baseline:artifacts|baseline-artifacts' \
  'phase200-judge\.mjs' \
  'phase200-signoff\.mjs' \
  'screenshot[[:space:]_-]*capture|capture[[:space:]_-]*screenshot' \
  'trace[[:space:]_-]*capture|capture[[:space:]_-]*trace' \
  'maintainer[[:space:]_-]*sign|human[[:space:]_-]*sign'
do
  require_source_absent_regex "admin-phase200-guardrails run commands" "$phase200_run_lines" "$pattern"
done

require_no_broad_playwright "admin-phase200-guardrails run commands" "$phase200_run_lines"

annotation_job="$(job_body "annotation-sweep")"
[ -n "$annotation_job" ] || fail "could not extract annotation-sweep job"
require_source_fixed "annotation-sweep job" "$annotation_job" "admin-phase200-guardrails"
require_source_fixed "annotation-sweep job" "$annotation_job" "bash scripts/ci/annotation_sweep.sh"

echo "verify_phase200_ci_contract: ok"
