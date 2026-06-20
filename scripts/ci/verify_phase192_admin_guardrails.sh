#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_step() {
  local label="$1"
  shift

  echo "==> ${label}"
  (cd "$root_dir" && "$@")
}

run_step "Phase 187 baseline artifacts parse" bash -c "cd accrue_admin && npm run baseline:parse"
run_step "Phase 191 AX187 coverage verifier" node scripts/ci/verify_phase191_ax187_coverage.mjs
run_step "Phase 190 admin group contracts" bash -c "cd accrue_admin && npm run e2e:group-contracts"
run_step "Phase 191 admin page-flow interactions" bash -c "cd accrue_admin && npm run e2e:phase191"
run_step "Admin axe accessibility" bash -c "cd accrue_admin && npm run e2e:a11y"
run_step "Admin reduced-motion guardrail" bash -c "cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1"
run_step "Phase 192 component-lab structural coverage" bash -c "cd accrue_admin && npm run phase192:component-lab"
