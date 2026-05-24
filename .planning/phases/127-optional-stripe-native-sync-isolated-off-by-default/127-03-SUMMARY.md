---
phase: 127-optional-stripe-native-sync-isolated-off-by-default
plan: 03
subsystem: testing
tags: [entitlements, stripe, capability-matrix, ci-gate, provider-honesty, drift-gate, static-analysis]

# Dependency graph
requires:
  - phase: 125-provider-honesty-lifecycle-truth
    provides: "entitlements.local_mapping convergence row + verify_processor_support_matrix.sh drift gate (positive byte-match + negative divergence guard)"
  - phase: 124-enforcement-surfaces-plug-liveview-guards
    provides: "verify_core_liveview_runtime_free.sh static-grep merge-gate clone target"
  - phase: 123-config-core-gate-api-foundation
    provides: "always-on gate-path files (entitlements.ex, resolver.ex, resolver/local_map.ex) the isolation gate scans"
provides:
  - "NEW entitlements.stripe_native_sync capability row (stripe: native (advisory), fake: out of slice, braintree: unsupported) across code labels + matrix markdown + drift gate (3-way SSOT)"
  - "Tightened verify_processor_support_matrix.sh negative divergence guard scoped to the local_mapping convergence row (exempts the new advisory row, still protects convergence)"
  - "NEW merge-blocking verify_entitlement_sync_isolation.sh static gate proving the advisory cache is unreachable from the always-on gate path (T-127-09)"
  - "CI wiring: isolation gate added to the docs-contracts-shift-left job"
affects: [127-default-handler-cache-projection, 127-admin-read-seam, entitlements, provider-honesty]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Capability-matrix: NEW divergence row alongside an existing convergence row; never mutate the convergence row (D-10)"
    - "Static merge-gate clone: comment-anchored grep (^[^#]*) + allowlist-by-construction + trailing || true, scoped to named gate-path files"

key-files:
  created:
    - scripts/ci/verify_entitlement_sync_isolation.sh
  modified:
    - accrue/lib/accrue/processor/capabilities.ex
    - .planning/processor-support-matrix.md
    - scripts/ci/verify_processor_support_matrix.sh
    - .github/workflows/ci.yml

key-decisions:
  - "Tightened the negative divergence guard by ANCHORING it to entitlements.local_mapping (not every entitlements.* row) — simplest way to exempt the new advisory row while keeping full convergence protection; paired with a positive require_substring for the exact new row line."
  - "Scoped the isolation gate to exactly the three always-on gate-path files (entitlements.ex, resolver.ex, resolver/local_map.ex) rather than all of accrue/lib — the cache MODEL itself will legitimately exist in core; only the gate-decision path must stay cache-free."
  - "Public label wording: 'Stripe-native advisory (observational)' / provider cell 'native (advisory)' — honest that Stripe-native sync exists but does NOT gate (D-10, D-01)."

patterns-established:
  - "NEW-row-not-mutation for capability-matrix evolution: add a sibling divergence row + tighten the drift gate to exempt it by name, never edit the protected convergence row"
  - "Gate-path isolation static analysis: clone verify_core_liveview_runtime_free.sh, swap the forbidden-reference alternatives and scope to named files, keep the ^[^#]* anchor + || true verbatim"

requirements-completed: [ENT-10]

# Metrics
duration: 4min
completed: 2026-05-24
---

# Phase 127 Plan 03: Provider-Honesty Row + Static Isolation Gate Summary

**New `entitlements.stripe_native_sync` capability row (Stripe `native (advisory)`, Fake out-of-slice, Braintree unsupported) landed across code labels + matrix markdown + a tightened drift gate, plus a new merge-blocking static gate proving the advisory cache is unreachable from the always-on entitlement gate path.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-24T12:01:00Z
- **Completed:** 2026-05-24T12:05:04Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- **D-10 provider-honesty surface:** Added a NEW `entitlements.stripe_native_sync` row as a same-PR 3-way SSOT co-update — `@support_labels` + `@provider_support_labels` in `capabilities.ex`, the matrix markdown table + advisory/observational prose, and the drift gate. The `entitlements.local_mapping` convergence row is **byte-for-byte unchanged** (all three providers still `local-identical`).
- **Tightened the negative drift guard:** The existing guard fired on ANY `entitlements.*` row carrying `native|unsupported|bounded` (which the new row's `native (advisory)` / `unsupported` labels would have tripped — the load-bearing conflict flagged in the Pattern Map). It is now anchored to `entitlements.local_mapping` specifically, so the new advisory row is allowed while the convergence contract is still fully protected. A positive `require_substring` pins the exact new row line.
- **D-04 layer 2 isolation gate:** Created `scripts/ci/verify_entitlement_sync_isolation.sh` (cloning the LiveView-runtime-free gate verbatim for its anchors/allowlist) scoped to the three always-on gate-path files; it fails the build if any of them references `EntitlementSummary`, `StripeSync`, or `accrue_entitlement_summaries` (T-127-09). Wired merge-blocking into the `docs-contracts-shift-left` CI job immediately after the LiveView-runtime-free step.

## Task Commits

Each task was committed atomically:

1. **Task 1: New entitlements.stripe_native_sync capability row + tightened drift gate (D-10)** — `f800997` (feat)
2. **Task 2: Static isolation gate verify_entitlement_sync_isolation.sh + CI wiring (D-04 layer 2)** — `8bc4a1f` (feat)

## Files Created/Modified

- `scripts/ci/verify_entitlement_sync_isolation.sh` (created) — Static merge-gate: comment-anchored grep over the 3 gate-path files; `exit 1` if any references the advisory cache.
- `accrue/lib/accrue/processor/capabilities.ex` (modified) — New `stripe_native_sync` key in both `@support_labels` (`"Stripe-native advisory (observational)"`) and `@provider_support_labels` (`fake: "out of slice"`, `stripe: "native (advisory)"`, `braintree: "unsupported"`); convergence `local_mapping` row untouched.
- `.planning/processor-support-matrix.md` (modified) — New `entitlements.stripe_native_sync` table row as a sibling beneath the convergence row + advisory/observational deferral prose; convergence table row byte-unchanged.
- `scripts/ci/verify_processor_support_matrix.sh` (modified) — Positive `require_substring` for the new row; negative divergence guard tightened to scope to `entitlements.local_mapping`.
- `.github/workflows/ci.yml` (modified) — New "Entitlement gate path stays advisory-cache-free (ENT-10 D-04)" step in `docs-contracts-shift-left`, after the LiveView-runtime-free step.

## Decisions Made

- **Anchor the negative guard to `entitlements.local_mapping`** rather than `grep -v`-excluding the new row from a broad scan — both satisfy the plan's "OR" choice; anchoring is the most legible and least brittle (the convergence row is the thing that must never diverge, so naming it directly is the truest expression of intent).
- **Isolation gate scoped to the three gate-path files explicitly** (not all of `accrue/lib`) — the advisory cache *model* will legitimately live in core `accrue/lib/accrue/billing/`; only the gate-decision path must stay cache-free, so a whole-tree scan would produce false positives once Plan 01/02 land the model.
- **Label wording** taken from CONTEXT D-10/D-Specifics: matrix cell `native (advisory)`, public label `Stripe-native advisory (observational)` — honest that the overlay exists but never gates.

## Deviations from Plan

None - plan executed exactly as written. The plan's `read_first` referenced `@core_capability_labels` (lines 60-62) but the live module names that attribute `@support_labels`; this was an expected naming alias (the plan also calls it "code labels"), so the new key was added to `@support_labels` as intended — no behavioral deviation.

## Issues Encountered

None. The one notable design point the plan pre-flagged (the new row's labels tripping the broad negative drift guard, the "PLANNER-CRITICAL CONFLICT") was resolved exactly as the plan directed by tightening the guard to the convergence row.

## Verification Evidence

- `bash scripts/ci/verify_processor_support_matrix.sh` → `OK` (exit 0).
- `bash scripts/ci/verify_entitlement_sync_isolation.sh` → `OK` (exit 0).
- `cd accrue && MIX_ENV=test mix compile --warnings-as-errors` → exit 0.
- Convergence row: `grep -c` returns 1; convergence table-row line shows no `+`/`-` across both commits (byte-unchanged).
- New row present: `entitlements.stripe_native_sync` ≥ 1 in matrix; `stripe_native_sync` ≥ 1 (2) in capabilities.ex.
- **Drift-gate regression proof:** flipping a `local_mapping` cell to `native` makes the matrix script `exit 1`; reverting returns `OK`. Isolated regex proof: the tightened guard FIRES on a `local_mapping` divergence label, does NOT fire on the new `stripe_native_sync` row, and does NOT fire on the clean convergence row.
- **Isolation-gate negative proof:** injecting `alias Accrue.Billing.EntitlementSummary` into `entitlements.ex` makes the gate `exit 1` (FAIL message lists the offending line); reverting returns `OK`. Anchor proof: a `#`-comment mention of the cache does NOT trip; a real code ref does.
- `grep -q 'verify_entitlement_sync_isolation' .github/workflows/ci.yml` matches, inside `docs-contracts-shift-left`.

## Next Phase Readiness

- The provider-honesty row and the static isolation gate are independent of the reducer's source code (they gate against gate-path files Phase 127 does NOT modify), so this plan ran in parallel with Plan 01 with no coupling.
- The isolation gate is intentionally scoped to the three gate-path files; when Plan 01/02 land the `EntitlementSummary` model + `StripeSync`/default-handler projection in core, the gate continues to pass (those files are outside the scanned set) — and will now block any future refactor that wires the cache into the gate path.

## Self-Check: PASSED

All created/modified files exist on disk (6/6) and both task commits are present in git history (`f800997`, `8bc4a1f`).

---
*Phase: 127-optional-stripe-native-sync-isolated-off-by-default*
*Completed: 2026-05-24*
