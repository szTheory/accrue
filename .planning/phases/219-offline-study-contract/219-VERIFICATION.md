---
phase: 219-offline-study-contract
verified: 2026-08-04T03:24:58Z
status: passed
score: 7/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "The language-neutral corpus contains rotation/retirement vectors (old+new overlap, early removal rejection, eligible removal, and unbounded-proof retention)."
    addressed_in: "Phase 220"
    evidence: "Phase 220 success criterion 2 explicitly requires deterministic proof of key rotation."
---

# Phase 219: Offline Study Contract Verification Report

**Phase Goal:** A registered device can safely retain downloaded-study continuity while offline, then converge atomically when it reconnects.
**Verified:** 2026-08-04T03:24:58Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A registered device independently verifies a compact, versioned ES256 proof using public material only. | ✓ VERIFIED | `Offline.verify/3` delegates to strict three-part parsing, fixed `ES256`/type/header, local `kid`, signature, identity, time, and high-water checks in `offline/proof.ex`; protocol tests pass with public P-256 JWKs and hostile-input failures. |
| 2 | Revalidation is 30 days or an earlier real provider bound; freshness equality is stale and there is no 72-hour cutoff. | ✓ VERIFIED | Issuer derives `fresh_until` from the 30-day cap and snapshot bounds; `Proof.classify/2` makes equality stale and explicit `exp` equality `hard_expired`. `offline_test.exs` exercises before/at/after freshness and stale-beyond-72-hours. |
| 3 | Stale access preserves downloaded lessons and local progress, but blocks expansion. | ✓ VERIFIED | Closed action policy allows only downloaded-lesson/local-progress reads and writes for `stale_offline`; it rejects premium download, enrollment, export, purchase, and account/rail mutation. Automated action-policy tests pass. |
| 4 | Hosts receive four distinguishable bounded proof states without changing legacy gates. | ✓ VERIFIED | `Proof.Decision` is limited to `fresh`, `stale_offline`, `denied`, and `invalid`; reasons are mapped to closed atoms and `Offline` is additive. Regression/property tests exercise boundaries and legacy entitlement API compatibility. |
| 5 | Reconnect authenticates account/device PoP, refreshes due rails, and atomically issues an allow proof or signed deny tombstone. | ✓ VERIFIED | Registration/reconnect bind account, installation, nonce, signature, and idempotency key under row locks. `Reconnect` persists/reclaims attempts and `Issuer` locks account/device, reads `Snapshot.fetch/2`, self-verifies, then commits issuance/high-water/terminal outcome together. Reconnect crash, race, replay, pending, revocation, and rollback tests pass. |
| 6 | Device state and installer migration are durable and fail closed. | ✓ VERIFIED | Migration creates constrained public-JWK, challenge, issuance, reconnect-attempt, and wakeup state; direct SQL constraint tests reject private JWKs and invalid values. Installer test verifies the migration is copied exactly once. |
| 7 | Key rotation cannot remove still-needed public keys and private material/PII stay out of public proof data. | ✓ VERIFIED | `Issuance.retirement_requirements/3` supplies per-`kid` retention to the public-key renderer; the targeted retirement test rejects early omission and permits removal at `max(exp)+86,400`. Corpus is public-only (`d`/`k` absent) and production telemetry is bounded/redacted. |
| 8 | The generated public corpus itself covers every promised security, boundary, ordering, rotation, and crash case. | ⚠️ DEFERRED | The checked-in 24-vector corpus covers public verification, stale/72h, expiry, binding, rollback, denial, malformed input, and replacement crashes, but has no rotation/retirement vector IDs or rotation/retirement fields. Elixir has a separate retirement test; Phase 220 explicitly owns deterministic key-rotation proof. |

**Score:** 7/8 truths verified (1 deferred to Phase 220; 0 present-but-behavior-unverified)

### Deferred Items

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | Corpus rotation/retirement rows | Phase 220 | Success criterion 2: deterministic proof includes key rotation. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/entitlements/offline.ex` | Public offline facade | ✓ VERIFIED | 225 substantive lines; exposes verification, policy, guidance, challenge/registration/reconnect, and retention-aware JWKS paths. |
| `accrue/lib/accrue/entitlements/offline/proof.ex` | Strict proof verifier and four-state policy | ✓ VERIFIED | 572 lines; strict local-key JOSE verification, duplicate-member rejection, bounded decisions, and action policy. |
| `accrue/lib/accrue/entitlements/offline/{key_provider,challenge,issuance,registration,issuer,source_coordinator,reconnect}.ex` | Host-key boundary, PoP, durable issuance/reconnect | ✓ VERIFIED | All substantive and reached from facade/reconnect worker paths; lock, retry, terminal-state, retention, and telemetry behavior is covered by integration tests. |
| `accrue/priv/repo/migrations/20260803040000_create_accrue_offline_proof_state.exs` | Durable constrained offline state | ✓ VERIFIED | 159-line migration with PostgreSQL constraints and indexes; exercised on the test database and installer path. |
| `accrue/priv/entitlements/v1.59-offline-golden-vectors.json` | Versioned public corpus | ⚠️ PARTIAL / DEFERRED | Production-shaped, deterministic, public-only 24-vector corpus; missing rotation/retirement rows as detailed above. |
| `accrue/test/support/entitlements/offline_golden_vector_verifier.ex` | Production-delegating oracle | ✓ VERIFIED | Corpus tests call public `Offline.verify/3`/policy rather than a duplicate reducer. |
| `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` | Independent verifier and authenticated cache | ✓ VERIFIED | CryptoKit ES256 verifier precedes file replacement; authenticated envelope, process lock, fsync, rename, recovery, and monotonic high-water code are substantive. |
| `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/{GoldenVectorTests,AtomicOfflineCacheProcessTests}.swift` | Parity and crash proof | ✓ VERIFIED | 27 Swift tests passed, including child-process before-rename/after-directory-sync crash cases. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Offline facade | Proof verifier | typed `Proof.verify` delegation | ✓ WIRED | Public `verify/3` emits bounded telemetry then calls `Proof.verify`. |
| Proof verifier | local public key | `kid` lookup and strict JOSE | ✓ WIRED | No token-directed fetch; remote key headers are rejected. |
| Registration | Device/challenge persistence | transaction and `FOR UPDATE` | ✓ WIRED | One-time nonce and PoP are verified before durable device admission. |
| Reconnect | source registry/coordinator | due source status and repair | ✓ WIRED | Unresolved due source becomes durable pending/repair, never a partial positive proof. |
| Issuer | canonical snapshot/key provider | locked snapshot, sign, self-verify | ✓ WIRED | Account/device locks precede `Snapshot.fetch/2`; issuance/high-water are committed only after self-verification. |
| Offline JWKS path | issuance history | retirement requirements | ✓ WIRED | Renderer rejects provider key omission while a durable requirement remains. |
| Decision-case exporter | offline corpus | deterministic check mode | ✓ WIRED | `mix accrue.entitlements.decision_cases --check` passed. |
| Elixir oracle and Swift client | corpus | exact profile/outcome binding before observation/replacement | ✓ WIRED | Elixir and Swift tests both consume the canonical checked-in corpus. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Elixir issuer/reconnect | proof claims and revision | locked persisted account/device plus `Snapshot.fetch/2` | Database-backed canonical snapshot; issuance/high-water writes occur in the same transaction | ✓ FLOWING |
| Swift cache | verified compact proof/high-water | strict CryptoKit verification of signed corpus/runtime candidate | Candidate is verified before authenticated atomic replacement | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase offline proof/policy/PoP/reconnect/corpus behaviors | `cd accrue && mix test test/accrue/entitlements/offline_protocol_test.exs test/accrue/entitlements/offline_test.exs test/accrue/entitlements/offline_registration_test.exs test/accrue/entitlements/offline_reconnect_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs` | exit 0; final suite reported 1 property, 42 tests, 0 failures | ✓ PASS |
| Deterministic corpus drift | `cd accrue && mix accrue.entitlements.decision_cases --check` | `Decision-case fixtures are current.` | ✓ PASS |
| Independent Swift verifier/cache and crash behavior | `cd examples/crosswake_tracer && swift test` | 27 tests in 3 suites, 0 failures | ✓ PASS |
| Whole Elixir quality gate | `cd accrue && mix test.all` | exit 0; Credo found no issues across 540 source files | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| OFF-01 | 219-01, 219-05 | Public-key-only compact ES256 proof and language-neutral fixtures | ✓ SATISFIED | Strict Elixir verifier plus independent Swift CryptoKit consumer and public-only corpus. |
| OFF-02 | 219-02, 219-04 | 30-day-or-earlier freshness and stale—not-72-hour—continuity | ✓ SATISFIED | Classifier/issuer code and exact-boundary/property tests. |
| OFF-03 | 219-02, 219-05 | Stale learner continuity with expansion restricted | ✓ SATISFIED | Closed action policy and tested stale actions. |
| OFF-04 | 219-02, 219-05 | Four state/reason surface without legacy gate breakage | ✓ SATISFIED | Typed decision/policy/guidance and compatibility tests. |
| OFF-05 | 219-03, 219-04 | Authenticated reconnect, due rail refresh, atomic allow/deny replacement | ✓ SATISFIED | PoP, locked durable attempt/issuance, recovery and cache crash tests. |
| OFF-06 | 219-01, 219-03, 219-04, 219-05 | Fail-closed security, privacy, replay/rollback/revocation/rotation resistance | ✓ SATISFIED | Strict verifier, DB constraints, retention-aware JWKS, races/fault tests, bounded telemetry, and public corpus. Corpus-specific rotation rows are deferred separately. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, or empty user-visible implementation markers in Phase 219 implementation/test files | ℹ️ Info | No auditable debt-marker blocker found. |

### Human Verification Required

None. `219-VALIDATION.md` declares executable evidence only and no manual-only/UAT acceptance; all behavior-dependent truths were exercised by the executed Elixir or Swift tests.

### Gaps Summary

No blocking Phase 219 gap remains after roadmap filtering. The corpus omits rotation/retirement rows promised by Plan 219-05, but the underlying issuance/retention behavior is implemented and tested in Elixir, and Phase 220 explicitly requires deterministic key-rotation proof. This is recorded above as a deferred item rather than silently treated as corpus-complete.

---

_Verified: 2026-08-04T03:24:58Z_
_Verifier: the agent (gsd-verifier)_
