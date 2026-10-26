#!/usr/bin/env bash
# Release merge gate for the 1.7.0 release PR (plan 251-06, RLS-01 + RLS-02).
#
# The Hex publish that follows the merge is irreversible, so this gate (not a person)
# decides whether the release PR may be merged. It runs every check, prints one
# `PASS: <n> <name>` or `FAIL: <n> <name>: <reason>` line per check, and exits 1 if any
# check failed. Every check fails closed: a non-zero exit from any tool it calls, empty
# output where output is expected, an unreachable remote, or an HTTP code other than the
# exact expected one is a FAIL, never a PASS.
#
#   bash 251-release-merge-gate.sh --pr <R> --sha <A> --freeze-sha <FREEZE_SHA> \
#        --baseline-run <ci.yml run id> [--ghrel-output <file>] [--control]
#
# Test hooks (controls only):
#   --ghrel-output <file>   parse a saved github-release dry-run output instead of running one
#   RELEASE_PLEASE_BIN      replaces the dry-run command (default: npx --yes release-please@17.6.0)
# When a hook is active the gate prints `NOTE: test hook active`, and unless --control is
# also passed it FAILs check 0, so a leftover hook can never stand in for the real dry run.
#
# This file ships no token. The GitHub token is read from `gh auth token` at run time and
# passed only to the read-only dry run; it is never echoed.

set -euo pipefail

REPO=szTheory/accrue
VERSION=1.7.0
PRIOR_VERSION=1.6.0
PACKAGES=(accrue accrue_admin accrue_portal)
RELEASE_BRANCH=release-please--branches--main
DEFAULT_RP_BIN="npx --yes release-please@17.6.0"
# GHREL_MARKER pinned by plan 251-04 (.planning/251-remote-writes.local). It is the last
# success-prefixed status line common to both completed 251-04 dry runs, so it marks that
# a dry run STARTED building releases; the completion proof is exit 0 plus the count line.
GHREL_MARKER='✔ Building strategies by path'

PR=""; SHA=""; FREEZE=""; BASELINE=""; GHREL_FILE=""; GHREL_FILE_SET=0; CONTROL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pr) PR="$2"; shift ;;
    --sha) SHA="$2"; shift ;;
    --freeze-sha) FREEZE="$2"; shift ;;
    --baseline-run) BASELINE="$2"; shift ;;
    --ghrel-output) GHREL_FILE="$2"; GHREL_FILE_SET=1; shift ;;
    --control) CONTROL=1 ;;
    -h|--help) sed -n 2,22p "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 64 ;;
  esac
  shift
done
for v in PR SHA FREEZE BASELINE; do
  if [ -z "${!v}" ]; then echo "missing required argument for $v" >&2; exit 64; fi
done
if ! [[ "$SHA" =~ ^[0-9a-f]{40}$ && "$FREEZE" =~ ^[0-9a-f]{40}$ ]]; then
  echo "--sha and --freeze-sha must be 40-hex SHAs" >&2; exit 64
fi

cd "$(git rev-parse --show-toplevel)"
ROOT="$PWD"
: "${GSD_SCRATCH:?GSD_SCRATCH must be set}"
WORK="$(mktemp -d "$GSD_SCRATCH/251-merge-gate.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

HELPER="$ROOT/.planning/phases/250-remote-integration/250-ci-head-status.mjs"
FAILS=()
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1: $2"; FAILS+=("$1"); }
# run <outfile> <cmd...>: runs a command capturing combined output; prints the exit status.
run() { local out="$1"; shift; local rc=0; "$@" >"$out" 2>&1 || rc=$?; echo "$rc"; }

echo "gate: pr=$PR sha=$SHA freeze=$FREEZE baseline=$BASELINE control=$CONTROL"

# ------------------------------------------------------------------ 0 test hooks
HOOKS=()
[ "$GHREL_FILE_SET" = 1 ] && HOOKS+=("--ghrel-output")
[ -n "${RELEASE_PLEASE_BIN+x}" ] && HOOKS+=("RELEASE_PLEASE_BIN")
if [ "${#HOOKS[@]}" -gt 0 ]; then
  echo "NOTE: test hook active: ${HOOKS[*]}"
  if [ "$CONTROL" = 1 ]; then pass "0 test hooks (control run)"; else
    fail "0 test hooks" "test hook set without --control (${HOOKS[*]}); a real gate run must have no hooks"
  fi
else
  pass "0 test hooks (none active)"
fi

# ------------------------------------------------------------------ 1 PR state
rc=$(run "$WORK/pr.json" gh pr view "$PR" --repo "$REPO" --json state,isDraft,baseRefName,title,headRefOid,body)
if [ "$rc" != 0 ] || [ ! -s "$WORK/pr.json" ]; then
  fail "1 release PR state" "gh pr view exited $rc or printed nothing"
else
  pr_line="$(jq -r '[.state,(.isDraft|tostring),.baseRefName,.title,.headRefOid]|@tsv' "$WORK/pr.json" 2>/dev/null)" && jrc=0 || jrc=$?
  want="$(printf 'OPEN\tfalse\tmain\tchore: release main\t%s' "$SHA")"
  if [ "$jrc" != 0 ] || [ -z "$pr_line" ]; then fail "1 release PR state" "could not parse gh pr view output"
  elif [ "$pr_line" != "$want" ]; then fail "1 release PR state" "got [$(echo "$pr_line" | tr '\t' '|')], want [OPEN|false|main|chore: release main|$SHA]"
  else pass "1 release PR state (OPEN, not draft, base main, title, head $SHA)"; fi
fi

# ------------------------------------------------------------------ 2 main frozen (live)
rc=$(run "$WORK/main.ls" git ls-remote origin refs/heads/main)
main_live="$(cut -f1 "$WORK/main.ls" 2>/dev/null || true)"
if [ "$rc" != 0 ] || [ -z "$main_live" ]; then fail "2 main frozen" "git ls-remote exited $rc or printed nothing"
elif [ "$(wc -l <"$WORK/main.ls" | tr -d ' ')" != 1 ] || [ "$main_live" != "$FREEZE" ]; then
  fail "2 main frozen" "live origin main is $main_live, want $FREEZE"
else pass "2 main frozen (live origin main = $FREEZE)"; fi

# Refresh the remote-tracking refs the helper and check 5 use.
fetch_rc=$(run "$WORK/fetch.out" git fetch -q origin main "$RELEASE_BRANCH")

# ------------------------------------------------------------------ 3 exact head green (PR)
# --pr-base origin/main: local main is not maintained as a mirror of origin (251-04 deviation 3);
# the fetch above refreshes origin/main, and check 2 proves the live value.
if [ "$fetch_rc" != 0 ]; then fail "3 head CI green" "git fetch exited $fetch_rc"
else
  rc=$(run "$WORK/ci-pr.out" node "$HELPER" --repo "$REPO" --sha "$SHA" --event pull_request --pr-base origin/main)
  if [ "$rc" = 0 ] && grep -q -e "GREEN at $SHA" "$WORK/ci-pr.out"; then pass "3 head CI green (pull_request at $SHA)"
  else fail "3 head CI green" "250-ci-head-status exited $rc: $(grep -m1 -E 'RED|PENDING|error|GREEN' "$WORK/ci-pr.out" || head -c 200 "$WORK/ci-pr.out")"; fi
fi

# ------------------------------------------------------------------ 4 main green (push)
rc=$(run "$WORK/ci-main.out" node "$HELPER" --repo "$REPO" --sha "$FREEZE" --event push --baseline-run "$BASELINE")
if [ "$rc" = 0 ] && grep -q -e "GREEN at $FREEZE" "$WORK/ci-main.out"; then pass "4 main CI green (push at $FREEZE)"
else fail "4 main CI green" "250-ci-head-status exited $rc: $(grep -m1 -E 'RED|PENDING|error|GREEN' "$WORK/ci-main.out" || head -c 200 "$WORK/ci-main.out")"; fi

# ------------------------------------------------------------------ 5 content gates on archive of SHA
ARCH="$WORK/archive"; mkdir -p "$ARCH"
if git archive "$SHA" >"$WORK/archive.tar" 2>"$WORK/archive.err" && [ -s "$WORK/archive.tar" ] \
   && tar -x -C "$ARCH" -f "$WORK/archive.tar" 2>>"$WORK/archive.err" && [ -f "$ARCH/scripts/ci/verify_package_docs.sh" ]; then
  c5=()
  for g in verify_release_notes_contract verify_release_manifest_alignment verify_release_changelog_curated; do
    grc=0; (cd "$ARCH" && ROOT_DIR="$ARCH" bash "scripts/ci/$g.sh") >"$WORK/c5-$g.out" 2>&1 || grc=$?
    if [ "$grc" != 0 ] || [ ! -s "$WORK/c5-$g.out" ]; then c5+=("$g rc=$grc: $(tail -n1 "$WORK/c5-$g.out")"); fi
  done
  grc=0; (cd "$ARCH" && env -u RELEASE_PLEASE_PR ROOT_DIR="$ARCH" bash scripts/ci/verify_package_docs.sh) >"$WORK/c5-pkgdocs.out" 2>&1 || grc=$?
  if [ "$grc" != 0 ] || ! grep -q -e '^fixed invariants checked:' "$WORK/c5-pkgdocs.out"; then
    c5+=("verify_package_docs rc=$grc: $(grep -m1 -i -e 'missing' -e 'error' "$WORK/c5-pkgdocs.out" || tail -n1 "$WORK/c5-pkgdocs.out")")
  fi
  if [ "${#c5[@]}" = 0 ]; then pass "5 content gates on archive of $SHA (notes, manifest, curated CHANGELOG, package docs)"
  else fail "5 content gates on archive" "$(printf '%s; ' "${c5[@]}")"; fi
else
  fail "5 content gates on archive" "git archive of $SHA failed: $(head -c 200 "$WORK/archive.err")"
fi

# ------------------------------------------------------------------ 6 PR scope
rc=$(run "$WORK/scope.out" bash scripts/ci/verify_release_pr_scope.sh --pr "$PR" --version "$VERSION")
if [ "$rc" = 0 ] && [ -s "$WORK/scope.out" ]; then pass "6 release PR scope ($VERSION)"
else fail "6 release PR scope" "verify_release_pr_scope.sh exited $rc: $(tail -n2 "$WORK/scope.out" | tr '\n' ' ')"; fi

# ------------------------------------------------------------------ 7 no stale pending label
rc1=$(run "$WORK/pend-merged.out" gh pr list --repo "$REPO" --state merged --label "autorelease: pending" --json number --jq '[.[].number]|tostring')
rc2=$(run "$WORK/pend-open.out" gh pr list --repo "$REPO" --state open --label "autorelease: pending" --json number --jq '[.[].number]|tostring')
merged_p="$(cat "$WORK/pend-merged.out")"; open_p="$(cat "$WORK/pend-open.out")"
if [ "$rc1" != 0 ] || [ "$rc2" != 0 ] || [ -z "$merged_p" ] || [ -z "$open_p" ]; then
  fail "7 pending label" "gh pr list exited $rc1/$rc2 or printed nothing"
elif [ "$open_p" != "[$PR]" ]; then fail "7 pending label" "positive control: open pending PRs are $open_p, want [$PR]"
elif [ "$merged_p" != "[]" ]; then fail "7 pending label" "merged PRs still labelled autorelease: pending: $merged_p"
else pass "7 pending label (merged pending [], open pending [$PR])"; fi

# ------------------------------------------------------------------ 8 nothing published yet
c8=()
hex_code() { curl -s -o /dev/null -w '%{http_code}' --max-time 30 "https://hex.pm/api/packages/$1/releases/$2" 2>/dev/null; }
# Positive controls first: the prior release's tags, releases and Hex versions are visible.
rc=$(run "$WORK/tags-prior.out" git ls-remote --tags origin "refs/tags/accrue*-v$PRIOR_VERSION")
n_prior="$(grep -c -v -e '\^{}$' "$WORK/tags-prior.out" || true)"
[ "$rc" = 0 ] && [ "$n_prior" = 3 ] || c8+=("control: ls-remote rc=$rc found $n_prior v$PRIOR_VERSION tags, want 3")
for p in "${PACKAGES[@]}"; do
  code="$(hex_code "$p" "$PRIOR_VERSION")" || code="curl-error"
  [ "$code" = 200 ] || c8+=("control: hex.pm $p $PRIOR_VERSION returned $code, want 200")
  rrc=$(run "$WORK/rel-prior-$p.out" gh release view "$p-v$PRIOR_VERSION" --repo "$REPO" --json tagName --jq .tagName)
  [ "$rrc" = 0 ] && [ "$(cat "$WORK/rel-prior-$p.out")" = "$p-v$PRIOR_VERSION" ] || c8+=("control: gh release view $p-v$PRIOR_VERSION rc=$rrc")
done
if [ "${#c8[@]}" = 0 ]; then
  rc=$(run "$WORK/tags-new.out" git ls-remote --tags origin "refs/tags/accrue*-v$VERSION")
  if [ "$rc" != 0 ]; then c8+=("ls-remote for v$VERSION exited $rc")
  elif [ -s "$WORK/tags-new.out" ]; then c8+=("v$VERSION tags already exist: $(cut -f2 "$WORK/tags-new.out" | tr '\n' ' ')"); fi
  for p in "${PACKAGES[@]}"; do
    rrc=$(run "$WORK/rel-new-$p.out" gh release view "$p-v$VERSION" --repo "$REPO" --json tagName)
    if [ "$rrc" = 0 ]; then c8+=("GitHub release $p-v$VERSION already exists")
    elif ! grep -q -i -e 'release not found' "$WORK/rel-new-$p.out"; then c8+=("gh release view $p-v$VERSION failed for a reason other than not-found (rc=$rrc)"); fi
    code="$(hex_code "$p" "$VERSION")" || code="curl-error"
    [ "$code" = 404 ] || c8+=("hex.pm $p $VERSION returned $code, want exactly 404")
  done
fi
if [ "${#c8[@]}" = 0 ]; then pass "8 nothing published (controls: 3 v$PRIOR_VERSION tags, releases, Hex 200; v$VERSION: no tags, no releases, Hex 404)"
else fail "8 nothing published" "$(printf '%s; ' "${c8[@]}")"; fi

# ------------------------------------------------------------------ 9 github-release dry run + PR body
c9=()
GHREL="$WORK/ghrel.out"
if [ "$GHREL_FILE_SET" = 1 ]; then
  if [ ! -f "$GHREL_FILE" ]; then c9+=("--ghrel-output file does not exist: $GHREL_FILE"); : >"$GHREL"
  else cp "$GHREL_FILE" "$GHREL"; ghrc=0; fi
else
  RP_BIN="${RELEASE_PLEASE_BIN-$DEFAULT_RP_BIN}"
  RPDIR="$WORK/rp-main"; mkdir -p "$RPDIR"
  if git archive "$FREEZE" >"$WORK/rp.tar" 2>/dev/null && tar -x -C "$RPDIR" -f "$WORK/rp.tar" 2>/dev/null; then
    tok_rc=0; TOKEN="$(gh auth token 2>/dev/null)" || tok_rc=$?
    if [ "$tok_rc" != 0 ] || [ -z "$TOKEN" ]; then c9+=("gh auth token unavailable (rc=$tok_rc)"); : >"$GHREL"
    else
      ghrc=0
      # shellcheck disable=SC2086 # RP_BIN is a command line by design (test hook)
      (cd "$RPDIR" && $RP_BIN github-release --dry-run --repo-url "$REPO" --target-branch main \
        --config-file release-please-config.json --manifest-file .release-please-manifest.json \
        --token "$TOKEN") >"$GHREL" 2>&1 || ghrc=$?
      unset TOKEN
      [ "$ghrc" = 0 ] || c9+=("dry run exited $ghrc")
    fi
  else c9+=("git archive of $FREEZE for the dry run failed"); : >"$GHREL"; fi
fi
if [ ! -s "$GHREL" ]; then c9+=("dry-run output is empty")
else
  grep -q -F -e "$GHREL_MARKER" "$GHREL" || c9+=("dry-run output lacks the GHREL_MARKER '$GHREL_MARKER'")
  if grep -q -E -e 'pullNumber:' "$GHREL"; then
    c9+=("dry run would tag a stale release PR: $(grep -E -o -e 'pullNumber: *[0-9]+' "$GHREL" | sort -u | tr '\n' ' ')")
  fi
  nonzero="$(grep -E -o -e 'Would tag [0-9]+ release' "$GHREL" | grep -v -e 'Would tag 0 release' || true)"
  [ -z "$nonzero" ] || c9+=("dry run reports '$nonzero'")
  grep -q -E -e 'Would tag 0 releases' "$GHREL" || c9+=("dry run lacks the completion line 'Would tag 0 releases'")
fi
if [ -s "$WORK/pr.json" ] && body="$(jq -r .body "$WORK/pr.json" 2>/dev/null)" && [ -n "$body" ]; then
  summaries="$(printf '%s\n' "$body" | grep -E -o -e '<details><summary>[^<]*</summary>' | sed -e 's/<details><summary>//' -e 's/<\/summary>//')" || true
  want_s="$(printf 'accrue: %s\naccrue_admin: %s\naccrue_portal: %s' "$VERSION" "$VERSION" "$VERSION")"
  [ "$(printf '%s\n' "$summaries" | sort)" = "$want_s" ] || c9+=("PR body components are [$(printf '%s' "$summaries" | tr '\n' ',')], want exactly the three $VERSION components")
else c9+=("PR body unavailable")
fi
if [ "${#c9[@]}" = 0 ]; then pass "9 github-release dry run (marker, Would tag 0, no pullNumber) and 3 PR body components"
else fail "9 github-release dry run" "$(printf '%s; ' "${c9[@]}")"; fi

# ------------------------------------------------------------------ verdict
if [ "${#FAILS[@]}" -gt 0 ]; then
  echo "gate: ${#FAILS[@]} check(s) failed: ${FAILS[*]}"
  exit 1
fi
echo "gate: all checks passed"
