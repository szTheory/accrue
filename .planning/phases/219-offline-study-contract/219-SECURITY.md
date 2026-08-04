---
phase: 219
slug: offline-study-contract
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-08-04
---

# Phase 219 — Security

> ASVS L1 verification of the plan-authored STRIDE register. All high-severity mitigations are implemented and automated; no blocking threat remains.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Compact JWS/JWKS → verifier | Attacker-controlled proof and key bytes enter parsing and cryptographic verification. | Public cryptographic material and bounded claims |
| Host key provider → public facade | Private signing capability must never cross into public verification output. | Signing capability vs public JWK |
| Verified claims → offline policy | Signed authority narrows as freshness changes. | Plans, features, quantities, disposition, time |
| Authenticated host/device → durable registration/reconnect | Host auth and device PoP establish or reuse durable authority. | Nonce/signature/idempotency/device binding |
| Ecto → PostgreSQL | Direct writes and races must not bypass lifecycle or ordering. | Durable challenge, attempt, issuance, high-water state |
| Reconnect → source coordination/issuer | Provider work must resolve before atomic issuance. | Due-source status and canonical snapshot |
| Generated corpus → Elixir/Swift consumers | Schema/label drift must not fake parity. | Synthetic signed and mutated vectors |
| Verified candidate → Swift cache | Authentication and monotonic ordering control visible offline authority. | Verified compact proof and persisted high-water |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-219-01 | Tampering | proof verifier | high | mitigate | Exact ES256/type/profile, recursive duplicate rejection, signature-before-classification; Elixir/Swift negative suites | closed |
| T-219-02 | Spoofing | key selection/binding | high | mitigate | Local `kid` lookup plus exact account/installation/RFC-7638 binding | closed |
| T-219-03 | Information Disclosure | JWKS/provider boundary | high | mitigate | Public-only JWK profile and recursive private/symmetric-member rejection | closed |
| T-219-SC | Tampering | Hex package install | high | mitigate | Approved `jose` dependency, pinned lockfile, focused and full gates | closed |
| T-219-04 | Elevation of Privilege | stale action policy | high | mitigate | Exhaustive downloaded-study/local-progress allowlist; unknown actions reconnect | closed |
| T-219-05 | Tampering | proof high-water/time | high | mitigate | Exact time boundaries, denial precedence, rollback/future-time and monotonic ordering tests | closed |
| T-219-06 | Elevation of Privilege | legacy gates | high | mitigate | Offline/connectivity state excluded from stable server authorization gates | closed |
| T-219-07 | Repudiation | guidance contract | low | accept | Typed deterministic reasons/guidance; rendered operator surface explicitly owned by Phase 220 | closed |
| T-219-08 | Spoofing | device registration | high | mitigate | Host auth, canonical PoP, recomputed thumbprint, account/installation binding | closed |
| T-219-09 | Elevation of Privilege | nonce/idempotency replay | high | mitigate | Locked one-time challenge consumption, hashed binding, uniqueness and adversarial replay tests | closed |
| T-219-10 | Tampering | persistence bypass | high | mitigate | Named PostgreSQL constraints and direct-invalid-write integration tests | closed |
| T-219-11 | Information Disclosure | stored/logged key/request data | high | mitigate | Public JWK only; request secrets stored as digests; recursive telemetry/result privacy tests | closed |
| T-219-12 | Elevation of Privilege | partial due-source result | high | mitigate | All required due sources must resolve before issuance; unresolved paths enqueue durable repair | closed |
| T-219-13 | Tampering | client high-water/proof hints | high | mitigate | Client hints cannot change due selection, snapshot, revision, lifecycle, or issuance | closed |
| T-219-14 | Tampering | issuance race | high | mitigate | Account/device/admission locks, self-verification, execution-token ownership, atomic terminal outcome | closed |
| T-219-15 | Denial of Service | due-source reconnect | medium | mitigate | Durable attempt/wakeup/Oban worker, bounded retry, lease sweeper, queue telemetry | closed |
| T-219-16 | Information Disclosure | reconnect telemetry/outcomes | high | mitigate | Closed metadata allowlist and recursive absence tests for proof/key/account/provider/PII | closed |
| T-219-22 | Denial of Service | JWKS key rotation | high | mitigate | Per-`kid` issued-expiry retention, early-removal rejection, indefinite retention for unbounded proof | closed |
| T-219-17 | Tampering | fixture oracle | high | mitigate | Canonical schema/case/byte binding and production-code observation before label comparison | closed |
| T-219-18 | Tampering | client cache rollback | high | mitigate | Verified-only admission, authenticated high-water restore, denial-aware ordering, restart/race tests | closed |
| T-219-19 | Tampering | atomic replacement | high | mitigate | Per-path locks, fsync/rename/directory sync, deterministic crash-process tests | closed |
| T-219-20 | Information Disclosure | corpus/results | high | mitigate | Synthetic-only corpus and recursive real identity/provider/private-key rejection | closed |
| T-219-21 | Spoofing | capability evidence | medium | mitigate | Canonical report validation remains feasibility-blocked without bridge/device evidence | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-219-01 | T-219-07 | Typed guidance is deterministic and tested; rendered/audited operator surfaces are explicitly Phase 220 scope. | Plan authority | 2026-08-04 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-04 | 23 | 23 | 0 | Codex execute:post ASVS L1 audit |

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-08-04
