#!/usr/bin/env bash
#
# annotation_sweep.sh
#
# Fails the current workflow run if named release-facing jobs still have
# warning or failure annotations attached to their check runs.
#
# Usage:
#   GITHUB_REPOSITORY=owner/repo GITHUB_RUN_ID=123 \
#   GH_TOKEN=... bash scripts/ci/annotation_sweep.sh release-gate host-integration
#
# Contract:
#   - Requires one or more job-name selectors on the command line.
#   - Requires GITHUB_REPOSITORY and GITHUB_RUN_ID.
#   - Requires GH_TOKEN or GITHUB_TOKEN with read access to Actions/checks data.
#   - Exits 2 for missing explicit CI inputs, 1 for API/query/annotation failures.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  GITHUB_REPOSITORY=owner/repo GITHUB_RUN_ID=123 GH_TOKEN=... \
    bash scripts/ci/annotation_sweep.sh release-gate host-integration annotation-sweep

Required environment:
  GITHUB_REPOSITORY   Repository in owner/name form
  GITHUB_RUN_ID       Current workflow run id
  GH_TOKEN            GitHub token with read access to Actions and checks
  GITHUB_TOKEN        Fallback token if GH_TOKEN is unset

Behavior:
  - Uses gh api when gh is installed, otherwise curl against https://api.github.com
  - Fails on warning, failure, or error annotations for the named jobs
  - Fails closed on API errors or when no named release-facing jobs are found
EOF
}

if [ "$#" -eq 0 ]; then
  usage
  exit 2
fi

if [ -z "${GITHUB_REPOSITORY:-}" ] || [ -z "${GITHUB_RUN_ID:-}" ]; then
  echo "annotation_sweep.sh requires GITHUB_REPOSITORY and GITHUB_RUN_ID." >&2
  usage >&2
  exit 2
fi

token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [ -z "$token" ]; then
  echo "annotation_sweep.sh requires GH_TOKEN or GITHUB_TOKEN." >&2
  usage >&2
  exit 2
fi

api_base="${GITHUB_API_URL:-https://api.github.com}"
repo_path="/repos/${GITHUB_REPOSITORY}"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

api_get() {
  local endpoint="$1"
  local body_file="$2"

  if command -v gh >/dev/null 2>&1; then
    GH_TOKEN="$token" gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$endpoint" >"$body_file"
  else
    curl --fail --silent --show-error \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $token" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${api_base}${endpoint}" >"$body_file"
  fi
}

fetch_paginated_array() {
  local endpoint_template="$1"
  local page_size="$2"
  local output_file="$3"
  local page=1
  : >"$output_file"

  while true; do
    local body_file="$tmp_dir/page-${page}.json"
    local endpoint
    endpoint="${endpoint_template}&per_page=${page_size}&page=${page}"
    api_get "$endpoint" "$body_file"

    local count
    count="$(python3 - "$body_file" "$output_file" <<'PY'
import json
import sys

body_path, output_path = sys.argv[1], sys.argv[2]
with open(body_path, "r", encoding="utf-8") as handle:
    payload = json.load(handle)

if isinstance(payload, dict):
    items = payload.get("jobs", [])
elif isinstance(payload, list):
    items = payload
else:
    raise SystemExit(f"Unsupported payload shape: {type(payload).__name__}")

with open(output_path, "a", encoding="utf-8") as handle:
    for item in items:
        handle.write(json.dumps(item))
        handle.write("\n")

print(len(items))
PY
)"

    if [ "$count" -lt "$page_size" ]; then
      break
    fi

    page=$((page + 1))
  done
}

jobs_ndjson="$tmp_dir/jobs.ndjson"
fetch_paginated_array "${repo_path}/actions/runs/${GITHUB_RUN_ID}/jobs?filter=latest" 100 "$jobs_ndjson"

matched_jobs="$tmp_dir/matched-jobs.ndjson"
python3 - "$jobs_ndjson" "$matched_jobs" "$@" <<'PY'
import json
import re
import sys

jobs_path = sys.argv[1]
output_path = sys.argv[2]
selectors = sys.argv[3:]

def normalize(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.lower()).strip()

needles = [normalize(selector) for selector in selectors]
matched = []

with open(jobs_path, "r", encoding="utf-8") as handle:
    for line in handle:
        if not line.strip():
            continue
        job = json.loads(line)
        haystack = normalize(job.get("name", ""))
        if any(needle and needle in haystack for needle in needles):
            matched.append(job)

seen = set()
with open(output_path, "w", encoding="utf-8") as handle:
    for job in matched:
        key = job.get("id")
        if key in seen:
            continue
        seen.add(key)
        handle.write(json.dumps(job))
        handle.write("\n")
PY

if [ ! -s "$matched_jobs" ]; then
  echo "No release-facing jobs matched: $*" >&2
  exit 1
fi

failures_file="$tmp_dir/failures.txt"
: >"$failures_file"

while IFS= read -r job_json; do
  [ -n "$job_json" ] || continue

  job_name="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("name",""))' <<<"$job_json")"
  check_run_url="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("check_run_url",""))' <<<"$job_json")"

  if [ -z "$check_run_url" ]; then
    echo "Unable to inspect annotations for job: $job_name" >&2
    exit 1
  fi

  annotation_path="${check_run_url#${api_base}}/annotations?"
  annotations_ndjson="$tmp_dir/$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("id"))' <<<"$job_json").annotations.ndjson"
  fetch_paginated_array "$annotation_path" 50 "$annotations_ndjson"

  python3 - "$job_name" "$annotations_ndjson" "$failures_file" <<'PY'
import json
import sys

job_name, annotations_path, failures_path = sys.argv[1:4]
levels = {"warning", "failure", "error"}
rows = []

with open(annotations_path, "r", encoding="utf-8") as handle:
    for line in handle:
        if not line.strip():
            continue
        annotation = json.loads(line)
        level = str(annotation.get("annotation_level", "")).lower()
        if level not in levels:
            continue
        path = annotation.get("path") or "[no path]"
        message = " ".join(str(annotation.get("message", "")).split())
        rows.append(f"{job_name}\t{path}\t{level}\t{message}")

if rows:
    with open(failures_path, "a", encoding="utf-8") as handle:
        for row in rows:
            handle.write(row)
            handle.write("\n")
PY
done <"$matched_jobs"

if [ -s "$failures_file" ]; then
  echo "Release-facing annotations detected:"
  while IFS=$'\t' read -r job_name annotation_path annotation_level annotation_message; do
    printf '%s | %s | %s | %s\n' \
      "$job_name" \
      "$annotation_path" \
      "$annotation_level" \
      "$annotation_message"
  done <"$failures_file"
  exit 1
fi

echo "No warning, failure, or error annotations detected for: $*"
