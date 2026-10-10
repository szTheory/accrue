---
phase: "242"
slug: "investigations-and-remaining-admin-surfaces"
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-10"
---

# Phase 242 — Security

## Trust Boundaries

Admin input crosses scoped query/render and read-to-mutation boundaries. Returns, selected IDs, reviews and asynchronous results must retain supported current admin/owner/actor authority. This is an ASVS L1 presence audit of the planned register; it does not establish provider-live, device, speech or remote CI behavior.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-242-01 | Tampering | Scoped returns | high | mitigate | `scoped_path.ex:7,56,103,127,196`: finite families, unique decoded keys, fresh owner rebuild, paired path/label; ScopedPath and route tests | closed |
| T-242-02 | Tampering | Replay | high | mitigate | `webhooks_live.ex:123,164,211,290,354,361`, `webhook_live.ex:149,601,645`, `webhooks/dlq.ex:76,96,104,118`: captured IDs, fresh authority/eligibility, StepUp, transaction authorization | closed |
| T-242-03 | Tampering | Catalog relationships | high | mitigate | `coupon_live.ex:265`, `promotion_code_live.ex:44,170,233,264,328`: exact coupon FK, associated parent identity, current route context. Incumbent global catalogs have no owner fields; no tenant-filtered catalog membership is claimed | closed |
| T-242-04 | Tampering | Connect fee review | high | mitigate | `connect_account_live.ex:94,344,360,414,701,791,814,987`: StepUp, fresh scoped account/current-policy comparison, duplicate no-op, stale lock feedback, validated domain preview | closed |
| T-242-05 | Tampering | Async search | high | mitigate | `global_search.ex:44,51,65,128,323,380`: matching generation/query/current owner and freshly scoped rendered links | closed |
| T-242-06 | Tampering | Shell and copy | high | mitigate | `dashboard_live.ex:42,65,88`, `webhooks_live.ex:522`, `invoices_live.ex:308`, `invoice_live.ex:892`, `copy.ex:328`: scoped Home, accurate resource/collection language; Copy.Locked unchanged | closed |
| T-242-07 | Tampering | Proof provenance | high | mitigate | Host `phase238-admin-events-webhooks.spec.js:12,16,42`: package/compiled/served/requested identity; `webhook_replay_test.exs:99,103,119,157,159`: persisted state/jobs/audit; current results in EXECUTION-GATES | closed |
| T-242-SC | Tampering | Existing dependency tree | low | accept | Planned existing-lockfile policy; no dependency or lockfile changes in this phase; accepted risk below | closed |

Paths above are relative to their existing Admin or host modules and tests; the auditor reopened each cited implementation. Seven high controls were verified by the typed security auditor. No unregistered SUMMARY threat flags were present. The audit did not rerun browser suites; their fresh execution results remain in the canonical SUMMARYs and EXECUTION-GATES.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| R-242-SC | T-242-SC | Keep the incumbent dependency tree and lockfiles; no package-manager install or dependency expansion is part of this cleanup. This records the acceptance already authored in all seven plans | Approved Phase 242 plans and execution owner | 2026-10-10 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---:|---:|---:|---|
| 2026-10-10 | 8 | 8 | 0 | gsd-security-auditor plus orchestrator accepted-risk log |

## Sign-Off

- [x] All eight unique threats have a disposition.
- [x] Planned accepted risk is recorded.
- [x] No blocking threat remains; `threats_open: 0`.
- [x] `status: verified` at ASVS L1.

**Approval:** Verified 2026-10-10; independent phase-goal verification remains downstream.
