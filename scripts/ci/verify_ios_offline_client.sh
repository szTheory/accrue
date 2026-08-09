#!/usr/bin/env bash
# Merge gate for the standalone offline client and its non-promoting tracer consumer.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PACKAGE_DIR="$ROOT_DIR/packages/accrue-offline-client"
TRACER_DIR="$ROOT_DIR/examples/crosswake_tracer"
REPORT="$TRACER_DIR/capability-report.json"
PHYSICAL_EVIDENCE="$TRACER_DIR/physical-device-evidence.md"

fail() { echo "verify_ios_offline_client: FAIL: $1" >&2; exit 1; }

for command in swift xcrun jq shasum cmp grep; do
  command -v "$command" >/dev/null 2>&1 || fail "$command is required"
done
for file in "$PACKAGE_DIR/Package.swift" "$REPORT" "$PHYSICAL_EVIDENCE"; do
  [ -f "$file" ] || fail "missing required file ${file#$ROOT_DIR/}"
done

report_before="$(mktemp)"
evidence_before="$(mktemp)"
trap 'rm -f "$report_before" "$evidence_before"' EXIT
shasum -a 256 "$REPORT" >"$report_before"
shasum -a 256 "$PHYSICAL_EVIDENCE" >"$evidence_before"

# Repository fixtures, private keys, and process fault harnesses are test-only.
runtime_sources="$PACKAGE_DIR/Sources/AccrueOfflineClientCore"
[ -d "$runtime_sources" ] || fail "missing core runtime sources"
if grep -R -n -E '#filePath|v1\.59-offline-test-key|v1\.59-offline-golden-vectors|Crosswake|StoreKit|SwiftUI|UIKit' "$runtime_sources"; then
  fail "core runtime source exposes a test fixture, key, or host runtime API"
fi
grep -R -q -E 'v1\.59-offline-golden-vectors|v1\.59-offline-test-key' "$PACKAGE_DIR/Tests" ||
  fail "test support no longer references the canonical corpus and key"
if ! swift package --package-path "$PACKAGE_DIR" dump-package | jq -e '
  ([.products[] | select(.name == "AccrueOfflineClientCore") | .targets] == [["AccrueOfflineClientCore"]]) and
  ([.targets[] | select(.name == "AccrueOfflineClientCore") | .dependencies] == [[]])
' >/dev/null; then
  fail "core product is not isolated from the crash harness"
fi

swift test --package-path "$PACKAGE_DIR"

SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
[ -d "$SDKROOT" ] || fail "iphoneos SDK path is unavailable"
swift build --package-path "$PACKAGE_DIR" --triple arm64-apple-ios16.0 \
  --target AccrueOfflineClientCore -Xswiftc -sdk -Xswiftc "$SDKROOT"

# This compilation is a compatibility check only. The capability report remains
# independently feasibility-blocked unless the external device-evidence process acts.
swift test --package-path "$TRACER_DIR"
jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' \
  "$REPORT" >/dev/null || fail "deterministic commands cannot promote feasibility"
cmp -s "$report_before" <(shasum -a 256 "$REPORT") || fail "capability report was modified"
cmp -s "$evidence_before" <(shasum -a 256 "$PHYSICAL_EVIDENCE") || fail "physical-device evidence was modified"

echo "verify_ios_offline_client: OK"
