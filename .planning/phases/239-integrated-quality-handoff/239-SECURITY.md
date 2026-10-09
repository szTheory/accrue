---
phase: "239"
slug: "integrated-quality-handoff"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-09"
---

# Phase 239 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Authenticated host route → mounted package | Admin and Portal resources are served through host mounts and authenticated fixture sessions. | Route paths, session identity, package assets |
| First-party Portal → checkout provider | The external checkout script is governed by a pinned integrity value and CSP policy. | Third-party script bytes and browser execution permission |
| Reviewer → local Fake-backed preview | The feedback walkthrough observes seeded preview routes; its no-write guarantee is scoped to that walkthrough. | Fixture-backed billing display data and navigation requests |
| Preview process → proof tooling | Local preview and reset-capable verification use distinct databases and environments. | Development preview state versus test proof state |
| Local evidence → handoff claims | Reports distinguish local test results from provider outcomes and remote CI execution. | Test status, workflow definitions, and evidence provenance |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-239-01 | Elevation of privilege (E) | Host smoke routes and fixtures | high | mitigate | Authenticated Admin/Portal route journey and compiled mount contract; see `239-COVERAGE.md`, `phase239_route_coverage_contract_test.exs`, and `phase239-integrated-quality.spec.js`. | closed |
| T-239-02 | Information disclosure (I) | Coverage ledger and CI inventory | medium | mitigate | The route ledger identifies source/current evidence and reports checked-in CI separately from unobserved remote runs; see `239-COVERAGE.md` and `239-01-SUMMARY.md`. | closed |
| T-239-03 | Tampering (T) | Generated assets and copy export | medium | mitigate | Mounted asset/font responses and full temporary-output copy export parity are covered by focused Admin/Portal tests; see `239-SERVED-PARITY.md` and `239-02-SUMMARY.md`. | closed |
| T-239-04 | Tampering (T) | CSP and checkout SRI | high | mitigate | Portal CSP nonce/origin and checkout SRI remain separate tested controls; see `csp_plug_test.exs`, `checkout_live_test.exs`, and `239-02-SUMMARY.md`. | closed |
| T-239-05 | Tampering (T) | Registry/example parity | medium | mitigate | Registry-derived component and Storybook suites passed; adopter-facing docs were reconciled without a duplicate static allowlist; see `239-COMPONENT-PARITY.md` and `239-03-SUMMARY.md`. | closed |
| T-239-06 | Information disclosure (I) | State/evidence report | low | mitigate | The parity report assigns each state family to a named evidence owner and identifies whether the evidence is rendered or server-side; see `239-COMPONENT-PARITY.md`. | closed |
| T-239-07 | Tampering (T) | Preview mutation/reset path | high | mitigate | The authenticated walkthrough captures every non-GET request and asserts none occur; development preview and test proof use separate databases; see the Playwright spec, `239-HANDOFF.md`, and `239-04-SUMMARY.md`. | closed |
| T-239-08 | Spoofing (S) | Fake-backed preview evidence | medium | mitigate | The handoff labels the preview Fake-backed and excludes live-provider parity claims; see `239-HANDOFF.md` and the host README. | closed |
| T-239-09 | Information disclosure (I) | Handoff claims | medium | mitigate | Local checks, checked-in CI jobs, remote CI execution, and provider outcomes are stated separately; remote CI/provider results remain unobserved. | closed |
| T-239-SC | Tampering (T) | Package installation | high | mitigate | No package install was needed; existing package and browser test infrastructure was reused. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-09 | 10 | 10 | 0 | GSD orchestrator evidence review (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-09
