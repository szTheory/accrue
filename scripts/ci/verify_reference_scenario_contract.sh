#!/usr/bin/env bash
# Merge gate for the v1.59 generated public capability and evidence-lane contract.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
ACCRUE_DIR="${ACCRUE_DIR:-$ROOT_DIR/accrue}"
fixture="$ROOT_DIR/accrue/priv/entitlements/v1.59-public-contract.json"
scenarios="$ROOT_DIR/accrue/priv/entitlements/v1.59-reference-scenarios.json"
matrix="$ROOT_DIR/examples/accrue_host/docs/capability-limits-matrix.md"
capability_report="$ROOT_DIR/examples/crosswake_tracer/capability-report.json"
physical_evidence="$ROOT_DIR/examples/crosswake_tracer/physical-device-evidence.md"
workflow="$ROOT_DIR/.github/workflows/ci.yml"

fail() { echo "verify_reference_scenario_contract: FAIL: $1" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v mix >/dev/null 2>&1 || fail "mix is required"

for file in "$fixture" "$scenarios" "$matrix" "$capability_report" "$physical_evidence" "$workflow"; do
  [ -f "$file" ] || fail "missing required file ${file#$ROOT_DIR/}"
done

[ -d "$ACCRUE_DIR" ] || fail "missing accrue Mix project"

jq -e '
  (keys | sort) == ["evidence_lanes", "privacy_exclusions", "runtime_capability", "scenario_ids", "support", "verification_command", "version"] and
  .version == "v1.59" and
  .verification_command == "cd accrue && mix accrue.entitlements.reference_scenarios --check" and
  .evidence_lanes == {"advisory_parity":"not_merge_blocking","deterministic_conformance":"merge_blocking","runtime_capability":"not_merge_blocking"} and
  .support == {"apple_subscription_management":"externally_managed","cross_rail_lifecycle_mutation":"not_supported","legacy_hosts":"compatible","stale_offline_continuity":"downloaded_study_and_local_progress_only"} and
  .privacy_exclusions == ["raw_transaction_data","signed_proof_material","account_tokens","personally_identifiable_information"] and
  (.scenario_ids | type == "array" and length > 0 and length == (unique | length)) and
  .runtime_capability == {"report":"examples/crosswake_tracer/capability-report.json","required_evidence_kinds":["crosswake_bridge_compile_unit","physical_device"],"scenario_id":"crosswake_runtime_capability","status":"feasibility_blocked"}
' "$fixture" >/dev/null || fail "malformed public contract fixture"

jq -e '
  .version == "v1.59" and
  (.scenarios | type == "array" and length > 0) and
  ([.scenarios[].id] | length == (unique | length)) and
  ([.scenarios[].evidence_lane] | all(. == "deterministic_conformance" or . == "runtime_capability" or . == "advisory_parity")) and
  ([.scenarios[] | select(.evidence_lane == "deterministic_conformance")] | length > 0)
' "$scenarios" >/dev/null || fail "malformed reference scenario corpus"

if ! diff -u \
  <(jq -r '.scenario_ids[]' "$fixture" | LC_ALL=C sort) \
  <(jq -r '.scenarios[].id' "$scenarios" | LC_ALL=C sort) >/dev/null; then
  fail "public scenario IDs do not exactly match the corpus"
fi

jq -e '
  .overall_status == "feasibility_blocked" and
  ([.capabilities[] | select(.capability == "authenticated_host_transport")][0]) as $transport |
  $transport.required_evidence_kinds == ["crosswake_bridge_compile_unit","physical_device"] and
  ($transport.evidence | map(.kind)) == ["crosswake_bridge_compile_unit","physical_device"]
' "$capability_report" >/dev/null || fail "missing feasibility-blocked capability-report evidence inventory"

# Check prohibitions in the generated region before byte-determinism so a known-bad
# temporary copy proves each public-boundary check, rather than only generic drift.
if grep -Eq 'Crosswake runtime (is )?(supported|feasible)' "$matrix"; then
  fail "runtime-capability inflation"
fi

if grep -Eq 'Apple lifecycle control (is )?(available|supported)' "$matrix"; then
  fail "Apple lifecycle control"
fi

if grep -Eq 'Cross-rail (lifecycle |migration |refund |proration )?(mutation )?is (supported|available)' "$matrix"; then
  fail "cross-rail mutation"
fi

if grep -Eq 'Stale access permits (premium )?expansion' "$matrix"; then
  fail "stale premium expansion"
fi

if grep -Eq '^(Raw transaction data.*(is )?exposed|Signed proof material.*(is )?exposed|Account tokens.*(are )?exposed|PII.*(is )?exposed)' "$matrix"; then
  fail "private-data claim"
fi

if ! awk '
  /^  docs-contracts-shift-left:/ { in_job = 1; next }
  in_job && /^  [[:alnum:]_-]+:/ { exit }
  in_job { print }
' "$workflow" | grep -Fq 'bash scripts/ci/verify_reference_scenario_contract.sh'; then
  fail "missing docs-contracts-shift-left invocation"
fi

grep -Eq '^  pull_request:' "$workflow" || fail "workflow lacks pull-request trigger"

(cd "$ACCRUE_DIR" && mix accrue.entitlements.reference_scenarios --check --root "$ROOT_DIR") ||
  fail "generated matrix drift"

echo "verify_reference_scenario_contract: OK"
