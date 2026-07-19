---
phase: 207
slug: orchestration-digest-one-command-round-fix-loop
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-07
---

# Phase 207 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Ledger files -> reducers/orchestrators | `findings.ledger.ndjson`, `rounds.ndjson`, and baseline artifacts are committed files that may be hand-edited or conflict-merged. | Ratchet state, finding lifecycle rows, round counters |
| Env/CLI -> capture/proposer/mix tasks | `RATCHET_ROUND`, `RATCHET_SURFACES`, `--slice`, and `--surface` are maintainer-supplied process inputs. | Surface scope, round number, subprocess env |
| LLM/probe output -> local artifacts | Model-originated prose and generated probe data feed digest rendering, decisions, and guard minting. | Free text, `decisions.json`, `probe-results.json`, guard row data |
| Generated guard rows -> committed specs | Guard minting writes into CI-executed Playwright spec files. | Auto-guard marker regions and generated rows |
| Local git index -> `ui.fix` commit | Maintainers may have unrelated staged files before the CSS rebuild commit. | `priv/static` bundle and existing git index state |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-207-01 | Tampering | `decisions.json` -> ledger mutation | mitigate | `ratchet-fix.mjs` reads JSON directly, validates decisions against ledger state before any append, validates `suppressed_reason` against the closed enum, and aborts the whole batch on invalid rows. | closed |
| T-207-02 | Tampering | Guard-mint write target | mitigate | Guard targets are derived from closed maps and revalidated via `isSafeSpecPath`/`GUARD_HOME_SPECS`; writes replace only delimited marker regions. | closed |
| T-207-03 | Tampering | `rounds.ndjson` / `--seal-round` | mitigate | The reducer reuses the existing seq-monotonic `fold()` tamper-evidence check for corrupted or reordered round rows. | closed |
| T-207-04 | Tampering | Digest HTML rendering | mitigate | Every rendered ledger-row string field flows through `escapeHtml()`; self-tests cover HTML escaping and nullable optional prose. | closed |
| T-207-05 | Tampering | `RATCHET_SURFACES` / `--surface` filtering | mitigate | The value is passed via `System.cmd` env, never interpolated into shell strings, and only narrows a closed in-memory surface list; unknown names match nothing. | closed |
| T-207-06 | Repudiation | `.round-next` / `.round-status` marker files | accept | Marker files are ephemeral, gitignored, single-scalar handoffs within one pipeline run; the durable audit record is `rounds.ndjson`. | closed |
| T-207-07 | Denial of Service | Malformed `RATCHET_ROUND` | mitigate | `--seal-round` validates a finite round number before writing and exits non-zero without appending on invalid input. | closed |
| T-207-08 | Tampering | `cache_control` request shape | accept | `cache_control` is a typed SDK request field added by harness-owned builders; identity remains re-derived from `region-tags.js`. | closed |
| T-207-09 | Repudiation | Idempotent guard append | mitigate | Guard minting greps for the exact `@ratchet:<finding_id>` token before append; self-tests cover rerun idempotency. | closed |
| T-207-10 | Elevation of Privilege | `ui.fix` creating new open rows | mitigate | `ui.fix` runs no proposer/verifier fan-out; ExUnit and grep evidence prove it advances existing findings only. | closed |
| T-207-11 | Denial of Service | `validateDigestRows()` | mitigate | Only `suggested_fix` is optional; required identity/location/defect fields remain strict and self-tested. | closed |
| T-207-12 | Tampering | Concrete guard row creation | mitigate | Required fields are validated by guard kind; incomplete concrete rows degrade to `ledger-count` and are covered by self-tests. | closed |
| T-207-13 | Tampering | `appendMintedRow()` direct caller bypass | mitigate | `appendMintedRow()` validates row kind, target home, finding id, and kind-specific fields before file reads/writes. | closed |
| T-207-14 | Repudiation / Tampering | `ui.fix` git commit | mitigate | Commit argv includes `-- priv/static`; FakeRunner tests assert unrelated staged files cannot enter the CSS commit. | closed |
| T-207-SC | Tampering | npm/pip/cargo installs | accept | Phase 207 introduced no new package installs, so the Package Legitimacy Gate was not triggered. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-207-01 | T-207-06 | Ephemeral marker files are same-run handoffs; durable audit state remains in committed ratchet ledgers. | agent | 2026-07-07 |
| AR-207-02 | T-207-08 | `cache_control` changes typed request shape only and does not affect local identity derivation. | agent | 2026-07-07 |
| AR-207-03 | T-207-SC | No new package installs occurred, so no dependency provenance risk was introduced. | agent | 2026-07-07 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-07 | 15 | 15 | 0 | agent |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-07
