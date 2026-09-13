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
within_repo() { case "$1" in "$repo_root"|"$repo_root"/*) return 0;; *) return 1;; esac; }

run() {
  [[ -d "$repo_root/.git" || -f "$repo_root/.git" ]] || die "--repo-root must be a git worktree"
  repo_root="$(git -C "$repo_root" rev-parse --show-toplevel)"
  [[ "$expected_repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "--expected-repository must be OWNER/REPO"
  [[ -n "$bundle_out" && -n "$private_manifest_out" ]] || usage
  [[ "$bundle_out" != /* ]] && bundle_out="$(cd "$(dirname "$bundle_out")" && pwd)/$(basename "$bundle_out")"
  [[ "$private_manifest_out" != /* ]] && private_manifest_out="$(cd "$(dirname "$private_manifest_out")" && pwd)/$(basename "$private_manifest_out")"
  [[ -n "$public_record_out" && "$public_record_out" != /* ]] && public_record_out="$(cd "$(dirname "$public_record_out")" && pwd)/$(basename "$public_record_out")"
  within_repo "$bundle_out" && die "bundle destination must be outside repository"
  within_repo "$private_manifest_out" && die "private manifest destination must be outside repository"
  [[ ! -e "$bundle_out" && ! -e "$private_manifest_out" ]] || die "output collision"
  [[ -z "$public_record_out" || ! -e "$public_record_out" ]] || die "output collision"
  mkdir -p "$(dirname "$bundle_out")" "$(dirname "$private_manifest_out")"
  local scratch; scratch="$(mktemp -d "${TMPDIR:-/tmp}/phase229-preserve.XXXXXX")"
  local frozen="$scratch/frozen" refs_for_bundle="$scratch/refs" artifacts="$scratch/artifacts"
  : > "$frozen"; : > "$refs_for_bundle"; : > "$artifacts"
  # This is the sole ref enumeration, before preservation refs or any remote operation.
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
    ref="${ref#$'\n'}"; type="${type%$'\n'}"
    encoded="refs/accrue-preserve/phase-229/$(encode_ref "$ref")"
    git -C "$repo_root" show-ref --verify --quiet "$encoded" && die "preservation ref collision"
    git -C "$repo_root" update-ref "$encoded" "$object"
  done < "$frozen"
  git -C "$repo_root" bundle create "$bundle_out" --stdin < "$refs_for_bundle" >/dev/null
  git -C "$repo_root" bundle verify "$bundle_out" >/dev/null || die "bundle verification failed"
  local bundle_heads; bundle_heads="$(git -C "$repo_root" bundle list-heads "$bundle_out")"
  while IFS= read -r -d '' ref && IFS= read -r -d '' object && IFS= read -r -d '' type; do
    ref="${ref#$'\n'}"; type="${type%$'\n'}"
    encoded="refs/accrue-preserve/phase-229/$(encode_ref "$ref")"
    [[ "$(git -C "$repo_root" rev-parse "$encoded^{object}")" == "$object" ]] || die "preservation ref mismatch"
    grep -Fqx "$object $ref" <<< "$bundle_heads" || die "bundle membership mismatch"
  done < "$frozen"
  # Git intentionally does not surface empty untracked directories; the public policy says so.
  while IFS= read -r -d '' item; do
    [[ "$item" != /* && "$item" != *$'\n'* && "$item" != *'..'* ]] || die "unsafe untracked path"
    local full="$repo_root/$item" type hash
    if [[ -L "$full" ]]; then type="symlink"; hash="$(printf '%s' "$(readlink "$full")" | shasum -a 256 | awk '{print $1}')"
    elif [[ -f "$full" ]]; then type="regular"; hash="$(sha256 "$full")"
    elif [[ -d "$full" ]]; then type="empty_directory"; hash="not_surfaced"
    else die "unsupported untracked entry type"; fi
    printf '%s\0%s\0%s\0' "$item" "$type" "$hash" >> "$artifacts"
  done < <(git -C "$repo_root" ls-files --others --exclude-standard -z)
  BUNDLE_SHA256="$(sha256 "$bundle_out")" FROZEN="$frozen" ARTIFACTS="$artifacts" MANIFEST="$private_manifest_out" EXPECTED="$expected_repository" node --input-type=module <<'NODE'
import fs from 'node:fs';
const read = (file) => fs.readFileSync(file).toString().split('\0').filter(Boolean);
const triples = (file, names) => { const values = read(file), result = []; for (let i = 0; i < values.length; i += names.length) result.push(Object.fromEntries(names.map((name, index) => [name, values[i + index]]))); return result; };
const refs = triples(process.env.FROZEN, ['original_ref','object','object_type']).map((ref) => ({ ...ref, encoded_ref: `refs/accrue-preserve/phase-229/${Buffer.from(ref.original_ref).toString('hex')}`, bundle_member: true, restore_command: `git update-ref ${ref.original_ref} ${ref.object}` }));
const artifacts = triples(process.env.ARTIFACTS, ['path','type','sha256']);
fs.writeFileSync(process.env.MANIFEST, `${JSON.stringify({ schema_version: 1, repository: process.env.EXPECTED, recovery_verified: true, bundle_sha256: process.env.BUNDLE_SHA256, refs, artifacts, empty_directory_policy: 'not_surfaced_by_git' }, null, 2)}\n`, { mode: 0o600 });
NODE
  if [[ -n "$public_record_out" ]]; then printf '{"schema_version":1,"recovery_verified":true,"bundle_sha256":"%s","ref_count":%s,"empty_directory_policy":"not_surfaced_by_git"}\n' "$BUNDLE_SHA256" "$(wc -l < "$refs_for_bundle" | tr -d ' ')" > "$public_record_out"; fi
  echo "preserve repository state: PASS"
}
self_test() {
  local scratch; scratch="$(mktemp -d "${TMPDIR:-/tmp}/phase229-self-test.XXXXXX")"
  git init -q "$scratch/repo"; git -C "$scratch/repo" config user.email phase229@example.invalid; git -C "$scratch/repo" config user.name phase229
  printf 'fixture\n' > "$scratch/repo/tracked"; git -C "$scratch/repo" add tracked; git -C "$scratch/repo" commit -qm fixture
  git -C "$scratch/repo" branch other; git -C "$scratch/repo" tag -a annotated -m tag; git -C "$scratch/repo" tag lightweight; git -C "$scratch/repo" notes add -m note; git -C "$scratch/repo" update-ref refs/remotes/origin/main HEAD; git -C "$scratch/repo" update-ref refs/custom/phase229 HEAD
  printf 'regular' > "$scratch/repo/nested-file"; mkdir "$scratch/repo/nested"; printf 'nested' > "$scratch/repo/nested/value"; ln -s nowhere "$scratch/repo/link"
  "$0" --repo-root "$scratch/repo" --expected-repository szTheory/accrue --bundle-out "$scratch/capsule.bundle" --private-manifest-out "$scratch/private.json" >/dev/null
  git -C "$scratch/repo" bundle verify "$scratch/capsule.bundle" >/dev/null
  node -e 'const m=require(process.argv[1]); if (!m.recovery_verified || m.refs.length < 7 || !m.artifacts.some(x=>x.type === "symlink")) process.exit(1)' "$scratch/private.json"
  echo "preserve repository state self-test: PASS"
}
if "$self_test"; then self_test; else run; fi
