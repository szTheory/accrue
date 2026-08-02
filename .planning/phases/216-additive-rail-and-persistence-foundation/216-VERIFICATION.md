---
phase: 216-additive-rail-and-persistence-foundation
verified: 2026-08-02T17:50:18Z
status: gaps_found
score: 18/21 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 18/21
  gaps_closed:
    - "Blank optional observation identities normalize to nil and the transaction-plus-kind fallback is idempotent."
    - "Evidence references are restricted to paired bounded opaque locators."
    - "A grant's non-null source observation is atomically scope-bound to the same account, rail, and environment."
    - "The hardening migration adds named rail/environment/state and numeric PostgreSQL constraints."
  gaps_remaining:
    - "Observation idempotent ingest can return another account's row after a rail/environment/provider-identity collision."
    - "Provider-originated identifiers retained as durable provenance have no application or database length bounds."
  regressions: []
gaps:
  - truth: "An account’s observations, grants, devices, provenance, quarantine state, and ordering data persist with stable identity and transactional uniqueness."
    status: failed
    reason: "Observation idempotency is globally keyed only by rail/environment/provider identity and the successful conflict path fetches without account_id. A collision from a second account returns the first account's observation as {:ok, row}."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/observation.ex"
        issue: "conflict_target/1 and fetch_by_identity!/2 omit account_id; insert_idempotently/2 treats the cross-account conflict as successful idempotence."
      - path: "accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs"
        issue: "Both partial observation identity indexes omit account_id."
    missing:
      - "Make the identity model account-scoped, or retain global identities but verify account_id after conflict and return an explicit ownership-collision error."
      - "Add event and transaction-plus-kind cross-account collision regression tests."
  - truth: "Qualified observations preserve normalized/redacted bounded provenance and duplicate event or transaction-plus-kind identity returns one durable row."
    status: failed
    reason: "provider_event_id, provider_transaction_id, kind, provider_lineage_id, and provider_product_id are provider-originated durable provenance fields with no length constraint in the changeset or PostgreSQL schema. This does not meet RAIL-03's bounded-provenance contract."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/observation.ex"
        issue: "No validate_length/3 calls cover the provider identity/provenance fields."
      - path: "accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs"
        issue: "Provider identifiers are unconstrained PostgreSQL text, including indexed event and transaction IDs."
    missing:
      - "Choose documented byte limits for retained provider identity/provenance fields, enforce them in changesets and named PostgreSQL octet_length checks, and test over-limit direct writes."
behavior_unverified_items:
  - truth: "Database constraints, rather than prechecks, safely decide all persistence races and retain valid projection metadata."
    test: "Attempt representative invalid account, observation, grant, and device direct inserts (including invalid enum/numeric and locator values) inside rollback-isolated transactions."
    expected: "PostgreSQL rejects every invalid row by its named constraint while zero-valued valid ordering metadata and valid history rows persist."
    why_human: "The hardening migration contains the checks and the focused suite migrates it, but persistence_test.exs has no insert_all/SQL direct-write or PostgreSQL-catalog behavioral test; source presence cannot prove the bypass path."
---

# Phase 216: Additive Rail and Persistence Foundation Verification Report

**Phase Goal:** Hosts can represent concurrent Stripe and Apple entitlement evidence on durable, rail-qualified records while existing single-processor integrations remain valid.
**Verified:** 2026-08-02T17:50:18Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Stripe and Apple can be registered together while `processor` remains the supported default-rail alias. | ✓ VERIFIED | `Config.validate_rails!/1` and `validate_default_rail!/3` enforce the closed registry and processor parity; focused config suite passed. |
| 2 | Rail/environment/product identifiers map to logical plans without cross-rail or sandbox/production collisions. | ✓ VERIFIED | `entitlement_product_catalog/0` keys by `{rail, environment, product_id}` and the focused suite passed its tuple/collision cases. |
| 3 | Durable accounts, observations, grants, devices, provenance, quarantine, ordering, and transactional uniqueness are safe. | ✗ FAILED | Observation idempotent conflicts can cross the durable account boundary; retained provider provenance is unbounded. |
| 4 | Stripe default plus Apple observer boots while `processor` selects Stripe. | ✓ VERIFIED | Config accessors/validators at `config.ex:1207-1393`; focused config tests passed. |
| 5 | A UUID account is created/fetched, reloads, and starts at revision zero. | ✓ VERIFIED | `Account.fetch_or_create/3` uses database conflict handling and reload; `persistence_test.exs:10-27` passed. |
| 6 | Repeated account creation returns one durable owner row. | ✓ VERIFIED | Named owner index plus the exercised repeat insert test. |
| 7 | No projector, entitlement-read cutover, Apple verification, or offline proof entered the foundation. | ✓ VERIFIED | Phase-owned modules/migrations contain only configuration and persistence; no later-phase runtime consumer was found. |
| 8 | Omitted `rails`/`default_rail` preserves legacy processor and `price_ids`. | ✓ VERIFIED | `validate_rails!/1` leaves the legacy path intact; focused config suite passed. |
| 9 | Explicit default rail is registered, controllable, processor-equivalent, and order-independent. | ✓ VERIFIED | `config.ex:1312-1330` and focused config tests passed. |
| 10 | `price_ids` expands only through the explicit default rail/environment. | ✓ VERIFIED | `add_default_rail_price_ids!/5` at `config.ex:1387-1393`. |
| 11 | Catalog normalization is deterministic and complete-tuple collisions fail. | ✓ VERIFIED | Pure reducer/config test coverage passed. |
| 12 | Empty, singleton, duplicate, and ordered catalog behavior is stable. | ✓ VERIFIED | Focused config/fixture tests passed. |
| 13 | Observations retain bounded/redacted provenance and idempotently return one correct durable row. | ✗ FAILED | Locators and blank identities are now protected, but cross-account conflict resolution leaks another account's row and provider identifiers remain unbounded. |
| 14 | Current grants retain complete-key uniqueness while history coexists. | ✓ VERIFIED | Partial index/history test passed; composite source-observation FK is present. |
| 15 | Devices are unique within an account and retain rotation/revocation history. | ✓ VERIFIED | Account-scoped partial indexes and device lifecycle test passed. |
| 16 | Database constraints decide persistence races and retain valid projection metadata. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Named checks exist in the hardening migration, but no direct-write or catalog test exercises their database-bypass behavior. |
| 17 | Normal changesets validate required identities, keys, and ordering data. | ✓ VERIFIED | Changeset validation and named constraint mappings exist; focused suite passed. |
| 18 | Deterministic fixtures cover both rails/environments and planned collision/history scenarios. | ✓ VERIFIED | Fixture contract suite passed. |
| 19 | Installer preserves legacy processor config and provides opt-in concurrent rails/catalog. | ✓ VERIFIED | Installer suite passed; hardening migration propagation is asserted at `accrue_install_test.exs:139-147`. |
| 20 | Guide explains aliasing, tuple equality, scope/privacy, and Apple observer exclusions. | ✓ VERIFIED | Guide-contract test passed. |
| 21 | Fixture and installer generation are repeat-safe. | ✓ VERIFIED | Focused fixture/installer suites passed. |

**Score:** 18/21 truths verified (1 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/config.ex` | Rail registration and qualified catalog | ✓ VERIFIED | Substantive public accessors, boot validation, and tuple reducer are exercised. |
| `accrue/lib/accrue/entitlements/account.ex` | Owner-stable account | ✓ VERIFIED | Schema, named uniqueness/check mappings, and conflict-safe fetch/create. |
| `accrue/lib/accrue/entitlements/observation.ex` | Privacy-bounded idempotent observation | ✗ HOLLOW | Locator/blank-ID repair is real, but its identity fetch is not account-safe and retained provider IDs are unbounded. |
| `accrue/lib/accrue/entitlements/grant.ex` | Qualified historical/current grant | ✓ VERIFIED | Composite provenance FK is mapped and exercised for account/rail/environment mismatches. |
| `accrue/lib/accrue/entitlements/device.ex` | Account-scoped device history | ✓ VERIFIED | Partial account keys and lifecycle validation are wired. |
| `accrue/priv/repo/migrations/20260802180000_harden_accrue_entitlement_persistence.exs` | Forward hardening constraints | ⚠️ PRESENT, BYPASS UNVERIFIED | Constraints are substantive and migration-backed; direct bypass behavior has no executable coverage. |
| `accrue/test/accrue/entitlements/persistence_test.exs` | PostgreSQL proof | ⚠️ PARTIAL | 12 substantive tests passed, but no cross-account observation collision or direct-SQL/`insert_all` test exists. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Config | source registry | `Registry.validate/1` | ✓ WIRED | `config.ex:1260-1264`. |
| `price_ids` | qualified catalog | default rail/environment | ✓ WIRED | `config.ex:1346-1393`. |
| Account schema | owner identity migration index | matching constraint name | ✓ WIRED | `account.ex:36`; creation migration lines 14-18. |
| Observation ingest | observation identity indexes | conflict target + lookup | ✗ NOT SAFE | Both use rail/environment/identity only (`observation.ex:209-242`), omitting account scope. |
| Grant | composite source scope FK | `source_observation_id, account_id, rail, environment` | ✓ WIRED | `grant.ex:49-51`; hardening migration lines 33-39. |
| Changesets | named hardening constraints | matching constraint names | ✓ WIRED | All four schema modules map the named checks present in the hardening migration. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Qualified catalog | tuple-keyed plan map | host config → pure reducer | Yes | ✓ FLOWING |
| Account | owner type/id | host caller → Repo conflict insert/reload | Yes | ✓ FLOWING |
| Observation | provider identity/provenance | caller attrs → changeset → PostgreSQL → conflict lookup | Cross-account collision can return another account’s row | ✗ HOLLOW |
| Grant | `source_observation_id` | caller attrs → composite FK | Same-account/rail/environment enforced | ✓ FLOWING |
| Device | registration attrs | caller attrs → account-scoped indexes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Config, persistence, fixtures, installer, and guide contracts | `cd accrue && mix test test/accrue/config_entitlements_test.exs test/accrue/entitlements/persistence_test.exs test/accrue/entitlements/fake_fixture_test.exs test/mix/tasks/accrue_install_test.exs test/accrue/docs/entitlements_guide_test.exs` | 72 tests, 0 failures (0.8 s) | ✓ PASS |
| Cross-account observation idempotency | No named regression test exists | Static trace shows conflict and fetch omit `account_id` | ✗ FAIL |
| Direct database constraint bypasses | No named direct-write/catalog test exists | Migration presence alone does not exercise `insert_all`/SQL behavior | ? SKIP |

### Probe Execution

No Phase-216 probe was declared or discovered.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RAIL-01 | 216-01, 216-02, 216-04 | Concurrent Stripe/Apple registration with legacy processor alias | ✓ SATISFIED | Config behavior is implemented and exercised by the focused suite. |
| RAIL-02 | 216-01, 216-02, 216-04 | Rail/environment-qualified products without tuple collisions | ✓ SATISFIED | Complete-tuple catalog reducer and tests pass. |
| RAIL-03 | 216-01, 216-03, 216-04, 216-05 | Stable rail-qualified durable records with bounded provenance and transactional uniqueness | ✗ BLOCKED | Cross-account observation collision and unbounded retained provider provenance violate the contract; database-bypass behavior is also unexercised. |

All plan-declared IDs (`RAIL-01`, `RAIL-02`, `RAIL-03`) occur in `REQUIREMENTS.md` and map to Phase 216. No orphaned Phase-216 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `observation.ex` | 115-120, 209-242 | Global conflict target followed by account-unscoped fetch | 🛑 BLOCKER | A second account can receive the first account's persisted observation. |
| `observation.ex` | 31-35, 66-107 | No length validation for durable provider identifier/provenance fields | 🛑 BLOCKER | Provider-controlled text can be stored and indexed without a bounded-provenance limit. |
| `persistence_test.exs` | 10-353 | No direct-write or PostgreSQL catalog assertions despite the hardening claim | ⚠️ WARNING | PostgreSQL bypass behavior remains unproven. |

No untracked `TBD`, `FIXME`, or `XXX` debt marker was found in the Phase-216 implementation files.

### Gaps Summary

The configuration and most persistence substrate are real, migration-backed, and exercised. The phase goal is still not achieved: its durable account boundary is contradicted by `Observation.insert_idempotently/2`. A duplicate identity submitted for account B conflicts with account A's row, then `fetch_by_identity!/2` selects account A's row because it does not filter `account_id`. The code therefore reports successful idempotence while crossing the account boundary.

The advisory review's identifier finding is also material to RAIL-03, though its exact sizes need a design decision: five provider-originated fields are indefinitely retained (two are indexed) without application or database length bounds, contrary to bounded provenance. This is not deferred to Phases 217–220; none of their goals specifically covers correcting the Phase-216 storage boundary.

_Verified: 2026-08-02T17:50:18Z_
_Verifier: the agent (gsd-verifier)_
