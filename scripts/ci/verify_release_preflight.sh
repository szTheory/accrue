#!/usr/bin/env bash

# Runs the deterministic local subset of the required release lane. It cannot
# replace GitHub's clean-host matrix, service containers, or artifact checks,
# but it catches source, documentation, static-contract, and Dialyzer failures
# before a branch is pushed or a workflow is dispatched.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root_dir"

run() {
  printf '\n==> %s\n' "$1"
  shift
  "$@"
}

for script in \
  verify_package_docs.sh \
  verify_processor_support_matrix.sh \
  verify_core_liveview_runtime_free.sh \
  verify_entitlement_sync_isolation.sh \
  verify_dunning_chimeway_isolation.sh \
  verify_v1_17_friction_research_contract.sh \
  verify_verify01_readme_contract.sh \
  verify_docker_dx_contract.sh \
  verify_production_readiness_discoverability.sh \
  verify_adoption_proof_matrix.sh \
  verify_reference_scenario_contract.sh \
  verify_core_admin_invoice_verify_ids.sh \
  verify_stable_core_posture.sh \
  verify_roadmap_hygiene.sh \
  verify_release_notes_contract.sh; do
  if [[ "$script" == "verify_reference_scenario_contract.sh" ]]; then
    run "$script" env V159_SKIP_RELEASE_CONTRACT=true bash "scripts/ci/$script"
  else
    run "$script" bash "scripts/ci/$script"
  fi
done

run "accrue format" bash -c 'cd accrue && mix format --check-formatted'
run "accrue compile" bash -c 'cd accrue && mix compile --warnings-as-errors'
run "accrue tests" bash -c 'cd accrue && mix test --warnings-as-errors'
run "accrue Credo" bash -c 'cd accrue && mix credo --strict'
run "accrue Dialyzer" bash -c 'cd accrue && MIX_ENV=test mix dialyzer --format short'
run "accrue docs" bash -c 'cd accrue && MIX_ENV=dev mix docs --warnings-as-errors'

printf '\nverify_release_preflight: OK\n'
