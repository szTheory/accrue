#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

REPO=${GITHUB_REPOSITORY:-szTheory/accrue}

fail() {
  echo "[capture_linked_release_proof] $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: bash scripts/ci/capture_linked_release_proof.sh --version <x.y.z> --run-id <id> --pr <number-or-url> --output <path>

Append a deterministic Phase 121 proof block keyed to one PR number, one target
version, and one Release Please workflow run id. The appended block captures:
- git tags for accrue, accrue_admin, accrue_portal
- GitHub release URLs and publish timestamps
- Hex API latest_version and updated_at for all three packages
- Release Please workflow job conclusions and ordering
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required but not installed"
}

normalize_pr() {
  local value=$1

  if [[ "$value" =~ ^https?://github\.com/[^/]+/[^/]+/pull/([0-9]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$value"
  else
    fail "invalid PR identifier: $value"
  fi
}

VERSION=""
RUN_ID=""
PR_ARG=""
OUTPUT=""

while (($# > 0)); do
  case "$1" in
    --version)
      (($# >= 2)) || fail "--version requires a value"
      VERSION=$2
      shift 2
      ;;
    --run-id)
      (($# >= 2)) || fail "--run-id requires a value"
      RUN_ID=$2
      shift 2
      ;;
    --pr)
      (($# >= 2)) || fail "--pr requires a value"
      PR_ARG=$2
      shift 2
      ;;
    --output)
      (($# >= 2)) || fail "--output requires a value"
      OUTPUT=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "$VERSION" ]] || fail "--version is required"
[[ -n "$RUN_ID" ]] || fail "--run-id is required"
[[ -n "$PR_ARG" ]] || fail "--pr is required"
[[ -n "$OUTPUT" ]] || fail "--output is required"

require_cmd gh
require_cmd jq
require_cmd curl
require_cmd git

PR_NUMBER=$(normalize_pr "$PR_ARG")
OUTPUT_PATH=$OUTPUT
[[ "$OUTPUT_PATH" = /* ]] || OUTPUT_PATH="$ROOT_DIR/$OUTPUT_PATH"
[[ -f "$OUTPUT_PATH" ]] || fail "output ledger does not exist: $OUTPUT_PATH"

git -C "$ROOT_DIR" fetch --tags --force origin

RUN_JSON=$(gh run view "$RUN_ID" --repo "$REPO" --json databaseId,url,workflowName,conclusion,jobs)
RUN_URL=$(jq -r '.url' <<<"$RUN_JSON")
RUN_CONCLUSION=$(jq -r '.conclusion' <<<"$RUN_JSON")
[[ "$RUN_CONCLUSION" == "success" ]] || fail "workflow run $RUN_ID did not succeed (conclusion=$RUN_CONCLUSION)"

job_names=( "Release Please" "Publish accrue" "Publish accrue_admin" "Publish accrue_portal" )
job_ids=( "release" "publish-accrue" "publish-accrue-admin" "publish-accrue-portal" )
job_lines=()

for i in "${!job_names[@]}"; do
  job_name=${job_names[$i]}
  job_id=${job_ids[$i]}
  job_json=$(jq -c --arg name "$job_name" '.jobs[] | select(.name == $name)' <<<"$RUN_JSON")
  [[ -n "$job_json" ]] || fail "workflow run $RUN_ID is missing job: $job_name"
  job_conclusion=$(jq -r '.conclusion' <<<"$job_json")
  job_started=$(jq -r '.startedAt' <<<"$job_json")
  job_completed=$(jq -r '.completedAt' <<<"$job_json")
  [[ "$job_conclusion" == "success" ]] || fail "$job_name did not succeed (conclusion=$job_conclusion)"
  job_lines+=( "| $job_id | $job_conclusion | $job_started | $job_completed |" )
done

release_lines=()
hex_lines=()
tag_lines=()

for package in accrue accrue_admin accrue_portal; do
  tag="${package}-v${VERSION}"
  git -C "$ROOT_DIR" rev-parse "$tag" >/dev/null 2>&1 || fail "missing git tag: $tag"
  tag_sha=$(git -C "$ROOT_DIR" rev-list -n 1 "$tag")
  tag_lines+=( "| $package | $tag | $tag_sha |" )

  release_json=$(gh release view "$tag" --repo "$REPO" --json tagName,url,publishedAt)
  release_url=$(jq -r '.url' <<<"$release_json")
  release_published=$(jq -r '.publishedAt' <<<"$release_json")
  release_lines+=( "| $package | $tag | $release_url | $release_published |" )

  hex_json=$(curl -fsSL "https://hex.pm/api/packages/${package}")
  hex_version=$(jq -r '.latest_version // empty' <<<"$hex_json")
  hex_updated=$(jq -r '.updated_at // empty' <<<"$hex_json")
  [[ "$hex_version" == "$VERSION" ]] ||
    fail "Hex latest_version mismatch for $package: expected $VERSION, found ${hex_version:-<empty>}"
  hex_lines+=( "| $package | $hex_version | $hex_updated | https://hex.pm/api/packages/$package |" )
done

captured_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

{
  printf '\n### Proof capture %s\n\n' "$captured_at"
  printf 'PR_NUMBER: %s\n' "$PR_NUMBER"
  printf 'TARGET_VERSION: %s\n' "$VERSION"
  printf 'RUN_ID: %s\n\n' "$RUN_ID"
  printf 'Workflow run: %s\n\n' "$RUN_URL"

  printf '#### Workflow job ordering\n\n'
  printf '| Job | Conclusion | Started | Completed |\n'
  printf '|-----|------------|---------|-----------|\n'
  for line in "${job_lines[@]}"; do
    printf '%s\n' "$line"
  done

  printf '\n#### Git tags\n\n'
  printf '| Package | Tag | Commit |\n'
  printf '|---------|-----|--------|\n'
  for line in "${tag_lines[@]}"; do
    printf '%s\n' "$line"
  done

  printf '\n#### GitHub releases\n\n'
  printf '| Package | Tag | Release URL | Published |\n'
  printf '|---------|-----|-------------|-----------|\n'
  for line in "${release_lines[@]}"; do
    printf '%s\n' "$line"
  done

  printf '\n#### Hex API truth\n\n'
  printf '| Package | latest_version | updated_at | API |\n'
  printf '|---------|----------------|------------|-----|\n'
  for line in "${hex_lines[@]}"; do
    printf '%s\n' "$line"
  done
} >>"$OUTPUT_PATH"

echo "OK: appended linked release proof for PR #$PR_NUMBER version $VERSION run $RUN_ID to $OUTPUT_PATH"
