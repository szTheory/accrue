#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
if [[ "$mode" != "source-gate" && "$mode" != "tracer" && "$mode" != "admission" && "$mode" != "lifecycle" && "$mode" != "trusted-frame" && "$mode" != "full" ]]; then
  echo "usage: $0 {source-gate|tracer|admission|lifecycle|trusted-frame|full}" >&2
  exit 64
fi

if [[ -z "${CROSSWAKE_SOURCE_ROOT:-}" || ! -e "$CROSSWAKE_SOURCE_ROOT/.git" ]]; then
  echo "CROSSWAKE_SOURCE_ROOT must name the authorized Crosswake checkout" >&2
  exit 65
fi

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
lock="$repo_root/.planning/phases/224-crosswake-host-command-bridge-seam/crosswake-source-lock.json"
audit="$repo_root/.planning/phases/224-crosswake-host-command-bridge-seam/224-CROSSWAKE-SOURCE-AUDIT.md"
evidence="$repo_root/.planning/phases/224-crosswake-host-command-bridge-seam/224-BRIDGE-CONFORMANCE-EVIDENCE.md"
report="$repo_root/examples/crosswake_tracer/capability-report.json"
expected_test_target='swift test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests'

[[ -f "$lock" && -f "$audit" ]] || { echo "source lock and audit are required" >&2; exit 66; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 67; }

remote="$(git -C "$CROSSWAKE_SOURCE_ROOT" remote get-url origin | sed -E 's#(https?://)[^/@]+@#\1#')"
expected_remote="$(jq -er '.sanitized_remote' "$lock")"
[[ "$remote" == "$expected_remote" ]] || { echo "Crosswake remote does not match the pinned sanitized identity" >&2; exit 68; }

[[ -z "$(git -C "$CROSSWAKE_SOURCE_ROOT" status --porcelain)" ]] || { echo "Crosswake checkout must be clean" >&2; exit 69; }
head="$(git -C "$CROSSWAKE_SOURCE_ROOT" rev-parse HEAD)"
base="$(jq -er '.upstream_base_revision' "$lock")"
state="$(jq -er '.lock_state' "$lock")"
audit_sha="$(shasum -a 256 "$audit" | awk '{print $1}')"
[[ "$audit_sha" == "$(jq -er '.audit_sha256' "$lock")" ]] || { echo "Crosswake audit digest mismatch" >&2; exit 70; }

case "$state" in
  base_locked)
    [[ "$head" == "$base" ]] || { echo "base_locked source HEAD must equal immutable base" >&2; exit 71; }
    ;;
  reviewed_patch)
    patch="$(jq -er '.patch_revision' "$lock")"
    expected_diff="$(jq -er '.diff_identity' "$lock")"
    [[ "$head" == "$patch" ]] || { echo "reviewed source HEAD must equal pinned patch" >&2; exit 72; }
    git -C "$CROSSWAKE_SOURCE_ROOT" merge-base --is-ancestor "$base" "$patch" || { echo "immutable base is not an ancestor of reviewed patch" >&2; exit 73; }
    actual_diff="$(git -C "$CROSSWAKE_SOURCE_ROOT" diff --binary "$base" "$patch" | shasum -a 256 | awk '{print $1}')"
    [[ "$actual_diff" == "$expected_diff" ]] || { echo "reviewed patch diff identity mismatch" >&2; exit 74; }
    ;;
  *) echo "unsupported lock state: $state" >&2; exit 75 ;;
esac

if [[ "$mode" == "full" ]]; then
  (cd "$CROSSWAKE_SOURCE_ROOT" && swift test --package-path packages/crosswake-shell-core-ios)
  (cd "$repo_root" && swift test --package-path examples/crosswake_tracer)
  [[ -f "$evidence" && -f "$report" ]] || { echo "conformance evidence and capability report are required" >&2; exit 77; }
  evidence_sha="$(shasum -a 256 "$evidence" | awk '{print $1}')"
  [[ "$evidence_sha" == "$(jq -er '.conformance_evidence_sha256' "$lock")" ]] || { echo "conformance evidence digest mismatch" >&2; exit 78; }
  jq -e '
    .overall_status == "feasibility_blocked" and
    all(.capabilities[]; .status == "feasibility_blocked") and
    all(.capabilities[] | .evidence[]; (.kind != "crosswake_bridge_compile_unit") or (.location | contains("224-BRIDGE-CONFORMANCE-EVIDENCE.md")))
  ' "$report" >/dev/null || { echo "capability report must retain blocked statuses and evidence locations" >&2; exit 79; }
elif [[ "$mode" == "tracer" || "$mode" == "admission" || "$mode" == "lifecycle" || "$mode" == "trusted-frame" ]]; then
  [[ "$state" == "reviewed_patch" ]] || { echo "tracer requires reviewed_patch lock state" >&2; exit 76; }
  test_target="$(jq -er '.test_target' "$lock")"
  [[ "$test_target" == "$expected_test_target" ]] || { echo "unexpected pinned test target" >&2; exit 80; }
  (cd "$CROSSWAKE_SOURCE_ROOT" && swift test \
    --package-path packages/crosswake-shell-core-ios \
    --filter HostCommandAdmissionTests)
fi

echo "Crosswake ${mode} verification passed (${state})"
