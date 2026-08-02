---
phase: 216-additive-rail-and-persistence-foundation
verified: 2026-08-02T19:00:00Z
status: passed
score: 21/21 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 19/21
  gaps_closed:
    - "Unboxed concurrent PostgreSQL account and observation writers converge, and a cross-account contender receives only an opaque ownership error."
    - "An interrupted multi-row persistence transaction leaves no account, observation, grant, or device row behind."
    - "Raw PostgreSQL writes retain revision zero and reject revision -1 through accrue_entitlement_accounts_revision_nonnegative_check."
  gaps_remaining: []
  regressions: []
---

# Phase 216: Additive Rail and Persistence Foundation Verification Report

**Phase Goal:** Hosts can represent concurrent Stripe and Apple entitlement evidence on durable, rail-qualified records while existing single-processor integrations remain valid.
**Verified:** 2026-08-02T19:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A host can register Stripe and Apple together while legacy `processor` remains the default-rail alias. | ✓ VERIFIED | `Config.validate_rails!/1` preserves the legacy branch and validates concurrent source registration; the focused config/installer/fixture tests pass. |
| 2 | Rail/environment/product identifiers map to one logical plan without cross-rail or sandbox/production collisions. | ✓ VERIFIED | `entitlement_product_catalog/0` uses `{rail, environment, product_id}` keys; collision and deterministic-read tests pass. |
| 3 | Accounts, observations, grants, devices, provenance, quarantine state, and ordering persist with stable identity and transactional uniqueness. | ✓ VERIFIED | Migration-backed schemas are wired to changesets; 83 focused tests include concurrent writers, raw PostgreSQL checks, history, and rollback proof. |
| 4 | Stripe default plus Apple observer boots while `processor` selects Stripe. | ✓ VERIFIED | `config.ex:1240-1329` enforces registered controllable processor parity; multi-rail config test passes. |
| 5 | A UUID account is created/fetched, reloads, and starts at revision zero. | ✓ VERIFIED | `Account.fetch_or_create/3` and `persistence_test.exs:10-27` exercise real PostgreSQL create/reload. |
| 6 | Repeated or concurrent account creation returns one durable owner row. | ✓ VERIFIED | Two unboxed concurrent writers return the same UUID and assert one owner row. |
| 7 | No projector, entitlement-read cutover, Apple verification, or offline proof entered this foundation. | ✓ VERIFIED | Phase modules remain configuration/persistence only; guide contract asserts the Phase-216 exclusions. |
| 8 | Omitted rail keys preserve legacy processor and `price_ids` behavior. | ✓ VERIFIED | The `[]/nil` configuration branch and legacy custom-processor test pass. |
| 9 | Explicit default rails are registered, controllable, processor-equivalent, and order-independent. | ✓ VERIFIED | Default validator plus invalid/default-order/concurrent-read tests pass. |
| 10 | `price_ids` expands only through the explicit default rail/environment. | ✓ VERIFIED | `add_default_rail_price_ids!/5` creates only the default tuple; alias collision test passes. |
| 11 | Catalog normalization is deterministic and exact-tuple collisions fail. | ✓ VERIFIED | Tuple reducer preserves same-plan duplicates and rejects another plan for the same tuple. |
| 12 | Empty, singleton, duplicate, and ordered catalog behavior is stable. | ✓ VERIFIED | Config matrix exercises empty, singleton, reordered, repeated, and concurrent reads. |
| 13 | Observations preserve bounded/redacted provenance and duplicate identities return one correct durable row. | ✓ VERIFIED | Global lookup compares `account_id`; event/fallback cross-account tests and concurrent ownership race test pass; PostgreSQL byte checks are exercised. |
| 14 | Current grants retain complete-key uniqueness while history coexists. | ✓ VERIFIED | Partial current index, provenance FK, duplicate/different-source/supersession tests pass. |
| 15 | Devices are account-scoped and retain rotation/revocation history. | ✓ VERIFIED | Account-scoped partial indexes and lifecycle test pass. |
| 16 | Database constraints decide persistence races, preserve valid ordering metadata, and prevent partial durable sets on rollback. | ✓ VERIFIED | Unboxed concurrent account/observation writers, cross-account conflict, raw zero/-1 revision check, and rollback-isolated four-record transaction are all executed. |
| 17 | Normal changesets validate required identities, keys, and ordering data. | ✓ VERIFIED | Four schemas map named constraints; focused persistence tests exercise identity, ordering, lifecycle, and zero values. |
| 18 | Deterministic fixtures cover both rails/environments and planned collision/history scenarios. | ✓ VERIFIED | Fixture contract uses all four rail/environment pairs and runs duplicate, supersession, and revocation scenarios. |
| 19 | Installer preserves legacy processor config and provides opt-in concurrent rails/catalog. | ✓ VERIFIED | Installer retains active Stripe processor, emits optional rails/catalog, and copies all persistence migrations. |
| 20 | Guide explains aliasing, tuple equality, privacy scope, and Apple observer exclusions. | ✓ VERIFIED | Literal guide-contract test passes and rejects forbidden Apple-authority claims. |
| 21 | Fixture and installer generation are repeat-safe. | ✓ VERIFIED | Fixture stability and installer re-run assertions pass. |

**Score:** 21/21 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/config.ex` | Rail registration and qualified catalog | ✓ VERIFIED | Public accessors, boot validation, source-registry validation, and tuple reducer are substantive and exercised. |
| `accrue/lib/accrue/entitlements/account.ex` | Owner-stable account | ✓ VERIFIED | UUID schema, named uniqueness/check mappings, conflict-safe create/reload, and concurrent test are wired. |
| `accrue/lib/accrue/entitlements/observation.ex` | Account-safe, bounded, idempotent observation | ✓ VERIFIED | Ownership comparison follows global identity selection; provenance, metadata, and evidence constraints are wired and exercised. |
| `accrue/lib/accrue/entitlements/grant.ex` | Qualified current/historical grant | ✓ VERIFIED | Complete current key, scope FK, byte checks, and history behavior are real. |
| `accrue/lib/accrue/entitlements/device.ex` | Account-scoped device history | ✓ VERIFIED | Partial account keys and lifecycle/opaque-ID constraints are real. |
| `accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs` | Four-table durable foundation | ✓ VERIFIED | Prefix-qualified tables, UUIDs, microsecond timestamps, FKs, and partial indexes exist. |
| `accrue/priv/repo/migrations/20260802180000_harden_accrue_entitlement_persistence.exs` | Domain, numeric, evidence, and provenance hardening | ✓ VERIFIED | Named checks and composite provenance FK match changeset mappings. |
| `accrue/priv/repo/migrations/20260802200000_bound_accrue_entitlement_provider_identity.exs` | Provider byte boundaries | ✓ VERIFIED | PostgreSQL `octet_length` checks match application byte validation and raw-write tests. |
| `accrue/test/accrue/entitlements/persistence_test.exs` | PostgreSQL persistence proof | ✓ VERIFIED | Substantive tests cover identity, ownership, byte/database boundaries, concurrency, and rollback. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Config | source registry | `Registry.validate/1` | ✓ WIRED | `config.ex:1260-1272`. |
| `price_ids` | qualified catalog | default rail/environment | ✓ WIRED | `config.ex:1387-1400`. |
| Account schema | owner identity index | matching constraint name | ✓ WIRED | `account.ex:33-36` maps the named migration index. |
| Observation ingest | global identity indexes | conflict target, lookup, ownership comparison | ✓ WIRED | `observation.ex:134-153,241-274`; event/fallback and concurrent ownership tests pass. |
| Observation/grant changesets | provider-bound migration | matching byte checks | ✓ WIRED | `validate_length(..., count: :bytes)` and named `octet_length` constraints agree. |
| Grant | composite source scope FK | account/rail/environment parity | ✓ WIRED | Changeset mapping and mismatch test exercise the migration FK. |
| Installer/fixtures/guide | configuration, migrations, docs | executable contracts | ✓ WIRED | Focused installer, fixture, and guide suites pass. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Qualified catalog | tuple-keyed plan map | host config → pure reducer | Yes | ✓ FLOWING |
| Account | owner type/id | host caller → Repo conflict insert/reload | Yes | ✓ FLOWING |
| Observation | provider identity/provenance | caller attrs → changeset → PostgreSQL identity winner | Yes; non-owner gets opaque error | ✓ FLOWING |
| Grant | `source_observation_id` | caller attrs → composite PostgreSQL FK | Yes; account/rail/environment scope enforced | ✓ FLOWING |
| Device | registration attrs | caller attrs → account-scoped partial indexes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Rail config, persistence, fixtures, installer, and guide contracts | `cd accrue && mix test test/accrue/entitlements/persistence_test.exs test/accrue/config_entitlements_test.exs test/accrue/entitlements/fake_fixture_test.exs test/mix/tasks/accrue_install_test.exs test/accrue/docs/entitlements_guide_test.exs` | 83 tests, 0 failures | ✓ PASS |
| Concurrent account/observation identity and cross-account privacy | Same focused PostgreSQL suite | Unboxed concurrent writers yield one row; losing account receives opaque error | ✓ PASS |
| Interrupted multi-row transaction | Same focused PostgreSQL suite | Account, observation, grant, and device counts are all zero after rollback | ✓ PASS |
| Raw account revision boundary | Same focused PostgreSQL suite | Revision `0` persists; revision `-1` fails named PostgreSQL check | ✓ PASS |

### Probe Execution

No Phase-216 probe was declared or discovered.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| RAIL-01 | 216-01, 216-02, 216-04 | Concurrent Stripe/Apple registration with legacy processor alias | ✓ SATISFIED | Configuration, fixture, and installer contracts pass. |
| RAIL-02 | 216-01, 216-02, 216-04 | Rail/environment-qualified products without tuple collisions | ✓ SATISFIED | Complete-tuple reducer and collision matrix pass. |
| RAIL-03 | 216-01, 216-03, 216-04, 216-05, 216-06 | Stable qualified records with bounded provenance and transactional uniqueness | ✓ SATISFIED | PostgreSQL-backed identity, ownership, domain, raw-write, concurrency, and rollback evidence passes. |

All plan-declared IDs occur in `REQUIREMENTS.md`; no orphaned Phase-216 requirement was found. No later-phase deferral applies.

### Anti-Patterns Found

None. No Phase-216 implementation file contains an unreferenced `TBD`, `FIXME`, or `XXX` marker.

### Gaps Summary

None. The former persistence-evidence gaps are closed by commit `dad6d6b1`: the tests use coordinated, unboxed PostgreSQL writers; assert the one-row and opaque-ownership outcomes; prove a multi-row rollback leaves no durable residue; and validate raw account revision zero/negative-one behavior against the named check.

_Verified: 2026-08-02T19:00:00Z_
_Verifier: the agent (gsd-verifier)_
