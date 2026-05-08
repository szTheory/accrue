#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "[repair_linked_release_pr] $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: bash scripts/ci/repair_linked_release_pr.sh --version <x.y.z>

Repair the checked-out Release Please branch when the linked three-package
contract drifts and `accrue_portal` is left behind. The script updates:
- .release-please-manifest.json
- accrue_portal/mix.exs
- accrue_portal/CHANGELOG.md
EOF
}

VERSION=""

while (($# > 0)); do
  case "$1" in
    --version)
      (($# >= 2)) || fail "--version requires a value"
      VERSION=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "$VERSION" ]] || fail "--version is required"
command -v jq >/dev/null 2>&1 || fail "jq is required but not installed"

MANIFEST="$ROOT_DIR/.release-please-manifest.json"
MIX_FILE="$ROOT_DIR/accrue_portal/mix.exs"
CHANGELOG="$ROOT_DIR/accrue_portal/CHANGELOG.md"

[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"
[[ -f "$MIX_FILE" ]] || fail "missing $MIX_FILE"
[[ -f "$CHANGELOG" ]] || fail "missing $CHANGELOG"

accrue_version=$(jq -r '.accrue // empty' "$MANIFEST")
admin_version=$(jq -r '.accrue_admin // empty' "$MANIFEST")
portal_version=$(jq -r '.accrue_portal // empty' "$MANIFEST")

[[ -n "$accrue_version" && -n "$admin_version" && -n "$portal_version" ]] ||
  fail "manifest must contain accrue, accrue_admin, and accrue_portal versions"
[[ "$accrue_version" == "$VERSION" ]] ||
  fail "expected accrue version $VERSION, found $accrue_version"
[[ "$admin_version" == "$VERSION" ]] ||
  fail "expected accrue_admin version $VERSION, found $admin_version"

if [[ "$portal_version" == "$VERSION" ]]; then
  echo "No repair needed: accrue_portal is already at $VERSION"
  exit 0
fi

manifest_tmp=$(mktemp)
jq --arg version "$VERSION" '.accrue_portal = $version' "$MANIFEST" >"$manifest_tmp"
mv "$manifest_tmp" "$MANIFEST"

mix_tmp=$(mktemp)
sed "0,/^  @version \".*\"/s//  @version \"$VERSION\"/" "$MIX_FILE" >"$mix_tmp"
mv "$mix_tmp" "$MIX_FILE"

if ! grep -Fq "## [$VERSION]" "$CHANGELOG"; then
  changelog_tmp=$(mktemp)
  release_date=$(date -u +"%Y-%m-%d")
  compare_url="https://github.com/szTheory/accrue/compare/accrue_portal-v${portal_version}...accrue_portal-v${VERSION}"
  {
    head -n 1 "$CHANGELOG"
    printf '\n'
    printf '## [%s](%s) (%s)\n\n' "$VERSION" "$compare_url" "$release_date"
    printf '### Bug Fixes\n\n'
    printf '* keep linked portal releases aligned with the locked three-package contract\n\n'
    tail -n +2 "$CHANGELOG"
  } >"$changelog_tmp"
  mv "$changelog_tmp" "$CHANGELOG"
fi

grep -Fq "\"accrue_portal\": \"$VERSION\"" "$MANIFEST" ||
  fail "manifest repair failed for accrue_portal"
grep -Fq "  @version \"$VERSION\"" "$MIX_FILE" ||
  fail "mix.exs repair failed for accrue_portal"
grep -Fq "## [$VERSION]" "$CHANGELOG" ||
  fail "CHANGELOG repair failed for accrue_portal"

echo "OK: repaired linked release PR checkout so accrue_portal matches $VERSION"
