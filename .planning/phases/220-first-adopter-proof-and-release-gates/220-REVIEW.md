---
phase: 220-first-adopter-proof-and-release-gates
reviewed: 2026-08-04T16:25:00Z
depth: standard
files_reviewed: 45
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/guides/entitlements.md
  - accrue/guides/multi-rail-offline-release.md
  - accrue/guides/operator-runbooks.md
  - accrue/guides/release-notes.md
  - accrue/lib/accrue/entitlements/admin.ex
  - accrue/lib/accrue/entitlements/reference_scenarios.ex
  - accrue/lib/accrue/entitlements/reference_scenarios/markdown.ex
  - accrue/lib/accrue/entitlements/repair.ex
  - accrue/lib/mix/tasks/accrue.entitlements.reference_scenarios.ex
  - accrue/mix.exs
  - accrue/priv/entitlements/v1.59-public-contract.json
  - accrue/priv/entitlements/v1.59-reference-scenarios.json
  - accrue/test/accrue/docs/v159_release_contract_test.exs
  - accrue/test/accrue/entitlements/admin_test.exs
  - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
  - accrue/test/accrue/entitlements/reference_scenarios_test.exs
  - accrue/test/accrue/entitlements/repair_drills_test.exs
  - examples/accrue_host/docs/adoption-proof-matrix.md
  - examples/accrue_host/docs/capability-limits-matrix.md
  - examples/accrue_host/e2e/entitlement-diagnostics.spec.js
  - examples/accrue_host/lib/accrue_host_web/live/entitlement_diagnostics_live.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs
  - examples/accrue_host/priv/repo/migrations/20260802180000_harden_accrue_entitlement_persistence.exs
  - examples/accrue_host/priv/repo/migrations/20260802200000_bound_accrue_entitlement_provider_identity.exs
  - examples/accrue_host/priv/repo/migrations/20260803010000_create_accrue_entitlement_purchase_operations.exs
  - examples/accrue_host/priv/repo/migrations/20260803013000_create_accrue_entitlement_compatibility_evidence.exs
  - examples/accrue_host/priv/repo/migrations/20260803020000_create_accrue_entitlement_purchase_overrides.exs
  - examples/accrue_host/priv/repo/migrations/20260803030000_create_accrue_apple_lineages_and_intakes.exs
  - examples/accrue_host/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs
  - examples/accrue_host/priv/repo/migrations/20260803032000_add_apple_ordering_to_entitlement_records.exs
  - examples/accrue_host/priv/repo/migrations/20260803040000_create_accrue_offline_proof_state.exs
  - examples/accrue_host/priv/repo/migrations/20260804000000_persist_accrue_offline_reconnect_outcomes.exs
  - examples/accrue_host/priv/repo/migrations/20260804010000_create_accrue_offline_reconnect_attempts.exs
  - examples/accrue_host/priv/repo/migrations/20260804020000_allow_base64url_device_thumbprints.exs
  - examples/accrue_host/priv/repo/migrations/20260804030000_add_execution_token_to_offline_reconnect_attempts.exs
  - examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs
  - examples/accrue_host/test/accrue_host_web/live/entitlement_diagnostics_live_test.exs
  - examples/crosswake_tracer/README.md
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/ReferenceScenarioTests.swift
  - scripts/ci/README.md
  - scripts/ci/verify_adoption_proof_matrix.sh
  - scripts/ci/verify_reference_scenario_contract.sh
  - scripts/ci/verify_release_contract.sh
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 220: Code Review Report

**Reviewed:** 2026-08-04T16:25:00Z
**Depth:** standard
**Files Reviewed:** 45
**Status:** issues_found

## Summary

Reviewed the Phase 220 source, migrations, CI gates, fixtures, documentation, and focused tests. The new contract checks and focused suites pass, but the diagnostic surface can present revoked/superseded-device evidence as current and its repair dialog does not provide the promised keyboard-safe focus behavior.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Revoked or superseded devices can be reported as a recent proof horizon

**File:** `accrue/lib/accrue/entitlements/admin.ex:293-306`

**Issue:** `device_summary/2` computes the active-device count, but passes the complete device list to `proof_horizon/2`. A revoked or superseded device retains its `last_seen_at`, so an account with no active device can render `state: :needs_attention` alongside `proof_horizon: :recent`. That is misleading diagnostic evidence for an operator deciding whether a device proof is still usable.

**Fix:** Derive both count and horizon from current active devices, or return `:unknown` when no active device exists. For example:

```elixir
active_devices = Enum.filter(devices, &(&1.state == :active))

%{
  state: if(active_devices == [], do: :needs_attention, else: :available),
  count: length(active_devices),
  proof_horizon: proof_horizon(active_devices, now)
}
```

Add coverage for a recent revoked device and a superseded device.

### WR-02: The repair confirmation dialog neither moves focus nor traps it

**File:** `examples/accrue_host/lib/accrue_host_web/live/entitlement_diagnostics_live.ex:127-158`

**Issue:** Opening the `aria-modal` dialog leaves focus on the triggering control behind the overlay, and the dialog has no focus trap. Keyboard users can therefore tab through background controls despite the modal assertion. On completion, `#repair-status` is merely focusable (`tabindex="-1"` at line 121); nothing focuses it. This contradicts the claimed focus-safe repair control and is not exercised by the browser test, which only covers the unavailable state.

**Fix:** Use Phoenix's focus-management component (for example, wrap the dialog in `<.focus_wrap id="repair-dialog">`) and explicitly restore focus to the trigger on cancel or move it to `#repair-status` after successful completion. Extend the Playwright test to open, tab within, cancel/confirm, and assert the resulting focus target.

---

_Reviewed: 2026-08-04T16:25:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
