#!/usr/bin/env bash
# Shift-left merge gate (ENT-10 / D-04 layer 2): the always-on entitlement gate
# path stays isolated from the optional Stripe-native advisory cache.
#
# Fails the build if any ALWAYS-ON gate-path file references the advisory cache
# (the Stripe-native entitlement-summary overlay). This makes "the advisory
# cache is observational-only and can NEVER influence gating" a verifiable,
# non-regressing invariant: a future refactor that accidentally wires the cache
# into the gate (fail-open via stale/partial cache, T-127-09) is blocked at
# merge, not caught post-merge.
#
# Gate-path files scanned (the always-on entitlement decision path):
#   - accrue/lib/accrue/entitlements.ex                      (public fail-closed gate API)
#   - accrue/lib/accrue/entitlements/resolver.ex             (resolver behaviour + dispatch)
#   - accrue/lib/accrue/entitlements/resolver/local_map.ex   (default local-state resolver)
#
# What it matches (REAL refs only, never doc comments or strings):
#   - `EntitlementSummary`            (the advisory-cache model)
#   - `StripeSync`                    (the Stripe-native sync namespace)
#   - `accrue_entitlement_summaries`  (the advisory-cache table)
#
# Allowlist (by construction):
#   - Doc comments / comment lines — the `^[^#]*` anchor means a matched
#     alternative must appear BEFORE any `#` on the line, so a leading-`#`
#     comment line (e.g. a moduledoc that NAMES the cache to explain the
#     isolation) never trips the gate, and a same-line trailing comment is
#     ignored. Only real code refs fail the build.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
lib="${repo_root}/accrue/lib"

gate_path_files=(
  "${lib}/accrue/entitlements.ex"
  "${lib}/accrue/entitlements/resolver.ex"
  "${lib}/accrue/entitlements/resolver/local_map.ex"
)

for f in "${gate_path_files[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "verify_entitlement_sync_isolation: missing gate-path file ${f}" >&2
    exit 1
  fi
done

hits=$(grep -rnE \
  '^[^#]*(EntitlementSummary|StripeSync|accrue_entitlement_summaries)' \
  "${gate_path_files[@]}" \
  || true)

if [[ -n "${hits}" ]]; then
  echo "verify_entitlement_sync_isolation: FAIL — advisory-cache ref reachable from the always-on gate path:" >&2
  echo "${hits}" >&2
  echo "The Stripe-native entitlement-summary cache is observational-only (D-01); it must NEVER be referenced from the gate-decision path (T-127-09)." >&2
  exit 1
fi

echo "verify_entitlement_sync_isolation: OK"
