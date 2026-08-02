---
phase: 216
slug: additive-rail-and-persistence-foundation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-02
---

# Phase 216 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host configuration → `Accrue.Config` | Host-owned rail, source, environment, processor, and product values become runtime routing identity. | Configuration and qualified product identifiers |
| Host identity → entitlement account | A host-authenticated owner identity becomes an opaque durable account UUID. | Authenticated owner type and owner ID |
| Provider-normalized input → observation | Provider identifiers, normalized attributes, metadata, digests, and opaque evidence references enter persistence. | Provider-derived entitlement evidence |
| Observation → grant | A caller-selected observation UUID becomes provenance for an account/rail/environment-qualified grant. | Entitlement provenance and scope |
| Account → device identity | Installation and key identifiers are associated with an account but do not establish authentication. | Opaque device identifiers and lifecycle state |
| Ecto/API → PostgreSQL | Changesets, concurrent calls, bulk writes, and direct SQL cross into the authoritative durability boundary. | Durable identities, constraints, and history |
| Migration/installer → host repository and Repo | Accrue-owned templates and prefix-qualified migrations enter adopter-controlled code and databases. | Generated configuration and database DDL |
| Fixtures/guidance → adopters and later phases | Examples and documentation can propagate unsafe data or incorrect authority assumptions. | Fake evidence, operational guidance, trust semantics |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-216-01 | Tampering | `Accrue.Config` default rail | high | mitigate | Boot validation requires an explicit registered controllable default and processor/alias agreement; covered by `config_entitlements_test.exs`. | closed |
| T-216-02 | Spoofing | `Account.fetch_or_create/3` | medium | mitigate | `account.ex` documents the authenticated-host boundary, stores an opaque UUID, and exposes only authenticated owner-based fetch/create. | closed |
| T-216-03 | Tampering | Account uniqueness | high | mitigate | Named PostgreSQL owner-identity unique index plus conflict-safe reload and sequential/concurrent persistence tests. | closed |
| T-216-04 | Tampering | Default-rail selection | high | mitigate | Registered/controllable/module agreement is enforced; missing, observer, mismatched, and reordered configurations are tested. | closed |
| T-216-05 | Tampering | Product catalog identity | high | mitigate | Closed rail/environment vocabulary and full qualified-tuple collision reduction are enforced and tested. | closed |
| T-216-06 | Denial of service | Boot normalization | medium | mitigate | Pure bounded normalization performs no provider calls or application-env writes; repeated and concurrent reads are tested. | closed |
| T-216-07 | Repudiation | Configuration errors | low | mitigate | Deterministic collision diagnostics identify logical plans and qualified tuples without secrets. | closed |
| T-216-08 | Tampering | Observation/grant environment | high | mitigate | Rail and environment are non-null identity/current-grant key fields; cross-environment isolation is covered in persistence tests. | closed |
| T-216-09 | Tampering | Concurrent durable identity | high | mitigate | PostgreSQL unique and partial indexes decide races; concurrent account and observation tests exercise the authority boundary. | closed |
| T-216-10 | Information disclosure | Observation metadata/evidence | high | mitigate | Fixed digest, allowlisted metadata, bounded opaque reference, and expiry pairing are enforced in changesets and named database checks with privacy-negative tests. | closed |
| T-216-11 | Repudiation | Device/grant history | medium | mitigate | Partial current indexes coexist with durable `superseded_at`/`revoked_at` history; replacement tests retain prior rows. | closed |
| T-216-12 | Elevation of privilege | Device identity | high | mitigate | Device identity is account-scoped storage identity only; APIs make no authentication claim and account switching retains independent history. | closed |
| T-216-13 | Information disclosure | Fixtures/examples | high | mitigate | Deterministic fake IDs/digests and bounded metadata are enforced by fixture tests and negative source scans. | closed |
| T-216-14 | Tampering | Generated migration/config | medium | mitigate | Installer fingerprint/overwrite behavior and repeat-install tests prevent duplicate generation and preserve host edits. | closed |
| T-216-15 | Elevation of privilege | Apple documentation | high | mitigate | Guide and template define Apple as observer/external manager, preserve Stripe control, and exclude verification/lifecycle authority; executable guide tests enforce the literals. | closed |
| T-216-16 | Information disclosure | `Observation.evidence_ref` | high | mitigate | Ecto byte/grammar validation and named PostgreSQL locator check accept only bounded `opaque://` references; changeset and direct-write tests cover bypasses. | closed |
| T-216-17 | Tampering | `Grant.source_observation_id` | high | mitigate | Composite PostgreSQL foreign key binds observation ID to account, rail, and environment; mismatch tests cover each scope column. | closed |
| T-216-18 | Tampering | Observation idempotency | high | mitigate | Blank identifiers normalize to nil and named identity checks reject blank direct writes before partial-index routing. | closed |
| T-216-19 | Tampering | Durable enum/numeric metadata | high | mitigate | Named domain and numeric checks cover all four tables and are mapped into changesets; catalog/direct-write tests verify them. | closed |
| T-216-20 | Denial of service | Additive hardening migration | medium | mitigate | Prefix-safe metadata-only constraints target newly introduced tables without row rewrites/backfills and pass the fresh installer migration path. | closed |
| T-216-21 | Repudiation | Device lifecycle history | medium | mitigate | Named lifecycle check enforces the active/revoked/superseded timestamp truth table; tests retain valid historical rows. | closed |
| T-216-06-01 | Spoofing | Observation account ownership | high | mitigate | Global identity winner is reloaded and its account compared with the requester; sequential/concurrent event and fallback collision tests reject foreign access. | closed |
| T-216-06-02 | Information disclosure | Cross-account collision response | high | mitigate | Foreign collisions return a generic ownership error without the durable row or account identifiers; tests assert the opaque result. | closed |
| T-216-06-03 | Tampering | Provider provenance fields | high | mitigate | Ecto byte validation and named PostgreSQL `octet_length` checks enforce matching 255/64-byte limits, including raw SQL bypass tests. | closed |
| T-216-06-04 | Denial of service | Indexed provider identities | medium | mitigate | Oversized provider-controlled identifiers are rejected before and at database insertion; multibyte and direct-write cases verify byte semantics. | closed |
| T-216-06-05 | Tampering | Direct durable writes | high | mitigate | Rollback-isolated SQL tests exercise named account, observation, grant, and device checks, and inspect their presence in the configured prefix. | closed |
| T-216-SC | Tampering | Package-manager installs | low | accept | All six plans added no npm, pip, cargo, or Mix dependency, so this supply-chain surface was unchanged. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-216-01 | T-216-SC | No package-manager installation or dependency addition occurred in any Phase 216 plan; the dependency supply-chain surface is unchanged. | Phase plan authors | 2026-08-02 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit 2026-08-02

| Metric | Count |
|--------|-------|
| Threats found | 27 |
| Closed | 27 |
| Open | 0 |

The register was authored at plan time. At configured ASVS level 1, artifact and implementation grep-depth verification found every planned mitigation or documented accepted risk. Per the secure-phase short-circuit rule, no deeper boundary-placement auditor was required.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-02 | 27 | 27 | 0 | Codex secure-phase orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-02
