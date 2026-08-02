---
phase: 216-additive-rail-and-persistence-foundation
verified: 2026-08-02T17:13:47Z
status: gaps_found
score: 18/21 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "An account’s observations, grants, devices, provenance, quarantine state, and ordering data persist with stable identity and transactional uniqueness."
    status: failed
    reason: "The durable evidence/provenance boundary is not enforced: raw evidence can be stored, and a grant can reference an observation belonging to another account, rail, or environment."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/observation.ex"
        issue: "evidence_ref has only a nil-pair check; it accepts unbounded raw receipts/JWS/provider bodies when expiry is supplied."
      - path: "accrue/lib/accrue/entitlements/grant.ex"
        issue: "source_observation_id has only an independent foreign key; no constraint or transaction requires matching account_id, rail, and environment."
    missing:
      - "Bound evidence_ref to an opaque locator and reject raw/provider payload forms."
      - "Atomically enforce source-observation account/rail/environment parity, preferably through a composite database relationship."
  - truth: "Qualified observations preserve normalized/redacted provenance and duplicate event or transaction-plus-kind identity returns one durable row."
    status: failed
    reason: "Blank provider_event_id is treated as absent for conflict selection but is persisted as an empty string. The fallback lookup then requires NULL and raises; the row is outside both partial unique indexes."
    artifacts:
      - path: "accrue/lib/accrue/entitlements/observation.ex"
        issue: "validate_identity/1, conflict_target/1, and fetch_by_identity!/2 use incompatible blank-value semantics."
    missing:
      - "Normalize blank optional identity values to nil (or reject them) before insert, conflict-target selection, and lookup, with regression coverage."
  - truth: "Database indexes—not application prechecks—decide all races and preserve valid durable projection metadata."
    status: failed
    reason: "The migration lacks database CHECK constraints for rail/environment/state domains and numeric bounds; direct SQL/insert_all can persist invalid enums or negative order/revision/retry/quantity values."
    artifacts:
      - path: "accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs"
        issue: "Domain and monotonicity invariants exist only in Ecto changesets."
    missing:
      - "Add named PostgreSQL CHECK constraints, map them in changesets, and prove direct invalid inserts are rejected."
---

# Phase 216: Additive Rail and Persistence Foundation Verification Report

**Phase Goal:** Hosts can represent concurrent Stripe and Apple entitlement evidence on durable, rail-qualified records while existing single-processor integrations remain valid.
**Verified:** 2026-08-02T17:13:47Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Stripe and Apple can be registered together while `processor` remains the supported default-rail alias. | ✓ VERIFIED | `Config.validate_rails!/1` validates the closed registry and `validate_default_rail!/3` requires a controllable rail with exact processor parity; config tests exercise Stripe+Apple and legacy hosts. |
| 2 | Rail/environment/product identifiers map to logical plans without cross-rail or sandbox/production collisions. | ✓ VERIFIED | `entitlement_product_catalog/0` keys by `{rail, environment, product_id}`; the 53-test run covered tuple separation, collisions, aliases, repeat reads, and concurrent reads. |
| 3 | Durable accounts, observations, grants, devices, provenance, quarantine, ordering, and transactional uniqueness are all safe. | ✗ FAILED | See G-1 through G-3: raw provenance can be stored, source observations can cross account/rail boundaries, blank event identity breaks idempotence, and DB-level domain/numeric invariants are absent. |
| 4 | A host can boot with Stripe as controllable default and Apple as observer while the unchanged processor selects Stripe. | ✓ VERIFIED | `config.ex:1240-1330`; `config_entitlements_test.exs:93-125`. |
| 5 | One stable UUID account is created/fetched, reloads from PostgreSQL, and starts at revision zero. | ✓ VERIFIED | `Account.fetch_or_create/3` uses `ON CONFLICT` plus reload; `persistence_test.exs:10-27` exercises it against PostgreSQL. |
| 6 | Repeating account creation returns the same durable row under the DB owner constraint. | ✓ VERIFIED | Named unique index in migration lines 14-18; repeated `fetch_or_create/3` test confirms one persisted row. |
| 7 | No projector, entitlement-read cutover, Apple verification, or offline proof was pulled into the tracer. | ✓ VERIFIED | Phase-owned source scan found no Apple processor, projector, Apple verifier, or proof issuer; guide explicitly excludes these concerns. |
| 8 | Omitted `rails`/`default_rail` preserves legacy processor and `price_ids` behavior. | ✓ VERIFIED | `validate_rails!/1` bypasses only when both are absent; config test lines 129-137 verifies legacy custom processor and `price_ids`. |
| 9 | Explicit default rail is registered, controllable, processor-equivalent, and order-independent. | ✓ VERIFIED | Validation at `config.ex:1312-1330`; tests cover missing/unregistered/Apple/mismatched defaults and Task-based concurrent reads. |
| 10 | `price_ids` expands only through explicit default rail/environment and equality uses the complete tuple. | ✓ VERIFIED | `add_default_rail_price_ids!/5` at lines 1374-1391 and tuple reducer; tested at config test lines 308-335. |
| 11 | Identical normalization is deterministic; same-plan repeats collapse, exact cross-plan collisions fail, and unequal tuples remain distinct. | ✓ VERIFIED | Pure map reducer and `Task.async_stream` coverage at config test lines 250-305 and 338-358. |
| 12 | Empty, singleton, duplicate, and ordered catalog behaviour is stable. | ✓ VERIFIED | Deterministic `%{}` reduction and explicit empty/singleton/repeated/concurrent test coverage. |
| 13 | Observations preserve redacted/bounded provenance and idempotently return one row. | ✗ FAILED | `evidence_ref` is unrestricted beyond pairing, and a blank event ID breaks the partial-index/fetch contract (`observation.ex:144-188`). |
| 14 | Current grants retain only complete-key uniqueness while superseded and distinct-source history coexist. | ✓ VERIFIED | Composite partial index in migration lines 126-145 and real PostgreSQL grant-history test lines 139-159. |
| 15 | Devices are unique within an account and retain rotation/revocation history. | ✓ VERIFIED | Account-scoped partial indexes in migration lines 172-184 and persistence test lines 102-120. |
| 16 | Database constraints, rather than prechecks, safely decide all persistence races and retain valid projection metadata. | ✗ FAILED | Blank event IDs evade the intended identity constraints; migration has no database checks for enum/numeric durable invariants. |
| 17 | Required identities, singleton rows, keys, and order/revision round trips are validated through the normal changeset path. | ✓ VERIFIED | Changeset tests cover required fields, positive quantity/non-negative order and revision, and persistence uses named constraints. |
| 18 | Deterministic fixtures cover both rails/environments and the planned collision/history scenarios. | ✓ VERIFIED | `fixtures.ex` is substantive (175 lines), used by `fake_fixture_test.exs`, and tests pass without live services. |
| 19 | Installer retains legacy processor configuration and supplies an opt-in concurrent-rail/catalog example. | ✓ VERIFIED | Runtime template lines 3-40 retains Stripe processor configuration and comments a coherent rails/default/catalog block; installer tests passed in supplied full-suite evidence. |
| 20 | Guide explains aliasing, tuple equality, scope/privacy, and Apple observer exclusions. | ✓ VERIFIED | Guide lines 27-51 plus executable guide-contract test; no Apple processor implementation was found. |
| 21 | Fixture and installer generation are repeat-safe. | ✓ VERIFIED | Fixture equality checks are executable; supplied full suite includes installer repeat-safety coverage. |

**Score:** 18/21 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue/lib/accrue/config.ex` | Rail registration/catalog | ✓ VERIFIED | Substantive 1,793-line module; boot validator and public accessors are used by config tests. |
| `accrue/lib/accrue/entitlements/account.ex` | Owner-stable account | ✓ VERIFIED | Schema, named unique constraint, and conflict-safe fetch/create wired to migration/test Repo. |
| `accrue/lib/accrue/entitlements/observation.ex` | Privacy-bounded idempotent observation | ⚠️ HOLLOW | Exists, substantive, and migration-wired, but fails provenance and blank-identity behavior. |
| `accrue/lib/accrue/entitlements/grant.ex` | Qualified historical/current grant | ⚠️ HOLLOW | Composite current-row uniqueness exists, but source-observation provenance is not constrained to the same account/rail/environment. |
| `accrue/lib/accrue/entitlements/device.ex` | Account-scoped device history | ✓ VERIFIED | Account FKs, partial current keys, and persistence tests are wired. |
| `accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs` | Four-table durable schema | ⚠️ PARTIAL | Tables/FKs/partial indexes/pair check exist; domain and numeric invariants are not DB-enforced. |
| `accrue/test/accrue/entitlements/persistence_test.exs` | PostgreSQL proof | ⚠️ PARTIAL | 8 substantive tests run and pass, but omit blank-event, raw-`evidence_ref`, cross-provenance, direct-DB, and race rollback cases. |
| `accrue/test/support/entitlements/fixtures.ex` | Deterministic fixtures | ✓ VERIFIED | Used directly by fixture tests; all four supported rail/environment pairs are generated. |
| Runtime installer template, guide, installer/guide tests | Opt-in host guidance | ✓ VERIFIED | Template is linked to Config keys and guide test reads the actual guide. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `Config` | source registry | `Registry.validate/1` | ✓ WIRED | `config.ex:1260-1272`. |
| Account schema | migration | owner identity index name | ✓ WIRED | Same named constraint appears in schema and migration. |
| `price_ids` | qualified catalog | default rail/environment | ✓ WIRED | `add_default_rail_price_ids!/5` constructs only qualified tuple keys. |
| Observation | migration | two observation identity index names | ⚠️ PARTIAL | Names match, but blank values are not normalized consistently with index predicates. |
| Grant/device | account/migration | account FKs and partial keys | ✓ WIRED | Schema associations and migration constraints agree. |
| Fixtures | decision vocabulary | closed rail/environment set | ✓ WIRED | Fixtures only emit Stripe/Apple × production/sandbox values. |
| Installer template | Config | exact rails/default/products keys | ✓ WIRED | Template uses the schema's accepted keys. |
| Guide contract test | guide | literal observer/exclusion anchors | ✓ WIRED | Test reads `guides/entitlements.md` and asserts required/prohibited text. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Qualified catalog | plans/products/price_ids | host application config → pure reducer | Yes | ✓ FLOWING |
| Account | owner type/id | authenticated host caller → Repo insert/reload | Yes | ✓ FLOWING |
| Observation | provider identity/provenance | caller attrs → changeset → PostgreSQL | Unsafe raw provenance accepted | ✗ HOLLOW |
| Grant provenance | `source_observation_id` | caller attrs → independent FK | Can reference mismatched observation | ✗ HOLLOW |
| Device | account/device attrs | caller attrs → account-scoped partial indexes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Config, persistence, fixtures, and guide contracts | `cd accrue && mix test test/accrue/config_entitlements_test.exs test/accrue/entitlements/persistence_test.exs test/accrue/entitlements/fake_fixture_test.exs test/accrue/docs/entitlements_guide_test.exs` | 53 tests, 0 failures | ✓ PASS |
| Full Accrue suite | Orchestrator evidence | 1,798 tests / 63 properties, 0 failures | ℹ️ REPORTED PASS |

### Probe Execution

No Phase-216 probe was declared or discovered; this is not a migration/tooling probe phase.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| RAIL-01 | 216-01, 216-02, 216-04 | ✓ SATISFIED | Concurrent rail validation and legacy alias behavior are implemented and tested. |
| RAIL-02 | 216-01, 216-02, 216-04 | ✓ SATISFIED | Qualified tuple catalogue, collision semantics, deterministic reads, fixtures, and guidance are implemented/tested. |
| RAIL-03 | 216-01, 216-03, 216-04 | ✗ BLOCKED | The core durable record schema exists, but its privacy, cross-account provenance, idempotence, and DB durability invariants do not all hold. |

All IDs declared by PLAN frontmatter are present in `REQUIREMENTS.md` and mapped to Phase 216. No orphaned Phase-216 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `observation.ex` | 144-188 | Paired-only raw evidence reference and incompatible blank ID paths | 🛑 BLOCKER | Privacy contract breached; idempotent ingestion can raise and lose uniqueness. |
| `grant.ex` | 45-48 | Independent FK only | 🛑 BLOCKER | Evidence can be attributed to a different account/rail/environment. |
| Migration | 32-48, 110-121, 160-167 | Missing DB domain/numeric checks | 🛑 BLOCKER | Direct persistence paths can corrupt projection metadata. |

No untracked `TBD`, `FIXME`, or `XXX` marker was found in Phase-216 implementation files. No forbidden Apple processor/projector/offline-proof implementation was found.

### Gaps Summary

The configuration half of the goal is achieved, and the tables are real, migration-backed PostgreSQL artifacts. The phase goal is nevertheless **not achieved** because RAIL-03 requires a safe durable evidence boundary. Three observable contradictions prevent that conclusion: unsafe `evidence_ref` persistence, unscoped grant provenance, and an idempotent observation path that fails for blank event IDs. Database checks for durable enum/numeric invariants are also absent. These are current-phase gaps, not deferred Phase 217+ projection work.

---

_Verified: 2026-08-02T17:13:47Z_
_Verifier: the agent (gsd-verifier)_
