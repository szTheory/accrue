#!/usr/bin/env bash
# Fail closed when v1.59 authority, amendment, or watchlist contracts drift.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
research_dir="${repo_root}/.planning/research"
index="${research_dir}/RESEARCH-INDEX.md"
authority="${research_dir}/v1.59-AUTHORITY.md"
amendments="${research_dir}/v1.59-AMENDMENTS.md"
watchlist="${research_dir}/v1.59-WATCHLIST.md"

fail() { echo "verify_v159_authority: $*" >&2; exit 1; }
require_file() { [[ -s "$1" ]] || fail "missing $2"; }
require() { grep -Fq "$1" "$2" || fail "${3:-missing required literal: $1}"; }

require_file "$index" "research index"
require_file "$authority" "authority manifest"
require_file "$amendments" "amendment ledger"
require_file "$watchlist" "watchlist"

first_bundle_entry=$(awk '/Current Milestone Canonical Bundle/,/Generic Research Files/' "$index" | grep -m1 '^-' || true)
[[ "$first_bundle_entry" == *'v1.59-AUTHORITY.md'* ]] || fail "first v1.59 index entry must be v1.59-AUTHORITY.md"

for literal in \
  'Bundle version:' 'Effective date:' 'Review state:' 'Active policy:' \
  '1. Current [PROJECT.md]' '2. Accepted v1.59 authority amendments' \
  '3. [v1.59-SUMMARY.md]' '4. [v1.59-SOURCES.md]' \
  '5. Specialist v1.59 research' '6. Generic research and prompts as historical context only.' \
  'v1.59-AMENDMENTS.md' 'v1.59-WATCHLIST.md' 'A newer prose edit never wins by recency.'; do
  require "$literal" "$authority" "authority manifest missing ${literal}"
done

for column in 'claim_id' 'active wording' 'disposition' 'confidence' 'source IDs' 'effective date' 'superseded locations' 'rationale' 'downstream phases/tests'; do
  require "$column" "$amendments" "amendment ledger missing ${column} field"
done

claim_ids=$(awk -F'|' '/^\| V159-CLAIM-/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}' "$amendments")
[[ -n "$claim_ids" ]] || fail "amendment ledger has no claim_id"
duplicates=$(printf '%s\n' "$claim_ids" | sort | uniq -d)
[[ -z "$duplicates" ]] || fail "duplicate claim_id: ${duplicates}"
awk -F'|' '/^\| V159-CLAIM-/ { for (i = 2; i <= 10; i++) { value=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); if (value == "" || value == "null") exit 1 } }' "$amendments" || fail "amendment ledger has missing claim field"
require 'no independent 72-hour cutoff' "$amendments" "amendment ledger missing no-72-hour claim"
require 'Historical independent 72-hour' "$amendments" "amendment ledger missing 72-hour superseded locations"
require 'dated reassessment' "$amendments" "amendment ledger missing dated reassessment protocol"

require '| Row ID | Monitor | Trigger | Owner phase / runbook | Required response |' "$watchlist" "watchlist missing required header"
require 'Effective review date:' "$watchlist" "watchlist missing effective review metadata"
require 'dated reassessment' "$watchlist" "watchlist missing dated reassessment behavior"

watch_rows=$(awk -F'|' '/^\| V159-WL-/ { print }' "$watchlist")
[[ -n "$watch_rows" ]] || fail "watchlist has no rows"
awk -F'|' '/^\| V159-WL-/ { for (i = 2; i <= 6; i++) { value=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); if (value == "" || value == "null") exit 1 } }' "$watchlist" || fail "watchlist row has empty or null field"

row_ids=$(printf '%s\n' "$watch_rows" | awk -F'|' '{v=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v}')
duplicates=$(printf '%s\n' "$row_ids" | sort | uniq -d)
[[ -z "$duplicates" ]] || fail "duplicate watchlist row ID: ${duplicates}"

tuples=$(printf '%s\n' "$watch_rows" | awk -F'|' '{for (i=3; i<=6; i++) {v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); printf "%s%s", v, (i == 6 ? ORS : "\034")}}')
duplicates=$(printf '%s\n' "$tuples" | sort | uniq -d)
[[ -z "$duplicates" ]] || fail "duplicate watchlist tuple: ${duplicates}"

for category in APPLE-API STRIPE CROSSWAKE DEPENDENCY POLICY PRIVACY SECURITY; do
  grep -Eq "^\\| V159-WL-${category} \\|" "$watchlist" || fail "watchlist missing ${category} category"
done

if ! awk -F'|' '/^\| V159-WL-/ { owner=$5; gsub(/^[[:space:]]+|[[:space:]]+$/, "", owner); if (owner !~ /^Phase 21[5-9] / && owner !~ /^Phase 220 /) exit 1 }' "$watchlist"; then
  fail "watchlist owner must name a current Phase 215-220 runbook"
fi

echo "verify_v159_authority: OK"
