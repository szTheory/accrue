#!/usr/bin/env bash
#
# Phase 251 (RLS-01): the Release Please workflow must never force-write the
# release branch, and a merged-but-still-pending release PR must turn the
# workflow red instead of leaving it silently green.
#
# MECHANISM (PR #50, and earlier #26/#28/#33). The old "stale-base repair"
# reset `release-please--branches--main` to the tip of main and force-pushed
# it whenever main had moved past the PR's base, then re-ran `release-pr`.
# release-please only rebuilds its release commit when the computed PR body
# changes. After a docs-only push to main the notes are identical, so
# release-please logged "remained the same" and never re-created the commit:
# the release branch was left equal to a main commit, the PR showed 0 changed
# files, and GitHub auto-marked it merged with `autorelease: pending` still
# set. That reset is unrecoverable by automation, so it is banned outright.
#
# Usage:
#   verify_release_branch_repair_safety.sh [--repo <root>]   # static rule (default: this repo)
#   verify_release_branch_repair_safety.sh --workflow <file> # static rule on one file (test hook)
#   verify_release_branch_repair_safety.sh --self-test       # fixture-driven controls
#
# Static rule, applied to .github/workflows/release-please.yml with YAML/shell
# comment lines blanked first (a comment can neither satisfy nor trip a rule):
#   forbidden: any forced `git push` (--force, --force-with-lease, -f, +refspec)
#   forbidden: git checkout -B "$release_branch" "$expected_base"
#   required:  the wedge detector query `--state merged --label 'autorelease: pending'`
#              with an `exit 1`, in a job whose key is not `release` and which no
#              `needs:` in the file names (a detector false positive must never be
#              able to skip a Hex publish job)
#   required:  bash scripts/ci/verify_release_pr_scope.sh --pr "$release_pr_number"

set -euo pipefail
shopt -s inherit_errexit

PREFIX="[verify_release_branch_repair_safety]"
DETECTOR_QUERY="--state merged --label 'autorelease: pending'"
SCOPE_CANARY='bash scripts/ci/verify_release_pr_scope.sh --pr "$release_pr_number"'
RESET_LINE='git checkout -B "$release_branch" "$expected_base"'
LEGACY_SHA="db1b6d85b8ecb94d1d4d781591a6bf0ad88a2401"

fail() {
  echo "$PREFIX $*" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Static rule
# ---------------------------------------------------------------------------

# Print the workflow with comment-only lines blanked (line numbers preserved).
strip_comments() {
  awk '{ if ($0 ~ /^[[:space:]]*#/) print ""; else print $0 }' "$1"
}

# For each line, print "<lineno>\t<job key or ->\t<text>".
annotate_jobs() {
  awk '
    BEGIN { in_jobs = 0; job = "-" }
    /^jobs:[[:space:]]*$/ { in_jobs = 1; job = "-"; printf "%d\t-\t%s\n", NR, $0; next }
    /^[^[:space:]]/ { in_jobs = 0; job = "-" }
    in_jobs && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ {
      job = $0; sub(/^  /, "", job); sub(/:.*$/, "", job)
    }
    { printf "%d\t%s\t%s\n", NR, job, $0 }
  '
}

# Print every job key named in any `needs:` (inline scalar, flow list, or block list).
needed_jobs() {
  awk '
    function emit(list,   n, i, parts, item) {
      gsub(/[][]/, "", list)
      n = split(list, parts, /[[:space:],]+/)
      for (i = 1; i <= n; i++) {
        item = parts[i]
        gsub(/["\047]/, "", item)
        if (item != "") print item
      }
    }
    {
      if (block_indent >= 0) {
        if ($0 ~ /^[[:space:]]*-[[:space:]]*/) {
          match($0, /^[[:space:]]*/)
          if (RLENGTH >= block_indent) {
            item = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", item); emit(item); next
          }
        }
        if ($0 !~ /^[[:space:]]*$/) block_indent = -1
      }
    }
    /^[[:space:]]+needs:/ {
      value = $0; sub(/^[[:space:]]+needs:[[:space:]]*/, "", value)
      if (value == "") { match($0, /^[[:space:]]*/); block_indent = RLENGTH } else emit(value)
    }
    BEGIN { block_indent = -1 }
  '
}

check_workflow() {
  local workflow=$1
  local label=${2:-$1}
  local text annotated needed violations="" line lineno job content
  local detector_jobs="" good_detector=""

  [ -f "$workflow" ] || { echo "$PREFIX $label: workflow file not found" >&2; return 1; }

  text="$(strip_comments "$workflow")"
  annotated="$(annotate_jobs <<<"$text")"
  needed="$(needed_jobs <<<"$text")"

  while IFS=$'\t' read -r lineno job content; do
    [ -n "$lineno" ] || continue
    if [[ "$content" =~ git[[:space:]]+push ]]; then
      if [[ "$content" =~ --force ]] ||
         [[ "$content" =~ (^|[[:space:]])-f([[:space:]]|$) ]] ||
         [[ "$content" =~ [[:space:]]\+[^[:space:]] ]]; then
        line="${content#"${content%%[![:space:]]*}"}"
        violations+="$label:$lineno: forbidden force push (automation must never force-write the release branch): $line"$'\n'
      fi
    fi
    if [[ "$content" == *"$RESET_LINE"* ]]; then
      line="${content#"${content%%[![:space:]]*}"}"
      violations+="$label:$lineno: forbidden reset of the release branch to the target-branch tip: $line"$'\n'
    fi
    if [[ "$content" == *"$DETECTOR_QUERY"* ]]; then
      detector_jobs+="$job"$'\n'
    fi
  done <<<"$annotated"

  if [ -z "$detector_jobs" ]; then
    violations+="$label: missing merged-but-pending wedge detector: $DETECTOR_QUERY"$'\n'
  else
    while IFS= read -r job; do
      [ -n "$job" ] || continue
      if [ "$job" = "release" ]; then
        violations+="$label: wedge detector sits in the release job (it must be its own job so it cannot block publish outputs)"$'\n'
        continue
      fi
      if [ "$job" = "-" ]; then
        violations+="$label: wedge detector is outside any job"$'\n'
        continue
      fi
      if [ -n "$needed" ] && [[ $'\n'"$needed"$'\n' == *$'\n'"$job"$'\n'* ]]; then
        violations+="$label: wedge detector job '$job' is named in a needs: list (a false positive could skip a publish job)"$'\n'
        continue
      fi
      # The detector job must actually fail: an `exit 1` inside the same job.
      local job_text
      job_text="$(awk -F'\t' -v j="$job" '$2 == j { print $3 }' <<<"$annotated")"
      if [[ "$job_text" =~ (^|[[:space:]])exit[[:space:]]+1([[:space:]]|$) ]]; then
        good_detector="$job"
      else
        violations+="$label: wedge detector job '$job' never runs exit 1"$'\n'
      fi
    done <<<"$detector_jobs"
  fi

  if [[ "$text" != *"$SCOPE_CANARY"* ]]; then
    violations+="$label: missing release-PR scope canary: $SCOPE_CANARY"$'\n'
  fi

  if [ -n "$violations" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && echo "$PREFIX FAIL: $line" >&2
    done <<<"$violations"
    return 1
  fi

  echo "$PREFIX OK: $label has no release-branch force write; wedge detector in job '$good_detector'; scope canary present"
}

# ---------------------------------------------------------------------------
# Self-test fixtures
# ---------------------------------------------------------------------------

# Verbatim db1b6d85 .github/workflows/release-please.yml lines 177-195 (the
# legacy stale-base repair). Embedded so the self-test does not depend on
# history depth in CI; compared against history when the object is present.
legacy_block() {
  cat <<'LEGACY'
            git checkout -B "$release_branch" "origin/$release_branch"

            expected_base="$(git rev-parse "origin/${target_branch}")"
            actual_base="$(git merge-base HEAD "$expected_base")"
            if [ "$actual_base" != "$expected_base" ]; then
              git checkout "$target_branch"
              git checkout -B "$release_branch" "$expected_base"
              git push --force-with-lease origin HEAD:"$release_branch"

              $release_please release-pr \
                --repo-url "$repo" \
                --target-branch "$target_branch" \
                --config-file release-please-config.json \
                --manifest-file .release-please-manifest.json \
                --token "$RELEASE_PLEASE_TOKEN"

              git fetch origin "$release_branch"
              git checkout -B "$release_branch" "origin/$release_branch"
            fi
LEGACY
}

# The fixed algorithm: check the release branch out, never write it.
fixed_block() {
  cat <<'FIXED'
            git checkout -B "$release_branch" "origin/$release_branch"
FIXED
}

detector_step() {
  local indent=$1
  sed "s/^/$indent/" <<'DETECTOR'
wedged="$(gh pr list --repo "$REPO" --state merged --label 'autorelease: pending' --json number --jq '.[].number')"
if [ -n "$wedged" ]; then
  echo "::error::merged release PR(s) still labelled autorelease: pending ($wedged)" >&2
  exit 1
fi
DETECTOR
}

# write_fixture <file> <legacy|fixed> <detector: separate|release|none|needed|comment>
write_fixture() {
  local file=$1 repair=$2 detector=$3
  {
    cat <<'HEAD'
name: Release Please
on:
  push:
    branches: [main]
jobs:
  release:
    name: Release Please
    runs-on: ubuntu-24.04
    steps:
      - name: Run Release Please
        run: |
          set -euo pipefail
          if [ -n "$release_pr_number" ]; then
            git fetch origin "$target_branch" "$release_branch"
HEAD
    if [ "$repair" = "legacy" ]; then legacy_block; else fixed_block; fi
    cat <<'MID'
            bash scripts/ci/repair_linked_release_pr.sh --version "$repair_version"
            git push origin HEAD:"$release_branch"
            git checkout "$target_branch"
            bash scripts/ci/verify_release_pr_scope.sh --pr "$release_pr_number"
          fi
MID
    if [ "$detector" = "release" ]; then detector_step "          "; fi
    if [ "$detector" = "comment" ]; then
      echo "          # gh pr list --state merged --label 'autorelease: pending' ... exit 1"
    fi
    if [ "$detector" = "needed" ]; then
      echo "  publish-accrue:"
      echo "    needs: [release, release-pr-wedge-check]"
    else
      echo "  publish-accrue:"
      echo "    needs: release"
    fi
    cat <<'PUB'
    runs-on: ubuntu-24.04
    steps:
      - run: cd accrue && mix hex.publish --yes
PUB
    if [ "$detector" = "separate" ] || [ "$detector" = "needed" ]; then
      cat <<'JOB'
  release-pr-wedge-check:
    name: Release PR wedge check
    needs: release
    if: ${{ !cancelled() }}
    runs-on: ubuntu-24.04
    steps:
      - run: |
JOB
      detector_step "          "
    fi
  } >"$file"
}

# Hermetic bare-origin fixture: main, a release branch carrying the seven
# release files, then a docs-only commit on main (the PR #50 trigger).
RELEASE_FILES=".release-please-manifest.json
accrue/CHANGELOG.md
accrue/mix.exs
accrue_admin/CHANGELOG.md
accrue_admin/mix.exs
accrue_portal/CHANGELOG.md
accrue_portal/mix.exs"

build_git_fixture() {
  local dir=$1 work f
  mkdir -p "$dir"
  git init -q --bare --initial-branch=main "$dir/origin.git"
  work="$dir/seed"
  git clone -q "$dir/origin.git" "$work" 2>/dev/null
  git -C "$work" config user.name "fixture"
  git -C "$work" config user.email "fixture@example.test"
  git -C "$work" config commit.gpgsign false
  git -C "$work" checkout -q -b main
  while IFS= read -r f; do
    mkdir -p "$work/$(dirname "$f")"
    echo "1.6.0" >"$work/$f"
  done <<<"$RELEASE_FILES"
  echo "readme" >"$work/README.md"
  git -C "$work" add -A
  git -C "$work" commit -qm "seed main"
  git -C "$work" push -q origin main
  git -C "$work" checkout -q -b release-please--branches--main
  while IFS= read -r f; do echo "1.7.0" >"$work/$f"; done <<<"$RELEASE_FILES"
  git -C "$work" add -A
  git -C "$work" commit -qm "chore: release main"
  git -C "$work" push -q origin release-please--branches--main
  git -C "$work" checkout -q main
  mkdir -p "$work/docs"
  echo "docs-only change" >"$work/docs/note.md"
  git -C "$work" add docs/note.md
  git -C "$work" commit -qm "docs: docs-only change on main"
  git -C "$work" push -q origin main
}

# run_algorithm <fixture dir> <legacy|fixed> -> prints the changed-file list
# of main...release on origin after the algorithm runs in a fresh CI-like clone.
run_algorithm() {
  local dir=$1 repair=$2 ci="$1/ci-$2" script
  git clone -q "$dir/origin.git" "$ci" 2>/dev/null
  git -C "$ci" config user.name "fixture"
  git -C "$ci" config user.email "fixture@example.test"
  if [ "$repair" = "legacy" ]; then script="$(legacy_block)"; else script="$(fixed_block)"; fi
  (
    cd "$ci"
    export target_branch=main release_branch=release-please--branches--main
    export repo=fixture/repo RELEASE_PLEASE_TOKEN=fixture-token
    # Stand-in for release-please reporting "PR remained the same": a no-op.
    export release_please=":"
    git fetch -q origin "$target_branch" "$release_branch"
    bash -euo pipefail -c "$script" >/dev/null 2>&1
  )
  git -C "$ci" fetch -q origin
  git -C "$ci" diff --name-only origin/main...origin/release-please--branches--main
}

SELFTEST_TMP=""
cleanup_selftest() { [ -n "$SELFTEST_TMP" ] && rm -rf "$SELFTEST_TMP"; }

self_test() {
  local status=0 out changed count
  SELFTEST_TMP="$(mktemp -d)"
  trap cleanup_selftest EXIT
  # Hermetic git: no host/global config, hooks or signing leak into fixtures.
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
  local t=$SELFTEST_TMP

  # Fixture provenance: the embedded legacy text equals db1b6d85 when the object exists.
  if git cat-file -e "$LEGACY_SHA" 2>/dev/null; then
    if [ "$(git show "$LEGACY_SHA:.github/workflows/release-please.yml" | sed -n 177,195p)" = "$(legacy_block)" ]; then
      echo "OK: embedded legacy fixture is byte-identical to ${LEGACY_SHA:0:8} release-please.yml lines 177-195"
    else
      echo "self-test FAIL: embedded legacy fixture drifted from ${LEGACY_SHA:0:8}"; status=1
    fi
  else
    echo "note: ${LEGACY_SHA:0:8} not in local history (shallow checkout); provenance compare not run"
  fi

  # Control A: the verbatim legacy block fails the static rule, naming the force push.
  write_fixture "$t/legacy.yml" legacy separate
  if out="$(check_workflow "$t/legacy.yml" legacy.yml 2>&1)"; then
    echo "self-test FAIL: control A -- legacy block passed the static rule"; status=1
  elif [[ "$out" == *'forbidden force push'*'git push --force-with-lease origin HEAD:"$release_branch"'* ]] &&
       [[ "$out" == *"forbidden reset"* ]]; then
    echo "negative control OK: control A (legacy ${LEGACY_SHA:0:8} block) fails the static rule:"
    sed 's/^/  /' <<<"$out"
  else
    echo "self-test FAIL: control A failed without naming the force push and reset: $out"; status=1
  fi

  # Positive: block removed, detector in its own un-needed job, canary present.
  write_fixture "$t/fixed.yml" fixed separate
  if out="$(check_workflow "$t/fixed.yml" fixed.yml 2>&1)"; then
    echo "OK: positive control (block removed, detector job present) passes: $out"
  else
    echo "self-test FAIL: positive fixture failed: $out"; status=1
  fi

  # Missing-detector control.
  write_fixture "$t/nodetector.yml" fixed none
  if out="$(check_workflow "$t/nodetector.yml" nodetector.yml 2>&1)"; then
    echo "self-test FAIL: missing-detector fixture passed"; status=1
  elif [[ "$out" == *"missing merged-but-pending wedge detector"* ]]; then
    echo "negative control OK: missing detector fails: $out"
  else
    echo "self-test FAIL: missing-detector fixture failed for another reason: $out"; status=1
  fi

  # Comment control: a comment naming the detector query cannot satisfy the rule.
  write_fixture "$t/comment.yml" fixed comment
  if out="$(check_workflow "$t/comment.yml" comment.yml 2>&1)"; then
    echo "self-test FAIL: a comment satisfied the detector rule"; status=1
  elif [[ "$out" == *"missing merged-but-pending wedge detector"* ]]; then
    echo "negative control OK: detector text inside a comment does not count: $out"
  else
    echo "self-test FAIL: comment fixture failed for another reason: $out"; status=1
  fi

  # Placement controls.
  write_fixture "$t/needed.yml" fixed needed
  if out="$(check_workflow "$t/needed.yml" needed.yml 2>&1)"; then
    echo "self-test FAIL: placement control -- detector named in publish-accrue needs passed"; status=1
  elif [[ "$out" == *"is named in a needs: list"* ]]; then
    echo "negative control OK: placement (detector job in publish-accrue needs) fails: $out"
  else
    echo "self-test FAIL: placement fixture failed for another reason: $out"; status=1
  fi

  write_fixture "$t/inrelease.yml" fixed release
  if out="$(check_workflow "$t/inrelease.yml" inrelease.yml 2>&1)"; then
    echo "self-test FAIL: placement control -- detector inside the release job passed"; status=1
  elif [[ "$out" == *"sits in the release job"* ]]; then
    echo "negative control OK: placement (detector inside release job) fails: $out"
  else
    echo "self-test FAIL: in-release fixture failed for another reason: $out"; status=1
  fi

  # Missing scope canary.
  awk -v c="$SCOPE_CANARY" 'index($0, c) == 0' "$t/fixed.yml" >"$t/nocanary.yml"
  if out="$(check_workflow "$t/nocanary.yml" nocanary.yml 2>&1)"; then
    echo "self-test FAIL: missing scope canary passed"; status=1
  elif [[ "$out" == *"missing release-PR scope canary"* ]]; then
    echo "negative control OK: missing scope canary fails: $out"
  else
    echo "self-test FAIL: no-canary fixture failed for another reason: $out"; status=1
  fi

  # Other forced-push shapes.
  local shape
  for shape in 'git push --force origin HEAD:"$release_branch"' 'git push -f origin HEAD:"$release_branch"' 'git push origin +HEAD:"$release_branch"'; do
    awk -v s="            $shape" '{ print } /git fetch origin "\$target_branch" "\$release_branch"/ { print s }' "$t/fixed.yml" >"$t/shape.yml"
    if out="$(check_workflow "$t/shape.yml" shape.yml 2>&1)"; then
      echo "self-test FAIL: forced push shape passed: $shape"; status=1
    elif [[ "$out" == *"forbidden force push"* ]]; then
      echo "negative control OK: forced push shape fails: $shape"
    else
      echo "self-test FAIL: forced push shape failed for another reason: $out"; status=1
    fi
  done

  # Control B (behavioral): the legacy algorithm empties the release PR.
  build_git_fixture "$t/git-legacy"
  changed="$(run_algorithm "$t/git-legacy" legacy)"
  count=0; [ -n "$changed" ] && count="$(wc -l <<<"$changed" | tr -d ' ')"
  if [ "$count" -eq 0 ]; then
    echo "negative control OK: legacy repair leaves 0 changed files (reproduces PR #50)"
  else
    echo "self-test FAIL: control B -- legacy repair left $count changed files: $changed"; status=1
  fi

  # Positive (behavioral): the fixed algorithm keeps all seven release files.
  build_git_fixture "$t/git-fixed"
  changed="$(run_algorithm "$t/git-fixed" fixed)"
  if [ "$changed" = "$RELEASE_FILES" ]; then
    echo "OK: positive control: fixed algorithm keeps all 7 release files in main...release"
  else
    echo "self-test FAIL: fixed algorithm changed-file list differs: $changed"; status=1
  fi

  if [ "$status" -eq 0 ]; then
    echo "verify_release_branch_repair_safety: self-test PASS (control A, control B, positive, missing detector, comment, placement x2, missing canary, forced-push shapes x3)"
  else
    echo "verify_release_branch_repair_safety: self-test FAIL"
  fi
  return "$status"
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

mode="repo"
root=""
workflow=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --self-test) mode="self-test"; shift ;;
    --repo)
      mode="repo"
      if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then root=$2; shift 2; else shift; fi
      ;;
    --workflow) mode="workflow"; workflow=${2:?--workflow needs a file}; shift 2 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

case "$mode" in
  self-test) self_test ;;
  workflow) check_workflow "$workflow" ;;
  repo)
    [ -n "$root" ] || root="$(git rev-parse --show-toplevel)"
    check_workflow "$root/.github/workflows/release-please.yml" ".github/workflows/release-please.yml"
    ;;
esac
