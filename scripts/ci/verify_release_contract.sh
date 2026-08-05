#!/usr/bin/env bash

set -euo pipefail

TARGET_ROOT=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}
# The longstanding linked-release gate reads its release configuration from the
# canonical repository. Tests may point TARGET_ROOT at isolated documentation
# copies while retaining that already-proven release configuration.
SOURCE_ROOT=${V159_SOURCE_ROOT:-$TARGET_ROOT}
ROOT_DIR=$SOURCE_ROOT

fail() {
  echo "[verify_release_contract] $*" >&2
  exit 1
}

require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}

require_regex() {
  local file=$1
  local pattern=$2

  grep -Eq "$pattern" "$file" || fail "$file does not match: $pattern"
}

command -v jq >/dev/null 2>&1 || fail "jq is required but not installed"

config="$ROOT_DIR/release-please-config.json"
manifest="$ROOT_DIR/.release-please-manifest.json"
releasing="$ROOT_DIR/RELEASING.md"
release_workflow="$ROOT_DIR/.github/workflows/release-please.yml"
recovery_workflow="$ROOT_DIR/.github/workflows/publish-hex.yml"

components=$(jq -r '.plugins[] | select(.type == "linked-versions") | .components | join(",")' "$config")
manifest_components=$(jq -r 'keys | join(",")' "$manifest")

[[ "$components" == "accrue,accrue_admin,accrue_portal" ]] ||
  fail "unexpected linked release scope: $components"
[[ "$manifest_components" == "$components" ]] ||
  fail "manifest keys drifted from linked release scope: manifest=$manifest_components config=$components"

require_fixed "$releasing" 'linked `accrue` +'
require_fixed "$releasing" '`accrue_admin` + `accrue_portal` releases via **Release Please**'
require_fixed "$releasing" '`accrue`, `accrue_admin`, and `accrue_portal` continue shipping as a coordinated combined Release Please PR.'
require_fixed "$releasing" 'publish-accrue-portal'
require_fixed "$releasing" 'ACCRUE_PORTAL_HEX_RELEASE=1'
require_fixed "$releasing" 'choose `accrue`, `accrue_admin`, or `accrue_portal`'
require_fixed "$releasing" 'Publish `accrue_portal`.'
require_fixed "$releasing" 'repair_linked_release_pr.sh'

require_fixed "$release_workflow" 'accrue_portal_release_created'
require_fixed "$release_workflow" 'publish-accrue-portal:'
require_fixed "$release_workflow" 'needs: [release, publish-accrue, publish-accrue-admin]'
require_fixed "$release_workflow" 'ACCRUE_PORTAL_HEX_RELEASE: "1"'
require_fixed "$release_workflow" 'cd accrue_portal && mix hex.publish --dry-run'
require_fixed "$release_workflow" 'cd accrue_portal && mix hex.publish --yes'
require_fixed "$release_workflow" 'git push --force-with-lease origin HEAD:"$release_branch"'
require_fixed "$release_workflow" 'bash scripts/ci/repair_linked_release_pr.sh --version "$repair_version"'
require_fixed "$release_workflow" 'bash scripts/ci/verify_release_pr_scope.sh --pr "$release_pr_number"'

require_fixed "$recovery_workflow" "Run accrue before accrue_admin before accrue_portal"
require_regex "$recovery_workflow" 'options:\s*$'
require_fixed "$recovery_workflow" '          - accrue_portal'
require_fixed "$recovery_workflow" "if: \${{ inputs.package == 'accrue_portal' }}"
require_fixed "$recovery_workflow" 'ACCRUE_PORTAL_HEX_RELEASE: "1"'
require_fixed "$recovery_workflow" 'grep -n "@version \"${{ inputs.release_version }}\"" accrue_portal/mix.exs'
require_fixed "$recovery_workflow" 'cd accrue_portal && mix hex.publish --dry-run'
require_fixed "$recovery_workflow" 'cd accrue_portal && mix hex.publish --yes'

require_fixed "$ROOT_DIR/scripts/ci/README.md" 'repair_linked_release_pr.sh'

echo "OK: linked release contract aligned for accrue/accrue_admin/accrue_portal"

v159_fail() {
  echo "verify_release_contract: $1" >&2
  exit 1
}

v159_file() {
  local relative=$1
  printf '%s/%s' "$TARGET_ROOT" "$relative"
}

v159_require_fixed() {
  local relative=$1
  local needle=$2
  local file
  file=$(v159_file "$relative")
  [ -f "$file" ] || v159_fail "$relative is missing"
  grep -Fq "$needle" "$file" || v159_fail "$relative is missing: $needle"
}

v159_require_regex() {
  local relative=$1
  local pattern=$2
  local file
  file=$(v159_file "$relative")
  [ -f "$file" ] || v159_fail "$relative is missing"
  grep -Eq "$pattern" "$file" || v159_fail "$relative does not match: $pattern"
}

v159_reject_regex() {
  local relative=$1
  local pattern=$2
  local label=$3
  local file
  file=$(v159_file "$relative")
  [ -f "$file" ] || v159_fail "$relative is missing"
  if grep -Eqi "$pattern" "$file"; then
    v159_fail "$relative has $label"
  fi
}

# D-09: canonical fixture/generated output are exact-fact authority. Invoke the
# Plan-04 gate rather than repeating its fixture needles in this release gate.
ROOT_DIR="$SOURCE_ROOT" V159_SKIP_RELEASE_CONTRACT=true bash "$SOURCE_ROOT/scripts/ci/verify_reference_scenario_contract.sh" ||
  v159_fail "canonical fixture/generated-matrix gate failed"
ROOT_DIR="$TARGET_ROOT" bash "$SOURCE_ROOT/scripts/ci/verify_adoption_proof_matrix.sh" ||
  v159_fail "adoption proof matrix gate failed"

fixture="$(v159_file 'accrue/priv/entitlements/v1.59-public-contract.json')"
scenarios="$(v159_file 'accrue/priv/entitlements/v1.59-reference-scenarios.json')"
matrix="$(v159_file 'examples/accrue_host/docs/capability-limits-matrix.md')"

command -v jq >/dev/null 2>&1 || v159_fail "jq is required"
for file in "$fixture" "$scenarios" "$matrix"; do
  [ -f "$file" ] || v159_fail "${file#$TARGET_ROOT/} is missing"
done

if ! diff -u \
  <(jq -r '.scenario_ids[]' "$fixture" | LC_ALL=C sort) \
  <(jq -r '.scenarios[].id' "$scenarios" | LC_ALL=C sort) >/dev/null; then
  v159_fail "accrue/priv/entitlements/v1.59-public-contract.json scenario IDs do not match accrue/priv/entitlements/v1.59-reference-scenarios.json"
fi

while IFS= read -r scenario_id; do
  grep -Fq "\`${scenario_id}\`" "$matrix" ||
    v159_fail "examples/accrue_host/docs/capability-limits-matrix.md is missing scenario ID ${scenario_id}"
done < <(jq -r '.scenario_ids[]' "$fixture")

# D-11 presence and hand-authored cross-reference ownership.
v159_require_fixed "examples/accrue_host/docs/adoption-proof-matrix.md" "## v1.59 first-adopter path"
v159_require_fixed "examples/accrue_host/docs/adoption-proof-matrix.md" "mix accrue.entitlements.reference_scenarios --check"
v159_require_fixed "examples/accrue_host/docs/adoption-proof-matrix.md" "capability-limits-matrix.md"
v159_require_fixed "examples/accrue_host/docs/adoption-proof-matrix.md" "operator-runbooks.md#v159-multi-rail-and-offline-runbooks"
v159_require_fixed "accrue/guides/entitlements.md" "## v1.59 multi-rail and offline adoption path"
v159_require_fixed "accrue/guides/multi-rail-offline-release.md" "## Evidence and App Review"
v159_require_fixed "accrue/guides/multi-rail-offline-release.md" "## Privacy and security limits"
v159_require_fixed "accrue/guides/multi-rail-offline-release.md" "## Release checklist"
v159_require_fixed "accrue/guides/release-notes.md" "## v1.59 release contract"
v159_require_fixed "examples/crosswake_tracer/README.md" "## Public adoption boundary"
v159_require_fixed ".planning/research/v1.59-WATCHLIST.md" "V159-WL-APPLE-POLICY"
v159_require_fixed ".planning/research/v1.59-WATCHLIST.md" "V159-WL-PRIVACY"

for runbook in V159-RUN-MISSED-NOTIFICATION V159-RUN-CURSOR V159-RUN-PROVIDER-OUTAGE V159-RUN-OWNERSHIP-CONFLICT V159-RUN-DUPLICATE V159-RUN-DEVICE V159-RUN-KEY-ROTATION V159-RUN-BACKLOG V159-RUN-APP-REVIEW V159-RUN-PRIVACY V159-RUN-ROADMAP; do
  v159_require_fixed "accrue/guides/operator-runbooks.md" "$runbook"
done

# D-10: only scan public/procedural regions. The runbook prohibition paragraph
# intentionally names forbidden backend/provider actions and is not an approval.
for relative in \
  "examples/accrue_host/docs/adoption-proof-matrix.md" \
  "accrue/guides/entitlements.md" \
  "accrue/guides/multi-rail-offline-release.md" \
  "accrue/guides/release-notes.md" \
  "examples/crosswake_tracer/README.md"; do
  v159_reject_regex "$relative" 'Crosswake runtime (is )?(supported|feasible)' "runtime-capability inflation"
  v159_reject_regex "$relative" 'Apple( subscriptions)? (lifecycle )?(control|management) (is )?(available|supported)' "Apple-owned lifecycle claim"
  v159_reject_regex "$relative" 'cross-rail .*?(migration|refund|proration|ownership).*(available|supported|automatic)' "automatic cross-rail mutation claim"
  v159_reject_regex "$relative" 'stale (offline )?(access|lease).*(premium )?expansion' "stale premium expansion claim"
done

v159_reject_regex "accrue/guides/multi-rail-offline-release.md" '(raw transaction|signed proof|account token|PII).*(visible|exposed)' "private-data visibility claim"

# D-12: procedures must start from the operator's job and safe next action;
# this is scoped below the v1.59 heading so explanatory prohibition text stays valid.
runbooks_file=$(v159_file "accrue/guides/operator-runbooks.md")
v159_section=$(awk '/^## v1\.59 multi-rail and offline runbooks/{found=1} found{print}' "$runbooks_file")
printf '%s\n' "$v159_section" | grep -Fq "bounded diagnostic" ||
  v159_fail "accrue/guides/operator-runbooks.md is missing job-oriented bounded diagnostic entry point"
printf '%s\n' "$v159_section" | grep -Fq "literal next action" ||
  v159_fail "accrue/guides/operator-runbooks.md is missing job/next-action structure"
if printf '%s\n' "$v159_section" | grep -Eqi '(inspect|check|run) (the )?(worker|provider|database|queue)' ; then
  v159_fail "accrue/guides/operator-runbooks.md has backend-first procedure wording"
fi

echo "verify_release_contract: v1.59 OK"
