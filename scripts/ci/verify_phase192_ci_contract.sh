#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ci_file="$root_dir/.github/workflows/ci.yml"
runner_file="$root_dir/scripts/ci/verify_phase192_admin_guardrails.sh"
guardrail_contract_file="$root_dir/scripts/ci/verify_phase192_guardrail_contract.sh"

fail() {
  echo "verify_phase192_ci_contract: $*" >&2
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

for file in "$ci_file" "$runner_file" "$guardrail_contract_file"; do
  require_file "$file"
done

require_fixed "$ci_file" "admin-group-contracts:"
require_fixed "$ci_file" "cd accrue_admin && npm run e2e:group-contracts"
require_fixed "$ci_file" "admin-hardening-guardrails:"
require_fixed "$ci_file" "Admin hardening guardrails (Phase 192)"
require_fixed "$ci_file" "bash scripts/ci/verify_phase192_ci_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase192_guardrail_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase192_admin_guardrails.sh"
require_fixed "$ci_file" "phase192-admin-playwright-report"
require_fixed "$ci_file" "phase192-admin-playwright-evidence"
require_fixed "$ci_file" "phase192-generated-evidence"

phase192_job="$(job_body "admin-hardening-guardrails")"
[ -n "$phase192_job" ] || fail "could not extract admin-hardening-guardrails job"
phase192_run_lines="$(printf '%s\n' "$phase192_job" | grep -E '^[[:space:]]*run:' || true)"
generated_evidence_step="$(printf '%s\n' "$phase192_job" | awk '
  /name: Upload Phase 192 generated evidence/ { in_step = 1 }
  in_step { print }
  in_step && /if-no-files-found:/ { exit }
')"
[ -n "$generated_evidence_step" ] || fail "could not extract Phase 192 generated-evidence step"

for needle in \
  "if: github.event_name != 'schedule'" \
  "runs-on: ubuntu-24.04" \
  "image: postgres:15" \
  "MIX_ENV: test" \
  "PGUSER: postgres" \
  "PGPASSWORD: postgres" \
  "PGHOST: localhost" \
  "ACCRUE_ADMIN_E2E_PORT: 4018" \
  "uses: actions/checkout@v6" \
  "uses: erlef/setup-beam@v1" \
  "otp-version: '28.0'" \
  "elixir-version: '1.19.5'" \
  "mix local.hex 2.4.2 --force" \
  "uses: actions/setup-node@v6" \
  "node-version: '22'" \
  "cache-dependency-path: accrue_admin/package-lock.json" \
  "phase192-admin-deps" \
  "cd accrue_admin && mix deps.get" \
  "cd accrue_admin && mix compile --warnings-as-errors" \
  "cd accrue_admin && npm ci" \
  "cd accrue_admin && npx playwright install --with-deps chromium" \
  "bash scripts/ci/verify_phase192_ci_contract.sh" \
  "bash scripts/ci/verify_phase192_guardrail_contract.sh" \
  "bash scripts/ci/verify_phase192_admin_guardrails.sh" \
  "phase192-admin-playwright-report" \
  "path: accrue_admin/playwright-report" \
  "phase192-admin-playwright-evidence" \
  "path: accrue_admin/test-results" \
  "phase192-generated-evidence" \
  ".planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/final.cells.json" \
  ".planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/scorecard.delta.json" \
  ".planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/regressions.ndjson" \
  ".planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/artifacts.manifest.json" \
  ".planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-SCORECARD.md"
do
  require_source_fixed "admin-hardening-guardrails job" "$phase192_job" "$needle"
done

require_source_fixed "Phase 192 generated-evidence step" "$generated_evidence_step" "if: always()"
require_source_fixed "Phase 192 generated-evidence step" "$generated_evidence_step" "if-no-files-found: error"
require_source_absent_regex \
  "Phase 192 generated-evidence step" \
  "$generated_evidence_step" \
  '\\.planning/phases/192-idempotent-verification-sign-off/'

require_source_regex "admin-hardening-guardrails job" "$phase192_job" 'name: Phase 192 CI contract'
require_source_regex "admin-hardening-guardrails job" "$phase192_job" 'name: Phase 192 local guardrail contract'
require_source_regex "admin-hardening-guardrails job" "$phase192_job" 'name: Run Phase 192 admin hardening guardrails'
require_source_regex "admin-hardening-guardrails job" "$phase192_job" 'if: always\(\)'

for pattern in \
  'npm run e2e([[:space:]"'\'';&|]|$)' \
  'playwright test([[:space:]]+--|[[:space:]]*(["'\'';&|]|$))' \
  'score-visuals' \
  'baseline:artifacts|baseline-artifacts' \
  'screenshot[[:space:]_-]*capture|capture[[:space:]_-]*screenshot' \
  'trace[[:space:]_-]*capture|capture[[:space:]_-]*trace' \
  'maintainer[[:space:]_-]*sign|sign[[:space:]_-]+off|sign[[:space:]_]+off|signoff'
do
  require_source_absent_regex "admin-hardening-guardrails run commands" "$phase192_run_lines" "$pattern"
done

annotation_job="$(job_body "annotation-sweep")"
[ -n "$annotation_job" ] || fail "could not extract annotation-sweep job"
require_source_fixed "annotation-sweep job" "$annotation_job" "admin-group-contracts"
require_source_fixed "annotation-sweep job" "$annotation_job" "admin-hardening-guardrails"
require_source_fixed "annotation-sweep job" "$annotation_job" "bash scripts/ci/annotation_sweep.sh"

echo "verify_phase192_ci_contract: ok"
