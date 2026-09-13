#!/usr/bin/env bash
# Creates Phase 229's recovery barrier without fetching, refreshing, or deleting.
set -euo pipefail

usage() { echo "usage: $0 --repo-root PATH --expected-repository OWNER/REPO --bundle-out PATH --private-manifest-out PATH [--public-record-out PATH] | --self-test" >&2; exit 64; }
die() { echo "preserve repository state: FAIL: $*" >&2; exit 65; }
repo_root="" expected_repository="" bundle_out="" private_manifest_out="" public_record_out="" self_test=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) repo_root="${2:-}"; shift 2 ;;
    --expected-repository) expected_repository="${2:-}"; shift 2 ;;
    --bundle-out) bundle_out="${2:-}"; shift 2 ;;
    --private-manifest-out) private_manifest_out="${2:-}"; shift 2 ;;
    --public-record-out) public_record_out="${2:-}"; shift 2 ;;
    --self-test) self_test=true; shift ;;
    *) usage ;;
  esac
done

sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
encode_ref() { printf '%s' "$1" | xxd -p -c 100000 | tr -d '\n'; }
path_is_within() { [[ "$1" == "$2" || "$1" == "$2"/* ]]; }
paths_touch() { path_is_within "$1" "$2" || path_is_within "$2" "$1"; }

# A physical parent check alone hides a lexical path that traverses a symlink.
has_symlink_component() {
  local path="$1" current="" component
  IFS=/ read -r -a components <<< "${path#/}"
  for component in "${components[@]}"; do
    [[ -n "$component" ]] || continue
    current="${current}/${component}"
    [[ -L "$current" ]] && return 0
  done
  return 1
}

physical_output_target() {
  local supplied="$1" lexical dir base physical_parent
  [[ -n "$supplied" ]] || die "empty output path"
  if [[ "$supplied" == /* ]]; then lexical="$supplied"; else lexical="$PWD/$supplied"; fi
  dir="$(dirname "$lexical")"; base="$(basename "$lexical")"
  [[ "$base" != . && "$base" != .. ]] || die "invalid output basename"
  [[ -d "$dir" ]] || die "output parent must already exist: $dir"
  has_symlink_component "$dir" && die "output parent contains a symlink: $dir"
  physical_parent="$(cd "$dir" && pwd -P)"
  printf '%s/%s\n' "$physical_parent" "$base"
}

validate_artifact_path() {
  local item="$1" component
  [[ -n "$item" && "$item" != /* && "$item" != *$'\n'* ]] || return 1
  IFS=/ read -r -a components <<< "$item"
  for component in "${components[@]}"; do
    [[ -n "$component" && "$component" != . && "$component" != .. ]] || return 1
  done
}

sha256_symlink_link_text() {
  local link_path="$1" digest
  if ! digest="$(node - "$link_path" <<'NODE'
const crypto = require('node:crypto');
const fs = require('node:fs');
let linkText;
try {
  linkText = fs.readlinkSync(process.argv[2], { encoding: 'buffer' });
} catch {
  process.exit(65);
}
if (!Buffer.isBuffer(linkText)) process.exit(65);
process.stdout.write(crypto.createHash('sha256').update(linkText).digest('hex'));
NODE
)"; then
    die "raw symlink link-text bytes unavailable"
  fi
  [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || die "invalid raw symlink link-text digest"
  printf '%s\n' "$digest"
}

snapshot_artifacts() {
  local output="$1" path_list
  path_list="${output}.paths"
  local ref full artifact_type artifact_hash
  : > "$output"
  git -C "$repo_root" ls-files --others --exclude-standard -z | LC_ALL=C sort -z > "$path_list" || die "untracked artifact enumeration failed"
  while IFS= read -r -d '' ref; do
    validate_artifact_path "$ref" || die "unsafe untracked path"
    full="$repo_root/$ref"
    if [[ -L "$full" ]]; then
      artifact_type="symlink"
      artifact_hash="$(sha256_symlink_link_text "$full")"
    elif [[ -f "$full" ]]; then
      artifact_type="regular"
      artifact_hash="$(sha256 "$full")"
    elif [[ -d "$full" ]]; then
      artifact_type="empty_directory"
      artifact_hash="not_surfaced"
    else
      die "unsupported untracked entry type"
    fi
    printf '%s\0%s\0%s\0' "$ref" "$artifact_type" "$artifact_hash" >> "$output"
  done < "$path_list"
}

scratch=""; created_outputs=(); temporary_outputs=(); created_refs=(); published=false
self_test_context=false; self_test_mutation_artifact=""; self_test_mutation_symlink=""
cleanup_run() {
  local output index ref expected
  for output in "${temporary_outputs[@]:-}"; do rm -f -- "$output" 2>/dev/null || true; done
  if ! "$published"; then
    for output in "${created_outputs[@]:-}"; do rm -f -- "$output" 2>/dev/null || true; done
    for ((index = ${#created_refs[@]} - 2; index >= 0; index -= 2)); do
      ref="${created_refs[$index]}"; expected="${created_refs[$((index + 1))]}"
      if ! git -C "$repo_root" update-ref -d "$ref" "$expected" 2>/dev/null; then
        echo "preserve repository state: rollback conflict retained changed ref: $ref" >&2
      fi
    done
  fi
  [[ -z "$scratch" ]] || rm -rf -- "$scratch" 2>/dev/null || true
}
publish_exclusive() {
  local temporary="$1" target="$2"
  # link(2) adds the final name atomically and fails if another writer won first.
  ln "$temporary" "$target" || die "output publication collision: $target"
  created_outputs+=("$target")
  rm -f -- "$temporary"
}

run_self_test_artifact_mutation() {
  [[ -z "$self_test_mutation_artifact" && -z "$self_test_mutation_symlink" ]] && return 0
  [[ "$self_test_context" == true ]] || die "test-only artifact mutation requested outside self-test"
  if [[ -n "$self_test_mutation_artifact" ]]; then
    printf '%s' '-mutated-after-snapshot' >> "$self_test_mutation_artifact" || die "test-only artifact mutation failed"
  fi
  if [[ -n "$self_test_mutation_symlink" ]]; then
    node - "$self_test_mutation_symlink" <<'NODE'
const fs = require('node:fs');
const linkPath = process.argv[2];
fs.unlinkSync(linkPath);
fs.symlinkSync(Buffer.from([0xff, 0xfd, 0x0a]), linkPath);
NODE
  fi
}

validate_output_targets() {
  local worktree raw_worktree
  bundle_out="$(physical_output_target "$bundle_out")"
  private_manifest_out="$(physical_output_target "$private_manifest_out")"
  if [[ -n "$public_record_out" ]]; then public_record_out="$(physical_output_target "$public_record_out")"; fi
  while IFS= read -r raw_worktree; do
    [[ -n "$raw_worktree" ]] || continue
    worktree="$(cd "$raw_worktree" && pwd -P)"
    path_is_within "$bundle_out" "$worktree" && die "bundle destination must be outside repository/worktrees"
    path_is_within "$private_manifest_out" "$worktree" && die "private manifest destination must be outside repository/worktrees"
    if [[ -n "$public_record_out" ]] && path_is_within "$public_record_out" "$worktree"; then
      die "public record destination must be outside repository/worktrees"
    fi
  done < <(git -C "$repo_root" worktree list --porcelain | sed -n 's/^worktree //p')
  local targets=("$bundle_out" "$private_manifest_out")
  [[ -z "$public_record_out" ]] || targets+=("$public_record_out")
  local i j
  for ((i = 0; i < ${#targets[@]}; i++)); do
    [[ ! -e "${targets[$i]}" && ! -L "${targets[$i]}" ]] || die "output collision: ${targets[$i]}"
    for ((j = i + 1; j < ${#targets[@]}; j++)); do
      paths_touch "${targets[$i]}" "${targets[$j]}" && die "output targets touch or alias"
    done
  done
}

verify_bundle_heads() {
  local frozen="$1" bundle="$2" bundle_heads ref object type encoded
  git -C "$repo_root" bundle verify "$bundle" >/dev/null || die "bundle verification failed"
  bundle_heads="$(git -C "$repo_root" bundle list-heads "$bundle")"
  while IFS= read -r -d '' ref && IFS= read -r -d '' object && IFS= read -r -d '' type; do
    ref="${ref#$'\n'}"; type="${type%$'\n'}"
    encoded="refs/accrue-preserve/phase-229/$(encode_ref "$ref")"
    [[ "$(git -C "$repo_root" rev-parse "$encoded^{object}")" == "$object" ]] || die "preservation ref mismatch"
    grep -Fqx "$object $ref" <<< "$bundle_heads" || die "bundle membership mismatch"
  done < "$frozen"
}

run() {
  [[ -d "$repo_root/.git" || -f "$repo_root/.git" ]] || die "--repo-root must be a git worktree"
  repo_root="$(git -C "$repo_root" rev-parse --show-toplevel)"
  repo_root="$(cd "$repo_root" && pwd -P)"
  [[ "$expected_repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "--expected-repository must be OWNER/REPO"
  [[ -n "$bundle_out" && -n "$private_manifest_out" ]] || usage
  validate_output_targets
  scratch="$(mktemp -d "${TMPDIR:-/tmp}/phase229-preserve.XXXXXX")"
  trap cleanup_run EXIT
  local frozen="$scratch/frozen" refs_for_bundle="$scratch/refs" artifacts="$scratch/artifacts" current_artifacts="$scratch/artifacts-current"
  : > "$frozen"; : > "$refs_for_bundle"; : > "$artifacts"
  local ref object type encoded
  while IFS= read -r -d '' ref && IFS= read -r -d '' object && IFS= read -r -d '' type; do
    ref="${ref#$'\n'}"; type="${type%$'\n'}"
    git -C "$repo_root" check-ref-format "$ref" >/dev/null || die "invalid ref name"
    [[ "$object" =~ ^[0-9a-f]{40}$ ]] || die "invalid ref object"
    [[ "$type" == commit || "$type" == tag ]] || die "unsupported ref object shape: $type"
    [[ "$(git -C "$repo_root" cat-file -t "$object")" == "$type" ]] || die "ref object changed while freezing"
    printf '%s\0%s\0%s\0' "$ref" "$object" "$type" >> "$frozen"; printf '%s\n' "$ref" >> "$refs_for_bundle"
  done < <(git -C "$repo_root" for-each-ref --format='%(refname)%00%(objectname)%00%(objecttype)%00' refs)
  [[ -s "$refs_for_bundle" ]] || die "no refs found"
  while IFS= read -r -d '' ref && IFS= read -r -d '' object && IFS= read -r -d '' type; do
    ref="${ref#$'\n'}"; encoded="refs/accrue-preserve/phase-229/$(encode_ref "$ref")"
    git -C "$repo_root" update-ref "$encoded" "$object" "0000000000000000000000000000000000000000" || die "preservation ref collision"
    created_refs+=("$encoded" "$object")
  done < "$frozen"
  local bundle_tmp manifest_tmp public_tmp bundle_sha256
  bundle_tmp="$(mktemp "$(dirname "$bundle_out")/.phase229-bundle.XXXXXX")"
  temporary_outputs+=("$bundle_tmp")
  git -C "$repo_root" bundle create "$bundle_tmp" --stdin < "$refs_for_bundle" >/dev/null
  verify_bundle_heads "$frozen" "$bundle_tmp"
  bundle_sha256="$(sha256 "$bundle_tmp")"
  snapshot_artifacts "$artifacts"
  manifest_tmp="$(mktemp "$(dirname "$private_manifest_out")/.phase229-manifest.XXXXXX")"; temporary_outputs+=("$manifest_tmp"); chmod 600 "$manifest_tmp"
  BUNDLE_SHA256="$bundle_sha256" FROZEN="$frozen" ARTIFACTS="$artifacts" MANIFEST="$manifest_tmp" EXPECTED="$expected_repository" node --input-type=module <<'NODE'
import fs from 'node:fs';
const read = (file) => fs.readFileSync(file).toString().split('\0').filter(Boolean);
const triples = (file, names) => { const values = read(file), result = []; for (let i = 0; i < values.length; i += names.length) result.push(Object.fromEntries(names.map((name, index) => [name, values[i + index]]))); return result; };
const refs = triples(process.env.FROZEN, ['original_ref', 'object', 'object_type']).map((ref) => ({ ...ref, encoded_ref: `refs/accrue-preserve/phase-229/${Buffer.from(ref.original_ref).toString('hex')}`, bundle_member: true, restore_argv: ['git', 'update-ref', ref.original_ref, ref.object] }));
fs.writeFileSync(process.env.MANIFEST, `${JSON.stringify({ schema_version: 1, repository: process.env.EXPECTED, recovery_verified: true, bundle_sha256: process.env.BUNDLE_SHA256, refs, artifacts: triples(process.env.ARTIFACTS, ['path', 'type', 'sha256']), empty_directory_policy: 'not_surfaced_by_git' }, null, 2)}\n`, { mode: 0o600 });
NODE
  if [[ -n "$public_record_out" ]]; then
    public_tmp="$(mktemp "$(dirname "$public_record_out")/.phase229-public.XXXXXX")"
    temporary_outputs+=("$public_tmp")
    printf '{"schema_version":1,"recovery_verified":true,"bundle_sha256":"%s","ref_count":%s,"empty_directory_policy":"not_surfaced_by_git"}\n' "$bundle_sha256" "$(wc -l < "$refs_for_bundle" | tr -d ' ')" > "$public_tmp"
  fi
  if [[ "${PHASE229_TEST_FAIL_AFTER_MANIFEST:-}" == 1 ]]; then
    echo "phase229-self-test-reached:after-manifest" >&2
    die "injected post-manifest failure"
  fi
  publish_exclusive "$bundle_tmp" "$bundle_out"; publish_exclusive "$manifest_tmp" "$private_manifest_out"
  [[ -z "$public_record_out" ]] || publish_exclusive "$public_tmp" "$public_record_out"
  verify_bundle_heads "$frozen" "$bundle_out"
  [[ "$(sha256 "$bundle_out")" == "$bundle_sha256" ]] || die "final bundle digest mismatch"
  run_self_test_artifact_mutation
  snapshot_artifacts "$current_artifacts"
  cmp -s "$artifacts" "$current_artifacts" || die "untracked artifact map changed after manifest snapshot"
  ARTIFACT_POLICY="not_surfaced_by_git" MANIFEST="$private_manifest_out" node --input-type=module <<'NODE'
import fs from 'node:fs';
const manifest = JSON.parse(fs.readFileSync(process.env.MANIFEST, 'utf8'));
if (manifest.empty_directory_policy !== process.env.ARTIFACT_POLICY) process.exit(1);
NODE
  published=true
  echo "preserve repository state: PASS"
}

assert_no_preservation_delta() {
  local repo="$1" before="$2" after
  after="$(git -C "$repo" for-each-ref --format='%(refname) %(objectname)' refs/accrue-preserve/phase-229)"
  [[ "$before" == "$after" ]] || { echo "self-test: preservation refs changed on rejected input" >&2; return 1; }
}
expect_rejected() {
  local repo="$1" before="$2"; shift 2
  if "$@" >/dev/null 2>&1; then echo "self-test: invalid invocation unexpectedly passed" >&2; return 1; fi
  assert_no_preservation_delta "$repo" "$before"
}
expect_failure_after_recovery() {
  if "$@" >/dev/null 2>&1; then echo "self-test: injected failure unexpectedly passed" >&2; return 1; fi
}
assert_empty_directory() { [[ -z "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit)" ]]; }

snapshot_fixture_state() {
  local repo="$1" output="$2" snapshot="$3"
  mkdir -p "$snapshot"
  git -C "$repo" for-each-ref --format='%(refname) %(objectname) %(objecttype)' > "$snapshot/refs"
  git -C "$repo" status --porcelain=v2 -z --untracked-files=all > "$snapshot/status"
  git -C "$repo" ls-files -s -z > "$snapshot/index"
  git -C "$repo" worktree list --porcelain > "$snapshot/worktrees"
  (repo_root="$repo"; snapshot_artifacts "$snapshot/artifacts")
  (cd "$output" && find . -mindepth 1 -print0 | LC_ALL=C sort -z) > "$snapshot/outputs"
}

assert_fixture_state_equal() {
  local before="$1" after="$2" authority
  for authority in refs status index worktrees artifacts outputs; do
    if ! cmp -s "$before/$authority" "$after/$authority"; then
      echo "TAP version 13" >&2
      echo "not ok 1 - post-manifest failure restores exact fixture state" >&2
      echo "self-test: post-manifest failure changed $authority authority" >&2
      echo "1..1" >&2
      echo "# tests 1" >&2
      echo "# pass 0" >&2
      echo "# fail 1" >&2
      return 1
    fi
  done
}

assert_post_manifest_failure_transactional() {
  local fixture_root="$1" tmp="$2"
  local repo="$fixture_root/post-manifest-repo" output="$fixture_root/post-manifest-output"
  local before="$fixture_root/post-manifest-before" after="$fixture_root/post-manifest-after" log="$fixture_root/post-manifest.log"
  mkdir -p "$output"
  git init -q "$repo"
  git -C "$repo" config user.email phase229@example.invalid
  git -C "$repo" config user.name phase229
  printf 'tracked\n' > "$repo/tracked"
  git -C "$repo" add tracked
  git -C "$repo" commit -qm fixture
  git -C "$repo" branch secondary
  printf 'artifact\n' > "$repo/untracked"
  ln -s nowhere "$repo/link"
  snapshot_fixture_state "$repo" "$output" "$before"
  if PHASE229_TEST_FAIL_AFTER_MANIFEST=1 TMPDIR="$tmp" "$0" \
    --repo-root "$repo" \
    --expected-repository szTheory/accrue \
    --bundle-out "$output/recovery.bundle" \
    --private-manifest-out "$output/private.json" \
    --public-record-out "$output/public.json" >"$log" 2>&1; then
    echo "self-test: post-manifest injected failure unexpectedly passed" >&2
    return 1
  fi
  grep -Fq 'phase229-self-test-reached:after-manifest' "$log" || { echo "self-test: post-manifest injection was not reached" >&2; return 1; }
  ! grep -Fq 'preserve repository state: PASS' "$log" || { echo "self-test: post-manifest failure printed PASS" >&2; return 1; }
  snapshot_fixture_state "$repo" "$output" "$after"
  assert_fixture_state_equal "$before" "$after"
  assert_empty_directory "$tmp" || { echo "self-test: production scratch leaked after post-manifest failure" >&2; return 1; }
}

assert_artifact_mutation_rejected() {
  local fixture_root="$1" output="$2" tmp="$3"
  local repo="$fixture_root/mutation-repo" artifact="$fixture_root/mutation-repo/artifact" log="$fixture_root/mutation.log"
  git init -q "$repo"
  git -C "$repo" config user.email phase229@example.invalid
  git -C "$repo" config user.name phase229
  printf 'tracked\n' > "$repo/tracked"
  git -C "$repo" add tracked
  git -C "$repo" commit -qm fixture
  printf 'before' > "$artifact"
  if (
    self_test_context=true
    self_test_mutation_artifact="$artifact"
    repo_root="$repo"
    expected_repository="szTheory/accrue"
    bundle_out="$output/mutation.bundle"
    private_manifest_out="$output/mutation-private.json"
    public_record_out="$output/mutation-public.json"
    scratch=""; created_outputs=(); temporary_outputs=(); created_refs=(); published=false
    run
  ) >"$log" 2>&1; then
    echo "self-test: post-snapshot artifact mutation unexpectedly passed" >&2
    return 1
  fi
  ! grep -Fq 'preserve repository state: PASS' "$log" || { echo "self-test: rejected mutation printed PASS" >&2; return 1; }
  [[ "$(cat "$artifact")" == 'before-mutated-after-snapshot' ]] || { echo "self-test: mutation fixture did not retain its deliberate artifact change" >&2; return 1; }
  [[ ! -e "$output/mutation.bundle" && ! -e "$output/mutation-private.json" && ! -e "$output/mutation-public.json" ]] || { echo "self-test: rejected mutation left invocation-owned output" >&2; return 1; }
  assert_empty_directory "$tmp" || { echo "self-test: production scratch leaked after artifact mutation" >&2; return 1; }
}

create_raw_symlink_fixtures() {
  local repo="$1" expected="$2"
  node - "$repo" "$expected" <<'NODE'
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const [repo, expectedFile] = process.argv.slice(2);
const fixtures = [
  ['link-embedded-newline', Buffer.from([0x61, 0x0a, 0x62])],
  ['link-trailing-newline', Buffer.from([0x74, 0x61, 0x72, 0x67, 0x65, 0x74, 0x0a])],
  ['link-empty-looking', Buffer.from([0x0a])],
  ['link-non-utf8', Buffer.from([0xff, 0xfe, 0x0a])],
];
const expected = {};
for (const [name, target] of fixtures) {
  const linkPath = path.join(repo, name);
  fs.symlinkSync(target, linkPath);
  const observed = fs.readlinkSync(linkPath, { encoding: 'buffer' });
  if (!Buffer.isBuffer(observed) || !observed.equals(target)) {
    throw new Error(`raw Buffer link-text unavailable for ${name}`);
  }
  expected[name] = crypto.createHash('sha256').update(target).digest('hex');
}
fs.writeFileSync(expectedFile, `${JSON.stringify(expected)}\n`);
NODE
}

assert_raw_symlink_manifest() {
  local manifest="$1" expected="$2"
  node - "$manifest" "$expected" <<'NODE'
const fs = require('node:fs');
const [manifestFile, expectedFile] = process.argv.slice(2);
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const expected = JSON.parse(fs.readFileSync(expectedFile, 'utf8'));
for (const [path, sha256] of Object.entries(expected)) {
  const artifact = manifest.artifacts.find((entry) => entry.path === path);
  if (!artifact || artifact.type !== 'symlink' || artifact.sha256 !== sha256) {
    throw new Error(`raw symlink digest mismatch for ${path}`);
  }
}
NODE
}

assert_symlink_mutation_rejected() {
  local fixture_root="$1" output="$2" tmp="$3"
  local repo="$fixture_root/symlink-mutation-repo" link="$fixture_root/symlink-mutation-repo/link" log="$fixture_root/symlink-mutation.log"
  git init -q "$repo"
  git -C "$repo" config user.email phase229@example.invalid
  git -C "$repo" config user.name phase229
  printf 'tracked\n' > "$repo/tracked"
  git -C "$repo" add tracked
  git -C "$repo" commit -qm fixture
  node - "$link" <<'NODE'
const fs = require('node:fs');
fs.symlinkSync(Buffer.from([0xff, 0xfe, 0x0a]), process.argv[2]);
NODE
  if (
    self_test_context=true
    self_test_mutation_symlink="$link"
    repo_root="$repo"
    expected_repository="szTheory/accrue"
    bundle_out="$output/symlink-mutation.bundle"
    private_manifest_out="$output/symlink-mutation-private.json"
    public_record_out="$output/symlink-mutation-public.json"
    scratch=""; created_outputs=(); temporary_outputs=(); created_refs=(); published=false
    run
  ) >"$log" 2>&1; then
    echo "self-test: changed symlink link text unexpectedly passed" >&2
    return 1
  fi
  ! grep -Fq 'preserve repository state: PASS' "$log" || { echo "self-test: rejected symlink mutation printed PASS" >&2; return 1; }
  [[ ! -e "$output/symlink-mutation.bundle" && ! -e "$output/symlink-mutation-private.json" && ! -e "$output/symlink-mutation-public.json" ]] || { echo "self-test: rejected symlink mutation left invocation-owned output" >&2; return 1; }
  assert_empty_directory "$tmp" || { echo "self-test: production scratch leaked after symlink mutation" >&2; return 1; }
}

self_test() {
  local scratch_created scratch
  scratch_created="$(mktemp -d "${TMPDIR:-/tmp}/phase229-self-test.XXXXXX")"
  scratch="$(cd "$scratch_created" && pwd -P)"
  cleanup_self_test() { rm -rf -- "$scratch" 2>/dev/null || true; }; trap cleanup_self_test EXIT
  local repo="$scratch/repo" output="$scratch/output" tmp="$scratch/tmp" before symlink_expected="$scratch/symlink-expected.json"
  mkdir -p "$output" "$tmp"
  local unsupported_log="$scratch/unsupported-symlink.log"
  if (sha256_symlink_link_text "$scratch/missing-link") >"$unsupported_log" 2>&1; then
    echo "self-test: unavailable raw symlink bytes unexpectedly produced a digest" >&2
    return 1
  fi
  ! grep -Fq 'preserve repository state: PASS' "$unsupported_log" || { echo "self-test: unavailable raw symlink bytes printed PASS" >&2; return 1; }
  assert_post_manifest_failure_transactional "$scratch" "$tmp"
  assert_artifact_mutation_rejected "$scratch" "$output" "$tmp"
  assert_symlink_mutation_rejected "$scratch" "$output" "$tmp"
  git init -q "$repo"; git -C "$repo" config user.email phase229@example.invalid; git -C "$repo" config user.name phase229
  printf 'fixture\n' > "$repo/tracked"; git -C "$repo" add tracked; git -C "$repo" commit -qm fixture
  git -C "$repo" branch other; git -C "$repo" tag -a annotated -m tag; git -C "$repo" tag lightweight; git -C "$repo" notes add -m note; git -C "$repo" update-ref refs/remotes/origin/main HEAD; git -C "$repo" update-ref refs/custom/phase229 HEAD; git -C "$repo" update-ref 'refs/custom/phase229$(not-executed)' HEAD
  printf 'stash fixture\n' >> "$repo/tracked"; git -C "$repo" stash push -qm phase229-fixture
  printf regular > "$repo/release..notes"; mkdir "$repo/nested"; printf nested > "$repo/nested/value"; ln -s nowhere "$repo/link"
  create_raw_symlink_fixtures "$repo" "$symlink_expected"
  before="$(git -C "$repo" for-each-ref --format='%(refname) %(objectname)' refs/accrue-preserve/phase-229)"
  expect_rejected "$repo" "$before" "$0" --repo-root "$repo" --expected-repository szTheory/accrue --bundle-out "$output/equal" --private-manifest-out "$output/equal"
  expect_rejected "$repo" "$before" "$0" --repo-root "$repo" --expected-repository szTheory/accrue --bundle-out "$output/alias" --private-manifest-out "$output/../output/alias"
  ln -s "$repo" "$output/inside-link"; expect_rejected "$repo" "$before" "$0" --repo-root "$repo" --expected-repository szTheory/accrue --bundle-out "$output/inside-link/bundle" --private-manifest-out "$output/private"; rm "$output/inside-link"
  : > "$output/inode"; ln "$output/inode" "$output/inode-alias"; expect_rejected "$repo" "$before" "$0" --repo-root "$repo" --expected-repository szTheory/accrue --bundle-out "$output/inode" --private-manifest-out "$output/inode-alias"
  expect_rejected "$repo" "$before" "$0" --repo-root "$repo" --expected-repository szTheory/accrue --bundle-out "$output/nested" --private-manifest-out "$output/nested/child"
  [[ ! -e "$output/equal" && ! -e "$output/alias" && ! -e "$output/private" ]] || { echo "self-test: rejected invocation wrote output" >&2; return 1; }
  TMPDIR="$tmp" "$0" --repo-root "$repo" --expected-repository szTheory/accrue --bundle-out "$output/capsule.bundle" --private-manifest-out "$output/private.json" --public-record-out "$output/public.json" >/dev/null
  assert_empty_directory "$tmp" || { echo "self-test: production scratch leaked after success" >&2; return 1; }
  expect_failure_after_recovery env PHASE229_TEST_FAIL_AFTER_MANIFEST=1 TMPDIR="$tmp" "$0" --repo-root "$repo" --expected-repository szTheory/accrue --bundle-out "$output/injected.bundle" --private-manifest-out "$output/injected.json"
  assert_empty_directory "$tmp" || { echo "self-test: production scratch leaked after injected failure" >&2; return 1; }
  [[ ! -e "$output/injected.bundle" && ! -e "$output/injected.json" ]] || { echo "self-test: injected failure published output" >&2; return 1; }
  git -C "$repo" bundle verify "$output/capsule.bundle" >/dev/null
  [[ "$(stat -f '%Lp' "$output/private.json")" == 600 ]] || { echo "self-test: private manifest mode is not 0600" >&2; return 1; }
  assert_raw_symlink_manifest "$output/private.json" "$symlink_expected"
  node - "$output/private.json" "$output/public.json" "$output/capsule.bundle" "$scratch/restore" <<'NODE'
const fs = require('node:fs'); const { spawnSync } = require('node:child_process');
const [manifestFile, publicFile, bundle, restore] = process.argv.slice(2), manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8')), publicRecord = JSON.parse(fs.readFileSync(publicFile, 'utf8'));
const expected = ['refs/stash', 'refs/tags/annotated', 'refs/notes/commits', 'refs/remotes/origin/main', 'refs/custom/phase229', 'refs/custom/phase229$(not-executed)'];
if (!manifest.recovery_verified || !expected.every((ref) => manifest.refs.some((row) => row.original_ref === ref)) || !manifest.refs.every((row) => Array.isArray(row.restore_argv) && row.restore_argv[0] === 'git' && row.restore_argv[1] === 'update-ref') || publicRecord.bundle_sha256 !== manifest.bundle_sha256 || publicRecord.ref_count !== manifest.refs.length) process.exit(1);
const run = (args) => { const result = spawnSync(args[0], args.slice(1), { encoding: 'utf8' }); if (result.status !== 0) { process.stderr.write(result.stderr); process.exit(1); } };
run(['git', 'init', '-q', restore]);
for (const ref of ['refs/stash', 'refs/custom/phase229$(not-executed)']) { const row = manifest.refs.find((entry) => entry.original_ref === ref); run(['git', '-C', restore, 'fetch', bundle, ref]); const result = spawnSync(row.restore_argv[0], ['-C', restore, ...row.restore_argv.slice(1)], { encoding: 'utf8' }); if (result.status !== 0 || spawnSync('git', ['-C', restore, 'rev-parse', `${ref}^{object}`], { encoding: 'utf8' }).stdout.trim() !== row.object) process.exit(1); }
NODE
  validate_artifact_path release..notes || { echo "self-test: valid artifact name rejected" >&2; return 1; }
  ! validate_artifact_path nested/../escape && ! validate_artifact_path ./self || { echo "self-test: dot path component accepted" >&2; return 1; }
  local single="$scratch/single" empty="$scratch/empty"
  git init -q "$single"; git -C "$single" config user.email phase229@example.invalid; git -C "$single" config user.name phase229; printf one > "$single/one"; git -C "$single" add one; git -C "$single" commit -qm one
  TMPDIR="$tmp" "$0" --repo-root "$single" --expected-repository szTheory/accrue --bundle-out "$output/single.bundle" --private-manifest-out "$output/single.json" >/dev/null
  git -C "$single" bundle verify "$output/single.bundle" >/dev/null; assert_empty_directory "$tmp"
  git init -q "$empty"; expect_rejected "$empty" "" env TMPDIR="$tmp" "$0" --repo-root "$empty" --expected-repository szTheory/accrue --bundle-out "$output/empty.bundle" --private-manifest-out "$output/empty.json"
  assert_empty_directory "$tmp" || { echo "self-test: production scratch leaked after failure" >&2; return 1; }
  [[ ! -e "$output/empty.bundle" && ! -e "$output/empty.json" ]] || { echo "self-test: empty repository published output" >&2; return 1; }
  echo "preserve repository state self-test: PASS"
}
if "$self_test"; then self_test; else run; fi
