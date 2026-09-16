#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ci_file="$root_dir/.github/workflows/ci.yml"
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

require_source_absent_fixed() {
  local label="$1"
  local source="$2"
  local needle="$3"

  if printf '%s\n' "$source" | grep -Fq "$needle"; then
    fail "forbidden '${needle}' found in ${label}"
  fi
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

# Extract a single step's body (from its "- name: <step_name>" line up to,
# but excluding, the next "      - name:"/"      - uses:" sibling step line)
# out of an already-extracted job body. Used where a needle must be scoped to
# one step rather than merely present anywhere in the job.
step_body() {
  local job_source="$1"
  local step_name="$2"

  printf '%s\n' "$job_source" | awk -v step_name="- name: $step_name" '
    index($0, step_name) { in_step = 1; print; next }
    in_step && $0 ~ /^      - (name|uses):/ { exit }
    in_step { print }
  '
}

for file in "$ci_file" "$ledger_verifier" "$signoff_verifier" "$contract_file"; do
  require_file "$file"
done

# D-23 (232-06): the machinery self-tests (ledger self-test, sign-off
# self-test, this CI-contract check itself) live in a BLOCKING job with no
# continue-on-error at job or step level. Only the two steps whose subject is
# the deliberately-parked ledger stay in the non-blocking job below.
require_fixed "$ci_file" "admin-ui-ratchet-selftests:"
require_fixed "$ci_file" "name: Admin UI ratchet self-tests"

selftests_job="$(job_body "admin-ui-ratchet-selftests")"
[ -n "$selftests_job" ] || fail "could not extract admin-ui-ratchet-selftests job"

for needle in \
  "name: Admin UI ratchet self-tests" \
  "if: github.event_name != 'schedule'" \
  "runs-on: ubuntu-24.04" \
  "uses: actions/checkout@v6" \
  "uses: actions/setup-node@v6" \
  "node-version: '22'" \
  "cache: npm" \
  "cache-dependency-path: accrue_admin/package-lock.json" \
  "cd accrue_admin && npm ci" \
  "cd accrue_admin && npm run ratchet:ledger:self-test" \
  "cd accrue_admin && npm run ratchet:signoff:self-test" \
  "cd accrue_admin && npm run ratchet:ci-contract" \
  "name: Parked-lane expiry trigger (D-26)"
do
  require_source_fixed "admin-ui-ratchet-selftests job" "$selftests_job" "$needle"
done

require_source_absent_fixed "admin-ui-ratchet-selftests job" "$selftests_job" "continue-on-error"
require_source_absent_fixed "admin-ui-ratchet-selftests job" "$selftests_job" "cd accrue_admin && npm run ratchet:ledger:verify-frozen"

# D-26 (232-06): the expiry trigger step must be always-run (its whole point
# is to fail even when the ledger, at rest, is not yet frozen) and it must
# read the real ledger.frozen flag plus the ship-window row's waived status --
# never a literal hardcoded outcome.
expiry_step="$(step_body "$selftests_job" "Parked-lane expiry trigger (D-26)")"
[ -n "$expiry_step" ] || fail "could not extract Parked-lane expiry trigger (D-26) step"
require_source_fixed "Parked-lane expiry trigger (D-26) step" "$expiry_step" "if: always()"
require_source_fixed "Parked-lane expiry trigger (D-26) step" "$expiry_step" "ledger.frozen"
require_source_fixed "Parked-lane expiry trigger (D-26) step" "$expiry_step" "row.id === 11"

require_fixed "$ci_file" "admin-ui-ratchet-guardrails:"
require_fixed "$ci_file" "Admin UI ratchet guardrails"

ratchet_job="$(job_body "admin-ui-ratchet-guardrails")"
[ -n "$ratchet_job" ] || fail "could not extract admin-ui-ratchet-guardrails job"

for needle in \
  "name: Admin UI ratchet guardrails" \
  "if: github.event_name != 'schedule'" \
  "continue-on-error: true" \
  "runs-on: ubuntu-24.04" \
  "uses: actions/checkout@v6" \
  "uses: actions/setup-node@v6" \
  "node-version: '22'" \
  "cache: npm" \
  "cache-dependency-path: accrue_admin/package-lock.json" \
  "cd accrue_admin && npm ci" \
  "cd accrue_admin && npm run ratchet:ledger:verify-frozen" \
  "cd accrue_admin && npm run ratchet:signoff" \
  "phase208-ratchet-evidence" \
  "accrue_admin/e2e/ratchet/ledger.baseline.json" \
  "accrue_admin/e2e/ratchet/finding-regressions.ndjson" \
  "accrue_admin/e2e/ratchet/rounds.ndjson" \
  ".planning/milestones/v1.56-phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/UI-RATCHET-SIGN-OFF.md" \
  "if-no-files-found: ignore"
do
  require_source_fixed "admin-ui-ratchet-guardrails job" "$ratchet_job" "$needle"
done

# D-23 (232-06): the genuinely-passing self-test steps moved out to
# admin-ui-ratchet-selftests -- they must not still be duplicated here.
require_source_absent_fixed "admin-ui-ratchet-guardrails job" "$ratchet_job" "cd accrue_admin && npm run ratchet:ledger:self-test"
require_source_absent_fixed "admin-ui-ratchet-guardrails job" "$ratchet_job" "cd accrue_admin && npm run ratchet:signoff:self-test"
require_source_absent_fixed "admin-ui-ratchet-guardrails job" "$ratchet_job" "cd accrue_admin && npm run ratchet:ci-contract"

evidence_upload_step="$(printf '%s\n' "$ratchet_job" | awk '
  /name: Upload Phase 208 ratchet evidence/ { in_step = 1 }
  in_step { print }
  in_step && /if-no-files-found:/ { exit }
')"
[ -n "$evidence_upload_step" ] || fail "could not extract Phase 208 ratchet-evidence upload step"
require_source_absent_regex \
  "Phase 208 ratchet-evidence upload step" \
  "$evidence_upload_step" \
  '\.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/'

require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Install admin Node dependencies'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Verify frozen ratchet evidence'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Verify UI ratchet sign-off'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'name: Ratchet status summary'
require_source_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'uses: actions/upload-artifact@v7'

# D-24 (232-06): the status-summary step must be always-run (it reports on a
# preceding step that fails on the merits today) and must read every value it
# prints from the live ledger file -- no literal hardcoded outcome word.
summary_step="$(step_body "$ratchet_job" "Ratchet status summary")"
[ -n "$summary_step" ] || fail "could not extract Ratchet status summary step"
require_source_fixed "Ratchet status summary step" "$summary_step" "if: always()"
require_source_fixed "Ratchet status summary step" "$summary_step" "ledger.baseline.json"
require_source_absent_regex "admin-ui-ratchet-guardrails job" "$ratchet_job" 'PASS - '

sanitized_job="$ratchet_job"
for pattern in \
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

annotation_job="$(job_body "annotation-sweep")"
[ -n "$annotation_job" ] || fail "could not extract annotation-sweep job"
require_source_fixed "annotation-sweep job" "$annotation_job" "admin-ui-ratchet-selftests"
require_source_fixed "annotation-sweep job" "$annotation_job" "admin-ui-ratchet-guardrails"
require_source_fixed "annotation-sweep job" "$annotation_job" "bash scripts/ci/annotation_sweep.sh"
require_source_fixed "annotation-sweep job" "$annotation_job" "ANNOTATION_SWEEP_EXCLUDE: advisory,ratchet"
annotation_job_flat="$(printf '%s\n' "$annotation_job" | tr '\n' ' ')"
require_source_regex "annotation-sweep job" "$annotation_job_flat" 'annotation_sweep\.sh .*admin-ui-ratchet-selftests'
require_source_regex "annotation-sweep job" "$annotation_job_flat" 'annotation_sweep\.sh .*admin-ui-ratchet-guardrails'

echo "verify_admin_ui_ratchet_ci_contract: ok"
