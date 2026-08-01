#!/usr/bin/env bash
# Merge gate for the bounded, processor-free entitlement-source contract.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
matrix="$ROOT_DIR/.planning/entitlement-source-capability-matrix.md"
guide="$ROOT_DIR/accrue/guides/entitlements.md"
fixture="$ROOT_DIR/accrue/priv/entitlements/v1.59-source-capabilities.json"
registry="$ROOT_DIR/accrue/lib/accrue/entitlements/source/registry.ex"
source_dir="$ROOT_DIR/accrue/lib/accrue/entitlements/source"

fail() { echo "verify_entitlement_source_matrix: FAIL: $1" >&2; exit 1; }
for file in "$matrix" "$guide" "$fixture" "$registry"; do [ -f "$file" ] || fail "missing $file"; done

for capability in observation control restore reconciliation management offline; do
  grep -Fq "$capability" "$fixture" || fail "fixture missing capability $capability"
  grep -Fq "\`$capability\`" "$matrix" || fail "matrix missing capability $capability"
  grep -Fq "\`$capability\`" "$guide" || fail "guide missing capability $capability"
done

for state in supported externally_managed host_owned deferred unavailable feasibility_blocked; do
  grep -Fq "$state" "$fixture" || fail "fixture missing state $state"
  grep -Fq "\`$state\`" "$matrix" || fail "matrix missing state $state"
  grep -Fq "\`$state\`" "$guide" || fail "guide missing state $state"
done

grep -Fq '"source":"apple","capability":"management","state":"externally_managed"' "$fixture" || fail "fixture missing Apple management outcome"
grep -Fq 'https://apps.apple.com/account/subscriptions' "$fixture" || fail "fixture missing Apple management URL"
grep -Fq 'processor-support-matrix.md' "$matrix" || fail "matrix missing separate processor authority"
grep -Fq 'processor-support-matrix.md' "$guide" || fail "guide missing separate processor authority"

# Limit leakage detection to source runtime modules. Documentation may accurately
# name forbidden operations while explaining why they are unavailable.
if grep -REn 'Accrue\.Processor|\.cancel_subscription|\.create_invoice|\.retry|\.swap|payment_method' "$source_dir"; then
  fail "source boundary contains a processor mutation edge"
fi

if grep -Eq 'true|false' "$fixture"; then
  fail "fixture contains booleanized capability state"
fi

echo "verify_entitlement_source_matrix: OK"
