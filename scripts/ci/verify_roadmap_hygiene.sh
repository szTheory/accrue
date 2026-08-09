#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "verify_roadmap_hygiene: $*" >&2
  exit 1
}

require_fixed() {
  grep -Fq "$2" "$1" || fail "$1 is missing: $2"
}

require_regex() {
  grep -Eq "$2" "$1" || fail "$1 does not match: $2"
}

require_absent_regex() {
  if grep -Eq "$2" "$1"; then
    fail "$1 must not match: $2"
  fi
}

project="$ROOT_DIR/.planning/PROJECT.md"
roadmap="$ROOT_DIR/.planning/ROADMAP.md"
state="$ROOT_DIR/.planning/STATE.md"

for file in "$project" "$roadmap" "$state"; do
  [[ -f "$file" ]] || fail "missing $file"
done

pause_rule="After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change."

for file in "$project" "$state"; do
  require_fixed "$file" "$pause_rule"
  require_absent_regex "$file" "feature freeze|maintenance only"
  require_absent_regex "$file" "dormant seed alone (creates|opens)|deferred idea alone (creates|opens)"
done

require_fixed "$project" "### Post-v1.48 pause rule"
require_fixed "$project" "historical anchor, dormant seed, or deferred idea never opens milestone scope by itself"

require_fixed "$roadmap" "Accrue remains in **stable-core / demand-driven expansion** posture."
require_regex "$roadmap" "New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change"
require_fixed "$roadmap" "Historical friction-backlog anchors remain canonical"
require_fixed "$roadmap" "research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63"
require_fixed "$roadmap" "research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64"
require_fixed "$roadmap" "research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65"
require_fixed "$roadmap" "Google Play remains backlogged in SEED-007"

require_fixed "$state" "## Deferred Items"
require_fixed "$state" "HOST-01..03"
require_fixed "$state" "READY-01..02"

echo "verify_roadmap_hygiene: OK"
