# v1.59 Capability and Limits Matrix

This generated reference contains exact supported and unsupported capability facts. It is not a walkthrough, runbook, App Review guide, security analysis, watchlist, or release narrative.

Contract version: `v1.59`

## Compatibility and limits

- Legacy hosts remain compatible.
- Apple subscriptions are externally managed.
- No cross-rail lifecycle, migration, refund, or proration mutation occurs.
- Stale access preserves downloaded study and local progress only; expansion waits for reconnect.
- No raw transaction data, signed proof material, tokens, or PII is exposed.

## Evidence lanes

| Lane | Merge authority |
| --- | --- |
| `deterministic_conformance` | `merge_blocking` |
| `runtime_capability` | `not_merge_blocking` |
| `advisory_parity` | `not_merge_blocking` |

Runtime capability is `feasibility_blocked` until the tracer records both `crosswake_bridge_compile_unit` and `physical_device` evidence.

## Scenario references

| Scenario ID | Evidence lane |
| --- | --- |
| `apple_purchase_to_web_login` | `deterministic_conformance` |
| `clock_rollback` | `deterministic_conformance` |
| `crosswake_runtime_capability` | `runtime_capability` |
| `deny_tombstone` | `deterministic_conformance` |
| `device_replacement` | `deterministic_conformance` |
| `duplicate_purchase_prevention` | `deterministic_conformance` |
| `empty_evidence_fails_closed` | `deterministic_conformance` |
| `equal_order_stability` | `deterministic_conformance` |
| `expiry_at_boundary` | `deterministic_conformance` |
| `expiry_immediately_after_boundary` | `deterministic_conformance` |
| `expiry_immediately_before_boundary` | `deterministic_conformance` |
| `interrupted_resume` | `deterministic_conformance` |
| `key_rotation` | `deterministic_conformance` |
| `offline_reconnect` | `deterministic_conformance` |
| `parallel_execution` | `deterministic_conformance` |
| `provider_advisory_parity` | `advisory_parity` |
| `refund_revocation` | `deterministic_conformance` |
| `repeat_idempotency` | `deterministic_conformance` |
| `restricted_expansion` | `deterministic_conformance` |
| `stale_downloaded_study_continuity` | `deterministic_conformance` |
| `stripe_purchase_to_ios_login` | `deterministic_conformance` |
| `survivor_grant` | `deterministic_conformance` |

## Deterministic verification

Run `cd accrue && mix accrue.entitlements.reference_scenarios --check` from the repository root. Only `deterministic_conformance` is merge-blocking.
