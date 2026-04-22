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

[[ -n "$m_accrue" ]] || fail "manifest missing non-empty .accrue version"
[[ -n "$m_admin" ]] || fail "manifest missing non-empty .accrue_admin version"

mix_accrue=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue/mix.exs" | head -n 1)
mix_admin=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue_admin/mix.exs" | head -n 1)

[[ -n "$mix_accrue" ]] || fail "could not parse @version from accrue/mix.exs"
[[ -n "$mix_admin" ]] || fail "could not parse @version from accrue_admin/mix.exs"

[[ "$m_accrue" == "$m_admin" ]] ||
  fail "manifest lockstep violated: accrue=$m_accrue accrue_admin=$m_admin"

[[ "$m_accrue" == "$mix_accrue" ]] ||
  fail "accrue: manifest version $m_accrue != mix.exs @version $mix_accrue"

[[ "$m_admin" == "$mix_admin" ]] ||
  fail "accrue_admin: manifest version $m_admin != mix.exs @version $mix_admin"

echo "OK: release manifest and mix.exs @version aligned at $m_accrue"
