#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_step() {
  local label="$1"
  shift

  echo "==> ${label}"
  (cd "$root_dir" && "$@")
}

run_step "Package documentation contract" bash scripts/ci/verify_package_docs.sh
run_step "Phase 200 Storybook coverage, assets, theme parity, and rendered a11y" bash -c "cd accrue_admin && npm run phase200:storybook"
run_step "Component registry drift contracts" bash -c "cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs"
run_step "Phase 190 admin group contracts" bash -c "cd accrue_admin && npm run e2e:group-contracts"
run_step "Phase 200 page-flow final evidence" bash -c "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-page-flow-phase200.spec.js --workers=1"
run_step "Phase 199 interaction regression" bash -c "cd accrue_admin && npm run e2e:phase199"
run_step "Admin reduced-motion guardrail" bash -c "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1"
run_step "Phase 200 scorecard baseline verifier" bash -c "cd accrue_admin && npm run phase200:scorecard"
run_step "Phase 200 scorecard full verifier when final artifacts exist" bash -c '
phase200_dir=".planning/phases/200-idempotent-verification-sign-off"
if [ -f "$phase200_dir/final.cells.json" ] &&
  [ -f "$phase200_dir/scorecard.delta.json" ] &&
  [ -f "$phase200_dir/regressions.ndjson" ] &&
  [ -f "$phase200_dir/artifacts.manifest.json" ]; then
  node scripts/ci/verify_phase200_scorecard.mjs
else
  echo "Phase 200 final scorecard artifacts not present; baseline verifier already passed"
fi
'
run_step "Phase 200 sign-off verifier" bash -c "cd accrue_admin && npm run phase200:signoff"
