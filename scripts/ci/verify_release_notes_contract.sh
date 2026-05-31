#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "verify_release_notes_contract: $*" >&2
  exit 1
}

extract_version() {
  local file=$1
  local version

  version=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$file" | head -n 1)
  [[ -n "$version" ]] || fail "could not parse @version from $file"
  printf '%s\n' "$version"
}

notes="$ROOT_DIR/accrue/guides/release-notes.md"
accrue_version=$(extract_version "$ROOT_DIR/accrue/mix.exs")
accrue_admin_version=$(extract_version "$ROOT_DIR/accrue_admin/mix.exs")
accrue_portal_version=$(extract_version "$ROOT_DIR/accrue_portal/mix.exs")

[[ "$accrue_version" == "$accrue_admin_version" ]] || fail "accrue and accrue_admin versions diverged"
[[ "$accrue_version" == "$accrue_portal_version" ]] || fail "accrue and accrue_portal versions diverged"
[[ -f "$notes" ]] || fail "missing $notes"

grep -Fq "# Release notes (plain-language)" "$notes" || fail "release-notes.md missing title"
grep -Fq "## accrue" "$notes" || fail "release-notes.md missing accrue section"
grep -Fq "## accrue_admin" "$notes" || fail "release-notes.md missing accrue_admin section"
grep -Fq "GitHub releases" "$notes" || fail "release-notes.md missing GitHub releases link"
grep -Fq "accrue_portal" "$notes" || fail "release-notes.md must mention accrue_portal version-family context"
grep -Eq "stable-core[^[:cntrl:]]*posture" "$notes" ||
  fail "release-notes.md missing stable-core posture token"
grep -Eq "maturity-and-maintenance\\.md|first_hour\\.md|jobs_to_be_done\\.md" "$notes" ||
  fail "release-notes.md must link to maturity-and-maintenance.md, first_hour.md, or jobs_to_be_done.md"

version_heading_count=$(grep -Ec "^### ${accrue_version}$" "$notes" || true)
[[ "$version_heading_count" -ge 2 ]] ||
  fail "release-notes.md must describe ${accrue_version} for both accrue and accrue_admin"

echo "verify_release_notes_contract: OK (${accrue_version})"
