---
phase: "248"
slug: "reproducible-scenarios-and-integrated-proof"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-12"
---

# Phase 248 — Security

Authored threat register verified by the typed security auditor at ASVS 1, blocking threshold high. Initial review found one high threat; corrected and independently reverified without product changes or new capture attribution.

## Trust Boundaries

| Boundary | Data crossing |
|---|---|
| Scenario command → host/Repo | Target, fixture and database identity; durable previews must retain custody |
| Browser → authenticated Admin | Normal login, owner scope and read-only record review |
| Browser → proof file | Source/asset/image identity and credential-free metadata |
| Historical receipt → current ledger | Exact owner keys, execution results and bounded visual claims |
| Artifact parser → filesystem | Repository-relative evidence paths, capture IDs and hashes |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-248-01 | Tampering | ordinary target | high | mitigate | Exact origin/lane guard in ordinary config; guarded ordinary seed/custody wrapper; skip automatic seeds | closed |
| T-248-02 | Elevation of Privilege | held-out fixture/capture | high | mitigate | Exact 4102 lane, normal auth and owner checks; config rejects disabled sandbox before shared lifecycle, setup rejects before baseSetup/seed; three isolation tests pass | closed |
| T-248-03 | Information Disclosure | manifest/logging | medium | mitigate | Credential only in process memory/environment; manifest has no credentials; render verifier rejects secret-bearing keys | closed |
| T-248-04 | Spoofing | integrated ledger | medium | mitigate | Canonical 13-topic/F01–F05 keys, owners, recorded command/results, revision/assets and capture links verified | closed |
| T-248-05 | Tampering | evidence references | medium | mitigate | Integrated validator rejects outside-repo/traversal/symlink paths; render validator checks capture paths, hashes and dimensions | closed |
| T-248-SC | Tampering | package installation | high | mitigate | No dependency/lockfile changes or package installation | closed |

## Accepted Risks Log

No accepted risks. The pre-existing Sigra bad-password UTC datetime 500 is recorded in `.planning/debug/phase248-ordinary-login.md`, transferred to the existing authentication backlog rather than fixed outside this proof phase; no bad-password retries were performed in closeout.

## Security Audit

| Audit | Closed | Open | Result |
|---|---|---|---|
| Initial typed audit | 5 | 1 high | T-248-02: inherited `ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX=1` bypassed declared checkout isolation |
| Corrective re-audit | 6 | 0 | SECURED; reject flag at config and setup boundaries before fixture operations |

Correction files: `examples/accrue_host/playwright.phase248-heldout.config.js`, `examples/accrue_host/e2e/phase248-heldout-setup.js`, `scripts/ci/phase248_heldout_isolation.test.mjs`. Auditor reran the focused isolation tests: 3 passed, 0 failed. Existing capture cohort remains attributed to source `5548e3fd60d31f256c6bfd5322883066855cc872`; no new browser run or product security claim is inferred.

## Sign-Off

- [x] All six distinct authored threats have verified mitigation dispositions.
- [x] Initial finding and corrective verification are retained.
- [x] `threats_open: 0` and `status: verified` confirmed.

## Fixture cleanup guard augmentation (2026-10-11)

The held-out teardown now invokes an exact-ID edge fixture cleanup. Before any deletion, the script requires the held-out lane on port 4102 with SQL sandbox enabled and verifies the connected local `accrue_host_test[digits]` database, `postgres` role, and loopback server through the existing ordinary seed boundary. It rejects unexpected processor/customer identity, parent links, and unrelated children, then deletes only five allowlisted rows in one transaction. A real no-lane invocation failed before mutation. This augments T-248-02's fixture isolation guard; it does not alter the recorded six-threat audit result or claim a new independent security audit.

**Approval:** verified 2026-10-12; phase completion remains pending the separate phase verification workflow.
