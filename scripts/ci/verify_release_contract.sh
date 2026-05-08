#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

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
