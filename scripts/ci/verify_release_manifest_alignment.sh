#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "[verify_release_manifest_alignment] $*" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required but not installed"

MANIFEST="$ROOT_DIR/.release-please-manifest.json"
[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"

m_accrue=$(jq -r '.accrue // empty' "$MANIFEST")
m_admin=$(jq -r '.accrue_admin // empty' "$MANIFEST")
m_portal=$(jq -r '.accrue_portal // empty' "$MANIFEST")

[[ -n "$m_accrue" ]] || fail "manifest missing non-empty .accrue version"
[[ -n "$m_admin" ]] || fail "manifest missing non-empty .accrue_admin version"
[[ -n "$m_portal" ]] || fail "manifest missing non-empty .accrue_portal version"

mix_accrue=$(sed -n 's/^[[:space:]]*@version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue/mix.exs" | head -n 1)
mix_admin=$(sed -n 's/^[[:space:]]*@version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue_admin/mix.exs" | head -n 1)
mix_portal=$(sed -n 's/^[[:space:]]*@version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue_portal/mix.exs" | head -n 1)

[[ -n "$mix_accrue" ]] || fail "could not parse @version from accrue/mix.exs"
[[ -n "$mix_admin" ]] || fail "could not parse @version from accrue_admin/mix.exs"
[[ -n "$mix_portal" ]] || fail "could not parse @version from accrue_portal/mix.exs"

[[ "$m_accrue" == "$m_admin" ]] ||
  fail "manifest lockstep violated: accrue=$m_accrue accrue_admin=$m_admin"
[[ "$m_accrue" == "$m_portal" ]] ||
  fail "manifest lockstep violated: accrue=$m_accrue accrue_portal=$m_portal"

[[ "$m_accrue" == "$mix_accrue" ]] ||
  fail "accrue: manifest version $m_accrue != mix.exs @version $mix_accrue"

[[ "$m_admin" == "$mix_admin" ]] ||
  fail "accrue_admin: manifest version $m_admin != mix.exs @version $mix_admin"
[[ "$m_portal" == "$mix_portal" ]] ||
  fail "accrue_portal: manifest version $m_portal != mix.exs @version $mix_portal"

# Both sibling packages (accrue_admin, accrue_portal) must declare their
# core `:accrue` dependency with the same-minor operator, interpolating
# `@version` — never a hardcoded literal, which would silently stop
# tracking the attribute and drift unnoticed.
#
# Comment lines are excluded ONLY when the first non-whitespace character
# on the line is `#`. We deliberately do NOT strip inline `#` characters —
# the required form itself contains the `#{@version}` interpolation, and a
# naive inline-`#` strip would destroy that token and make this assertion
# vacuous.
EXPECTED_ACCRUE_DEP='{:accrue, "~> #{@version}"}'

check_sibling_accrue_dep() {
  local file="$1"
  local rel="${file#"$ROOT_DIR/"}"

  local candidates
  candidates=$(grep -n '{:accrue, "' "$file" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*#' || true)

  local count=0
  if [[ -n "$candidates" ]]; then
    count=$(printf '%s\n' "$candidates" | wc -l | tr -d '[:space:]')
  fi

  if [[ "$count" -eq 0 ]]; then
    fail "$rel: found 0 sibling accrue dependency declarations matching '{:accrue, \"...'; expected exactly 1 matching '$EXPECTED_ACCRUE_DEP'"
  fi

  if [[ "$count" -gt 1 ]]; then
    fail "$rel: found $count sibling accrue dependency declarations matching '{:accrue, \"...'; expected exactly 1 matching '$EXPECTED_ACCRUE_DEP'"
  fi

  local raw content
  raw=$(printf '%s\n' "$candidates" | cut -d: -f2-)
  content=$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  [[ "$content" == "$EXPECTED_ACCRUE_DEP" ]] ||
    fail "$rel: sibling accrue dependency declared as '$content', expected '$EXPECTED_ACCRUE_DEP' (same-minor operator interpolating @version, not a hardcoded version literal)"
}

check_sibling_accrue_dep "$ROOT_DIR/accrue_admin/mix.exs"
check_sibling_accrue_dep "$ROOT_DIR/accrue_portal/mix.exs"

echo "OK: release manifest and mix.exs @version aligned at $m_accrue (accrue, accrue_admin, accrue_portal); accrue_admin and accrue_portal both declare the interpolated same-minor accrue constraint ($EXPECTED_ACCRUE_DEP)"
