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
Usage:
  bash scripts/ci/capture_linked_release_proof.sh --auto [--output <path>]
  bash scripts/ci/capture_linked_release_proof.sh --version <x.y.z> --run-id <id> --pr <number-or-url> --output <path>
  bash scripts/ci/capture_linked_release_proof.sh --recovery --version <x.y.z> --run-id <id> --pr <number> \
      --accrue-public-state <state> --accrue-admin-public-state <state> --accrue-portal-public-state <state> \
      --failed-step <step> --recovery-path <path> --next-command <command> --output <path>

Append a deterministic linked-release proof block keyed to one PR number, one target
version, and one Release Please workflow run id. The appended block captures:
- git tags for accrue, accrue_admin, accrue_portal
- GitHub release URLs and publish timestamps
- Hex API latest_version and updated_at for all three packages
- Release Please workflow job conclusions and ordering
- release file snapshot for manifest + package mix/changelog files
- HexDocs availability for all three packages

With --recovery, append a partial publish recovery block instead:
- Records public state of each package
- Documents the failed step and intended recovery path
- Recommends the exact next command

With --auto, derive the proof identifiers from GitHub Actions:
- RUN_ID from GITHUB_RUN_ID
- PR_NUMBER from the pull request associated with GITHUB_SHA
- TARGET_VERSION from the lockstep .release-please-manifest.json
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required but not installed"
}

normalize_pr() {
  local value=$1

  if [[ "$value" =~ ^https?://github\.com/[^/]+/[^/]+/pull/([0-9]+) ]]; then
    local pr_repo="${BASH_REMATCH[0]#https://github.com/}"
    pr_repo="${pr_repo#http://github.com/}"
    pr_repo="${pr_repo%/pull/*}"
    [[ "$pr_repo" == "$REPO" ]] || fail "PR URL repo mismatch: expected $REPO, found $pr_repo"
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$value"
  else
    fail "invalid PR identifier: $value"
  fi
}

version_gt() {
  local lower=$1
  local candidate=$2
  [[ "$candidate" != "$lower" ]] &&
    [[ "$(printf '%s\n%s\n' "$lower" "$candidate" | sort -V | tail -n 1)" == "$candidate" ]]
}

derive_version_from_manifest() {
  local manifest="$ROOT_DIR/.release-please-manifest.json"
  [[ -f "$manifest" ]] || fail "release manifest does not exist: $manifest"

  local accrue_version admin_version portal_version
  accrue_version=$(jq -r '.accrue // empty' "$manifest")
  admin_version=$(jq -r '.accrue_admin // empty' "$manifest")
  portal_version=$(jq -r '.accrue_portal // empty' "$manifest")

  [[ -n "$accrue_version" && -n "$admin_version" && -n "$portal_version" ]] ||
    fail "manifest must contain accrue, accrue_admin, and accrue_portal versions"
  [[ "$accrue_version" == "$admin_version" && "$accrue_version" == "$portal_version" ]] ||
    fail "manifest versions are not lockstep: accrue=$accrue_version accrue_admin=$admin_version accrue_portal=$portal_version"

  local min_version="${LINKED_RELEASE_MIN_VERSION:-1.3.0}"
  version_gt "$min_version" "$accrue_version" ||
    fail "target version must be greater than $min_version for linked proof (found $accrue_version)"

  printf '%s\n' "$accrue_version"
}

derive_pr_from_commit() {
  local sha=$1
  local prs_json pr_number

  prs_json=$(gh api \
    -H "Accept: application/vnd.github+json" \
    "repos/$REPO/commits/$sha/pulls?per_page=100")

  pr_number=$(jq -r '
    [
      .[]
      | select((.merged_at // "") != "")
      | select(
          ((.head.ref // "") | startswith("release-please--"))
          or ((.title // "") | test("release"; "i"))
        )
    ]
    | sort_by(.number)
    | last
    | .number // empty
  ' <<<"$prs_json")

  [[ -n "$pr_number" ]] ||
    fail "could not derive a merged Release Please PR associated with commit $sha"

  printf '%s\n' "$pr_number"
}

AUTO_MODE=false
RECOVERY_MODE=false
VERSION=""
RUN_ID=""
PR_ARG=""
OUTPUT=""
ACCRUE_PUBLIC_STATE=""
ACCRUE_ADMIN_PUBLIC_STATE=""
ACCRUE_PORTAL_PUBLIC_STATE=""
FAILED_STEP=""
RECOVERY_PATH=""
NEXT_COMMAND=""

while (($# > 0)); do
  case "$1" in
    --auto)
      AUTO_MODE=true
      shift
      ;;
    --recovery)
      RECOVERY_MODE=true
      shift
      ;;
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
    --accrue-public-state)
      (($# >= 2)) || fail "--accrue-public-state requires a value"
      ACCRUE_PUBLIC_STATE=$2
      shift 2
      ;;
    --accrue-admin-public-state)
      (($# >= 2)) || fail "--accrue-admin-public-state requires a value"
      ACCRUE_ADMIN_PUBLIC_STATE=$2
      shift 2
      ;;
    --accrue-portal-public-state)
      (($# >= 2)) || fail "--accrue-portal-public-state requires a value"
      ACCRUE_PORTAL_PUBLIC_STATE=$2
      shift 2
      ;;
    --failed-step)
      (($# >= 2)) || fail "--failed-step requires a value"
      FAILED_STEP=$2
      shift 2
      ;;
    --recovery-path)
      (($# >= 2)) || fail "--recovery-path requires a value"
      RECOVERY_PATH=$2
      shift 2
      ;;
    --next-command)
      (($# >= 2)) || fail "--next-command requires a value"
      NEXT_COMMAND=$2
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

require_cmd gh
require_cmd jq
require_cmd curl
require_cmd git

if command -v shasum >/dev/null 2>&1; then
  sha256_file() { shasum -a 256 "$1" | awk '{print $1}'; }
elif command -v sha256sum >/dev/null 2>&1; then
  sha256_file() { sha256sum "$1" | awk '{print $1}'; }
else
  fail "shasum or sha256sum is required but not installed"
fi

if [[ "$AUTO_MODE" == "true" ]]; then
  [[ -n "${GITHUB_ACTIONS:-}" ]] || fail "--auto requires GitHub Actions environment"
  [[ -n "${GITHUB_RUN_ID:-}" ]] || fail "--auto requires GITHUB_RUN_ID"
  [[ -n "${GITHUB_SHA:-}" ]] || fail "--auto requires GITHUB_SHA"

  VERSION=${VERSION:-$(derive_version_from_manifest)}
  RUN_ID=${RUN_ID:-$GITHUB_RUN_ID}
  PR_ARG=${PR_ARG:-$(derive_pr_from_commit "$GITHUB_SHA")}
  OUTPUT=${OUTPUT:-linked-release-proof.md}
fi

[[ -n "$VERSION" ]] || fail "--version is required"
[[ -n "$RUN_ID" ]] || fail "--run-id is required"
[[ -n "$PR_ARG" ]] || fail "--pr is required"
[[ -n "$OUTPUT" ]] || fail "--output is required"

PR_NUMBER=$(normalize_pr "$PR_ARG")
OUTPUT_PATH=$OUTPUT
[[ "$OUTPUT_PATH" = /* ]] || OUTPUT_PATH="$ROOT_DIR/$OUTPUT_PATH"
mkdir -p "$(dirname "$OUTPUT_PATH")"
touch "$OUTPUT_PATH"

if [[ "$RECOVERY_MODE" == "true" ]]; then
  [[ -n "$ACCRUE_PUBLIC_STATE" ]] || fail "--accrue-public-state is required in recovery mode"
  [[ -n "$ACCRUE_ADMIN_PUBLIC_STATE" ]] || fail "--accrue-admin-public-state is required in recovery mode"
  [[ -n "$ACCRUE_PORTAL_PUBLIC_STATE" ]] || fail "--accrue-portal-public-state is required in recovery mode"
  [[ -n "$FAILED_STEP" ]] || fail "--failed-step is required in recovery mode"
  [[ -n "$RECOVERY_PATH" ]] || fail "--recovery-path is required in recovery mode"
  [[ -n "$NEXT_COMMAND" ]] || fail "--next-command is required in recovery mode"

  captured_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  {
    printf '\n### Recovery attempt %s\n\n' "$captured_at"
    printf 'target_version: %s\n' "$VERSION"
    printf 'run_id: %s\n' "$RUN_ID"
    printf 'pr_number: %s\n' "$PR_NUMBER"
    printf 'accrue_public_state: %s\n' "$ACCRUE_PUBLIC_STATE"
    printf 'accrue_admin_public_state: %s\n' "$ACCRUE_ADMIN_PUBLIC_STATE"
    printf 'accrue_portal_public_state: %s\n' "$ACCRUE_PORTAL_PUBLIC_STATE"
    printf 'failed_step: %s\n' "$FAILED_STEP"
    printf 'recovery_path: %s\n' "$RECOVERY_PATH"
    printf 'next_command: %s\n' "$NEXT_COMMAND"
    printf 'recorded_at: %s\n' "$captured_at"
  } >>"$OUTPUT_PATH"

  echo "OK: appended recovery block for PR #$PR_NUMBER version $VERSION run $RUN_ID to $OUTPUT_PATH"
  exit 0
fi

git -C "$ROOT_DIR" fetch --tags --force origin

RUN_JSON=$(gh run view "$RUN_ID" --repo "$REPO" --json databaseId,url,workflowName,headSha,conclusion,jobs)
RUN_URL=$(jq -r '.url' <<<"$RUN_JSON")
RUN_WORKFLOW_NAME=$(jq -r '.workflowName // empty' <<<"$RUN_JSON")
RUN_HEAD_SHA=$(jq -r '.headSha // empty' <<<"$RUN_JSON")
RUN_CONCLUSION=$(jq -r '.conclusion' <<<"$RUN_JSON")
[[ "$RUN_WORKFLOW_NAME" == "release-please" || "$RUN_WORKFLOW_NAME" == "Release Please" ]] ||
  fail "run $RUN_ID is not the release workflow (workflowName=${RUN_WORKFLOW_NAME:-<empty>})"
if [[ "$RUN_CONCLUSION" != "success" ]]; then
  if [[ "$AUTO_MODE" != "true" || "${GITHUB_RUN_ID:-}" != "$RUN_ID" || ! "$RUN_CONCLUSION" =~ ^(|null)$ ]]; then
    fail "workflow run $RUN_ID did not succeed (conclusion=$RUN_CONCLUSION)"
  fi
fi

PR_JSON=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json number,mergeCommit,url)
PR_FOUND_NUMBER=$(jq -r '.number // empty' <<<"$PR_JSON")
PR_MERGE_SHA=$(jq -r '.mergeCommit.oid // empty' <<<"$PR_JSON")
[[ "$PR_FOUND_NUMBER" == "$PR_NUMBER" ]] || fail "PR not found in $REPO: #$PR_NUMBER"
[[ -n "$PR_MERGE_SHA" ]] || fail "PR #$PR_NUMBER does not have a merge commit"
[[ "$RUN_HEAD_SHA" == "$PR_MERGE_SHA" ]] ||
  fail "workflow run $RUN_ID head SHA ($RUN_HEAD_SHA) is not bound to PR #$PR_NUMBER merge commit ($PR_MERGE_SHA)"

job_names=( "Release Please" "Publish accrue" "Publish accrue_admin" "Publish accrue_portal" )
job_ids=( "release" "publish-accrue" "publish-accrue-admin" "publish-accrue-portal" )
job_lines=()

for i in "${!job_names[@]}"; do
  job_name=${job_names[$i]}
  job_id=${job_ids[$i]}
  job_json=$(jq -c --arg name "$job_name" '[.jobs[] | select(.name == $name)] | sort_by(.startedAt) | last // empty' <<<"$RUN_JSON")
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
snapshot_lines=()
hexdocs_lines=()

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

  hexdocs_url="https://hexdocs.pm/${package}/readme.html"
  hexdocs_status=$(curl -fsSIL -o /dev/null -w "%{http_code}" "$hexdocs_url" || true)
  [[ -n "$hexdocs_status" ]] || hexdocs_status="000"
  [[ "$hexdocs_status" == "200" ]] || fail "HexDocs availability check failed for $package (status=$hexdocs_status url=$hexdocs_url)"
  hexdocs_lines+=( "| $package | $hexdocs_url | $hexdocs_status |" )
done

for file in \
  ".release-please-manifest.json" \
  "accrue/mix.exs" \
  "accrue_admin/mix.exs" \
  "accrue_portal/mix.exs" \
  "accrue/CHANGELOG.md" \
  "accrue_admin/CHANGELOG.md" \
  "accrue_portal/CHANGELOG.md"; do
  abs="$ROOT_DIR/$file"
  [[ -f "$abs" ]] || fail "release snapshot file missing: $file"
  sha=$(sha256_file "$abs")
  snapshot_lines+=( "| $file | $sha |" )
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

  printf '\n#### Release file snapshot\n\n'
  printf '| File | sha256 |\n'
  printf '|------|--------|\n'
  for line in "${snapshot_lines[@]}"; do
    printf '%s\n' "$line"
  done

  printf '\n#### HexDocs availability\n\n'
  printf '| Package | URL | HTTP |\n'
  printf '|---------|-----|------|\n'
  for line in "${hexdocs_lines[@]}"; do
    printf '%s\n' "$line"
  done
} >>"$OUTPUT_PATH"

echo "OK: appended linked release proof for PR #$PR_NUMBER version $VERSION run $RUN_ID to $OUTPUT_PATH"
