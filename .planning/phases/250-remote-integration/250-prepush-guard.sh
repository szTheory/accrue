#!/usr/bin/env bash
# Pre-push guard for the Phase 250 integration branch (plan 250-03, LAND-01 + LAND-02).
#
# Run before EVERY push to origin integration/v1.63-v1.66. A push publishes history
# permanently, so this refuses on any failed check and prints every failure it found.
#
#   bash 250-prepush-guard.sh [--loop|--close] [--hygiene-only]
#                             [--remote-ref <ref>] [--range <a..b>]
#
#   --loop         (default) all checks.
#   --close        all checks, and additionally a clean tracked tree plus the phase-scoped
#                  executable-UAT contract (phase 250).
#   --hygiene-only only the publication-hygiene subset: home paths, token census,
#                  secret/PII scan, large blobs, milestone tags.
#   --remote-ref   default refs/heads/integration/v1.63-v1.66
#   --range        default <remote tip>..HEAD, or origin/main..HEAD when the ref is not on origin
#
# This file ships no secret, username or token literal. Secret patterns are assembled at
# runtime from fragments, and the local username is derived from $HOME. Every pattern
# check first has to fire on a synthetic positive sample built at runtime; a check that
# cannot find a known positive is itself a failure (a zero-result scan proves nothing).

set -euo pipefail

MODE=loop
HYGIENE_ONLY=0
REMOTE_REF=refs/heads/integration/v1.63-v1.66
RANGE=""
PHASE249_CLOSE=23bee494
PHASE_DIR=.planning/phases/250-remote-integration
BIG_BYTES=1048576
BIG_ALLOWED_PREFIX=accrue_admin/e2e/__screenshots__/

while [ $# -gt 0 ]; do
  case "$1" in
    --loop) MODE=loop ;;
    --close) MODE=close ;;
    --hygiene-only) HYGIENE_ONLY=1 ;;
    --remote-ref) REMOTE_REF="$2"; shift ;;
    --range) RANGE="$2"; shift ;;
    -h|--help) sed -n 2,20p "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 64 ;;
  esac
  shift
done

cd "$(git rev-parse --show-toplevel)"
: "${GSD_SCRATCH:?GSD_SCRATCH must be set}"
WORK="$(mktemp -d "$GSD_SCRATCH/guard.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

FAILS=()
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAILS+=("$1"); }
step() { # step <label> <command...>
  local label="$1"; shift
  if "$@" >"$WORK/step.out" 2>&1; then pass "$label"; else
    fail "$label"; tail -n 25 "$WORK/step.out" >&2
  fi
}

# ------------------------------------------------------------------ range
REMOTE_TIP="$(git ls-remote origin "$REMOTE_REF" | cut -f1)"
if [ -z "$RANGE" ]; then
  if [ -n "$REMOTE_TIP" ]; then RANGE="$REMOTE_TIP..HEAD"; else RANGE="origin/main..HEAD"; fi
fi
echo "guard: mode=$MODE hygiene_only=$HYGIENE_ONLY remote_ref=$REMOTE_REF range=$RANGE"

# ------------------------------------------------------------------ secret / PII scanner
# Patterns are assembled from fragments so this file contains no secret-shaped literal.
q1="s""k"; q2="p""k"; q3="r""k"
stripe_pat="(${q1}|${q2}|${q3})_(live|test)_[A-Za-z0-9]{10,}"
whsec_pat="w""hsec_[A-Za-z0-9]{10,}"
aws_pat="A""KIA[0-9A-Z]{16}"
pem_pat="-----BEGIN ([A-Z]+ )?PRIVATE ""KEY-----"
gh_pat="(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,})"
local_part="[A-Za-z0-9._%+-]+"
email_pat="${local_part}@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}"
# Allowed e-mail shapes: bot/no-reply identities, ssh remote form, reserved example domains.
email_allow='^(noreply@anthropic\.com|[A-Za-z0-9._%+-]+@users\.noreply\.github\.com|git@github\.com|[A-Za-z0-9._%+-]+@example\.(com|org|test|net))$'
UNAME="$(basename "$HOME")"
user_pat="(/Users/|/home/)${UNAME}([^A-Za-z0-9_-]|\$)|\\b${UNAME}@[A-Za-z0-9-]+\\.[A-Za-z]{2,}"
PATS="$(printf 'stripe-key\t%s\nwebhook-secret\t%s\naws-key-id\t%s\npem-private-key\t%s\ngithub-token\t%s\nemail\t%s\nlocal-username\t%s\n' \
  "$stripe_pat" "$whsec_pat" "$aws_pat" "$pem_pat" "$gh_pat" "$email_pat" "$user_pat")"

# Reasoned allowlist keyed by PATH (never by literal value): "<pattern-name>|<path-regex>|<reason>".
PATH_ALLOW=()

# Reads a unified diff (-U0) on stdin; prints file:line [pattern] first4*** for each hit in an
# added line. rc 1 when at least one hit survives the allowlists.
scan_diff() {
  PATS="$PATS" EMAIL_ALLOW="$email_allow" PATH_ALLOW="$(printf '%s\n' "${PATH_ALLOW[@]:-}")" perl -e '
    my @p; for (split /\n/, $ENV{PATS}) { my ($n,$r) = split /\t/, $_, 2; push @p, [$n, qr/$r/]; }
    my $ea = qr/$ENV{EMAIL_ALLOW}/;
    my @pa; for (split /\n/, $ENV{PATH_ALLOW}) { next unless length; my ($n,$r) = split /\|/, $_, 3; push @pa, [$n, qr/$r/]; }
    my ($f, $l, $hits) = ("", 0, 0);
    while (<STDIN>) {
      chomp;
      if (/^\+\+\+ b\/(.*)$/) { $f = $1; next }
      if (/^\+\+\+ /) { $f = ""; next }
      if (/^--- /) { next }
      if (/^\@\@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? \@\@/) { $l = $1; next }
      if (/^\+/) {
        my $c = substr($_, 1);
        for my $p (@p) {
          while ($c =~ /($p->[1])/g) {
            my $m = $1;
            next if $p->[0] eq "email" && $m =~ $ea;
            next if grep { $_->[0] eq $p->[0] && $f =~ $_->[1] } @pa;
            printf "%s:%d: [%s] %s***\n", $f, $l, $p->[0], substr($m, 0, 4);
            $hits++;
          }
        }
        $l++;
      }
    }
    exit($hits ? 1 : 0);'
}

# Synthetic positive samples, assembled at runtime. One added line per pattern name.
synthetic_diff() {
  local u="$UNAME"
  printf '%s\n' 'diff --git a/x.txt b/x.txt' '--- /dev/null' '+++ b/x.txt' '@@ -0,0 +1,8 @@'
  printf '+%s\n' \
    "k=${q1}_live_$(printf 'a%.0s' {1..24})" \
    "k=${q2}_test_$(printf 'b%.0s' {1..24})" \
    "k=w""hsec_$(printf 'c%.0s' {1..24})" \
    "k=A""KIA$(printf 'D%.0s' {1..16})" \
    "-----BEGIN RSA PRIVATE ""KEY-----" \
    "t=gh""p_$(printf 'e%.0s' {1..36})" \
    "mail someone@real-company.io" \
    "p=/Users/${u}/projects"
}

controls_secret_scan() {
  local out="$WORK/synth.out" want
  if synthetic_diff | scan_diff >"$out" 2>&1; then
    echo "synthetic positive sample was NOT detected" >&2; return 1
  fi
  for want in stripe-key webhook-secret aws-key-id pem-private-key github-token email local-username; do
    grep -qF "[$want]" "$out" || { echo "pattern '$want' did not fire on its synthetic sample" >&2; cat "$out" >&2; return 1; }
  done
  # redaction: no hit line may carry more than 4 characters of a match
  if grep -qE "\\*\\*\\*.*[A-Za-z0-9]{12}" "$out"; then echo "hit output is not redacted" >&2; return 1; fi
  # negative controls: allowlisted identities and reserved domains must not fire
  if printf '%s\n' 'diff --git a/y b/y' '--- /dev/null' '+++ b/y' '@@ -0,0 +1,3 @@' \
      '+Co-Authored-By: Claude <noreply@anthropic.com>' '+a@example.com b@users.noreply.github.com' '+git@github.com:o/r.git' \
      | scan_diff >"$WORK/neg.out" 2>&1; then :; else echo "allowlisted identities fired:" >&2; cat "$WORK/neg.out" >&2; return 1; fi
  return 0
}

secret_scan_range() {
  local hits="$WORK/range.hits"
  if git diff -U0 --no-color --no-ext-diff "$RANGE" | scan_diff >"$hits" 2>&1; then
    return 0
  fi
  cat "$hits" >&2
  return 1
}

# ------------------------------------------------------------------ large blob scan
# large_blobs <repo-dir> <range>: prints offending "path size" lines; rc 1 if any.
large_blobs() {
  local repo="$1" range="$2" bad=0 oid path size
  while IFS=$'\t' read -r meta path; do
    oid="$(printf '%s' "$meta" | awk '{print $4}')"
    [ -n "$oid" ] || continue
    case "$oid" in 0000000*) continue ;; esac
    size="$(git -C "$repo" cat-file -s "$oid" 2>/dev/null || echo 0)"
    if [ "$size" -gt "$BIG_BYTES" ]; then
      case "$path" in "$BIG_ALLOWED_PREFIX"*) continue ;; esac
      echo "$path $size bytes" ; bad=1
    fi
  done < <(git -C "$repo" diff --raw --no-renames --diff-filter=AM "$range")
  return "$bad"
}

controls_large_blob() {
  local d="$WORK/blobrepo"
  git init -q "$d"
  ( cd "$d" && git config user.email a@example.com && git config user.name t \
    && git commit -q --allow-empty -m base \
    && head -c 2000000 /dev/zero > big.bin && mkdir -p "$BIG_ALLOWED_PREFIX" && cp big.bin "${BIG_ALLOWED_PREFIX}ok.png" \
    && git add big.bin "${BIG_ALLOWED_PREFIX}ok.png" && git commit -q -m big )
  local out
  if out="$(large_blobs "$d" HEAD~1..HEAD)"; then echo "2 MB blob was not detected" >&2; return 1; fi
  printf '%s\n' "$out" | grep -qF 'big.bin' || { echo "wrong offender: $out" >&2; return 1; }
  if printf '%s\n' "$out" | grep -qF "$BIG_ALLOWED_PREFIX"; then echo "allowed screenshot prefix was flagged" >&2; return 1; fi
  return 0
}

# ------------------------------------------------------------------ milestone tags
TAG_RE='refs/tags/v1\.6[3-6]($|\^)'
remote_milestone_tags() { git ls-remote --tags "${1:-origin}" | grep -E "$TAG_RE" || true; }

controls_tags() {
  local local_tags
  local_tags="$(git tag -l | grep -E '^v1\.6[3-6]$' || true)"
  [ -n "$local_tags" ] || { echo "no local v1.63-v1.66 tag to use as a positive control" >&2; return 1; }
  [ -n "$(remote_milestone_tags .)" ] || { echo "tag pattern did not match the local tags" >&2; return 1; }
  return 0
}

check_no_remote_tags() {
  local found
  found="$(remote_milestone_tags origin)"
  [ -z "$found" ] || { echo "milestone tag(s) present on origin:" >&2; echo "$found" >&2; return 1; }
}

# ------------------------------------------------------------------ individual checks
check_fast_forward() {
  if [ -z "$REMOTE_TIP" ]; then echo "remote ref not on origin; nothing to fast-forward over"; return 0; fi
  git cat-file -e "$REMOTE_TIP^{commit}" 2>/dev/null || git fetch -q origin "$REMOTE_REF" || true
  git merge-base --is-ancestor "$REMOTE_TIP" HEAD
}

check_current_phase() { grep -q '^current_phase: 250$' .planning/STATE.md; }

check_phase249_frozen() {
  git diff --quiet "$PHASE249_CLOSE" HEAD -- \
    .planning/phases/249-local-gate-parity-planning-truth/249-VERIFICATION.md \
    .planning/phases/249-local-gate-parity-planning-truth/249-UAT.md
}

# Every non-.planning file changed in the range (and still present) must be named in
# 250-VERIFICATION covered_files, so diff-derived coverage cannot silently be empty.
check_covered_files() {
  local ver="$PHASE_DIR/250-VERIFICATION.md" rel missing=0 n=0
  [ -f "$ver" ] || { echo "$ver missing" >&2; return 1; }
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    case "$rel" in .planning/*) continue ;; esac
    [ -f "$rel" ] || continue
    n=$((n + 1))
    if ! grep -qF -e "  - \"$rel\"" "$ver"; then echo "not in covered_files: $rel" >&2; missing=1; fi
  done < <(git diff --name-only --diff-filter=AM "$RANGE")
  echo "checked $n source/workflow file(s) against covered_files"
  return "$missing"
}

check_clean_tree() { [ -z "$(git status --porcelain --untracked-files=no)" ]; }

sl_g() {
  node --test --test-reporter=tap scripts/ci/verify_artifact_fixed_point.mjs &&
  node scripts/ci/verify_artifact_fixed_point.mjs --fixtures --require-acyclic --require-fixed-point --require-digest-match &&
  node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match
}
sl_e() {
  node --test --test-reporter=tap scripts/ci/verify_completion_evidence.mjs &&
  node scripts/ci/verify_completion_evidence.mjs --fixtures --require-completion-evidence --require-table-agreement &&
  node scripts/ci/verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement
}
exec_uat() {
  node scripts/ci/verify_executable_uat_contract.mjs --self-test &&
  node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in &&
  node scripts/ci/verify_executable_uat_contract.mjs --all-since 229
}
archive_sweep() {
  node --test scripts/ci/verify_phase230_archive_invariants.mjs &&
  node scripts/ci/verify_phase230_archive_invariants.mjs --fixtures &&
  node scripts/ci/verify_phase230_archive_invariants.mjs &&
  node scripts/ci/verify_phase230_archive_invariants.mjs --repo .
}
d32() {
  node --test --test-reporter=tap scripts/ci/verify_ci_script_contract.mjs &&
  node scripts/ci/verify_ci_script_contract.mjs --fixtures --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor &&
  node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor
}
home_paths() {
  bash scripts/ci/verify_no_home_paths.sh --self-test &&
  bash scripts/ci/verify_no_home_paths.sh --repo
}
census() {
  node --test --test-reporter=tap scripts/ci/verify_sensitive_token_census.mjs &&
  node scripts/ci/verify_sensitive_token_census.mjs --fixtures --require-scope-lock --require-ratchet --require-no-cleartext &&
  node scripts/ci/verify_sensitive_token_census.mjs --repo . --census .planning/hygiene/sensitive-token-census.json --require-scope-lock --require-ratchet --require-no-cleartext
}
blobs_range() {
  local out
  if out="$(large_blobs . "$RANGE")"; then return 0; fi
  echo "$out" >&2; return 1
}

# ------------------------------------------------------------------ run
step "control: secret/PII patterns fire on synthetic samples and spare allowlisted identities" controls_secret_scan
step "control: large-blob scan flags a 2 MB blob and spares the screenshot prefix" controls_large_blob
step "control: milestone-tag pattern matches the local tags" controls_tags

if [ "$HYGIENE_ONLY" = 0 ]; then
  step "fast-forward only: origin tip is an ancestor of HEAD" check_fast_forward
  step "STATE current_phase is 250" check_current_phase
  step "SL-G artifact fixed point" sl_g
  step "SL-E completion evidence" sl_e
  step "executable UAT contract" exec_uat
  step "phase-230 archive-path sweep" archive_sweep
  step "D-32 CI script contract" d32
  step "Phase 249 VERIFICATION/UAT byte-unchanged since $PHASE249_CLOSE" check_phase249_frozen
  step "every changed source/workflow file is in 250-VERIFICATION covered_files" check_covered_files
fi

step "no absolute home paths" home_paths
step "sensitive-token census (SL-C)" census
step "no secret/e-mail/username in added lines of $RANGE" secret_scan_range
step "no added blob over 1 MiB outside $BIG_ALLOWED_PREFIX" blobs_range
step "no refs/tags/v1.63-v1.66 on origin" check_no_remote_tags

if [ "$MODE" = close ] && [ "$HYGIENE_ONLY" = 0 ]; then
  step "close: clean tracked tree" check_clean_tree
  step "close: executable UAT for phase 250" node scripts/ci/verify_executable_uat_contract.mjs --phase 250
fi

if [ "${#FAILS[@]}" -gt 0 ]; then
  echo "guard: REFUSE - ${#FAILS[@]} check(s) failed" >&2
  printf '  - %s\n' "${FAILS[@]}" >&2
  exit 1
fi
echo "guard: all checks passed for range $RANGE"
