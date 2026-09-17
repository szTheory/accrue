#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "verify_stable_core_posture: $*" >&2
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

requirements_file="$ROOT_DIR/.planning/REQUIREMENTS.md"

# POS-03 was defined and completed by v1.48. Later milestone requirement files
# can exist while intentionally omitting that standing posture anchor, so they
# are not a reliable authority for this long-lived contract.
if [[ ! -f "$requirements_file" ]] || ! grep -Fq "POS-03" "$requirements_file"; then
  requirements_file="$ROOT_DIR/.planning/milestones/v1.48-REQUIREMENTS.md"
fi

public_anchor_files=(
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/accrue/README.md"
  "$ROOT_DIR/accrue/guides/maturity-and-maintenance.md"
  "$ROOT_DIR/accrue/guides/jobs_to_be_done.md"
  "$ROOT_DIR/accrue/guides/release-notes.md"
  "$ROOT_DIR/.planning/PROJECT.md"
  "$requirements_file"
  "$ROOT_DIR/.planning/processor-support-matrix.md"
  "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md"
)

thin_mirror_files=(
  "$ROOT_DIR/accrue/guides/first_hour.md"
  "$ROOT_DIR/accrue_admin/README.md"
  "$ROOT_DIR/accrue_portal/README.md"
  "$ROOT_DIR/examples/accrue_host/README.md"
)

for file in "${public_anchor_files[@]}" "${thin_mirror_files[@]}"; do
  [[ -f "$file" ]] || fail "missing $file"
done

require_fixed "$ROOT_DIR/README.md" "stable-core / demand-driven expansion"
require_fixed "$ROOT_DIR/accrue/README.md" "stable-core / demand-driven expansion"
require_fixed "$ROOT_DIR/accrue/guides/maturity-and-maintenance.md" "stable-core / demand-driven expansion"
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" "stable-core / demand-driven expansion"
require_regex "$ROOT_DIR/accrue/guides/release-notes.md" "stable-core[^[:cntrl:]]*posture"
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "stable-core / demand-driven expansion"
require_fixed "$requirements_file" "POS-03"
require_fixed "$ROOT_DIR/.planning/processor-support-matrix.md" "maintainer-facing capability SSOT"
require_fixed "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md" "scripts/ci/README.md"

require_fixed "$ROOT_DIR/accrue/README.md" "concrete adopter failure mode"
require_fixed "$ROOT_DIR/accrue/README.md" "correctness/security/data-loss risk"
require_fixed "$ROOT_DIR/accrue/README.md" "repeated support issue"
require_fixed "$ROOT_DIR/accrue/README.md" "operational failure"
require_fixed "$ROOT_DIR/accrue/README.md" "explicit strategy change"

require_fixed "$ROOT_DIR/accrue/guides/release-notes.md" "maturity-and-maintenance.md"
require_fixed "$ROOT_DIR/accrue/guides/release-notes.md" "first_hour.md"
require_fixed "$ROOT_DIR/accrue/guides/release-notes.md" "jobs_to_be_done.md"
require_regex "$ROOT_DIR/accrue/guides/first_hour.md" "Maturity and maintenance|maturity-and-maintenance\\.md"
require_regex "$ROOT_DIR/accrue_admin/README.md" "First Hour|first_hour\\.md"
require_regex "$ROOT_DIR/accrue_portal/README.md" "First Hour|first_hour\\.md"
require_regex "$ROOT_DIR/examples/accrue_host/README.md" "stable-core posture|Maturity and maintenance|jobs_to_be_done\\.md"

for file in "${public_anchor_files[@]}" "${thin_mirror_files[@]}"; do
  require_absent_regex "$file" "feature freeze|no new features ever|maintenance only"
done

echo "verify_stable_core_posture: OK"
