---
phase: 225
slug: required-lane-signal-repair
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
created: 2026-08-11
---

# Phase 225 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub Actions evidence → checked-in incident index | External run, job, artifact, and failure evidence is reduced to immutable links and credential-free classifications. | CI metadata; potentially sensitive raw diagnostic output remains in Actions artifacts. |
| Test-created webhook identity → shared PostgreSQL tables | Assertions must select facts owned by the event under test rather than depend on global table state. | Webhook, Oban job, and event-ledger identifiers. |
| Playwright fixture/server → browser assertion case | Each bounded viewport case resets and seeds its state before evaluating the preserved assertions. | Test fixtures and browser state. |
| Repository evidence paths → GitHub artifact service | Only existing, governed Phase 192 evidence paths may satisfy artifact upload contracts. | Reports, first-failure evidence, and generated verification records. |
| Local committed repair → remote branch/workflow dispatch | Fresh proof must remain bound to the exact committed repair SHA. | Git ref, commit SHA, and workflow event identity. |
| GitHub run/job/artifact JSON → incident completion status | External CI metadata is validated before an incident can be marked repaired. | Event, SHA, job names, support labels, conclusions, and artifact identities. |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-225-01 | Information disclosure | `225-CI-INCIDENTS.md` | high | mitigate | The incident index contains concise metadata and immutable links; it explicitly keeps logs, payloads, traces, screenshots, secrets, and user data in Actions artifacts. | closed |
| T-225-02 | Tampering | `Accrue.Webhook.IngestTest` | high | mitigate | `ingest_test.exs` selects the webhook by processor identity and its job/ledger facts by the persisted event ID, including a same-identity duplicate negative control. | closed |
| T-225-03 | Repudiation | incident classification | medium | mitigate | Both incident records retain classification, confidence, ruled-out hypotheses, exact commands, owner, SHA, and immutable run/job/artifact links. | closed |
| T-225-04 | Denial of service | release test isolation | low | accept | The established SQL sandbox and focused integration-test cost remain unchanged; no production path or new execution surface was introduced. See Accepted Risks Log. | closed |
| T-225-SC (225-01) | Tampering | package/source acquisition | high | mitigate | The webhook repair changes only test queries and documentation; it introduces no dependency declaration, version, or package-source change. | closed |
| T-225-05 | Tampering | Page 191 partition | high | mitigate | The spec asserts the `5 × 2 × 21 = 210` invariant and creates one native test per viewport while retaining both themes, all flows, and the original assertion body. | closed |
| T-225-06 | Repudiation | Playwright result identity | medium | mitigate | Five uniquely named viewport tests preserve reporter attribution, per-case timeout, retained failure traces, and failure screenshots. | closed |
| T-225-07 | Information disclosure | Phase 192 artifacts | medium | mitigate | CI uploads the governed report, test-results, and archived generated-evidence paths; Phase 225 Markdown records metadata and links rather than copying raw content. | closed |
| T-225-08 | Denial of service | whole-test timeout | high | mitigate | The former 210-cycle traversal is split into five independently budgeted viewport tests while Playwright remains single-worker with zero retries. | closed |
| T-225-SC (225-02) | Tampering | npm/action dependencies | high | mitigate | No dependency declaration or version selection changed; the sole lockfile correction pins the already-declared `jose` dependency by registry checksums, and existing action references remain unchanged. | closed |
| T-225-09 | Spoofing | fresh Actions proof | high | mitigate | The incident ledger binds workflow-dispatch run `31322443304` to repair SHA `ee940cf9e1f86b4d7c551b15ce113feb7f2a2997` and records that it is not a rerun. | closed |
| T-225-10 | Tampering | required/advisory classification | high | mitigate | CI metadata validation counts exactly three release jobs without `[advisory]`; Sigra is separately labeled and cannot satisfy required proof. | closed |
| T-225-11 | Repudiation | incident closure | high | mitigate | The causal index persists exact SHA, run/job/artifact URLs, UTC evidence timestamps, conclusions, commands, and repaired residual status for both incidents. | closed |
| T-225-12 | Information disclosure | CI output capture | medium | mitigate | The causal index stores privacy-safe metadata and immutable URLs only; raw Playwright and server evidence remains in Actions artifacts. | closed |
| T-225-SC (225-03) | Tampering | GitHub CLI/dependencies | high | mitigate | Fresh proof used the configured GitHub CLI and repository workflow without installing a package or changing an action version. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on: high` count toward `threats_open`.*

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party). Repeated `T-225-SC` identifiers are qualified by source plan because each plan authored that shared supply-chain identifier independently.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-225-01 | T-225-04 | Focused integration tests retain the established SQL sandbox and its existing resource cost. The phase adds no production path, retry, serialization, or execution-topology change, so the residual low-severity availability risk is unchanged. | Phase 225 plan disposition, verified by secure-phase audit | 2026-08-11 |

*Accepted risks do not resurface in future audit runs unless the documented boundary changes.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-11 | 15 | 15 | 0 | Codex secure-phase (ASVS L1) |

### Security Audit 2026-08-11

| Metric | Count |
|--------|-------|
| Threats found | 15 |
| Closed | 15 |
| Open | 0 |

The audit parsed all three plan-time `<threat_model>` registers and found no `## Threat Flags` entries in the summaries. L1 evidence checks confirmed the documented controls in the incident ledger, identity-scoped ExUnit queries, bounded Playwright cases/configuration, static CI contracts, workflow artifact definitions, verification report, and phase commit history. With zero open threats and a plan-time register, the ASVS L1 workflow short-circuit applied; no deeper boundary-placement or end-to-end auditor pass was required.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-11
