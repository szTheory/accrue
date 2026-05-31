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

section_has_version() {
  local start_heading=$1
  local stop_heading=$2

  awk -v start="$start_heading" -v stop="$stop_heading" -v version="$accrue_version" '
    $0 == start { in_section = 1; next }
    stop != "" && $0 == stop { in_section = 0 }
    in_section && $0 == "### " version { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$notes"
}

section_has_version "## accrue" "## accrue_admin" ||
  fail "release-notes.md must describe ${accrue_version} in the accrue section"
section_has_version "## accrue_admin" "## How we version" ||
  fail "release-notes.md must describe ${accrue_version} in the accrue_admin section"

echo "verify_release_notes_contract: OK (${accrue_version})"
