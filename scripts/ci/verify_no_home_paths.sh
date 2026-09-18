#!/usr/bin/env bash
# Fail when tracked (or staged) content embeds an absolute home directory whose
# user segment is not a known placeholder.
#
# DESIGN CONSTRAINT: this file is committed and published, so it must never
# contain a real username. It matches the CLASS /Users/<x> and /home/<x> and
# allowlists generic placeholders; it never names anyone. Offending values are
# redacted in output so the guard cannot leak what it guards against.
#
# Usage:
#   verify_no_home_paths.sh --repo      # working tree, all tracked files (CI)
#   verify_no_home_paths.sh --staged    # index content only (pre-commit hook)
#   verify_no_home_paths.sh --self-test # fixture-driven positive/negative controls
set -uo pipefail

ALLOWED_USERS='dev|example|someone|private|runner|ci|user|home|root|maintainer|adopter'
PATTERN='/(Users|home)/[A-Za-z0-9._-]+'

# This guard and the hook that shares it both spell out the pattern itself.
SELF_EXEMPT='^(scripts/ci/verify_no_home_paths\.sh|\.githooks/pre-commit)$'

scan() { # $1: extra git-grep flags ("" or --cached)
  local cached="$1"; shift
  # shellcheck disable=SC2086
  git grep -I -h -o $cached -E "$PATTERN" -- "$@" 2>/dev/null \
    | grep -vEi "^$PATTERN\$" >/dev/null 2>&1 || true
}

report() { # $1: --cached|""   rest: pathspecs
  local cached="$1"; shift
  local hits
  # shellcheck disable=SC2086
  hits="$(git grep -I -n -o $cached -E "$PATTERN" -- "$@" 2>/dev/null \
    | awk -F: -v allow="^/(Users|home)/($ALLOWED_USERS)\$" '
        { m=$NF; if (m !~ allow) print $1 }
      ' \
    | grep -vE "$SELF_EXEMPT" \
    | sort -u)"
  printf '%s' "$hits"
}

MODE="${1:---repo}"
ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$ROOT" || exit 1

case "$MODE" in
  --repo)   OFFENDERS="$(report "" .)" ;;
  --staged)
    mapfile -t STAGED < <(git diff --cached --name-only --diff-filter=ACMR)
    if [ "${#STAGED[@]}" -eq 0 ]; then echo "verify_no_home_paths: OK (no staged files)"; exit 0; fi
    OFFENDERS="$(report --cached "${STAGED[@]}")"
    ;;
  --self-test)
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    git init -q "$tmp" && cd "$tmp" || exit 1
    printf 'ok /Users/dev/x\n' > good.md
    git add good.md && git -c user.email=t@e.co -c user.name=t commit -qm seed
    if ! bash "$ROOT/scripts/ci/verify_no_home_paths.sh" --repo >/dev/null 2>&1; then
      echo "verify_no_home_paths: SELF-TEST FAIL (placeholder path was rejected)" >&2; exit 1
    fi
    printf 'bad /Users/realperson/x\n' > bad.md
    git add bad.md && git -c user.email=t@e.co -c user.name=t commit -qm bad
    if bash "$ROOT/scripts/ci/verify_no_home_paths.sh" --repo >/dev/null 2>&1; then
      echo "verify_no_home_paths: SELF-TEST FAIL (non-placeholder path was accepted)" >&2; exit 1
    fi
    echo "verify_no_home_paths: SELF-TEST OK (placeholder accepted, non-placeholder rejected)"
    exit 0
    ;;
  *) echo "verify_no_home_paths: unknown option: $MODE" >&2; exit 2 ;;
esac

if [ -n "$OFFENDERS" ]; then
  echo "verify_no_home_paths: FAIL -- absolute home path with a non-placeholder user:" >&2
  printf '%s\n' "$OFFENDERS" | sed 's/^/    /' >&2
  echo "Use a placeholder such as /Users/dev (allowed: ${ALLOWED_USERS//|/, })." >&2
  exit 1
fi
echo "verify_no_home_paths: OK (mode ${MODE#--})"
