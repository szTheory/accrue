#!/usr/bin/env bash
# Prune first-party apps from a restored Mix build env dir (quick task 261025-vdn).
#
# CI caches third-party `_build/<env>` trees to skip ~9 minutes of deps
# compile. A cached first-party app must never survive into a run: Mix would
# treat its .beam files as up to date and could skip recompiling a module,
# so a new warning (and `--warnings-as-errors`) would not fire. This script
# runs immediately after every `_build` cache restore and deletes the
# first-party app dirs so they always compile fresh; the cache save steps
# also exclude them. The warm-vs-cold compile-rc matrix in the 261025-vdn
# SUMMARY proves a planted first-party warning fails identically on a pruned
# warm `_build` and on a cold one.
#
# Usage: prune_first_party_build.sh <build_env_dir>   (e.g. accrue/_build/test)
#        prune_first_party_build.sh --self-test
set -euo pipefail

# accrue_host's `sigra` is a path dep when ACCRUE_SIGRA_PATH is set, so it is
# treated as first-party too.
FIRST_PARTY_APPS=(accrue accrue_admin accrue_portal accrue_host sigra)

prune() {
  local env_dir="$1"
  if [ ! -d "$env_dir/lib" ]; then
    echo "prune_first_party_build: nothing restored at $env_dir (no lib/ dir); nothing to prune"
    return 0
  fi
  local app removed=0
  for app in "${FIRST_PARTY_APPS[@]}"; do
    if [ -e "$env_dir/lib/$app" ]; then
      rm -rf "${env_dir:?}/lib/$app"
      echo "prune_first_party_build: removed $env_dir/lib/$app"
      removed=$((removed + 1))
    fi
  done
  echo "prune_first_party_build: $removed first-party app dir(s) removed from $env_dir; third-party dirs kept: $(find "$env_dir/lib" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
}

# The self-test's expectations are spelled out independently of
# FIRST_PARTY_APPS, so emptying or shortening that list cannot also weaken
# the assertion that checks it.
EXPECTED_PRUNED=(accrue accrue_admin accrue_portal accrue_host sigra)
EXPECTED_KEPT=(jason plug)

seed_fake_build() {
  local env_dir="$1" app
  for app in "${EXPECTED_PRUNED[@]}" "${EXPECTED_KEPT[@]}"; do
    mkdir -p "$env_dir/lib/$app/ebin"
    touch "$env_dir/lib/$app/ebin/$app.app"
  done
}

# Returns non-zero (and names the problem) unless exactly EXPECTED_PRUNED is
# gone and every EXPECTED_KEPT dir survived.
assert_pruned() {
  local env_dir="$1" app ok=0
  for app in "${EXPECTED_PRUNED[@]}"; do
    if [ -e "$env_dir/lib/$app" ]; then echo "  assertion: first-party $app survived the prune"; ok=1; fi
  done
  for app in "${EXPECTED_KEPT[@]}"; do
    if [ ! -f "$env_dir/lib/$app/ebin/$app.app" ]; then echo "  assertion: third-party $app was removed"; ok=1; fi
  done
  return "$ok"
}

self_test() {
  local tmp status=0 out
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  # Positive case: exactly the five first-party dirs go; jason and plug stay.
  seed_fake_build "$tmp/positive/_build/test"
  prune "$tmp/positive/_build/test" >/dev/null
  if assert_pruned "$tmp/positive/_build/test"; then
    echo "self-test: positive case OK (removed ${EXPECTED_PRUNED[*]}; kept ${EXPECTED_KEPT[*]})"
  else
    echo "self-test FAIL: positive case"; status=1
  fi

  # Missing-dir case: a cache miss restores nothing; exit 0 and say so.
  if out="$(prune "$tmp/missing/_build/test")"; then
    case "$out" in
      *"nothing restored"*) echo "self-test: missing-dir case OK" ;;
      *) echo "self-test FAIL: missing dir did not print 'nothing restored'"; status=1 ;;
    esac
  else
    echo "self-test FAIL: missing dir exited non-zero"; status=1
  fi

  # Negative control: run the SAME positive assertion after a prune with an
  # emptied list. It must fail; if it passed, the assertion could not detect
  # a no-op prune and the positive case would prove nothing.
  seed_fake_build "$tmp/negative/_build/test"
  (FIRST_PARTY_APPS=(); prune "$tmp/negative/_build/test" >/dev/null)
  if assert_pruned "$tmp/negative/_build/test" >/dev/null; then
    echo "self-test FAIL: negative control -- the assertion passed on a no-op prune"; status=1
  else
    echo "self-test: negative control OK (an emptied prune list fails the positive assertion)"
  fi

  if [ "$status" -eq 0 ]; then
    echo "prune_first_party_build: self-test PASS (positive, missing-dir, negative control)"
  else
    echo "prune_first_party_build: self-test FAIL"
  fi
  return "$status"
}

case "${1:-}" in
  --self-test) self_test ;;
  "") echo "usage: $0 <build_env_dir> | --self-test" >&2; exit 2 ;;
  *) prune "$1" ;;
esac
