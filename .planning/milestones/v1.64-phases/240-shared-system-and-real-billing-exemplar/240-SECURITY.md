---
phase: "240"
slug: "shared-system-and-real-billing-exemplar"
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-09"
---

# Phase 240 — Security

The configured L1 audit verifies the authored register against current source and execution evidence. All 12 unique phase threats are closed. The repeated `T-240-SC` installation sentinel is recorded once. No new threat inventory or universal security certification is claimed.

## Trust Boundaries

| Boundary | Control |
|---|---|
| Browser → owner-scoped LiveView → billing dispatch | Fresh actor/scope/target/material-state checks, exact money, step-up and duplicate protection remain server-owned. |
| Browser preference/connectivity → rendered controls | Host-forced theme and actual LiveView rejoin have higher authority than local preference/network online events. |
| Source/build → compiled host → served assets | Mounted digest checks bind actual CSS/JS/font bytes and reject a stale response. |
| Proof fixture → preview | Test-only hold/release and seed/reset commands use test configuration; preview is separate. |
| Committed baseline set → CI verdict | Exact eight-file preflight and unchanged blocking Linux pixel comparison. |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / current evidence | Status |
|---|---|---|---|---|---|---|
| T-240-01 | Tampering | Invoice review dispatch | high | mitigate | `invoice_live.ex` `validate_review/2`, `review_fingerprint/2`, step-up and submitted-state guard; invoice LiveView owner asserts stale/foreign/repeated rejection. | closed |
| T-240-02 | Spoofing | Invoice money/outcome | high | mitigate | `reviewed_amount/2` and canonical MoneyFormatter; result branches distinguish accepted, requires-action, rejected and unknown; invoice owner tests. | closed |
| T-240-03 | Tampering | Linux baseline set | medium | mitigate | `visual-baseline-set.cjs`, 12 complete/missing-set Node controls, unconditional existing browser workflow preflight then pixel comparison. Linux pixels remain explicitly unrun locally. | closed |
| T-240-04 | Spoofing | Invoice state/copy | high | mitigate | Canonical `Copy.Invoice.invoice_action_unavailable()` and separate provider-result branches; current state matrix owner assertions. | closed |
| T-240-05 | Tampering | Target/money during reflow | high | mitigate | Review shows canonical invoice/customer/owner identity and currency; fresh server fingerprint independent of viewport; Phase 196/198 narrow/coarse-pointer assertions. | closed |
| T-240-06 | Spoofing | Theme/host force | medium | mitigate | Theme input allowlist and replacement-picker synchronization; Phase 199 System/effective styles and Phase 238 host-forced owner. | closed |
| T-240-07 | Tampering | Validation/focus | medium | mitigate | Existing server submit/step-up checks retained; FocusTrap replacement-target Node proof and Phase 199 keyboard correction/submit/dismiss. | closed |
| T-240-08 | Tampering | Reconnect controls | high | mitigate | `ConnectionState.markNetworkOnline()` stays locked; only `reconnected()` restores original disabled state; document observer covers replaced overlays; Phase 191 negative/ready assertions. | closed |
| T-240-09 | Denial | Repeated dispatch | high | mitigate | Existing server duplicate guard plus test-only held cancellation; Phase 191 checks authoritative dispatch/canceled-event/admin-audit counts remain one. | closed |
| T-240-10 | Tampering | Served provenance | medium | mitigate | Phase 237 compares package-built, host-compiled and served CSS/JS/Geist bytes; stale JS negative fails then interception is removed and bytes restored. | closed |
| T-240-11 | Repudiation | Evidence ledger | medium | mitigate | `240-COVERAGE.md` separates exercised/source-only/historical evidence and recurring owners; CLI rejects an omitted route. Capture manifest records fixture, scope, state and review target. | closed |
| T-240-12 | Tampering | Preview boundary | high | mitigate | `accrue_admin/config/test.exs` selects `accrue_admin_test`; host test config selects `accrue_host_test`; E2E seed/reset uses `MIX_ENV=test`, and held action lives in test/support. | closed |
| T-240-SC | Tampering | Package installation | low | accept | No new dependency or package-manager install task. Existing pinned dependency/bootstrap owners remain unchanged. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| R-240-SC | T-240-SC | Existing dependency installation risk remains with incumbent locked owners; no new dependency was introduced. | Approved phase plans (reserved sentinel) | 2026-10-09 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-09 | 13 | 13 | 0 | Execute-phase orchestrator, configured ASVS L1 source/evidence check |

## Sign-Off

- [x] Authored register and summary threat flags checked against current owners
- [x] Accepted installation sentinel documented once
- [x] `threats_open: 0`; configured high threshold has no open item
- [x] L1 short-circuit applies: authored register, no open threats, ASVS level 1

**Approval:** Verified 2026-10-09. Browser emulation, historical TDD timing, remote Linux pixels and provider limits remain explicit in their evidence; none is represented as a stronger security proof.

## Security Audit 2026-10-10

| Metric | Count |
|---|---|
| Threats found | 13 |
| Closed | 13 |
| Open | 0 |
