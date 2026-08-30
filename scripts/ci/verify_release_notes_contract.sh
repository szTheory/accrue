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

is_stable_semver() {
  [[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

assert_stable_semver() {
  local label=$1
  local version=$2

  is_stable_semver "$version" || fail "$label @version must be stable SemVer"
}

notes="$ROOT_DIR/accrue/guides/release-notes.md"
core_changelog="$ROOT_DIR/accrue/CHANGELOG.md"
admin_changelog="$ROOT_DIR/accrue_admin/CHANGELOG.md"
portal_changelog="$ROOT_DIR/accrue_portal/CHANGELOG.md"
accrue_version=$(extract_version "$ROOT_DIR/accrue/mix.exs")
accrue_admin_version=$(extract_version "$ROOT_DIR/accrue_admin/mix.exs")
accrue_portal_version=$(extract_version "$ROOT_DIR/accrue_portal/mix.exs")

assert_stable_semver "accrue" "$accrue_version"
assert_stable_semver "accrue_admin" "$accrue_admin_version"
assert_stable_semver "accrue_portal" "$accrue_portal_version"
[[ "$accrue_version" == "$accrue_admin_version" ]] || fail "accrue and accrue_admin versions diverged"
[[ "$accrue_version" == "$accrue_portal_version" ]] || fail "accrue and accrue_portal versions diverged"

[[ -f "$notes" ]] || fail "missing $notes"
[[ -f "$core_changelog" ]] || fail "missing $core_changelog"
[[ -f "$admin_changelog" ]] || fail "missing $admin_changelog"
[[ -f "$portal_changelog" ]] || fail "missing $portal_changelog"

first_line_matching() {
  local pattern=$1
  local file=$2

  grep -nE "$pattern" "$file" | head -n 1 | cut -d: -f1 || true
}

changelog_unreleased_section() {
  local file=$1

  awk '
    /^## Unreleased$/ { in_section = 1; next }
    /^## \[/ && in_section { exit }
    in_section { print }
  ' "$file"
}

changelog_release_section() {
  local file=$1
  local version=$2

  awk -v heading="## [${version}]" '
    index($0, heading) == 1 { in_section = 1; found = 1; next }
    /^## \[/ && in_section { exit }
    in_section { print }
    END { exit found ? 0 : 1 }
  ' "$file"
}

assert_unreleased_before_latest() {
  local label=$1
  local file=$2
  local unreleased_line
  local latest_line

  unreleased_line=$(first_line_matching '^## Unreleased$' "$file")
  latest_line=$(first_line_matching '^## \[' "$file")

  [[ -n "$unreleased_line" && -n "$latest_line" && "$unreleased_line" -lt "$latest_line" ]] ||
    fail "$label missing top-level Unreleased before latest release"
}

assert_no_manual_next_release_section() {
  local label=$1
  local file=$2

  ! grep -Eq '^## \[?1\.5\.0\]?' "$file" ||
    fail "Release Please owns numbered 1.5.0 changelog sections"
}

assert_section_contains() {
  local label=$1
  local section=$2
  local token=$3
  local message=$4

  grep -Fq "$token" <<<"$section" || fail "$label $message"
}

assert_companion_compatibility_only() {
  local label=$1
  local section=$2
  local version=$3

  assert_section_contains "$label" "$section" "Compatibility only:" "must remain compatibility-only"
  assert_section_contains "$label" "$section" "linked ${version}" "must name the linked ${version} line"
  assert_section_contains "$label" "$section" "core" "must defer substantive capability to core"
  assert_section_contains "$label" "$section" "package owns" "must defer substantive capability to core"

  ! grep -Eiq 'admin-owned|portal-owned|new .*workflow|new .*API|grant authority|authorization behavior' <<<"$section" ||
    fail "$label must remain compatibility-only"
}

if [[ "$accrue_version" == "1.4.0" ]]; then
  release_state="pre-release"
  companion_version="1.5.0"
else
  release_state="candidate"
  companion_version="$accrue_version"
fi

if [[ "$release_state" == "pre-release" ]]; then
  for entry in \
    "accrue/CHANGELOG.md:$core_changelog" \
    "accrue_admin/CHANGELOG.md:$admin_changelog" \
    "accrue_portal/CHANGELOG.md:$portal_changelog"; do
    label=${entry%%:*}
    file=${entry#*:}
    assert_unreleased_before_latest "$label" "$file"
    assert_no_manual_next_release_section "$label" "$file"
  done

  core_section=$(changelog_unreleased_section "$core_changelog")
  admin_section=$(changelog_unreleased_section "$admin_changelog")
  portal_section=$(changelog_unreleased_section "$portal_changelog")
else
  for entry in \
    "accrue/CHANGELOG.md:$core_changelog" \
    "accrue_admin/CHANGELOG.md:$admin_changelog" \
    "accrue_portal/CHANGELOG.md:$portal_changelog"; do
    label=${entry%%:*}
    file=${entry#*:}
    if ! section=$(changelog_release_section "$file" "$accrue_version"); then
      fail "$label missing numbered ${accrue_version} changelog section"
    fi

    case "$label" in
      accrue/CHANGELOG.md) core_section=$section ;;
      accrue_admin/CHANGELOG.md) admin_section=$section ;;
      accrue_portal/CHANGELOG.md) portal_section=$section ;;
    esac
  done
fi

if [[ "$release_state" == "pre-release" || "$accrue_version" == "1.5.0" ]]; then
  feature_section=$core_section
else
  feature_section=$(changelog_release_section "$core_changelog" "1.5.0") ||
    fail "accrue/CHANGELOG.md missing historical 1.5.0 feature section"

  assert_section_contains "accrue/CHANGELOG.md" "$core_section" "Phoenix 1.8" "missing Phoenix 1.8 compatibility fix"
  assert_section_contains "accrue/CHANGELOG.md" "$core_section" "Decimal 3" "missing Decimal 3 compatibility fix"
  assert_section_contains "accrue/CHANGELOG.md" "$core_section" "API-only entitlement readers" "missing API-only entitlement posture"
  assert_section_contains "accrue/CHANGELOG.md" "$core_section" '`:limits`' "missing limits-to-quantities fix"
  assert_section_contains "accrue/CHANGELOG.md" "$core_section" "Accrue.Test.Entitlements" "missing public entitlement fixtures"
fi

assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "lattice_stripe" "missing lattice_stripe ~> 2.0 bump"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "~> 2.0" "missing lattice_stripe ~> 2.0 bump"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "optional, default-off advisory Stripe-native entitlement refresh" "missing advisory refresh"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "never changes entitlement grants" "missing never-a-gate semantics"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "Accrue.Entitlements.StripeSync.refresh/2" "missing StripeSync.refresh/2 contract"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "Accrue.Processor.list_active_entitlements/2" "missing Processor list contract"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "Accrue.Processor.Fake.put_entitlements/2" "missing Fake test helper contract"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "shared reconcile/isolation proof" "missing reconcile/isolation proof"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "fetch_entitled/2" "missing fetch_entitled closure"
assert_section_contains "accrue/CHANGELOG.md" "$feature_section" "remains closed" "missing fetch_entitled closure"

assert_companion_compatibility_only "accrue_admin/CHANGELOG.md" "$admin_section" "$companion_version"
assert_companion_compatibility_only "accrue_portal/CHANGELOG.md" "$portal_section" "$companion_version"

grep -Fq "# Release notes (plain-language)" "$notes" || fail "release-notes.md missing title"
grep -Fq "## accrue" "$notes" || fail "release-notes.md missing accrue section"
grep -Fq "## accrue_admin" "$notes" || fail "release-notes.md missing accrue_admin section"
grep -Fq "GitHub releases" "$notes" || fail "release-notes.md missing GitHub releases link"
grep -Fq "accrue_portal" "$notes" || fail "release-notes.md must mention accrue_portal version-family context"
grep -Fq '[`accrue_portal/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue_portal/CHANGELOG.md)' "$notes" ||
  fail "release-notes.md missing accrue_portal changelog link"
grep -Fq '### 1.5.0' "$notes" ||
  fail "release-notes.md missing next-release 1.5.0 story"
grep -Fq '`1.5.0` is the next linked feature release' "$notes" ||
  fail "release-notes.md missing next-release 1.5.0 story"
grep -Fq 'lattice_stripe ~> 2.0' "$notes" ||
  fail "release-notes.md missing next-release 1.5.0 story"
grep -Fq 'optional, default-off Stripe-native entitlement refresh' "$notes" ||
  fail "release-notes.md missing next-release 1.5.0 story"
grep -Fq 'Stripe-native advisory data never changes `entitled?/2`, plugs, or LiveView guards' "$notes" ||
  fail "release-notes.md missing next-release 1.5.0 story"
grep -Fq 'compatibility-only updates' "$notes" ||
  fail "release-notes.md missing next-release 1.5.0 story"
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
