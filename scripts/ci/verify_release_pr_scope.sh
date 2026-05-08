#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

REPO=${GITHUB_REPOSITORY:-szTheory/accrue}

fail() {
  echo "[verify_release_pr_scope] $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: bash scripts/ci/verify_release_pr_scope.sh --pr <number-or-url> [--version <x.y.z>]

Verify that a Release Please PR matches the locked three-package release contract:
- .release-please-manifest.json
- accrue/mix.exs and accrue/CHANGELOG.md
- accrue_admin/mix.exs and accrue_admin/CHANGELOG.md
- accrue_portal/mix.exs and accrue_portal/CHANGELOG.md

If --version is provided, the script also proves the PR head carries that exact
version in the manifest, all three mix.exs files, and all three changelog files.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required but not installed"
}

normalize_pr() {
  local value=$1

  if [[ "$value" =~ ^https?://github\.com/[^/]+/[^/]+/pull/([0-9]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$value"
  else
    fail "invalid PR identifier: $value"
  fi
}

decode_content() {
  local payload

  payload=$(jq -r '.content' | tr -d '\n')
  if printf '%s' "$payload" | base64 --decode >/dev/null 2>&1; then
    printf '%s' "$payload" | base64 --decode
  else
    printf '%s' "$payload" | base64 -D
  fi
}

fetch_pr_file() {
  local ref=$1
  local path=$2

  gh api "repos/$REPO/contents/$path?ref=$ref" | decode_content
}

PR_ARG=""
TARGET_VERSION=""

while (($# > 0)); do
  case "$1" in
    --pr)
      (($# >= 2)) || fail "--pr requires a value"
      PR_ARG=$2
      shift 2
      ;;
    --version)
      (($# >= 2)) || fail "--version requires a value"
      TARGET_VERSION=$2
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

[[ -n "$PR_ARG" ]] || {
  usage
  fail "--pr is required"
}

require_cmd gh
require_cmd jq
require_cmd base64

PR_NUMBER=$(normalize_pr "$PR_ARG")
PR_JSON=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json number,url,state,mergeStateStatus,headRefOid)
PR_STATE=$(jq -r '.state' <<<"$PR_JSON")
PR_URL=$(jq -r '.url' <<<"$PR_JSON")
PR_MERGE_STATE=$(jq -r '.mergeStateStatus' <<<"$PR_JSON")
HEAD_SHA=$(jq -r '.headRefOid' <<<"$PR_JSON")

[[ -n "$HEAD_SHA" && "$HEAD_SHA" != "null" ]] || fail "could not determine PR head sha for #$PR_NUMBER"

FILES_JSON=$(gh api "repos/$REPO/pulls/$PR_NUMBER/files?per_page=100")
FILE_PATHS=$(jq -r '.[].filename' <<<"$FILES_JSON")

required_files=(
  ".release-please-manifest.json"
  "accrue/mix.exs"
  "accrue/CHANGELOG.md"
  "accrue_admin/mix.exs"
  "accrue_admin/CHANGELOG.md"
  "accrue_portal/mix.exs"
  "accrue_portal/CHANGELOG.md"
)

for required in "${required_files[@]}"; do
  grep -Fxq "$required" <<<"$FILE_PATHS" || fail "PR #$PR_NUMBER is missing required release file: $required"
done

manifest=$(fetch_pr_file "$HEAD_SHA" ".release-please-manifest.json")
for package in accrue accrue_admin accrue_portal; do
  version=$(jq -r --arg pkg "$package" '.[$pkg] // empty' <<<"$manifest")
  [[ -n "$version" ]] || fail "manifest at PR head is missing $package"
  if [[ -n "$TARGET_VERSION" && "$version" != "$TARGET_VERSION" ]]; then
    fail "manifest version mismatch for $package: expected $TARGET_VERSION, found $version"
  fi
done

for package in accrue accrue_admin accrue_portal; do
  mix_contents=$(fetch_pr_file "$HEAD_SHA" "$package/mix.exs")
  mix_version=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' <<<"$mix_contents" | head -n 1)
  [[ -n "$mix_version" ]] || fail "could not parse @version from $package/mix.exs at PR head"

  changelog=$(fetch_pr_file "$HEAD_SHA" "$package/CHANGELOG.md")
  grep -Fq "## [" <<<"$changelog" || fail "$package/CHANGELOG.md does not contain any release headings"

  if [[ -n "$TARGET_VERSION" ]]; then
    [[ "$mix_version" == "$TARGET_VERSION" ]] ||
      fail "$package/mix.exs version mismatch: expected $TARGET_VERSION, found $mix_version"
    grep -Fq "## [$TARGET_VERSION]" <<<"$changelog" ||
      fail "$package/CHANGELOG.md does not contain release heading for $TARGET_VERSION"
  fi
done

echo "OK: Release PR #$PR_NUMBER ($PR_URL) matches the three-package contract"
echo "State: $PR_STATE"
echo "Merge state: $PR_MERGE_STATE"
if [[ -n "$TARGET_VERSION" ]]; then
  echo "Target version: $TARGET_VERSION"
fi
