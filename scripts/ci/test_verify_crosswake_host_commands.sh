#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT

fixture_repo="$fixture_root/repo"
fixture_source="$fixture_root/crosswake"
fixture_bin="$fixture_root/bin"
lock="$fixture_repo/.planning/phases/224-crosswake-host-command-bridge-seam/crosswake-source-lock.json"
swift_log="$fixture_root/swift-argv.log"
swift_marker="$fixture_root/swift-ran"
injected_marker="$fixture_root/injected"
approved_target='swift test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests'
base='932b4f32bf087b8e4c0c36c3e54b1031839e867d'
patch='fc5e399fcb46d78b610c81e13c644277f3fcf1c5'

mkdir -p \
  "$fixture_repo/scripts/ci" \
  "$(dirname "$lock")" \
  "$fixture_source/.git" \
  "$fixture_bin"
cp "$repo_root/scripts/ci/verify_crosswake_host_commands.sh" "$fixture_repo/scripts/ci/"
chmod +x "$fixture_repo/scripts/ci/verify_crosswake_host_commands.sh"

printf '%s\n' 'fixture audit' > "$fixture_repo/.planning/phases/224-crosswake-host-command-bridge-seam/224-CROSSWAKE-SOURCE-AUDIT.md"
audit_sha="$(shasum -a 256 "$fixture_repo/.planning/phases/224-crosswake-host-command-bridge-seam/224-CROSSWAKE-SOURCE-AUDIT.md" | awk '{print $1}')"
diff_sha="$(printf '%s\n' 'fixture reviewed diff' | shasum -a 256 | awk '{print $1}')"

jq -n \
  --arg audit_sha "$audit_sha" \
  --arg diff_sha "$diff_sha" \
  --arg base "$base" \
  --arg patch "$patch" \
  --arg test_target "$approved_target" \
  '{
    lock_state: "reviewed_patch",
    sanitized_remote: "https://github.com/szTheory/crosswake.git",
    upstream_base_revision: $base,
    patch_revision: $patch,
    audit_sha256: $audit_sha,
    diff_identity: $diff_sha,
    test_target: $test_target
  }' > "$lock"

cat > "$fixture_bin/git" <<'SHIM'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "-C" ]]; then
  shift 2
fi
case "${1:-}" in
  remote)
    printf '%s\n' 'https://github.com/szTheory/crosswake.git'
    ;;
  status)
    ;;
  rev-parse)
    printf '%s\n' 'fc5e399fcb46d78b610c81e13c644277f3fcf1c5'
    ;;
  merge-base)
    ;;
  diff)
    printf '%s\n' 'fixture reviewed diff'
    ;;
  *)
    echo "unexpected git invocation: $*" >&2
    exit 97
    ;;
esac
SHIM
chmod +x "$fixture_bin/git"

cat > "$fixture_bin/swift" <<'SHIM'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$PWD" > "$SWIFT_PWD_LOG"
printf '%s\n' "$@" > "$SWIFT_ARGV_LOG"
touch "$SWIFT_MARKER"
SHIM
chmod +x "$fixture_bin/swift"

run_runner() {
  PATH="$fixture_bin:$PATH" \
  CROSSWAKE_SOURCE_ROOT="$fixture_source" \
  SWIFT_PWD_LOG="$fixture_root/swift-pwd.log" \
  SWIFT_ARGV_LOG="$swift_log" \
  SWIFT_MARKER="$swift_marker" \
  bash "$fixture_repo/scripts/ci/verify_crosswake_host_commands.sh" trusted-frame
}

run_runner
[[ "$(cat "$fixture_root/swift-pwd.log")" == "$fixture_source" ]] || {
  echo "Swift did not run from the Crosswake source root" >&2
  exit 1
}
diff -u <(printf '%s\n' test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests) "$swift_log"
[[ -f "$swift_marker" ]] || { echo "Swift shim was not invoked" >&2; exit 1; }

malicious_target="$approved_target; touch $injected_marker"
jq --arg test_target "$malicious_target" '.test_target = $test_target' "$lock" > "$lock.tmp"
mv "$lock.tmp" "$lock"
set +e
run_runner
status=$?
set -e
[[ "$status" -eq 80 ]] || { echo "shell-bearing target returned $status, expected 80" >&2; exit 1; }
[[ ! -e "$injected_marker" ]] || { echo "shell-bearing target executed an injected side effect" >&2; exit 1; }
[[ "$(wc -l < "$swift_log" | tr -d ' ')" -eq 5 ]] || { echo "shell-bearing target launched Swift" >&2; exit 1; }

jq --arg test_target 'swift test --package-path packages/crosswake-shell-core-ios --filter DifferentSuite' '.test_target = $test_target' "$lock" > "$lock.tmp"
mv "$lock.tmp" "$lock"
set +e
run_runner
status=$?
set -e
[[ "$status" -eq 80 ]] || { echo "substitute target returned $status, expected 80" >&2; exit 1; }
[[ "$(wc -l < "$swift_log" | tr -d ' ')" -eq 5 ]] || { echo "substitute target launched Swift" >&2; exit 1; }

echo "Crosswake host-command runner target rejection regression passed"
