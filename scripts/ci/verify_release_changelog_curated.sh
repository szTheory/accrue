#!/usr/bin/env bash
#
# Phase 251 SC1: the release section of every package CHANGELOG is curated.
#
# Release Please renders each conventional commit as a raw, phase-scoped
# bullet such as
#
#   * **233-05:** add host shared billing context adapter ([e4e9752](https://github.com/<owner>/<repo>/commit/<sha>))
#
# That is engineering history, not adopter-readable release notes. This gate
# reads only the `## [<V>]` section of accrue, accrue_admin and accrue_portal
# CHANGELOG.md (V = the manifest version, or --version), up to the next
# `## [` heading, and fails if any line in it is one of the raw forms:
#
#   - a phase-scoped bullet: `* **233:**`, `* **233-05:**`, `* **phase-12:**`,
#     `* **quick-261008-lbv:**`, and suffixed scopes such as `* **241-ui:**`
#     or `* **247-post-review:**` (all seen in the 963ad2cd raw candidate);
#   - a conventional-commit subject: `feat(233` or `fix(233`;
#   - a raw commit link: `([<7 hex>](https://github.com/<owner>/<repo>/commit/<40 hex>))`.
#
# A literal grep for `feat(2xx-yy)` alone is vacuous: Release Please never
# renders that form (RESEARCH Pitfall 5). The self-test proves each pattern
# can find a known positive.
#
# Usage:
#   bash scripts/ci/verify_release_changelog_curated.sh [--root <dir>] [--version <x.y.z>]
#   bash scripts/ci/verify_release_changelog_curated.sh --self-test

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
PREFIX="[verify_release_changelog_curated]"

# Historic sections (every version below this floor) are released history:
# they shipped before the curated-notes rule and rewriting them is out of scope
# (Phase 251 resolved research decision A1). Lowering this constant to skip a
# curated release is a visible diff, and the self-test pins that 1.7.0 itself
# is enforced.
CURATED_FROM=1.7.0

PACKAGES=(accrue accrue_admin accrue_portal)

# Superset of `^\* \*\*([0-9]{3}(-[0-9]+)?|phase-[0-9]+|quick-[0-9a-z]+):\*\*`:
# hyphenated suffixes (`quick-261008-lbv`, `247-post-review`) are matched too.
PHASE_BULLET_RE='^\* \*\*([0-9]{3}(-[0-9a-z]+)*|phase-[0-9]+(-[0-9a-z]+)*|quick-[0-9a-z]+(-[0-9a-z]+)*):\*\*'
CONVENTIONAL_RE='(feat|fix)\([0-9]{3}'
COMMIT_LINK_RE='\(\[[0-9a-f]{7}\]\(https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/commit/[0-9a-f]{40}\)\)'

fail() {
  echo "$PREFIX FAIL: $*" >&2
  exit 1
}

usage() {
  echo "usage: verify_release_changelog_curated.sh [--root <dir>] [--version <x.y.z>] | --self-test" >&2
  exit 2
}

is_stable_semver() {
  [[ "$1" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

# True when $1 sorts strictly below $2 as a version.
version_lt() {
  local lowest
  [[ "$1" != "$2" ]] || return 1
  lowest=$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)
  [[ "$lowest" == "$1" ]]
}

# Prints the body of the `## [<version>]` section; exit 3 when the heading is absent.
release_section() {
  local file=$1
  local version=$2

  awk -v heading="## [${version}]" '
    index($0, heading) == 1 { in_section = 1; found = 1; next }
    /^## \[/ && in_section { exit }
    in_section { print }
    END { exit found ? 0 : 3 }
  ' "$file"
}

# Counts lines of $1 matching any raw pattern. grep exit 1 (no match) is zero.
count_raw_lines() {
  local section=$1
  local count rc

  rc=0
  count=$(grep -E -c -e "$PHASE_BULLET_RE" -e "$CONVENTIONAL_RE" -e "$COMMIT_LINK_RE" <<<"$section") || rc=$?
  if [[ "$rc" -eq 1 ]]; then
    count=0
  elif [[ "$rc" -ne 0 ]]; then
    fail "grep failed (rc $rc) while scanning a CHANGELOG section"
  fi
  printf '%s\n' "$count"
}

run_check() {
  local root=$1
  local version=$2
  local manifest="$root/.release-please-manifest.json"
  local pkg file section rc count total=0 failed=0

  if [[ -z "$version" ]]; then
    command -v jq >/dev/null 2>&1 || fail "jq is required to read $manifest"
    [[ -f "$manifest" ]] || fail "missing $manifest"
    version=$(jq -r '.accrue // empty' "$manifest")
    [[ -n "$version" ]] || fail "$manifest has no accrue version"
  fi

  is_stable_semver "$version" || fail "version must be stable SemVer, got: $version"

  if version_lt "$version" "$CURATED_FROM"; then
    echo "$PREFIX $version: grandfathered (released before the curated-notes rule, which applies from $CURATED_FROM)"
    return 0
  fi

  for pkg in "${PACKAGES[@]}"; do
    file="$root/$pkg/CHANGELOG.md"
    if [[ ! -f "$file" ]]; then
      echo "$PREFIX FAIL: missing $pkg/CHANGELOG.md" >&2
      failed=1
      continue
    fi

    rc=0
    section=$(release_section "$file" "$version") || rc=$?
    if [[ "$rc" -eq 3 ]]; then
      echo "$PREFIX FAIL: $pkg/CHANGELOG.md has no ## [$version] section" >&2
      failed=1
      continue
    elif [[ "$rc" -ne 0 ]]; then
      fail "awk failed (rc $rc) reading $pkg/CHANGELOG.md"
    fi

    if [[ -z "${section//[[:space:]]/}" ]]; then
      echo "$PREFIX FAIL: $pkg/CHANGELOG.md ## [$version] section is empty" >&2
      failed=1
      continue
    fi

    count=$(count_raw_lines "$section")
    echo "$pkg: $count raw line(s)"
    total=$((total + count))
  done

  if [[ "$total" -ne 0 ]]; then
    echo "$PREFIX FAIL: $total raw release-please line(s) in the ## [$version] sections; curate them into adopter-readable notes" >&2
    failed=1
  fi

  [[ "$failed" -eq 0 ]] || exit 1
  echo "$PREFIX OK ($version): curated release sections"
}

# ---------------------------------------------------------------------------
# Self-test
# ---------------------------------------------------------------------------

SELFTEST_TMP=""

cleanup_selftest() {
  [[ -z "$SELFTEST_TMP" ]] || rm -rf "$SELFTEST_TMP"
}

CURATED_BODY='### Release highlights

- Portal checkout now confirms the selected billing context before it charges.
- Admin lists keep their filters when you return from a detail page.
* **Portal:** bold product labels are adopter-readable and allowed.

### Notes

- Compatibility only: linked 1.7.0 line; core package owns billing behavior.'

RAW_PHASE_BODY='### Features

* **233-05:** add host shared billing context adapter'

RAW_SUFFIXED_BODY='### Bug Fixes

* **quick-261008-lbv:** fail closed on teardown errors
* **247-post-review:** close detail and timestamp gaps
* **phase-12-gap:** close audit findings'

RAW_CONVENTIONAL_BODY='### Features

- feat(233-05): add host shared billing context adapter'

RAW_LINK_BODY='### Features

* add host shared billing context adapter ([e4e9752](https://github.com/szTheory/accrue/commit/e4e975269b3d16689f1892151e2a6fe50017da83))'

# make_root <dir> <body-for-accrue_portal> [<section-version>] [<older raw 1.6.0 section: yes|no>]
make_root() {
  local dir=$1
  local portal_body=$2
  local section_version=${3-1.7.0}
  local with_old=${4:-no}
  local pkg body file

  mkdir -p "$dir"
  printf '{\n  "accrue": "%s",\n  "accrue_admin": "%s",\n  "accrue_portal": "%s"\n}\n' \
    "$section_version" "$section_version" "$section_version" >"$dir/.release-please-manifest.json"

  for pkg in "${PACKAGES[@]}"; do
    mkdir -p "$dir/$pkg"
    file="$dir/$pkg/CHANGELOG.md"
    body=$CURATED_BODY
    [[ "$pkg" != accrue_portal ]] || body=$portal_body
    {
      printf '# Changelog\n\n## Unreleased\n\n'
      if [[ -n "$section_version" ]]; then
        printf '## [%s](https://github.com/szTheory/accrue/compare/%s-v1.6.0...%s-v%s) (2026-10-26)\n\n%s\n\n' \
          "$section_version" "$pkg" "$pkg" "$section_version" "$body"
      fi
      if [[ "$with_old" == yes ]]; then
        printf '## [1.6.0](https://github.com/szTheory/accrue/compare/%s-v1.5.1...%s-v1.6.0) (2026-09-18)\n\n%s\n' \
          "$pkg" "$pkg" "$RAW_PHASE_BODY"
      fi
    } >"$file"
  done
}

# expect <label> <want-rc: 0|1> <needle> -- <args...>
expect() {
  local label=$1 want=$2 needle=$3
  shift 4
  local out rc=0

  out=$(bash "$SCRIPT_PATH" "$@" 2>&1) || rc=$?
  if [[ "$want" -eq 0 && "$rc" -ne 0 ]]; then
    printf '%s\n' "$out" >&2
    fail "self-test $label: expected PASS, got rc $rc"
  fi
  if [[ "$want" -ne 0 && "$rc" -eq 0 ]]; then
    printf '%s\n' "$out" >&2
    fail "self-test $label: expected FAIL, got rc 0 (the check cannot find a known positive)"
  fi
  grep -Fq -e "$needle" <<<"$out" || {
    printf '%s\n' "$out" >&2
    fail "self-test $label: output is missing: $needle"
  }
  echo "$PREFIX self-test $label: $( [[ "$want" -eq 0 ]] && echo PASS || echo FAIL ) as required ($needle)"
}

self_test() {
  SELFTEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/verify_release_changelog_curated.XXXXXX")
  trap cleanup_selftest EXIT
  local t=$SELFTEST_TMP

  make_root "$t/raw-phase" "$RAW_PHASE_BODY"
  expect "raw **233-05:** bullet" 1 "accrue_portal: 1 raw line(s)" -- --root "$t/raw-phase" --version 1.7.0

  make_root "$t/raw-suffixed" "$RAW_SUFFIXED_BODY"
  expect "suffixed **quick-261008-lbv:** / **247-post-review:** / **phase-12-gap:** bullets" 1 "accrue_portal: 3 raw line(s)" -- --root "$t/raw-suffixed" --version 1.7.0

  make_root "$t/raw-conventional" "$RAW_CONVENTIONAL_BODY"
  expect "feat(233-05) line" 1 "accrue_portal: 1 raw line(s)" -- --root "$t/raw-conventional" --version 1.7.0

  make_root "$t/raw-link" "$RAW_LINK_BODY"
  expect "hash-link-only bullet" 1 "accrue_portal: 1 raw line(s)" -- --root "$t/raw-link" --version 1.7.0

  make_root "$t/missing" "$CURATED_BODY" ""
  expect "missing ## [1.7.0] section" 1 "accrue_portal/CHANGELOG.md has no ## [1.7.0] section" -- --root "$t/missing" --version 1.7.0

  make_root "$t/empty" ""
  expect "empty ## [1.7.0] section" 1 "accrue_portal/CHANGELOG.md ## [1.7.0] section is empty" -- --root "$t/empty" --version 1.7.0

  make_root "$t/curated" "$CURATED_BODY"
  expect "curated section" 0 "OK (1.7.0): curated release sections" -- --root "$t/curated" --version 1.7.0

  # Default version comes from the manifest; 1.7.0 itself is enforced (floor is inclusive).
  expect "manifest 1.7.0 is enforced, not grandfathered" 1 "accrue_portal: 1 raw line(s)" -- --root "$t/raw-phase"

  make_root "$t/scoped" "$CURATED_BODY" 1.7.0 yes
  expect "curated 1.7.0 above raw 1.6.0 (section scoping)" 0 "OK (1.7.0): curated release sections" -- --root "$t/scoped" --version 1.7.0

  make_root "$t/historic" "$RAW_PHASE_BODY" 1.6.0
  expect "raw 1.6.0 under version 1.6.0" 0 "grandfathered (released before the curated-notes rule" -- --root "$t/historic" --version 1.6.0

  echo "$PREFIX self-test PASS (raw bullet, suffixed scopes, conventional line, hash link, missing section, empty section, curated, inclusive floor, section scoping, grandfathered)"
}

# ---------------------------------------------------------------------------

ROOT=""
VERSION=""
MODE=check

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -ge 2 ]] || usage
      ROOT=$2
      shift 2
      ;;
    --version)
      [[ $# -ge 2 ]] || usage
      VERSION=$2
      shift 2
      ;;
    --self-test)
      MODE=self-test
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if [[ "$MODE" == self-test ]]; then
  self_test
  exit 0
fi

if [[ -z "$ROOT" ]]; then
  ROOT=$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)
fi

run_check "$ROOT" "$VERSION"
